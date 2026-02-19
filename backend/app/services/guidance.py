import json
import logging
from collections.abc import Sequence
from typing import Protocol

import httpx
from pydantic import ValidationError

from ..models import Verse
from ..schemas import GuidanceMode, GuidanceResponse, GuidanceVerse, LanguageCode
from .language import language_instruction

logger = logging.getLogger(__name__)


class GuidanceProvider(Protocol):
    def generate(
        self,
        *,
        topic: str,
        mode: GuidanceMode,
        language: LanguageCode,
        verses: Sequence[Verse],
    ) -> GuidanceResponse:
        ...


def _build_verse_payload(verses: Sequence[Verse], mode: GuidanceMode) -> list[GuidanceVerse]:
    payload: list[GuidanceVerse] = []
    for verse in verses[:3]:
        if mode == "comfort":
            reason = "This verse supports emotional steadiness and self-awareness."
        elif mode == "clarity":
            reason = "This verse supports disciplined action and clear thinking."
        else:
            reason = "This verse supports dharma-centered reflection with a traditional tone."
        payload.append(
            GuidanceVerse(
                verse_id=verse.id,
                ref=verse.ref,
                sanskrit=verse.sanskrit,
                transliteration=verse.transliteration,
                translation=verse.translation,
                why_this=reason,
            )
        )
    return payload


def _mode_style_instruction(mode: GuidanceMode) -> str:
    if mode == "comfort":
        return (
            "Style: warm and reassuring. Keep responses concise, gentle, and practical."
        )
    if mode == "clarity":
        return (
            "Style: direct and action-oriented. Keep responses brief with crisp next steps."
        )
    return (
        "Style: traditional Bhagavad Gita voice. Use respectful, dharma-centered language "
        "with slightly richer detail than clarity mode while staying practical."
    )


