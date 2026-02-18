import json
import os
import sys
from collections import Counter
from pathlib import Path
from typing import Any

try:
    import requests
except ImportError as exc:  # pragma: no cover - runtime guard
    raise SystemExit(
        'Missing dependency: requests. Install with "pip install requests".'
    ) from exc

DEFAULT_BASE_URL = 'https://raw.githubusercontent.com/gita/bhagavad-gita-api/master/data'
CHAPTER_VERSE_COUNTS = {
    1: 47,
    2: 72,
    3: 43,
    4: 42,
    5: 29,
    6: 47,
    7: 30,
    8: 28,
    9: 34,
    10: 42,
    11: 55,
    12: 20,
    13: 35,
    14: 27,
    15: 20,
    16: 24,
    17: 28,
    18: 78,
}


def _repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


def _resolve_output_path() -> Path:
    out_path_raw = os.getenv('OUT_PATH', 'data/gita_verses_full.json').strip()
    out_path = Path(out_path_raw)
    if out_path.is_absolute():
        return out_path
    return _repo_root() / out_path


def _first_non_empty_string(values: list[Any]) -> str:
    for value in values:
        if isinstance(value, str):
            cleaned = value.strip()
            if cleaned:
                return cleaned
    return ''


def _extract_translation(raw: dict[str, Any]) -> str:
    direct = _first_non_empty_string([raw.get('translation')])
    if direct:
        return direct

    translations = raw.get('translations')
    if isinstance(translations, list):
        for item in translations:
            if not isinstance(item, dict):
                continue
            language = str(item.get('language') or '').strip().lower()
            text = _first_non_empty_string(
                [item.get('description'), item.get('translation'), item.get('text')]
            )
            if text and language in {'english', 'en'}:
                return text
        for item in translations:
            if not isinstance(item, dict):
                continue
            text = _first_non_empty_string(
                [item.get('description'), item.get('translation'), item.get('text')]
            )
            if text:
                return text

    meaning = raw.get('meaning')
    if isinstance(meaning, dict):
        text = _first_non_empty_string([meaning.get('en'), meaning.get('english')])
        if text:
            return text

    return ''


def _normalize_verse(raw: dict[str, Any], chapter: int, verse_number: int) -> dict[str, Any]:
    normalized_chapter = int(raw.get('chapter') or raw.get('chapter_number') or chapter)
    normalized_verse = int(raw.get('verse') or raw.get('verse_number') or verse_number)
    normalized: dict[str, Any] = {
        'chapter': normalized_chapter,
        'verse_number': normalized_verse,
        'ref': str(raw.get('ref') or f'{normalized_chapter}.{normalized_verse}'),
        'sanskrit': _first_non_empty_string(
            [raw.get('sanskrit'), raw.get('text'), raw.get('slok')]
        ),
        'transliteration': _first_non_empty_string(
            [raw.get('transliteration'), raw.get('transliterate')]
        ),
        'translation': _extract_translation(raw),
        'tags': [],
    }

    verse_id = raw.get('id') or raw.get('verse_order')
    if verse_id is not None:
        try:
            normalized['id'] = int(verse_id)
        except (TypeError, ValueError):
            pass

    tags = raw.get('tags')
    if isinstance(tags, list):
        normalized['tags'] = [str(tag).strip() for tag in tags if str(tag).strip()]

    return normalized


def _fetch_json(url: str, timeout_s: int = 30) -> dict[str, Any]:
    try:
        response = requests.get(url, timeout=timeout_s)
    except requests.RequestException as exc:
        raise RuntimeError(f'Failed to reach source endpoint: {url} ({exc})') from exc

    if response.status_code != 200:
        raise RuntimeError(f'Source endpoint returned {response.status_code}: {url}')

    try:
        payload = response.json()
    except ValueError as exc:
        raise RuntimeError(f'Endpoint did not return valid JSON: {url}') from exc

    if not isinstance(payload, dict):
        raise RuntimeError(f'Unexpected payload type from endpoint: {url}')
    return payload


def fetch_all_verses(base_url: str) -> list[dict[str, Any]]:
    cleaned_base = base_url.rstrip('/')
    verses: list[dict[str, Any]] = []
    for chapter, total_verses in CHAPTER_VERSE_COUNTS.items():
        for verse_number in range(1, total_verses + 1):
            url = (
                f'{cleaned_base}/verses/verse_{chapter:02d}_{verse_number}.json'
            )
            raw = _fetch_json(url)
            verses.append(_normalize_verse(raw, chapter, verse_number))
    return verses


def dedupe_and_sort(verses: list[dict[str, Any]]) -> list[dict[str, Any]]:
    by_key: dict[tuple[int, int], dict[str, Any]] = {}
    for verse in verses:
        key = (int(verse['chapter']), int(verse['verse_number']))
        by_key[key] = verse
    return [by_key[key] for key in sorted(by_key)]


def main() -> int:
    source = os.getenv('GITA_SOURCE', 'api').strip().lower()
    if source != 'api':
        print('Error: only GITA_SOURCE=api is supported.', file=sys.stderr)
        return 1

    base_url = os.getenv('API_BASE_URL', DEFAULT_BASE_URL).strip() or DEFAULT_BASE_URL
    output_path = _resolve_output_path()

    try:
        normalized = dedupe_and_sort(fetch_all_verses(base_url))
    except RuntimeError as exc:
        print(f'Error: {exc}', file=sys.stderr)
        return 1

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(
        json.dumps(normalized, ensure_ascii=False, indent=2) + '\n',
        encoding='utf-8',
    )

    chapter_counts = Counter(int(verse['chapter']) for verse in normalized)
    print(f'total_verses={len(normalized)}')
    for chapter in range(1, 19):
        print(f'chapter_{chapter}={chapter_counts.get(chapter, 0)}')
    print(f'output_path={output_path}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
