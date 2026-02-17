import json
import logging
from collections.abc import Sequence
from typing import Literal, Protocol

import httpx
from pydantic import ValidationError

from ..models import Verse
from ..schemas import ChatResponse, ChatTurn, GuidanceVerse, LanguageCode
from .guidance import extract_json
from .language import language_instruction

logger = logging.getLogger(__name__)


class ChatProvider(Protocol):
    def generate(
        self,
        *,
        message: str,
        mode: Literal["comfort", "clarity"],
        language: LanguageCode,
        history: Sequence[ChatTurn],
        verses: Sequence[Verse],
    ) -> ChatResponse:
        ...


def _build_verse_payload(verses: Sequence[Verse], mode: Literal["comfort", "clarity"]) -> list[GuidanceVerse]:
    payload: list[GuidanceVerse] = []
    for verse in verses[:3]:
        reason = (
            "This verse helps with emotional steadiness."
            if mode == "comfort"
            else "This verse supports clear action and discernment."
        )
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


def _serialize_history(history: Sequence[ChatTurn]) -> list[dict[str, str]]:
    return [{"role": turn.role, "content": turn.content} for turn in history[-12:]]


class MockChatProvider:
    def generate(
        self,
        *,
        message: str,
        mode: Literal["comfort", "clarity"],
        language: LanguageCode,
        history: Sequence[ChatTurn],
        verses: Sequence[Verse],
    ) -> ChatResponse:
        verse_payload = _build_verse_payload(verses, mode)
        primary_ref = verse_payload[0].ref
        tone_by_language = {
            "en": {
                "comfort": "You are not alone in this. Let us make this gentle and practical.",
                "clarity": "Let us simplify this into one clear, disciplined next move.",
                "action": "Pause for one minute, read the first verse once, then complete one focused task immediately.",
                "reflect": "What can I do now with sincerity, without clinging to the result?",
            },
            "hi": {
                "comfort": "Aap ismein akele nahin hain. Isse saral aur vyavaharik rakhte hain.",
                "clarity": "Isse ek spasht aur anushasit agle kadam mein badalte hain.",
                "action": "Ek minute rukkar pehla shlok padhein aur turant ek kendrit kaam poora karein.",
                "reflect": "Main ab kaunsa karya imaandari se kar sakta hoon, bina phal se aasakti ke?",
            },
            "te": {
                "comfort": "Meeru indulo ontariga leru. Dinni mruduvuga, upayogakaranga teesukundam.",
                "clarity": "Dini ni oka spashtamaina tadupiri charyaga saraleekariddam.",
                "action": "Oka nimisham aagi, modati shlokanni chadivi, ventane oka pani poorthi cheyyandi.",
                "reflect": "Phalampai aasakti lekunda nenu ippude e pani nijayitiga cheyagalanu?",
            },
            "ta": {
                "comfort": "Neenga idhil thaniya illai. Idhai menmaiyaagavum payanulladhaagavum vaippom.",
                "clarity": "Idhai oru thelivana adutha nadai-yaga sulabhamaakkalaam.",
                "action": "Oru nimidam niruththi, mudhal slokathai oru murai padithu, udane oru gavanamaana seyal seyyungal.",
                "reflect": "Palanai pidikkaamal naan ippodu seiyya koodiya unmaiyana seyal enna?",
            },
            "kn": {
                "comfort": "Neevu idaralli obbare alla. Idanna komalavagi mattu prayogikavagi madona.",
                "clarity": "Idanna ondu spashta mundina hejjeyagi saralagoLisona.",
                "action": "Ondu nimisha nillisiri, modalina shlokavannu ondu sari odi, takshana ondu kendrita karyavannu mugisi.",
                "reflect": "Phalakke aasakti illade nanu iga satyavagi yava karya madabahudu?",
            },
            "ml": {
                "comfort": "Ningal ithil thanichalla. Ithine mriduvum prayogikavum aakkam.",
                "clarity": "Ithine oru thelivulla adutha nadapadiyayi lalthamakkam.",
                "action": "Oru nimisham nirthi, adya shlokam oru pravashyam vayichu, udane oru kendrikritha pravarthi poorthiyakkuka.",
                "reflect": "Phalathil pidippillathe njan ippol satyathode cheyyan kazhiyunna pravarthi enthaanu?",
            },
            "es": {
                "comfort": "No estas solo en esto. Hagamoslo suave y practico.",
                "clarity": "Convirtamos esto en un siguiente paso claro y disciplinado.",
                "action": "Haz una pausa de un minuto, lee el primer verso una vez y completa una tarea enfocada de inmediato.",
                "reflect": "Que puedo hacer ahora con sinceridad, sin apegarme al resultado?",
            },
        }
        selected_language = language if language in tone_by_language else "en"
        copy = tone_by_language[selected_language]
        tone = copy["comfort"] if mode == "comfort" else copy["clarity"]
        reply_by_language = {
            "en": (
                f"{tone} Your question was: '{message}'. "
                f"Begin with verse {primary_ref}, then apply one concrete action in the next hour."
            ),
            "hi": (
                f"{tone} Aapka prashn tha: '{message}'. "
                f"Shlok {primary_ref} se shuru karein aur agle ek ghante mein ek thos kadam uthayein."
            ),
            "te": (
                f"{tone} Mee prashna: '{message}'. "
                f"Shlokam {primary_ref} to modalu petti, vachche gantalo oka spashtamaina charya cheyyandi."
            ),
            "ta": (
                f"{tone} Ungal kelvi: '{message}'. "
                f"Slokam {primary_ref} mudhal seidhu, adutha oru maninerathil oru urudhiyaana nadavadikkai edungal."
            ),
            "kn": (
                f"{tone} Nimma prashne: '{message}'. "
                f"Shloka {primary_ref} inda prarambhisi, mundina ondu gantheyalli ondu spashta karyavannu madi."
            ),
            "ml": (
                f"{tone} Ningalude chodyam: '{message}'. "
                f"Shlokam {primary_ref} il ninn thudangi, adutha oru manikkooril oru vyakthamaaya pravarthi cheyyuka."
            ),
            "es": (
                f"{tone} Tu pregunta fue: '{message}'. "
                f"Comienza con el verso {primary_ref} y aplica una accion concreta en la proxima hora."
            ),
        }
        return ChatResponse(
            mode=mode,
            reply=reply_by_language[selected_language],
            verses=verse_payload,
            action_step=copy["action"],
            reflection_prompt=copy["reflect"],
            safety={"flagged": False, "message": None},
        )


