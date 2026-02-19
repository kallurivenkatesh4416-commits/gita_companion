from typing import Any

import logging
from sqlalchemy import func, select
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from ..models import Verse

logger = logging.getLogger(__name__)


def _chapter_stats(db: Session) -> tuple[int, int]:
    chapter_counts = dict(
        db.execute(
            select(Verse.chapter, func.count(Verse.id))
            .group_by(Verse.chapter)
            .order_by(Verse.chapter)
        ).all()
    )
    total = sum(int(count or 0) for count in chapter_counts.values())
    chapters = sum(1 for count in chapter_counts.values() if (count or 0) > 0)
    return total, chapters


def ensure_verse_catalog(db: Session) -> dict[str, Any]:
    result = {
        "seeded": False,
        "source": "noop",
        "before_total": 0,
        "before_chapters": 0,
        "after_total": 0,
        "after_chapters": 0,
    }
    try:
        before_total, before_chapters = _chapter_stats(db)
        result.update(
            {
                "before_total": before_total,
                "before_chapters": before_chapters,
                "after_total": before_total,
                "after_chapters": before_chapters,
            }
        )
        if before_total > 0:
            result["source"] = "db_only"
    except SQLAlchemyError:
        logger.exception("ensure_verse_catalog failed to read verse counts")
    except Exception:
        logger.exception("ensure_verse_catalog hit an unexpected error")
    return result
