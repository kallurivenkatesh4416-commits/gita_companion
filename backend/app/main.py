import logging
import time
from datetime import date
from typing import Any

from fastapi import Depends, FastAPI, HTTPException, Query, Response, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import delete, func, select
from sqlalchemy.orm import Session, selectinload

from .config import get_settings
from .db import SessionLocal, get_db, init_db
from .logging_config import configure_logging
from .models import Favorite, Verse
from .schemas import (
    AskRequest,
    ChatRequest,
    ChatResponse,
    ChapterVersePageOut,
    ChapterSummaryOut,
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
from .services.chatbot import GeminiChatProvider, MockChatProvider, OllamaChatProvider
from .services.claude_provider import ClaudeChatProvider, ClaudeProvider
from .services.codex_provider import CodexChatProvider, CodexGuidanceProvider
from .services.embeddings import LocalHashEmbeddingProvider
from .services.guidance import GeminiProvider, MockProvider
from .services.llm_orchestrator import LLMOrchestrator
from .services.retrieval import VerseRetriever

settings = get_settings()
configure_logging()
logger = logging.getLogger(__name__)

app = FastAPI(title=settings.app_name, version='0.1.0')
app.add_middleware(
    CORSMiddleware,
    allow_origins=['*'],
    allow_credentials=True,
    allow_methods=['*'],
    allow_headers=['*'],
)

cache = TTLCache(ttl_seconds=settings.cache_ttl_seconds)
embedding_provider = LocalHashEmbeddingProvider(dimension=settings.embedding_dim)
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
    cache.set(cache_key, result)
    return result


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
    cache.set(cache_key, result)
    return result


@app.post('/chat', response_model=ChatResponse)
def chat(request: ChatRequest) -> ChatResponse:
    message = request.message.strip()
    if not message:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail='Message cannot be empty')

    history_text = '|'.join(f'{turn.role}:{turn.content.strip().lower()}' for turn in request.history[-12:])
    cache_key = f'chat:{request.mode}:{request.language}:{message.lower()}:{hash(history_text)}'
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
    cache.set(cache_key, result)
    return result


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


@app.get('/verses/{verse_id}', response_model=VerseOut)
def get_verse(verse_id: int, db: Session = Depends(get_db)) -> Verse:
    verse = db.get(Verse, verse_id)
    if verse is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail='Verse not found')
    return verse


@app.get('/verses', response_model=list[VerseOut])
def list_verses(
    offset: int = Query(default=0, ge=0),
    limit: int = Query(default=200, ge=1, le=500),
    db: Session = Depends(get_db),
) -> list[Verse]:
    return list(
        db.execute(select(Verse).order_by(Verse.id).offset(offset).limit(limit))
        .scalars()
        .all()
    )


@app.get('/verse-stats')
def verse_stats(db: Session = Depends(get_db)) -> dict[str, int]:
    total = int(db.scalar(select(func.count(Verse.id))) or 0)
    return {'total_verses': total, 'expected_minimum': 700}


@app.get('/chapters', response_model=list[ChapterSummaryOut])
def list_chapters(db: Session = Depends(get_db)) -> list[ChapterSummaryOut]:
    rows = db.execute(
        select(Verse.chapter, func.count(Verse.id))
        .group_by(Verse.chapter)
        .order_by(Verse.chapter)
    ).all()
    count_by_chapter = {int(chapter): int(count) for chapter, count in rows}

    return [
        ChapterSummaryOut(chapter=chapter, verse_count=count_by_chapter.get(chapter, 0))
        for chapter in range(1, 19)
    ]


@app.get('/chapters/{chapter}/verses', response_model=ChapterVersePageOut)
def list_chapter_verses(
    chapter: int,
    offset: int = Query(default=0, ge=0),
    limit: int = Query(default=200, ge=1, le=500),
    db: Session = Depends(get_db),
) -> ChapterVersePageOut:
    if chapter < 1 or chapter > 18:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail='Chapter must be between 1 and 18',
        )

    total = int(
        db.scalar(select(func.count(Verse.id)).where(Verse.chapter == chapter)) or 0
    )
    items = list(
        db.execute(
            select(Verse)
            .where(Verse.chapter == chapter)
            .order_by(Verse.verse_number.asc(), Verse.id.asc())
            .offset(offset)
            .limit(limit)
        )
        .scalars()
        .all()
    )
    has_more = (offset + len(items)) < total

    return ChapterVersePageOut(
        items=items,
        total=total,
        limit=limit,
        offset=offset,
        has_more=has_more,
    )


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
