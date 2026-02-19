import logging
import math
import re
from collections.abc import Iterable
from functools import lru_cache
from typing import Protocol

TOKEN_PATTERN = re.compile(r"[a-zA-Z0-9']+")
logger = logging.getLogger(__name__)


class EmbeddingProvider(Protocol):
    dimension: int

    def embed(self, text: str) -> list[float]:
        ...


class LocalHashEmbeddingProvider:
    """A deterministic local embedder so the MVP works without any API keys."""

    def __init__(self, dimension: int = 64):
        self.dimension = dimension

    def embed(self, text: str) -> list[float]:
        vector = [0.0] * self.dimension
        tokens = TOKEN_PATTERN.findall(text.lower())
        if not tokens:
            return vector

        for token in tokens:
            idx = hash(token) % self.dimension
            vector[idx] += 1.0

        norm = math.sqrt(sum(v * v for v in vector))
        if norm == 0:
            return vector
        return [v / norm for v in vector]


class SentenceTransformerEmbeddingProvider:
    """Real semantic embeddings using sentence-transformers (all-MiniLM-L6-v2)."""

    def __init__(self, model_name: str = "all-MiniLM-L6-v2"):
        self._model_name = model_name
        self._model = None
        self.dimension = 384

    def _load_model(self):
        if self._model is None:
            from sentence_transformers import SentenceTransformer
            logger.info("Loading sentence-transformer model: %s", self._model_name)
            self._model = SentenceTransformer(self._model_name)
            self.dimension = self._model.get_sentence_embedding_dimension()
        return self._model

    @lru_cache(maxsize=512)
    def embed(self, text: str) -> tuple[float, ...]:
        model = self._load_model()
        vector = model.encode(text, normalize_embeddings=True)
        return tuple(float(v) for v in vector)


def create_embedding_provider(provider_type: str = "sentence_transformer", **kwargs) -> EmbeddingProvider:
    """Factory function to create the configured embedding provider."""
    if provider_type == "sentence_transformer":
        try:
            provider = SentenceTransformerEmbeddingProvider(
                model_name=kwargs.get("model_name", "all-MiniLM-L6-v2"),
            )
            # Trigger model load to verify it works
            provider._load_model()
            return provider
        except Exception as e:
            logger.warning("Failed to load sentence-transformer (%s), falling back to hash embeddings", e)
            return LocalHashEmbeddingProvider(dimension=kwargs.get("dimension", 64))
    else:
        return LocalHashEmbeddingProvider(dimension=kwargs.get("dimension", 64))


def tokenize(text: str) -> set[str]:
    return set(TOKEN_PATTERN.findall(text.lower()))


def keyword_score(query: str, fields: Iterable[str]) -> float:
    query_tokens = tokenize(query)
    if not query_tokens:
        return 0.0

    text_tokens: set[str] = set()
    for field in fields:
        text_tokens.update(tokenize(field))

    overlap = query_tokens.intersection(text_tokens)
    return float(len(overlap)) / float(len(query_tokens))
