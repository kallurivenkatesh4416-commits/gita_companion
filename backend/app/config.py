from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "Gita Companion API"
    environment: str = "dev"
    database_url: str = "postgresql+psycopg://postgres:postgres@localhost:5432/gita_companion"
    gemini_api_key: str | None = None
    gemini_model: str = "gemini-1.5-flash"
    use_ollama_provider: bool = False
    ollama_base_url: str = "http://host.docker.internal:11434"
    ollama_model: str = "llama3.1:8b"
    embedding_dim: int = 384
    embedding_model: str = "all-MiniLM-L6-v2"
    embedding_provider: str = "sentence_transformer"  # "sentence_transformer" or "hash"
    cache_ttl_seconds: int = 300
    use_mock_provider: bool = True
    production_domain: str | None = None  # e.g. "https://gita.yourdomain.com"

    # Security: set a non-empty value to require X-API-Key header on all requests.
    # Leave empty (default) to run unauthenticated in local dev.
    client_api_key: str = ""

    # Rate limiting (requests per minute per IP for LLM-heavy endpoints)
    rate_limit_ask: str = "20/minute"
    rate_limit_chat: str = "30/minute"
    rate_limit_mood: str = "20/minute"

    # Retrieval tuning
    retrieval_top_k: int = 3
    retrieval_similarity_threshold: float = 0.75

    # Feature flags
    feature_journeys_enabled: bool = False

    # Claude (Anthropic)
    anthropic_api_key: str | None = None
    claude_model: str = "claude-sonnet-4-5-20250929"

    # OpenAI / Codex
    openai_api_key: str | None = None
    codex_model: str = "gpt-4o-mini"

    # Router default: "claude" or "codex"
    default_llm: str = "claude"

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )


@lru_cache
def get_settings() -> Settings:
    return Settings()
