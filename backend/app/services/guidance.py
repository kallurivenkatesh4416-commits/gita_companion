import json
import logging
from collections.abc import Sequence
from typing import Literal, Protocol

import httpx
from pydantic import ValidationError

from ..models import Verse
from ..schemas import GuidanceResponse, GuidanceVerse

logger = logging.getLogger(__name__)


class GuidanceProvider(Protocol):
    def generate(self, *, topic: str, mode: Literal["comfort", "clarity"], verses: Sequence[Verse]) -> GuidanceResponse:
        ...


def _build_verse_payload(verses: Sequence[Verse], mode: Literal["comfort", "clarity"]) -> list[GuidanceVerse]:
    payload: list[GuidanceVerse] = []
    for verse in verses[:3]:
        reason = (
            "This verse supports emotional steadiness and self-awareness."
            if mode == "comfort"
            else "This verse supports disciplined action and clear thinking."
        )
        payload.append(
            GuidanceVerse(
                ref=verse.ref,
                sanskrit=verse.sanskrit,
                transliteration=verse.transliteration,
                translation=verse.translation,
                why_this=reason,
            )
        )
    return payload


class MockProvider:
    def generate(self, *, topic: str, mode: Literal["comfort", "clarity"], verses: Sequence[Verse]) -> GuidanceResponse:
        verse_payload = _build_verse_payload(verses, mode)

        tone_line = (
            "Take one small gentle step and steady your breath."
            if mode == "comfort"
            else "Choose the next right action and execute it with focus."
        )

        return GuidanceResponse(
            mode=mode,
            topic=topic,
            verses=verse_payload,
            guidance_short=tone_line,
            guidance_long=(
                "Anchor attention in what is in your control. "
                "Read one verse slowly, notice one practical lesson, and apply it to the next hour."
            ),
            micro_practice={
                "title": "One-Minute Grounding",
                "steps": [
                    "Inhale for 4 counts, exhale for 6 counts, repeat five times.",
                    "Read the first selected verse once and name one action you can do now.",
                ],
                "duration_minutes": 1,
            },
            reflection_prompt="What is one action I can complete today without attachment to the outcome?",
            safety={"flagged": False, "message": None},
        )


class GeminiProvider:
    def __init__(self, api_key: str, model: str, fallback: GuidanceProvider):
        self.api_key = api_key
        self.model = model
        self.fallback = fallback

    def generate(self, *, topic: str, mode: Literal["comfort", "clarity"], verses: Sequence[Verse]) -> GuidanceResponse:
        prompt = self._build_prompt(topic=topic, mode=mode, verses=verses)
        url = f"https://generativelanguage.googleapis.com/v1beta/models/{self.model}:generateContent"

        payload = {
            "contents": [{"parts": [{"text": prompt}]}],
            "generationConfig": {
                "temperature": 0.2,
                "responseMimeType": "application/json",
            },
        }

        try:
            response = httpx.post(url, params={"key": self.api_key}, json=payload, timeout=30.0)
            response.raise_for_status()
            text = response.json()["candidates"][0]["content"]["parts"][0]["text"]
            parsed = json.loads(extract_json(text))
            return GuidanceResponse.model_validate(parsed)
        except (httpx.HTTPError, KeyError, IndexError, json.JSONDecodeError, ValidationError) as exc:
            logger.warning("Falling back to mock provider after Gemini failure: %s", exc)
            return self.fallback.generate(topic=topic, mode=mode, verses=verses)

    def _build_prompt(self, *, topic: str, mode: str, verses: Sequence[Verse]) -> str:
        verse_text = []
        for verse in verses[:3]:
            verse_text.append(
                {
                    "ref": verse.ref,
                    "sanskrit": verse.sanskrit,
                    "transliteration": verse.transliteration,
                    "translation": verse.translation,
                }
            )

        schema = {
            "mode": "comfort|clarity",
            "topic": "string",
            "verses": [
                {
                    "ref": "2.47",
                    "sanskrit": "...",
                    "transliteration": "...",
                    "translation": "...",
                    "why_this": "...",
                }
            ],
            "guidance_short": "string",
            "guidance_long": "string",
            "micro_practice": {
                "title": "string",
                "steps": ["...", "..."],
                "duration_minutes": 1,
            },
            "reflection_prompt": "string",
            "safety": {"flagged": False, "message": None},
        }

        return (
            "You are a Bhagavad Gita guidance assistant. Use only the supplied verses. "
            "Do not invent verse references. Return strict JSON only with this schema: "
            f"{json.dumps(schema)}\n\n"
            f"Mode: {mode}\n"
            f"Topic: {topic}\n"
            f"Available verses JSON: {json.dumps(verse_text, ensure_ascii=True)}"
        )


def extract_json(text: str) -> str:
    start = text.find("{")
    end = text.rfind("}")
    if start == -1 or end == -1 or end <= start:
        raise json.JSONDecodeError("No JSON object found", text, 0)
    return text[start : end + 1]
