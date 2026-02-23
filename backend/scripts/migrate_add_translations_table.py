"""
Migration: Add verse_translations table for i18n-first content schema.

WHAT THIS DOES
──────────────
Creates a new `verse_translations` table that decouples translation storage from
the `verses` table. New translations for any language can be added as rows — no
schema change needed.

Migrates existing data:
  - verses.translation       → verse_translations (language_code='en', source='original')
  - verses.translation_hi    → verse_translations (language_code='hi', source='original')

Backward compatibility:
  - The original `verses.translation` and `verses.translation_hi` columns are NOT
    dropped; they are kept as-is so existing queries continue to work unchanged.
  - A helper SQL view `verse_with_translations` is created for convenience.

HOW TO RUN
──────────
  cd backend
  python -m scripts.migrate_add_translations_table

  # With a specific DATABASE_URL:
  DATABASE_URL=postgresql+psycopg://... python -m scripts.migrate_add_translations_table

  # Dry-run (shows SQL without executing):
  DRY_RUN=true python -m scripts.migrate_add_translations_table
"""

from __future__ import annotations

import logging
import os
import sys

import psycopg

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# DDL
# ---------------------------------------------------------------------------

CREATE_TABLE_SQL = """
CREATE TABLE IF NOT EXISTS verse_translations (
    verse_id     INTEGER     NOT NULL REFERENCES verses(id) ON DELETE CASCADE,
    language_code CHAR(2)    NOT NULL,
    translation  TEXT        NOT NULL,
    source       VARCHAR(100) NOT NULL DEFAULT 'original',
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (verse_id, language_code)
);

CREATE INDEX IF NOT EXISTS idx_verse_translations_verse_id
    ON verse_translations(verse_id);

CREATE INDEX IF NOT EXISTS idx_verse_translations_language
    ON verse_translations(language_code);
"""

MIGRATE_ENGLISH_SQL = """
INSERT INTO verse_translations (verse_id, language_code, translation, source)
SELECT id, 'en', translation, 'original'
FROM   verses
WHERE  translation IS NOT NULL AND translation <> ''
ON CONFLICT (verse_id, language_code) DO NOTHING;
"""

MIGRATE_HINDI_SQL = """
INSERT INTO verse_translations (verse_id, language_code, translation, source)
SELECT id, 'hi', translation_hi, 'original'
FROM   verses
WHERE  translation_hi IS NOT NULL AND translation_hi <> ''
ON CONFLICT (verse_id, language_code) DO NOTHING;
"""

CREATE_VIEW_SQL = """
CREATE OR REPLACE VIEW verse_with_translations AS
SELECT
    v.id,
    v.chapter,
    v.verse_number,
    v.ref,
    v.sanskrit,
    v.transliteration,
    v.tags,
    COALESCE(t_en.translation, v.translation) AS translation_en,
    COALESCE(t_hi.translation, v.translation_hi, v.translation) AS translation_hi
FROM verses v
LEFT JOIN verse_translations t_en ON v.id = t_en.verse_id AND t_en.language_code = 'en'
LEFT JOIN verse_translations t_hi ON v.id = t_hi.verse_id AND t_hi.language_code = 'hi';
"""

LANGUAGE_LOOKUP_FUNCTION_SQL = """
CREATE OR REPLACE FUNCTION get_verse_translation(p_verse_id INTEGER, p_lang CHAR(2))
RETURNS TEXT AS $$
DECLARE
    result TEXT;
BEGIN
    -- Try requested language first, fall back to English
    SELECT translation INTO result
    FROM   verse_translations
    WHERE  verse_id = p_verse_id
      AND  language_code = p_lang;

    IF result IS NULL THEN
        SELECT translation INTO result
        FROM   verse_translations
        WHERE  verse_id = p_verse_id
          AND  language_code = 'en';
    END IF;

    RETURN result;
END;
$$ LANGUAGE plpgsql STABLE;
"""


def _resolve_database_url() -> str:
    url = os.environ.get("DATABASE_URL", "")
    if url:
        return url

    # Try loading from backend/.env
    env_path = os.path.join(os.path.dirname(__file__), "..", ".env")
    if os.path.exists(env_path):
        with open(env_path) as fh:
            for line in fh:
                line = line.strip()
                if line.startswith("DATABASE_URL="):
                    return line.split("=", 1)[1].strip().strip('"').strip("'")

    return "postgresql://postgres:postgres@localhost:5432/gita_companion"


def _psycopg_url(url: str) -> str:
    """Convert SQLAlchemy-style URL to plain psycopg3 DSN if needed."""
    return url.replace("postgresql+psycopg://", "postgresql://")


def run(dry_run: bool = False) -> None:
    database_url = _psycopg_url(_resolve_database_url())
    logger.info("Connecting to database…")

    steps = [
        ("Create verse_translations table + indexes", CREATE_TABLE_SQL),
        ("Migrate English translations", MIGRATE_ENGLISH_SQL),
        ("Migrate Hindi translations", MIGRATE_HINDI_SQL),
        ("Create verse_with_translations view", CREATE_VIEW_SQL),
        ("Create get_verse_translation() helper function", LANGUAGE_LOOKUP_FUNCTION_SQL),
    ]

    if dry_run:
        logger.info("DRY RUN — the following SQL would be executed:\n")
        for label, sql in steps:
            print(f"-- {label}\n{sql}\n")
        return

    with psycopg.connect(database_url, autocommit=False) as conn:
        with conn.cursor() as cur:
            for label, sql in steps:
                logger.info("Step: %s", label)
                cur.execute(sql)
            conn.commit()

    logger.info("Migration complete.")
    logger.info(
        "TIP: To add a new language (e.g. Telugu), run:\n"
        "  INSERT INTO verse_translations (verse_id, language_code, translation, source)\n"
        "  VALUES (<verse_id>, 'te', '<Telugu text>', 'AI-generated');"
    )


if __name__ == "__main__":
    dry_run = os.environ.get("DRY_RUN", "").lower() in ("true", "1", "yes")
    try:
        run(dry_run=dry_run)
    except Exception as exc:
        logger.error("Migration failed: %s", exc)
        sys.exit(1)
