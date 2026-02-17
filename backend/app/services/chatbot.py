import json
import logging
from collections.abc import Sequence
from typing import Literal, Protocol

import httpx
from pydantic import ValidationError

from ..models import Verse
from ..schemas import ChatResponse, ChatTurn, GuidanceVerse
from .guidance import extract_json

logger = logging.getLogger(__name__)


class ChatProvider(Protocol):
    def generate(
        self,
        *,
        message: str,
        mode: Literal["comfort", "clarity"],
        history: Sequence[ChatTurn],
        verses: Sequence[Verse],
    ) -> ChatResponse:
        ...


def _build_verse_payload(verses: Sequence[Verse], mode: Literal["comfort", "clarity"]) -> list[GuidanceVerse]:
    payload: list[GuidanceVerse] = []
    for verse in verses[:3]:
        reason = (
            "This verse helps with emotional steadiness."
            if mode == "comfort"
            else "This verse supports clear action and discernment."
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


class MockChatProvider:
    def generate(
        self,
        *,
        message: str,
        mode: Literal["comfort", "clarity"],
        history: Sequence[ChatTurn],
        verses: Sequence[Verse],
    ) -> ChatResponse:
        verse_payload = _build_verse_payload(verses, mode)
        primary_ref = verse_payload[0].ref
        tone = (
            "You are not alone in this. Let us make this gentle and practical."
            if mode == "comfort"
            else "Let us simplify this into one clear, disciplined next move."
        )
        return ChatResponse(
            mode=mode,
            reply=(
                f"{tone} Your question was: '{message}'. "
                f"Begin with verse {primary_ref}, then apply one concrete action in the next hour."
            ),
            verses=verse_payload,
            action_step="Pause for one minute, read the first verse once, then complete one focused task immediately.",
            reflection_prompt="What can I do now with sincerity, without clinging to the result?",
            safety={"flagged": False, "message": None},
        )


class GeminiChatProvider:
    def __init__(self, *, api_key: str, model: str, fallback: ChatProvider):
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
        url = f"https://generativelanguage.googleapis.com/v1beta/models/{self.model}:generateContent"
        payload = {
            "contents": [{"parts": [{"text": prompt}]}],
            "generationConfig": {"temperature": 0.2, "responseMimeType": "application/json"},
        }
        try:
            response = httpx.post(url, params={"key": self.api_key}, json=payload, timeout=35.0)
            response.raise_for_status()
            text = response.json()["candidates"][0]["content"]["parts"][0]["text"]
            parsed = json.loads(extract_json(text))
            return ChatResponse.model_validate(parsed)
        except (httpx.HTTPError, KeyError, IndexError, json.JSONDecodeError, ValidationError) as exc:
            logger.warning("Gemini chat failed, falling back to mock provider: %s", exc)
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
            "You are a Bhagavad Gita chatbot. Use only provided verses and never invent verse references. "
            "Keep tone practical, warm, and concise. Return strict JSON only.\n"
            f"Schema: {json.dumps(schema)}\n"
            f"Mode: {mode}\n"
            f"Conversation history JSON: {json.dumps(_serialize_history(history), ensure_ascii=True)}\n"
            f"User message: {message}\n"
            f"Available verses JSON: {json.dumps(verses_payload, ensure_ascii=True)}"
        )


class OllamaChatProvider:
    def __init__(self, *, base_url: str, model: str, fallback: ChatProvider):
        self.base_url = base_url.rstrip("/")
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
        url = f"{self.base_url}/api/generate"
        payload = {
            "model": self.model,
            "prompt": prompt,
            "stream": False,
            "options": {"temperature": 0.2},
        }
        try:
            response = httpx.post(url, json=payload, timeout=60.0)
            response.raise_for_status()
            raw_text = response.json().get("response", "")
            parsed = json.loads(extract_json(raw_text))
            return ChatResponse.model_validate(parsed)
        except (httpx.HTTPError, KeyError, json.JSONDecodeError, ValidationError) as exc:
            logger.warning("Ollama chat failed, falling back to mock provider: %s", exc)
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
        return (
            "You are a Bhagavad Gita guidance chatbot.\n"
            "Rules:\n"
            "1) Use only verses in Available verses JSON.\n"
            "2) Do not invent verse numbers.\n"
            "3) Return strict JSON only in this structure:\n"
            '{"mode":"comfort|clarity","reply":"...","verses":[{"ref":"2.47","sanskrit":"...","transliteration":"...","translation":"...","why_this":"..."}],"action_step":"...","reflection_prompt":"...","safety":{"flagged":false,"message":null}}\n'
            f"Mode: {mode}\n"
            f"Conversation history JSON: {json.dumps(_serialize_history(history), ensure_ascii=True)}\n"
            f"User message: {message}\n"
            f"Available verses JSON: {json.dumps(verses_payload, ensure_ascii=True)}\n"
        )

