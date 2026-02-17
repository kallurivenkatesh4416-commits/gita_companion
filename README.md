# Gita Companion (Flutter + FastAPI)

Monorepo MVP for a cross-platform Gita Companion app with:
- Flutter client (`/app`)
- FastAPI backend (`/backend`)
- PostgreSQL + pgvector via Docker Compose
- Local sample Bhagavad Gita verses (`/data/gita_verses_sample.json`)

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

## API Endpoints

- `GET /health`
- `GET /daily-verse`
- `GET /moods`
- `POST /moods/guidance`
- `POST /ask`
- `POST /chat`
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
  -Body '{"question":"How can I act without anxiety?","mode":"clarity"}' `
  -ContentType 'application/json'
Invoke-RestMethod -Method Post http://localhost:8000/chat `
  -Body '{"message":"I feel overwhelmed with work","mode":"comfort","history":[]}' `
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

## Known Limitations / Next Steps

- Current embeddings are deterministic local hash vectors for offline MVP reliability.
- Chatbot is retrieval-grounded on local verses (RAG), not fine-tuned model training on the full scripture.
- Gemini provider is optional and disabled by default.
- Journeys endpoint/UI is currently a stub.
- Audio in verse detail is a placeholder.
- Add proper authentication and user-scoped favorites for production.
