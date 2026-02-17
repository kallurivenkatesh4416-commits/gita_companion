"""Query router — classifies queries to pick the best LLM provider."""

import logging
from typing import Literal

logger = logging.getLogger(__name__)

ModelChoice = Literal["claude", "codex"]

CODEX_KEYWORDS: list[str] = [
    "code", "function", "bug", "error", "script",
    "python", "javascript", "debug", "syntax",
    "algorithm", "compile", "runtime", "api",
    "class", "method", "variable", "loop",
]

CLAUDE_KEYWORDS: list[str] = [
    "gita", "verse", "dharma", "karma", "life",
    "advice", "anxiety", "purpose", "duty", "peace",
    "krishna", "arjuna", "spiritual", "meditation",
    "fear", "sorrow", "yoga", "soul", "atman",
    "mind", "suffering", "detachment", "devotion",
    "compassion", "gratitude", "anger", "healing",
    "mood", "overwhelmed", "unmotivated", "hopeful",
    "surrender", "action", "equanimity", "self",
]


def route_query(query: str, default: ModelChoice = "claude") -> ModelChoice:
    """Return 'claude' or 'codex' based on keyword analysis.

    Scoring: each keyword hit adds 1 point to its category.
    If tied or no hits, falls back to *default* (configurable via DEFAULT_LLM env var).
    """
    query_lower = query.lower()

    codex_score = sum(1 for kw in CODEX_KEYWORDS if kw in query_lower)
    claude_score = sum(1 for kw in CLAUDE_KEYWORDS if kw in query_lower)

    if codex_score > claude_score:
        choice: ModelChoice = "codex"
    elif claude_score > codex_score:
        choice = "claude"
    else:
        choice = default

    logger.info(
        "route_decision",
        extra={
            "query_preview": query[:80],
            "claude_score": claude_score,
            "codex_score": codex_score,
            "routed_to": choice,
        },
    )
    return choice
