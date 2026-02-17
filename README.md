# Gita Companion (Flutter + FastAPI)

Monorepo MVP for a cross-platform Gita Companion app with:
- Flutter client (`/app`)
- FastAPI backend (`/backend`)
- PostgreSQL + pgvector via Docker Compose
- Local sample Bhagavad Gita verses (`/data/gita_verses_sample.json`)
- Multi-language UI/chat support (`en`, `hi`, `te`, with extensible language codes)
- Voice input/output in Flutter chat (speech-to-text + TTS)
- Persistent local chat history via `SharedPreferences`

## Monorepo Layout

- `backend/` FastAPI app, retrieval, providers, seed script
- `app/` Flutter UI with onboarding, dashboard, mood check-in, ask, favorites, journeys, settings
- `data/` local verse dataset
- `docker-compose.yml` postgres + backend services

## Backend Design (MVP)

- FastAPI + SQLAlchemy + pgvector
- Create-tables-on-start (no Alembic for MVP)
- Deterministic local hash embeddings (no API key required)
- Vector retrieval with keyword fallback
- Guidance + chatbot provider abstraction:
  - `MockProvider` (default, deterministic)
  - `GeminiProvider` (optional, only if key set and `USE_MOCK_PROVIDER=false`)
  - `OllamaChatProvider` (optional local LLM for chatbot)
- In-memory TTL cache for repeated `/ask`, `/moods/guidance`, and `/chat` requests
- Optional language-aware generation for `/ask`, `/moods/guidance`, and `/chat` via `language` request field

## API Endpoints

- `GET /health`
- `GET /daily-verse`
- `GET /moods`
- `POST /moods/guidance`
- `POST /ask`
- `POST /chat`
- `POST /morning-greeting`
- `GET /verses/{id}`
- `GET /favorites`
- `POST /favorites`
- `DELETE /favorites/{verse_id}`
- `GET /journeys`

## Output Schema Enforcement

`/ask` and `/moods/guidance` return strict Pydantic `GuidanceResponse`:
- `mode`
- `topic`
- `verses` (1-3 entries)
- `guidance_short`
- `guidance_long`
- `micro_practice`
- `reflection_prompt`
- `safety`

## Setup

### 1) Environment

```powershell
cd C:\Users\VENKATESH\gita_companion
Copy-Item backend\.env.example backend\.env -Force
```

### 2) Start Postgres + Backend

```powershell
docker compose up -d --build
```

### 3) Seed Data

```powershell
docker compose exec backend python scripts/seed_data.py --file /data/gita_verses_sample.json
```

### 4) Verify Backend

```powershell
Invoke-RestMethod http://localhost:8000/health
Invoke-RestMethod http://localhost:8000/daily-verse
Invoke-RestMethod -Method Post http://localhost:8000/ask `
  -Body '{"question":"How can I act without anxiety?","mode":"clarity","language":"en"}' `
  -ContentType 'application/json'
Invoke-RestMethod -Method Post http://localhost:8000/chat `
  -Body '{"message":"How do I stay calm under pressure?","mode":"comfort","language":"hi","history":[]}' `
  -ContentType 'application/json'
Invoke-RestMethod -Method Post http://localhost:8000/morning-greeting `
  -Body '{"mode":"comfort","language":"en"}' `
  -ContentType 'application/json'
```

Swagger docs:
- `http://localhost:8000/docs`

## Flutter App

The Flutter UI code is under `app/lib`.

If platform folders are not present yet, generate them once:

```powershell
cd C:\Users\VENKATESH\gita_companion\app
flutter create .
flutter pub get
```

Run on web:

```powershell
flutter run -d chrome --dart-define API_BASE_URL=http://localhost:8000
```

Run on Android emulator:

```powershell
flutter run -d emulator-5554 --dart-define API_BASE_URL=http://10.0.2.2:8000
```

Run on a physical Android phone (USB):

```powershell
adb devices
adb reverse tcp:8000 tcp:8000
flutter run -d <device_id> --dart-define API_BASE_URL=http://127.0.0.1:8000
```

## Design Approach

- UI architecture:
  - Dashboard-first companion UX (not chat-only)
  - Single `AppState` (`provider`) for profile, language, voice toggles, and persisted chat history
  - Reusable spiritual visual layer (`SpiritualBackground`) + cohesive saffron/earth theme
- LLM and RAG architecture:
  - Retrieval remains backend-only and verse-grounded
  - Frontend passes `language` preference; backend enforces JSON schema and forwards language instruction to LLM providers
  - Mock provider remains deterministic fallback for offline reliability
- Mobile-first evolution path:
  - Keep current local-first history for MVP speed/privacy
  - Add backend user accounts + cloud sync later without breaking the current API contract
  - Add streaming chat responses and per-message source cards as next UX upgrades

## Backend Local (Without Docker, Optional)

```powershell
cd C:\Users\VENKATESH\gita_companion\backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
uvicorn app.main:app --reload
```

Set `DATABASE_URL` accordingly if running outside Docker.

### Optional: Run Chatbot on Local Ollama

If you have Ollama running locally, switch chatbot provider to Ollama in `backend/.env`:

```env
USE_MOCK_PROVIDER=false
USE_OLLAMA_PROVIDER=true
OLLAMA_BASE_URL=http://host.docker.internal:11434
OLLAMA_MODEL=llama3.1:8b
```

Then restart backend:

```powershell
docker compose restart backend
```

## Security and Secrets

- Do not commit real API keys.
- Keep `backend/.env` local only.
- `backend/.env.example` contains placeholders.
- Keep all model-provider secrets backend-only (`backend/.env` or process env vars). The Flutter client must call backend routes only.

### Key Rotation (Required After Exposure)

If any key was exposed, rotate/revoke it first, then update local env values.

1. Anthropic: Console -> API Keys -> revoke the exposed key -> create a new key -> set `ANTHROPIC_API_KEY` in `backend/.env`.
2. OpenAI: Platform -> API Keys -> delete the exposed key -> create a new key -> set `OPENAI_API_KEY` in `backend/.env`.
3. Gemini: Google AI Studio -> API Keys -> delete the exposed key -> create a new key -> set `GEMINI_API_KEY` in `backend/.env`.
4. Restart backend after updates: `docker compose up -d --build` (or restart your local `uvicorn` process).

## Known Limitations / Next Steps

- Current embeddings are deterministic local hash vectors for offline MVP reliability.
- Chatbot is retrieval-grounded on local verses (RAG), not fine-tuned model training on the full scripture.
- Gemini provider is optional and disabled by default.
- Journeys endpoint/UI is currently a stub.
- Audio in verse detail is a placeholder.
- Speech-to-text/TTS behavior can vary by device/browser language engine support.
- Add proper authentication and user-scoped favorites for production.
