"""One-time offline script to regenerate all verse embeddings in-place.

Usage:
    python scripts/build_embeddings.py
    python scripts/build_embeddings.py --provider hash
"""

import argparse
import sys
from pathlib import Path

from sqlalchemy import func, select

APP_ROOT = Path(__file__).resolve().parents[1]
if str(APP_ROOT) not in sys.path:
    sys.path.insert(0, str(APP_ROOT))

from app.config import get_settings
from app.db import SessionLocal, init_db
from app.models import Verse
from app.services.embeddings import create_embedding_provider


def validate_db(db) -> None:
    """Verify database has expected verse count and chapter coverage."""
    total = db.scalar(select(func.count(Verse.id))) or 0
    chapters = db.execute(select(Verse.chapter).distinct()).scalars().all()

    print(f'Database: {total} verses across {len(chapters)} chapters')

    if total in (700, 701) and len(chapters) == 18:
        print(f'Validation PASSED: Full {total}-verse / 18-chapter dataset')
    elif total < 700:
        print(f'Note: Partial dataset ({total} verses). Full dataset has 700.')
    elif total > 700:
        print(f'WARNING: More than 700 verses found ({total}). Check for duplicates.')


def main() -> None:
    parser = argparse.ArgumentParser(description='Rebuild embeddings for all verses')
    parser.add_argument(
        '--provider',
        choices=['sentence_transformer', 'hash'],
        default=None,
        help='Embedding provider override (default: use config)',
    )
    parser.add_argument(
        '--validate-only',
        action='store_true',
        help='Only validate the database, do not rebuild embeddings',
    )
    args = parser.parse_args()

    settings = get_settings()
    init_db()

    with SessionLocal() as db:
        validate_db(db)

        if args.validate_only:
            return

        provider_type = args.provider or settings.embedding_provider
        embedder = create_embedding_provider(
            provider_type=provider_type,
            model_name=settings.embedding_model,
            dimension=settings.embedding_dim,
        )
        print(f'Using embedding provider: {type(embedder).__name__} (dim={embedder.dimension})')

        verses = list(db.execute(select(Verse)).scalars().all())
        if not verses:
            print('No verses found in database. Run seed_data.py first.')
            return

        print(f'Rebuilding embeddings for {len(verses)} verses...')

        for i, verse in enumerate(verses, 1):
            embedding_input = ' '.join([
                verse.ref,
                verse.transliteration or '',
                verse.translation,
                ' '.join(verse.tags or []),
            ])
            verse.embedding = list(embedder.embed(embedding_input))
            if i % 50 == 0:
                print(f'  [{i}/{len(verses)}] done')

        db.commit()
        print(f'\nDone. Updated embeddings for {len(verses)} verses.')


if __name__ == '__main__':
    main()
