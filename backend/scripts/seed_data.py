import argparse
import json
import sys
from pathlib import Path

from sqlalchemy import func, select
from sqlalchemy.dialects.postgresql import insert

APP_ROOT = Path(__file__).resolve().parents[1]
if str(APP_ROOT) not in sys.path:
    sys.path.insert(0, str(APP_ROOT))

from app.config import get_settings
from app.db import SessionLocal, init_db
from app.models import Verse
from app.services.embeddings import create_embedding_provider

# Canonical data file priority: complete > sample
DATA_FILENAMES = [
    'gita_verses_complete.json',
    'gita_verses_sample.json',
]


def resolve_data_file(cli_path: str | None) -> Path:
    if cli_path:
        candidate = Path(cli_path)
        if candidate.exists():
            return candidate

    for name in DATA_FILENAMES:
        candidates = [
            Path('/data') / name,
            Path(__file__).resolve().parents[2] / 'data' / name,
        ]
        for candidate in candidates:
            if candidate.exists():
                return candidate

    raise FileNotFoundError('Could not find any gita verse JSON file')


def validate_dataset(rows: list[dict]) -> None:
    """Validate dataset structure and completeness."""
    chapters = set(row['chapter'] for row in rows)
    refs = [row.get('ref') or f"{row['chapter']}.{row['verse']}" for row in rows]

    print(f'Dataset: {len(rows)} verses across {len(chapters)} chapters')

    if len(rows) in (700, 701) and len(chapters) == 18:
        print(f'Validation PASSED: Full {len(rows)}-verse / 18-chapter dataset')
    elif len(rows) < 700:
        print(f'Note: Partial dataset ({len(rows)} verses). Full dataset has 700 verses.')

    # Check for duplicates
    if len(refs) != len(set(refs)):
        dupes = [r for r in refs if refs.count(r) > 1]
        raise ValueError(f'Duplicate refs found: {set(dupes)}')

    # Check required fields
    for i, row in enumerate(rows):
        for field in ('chapter', 'verse', 'sanskrit', 'translation'):
            if not row.get(field):
                print(f'  WARN: Row {i} ({row.get("ref", "?")}) missing field: {field}')


def main() -> None:
    parser = argparse.ArgumentParser(description='Seed Bhagavad Gita verses into PostgreSQL')
    parser.add_argument('--file', dest='file_path', default=None, help='Path to verse JSON file')
    parser.add_argument(
        '--provider',
        choices=['sentence_transformer', 'hash'],
        default=None,
        help='Embedding provider override (default: use config)',
    )
    parser.add_argument(
        '--validate-only',
        action='store_true',
        help='Only validate the dataset, do not seed',
    )
    args = parser.parse_args()

    data_file = resolve_data_file(args.file_path)
    print(f'Data file: {data_file}')
    rows = json.loads(data_file.read_text(encoding='utf-8-sig'))
    if not isinstance(rows, list):
        raise ValueError('Input JSON must be a list of verse objects')

    validate_dataset(rows)

    if args.validate_only:
        return

    settings = get_settings()
    provider_type = args.provider or settings.embedding_provider
    embedder = create_embedding_provider(
        provider_type=provider_type,
        model_name=settings.embedding_model,
        dimension=settings.embedding_dim,
    )
    print(f'Using embedding provider: {type(embedder).__name__} (dim={embedder.dimension})')

    init_db()

    with SessionLocal() as db:
        for i, row in enumerate(rows, 1):
            chapter = int(row['chapter'])
            verse_number = int(row['verse'])
            ref = row.get('ref') or f'{chapter}.{verse_number}'
            tags = row.get('tags') or []
            chapter_name = row.get('chapter_name', '')
            translation_hi = row.get('translation_hi', '')
            source = row.get('source')

            embedding_input = ' '.join([
                ref,
                row.get('transliteration', ''),
                row['translation'],
                ' '.join(tags),
            ])
            embedding = list(embedder.embed(embedding_input))

            stmt = insert(Verse).values(
                chapter=chapter,
                verse_number=verse_number,
                ref=ref,
                chapter_name=chapter_name,
                sanskrit=row['sanskrit'],
                transliteration=row.get('transliteration', ''),
                translation=row['translation'],
                translation_hi=translation_hi,
                tags=tags,
                source=source,
                embedding=embedding,
            )

            db.execute(
                stmt.on_conflict_do_update(
                    index_elements=[Verse.ref],
                    set_={
                        'chapter': chapter,
                        'verse_number': verse_number,
                        'chapter_name': chapter_name,
                        'sanskrit': row['sanskrit'],
                        'transliteration': row.get('transliteration', ''),
                        'translation': row['translation'],
                        'translation_hi': translation_hi,
                        'tags': tags,
                        'source': source,
                        'embedding': embedding,
                    },
                )
            )

            if i % 50 == 0:
                print(f'  [{i}/{len(rows)}] seeded...')

        db.commit()
        total = db.scalar(select(func.count(Verse.id))) or 0

    print(f'Seed complete. Loaded verses: {total}')


if __name__ == '__main__':
    main()
