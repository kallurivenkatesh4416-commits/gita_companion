import json
import logging
from collections.abc import Sequence
from typing import Literal

import httpx
from pydantic import ValidationError

from ..models import Verse
from ..schemas import ChatResponse, ChatTurn, GuidanceResponse, LanguageCode
from .guidance import extract_json
from .language import language_instruction

logger = logging.getLogger(__name__)

OPENAI_API_URL = "https://api.openai.com/v1/chat/completions"


def _serialize_history(history: Sequence[ChatTurn]) -> list[dict[str, str]]:
    return [{"role": turn.role, "content": turn.content} for turn in history[-12:]]


class CodexGuidanceProvider:
    """Guidance provider using OpenAI API (GPT/Codex models)."""

    def __init__(self, api_key: str, model: str, fallback):
        self.api_key = api_key
        self.model = model
        self.fallback = fallback

    def generate(
        self,
        *,
        topic: str,
        mode: Literal["comfort", "clarity"],
        language: LanguageCode,
        verses: Sequence[Verse],
    ) -> GuidanceResponse:
        prompt = self._build_prompt(topic=topic, mode=mode, language=language, verses=verses)
        try:
            response = httpx.post(
                OPENAI_API_URL,
                headers={
                    "Authorization": f"Bearer {self.api_key}",
                    "Content-Type": "application/json",
                },
                json={
                    "model": self.model,
                    "temperature": 0.2,
                    "max_tokens": 1024,
                    "messages": [
                        {
                            "role": "system",
                            "content": "You are a Bhagavad Gita guidance assistant. Return strict JSON only.",
                        },
                        {"role": "user", "content": prompt},
                    ],
                },
                timeout=30.0,
            )
            response.raise_for_status()
            text = response.json()["choices"][0]["message"]["content"]
            parsed = json.loads(extract_json(text))
            return GuidanceResponse.model_validate(parsed)
        except (httpx.HTTPError, KeyError, IndexError, json.JSONDecodeError, ValidationError) as exc:
            logger.warning("Codex/OpenAI guidance failed, falling back: %s", exc)
            return self.fallback.generate(topic=topic, mode=mode, language=language, verses=verses)

    def _build_prompt(
        self,
        *,
        topic: str,
        mode: str,
        language: LanguageCode,
        verses: Sequence[Verse],
    ) -> str:
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
            "Use only the supplied verses. Do not invent verse references. "
            f"Return strict JSON matching this schema: {json.dumps(schema)}\n\n"
            f"{language_instruction(language)}\n"
            f"Mode: {mode}\nTopic: {topic}\n"
            f"Available verses JSON: {json.dumps(verse_text, ensure_ascii=True)}"
        )


class CodexChatProvider:
    """Chat provider using OpenAI API (GPT/Codex models)."""

    def __init__(self, *, api_key: str, model: str, fallback):
        self.api_key = api_key
        self.model = model
        self.fallback = fallback

    def generate(
        self,
        *,
        message: str,
        mode: Literal["comfort", "clarity"],
        language: LanguageCode,
        history: Sequence[ChatTurn],
        verses: Sequence[Verse],
    ) -> ChatResponse:
        prompt = self._build_prompt(
            message=message,
            mode=mode,
            language=language,
            history=history,
            verses=verses,
        )
        try:
            response = httpx.post(
                OPENAI_API_URL,
                headers={
                    "Authorization": f"Bearer {self.api_key}",
                    "Content-Type": "application/json",
                },
                json={
                    "model": self.model,
                    "temperature": 0.2,
                    "max_tokens": 1024,
                    "messages": [
                        {"role": "system", "content": "You are a Bhagavad Gita chatbot. Return strict JSON only."},
                        {"role": "user", "content": prompt},
                    ],
                },
                timeout=35.0,
            )
            response.raise_for_status()
            text = response.json()["choices"][0]["message"]["content"]
            parsed = json.loads(extract_json(text))
            return ChatResponse.model_validate(parsed)
        except (httpx.HTTPError, KeyError, IndexError, json.JSONDecodeError, ValidationError) as exc:
            logger.warning("Codex/OpenAI chat failed, falling back: %s", exc)
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
        mode: Literal["comfort", "clarity"],
        language: LanguageCode,
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
            "Use only provided verses. Never invent verse references. "
            "Keep tone practical, warm, concise. Return strict JSON only.\n"
            f"Schema: {json.dumps(schema)}\n"
            f"{language_instruction(language)}\n"
            f"Mode: {mode}\n"
            f"Conversation history: {json.dumps(_serialize_history(history), ensure_ascii=True)}\n"
            f"User message: {message}\n"
            f"Available verses: {json.dumps(verses_payload, ensure_ascii=True)}"
        )
