import logging
import time
from datetime import date
from typing import Any

from fastapi import Depends, FastAPI, HTTPException, Response, status
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
    FavoriteCreate,
    FavoriteOut,
    GuidanceResponse,
    JourneyOut,
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
# Legacy provider wiring (unchanged — keeps existing behaviour intact)
# ---------------------------------------------------------------------------
mock_provider = MockProvider()
guidance_provider = (
    mock_provider
    if settings.use_mock_provider or not settings.gemini_api_key
    else GeminiProvider(api_key=settings.gemini_api_key, model=settings.gemini_model, fallback=mock_provider)
)
mock_chat_provider = MockChatProvider()
if settings.use_ollama_provider:
    chat_provider = OllamaChatProvider(
        base_url=settings.ollama_base_url,
        model=settings.ollama_model,
        fallback=mock_chat_provider,
    )
elif settings.use_mock_provider or not settings.gemini_api_key:
    chat_provider = mock_chat_provider
else:
    chat_provider = GeminiChatProvider(
        api_key=settings.gemini_api_key,
        model=settings.gemini_model,
        fallback=mock_chat_provider,
    )

# ---------------------------------------------------------------------------
# Multi-LLM orchestrator (Claude primary → Codex fallback → Gemini → mock)
# ---------------------------------------------------------------------------
_guidance_providers: dict[str, Any] = {"mock": mock_provider}
_chat_providers: dict[str, Any] = {"mock": mock_chat_provider}

# Gemini (existing)
if settings.gemini_api_key and not settings.use_mock_provider:
    _guidance_providers["gemini"] = GeminiProvider(
        api_key=settings.gemini_api_key, model=settings.gemini_model, fallback=mock_provider
    )
    _chat_providers["gemini"] = GeminiChatProvider(
        api_key=settings.gemini_api_key, model=settings.gemini_model, fallback=mock_chat_provider
    )

# Codex / OpenAI (new — fallback)
if settings.openai_api_key:
    _guidance_providers["codex"] = CodexGuidanceProvider(
        api_key=settings.openai_api_key, model=settings.codex_model, fallback=mock_provider
    )
    _chat_providers["codex"] = CodexChatProvider(
        api_key=settings.openai_api_key, model=settings.codex_model, fallback=mock_chat_provider
    )

# Claude (new — primary)
if settings.anthropic_api_key:
    _guidance_providers["claude"] = ClaudeProvider(
        api_key=settings.anthropic_api_key, model=settings.claude_model, fallback=mock_provider
    )
    _chat_providers["claude"] = ClaudeChatProvider(
        api_key=settings.anthropic_api_key, model=settings.claude_model, fallback=mock_chat_provider
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
    guidance_provider_name = 'mock' if isinstance(guidance_provider, MockProvider) else 'gemini'
    if isinstance(chat_provider, OllamaChatProvider):
        chat_provider_name = f'ollama:{settings.ollama_model}'
    elif isinstance(chat_provider, GeminiChatProvider):
        chat_provider_name = 'gemini'
    else:
        chat_provider_name = 'mock'

    return {
        'status': 'ok',
        'guidance_provider': guidance_provider_name,
        'chat_provider': chat_provider_name,
    }


@app.get('/api/model-status')
def model_status() -> dict[str, Any]:
    """Health dashboard for all registered LLM providers."""
    return {
        'default_llm': settings.default_llm,
        'providers': orchestrator.model_status(),
    }


@app.get('/daily-verse', response_model=VerseOut)
def daily_verse(db: Session = Depends(get_db)) -> Verse:
    total = db.scalar(select(func.count(Verse.id)))
    if not total:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail='No verses seeded yet')

    day_of_year = date.today().timetuple().tm_yday
    index = day_of_year % total
    verse = db.execute(select(Verse).order_by(Verse.id).offset(index).limit(1)).scalar_one()
    return verse


@app.get('/moods', response_model=MoodOptionsResponse)
def moods() -> MoodOptionsResponse:
    return MoodOptionsResponse(moods=MOOD_OPTIONS)


@app.post('/moods/guidance', response_model=GuidanceResponse)
def mood_guidance(request: MoodGuidanceRequest) -> GuidanceResponse:
    topic_parts = [', '.join(request.moods)]
    if request.note:
        topic_parts.append(request.note)
    topic = ' | '.join(topic_parts)

    cache_key = f'mood:{request.mode}:{topic.strip().lower()}'
    cached = cache.get(cache_key)
    if isinstance(cached, GuidanceResponse):
        return cached

    verses = retriever.retrieve(query=topic, top_k=3)
    if not verses:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail='No verses found')

    result, _model = orchestrator.generate_guidance(topic=topic, mode=request.mode, verses=verses)
    cache.set(cache_key, result)
    return result


@app.post('/ask', response_model=GuidanceResponse)
def ask(request: AskRequest) -> GuidanceResponse:
    topic = request.question.strip()
    cache_key = f'ask:{request.mode}:{topic.lower()}'
    cached = cache.get(cache_key)
    if isinstance(cached, GuidanceResponse):
        return cached

    verses = retriever.retrieve(query=topic, top_k=3)
    if not verses:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail='No verses found')

    result, _model = orchestrator.generate_guidance(topic=topic, mode=request.mode, verses=verses)
    cache.set(cache_key, result)
    return result


@app.post('/chat', response_model=ChatResponse)
def chat(request: ChatRequest) -> ChatResponse:
    message = request.message.strip()
    if not message:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail='Message cannot be empty')

    history_text = '|'.join(f'{turn.role}:{turn.content.strip().lower()}' for turn in request.history[-12:])
    cache_key = f'chat:{request.mode}:{message.lower()}:{hash(history_text)}'
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
        history=request.history,
        verses=verses,
    )
    cache.set(cache_key, result)
    return result


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
