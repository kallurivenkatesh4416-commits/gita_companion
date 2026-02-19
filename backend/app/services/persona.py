from ..schemas import LanguageCode


def wants_krishna_voice(language: LanguageCode) -> bool:
    if language == "hi":
        return True
    return False
