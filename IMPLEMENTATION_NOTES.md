# Implementation Notes (Gita Companion)

This document tracks feature work done via Codex prompts.
Principle: Minimal diffs, maximum impact. Each entry lists scope, key changes, files touched, and verification steps.

Last updated: 2026-02-18 (Asia/Kolkata)

---

## Status Snapshot

Implemented:
- Prompt 2: Verification engine integration + verification badges (backend + frontend)
- Prompt 5: Chapter-wise verse browser (TOC -> verse list -> verse detail -> ask with verse context) + caching
- Prompt 6: Onboarding language + guidance mode (Comfort | Clarity | Traditional), persisted and respected by backend

Pending / Next (planned):
- Real embeddings replacement (Prompt 3)
- Full 700-verse dataset + validation (Prompt 4)
- Error UX polish (Prompt 7)
- Bookmarks, journaling, notifications, journeys, offline, streaming (later)

---

## Entry: Prompt 2 - Verification engine + verification badges

### Goal
Integrate the internal 3-gate verification system into the companion backend and expose verification level + provenance to the frontend. Add a calm badge UI that explains Verified / Reviewed / Raw with expandable details.

### Key Changes
Backend:
- Added internal 3-gate verification service producing:
  - `verification_level`: `VERIFIED | REVIEWED | RAW`
  - `verification_details`: per-check pass/fail + short note
  - `provenance`: verses used (chapter, verse, Sanskrit, translation source)
- Extended response schemas and wired `/ask`, `/chat`, and `/moods/guidance` to return:
  - `answer_text`
  - `verification_level`
  - `verification_details`
  - `provenance`

Frontend:
- Added verification badge component shown on every AI answer.
- Tap badge opens details with:
  - verses used
  - checks pass/fail list

Tests:
- Added backend verification tests validating level logic.

### Files Changed
Backend:
- `backend/app/services/verification.py` (new)
- `backend/app/schemas.py`
- `backend/app/main.py`
- `backend/app/services/retrieval.py`
- `backend/app/__init__.py`
- `backend/test_verification.py` (new)

Frontend:
- `app/lib/src/models/models.dart`
- `app/lib/src/widgets/verification_badge_panel.dart` (new)
- `app/lib/src/widgets/guidance_panel.dart`
- `app/lib/src/screens/ask_screen.dart`
- `app/lib/src/screens/ritual_screen.dart`
- `app/lib/src/i18n/app_strings.dart`

### Verification / Checks Run
- `python -m compileall backend`
- `python backend/test_verification.py`
- `GET /health`

### Notes / Risks
- API payloads now include verification fields; older clients that ignore unknown JSON fields remain compatible.
- Verification level depends on retrieved verse quality, so weak retrieval can downgrade outputs to `REVIEWED`/`RAW`.

---

## Entry: Prompt 5 - Verse browser (chapter TOC + summaries + verse detail)

### Goal
Implement chapter-wise browsing:
- Chapter list screen with all 18 chapters and 1-2 line summary
- Chapter detail screen with verse list
- Verse detail with Sanskrit + translation + optional transliteration and "Ask about this verse"
- Route to chat with the verse pre-attached as context
- Add basic caching so browsing feels instant

### Key Changes
Backend:
- Added `GET /chapters` for chapter TOC summaries + verse counts.
- Added `GET /verses?chapter=` for chapter-wise verse lists.
- Added TTL-cache-backed responses for `/chapters` and `/verses`.

Frontend:
- Added chapter model, API methods, repository cache, and AppState chapter loaders.
- Added chapter list and chapter detail screens.
- Added home entry point for chapter browser.
- Updated verse detail:
  - show transliteration only when available
  - add "Ask about this verse" CTA
- Updated chat screen route args handling:
  - attach verse context marker
  - prefill starter message
  - inject verse context into request history for grounded replies

Caching:
- Backend: existing TTL cache used for chapter TOC and chapter-verse responses.
- Frontend: in-memory cache in repository + AppState chapter verse map.

### Files Changed
Backend:
- `backend/app/main.py`

Frontend:
- `app/lib/src/models/models.dart`
- `app/lib/src/api/api_client.dart`
- `app/lib/src/repositories/gita_repository.dart`
- `app/lib/src/state/app_state.dart`
- `app/lib/main.dart`
- `app/lib/src/screens/chapter_list_screen.dart` (new)
- `app/lib/src/screens/chapter_detail_screen.dart` (new)
- `app/lib/src/screens/home_screen.dart`
- `app/lib/src/screens/verse_detail_screen.dart`
- `app/lib/src/screens/ask_screen.dart`
- `app/lib/src/i18n/app_strings.dart`

### Verification / Checks Run
- `python -m compileall backend`
- `flutter analyze`
- `flutter build apk --release`

### Navigation Flow
1. Home -> Chapters
2. Chapter list (18 chapters + summary)
3. Chapter detail (verse list for selected chapter)
4. Verse detail (Sanskrit, translation, optional transliteration)
5. Ask about this verse -> Chat with verse context pre-attached

### Notes / Risks
- Chapter summaries are currently static content in backend.
- If chat providers ignore subtle context, verse attachment still helps retrieval but does not hard-force citation.

---

## Entry: Prompt 6 - Onboarding improvements (language + guidance mode)

### Goal
Move language picker and guidance mode selection into onboarding (not buried in settings), keep onboarding max 2 screens, persist choices, and ensure chat/guidance prompts use selected mode:
- Comfort
- Clarity
- Traditional

### Key Changes
Frontend:
- Converted onboarding into 2-step flow:
  - Step 1: language + guidance mode selection
  - Step 2: existing private/email onboarding completion
- Added onboarding preference persistence method in AppState:
  - saves `guidance_mode`
  - saves `language_code`
- Added guidance mode normalization helper and supported mode list.
- Added Traditional mode labels and onboarding copy keys.
- Updated settings segmented control to include Traditional.
- Updated mode badge rendering on home header + guidance panel to use a unified mode label helper.

Backend:
- Expanded mode schema to include `traditional` in request/response models.
- Updated provider interfaces and prompt builders (mock/gemini/claude/codex/orchestrator typing) so mode affects tone and verbosity.
- Added explicit Traditional style instructions in prompts.

Additional fix during verification:
- Fixed a pre-existing analyze-time error in `mood_screen.dart` (`strings` scope in error mapper path).

### Files Changed
Frontend:
- `app/lib/src/i18n/app_strings.dart`
- `app/lib/src/state/app_state.dart`
- `app/lib/src/screens/onboarding_screen.dart`
- `app/lib/src/screens/settings_screen.dart`
- `app/lib/src/screens/home_screen.dart`
- `app/lib/src/widgets/guidance_panel.dart`
- `app/lib/src/screens/mood_screen.dart`

Backend:
- `backend/app/schemas.py`
- `backend/app/services/guidance.py`
- `backend/app/services/chatbot.py`
- `backend/app/services/codex_provider.py`
- `backend/app/services/claude_provider.py`
- `backend/app/services/llm_orchestrator.py`

### Verification / Checks Run
- `python -m compileall backend`
- `flutter analyze`
- `flutter build apk --release`

### Notes / Risks
- Traditional mode behavior is provider-prompt-based; quality depends on active model adherence.
- Non-English traditional style is strongest in provider prompt instruction and English mock copy; localized traditional phrasing can be expanded later.

