from __future__ import annotations

import re
from dataclasses import dataclass
from typing import Protocol, Sequence

from ..schemas import GuidanceVerse, ProvenanceVerse, VerificationCheck

_WORD_RE = re.compile(r"[A-Za-z][A-Za-z']+")


@dataclass(frozen=True)
class VerificationResult:
    level: str
    checks: list[VerificationCheck]
    provenance: list[ProvenanceVerse]


class RetrievedVerseLike(Protocol):
    id: int
    chapter: int
    verse_number: int
    sanskrit: str
    translation: str


def verify_answer(
    *,
    answer_text: str,
    response_verses: Sequence[GuidanceVerse],
    retrieved_verses: Sequence[RetrievedVerseLike],
) -> VerificationResult:
    verse_by_id = {verse.id: verse for verse in retrieved_verses}

    cited_ids = [item.verse_id for item in response_verses if item.verse_id is not None]
    cited_in_retrieval = all(verse_id in verse_by_id for verse_id in cited_ids)
    has_citations = len(cited_ids) > 0
    citation_passed = has_citations and cited_in_retrieval
    citation_note = (
        f'{len(cited_ids)} cited verse id(s) map to retrieved context.'
        if citation_passed
        else 'Cited verse ids are missing or do not map to retrieved context.'
    )

    grounding_passed = _is_grounded(answer_text=answer_text, response_verses=response_verses, retrieved_verses=retrieved_verses)
    grounding_note = (
        'Answer references retrieved verse refs/tokens.'
        if grounding_passed
        else 'Answer grounding signals are weak; review is recommended.'
    )

    provenance = _build_provenance(response_verses=response_verses, retrieved_verses=retrieved_verses)
    provenance_passed = len(provenance) > 0
    provenance_note = (
        f'{len(provenance)} provenance verse(s) attached.'
        if provenance_passed
        else 'No provenance verse metadata attached.'
    )

    checks = [
        VerificationCheck(name='citation_integrity', passed=citation_passed, note=citation_note),
        VerificationCheck(name='answer_grounding', passed=grounding_passed, note=grounding_note),
        VerificationCheck(name='provenance_attached', passed=provenance_passed, note=provenance_note),
    ]

    if citation_passed and grounding_passed and provenance_passed:
        level = 'VERIFIED'
    elif citation_passed:
        level = 'REVIEWED'
    else:
        level = 'RAW'

    return VerificationResult(level=level, checks=checks, provenance=provenance)


def _is_grounded(
    *,
    answer_text: str,
    response_verses: Sequence[GuidanceVerse],
    retrieved_verses: Sequence[RetrievedVerseLike],
) -> bool:
    normalized_answer = answer_text.lower()

    # Signal 1: explicit verse references from response payload.
    for verse in response_verses:
        if verse.ref.lower() in normalized_answer:
            return True

    # Signal 2: lightweight lexical overlap with retrieved translation/sanskrit tokens.
    answer_tokens = {token.lower() for token in _WORD_RE.findall(answer_text) if len(token) >= 5}
    if not answer_tokens:
        return False

    verse_tokens: set[str] = set()
    for verse in retrieved_verses:
        verse_tokens.update(token.lower() for token in _WORD_RE.findall(verse.translation) if len(token) >= 5)
        verse_tokens.update(token.lower() for token in _WORD_RE.findall(verse.sanskrit) if len(token) >= 5)

    overlap = answer_tokens & verse_tokens
    return len(overlap) >= 2


def _build_provenance(
    *,
    response_verses: Sequence[GuidanceVerse],
    retrieved_verses: Sequence[RetrievedVerseLike],
) -> list[ProvenanceVerse]:
    verse_by_id = {verse.id: verse for verse in retrieved_verses}
    ordered_ids: list[int] = []
    for verse in response_verses:
        if verse.verse_id is None:
            continue
        if verse.verse_id in verse_by_id and verse.verse_id not in ordered_ids:
            ordered_ids.append(verse.verse_id)

    if not ordered_ids and retrieved_verses:
        ordered_ids.append(retrieved_verses[0].id)

    provenance: list[ProvenanceVerse] = []
    for verse_id in ordered_ids:
        verse = verse_by_id.get(verse_id)
        if verse is None:
            continue
        provenance.append(
            ProvenanceVerse(
                verse_id=verse.id,
                chapter=verse.chapter,
                verse=verse.verse_number,
                sanskrit=verse.sanskrit,
                translation_source='Local Bhagavad Gita dataset',
            )
        )

    return provenance
