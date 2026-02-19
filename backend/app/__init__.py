"""Backend app package."""

from typing import Any

__all__ = ['app']


def __getattr__(name: str) -> Any:
    if name == 'app':
        from .main import app as fastapi_app

        return fastapi_app
    raise AttributeError(name)
