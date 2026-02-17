"""LLM Orchestrator — routes queries, handles failover, logs decisions."""

import json
import logging
import os
import time
from collections.abc import Sequence
from pathlib import Path
from typing import Any, Literal

from ..models import Verse
from ..schemas import ChatResponse, ChatTurn, GuidanceResponse
from .router import ModelChoice, route_query

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Routing log — append-only JSON-lines file
# ---------------------------------------------------------------------------
LOG_DIR = Path(__file__).resolve().parents[3] / "logs"
ROUTING_LOG = LOG_DIR / "routing.log"


def _ensure_log_dir() -> None:
    LOG_DIR.mkdir(parents=True, exist_ok=True)


def _log_routing(entry: dict[str, Any]) -> None:
    try:
        _ensure_log_dir()
        with ROUTING_LOG.open("a", encoding="utf-8") as fh:
            fh.write(json.dumps(entry, ensure_ascii=True) + "\n")
    except OSError as exc:
        logger.warning("Could not write routing log: %s", exc)


# ---------------------------------------------------------------------------
# Health tracking for each provider
# ---------------------------------------------------------------------------
class _ProviderHealth:
    def __init__(self) -> None:
        self.healthy: bool = True
        self.last_error: str | None = None
        self.last_checked: float = 0.0

    def mark_ok(self) -> None:
        self.healthy = True
        self.last_error = None
        self.last_checked = time.time()

    def mark_failed(self, reason: str) -> None:
        self.healthy = False
        self.last_error = reason
        self.last_checked = time.time()

    def to_dict(self) -> dict[str, Any]:
        return {
            "healthy": self.healthy,
            "last_error": self.last_error,
            "last_checked_epoch": self.last_checked,
        }


# ---------------------------------------------------------------------------
# Orchestrator
# ---------------------------------------------------------------------------
class LLMOrchestrator:
    """Central orchestrator that routes queries and handles failover.

    Provider maps:
        guidance_providers  — {model_name: provider} for /ask and /moods/guidance
        chat_providers      — {model_name: provider} for /chat
    """

    def __init__(
        self,
        guidance_providers: dict[str, Any],
        chat_providers: dict[str, Any],
        default_llm: ModelChoice = "claude",
    ):
        self.guidance_providers = guidance_providers
        self.chat_providers = chat_providers
        self.default_llm: ModelChoice = default_llm
        self._health: dict[str, _ProviderHealth] = {}
        for name in set(list(guidance_providers) + list(chat_providers)):
            self._health[name] = _ProviderHealth()

    # -- public helpers -----------------------------------------------------

    def model_status(self) -> dict[str, Any]:
        return {name: health.to_dict() for name, health in self._health.items()}

    # -- guidance -----------------------------------------------------------

    def generate_guidance(
        self,
        *,
        topic: str,
        mode: Literal["comfort", "clarity"],
        verses: Sequence[Verse],
    ) -> tuple[GuidanceResponse, str]:
        """Returns (response, model_used)."""
        chosen = route_query(topic, default=self.default_llm)
        order = self._failover_order(chosen, list(self.guidance_providers))

        start = time.perf_counter()
        for model_name in order:
            provider = self.guidance_providers.get(model_name)
            if provider is None:
                continue
            try:
                result = provider.generate(topic=topic, mode=mode, verses=verses)
                elapsed_ms = round((time.perf_counter() - start) * 1000, 2)
                self._health[model_name].mark_ok()
                self._log("guidance", topic, model_name, chosen, elapsed_ms, success=True)
                return result, model_name
            except Exception as exc:
                self._health[model_name].mark_failed(str(exc))
                logger.warning("Orchestrator: %s guidance failed — %s", model_name, exc)

        # all providers failed — last-resort mock is always in the providers map
        elapsed_ms = round((time.perf_counter() - start) * 1000, 2)
        self._log("guidance", topic, "mock", chosen, elapsed_ms, success=False)
        raise RuntimeError("All guidance providers failed")

    # -- chat ---------------------------------------------------------------

    def generate_chat(
        self,
        *,
        message: str,
        mode: Literal["comfort", "clarity"],
        history: Sequence[ChatTurn],
        verses: Sequence[Verse],
    ) -> tuple[ChatResponse, str]:
        """Returns (response, model_used)."""
        chosen = route_query(message, default=self.default_llm)
        order = self._failover_order(chosen, list(self.chat_providers))

        start = time.perf_counter()
        for model_name in order:
            provider = self.chat_providers.get(model_name)
            if provider is None:
                continue
            try:
                result = provider.generate(message=message, mode=mode, history=history, verses=verses)
                elapsed_ms = round((time.perf_counter() - start) * 1000, 2)
                self._health[model_name].mark_ok()
                self._log("chat", message, model_name, chosen, elapsed_ms, success=True)
                return result, model_name
            except Exception as exc:
                self._health[model_name].mark_failed(str(exc))
                logger.warning("Orchestrator: %s chat failed — %s", model_name, exc)

        elapsed_ms = round((time.perf_counter() - start) * 1000, 2)
        self._log("chat", message, "mock", chosen, elapsed_ms, success=False)
        raise RuntimeError("All chat providers failed")

    # -- internals ----------------------------------------------------------

    @staticmethod
    def _failover_order(primary: str, available: list[str]) -> list[str]:
        """Put *primary* first, then everything else in original order."""
        order = [primary]
        for name in available:
            if name != primary:
                order.append(name)
        return order

    def _log(
        self,
        endpoint: str,
        query: str,
        model_used: str,
        routed_to: str,
        elapsed_ms: float,
        *,
        success: bool,
    ) -> None:
        entry = {
            "ts": time.time(),
            "endpoint": endpoint,
            "query_preview": query[:100],
            "routed_to": routed_to,
            "model_used": model_used,
            "response_time_ms": elapsed_ms,
            "success": success,
        }
        _log_routing(entry)
