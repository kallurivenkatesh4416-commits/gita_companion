import time
from collections.abc import Hashable
from dataclasses import dataclass
from threading import Lock
from typing import Any


@dataclass
class CacheItem:
    value: Any
    expires_at: float


class TTLCache:
    def __init__(self, ttl_seconds: int = 300):
        self.ttl_seconds = ttl_seconds
        self._items: dict[Hashable, CacheItem] = {}
        self._lock = Lock()

    def get(self, key: Hashable) -> Any | None:
        now = time.time()
        with self._lock:
            item = self._items.get(key)
            if item is None:
                return None
            if item.expires_at < now:
                self._items.pop(key, None)
                return None
            return item.value

    def set(self, key: Hashable, value: Any) -> None:
        with self._lock:
            self._items[key] = CacheItem(value=value, expires_at=time.time() + self.ttl_seconds)
