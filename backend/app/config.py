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
    embedding_dim: int = 64
    cache_ttl_seconds: int = 300
    use_mock_provider: bool = True

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