class GeminiChatProvider:
    def __init__(self, *, api_key: str, model: str, fallback: ChatProvider):
        self.api_key = api_key
        self.model = model
        self.fallback = fallback

    def generate(
        self,
        *,
        message: str,
        mode: Literal["comfort", "clarity"],
        language: LanguageCode,
        history: Sequence[ChatTurn],
        verses: Sequence[Verse],
    ) -> ChatResponse:
        prompt = self._build_prompt(
            message=message,
            mode=mode,
            language=language,
            history=history,
            verses=verses,
        )
        url = f"https://generativelanguage.googleapis.com/v1beta/models/{self.model}:generateContent"
        payload = {
            "contents": [{"parts": [{"text": prompt}]}],
            "generationConfig": {"temperature": 0.2, "responseMimeType": "application/json"},
        }
        try:
            response = httpx.post(url, params={"key": self.api_key}, json=payload, timeout=35.0)
            response.raise_for_status()
            text = response.json()["candidates"][0]["content"]["parts"][0]["text"]
            parsed = json.loads(extract_json(text))
            return ChatResponse.model_validate(parsed)
        except (httpx.HTTPError, KeyError, IndexError, json.JSONDecodeError, ValidationError) as exc:
            logger.warning("Gemini chat failed, falling back to mock provider: %s", exc)
            return self.fallback.generate(
                message=message,
                mode=mode,
                language=language,
                history=history,
                verses=verses,
            )

    def _build_prompt(
        self,
        *,
        message: str,
        mode: Literal["comfort", "clarity"],
        language: LanguageCode,
        history: Sequence[ChatTurn],
        verses: Sequence[Verse],
    ) -> str:
        verses_payload = [
            {
                "verse_id": verse.id,
                "ref": verse.ref,
                "sanskrit": verse.sanskrit,
                "transliteration": verse.transliteration,
                "translation": verse.translation,
            }
            for verse in verses[:3]
        ]
        schema = {
            "mode": "comfort|clarity",
            "reply": "string",
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
            "action_step": "string",
            "reflection_prompt": "string",
            "safety": {"flagged": False, "message": None},
        }
        return (
            "You are a Bhagavad Gita chatbot. Use only provided verses and never invent verse references. "
            "Keep tone practical, warm, and concise. Return strict JSON only.\n"
            f"Schema: {json.dumps(schema)}\n"
            f"{language_instruction(language)}\n"
            f"Mode: {mode}\n"
            f"Conversation history JSON: {json.dumps(_serialize_history(history), ensure_ascii=True)}\n"
            f"User message: {message}\n"
            f"Available verses JSON: {json.dumps(verses_payload, ensure_ascii=True)}"
        )


