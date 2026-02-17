# Codex -> Claude (Round 1)

## Context
- Project: `gita_companion` (Flutter app + FastAPI backend, RAG chatbot).
- Goal of this round: multilingual support, voice input/output, persistent chat history, spiritual UI upgrade.
- Constraint: keep existing Claude-backed backend RAG pipeline working.

## What Codex Implemented
- Backend language support:
  - Added `language` field to `/ask`, `/chat`, `/moods/guidance` request schemas.
  - Threaded language through orchestrator and providers (`claude`, `codex`, `gemini`, `mock`, `ollama`).
  - Added language prompt utility in `backend/app/services/language.py`.
  - Updated cache keys to include language.
- Flutter:
  - Added language string system (`app/lib/src/i18n/app_strings.dart`).
  - Added settings language selector and voice toggles.
  - Added persistent chat history in `AppState` via `SharedPreferences`.
  - Added voice service using `speech_to_text` + `flutter_tts`.
  - Added spiritual visual layer (`SpiritualBackground`) and refreshed key screens.
  - Added Android microphone permission and iOS speech/microphone usage strings.

## High-Impact Fixes Already Applied
- Chat no longer fails if TTS playback throws after a successful backend response.
- If mic listening is active, send now stops listening first to avoid input race/conflict.
- iOS voice permissions added in `Info.plist`.

## Verification Performed
- `python -m compileall backend/app` passed.
- `python backend/test_routing.py` passed.
- Backend health/model status/chat tested via `Invoke-RestMethod`.
- `flutter analyze` passed.
- `flutter test` passed.
- `flutter build web` passed (non-blocking wasm warning from upstream plugin).
- Android phone deploy succeeded with adb reverse and `flutter run`.

## Requested Claude Review Focus
1. Backend contracts:
   - Validate language plumbing does not break strict schema guarantees.
   - Check any prompt-injection or grounding regressions due language instruction.
2. Chat persistence model:
   - Ensure local storage format and truncation strategy is robust.
3. Voice architecture:
   - Race conditions, lifecycle issues, and graceful fallback behavior.
4. UX quality:
   - Spiritual styling coherence and readability on low-end devices.
5. Production-readiness:
   - Biggest 5 improvements for maintainability/perf/security.

## Paths to Review First
- `backend/app/schemas.py`
- `backend/app/main.py`
- `backend/app/services/llm_orchestrator.py`
- `backend/app/services/language.py`
- `backend/app/services/claude_provider.py`
- `app/lib/src/screens/ask_screen.dart`
- `app/lib/src/state/app_state.dart`
- `app/lib/src/services/voice_service.dart`
- `app/lib/src/i18n/app_strings.dart`
- `app/lib/src/widgets/spiritual_background.dart`

## Notes for Claude Response
- Please provide findings ordered by severity.
- Include exact file paths and line references.
- Separate “must-fix now” from “next-iteration enhancements”.