class MockProvider:
    def generate(
        self,
        *,
        topic: str,
        mode: GuidanceMode,
        language: LanguageCode,
        verses: Sequence[Verse],
    ) -> GuidanceResponse:
        verse_payload = _build_verse_payload(verses, mode)

        tone_by_language = {
            "en": {
                "comfort": "Take one small gentle step and steady your breath.",
                "clarity": "Choose the next right action and execute it with focus.",
                "traditional": "Act from dharma with steadiness, humility, and devotion.",
                "long": (
                    "Anchor attention in what is in your control. "
                    "Read one verse slowly, notice one practical lesson, and apply it to the next hour."
                ),
                "traditional_long": (
                    "Steady your attention in dharma and nishkama karma. "
                    "Read one verse with reverence, contemplate its inner meaning, and live one duty in the next hour."
                ),
                "title": "One-Minute Grounding",
                "traditional_title": "One-Minute Dharma Reflection",
                "step_1": "Inhale for 4 counts, exhale for 6 counts, repeat five times.",
                "step_2": "Read the first selected verse once and name one action you can do now.",
                "traditional_step_1": (
                    "Take 5 deep breaths, remembering you are responsible for action, not the fruits."
                ),
                "traditional_step_2": (
                    "Recite or read the first selected verse and commit to one duty-aligned action now."
                ),
                "reflect": "What is one action I can complete today without attachment to the outcome?",
                "traditional_reflect": (
                    "Which duty can I perform today as an offering, without attachment to results?"
                ),
            },
            "hi": {
                "comfort": "एक छोटा सा कोमल कदम लें और अपनी सांस को स्थिर करें।",
                "clarity": "अगला सही कदम चुनें और उसे एकाग्रता से पूरा करें।",
                "long": (
                    "ध्यान को उसी पर टिकाएं जो आपके नियंत्रण में है। "
                    "एक श्लोक धीरे से पढ़ें, एक व्यावहारिक सीख चुनें, और अगले एक घंटे में लागू करें।"
                ),
                "title": "एक मिनट स्थिरता अभ्यास",
                "step_1": "4 गिनती में श्वास लें, 6 गिनती में छोड़ें, पांच बार दोहराएं।",
                "step_2": "पहला चुना हुआ श्लोक एक बार पढ़ें और अभी का एक कार्य तय करें।",
                "reflect": "आज मैं परिणाम से आसक्ति छोड़े बिना कौन सा एक कार्य पूरा कर सकता हूं?",
            },
            "te": {
                "comfort": "ఒక చిన్న సున్నితమైన అడుగు వేయండి, శ్వాసను స్థిరపరచండి.",
                "clarity": "తదుపరి సరైన చర్యను ఎంచుకుని ఏకాగ్రతతో చేయండి.",
                "long": (
                    "మీ నియంత్రణలో ఉన్నదానిపై దృష్టిని నిలపండి. "
                    "ఒక శ్లోకాన్ని నెమ్మదిగా చదివి, ఒక ఉపయోగకరమైన పాఠాన్ని ఎంచుకుని తదుపరి గంటలో అమలు చేయండి."
                ),
                "title": "ఒక నిమిషం స్థిరత సాధన",
                "step_1": "4 కౌంట్లలో శ్వాస తీసుకుని, 6 కౌంట్లలో విడిచి, ఐదు సార్లు పునరావృతం చేయండి.",
                "step_2": "మొదటి శ్లోకాన్ని ఒకసారి చదివి, ఇప్పుడు చేయగల ఒక చర్యను నిర్ణయించండి.",
                "reflect": "ఫలంపై ఆసక్తి లేకుండా నేను ఈరోజు పూర్తి చేయగల ఒక చర్య ఏమిటి?",
            },
            "ta": {
                "comfort": "Oru siru menmaiyana adi edungal; moochai amaidhiyaaga nilai niruthungal.",
                "clarity": "Adutha sariyana seyalaich therindhu manadhudan mudikkavum.",
                "long": (
                    "Ungal kattupadil ulladhil dhyanam vaikkavum. "
                    "Oru slokathai medhuvaga padithu, oru payanulla paadathai adutha oru maninerathil seyalpaduthavum."
                ),
                "title": "Oru Nimida Amaidhi Payirchi",
                "step_1": "4 count-il suvasam eduththu, 6 count-il vidavum; 5 murai seyyavum.",
                "step_2": "Mudhal slokathai oru murai padithu, ippove seiyya mudiyum oru nadavadikkaiyai therindhukollungal.",
                "reflect": "Palanil pidippu illamal naan indru mudikka koodiya oru seyal enna?",
            },
            "kn": {
                "comfort": "Ondu chikka komala hejje haaki, usirannu shantavagi nilisi.",
                "clarity": "Mundina sariyada karya vannu ayke madi ekagrateyondige mugisi.",
                "long": (
                    "Nimma niyantranadalli iruvudara mele gamana kodi. "
                    "Ondu shlokavannu nidhanavagi odi, upayukta paatavannu mundina ondu gantheyalli anusarisi."
                ),
                "title": "Ondu Nimisha Sthirate Abhyasa",
                "step_1": "4 count ge usiru tegedukolli, 6 count ge bidiri; aidu sari punaravartisi.",
                "step_2": "Modalina shlokavannu ondu sari odi, iga madabahudaada ondu karyavannu nirdharisi.",
                "reflect": "Phalakke aasakti illade nanu ivattu mugisabahudaada ondu karya yavudu?",
            },
            "ml": {
                "comfort": "Oru cheriya mriduvaya padi edukkuka; shwasam shanthamayi nilanirthuka.",
                "clarity": "Adutha sariyaya pravarthi thiranjeduthu ekagrathayode poorthiyakkuka.",
                "long": (
                    "Ningalude niyantranathil ullathil shraddha nilanirthuka. "
                    "Oru shlokam mellayayi vayichu, upayogapradamaya oru paadam adutha oru manikkooril prayogikkuka."
                ),
                "title": "Oru Nimisha Sthiratha Abhyasam",
                "step_1": "4 count-il shwasam edukka, 6 count-il viduka; anchu pravashyam avarthikkuka.",
                "step_2": "Aadyathe shlokam oru pravashyam vayichu, ippol cheyyan kazhiyunna oru pravarthi theerumanikkuka.",
                "reflect": "Phalathil pidippillathe njan innu poorthiyakkan kazhiyunna oru pravarthi enthaanu?",
            },
            "es": {
                "comfort": "Da un paso pequeno y suave, y estabiliza tu respiracion.",
                "clarity": "Elige la siguiente accion correcta y ejecutala con enfoque.",
                "long": (
                    "Enfoca tu atencion en lo que esta bajo tu control. "
                    "Lee un verso con calma, elige una leccion practica y aplicala en la proxima hora."
                ),
                "title": "Practica De Un Minuto",
                "step_1": "Inhala en 4 tiempos y exhala en 6 tiempos, repitelo cinco veces.",
                "step_2": "Lee el primer verso una vez y define una accion concreta para ahora.",
                "reflect": "Que accion puedo completar hoy sin apegarme al resultado?",
            },
        }
        selected_language = language if language in tone_by_language else "en"
        copy = tone_by_language[selected_language]

        short_text = {
            "comfort": copy["comfort"],
            "clarity": copy["clarity"],
            "traditional": copy.get("traditional", copy["clarity"]),
        }[mode]
        long_text = copy["long"] if mode != "traditional" else copy.get("traditional_long", copy["long"])
        practice_title = copy["title"] if mode != "traditional" else copy.get("traditional_title", copy["title"])
        practice_step_1 = copy["step_1"] if mode != "traditional" else copy.get("traditional_step_1", copy["step_1"])
        practice_step_2 = copy["step_2"] if mode != "traditional" else copy.get("traditional_step_2", copy["step_2"])
        reflection_prompt = copy["reflect"] if mode != "traditional" else copy.get("traditional_reflect", copy["reflect"])

        return GuidanceResponse(
            mode=mode,
            topic=topic,
            verses=verse_payload,
            guidance_short=short_text,
            guidance_long=long_text,
            micro_practice={
                "title": practice_title,
                "steps": [
                    practice_step_1,
                    practice_step_2,
                ],
                "duration_minutes": 1,
            },
            reflection_prompt=reflection_prompt,
            safety={"flagged": False, "message": None},
        )


