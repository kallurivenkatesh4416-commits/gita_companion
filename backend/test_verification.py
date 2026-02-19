"""Basic tests for verification level logic."""

import os
import sys
import unittest
from dataclasses import dataclass

sys.path.insert(0, os.path.dirname(__file__))

from app.schemas import GuidanceVerse
from app.services.verification import verify_answer


@dataclass(frozen=True)
class VerseStub:
    id: int
    chapter: int
    verse_number: int
    ref: str
    sanskrit: str
    translation: str


def _verse(
    *,
    verse_id: int,
    chapter: int,
    verse_number: int,
    ref: str,
    sanskrit: str,
    translation: str,
) -> VerseStub:
    return VerseStub(
        id=verse_id,
        chapter=chapter,
        verse_number=verse_number,
        ref=ref,
        sanskrit=sanskrit,
        translation=translation,
    )


class VerificationTests(unittest.TestCase):
    def test_verified_when_all_three_gates_pass(self) -> None:
        retrieved = [
            _verse(
                verse_id=1,
                chapter=2,
                verse_number=47,
                ref='2.47',
                sanskrit='karmany evadhikaras te',
                translation='You have a right to action, never to fruits.',
            )
        ]
        response_verses = [
            GuidanceVerse(
                verse_id=1,
                ref='2.47',
                sanskrit='karmany evadhikaras te',
                transliteration='karmany evadhikaras te',
                translation='You have a right to action, never to fruits.',
                why_this='Grounding verse',
            )
        ]
        result = verify_answer(
            answer_text='As verse 2.47 teaches, focus on action and release attachment to results.',
            response_verses=response_verses,
            retrieved_verses=retrieved,
        )

        self.assertEqual(result.level, 'VERIFIED')
        self.assertTrue(all(check.passed for check in result.checks))
        self.assertGreaterEqual(len(result.provenance), 1)

    def test_raw_when_citation_gate_fails(self) -> None:
        retrieved = [
            _verse(
                verse_id=1,
                chapter=2,
                verse_number=47,
                ref='2.47',
                sanskrit='karmany evadhikaras te',
                translation='You have a right to action, never to fruits.',
            )
        ]
        response_verses = [
            GuidanceVerse(
                verse_id=999,
                ref='99.1',
                sanskrit='nakli shlok',
                transliteration='nakli shlok',
                translation='Fabricated verse',
                why_this='Invalid citation',
            )
        ]
        result = verify_answer(
            answer_text='Do this because verse 99.1 says so.',
            response_verses=response_verses,
            retrieved_verses=retrieved,
        )

        citation_check = next(check for check in result.checks if check.name == 'citation_integrity')
        self.assertEqual(result.level, 'RAW')
        self.assertFalse(citation_check.passed)


if __name__ == '__main__':
    unittest.main()
