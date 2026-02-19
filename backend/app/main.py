import logging
import asyncio
import json
import time
import hashlib
from datetime import date
from typing import Any

from fastapi import Depends, FastAPI, HTTPException, Query, Request, Response, status
from fastapi.concurrency import run_in_threadpool
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from sqlalchemy import delete, func, select
from sqlalchemy.orm import Session, selectinload

from .config import get_settings
from .db import SessionLocal, get_db, init_db
from .logging_config import configure_logging
from .models import Favorite, Verse
from .schemas import (
    AskRequest,
    ChapterSummary,
    ChatRequest,
    ChatResponse,
    FavoriteCreate,
    FavoriteOut,
    GuidanceVerse,
    GuidanceResponse,
    JourneyOut,
    MorningBackground,
    MorningGreetingRequest,
    MorningGreetingResponse,
    MoodGuidanceRequest,
    MoodOptionsResponse,
    VerseOut,
)
from .services.cache import TTLCache
from .services.catalog_bootstrap import ensure_verse_catalog
from .services.chatbot import GeminiChatProvider, MockChatProvider, OllamaChatProvider
from .services.claude_provider import ClaudeChatProvider, ClaudeProvider
from .services.codex_provider import CodexChatProvider, CodexGuidanceProvider
from .services.embeddings import create_embedding_provider
from .services.guidance import GeminiProvider, MockProvider
from .services.llm_orchestrator import LLMOrchestrator
from .services.retrieval import VerseRetriever
from .services.verification import verify_answer

settings = get_settings()
configure_logging()
logger = logging.getLogger(__name__)

def _cors_allow_origins() -> list[str]:
    # Production: lock to a single domain
    if settings.production_domain:
        domain = settings.production_domain.rstrip("/")
        origins = [domain]

        # Optional convenience: allow www. variant
        if domain.startswith("https://"):
            origins.append(domain.replace("https://", "https://www.", 1))
        elif domain.startswith("http://"):
            origins.append(domain.replace("http://", "http://www.", 1))

        # De-dupe while keeping order
        return list(dict.fromkeys(origins))

    # Dev-only defaults (safe)
    return [
        "http://localhost",
        "http://localhost:3000",
        "http://localhost:5173",
        "http://127.0.0.1",
        "http://127.0.0.1:8000",
        "http://10.0.2.2",       # Android emulator -> host loopback
        "http://10.0.2.2:8000",
    ]



app = FastAPI(title=settings.app_name, version='0.1.0')
app.add_middleware(
    CORSMiddleware,
    allow_origins=_cors_allow_origins(),
    allow_credentials=True,
    allow_methods=['*'],
    allow_headers=['*'],
)
if not settings.production_domain:
    logger.warning("PRODUCTION_DOMAIN is not set; CORS is restricted to local dev origins only.")
else:
    logger.info("CORS allow_origins=%s", _cors_allow_origins())

cache = TTLCache(ttl_seconds=settings.cache_ttl_seconds)
embedding_provider = create_embedding_provider(
    provider_type=settings.embedding_provider,
    model_name=settings.embedding_model,
    dimension=settings.embedding_dim,
)
logger.info("Embedding provider: %s (dim=%d)", type(embedding_provider).__name__, embedding_provider.dimension)
retriever = VerseRetriever(session_factory=SessionLocal, embedding_provider=embedding_provider)

# ---------------------------------------------------------------------------
# Multi-LLM orchestrator (Claude primary -> Codex fallback -> Gemini -> mock)
# ---------------------------------------------------------------------------
mock_provider = MockProvider()
mock_chat_provider = MockChatProvider()
_guidance_providers: dict[str, Any] = {'mock': mock_provider}
_chat_providers: dict[str, Any] = {'mock': mock_chat_provider}
allow_external_llms = not settings.use_mock_provider

if allow_external_llms and settings.gemini_api_key:
    _guidance_providers['gemini'] = GeminiProvider(
        api_key=settings.gemini_api_key,
        model=settings.gemini_model,
        fallback=mock_provider,
    )
    _chat_providers['gemini'] = GeminiChatProvider(
        api_key=settings.gemini_api_key,
        model=settings.gemini_model,
        fallback=mock_chat_provider,
    )

