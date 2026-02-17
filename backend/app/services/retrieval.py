from collections.abc import Callable

from sqlalchemy import Select, select
from sqlalchemy.orm import Session

from ..models import Verse
from .embeddings import EmbeddingProvider, keyword_score


class VerseRetriever:
    def __init__(self, session_factory: Callable[[], Session], embedding_provider: EmbeddingProvider):
        self.session_factory = session_factory
        self.embedding_provider = embedding_provider

    def retrieve(self, query: str, top_k: int = 3) -> list[Verse]:
        vector = self.embedding_provider.embed(query)
        with self.session_factory() as db:
            verses = self._vector_search(db, vector, top_k)
            if verses:
                return verses
            return self._keyword_fallback(db, query, top_k)

    def _vector_search(self, db: Session, vector: list[float], top_k: int) -> list[Verse]:
        stmt: Select[tuple[Verse]] = (
            select(Verse)
            .where(Verse.embedding.is_not(None))
            .order_by(Verse.embedding.cosine_distance(vector))
            .limit(top_k)
        )
        return list(db.execute(stmt).scalars().all())

    def _keyword_fallback(self, db: Session, query: str, top_k: int) -> list[Verse]:
        verses = list(db.execute(select(Verse)).scalars().all())
        scored = []
        for verse in verses:
            score = keyword_score(query, [verse.translation, verse.transliteration, " ".join(verse.tags or [])])
            if score > 0:
                scored.append((score, verse))

        scored.sort(key=lambda item: item[0], reverse=True)
        return [item[1] for item in scored[:top_k]]