class GeminiProvider:
    def __init__(self, api_key: str, model: str, fallback: GuidanceProvider):
        self.api_key = api_key
        self.model = model
        self.fallback = fallback

    def generate(
        self,
        *,
        topic: str,
        mode: GuidanceMode,
        language: LanguageCode,
        verses: Sequence[Verse],
    ) -> GuidanceResponse:
        prompt = self._build_prompt(topic=topic, mode=mode, language=language, verses=verses)
        url = f"https://generativelanguage.googleapis.com/v1beta/models/{self.model}:generateContent"

        payload = {
            "contents": [{"parts": [{"text": prompt}]}],
            "generationConfig": {
                "temperature": 0.2,
                "responseMimeType": "application/json",
            },
        }

        try:
            response = httpx.post(url, params={"key": self.api_key}, json=payload, timeout=30.0)
            response.raise_for_status()
            text = response.json()["candidates"][0]["content"]["parts"][0]["text"]
            parsed = json.loads(extract_json(text))
            return GuidanceResponse.model_validate(parsed)
        except (httpx.HTTPError, KeyError, IndexError, json.JSONDecodeError, ValidationError) as exc:
            logger.warning("Falling back to mock provider after Gemini failure: %s", exc)
            return self.fallback.generate(topic=topic, mode=mode, language=language, verses=verses)

    def _build_prompt(
        self,
        *,
        topic: str,
        mode: GuidanceMode,
        language: LanguageCode,
        verses: Sequence[Verse],
    ) -> str:
        verse_text = []
        for verse in verses[:3]:
            verse_text.append(
                {
                    "verse_id": verse.id,
                    "ref": verse.ref,
                    "sanskrit": verse.sanskrit,
                    "transliteration": verse.transliteration,
                    "translation": verse.translation,
                }
            )

        schema = {
            "mode": "comfort|clarity|traditional",
            "topic": "string",
            "verses": [
                {
                    "verse_id": 47,
                    "ref": "2.47",
                    "sanskrit": "...",
                    "transliteration": "...",
                    "translation": "...",
                    "why_this": "...",
                }
            ],
            "guidance_short": "string",
            "guidance_long": "string",
            "micro_practice": {
                "title": "string",
                "steps": ["...", "..."],
                "duration_minutes": 1,
            },
            "reflection_prompt": "string",
            "safety": {"flagged": False, "message": None},
        }

        return (
            "You are a Bhagavad Gita guidance assistant. Use only the supplied verses. "
            "Do not invent verse references. Return strict JSON only with this schema: "
            f"{json.dumps(schema)}\n\n"
            f"{language_instruction(language)}\n"
            f"{_mode_style_instruction(mode)}\n"
            f"Mode: {mode}\n"
            f"Topic: {topic}\n"
            f"Available verses JSON: {json.dumps(verse_text, ensure_ascii=True)}"
        )


def extract_json(text: str) -> str:
    start = text.find("{")
    end = text.rfind("}")
    if start == -1 or end == -1 or end <= start:
        raise json.JSONDecodeError("No JSON object found", text, 0)
    return text[start : end + 1]