if allow_external_llms and settings.use_ollama_provider:
    _chat_providers['ollama'] = OllamaChatProvider(
        base_url=settings.ollama_base_url,
        model=settings.ollama_model,
        fallback=mock_chat_provider,
    )

if allow_external_llms and settings.openai_api_key:
    _guidance_providers['codex'] = CodexGuidanceProvider(
        api_key=settings.openai_api_key,
        model=settings.codex_model,
        fallback=mock_provider,
    )
    _chat_providers['codex'] = CodexChatProvider(
        api_key=settings.openai_api_key,
        model=settings.codex_model,
        fallback=mock_chat_provider,
    )

if allow_external_llms and settings.anthropic_api_key:
    _guidance_providers['claude'] = ClaudeProvider(
        api_key=settings.anthropic_api_key,
        model=settings.claude_model,
        fallback=mock_provider,
    )
    _chat_providers['claude'] = ClaudeChatProvider(
        api_key=settings.anthropic_api_key,
        model=settings.claude_model,
        fallback=mock_chat_provider,
    )

orchestrator = LLMOrchestrator(
    guidance_providers=_guidance_providers,
    chat_providers=_chat_providers,
    default_llm=settings.default_llm,  # type: ignore[arg-type]
)

MOOD_OPTIONS = [
    'Anxious',
    'Overwhelmed',
    'Uncertain',
    'Unmotivated',
    'Grateful',
    'Sad',
    'Angry',
    'Hopeful',
]

CHAPTER_SUMMARIES: dict[int, dict[str, str]] = {
    1: {'name': 'Arjuna Vishada Yoga', 'summary': "Arjuna's despair on the battlefield. Overwhelmed by grief at the prospect of fighting his own kin, he lays down his arms."},
    2: {'name': 'Sankhya Yoga', 'summary': 'The yoga of knowledge. Krishna teaches the eternal nature of the soul, the importance of duty, and introduces karma yoga.'},
    3: {'name': 'Karma Yoga', 'summary': 'The yoga of selfless action. Krishna explains why action performed without attachment leads to liberation.'},
    4: {'name': 'Jnana Karma Sanyasa Yoga', 'summary': 'The yoga of knowledge and renunciation of action. Krishna reveals divine incarnation and the fire of knowledge that burns all karma.'},
    5: {'name': 'Karma Sanyasa Yoga', 'summary': 'The yoga of renunciation. Krishna compares renunciation and selfless action, showing both paths lead to the same goal.'},
    6: {'name': 'Dhyana Yoga', 'summary': 'The yoga of meditation. Detailed instructions on meditation practice, self-control, and the marks of a true yogi.'},
    7: {'name': 'Jnana Vijnana Yoga', 'summary': 'The yoga of knowledge and wisdom. Krishna reveals His divine nature and how all of creation rests in Him.'},
    8: {'name': 'Aksara Brahma Yoga', 'summary': 'The yoga of the imperishable Brahman. Teachings on what happens at the time of death and how to attain the Supreme.'},
    9: {'name': 'Raja Vidya Raja Guhya Yoga', 'summary': 'The yoga of royal knowledge and royal secret. Krishna reveals the most confidential knowledge of devotion.'},
    10: {'name': 'Vibhuti Yoga', 'summary': 'The yoga of divine glories. Krishna describes His divine manifestations throughout creation.'},
    11: {'name': 'Vishvarupa Darshana Yoga', 'summary': "The yoga of the cosmic form. Arjuna is granted divine vision to see Krishna's universal form containing all of existence."},
    12: {'name': 'Bhakti Yoga', 'summary': 'The yoga of devotion. Krishna explains the path of loving devotion and the qualities of His dearest devotees.'},
    13: {'name': 'Ksetra Ksetrajna Vibhaga Yoga', 'summary': 'The yoga of the field and its knower. Distinguishing between the body (field) and the soul (knower of the field).'},
    14: {'name': 'Gunatraya Vibhaga Yoga', 'summary': 'The yoga of the three gunas. Krishna explains sattva, rajas, and tamas — the three qualities of material nature.'},
    15: {'name': 'Purushottama Yoga', 'summary': 'The yoga of the Supreme Person. The metaphor of the sacred banyan tree and the nature of the Supreme Being.'},
    16: {'name': 'Daivasura Sampad Vibhaga Yoga', 'summary': 'The yoga of divine and demonic qualities. Contrasting divine virtues with demonic tendencies in human nature.'},
    17: {'name': 'Shraddhatraya Vibhaga Yoga', 'summary': 'The yoga of the three divisions of faith. How faith, food, sacrifice, and charity differ according to the three gunas.'},
    18: {'name': 'Moksha Sanyasa Yoga', 'summary': 'The yoga of liberation through renunciation. The grand conclusion synthesizing all teachings, culminating in complete surrender to the Divine.'},
}


