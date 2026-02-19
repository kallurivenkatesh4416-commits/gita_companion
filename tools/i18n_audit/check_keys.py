#!/usr/bin/env python3
import pathlib
import re
import sys
from typing import Dict, Iterable, Set


ROOT = pathlib.Path(__file__).resolve().parent.parent.parent
I18N_PATH = ROOT / "app" / "lib" / "src" / "i18n" / "app_strings.dart"
LOCALES = ["hi", "te", "ta", "kn", "ml", "es"]


def load_map(block: str) -> Set[str]:
    return {
        match.group(1)
        for match in re.finditer(r"'([^']+)'\s*:", block)
    }


def extract_block(text: str, key: str) -> str:
    pattern = rf"'{re.escape(key)}': <String, String>\{{([\s\S]*?)\n\s*\}},"
    match = re.search(pattern, text, re.MULTILINE)
    if not match:
        return ""
    return match.group(1)


def load_used_keys(src_root: pathlib.Path) -> Set[str]:
    pattern = re.compile(r"strings\.t\(\s*['\"]([^'\"]+)['\"]\s*\)")
    files = src_root.rglob("*.dart")
    keys: Set[str] = set()
    for path in files:
        text = path.read_text(encoding="utf-8")
        keys.update(match.group(1) for match in pattern.finditer(text))
    return keys


def main() -> None:
    app_strings = I18N_PATH.read_text(encoding="utf-8")
    en_block = re.search(
        r"const Map<String, String> _enValues = <String, String>\{([\s\S]*?)\n\};",
        app_strings,
    )
    if not en_block:
        print("Unable to locate _enValues block in app_strings.dart")
        sys.exit(1)
    en_keys = load_map(en_block.group(1))

    src_root = ROOT / "app" / "lib"
    used_keys = load_used_keys(src_root)
    missing_en = sorted(key for key in used_keys if key not in en_keys)

    if missing_en:
        print("Missing keys in English map:")
        for key in missing_en:
            print(f"  • {key}")
        sys.exit(1)

    print("All used keys exist in English map.")

    for locale in LOCALES:
        block = extract_block(app_strings, locale)
        if not block:
            print(f"⚠️ Locale '{locale}' block missing; skipping coverage check.")
            continue
        locale_keys = load_map(block)
        missing = sorted(key for key in used_keys if key not in locale_keys)
        print(f"- {locale} coverage: {len(used_keys)-len(missing)}/{len(used_keys)}")
        if missing:
            sample = ", ".join(missing[:5])
            print(f"  missing sample: {sample}")


if __name__ == "__main__":
    main()
