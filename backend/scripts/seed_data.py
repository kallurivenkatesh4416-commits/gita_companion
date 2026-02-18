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
from app.services.embeddings import LocalHashEmbeddingProvider


def resolve_data_file(cli_path: str | None) -> Path:
    if cli_path:
        candidate = Path(cli_path)
        if candidate.exists():
            return candidate

    defaults = [
        Path('/data/gita_verses_full.json'),
        Path('/data/gita_verses_sample.json'),
        Path('/data/gita_verses_complete.json'),
        Path(__file__).resolve().parents[2] / 'data' / 'gita_verses_full.json',
        Path(__file__).resolve().parents[2] / 'data' / 'gita_verses_sample.json',
        Path(__file__).resolve().parents[2] / 'data' / 'gita_verses_complete.json',
    ]
    for candidate in defaults:
        if candidate.exists():
            return candidate

    raise FileNotFoundError(
        'Could not find gita_verses_full.json or gita_verses_sample.json'
    )


def main() -> None:
    parser = argparse.ArgumentParser(description='Seed Bhagavad Gita verses into PostgreSQL')
    parser.add_argument('--file', dest='file_path', default=None, help='Path to verse JSON file')
    args = parser.parse_args()

    data_file = resolve_data_file(args.file_path)
    rows = json.loads(data_file.read_text(encoding='utf-8-sig'))
    if not isinstance(rows, list):
        raise ValueError('Input JSON must be a list of verse objects')

    settings = get_settings()
    embedder = LocalHashEmbeddingProvider(dimension=settings.embedding_dim)

    init_db()

    with SessionLocal() as db:
        for row in rows:
            chapter = int(row['chapter'])
            verse_number = int(row.get('verse_number', row.get('verse')))
            ref = row.get('ref') or f'{chapter}.{verse_number}'
            tags = row.get('tags') or []
            transliteration = str(row.get('transliteration') or '')
            translation = str(row.get('translation') or '')
            sanskrit = str(row.get('sanskrit') or '')

            embedding_input = ' '.join(
                [
                    ref,
                    transliteration,
                    translation,
                    ' '.join(tags),
                ]
            )
            embedding = embedder.embed(embedding_input)

            stmt = insert(Verse).values(
                chapter=chapter,
                verse_number=verse_number,
                ref=ref,
                sanskrit=sanskrit,
                transliteration=transliteration,
                translation=translation,
                tags=tags,
                embedding=embedding,
            )

            db.execute(
                stmt.on_conflict_do_update(
                    index_elements=[Verse.ref],
                    set_={
                        'chapter': chapter,
                        'verse_number': verse_number,
                        'sanskrit': sanskrit,
                        'transliteration': transliteration,
                        'translation': translation,
                        'tags': tags,
                        'embedding': embedding,
                    },
                )
            )

        db.commit()
        total = db.scalar(select(func.count(Verse.id))) or 0

    print(f'Seed complete. total_seeded={total}')
    if total < 650:
        print('Warning: total_seeded is below expected minimum (650).')


if __name__ == '__main__':
    main()
