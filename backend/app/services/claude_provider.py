import json
import logging
from collections.abc import Sequence

import httpx
from pydantic import ValidationError

from ..models import Verse
from ..schemas import ChatResponse, ChatTurn, GuidanceMode, GuidanceResponse, LanguageCode
from .guidance import extract_json
from .language import language_instruction
from .persona import wants_krishna_voice

logger = logging.getLogger(__name__)

ANTHROPIC_API_URL = "https://api.anthropic.com/v1/messages"


def _serialize_history(history: Sequence[ChatTurn]) -> list[dict[str, str]]:
    return [{"role": turn.role, "content": turn.content} for turn in history[-12:]]


def _mode_style_instruction(
    mode: GuidanceMode,
    *,
    prefer_krishna_voice: bool = False,
) -> str:
    if prefer_krishna_voice:
        return (
            "Voice: speak in first-person Krishna voice, compassionate and steady, "
            "with practical dharma guidance and no fabricated claims."
        )
    if mode == "comfort":
        return "Style: warm, reassuring, and concise."
    if mode == "clarity":
        return "Style: direct, concise, and action-focused."
    return (
        "Style: traditional Bhagavad Gita voice, respectful and dharma-centered, "
        "with moderately detailed explanation."
    )


class ClaudeProvider:
    """Guidance provider using Anthropic Claude API."""

    def __init__(self, api_key: str, model: str, fallback):
        self.api_key = api_key
        self.model = model
        self.fallback = fallback

    def generate(
        self,
        *,
        topic: str,
        mode: GuidanceMode,
        language: LanguageCode,
        verses: Sequence[Verse],
    ) -> GuidanceResponse:
        prompt = self._build_prompt(topic=topic, mode=mode, language=language, verses=verses)
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
            return self.fallback.generate(topic=topic, mode=mode, language=language, verses=verses)

    def _build_prompt(
        self,
        *,
        topic: str,
        mode: GuidanceMode,
        language: LanguageCode,
        verses: Sequence[Verse],
    ) -> str:
        verse_text = [
            {
                "verse_id": verse.id,
                "ref": verse.ref,
                "sanskrit": verse.sanskrit,
                "transliteration": verse.transliteration,
                "translation": verse.translation,
            }
            for verse in verses[:3]
        ]

        schema = {
            "mode": "comfort|clarity|traditional",
            "topic": "string",
            "verses": [
                {
                    "verse_id": 47,
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
            "Return strict JSON only - no markdown fences and no explanation outside JSON. "
            f"Schema: {json.dumps(schema)}\n\n"
            f"{language_instruction(language)}\n"
            f"{_mode_style_instruction(mode)}\n"
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
        mode: GuidanceMode,
        language: LanguageCode,
        history: Sequence[ChatTurn],
        verses: Sequence[Verse],
    ) -> ChatResponse:
        prefer_krishna_voice = mode == "traditional" or wants_krishna_voice(
            message,
            [turn.content for turn in history if turn.role == "user"],
        )
        prompt = self._build_prompt(
            message=message,
            mode=mode,
            language=language,
            history=history,
            verses=verses,
            prefer_krishna_voice=prefer_krishna_voice,
        )
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
            return self.fallback.generate(
                message=message,
                mode=mode,
                language=language,
                history=history,
                verses=verses,
            )

    def _build_prompt(
        self,
        *,
        message: str,
        mode: GuidanceMode,
        language: LanguageCode,
        history: Sequence[ChatTurn],
        verses: Sequence[Verse],
        prefer_krishna_voice: bool,
    ) -> str:
        verses_payload = [
            {
                "verse_id": verse.id,
                "ref": verse.ref,
                "sanskrit": verse.sanskrit,
                "transliteration": verse.transliteration,
                "translation": verse.translation,
            }
            for verse in verses[:3]
        ]
        schema = {
            "mode": "comfort|clarity|traditional",
            "reply": "string",
            "verses": [
                {
                    "verse_id": 47,
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
            "Return strict JSON only - no markdown fences.\n"
            f"Schema: {json.dumps(schema)}\n"
            f"{language_instruction(language)}\n"
            f"{_mode_style_instruction(mode, prefer_krishna_voice=prefer_krishna_voice)}\n"
            f"Mode: {mode}\n"
            f"Conversation history JSON: {json.dumps(_serialize_history(history), ensure_ascii=True)}\n"
            f"User message: {message}\n"
            f"Available verses JSON: {json.dumps(verses_payload, ensure_ascii=True)}"
        )