def _daily_verse_from_db(db: Session) -> Verse:
    total = db.scalar(select(func.count(Verse.id)))
    if not total:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail='No verses seeded yet')

    day_of_year = date.today().timetuple().tm_yday
    index = day_of_year % total
    return db.execute(select(Verse).order_by(Verse.id).offset(index).limit(1)).scalar_one()


def _morning_background(tags: list[str], mode: str) -> MorningBackground:
    tag_blob = ' '.join(tags).lower()

    if any(token in tag_blob for token in ['calm', 'mind', 'equanimity', 'peace']):
        return MorningBackground(
            name='Still Dawn',
            palette=['#F9E7C2', '#E8CFA1', '#B7C7C7'],
            image_prompt='A peaceful sunrise over a calm river with soft saffron and misty blue tones.',
        )

    if any(token in tag_blob for token in ['duty', 'action', 'karma', 'courage']):
        return MorningBackground(
            name='Courageous Sunrise',
            palette=['#F4C26C', '#E28743', '#7B3F00'],
            image_prompt='Golden sunrise over ancient temple steps, warm saffron light, disciplined energy.',
        )

    if any(token in tag_blob for token in ['devotion', 'faith', 'bhakti', 'surrender']):
        return MorningBackground(
            name='Devotional Glow',
            palette=['#FFD9A0', '#E9B77D', '#6E7D57'],
            image_prompt='Morning diya light in a serene shrine, soft saffron and leaf-green harmony.',
        )

    if mode == 'clarity':
        return MorningBackground(
            name='Focused Morning',
            palette=['#F6D08D', '#D98F4E', '#4F6D7A'],
            image_prompt='Crisp morning light, clear horizon, saffron and slate tones for focused intention.',
        )

    return MorningBackground(
        name='Gentle Morning',
        palette=['#FCE3B4', '#F2B58A', '#A5BCA7'],
        image_prompt='Soft dawn sky with warm saffron clouds and quiet earth tones for emotional steadiness.',
    )


@app.middleware('http')
async def log_requests(request, call_next):
    start = time.perf_counter()
    response = await call_next(request)
    duration_ms = round((time.perf_counter() - start) * 1000, 2)
    logger.info(
        'request',
        extra={
            'path': request.url.path,
            'method': request.method,
            'status_code': response.status_code,
            'duration_ms': duration_ms,
        },
    )
    return response


@app.on_event('startup')
def on_startup() -> None:
    init_db()
    logger.info('database_initialized')
    with SessionLocal() as db:
        catalog_status = ensure_verse_catalog(db)
    logger.info(
        'verse_catalog_ready seeded=%s before=%s/%s after=%s/%s source=%s',
        catalog_status['seeded'],
        catalog_status['before_total'],
        catalog_status['before_chapters'],
        catalog_status['after_total'],
        catalog_status['after_chapters'],
        catalog_status['source'],
    )

    if not settings.use_mock_provider:
        keys_present = any(
            [
                bool(settings.anthropic_api_key),
                bool(settings.openai_api_key),
                bool(settings.gemini_api_key),
            ]
        )
        if not keys_present:
            logger.warning(
                "LLM STARTUP WARNING: use_mock_provider=false but no API keys are set "
                "(ANTHROPIC_API_KEY / OPENAI_API_KEY / GEMINI_API_KEY). "
                "The app cannot call external LLMs."
            )



