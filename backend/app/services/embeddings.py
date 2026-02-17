import math
import re
from collections.abc import Iterable
from typing import Protocol

TOKEN_PATTERN = re.compile(r"[a-zA-Z0-9']+")


class EmbeddingProvider(Protocol):
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