class OllamaChatProvider:
    def __init__(self, *, base_url: str, model: str, fallback: ChatProvider):
        self.base_url = base_url.rstrip("/")
        self.model = model
        self.fallback = fallback

    def generate(
        self,
        *,
        message: str,
        mode: Literal["comfort", "clarity"],
        language: LanguageCode,
        history: Sequence[ChatTurn],
        verses: Sequence[Verse],
    ) -> ChatResponse:
        prompt = self._build_prompt(
            message=message,
            mode=mode,
            language=language,
            history=history,
            verses=verses,
        )
        url = f"{self.base_url}/api/generate"
        payload = {
            "model": self.model,
            "prompt": prompt,
            "stream": False,
            "options": {"temperature": 0.2},
        }
        try:
            response = httpx.post(url, json=payload, timeout=60.0)
            response.raise_for_status()
            raw_text = response.json().get("response", "")
            parsed = json.loads(extract_json(raw_text))
            return ChatResponse.model_validate(parsed)
        except (httpx.HTTPError, KeyError, json.JSONDecodeError, ValidationError) as exc:
            logger.warning("Ollama chat failed, falling back to mock provider: %s", exc)
            return self.fallback.generate(
                message=message,
                mode=mode,
                language=language,
                history=history,
                verses=verses,
            )

    def _build_prompt(
        self,
        *,
        message: str,
        mode: Literal["comfort", "clarity"],
        language: LanguageCode,
        history: Sequence[ChatTurn],
        verses: Sequence[Verse],
    ) -> str:
        verses_payload = [
            {
                "verse_id": verse.id,
                "ref": verse.ref,
                "sanskrit": verse.sanskrit,
                "transliteration": verse.transliteration,
                "translation": verse.translation,
            }
            for verse in verses[:3]
        ]
        return (
            "You are a Bhagavad Gita guidance chatbot.\n"
            "Rules:\n"
            "1) Use only verses in Available verses JSON.\n"
            "2) Do not invent verse numbers.\n"
            "3) Return strict JSON only in this structure:\n"
            '{"mode":"comfort|clarity","reply":"...","verses":[{"verse_id":47,"ref":"2.47","sanskrit":"...","transliteration":"...","translation":"...","why_this":"..."}],"action_step":"...","reflection_prompt":"...","safety":{"flagged":false,"message":null}}\n'
            f"{language_instruction(language)}\n"
            f"Mode: {mode}\n"
            f"Conversation history JSON: {json.dumps(_serialize_history(history), ensure_ascii=True)}\n"
            f"User message: {message}\n"
            f"Available verses JSON: {json.dumps(verses_payload, ensure_ascii=True)}\n"
        )