@app.get('/health')
def health() -> dict[str, Any]:
    registered = sorted(orchestrator.model_status().keys())
    default_llm = settings.default_llm if settings.default_llm in registered else 'mock'

    return {
        'status': 'ok',
        'guidance_provider': 'orchestrated',
        'chat_provider': 'orchestrated',
        'default_llm': default_llm,
        'registered_models': registered,
        'mock_mode': settings.use_mock_provider,
    }


@app.get('/api/model-status')
def model_status() -> dict[str, Any]:
    return {
        'default_llm': settings.default_llm,
        'mock_mode': settings.use_mock_provider,
        'providers': orchestrator.model_status(),
    }


@app.get('/daily-verse', response_model=VerseOut)
def daily_verse(db: Session = Depends(get_db)) -> Verse:
    return _daily_verse_from_db(db)


@app.get('/chapters', response_model=list[ChapterSummary])
def list_chapters(db: Session = Depends(get_db)) -> list[ChapterSummary]:
    cache_key = 'chapters:v1'
    cached = cache.get(cache_key)
    if isinstance(cached, list):
        return cached

    chapter_counts = dict(
        db.execute(
            select(Verse.chapter, func.count(Verse.id))
            .group_by(Verse.chapter)
            .order_by(Verse.chapter)
        ).all()
    )

    chapters = [
        ChapterSummary(
            chapter=chapter,
            name=CHAPTER_SUMMARIES.get(chapter, {}).get('name', f'Chapter {chapter}'),
            summary=CHAPTER_SUMMARIES.get(chapter, {}).get('summary', ''),
            verse_count=int(chapter_counts.get(chapter, 0)),
        )
        for chapter in range(1, 19)
    ]

    cache.set(cache_key, chapters)
    return chapters


@app.get('/moods', response_model=MoodOptionsResponse)
def moods() -> MoodOptionsResponse:
    return MoodOptionsResponse(moods=MOOD_OPTIONS)


@app.post('/moods/guidance', response_model=GuidanceResponse)
def mood_guidance(request: MoodGuidanceRequest) -> GuidanceResponse:
    topic_parts = [', '.join(request.moods)]
    if request.note:
        topic_parts.append(request.note)
    topic = ' | '.join(topic_parts)

    cache_key = f'mood:{request.mode}:{request.language}:{topic.strip().lower()}'
    cached = cache.get(cache_key)
    if isinstance(cached, GuidanceResponse):
        return cached

    verses = retriever.retrieve(query=topic, top_k=3)
    if not verses:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail='No verses found')

    result, _model = orchestrator.generate_guidance(
        topic=topic,
        mode=request.mode,
        language=request.language,
        verses=verses,
    )
    verification = verify_answer(
        answer_text=result.guidance_long,
        response_verses=result.verses,
        retrieved_verses=verses,
    )
    verified_result = result.model_copy(
        update={
            'answer_text': result.guidance_long,
            'verification_level': verification.level,
            'verification_details': verification.checks,
            'provenance': verification.provenance,
        }
    )
    cache.set(cache_key, verified_result)
    return verified_result


@app.post('/ask', response_model=GuidanceResponse)
def ask(request: AskRequest) -> GuidanceResponse:
    topic = request.question.strip()
    cache_key = f'ask:{request.mode}:{request.language}:{topic.lower()}'
    cached = cache.get(cache_key)
    if isinstance(cached, GuidanceResponse):
        return cached

    verses = retriever.retrieve(query=topic, top_k=3)
    if not verses:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail='No verses found')

    result, _model = orchestrator.generate_guidance(
        topic=topic,
        mode=request.mode,
        language=request.language,
        verses=verses,
    )
    verification = verify_answer(
        answer_text=result.guidance_long,
        response_verses=result.verses,
        retrieved_verses=verses,
    )
    verified_result = result.model_copy(
        update={
            'answer_text': result.guidance_long,
            'verification_level': verification.level,
            'verification_details': verification.checks,
            'provenance': verification.provenance,
        }
    )
    cache.set(cache_key, verified_result)
    return verified_result


