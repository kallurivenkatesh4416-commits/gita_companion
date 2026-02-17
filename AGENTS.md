# Repository Guidelines

## Scope And Workflow
- Keep diffs small and task-scoped. Do not include unrelated refactors or formatting sweeps.
- Preserve existing API routes, JSON fields, i18n keys, and DB schema unless the task explicitly requires a change.
- Favor calm, companion-first UX: clear hierarchy, one primary action on Home, and low visual noise.
- Always preserve existing UI/UX unless explicitly requested.

## Project Layout
- `app/`: Flutter client (`lib/src/screens`, `lib/src/state`, `lib/src/widgets`).
- `backend/`: FastAPI service (`app/main.py`, `app/services`, `app/schemas.py`).
- `data/`: local seed/content files used by backend scripts.
- `docker-compose.yml`: local Postgres + backend runtime.

## Required Commands
- Frontend run (Flutter):
  - `cd app`
  - `flutter pub get`
  - `flutter run -d chrome --dart-define API_BASE_URL=http://localhost:8000`
  - `flutter run -d <device_id> --dart-define API_BASE_URL=http://127.0.0.1:8000`
- Frontend build:
  - `cd app`
  - `flutter build apk --release`
- Backend run (Docker Compose):
  - `docker compose up -d --build`
  - `Invoke-RestMethod http://localhost:8000/health`
- Backend run (local optional):
  - `cd backend`
  - `python -m venv .venv`
  - `.\.venv\Scripts\Activate.ps1`
  - `pip install -r requirements.txt`
  - `uvicorn app.main:app --reload --port 8000`

## Test Commands
- Frontend static checks:
  - `cd app`
  - `flutter analyze`
  - `flutter test`
- Backend static checks:
  - `python -m compileall backend`
- Backend API smoke:
  - `Invoke-RestMethod http://localhost:8000/health`

## Coding Expectations
- Flutter: keep `Provider` + `AppState` patterns.
  - Mutations via `context.read<AppState>()`.
  - Reactive UI via `context.watch<AppState>()`.
- i18n:
  - Never hardcode production UI strings.
  - Add keys in `app/lib/src/i18n/app_strings.dart` only when needed.
- Home screen:
  - Keep calm spacing and minimal hierarchy.
  - Avoid duplicate buttons/sections and keep secondary content visually de-emphasized.
