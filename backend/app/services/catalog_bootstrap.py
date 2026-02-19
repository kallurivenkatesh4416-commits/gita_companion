from typing import Any

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from ..models import Verse


def ensure_verse_catalog(db: Session) -> dict[str, Any]:
    total = db.scalar(select(func.count(Verse.id)))
    chapter_counts = dict(
        db.execute(
            select(Verse.chapter, func.count(Verse.id))
            .group_by(Verse.chapter)
            .order_by(Verse.chapter)
        ).all()
    )
    seeded = False
    before_total = int(total or 0)
    before_chapters = len(
        [chapter for chapter, count in chapter_counts.items() if (count or 0) > 0]
    )
    return {
        "seeded": seeded,
        "source": "none",
        "before_total": before_total,
        "before_chapters": before_chapters,
        "after_total": before_total,
        "after_chapters": before_chapters,
    }