def _chat_cache_key(request: ChatRequest) -> str:
    message = request.message.strip()
    history_text = "|".join(
        f"{turn.role}:{turn.content.strip().lower()}"
        for turn in request.history[-12:]
    )
    digest = hashlib.md5(history_text.encode("utf-8")).hexdigest()
    return f"chat:{request.mode}:{request.language}:{message.lower()}:{digest}"


def _build_verified_chat_response(request: ChatRequest) -> ChatResponse:
    message = request.message.strip()
    if not message:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail='Message cannot be empty')

    cache_key = _chat_cache_key(request)
    cached = cache.get(cache_key)
    if isinstance(cached, ChatResponse):
        return cached

    recent_user_turns = [turn.content for turn in request.history[-6:] if turn.role == 'user']
    retrieval_query = ' '.join(recent_user_turns + [message])

    verses = retriever.retrieve(query=retrieval_query, top_k=3)
    if not verses:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail='No verses found')

    result, _model = orchestrator.generate_chat(
        message=message,
        mode=request.mode,
        language=request.language,
        history=request.history,
        verses=verses,
    )
    verification = verify_answer(
        answer_text=result.reply,
        response_verses=result.verses,
        retrieved_verses=verses,
    )
    verified_result = result.model_copy(
        update={
            'answer_text': result.reply,
            'verification_level': verification.level,
            'verification_details': verification.checks,
            'provenance': verification.provenance,
        }
    )
    cache.set(cache_key, verified_result)
    return verified_result


def _iter_reply_chunks(reply: str, *, chunk_chars: int = 28) -> list[str]:
    words = reply.split()
    if not words:
        return []

    chunks: list[str] = []
    current_words: list[str] = []
    current_len = 0

    for word in words:
        word_len = len(word)
        proposed_len = word_len if not current_words else current_len + 1 + word_len
        if current_words and proposed_len > chunk_chars:
            chunks.append(' '.join(current_words) + ' ')
            current_words = [word]
            current_len = word_len
        else:
            current_words.append(word)
            current_len = proposed_len

    if current_words:
        chunks.append(' '.join(current_words))
    return chunks


def _sse_event(event: str, payload: dict[str, Any]) -> str:
    return f'event: {event}\ndata: {json.dumps(payload, ensure_ascii=True)}\n\n'


@app.post('/chat', response_model=ChatResponse)
def chat(request: ChatRequest) -> ChatResponse:
    return _build_verified_chat_response(request)


@app.post('/chat/stream')
async def chat_stream(request: ChatRequest, raw_request: Request) -> StreamingResponse:
    async def event_generator():
        try:
            result = await run_in_threadpool(_build_verified_chat_response, request)
            for chunk in _iter_reply_chunks(result.reply):
                if await raw_request.is_disconnected():
                    return
                yield _sse_event('token', {'token': chunk})
                await asyncio.sleep(0.02)

            if await raw_request.is_disconnected():
                return
            yield _sse_event('done', result.model_dump(mode='json'))
        except HTTPException as exc:
            if await raw_request.is_disconnected():
                return
            yield _sse_event(
                'error',
                {
                    'message': str(exc.detail),
                    'status_code': exc.status_code,
                },
            )
        except Exception:
            logger.exception('chat_stream_failed')
            if await raw_request.is_disconnected():
                return
            yield _sse_event('error', {'message': 'Streaming failed'})

    return StreamingResponse(
        event_generator(),
        media_type='text/event-stream',
        headers={
            'Cache-Control': 'no-cache',
            'Connection': 'keep-alive',
            'X-Accel-Buffering': 'no',
        },
    )


