"""Idempotent local schema compatibility migration.

Usage:
  python backend/scripts/migrate_schema_compat.py
"""

from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from app.db import ensure_schema_compatibility, init_db


def main() -> None:
    # Ensure baseline tables exist, then apply compatibility columns.
    init_db()
    ensure_schema_compatibility()
    print("Schema compatibility migration applied.")


if __name__ == "__main__":
    main()
