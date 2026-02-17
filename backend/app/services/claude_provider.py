import json
import logging
from collections.abc import Sequence
from typing import Literal, Protocol

import httpx
from pydantic import ValidationError

from ..models import Verse
from ..schemas import ChatResponse, ChatTurn, GuidanceResponse, GuidanceVerse
from .guidance import extract_json

logger = logging.getLogger(__name__)

ANTHROPIC_API_URL = "https://api.anthropic.com/v1/messages"


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


def _serialize_history(history: Sequence[ChatTurn]) -> list[dict[str, str]]:
    return [{"role": turn.role, "content": turn.content} for turn in history[-12:]]


class ClaudeProvider:
    """Guidance provider using Anthropic Claude API."""

    def __init__(self, api_key: str, model: str, fallback):
        self.api_key = api_key
        self.model = model
        self.fallback = fallback

    def generate(self, *, topic: str, mode: Literal["comfort", "clarity"], verses: Sequence[Verse]) -> GuidanceResponse:
        prompt = self._build_prompt(topic=topic, mode=mode, verses=verses)
        try:
            response = httpx.post(
                ANTHROPIC_API_URL,
                headers={
                    "x-api-key": self.api_key,
                    "anthropic-version": "2023-06-01",
                    "content-type": "application/json",
                },
                json={
                    "model": self.model,
                    "max_tokens": 1024,
                    "temperature": 0.2,
                    "messages": [{"role": "user", "content": prompt}],
                },
                timeout=30.0,
            )
            response.raise_for_status()
            text = response.json()["content"][0]["text"]
            parsed = json.loads(extract_json(text))
            return GuidanceResponse.model_validate(parsed)
        except (httpx.HTTPError, KeyError, IndexError, json.JSONDecodeError, ValidationError) as exc:
            logger.warning("Claude guidance failed, falling back: %s", exc)
            return self.fallback.generate(topic=topic, mode=mode, verses=verses)

    def _build_prompt(self, *, topic: str, mode: str, verses: Sequence[Verse]) -> str:
        verse_text = [
            {
                "ref": verse.ref,
                "sanskrit": verse.sanskrit,
                "transliteration": verse.transliteration,
                "translation": verse.translation,
            }
            for verse in verses[:3]
        ]

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
            "guidance_short": "string (max 500 chars)",
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
            "You are a compassionate Bhagavad Gita guidance assistant. "
            "Use only the supplied verses. Do not invent verse references. "
            "Return strict JSON only — no markdown fences, no explanation outside the JSON. "
            f"Schema: {json.dumps(schema)}\n\n"
            f"Mode: {mode}\n"
            f"Topic: {topic}\n"
            f"Available verses JSON: {json.dumps(verse_text, ensure_ascii=True)}"
        )


class ClaudeChatProvider:
    """Chat provider using Anthropic Claude API."""

    def __init__(self, *, api_key: str, model: str, fallback):
        self.api_key = api_key
        self.model = model
        self.fallback = fallback

    def generate(
        self,
        *,
        message: str,
        mode: Literal["comfort", "clarity"],
        history: Sequence[ChatTurn],
        verses: Sequence[Verse],
    ) -> ChatResponse:
        prompt = self._build_prompt(message=message, mode=mode, history=history, verses=verses)
        try:
            response = httpx.post(
                ANTHROPIC_API_URL,
                headers={
                    "x-api-key": self.api_key,
                    "anthropic-version": "2023-06-01",
                    "content-type": "application/json",
                },
                json={
                    "model": self.model,
                    "max_tokens": 1024,
                    "temperature": 0.2,
                    "messages": [{"role": "user", "content": prompt}],
                },
                timeout=35.0,
            )
            response.raise_for_status()
            text = response.json()["content"][0]["text"]
            parsed = json.loads(extract_json(text))
            return ChatResponse.model_validate(parsed)
        except (httpx.HTTPError, KeyError, IndexError, json.JSONDecodeError, ValidationError) as exc:
            logger.warning("Claude chat failed, falling back: %s", exc)
            return self.fallback.generate(message=message, mode=mode, history=history, verses=verses)

    def _build_prompt(
        self,
        *,
        message: str,
        mode: Literal["comfort", "clarity"],
        history: Sequence[ChatTurn],
        verses: Sequence[Verse],
    ) -> str:
        verses_payload = [
            {
                "ref": verse.ref,
                "sanskrit": verse.sanskrit,
                "transliteration": verse.transliteration,
                "translation": verse.translation,
            }
            for verse in verses[:3]
        ]
        schema = {
            "mode": "comfort|clarity",
            "reply": "string",
            "verses": [
                {
                    "ref": "2.47",
                    "sanskrit": "...",
                    "transliteration": "...",
                    "translation": "...",
                    "why_this": "...",
                }
            ],
            "action_step": "string",
            "reflection_prompt": "string",
            "safety": {"flagged": False, "message": None},
        }
        return (
            "You are a compassionate Bhagavad Gita chatbot. "
            "Use only provided verses and never invent verse references. "
            "Keep tone practical, warm, and concise. "
            "Return strict JSON only — no markdown fences.\n"
            f"Schema: {json.dumps(schema)}\n"
            f"Mode: {mode}\n"
            f"Conversation history JSON: {json.dumps(_serialize_history(history), ensure_ascii=True)}\n"
            f"User message: {message}\n"
            f"Available verses JSON: {json.dumps(verses_payload, ensure_ascii=True)}"
        )
