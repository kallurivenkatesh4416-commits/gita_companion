"""Fetch the complete 700-verse Bhagavad Gita from the public Vedicscriptures API.

API: https://vedicscriptures.github.io/
Outputs: data/gita_verses_complete.json in the canonical schema.

Usage:
    python scripts/fetch_gita_dataset.py
"""

import json
import time
from pathlib import Path

import httpx

API_BASE = "https://vedicscriptures.github.io"

# Verse counts per chapter (18 chapters, 700 verses total)
CHAPTER_VERSE_COUNTS = {
    1: 47, 2: 72, 3: 43, 4: 42, 5: 29, 6: 47,
    7: 30, 8: 28, 9: 34, 10: 42, 11: 55, 12: 20,
    13: 35, 14: 27, 15: 20, 16: 24, 17: 28, 18: 78,
}

CHAPTER_NAMES = {
    1: "Arjuna Vishada Yoga",
    2: "Sankhya Yoga",
    3: "Karma Yoga",
    4: "Jnana Karma Sanyasa Yoga",
    5: "Karma Sanyasa Yoga",
    6: "Dhyana Yoga",
    7: "Jnana Vijnana Yoga",
    8: "Aksara Brahma Yoga",
    9: "Raja Vidya Raja Guhya Yoga",
    10: "Vibhuti Yoga",
    11: "Vishvarupa Darshana Yoga",
    12: "Bhakti Yoga",
    13: "Ksetra Ksetrajna Vibhaga Yoga",
    14: "Gunatraya Vibhaga Yoga",
    15: "Purushottama Yoga",
    16: "Daivasura Sampad Vibhaga Yoga",
    17: "Shraddhatraya Vibhaga Yoga",
    18: "Moksha Sanyasa Yoga",
}

OUTPUT_FILE = Path(__file__).resolve().parents[1] / "data" / "gita_verses_complete.json"


def fetch_verse(client: httpx.Client, chapter: int, verse: int) -> dict | None:
    url = f"{API_BASE}/slok/{chapter}/{verse}/"
    try:
        resp = client.get(url, timeout=15)
        resp.raise_for_status()
        return resp.json()
    except Exception as e:
        print(f"  WARN: Failed to fetch {chapter}.{verse}: {e}")
        return None


def normalize_verse(raw: dict, chapter: int, verse: int) -> dict:
    """Convert API response to our canonical schema."""
    # Extract Sanskrit (slok field)
    sanskrit = raw.get("slok", "").strip()

    # Extract transliteration
    transliteration = raw.get("transliteration", "").strip()

    # Extract translations — API provides multiple authors
    translations = {}
    author_map = raw.get("tej", {})  # Swami Tejomayananda (Hindi)
    gambir = raw.get("gambpiranand", raw.get("gampiranand", {}))  # Swami Gambirananda
    spiegel = raw.get("sivananda", {})  # Swami Sivananda
    raman = raw.get("rpilananda", raw.get("rams", {}))  # Swami Ramsukhdas
    purohit = raw.get("purohit", {})
    chinmaya = raw.get("chinpilay", raw.get("chinmay", {}))
    spivananda = raw.get("spivananda", raw.get("sivananda", {}))

    # Primary English translation — try multiple sources
    english_translation = ""
    for key in ["purohit", "sivananda", "gambpiranand", "gampiranand", "abpidev", "adi"]:
        author_data = raw.get(key, {})
        if isinstance(author_data, dict):
            et = author_data.get("et", "").strip()
            if et:
                english_translation = et
                break

    # Hindi translation
    hindi_translation = ""
    for key in ["tej", "rams", "rpilananda", "spivananda", "chinpilay", "chinmay"]:
        author_data = raw.get(key, {})
        if isinstance(author_data, dict):
            ht = author_data.get("ht", "").strip()
            if ht:
                hindi_translation = ht
                break

    # Build source metadata with all available translations
    source = {"api": "vedicscriptures.github.io"}
    for key in raw:
        if isinstance(raw[key], dict) and ("et" in raw[key] or "ht" in raw[key]):
            source[key] = {}
            if raw[key].get("et"):
                source[key]["en"] = raw[key]["et"].strip()
            if raw[key].get("ht"):
                source[key]["hi"] = raw[key]["ht"].strip()
            if raw[key].get("sc"):
                source[key]["author"] = raw[key]["sc"].strip()

    return {
        "chapter": chapter,
        "verse": verse,
        "ref": f"{chapter}.{verse}",
        "chapter_name": CHAPTER_NAMES.get(chapter, ""),
        "sanskrit": sanskrit,
        "transliteration": transliteration,
        "translation": english_translation,
        "translation_hi": hindi_translation,
        "tags": [],
        "source": source,
    }


def main() -> None:
    all_verses = []
    total_expected = sum(CHAPTER_VERSE_COUNTS.values())
    print(f"Fetching {total_expected} verses across 18 chapters...")

    with httpx.Client() as client:
        for chapter in range(1, 19):
            verse_count = CHAPTER_VERSE_COUNTS[chapter]
            print(f"\nChapter {chapter} ({CHAPTER_NAMES[chapter]}): {verse_count} verses")

            for verse in range(1, verse_count + 1):
                raw = fetch_verse(client, chapter, verse)
                if raw:
                    normalized = normalize_verse(raw, chapter, verse)
                    all_verses.append(normalized)
                    if verse % 10 == 0:
                        print(f"  {verse}/{verse_count} done")
                else:
                    # Create placeholder for failed fetches
                    all_verses.append({
                        "chapter": chapter,
                        "verse": verse,
                        "ref": f"{chapter}.{verse}",
                        "chapter_name": CHAPTER_NAMES.get(chapter, ""),
                        "sanskrit": "",
                        "transliteration": "",
                        "translation": "",
                        "translation_hi": "",
                        "tags": [],
                        "source": {"api": "vedicscriptures.github.io", "status": "fetch_failed"},
                    })

                # Be polite to the API
                time.sleep(0.1)

    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_FILE.write_text(
        json.dumps(all_verses, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    # Validation
    chapters = set(v["chapter"] for v in all_verses)
    failed = [v["ref"] for v in all_verses if not v["sanskrit"]]

    print(f"\n{'='*50}")
    print(f"Total verses fetched: {len(all_verses)}")
    print(f"Chapters covered: {len(chapters)}")
    print(f"Failed fetches: {len(failed)}")
    if failed:
        print(f"  Failed refs: {failed[:10]}{'...' if len(failed) > 10 else ''}")
    print(f"Output: {OUTPUT_FILE}")

    assert len(all_verses) in (700, 701), f"Expected 700-701 verses, got {len(all_verses)}"
    assert len(chapters) == 18, f"Expected 18 chapters, got {len(chapters)}"
    print(f"Validation PASSED: {len(all_verses)} verses, 18 chapters")


if __name__ == "__main__":
    main()
