from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


class VerseOut(BaseModel):
    id: int
    chapter: int
    verse_number: int
    ref: str
    sanskrit: str
    transliteration: str
    translation: str
    tags: list[str]

    model_config = ConfigDict(from_attributes=True, extra="forbid")


class GuidanceVerse(BaseModel):
    ref: str
    sanskrit: str
    transliteration: str
    translation: str
    why_this: str

    model_config = ConfigDict(extra="forbid")


class MicroPractice(BaseModel):
    title: str
    steps: list[str] = Field(min_length=1)
    duration_minutes: int = Field(ge=1, le=15)

    model_config = ConfigDict(extra="forbid")


class SafetyMeta(BaseModel):
    flagged: bool = False
    message: str | None = None

    model_config = ConfigDict(extra="forbid")


class GuidanceResponse(BaseModel):
    mode: Literal["comfort", "clarity"]
    topic: str
    verses: list[GuidanceVerse] = Field(min_length=1, max_length=3)
    guidance_short: str = Field(max_length=500)
    guidance_long: str
    micro_practice: MicroPractice
    reflection_prompt: str
    safety: SafetyMeta

    model_config = ConfigDict(extra="forbid")


class AskRequest(BaseModel):
    question: str = Field(min_length=3, max_length=500)
    mode: Literal["comfort", "clarity"] = "clarity"

    model_config = ConfigDict(extra="forbid")


class ChatTurn(BaseModel):
    role: Literal["user", "assistant"]
    content: str = Field(min_length=1, max_length=1000)

    model_config = ConfigDict(extra="forbid")


class ChatRequest(BaseModel):
    message: str = Field(min_length=1, max_length=1000)
    mode: Literal["comfort", "clarity"] = "clarity"
    history: list[ChatTurn] = Field(default_factory=list, max_length=12)

    model_config = ConfigDict(extra="forbid")


class ChatResponse(BaseModel):
    mode: Literal["comfort", "clarity"]
    reply: str
    verses: list[GuidanceVerse] = Field(min_length=1, max_length=3)
    action_step: str
    reflection_prompt: str
    safety: SafetyMeta

    model_config = ConfigDict(extra="forbid")


class MoodGuidanceRequest(BaseModel):
    moods: list[str] = Field(min_length=1, max_length=5)
    note: str | None = Field(default=None, max_length=200)
    mode: Literal["comfort", "clarity"] = "comfort"

    model_config = ConfigDict(extra="forbid")


class MoodOptionsResponse(BaseModel):
    moods: list[str]

    model_config = ConfigDict(extra="forbid")


class FavoriteCreate(BaseModel):
    verse_id: int = Field(gt=0)

    model_config = ConfigDict(extra="forbid")


class FavoriteOut(BaseModel):
    id: int
    verse: VerseOut
    created_at: datetime

    model_config = ConfigDict(from_attributes=True, extra="forbid")


class JourneyOut(BaseModel):
    id: str
    title: str
    description: str
    days: int
    status: Literal["not_started", "in_progress", "completed"]

    model_config = ConfigDict(extra="forbid")
