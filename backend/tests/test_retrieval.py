"""Smoke regression tests for semantic retrieval quality and dataset validation.

These tests run purely in-memory — no database or Docker needed.
They embed verses and sample queries using the real
SentenceTransformerEmbeddingProvider and verify that the expected
verses appear in the top-k results by cosine similarity.
"""

import json
import math
from pathlib import Path

import pytest

DATA_DIR = Path(__file__).resolve().parents[2] / "data"

# Prefer complete dataset, fall back to sample
COMPLETE_FILE = DATA_DIR / "gita_verses_complete.json"
SAMPLE_FILE = DATA_DIR / "gita_verses_sample.json"
DATA_FILE = COMPLETE_FILE if COMPLETE_FILE.exists() else SAMPLE_FILE

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def cosine_similarity(a: list[float] | tuple[float, ...], b: list[float] | tuple[float, ...]) -> float:
    dot = sum(x * y for x, y in zip(a, b))
    norm_a = math.sqrt(sum(x * x for x in a))
    norm_b = math.sqrt(sum(x * x for x in b))
    if norm_a == 0 or norm_b == 0:
        return 0.0
    return dot / (norm_a * norm_b)


def load_verses() -> list[dict]:
    return json.loads(DATA_FILE.read_text(encoding="utf-8-sig"))


def embedding_text(verse: dict) -> str:
    tags = verse.get("tags") or []
    return " ".join([
        verse.get("ref", ""),
        verse.get("transliteration", ""),
        verse["translation"],
        " ".join(tags),
    ])


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture(scope="module")
def provider():
    from app.services.embeddings import SentenceTransformerEmbeddingProvider
    return SentenceTransformerEmbeddingProvider()


@pytest.fixture(scope="module")
def verses():
    return load_verses()


@pytest.fixture(scope="module")
def verse_embeddings(provider, verses):
    result = {}
    for v in verses:
        ref = v["ref"]
        text = embedding_text(v)
        result[ref] = list(provider.embed(text))
    return result


def top_k_refs(provider, verse_embeddings: dict, query: str, k: int = 5) -> list[str]:
    query_vec = list(provider.embed(query))
    scored = [
        (ref, cosine_similarity(query_vec, vec))
        for ref, vec in verse_embeddings.items()
    ]
    scored.sort(key=lambda x: x[1], reverse=True)
    return [ref for ref, _score in scored[:k]]


# ---------------------------------------------------------------------------
# Dataset validation tests
# ---------------------------------------------------------------------------


class TestDatasetValidation:
    def test_complete_dataset_exists(self):
        """The complete 700+ verse dataset file must exist."""
        assert COMPLETE_FILE.exists(), f"Complete dataset not found at {COMPLETE_FILE}"

    def test_verse_count(self, verses):
        """The dataset must have 700 or 701 verses (scholarly variation in Ch.13)."""
        assert len(verses) in (700, 701), f"Expected 700-701 verses, got {len(verses)}"

    def test_chapter_count(self, verses):
        """All 18 chapters must be present."""
        chapters = set(v["chapter"] for v in verses)
        assert len(chapters) == 18, f"Expected 18 chapters, got {len(chapters)}: {sorted(chapters)}"
        assert chapters == set(range(1, 19)), f"Missing chapters: {set(range(1,19)) - chapters}"

    def test_no_duplicate_refs(self, verses):
        """Every verse must have a unique ref."""
        refs = [v["ref"] for v in verses]
        assert len(refs) == len(set(refs)), f"Found duplicate refs"

    def test_required_fields_present(self, verses):
        """Every verse must have chapter, verse, ref, sanskrit, translation."""
        required = ["chapter", "verse", "ref", "sanskrit", "translation"]
        for v in verses:
            for field in required:
                assert v.get(field), f"Verse {v.get('ref', '?')} missing field: {field}"

    def test_canonical_schema(self, verses):
        """Verify the canonical schema fields are present."""
        expected_keys = {"chapter", "verse", "ref", "chapter_name", "sanskrit",
                         "transliteration", "translation", "translation_hi", "tags", "source"}
        first = verses[0]
        actual_keys = set(first.keys())
        missing = expected_keys - actual_keys
        assert not missing, f"Missing schema fields: {missing}"

    def test_chapter_names_present(self, verses):
        """Each verse should have a chapter_name."""
        missing = [v["ref"] for v in verses if not v.get("chapter_name")]
        assert len(missing) == 0, f"{len(missing)} verses missing chapter_name"

    def test_chapter_verse_counts(self, verses):
        """Verify per-chapter verse counts match known Gita structure."""
        from collections import Counter
        expected = {
            1: 47, 2: 72, 3: 43, 4: 42, 5: 29, 6: 47,
            7: 30, 8: 28, 9: 34, 10: 42, 11: 55, 12: 20,
            13: 35, 14: 27, 15: 20, 16: 24, 17: 28, 18: 78,
        }
        actual = Counter(v["chapter"] for v in verses)
        for ch in range(1, 19):
            # Allow +/-1 for Ch.13 scholarly variation
            assert abs(actual[ch] - expected[ch]) <= 1, \
                f"Chapter {ch}: expected ~{expected[ch]}, got {actual[ch]}"