@app.post('/morning-greeting', response_model=MorningGreetingResponse)
def morning_greeting(request: MorningGreetingRequest, db: Session = Depends(get_db)) -> MorningGreetingResponse:
    today = date.today()
    cache_key = f'morning:{today.isoformat()}:{request.mode}:{request.language}'
    cached = cache.get(cache_key)
    if isinstance(cached, MorningGreetingResponse):
        return cached

    verse = _daily_verse_from_db(db)
    greeting_prompt = (
        'Create a concise good-morning greeting grounded in the provided Bhagavad Gita verse. '
        'Keep it warm and practical, and include one uplifting line for the day.'
    )
    chat_result, _model = orchestrator.generate_chat(
        message=greeting_prompt,
        mode=request.mode,
        language=request.language,
        history=[],
        verses=[verse],
    )

    selected_verse = chat_result.verses[0] if chat_result.verses else GuidanceVerse(
        verse_id=verse.id,
        ref=verse.ref,
        sanskrit=verse.sanskrit,
        transliteration=verse.transliteration,
        translation=verse.translation,
        why_this='Selected as the anchor verse for your morning.',
    )
    background = _morning_background(verse.tags, request.mode)

    result = MorningGreetingResponse(
        date=today,
        mode=request.mode,
        language=request.language,
        greeting=chat_result.reply.strip(),
        verse=selected_verse,
        meaning=selected_verse.translation,
        affirmation=chat_result.action_step,
        background=background,
    )
    cache.set(cache_key, result)
    return result


@app.get('/verses', response_model=list[VerseOut])
def list_verses(
    chapter: int | None = Query(default=None, ge=1, le=18),
    db: Session = Depends(get_db),
) -> list[VerseOut]:
    chapter_key = chapter if chapter is not None else 'all'
    cache_key = f'verses:{chapter_key}'
    cached = cache.get(cache_key)
    if isinstance(cached, list):
        return cached

    query = select(Verse)
    if chapter is not None:
        query = query.where(Verse.chapter == chapter)

    verses = list(
        db.execute(query.order_by(Verse.chapter, Verse.verse_number)).scalars().all()
    )
    payload = [VerseOut.model_validate(verse) for verse in verses]
    cache.set(cache_key, payload)
    return payload


@app.get('/verses/{verse_id}', response_model=VerseOut)
def get_verse(verse_id: int, db: Session = Depends(get_db)) -> Verse:
    verse = db.get(Verse, verse_id)
    if verse is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail='Verse not found')
    return verse


@app.get('/favorites', response_model=list[FavoriteOut])
def list_favorites(db: Session = Depends(get_db)) -> list[Favorite]:
    return list(
        db.execute(select(Favorite).options(selectinload(Favorite.verse)).order_by(Favorite.created_at.desc()))
        .scalars()
        .all()
    )


@app.post('/favorites', response_model=FavoriteOut, status_code=status.HTTP_201_CREATED)
def create_favorite(payload: FavoriteCreate, db: Session = Depends(get_db)) -> Favorite:
    verse = db.get(Verse, payload.verse_id)
    if verse is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail='Verse not found')

    existing = db.execute(
        select(Favorite).options(selectinload(Favorite.verse)).where(Favorite.verse_id == payload.verse_id)
    ).scalar_one_or_none()
    if existing is not None:
        return existing

    favorite = Favorite(verse_id=payload.verse_id)
    db.add(favorite)
    db.commit()
    db.refresh(favorite)
    favorite = db.execute(select(Favorite).options(selectinload(Favorite.verse)).where(Favorite.id == favorite.id)).scalar_one()
    return favorite


@app.delete('/favorites/{verse_id}', status_code=status.HTTP_204_NO_CONTENT)
def delete_favorite(verse_id: int, db: Session = Depends(get_db)) -> Response:
    db.execute(delete(Favorite).where(Favorite.verse_id == verse_id))
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@app.get('/journeys', response_model=list[JourneyOut])
def journeys() -> list[JourneyOut]:
    return [
        JourneyOut(
            id='starter-3-day',
            title='3-Day Inner Balance',
            description='A short guided sequence for grounding attention and intention.',
            days=3,
            status='not_started',
        )
    ]
