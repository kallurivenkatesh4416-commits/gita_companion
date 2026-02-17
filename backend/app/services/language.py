from ..schemas import LanguageCode


LANGUAGE_NAMES: dict[LanguageCode, str] = {
    "en": "English",
    "hi": "Hindi",
    "te": "Telugu",
    "ta": "Tamil",
    "kn": "Kannada",
    "ml": "Malayalam",
    "es": "Spanish",
}


def language_name(code: LanguageCode) -> str:
    return LANGUAGE_NAMES.get(code, "English")


def language_instruction(code: LanguageCode) -> str:
    language = language_name(code)
    return (
        f"Respond in {language}. Keep verse ref, sanskrit, and transliteration aligned with provided verses. "
        "Use the target language for translation, explanation, and guidance fields."
    )