# ---------------------------------------------------------------------------
# Semantic retrieval regression tests
# ---------------------------------------------------------------------------


class TestSemanticRetrieval:
    def test_anxiety_and_restless_mind(self, provider, verse_embeddings):
        """Query about anxiety should surface mindfulness/peace verses."""
        results = top_k_refs(provider, verse_embeddings, "How to deal with anxiety and restless mind?")
        # 6.26 = mindfulness/focus/meditation, 2.70 = peace/steadiness, 6.34/6.35
        anxiety_verses = {"6.26", "2.70", "6.34", "6.35", "6.5"}
        assert any(r in anxiety_verses for r in results), f"Expected anxiety-related verse in top-5, got {results}"

    def test_duty_in_life(self, provider, verse_embeddings):
        """Query about duty should surface the karma yoga verse."""
        results = top_k_refs(provider, verse_embeddings, "What is my duty in life?")
        duty_verses = {"2.47", "3.35", "2.31", "3.8", "18.47"}
        assert any(r in duty_verses for r in results), f"Expected duty-related verse in top-5, got {results}"

    def test_surrender_to_god(self, provider, verse_embeddings):
        """Query about surrender should surface surrender verses."""
        results = top_k_refs(provider, verse_embeddings, "How to surrender to God?")
        surrender_verses = {"18.66", "3.30", "9.27", "12.6", "18.62"}
        assert any(r in surrender_verses for r in results), f"Expected surrender verse in top-5, got {results}"

    def test_compassion(self, provider, verse_embeddings):
        """Query about compassion should surface the compassion verse."""
        results = top_k_refs(provider, verse_embeddings, "How to be compassionate to others?")
        compassion_verses = {"12.13", "12.14", "16.2", "6.32"}
        assert any(r in compassion_verses for r in results), f"Expected compassion verse in top-5, got {results}"

    def test_meditation_and_focus(self, provider, verse_embeddings):
        """Query about meditation should surface meditation/focus verses."""
        results = top_k_refs(provider, verse_embeddings, "How to meditate and concentrate?")
        meditation_verses = {"6.26", "6.5", "6.10", "6.11", "6.12", "6.13", "6.25", "8.8"}
        assert any(r in meditation_verses for r in results), f"Expected meditation verse in top-5, got {results}"

    def test_death_and_afterlife(self, provider, verse_embeddings):
        """Query about death should surface relevant verses."""
        results = top_k_refs(provider, verse_embeddings, "What happens after death?")
        death_verses = {"2.22", "2.20", "2.13", "8.5", "8.6", "15.8"}
        assert any(r in death_verses for r in results), f"Expected death-related verse in top-5, got {results}"

    def test_anger_management(self, provider, verse_embeddings):
        """Query about anger should surface relevant verses."""
        results = top_k_refs(provider, verse_embeddings, "How to control anger?")
        anger_verses = {"2.62", "2.63", "5.26", "16.21", "16.1", "16.2"}
        assert any(r in anger_verses for r in results), f"Expected anger-related verse in top-5, got {results}"

    def test_embedding_dimension(self, provider):
        """Verify the embedding dimension is 384 (MiniLM-L6-v2)."""
        vec = provider.embed("test")
        assert len(vec) == 384

    def test_embeddings_are_normalized(self, provider):
        """Verify embeddings are L2-normalized."""
        vec = provider.embed("yoga is excellence in action")
        norm = math.sqrt(sum(v * v for v in vec))
        assert abs(norm - 1.0) < 0.01, f"Expected unit norm, got {norm}"
