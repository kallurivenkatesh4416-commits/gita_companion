# Repository Guidelines

## Scope And Workflow
- Keep diffs small and task-scoped. Do not include unrelated refactors or formatting sweeps.
- Preserve existing API routes, JSON fields, i18n keys, and DB schema unless the task explicitly requires a change.
- Favor calm, companion-first UX: clear hierarchy, one primary action on Home, and low visual noise.

## Project Layout
- `app/`: Flutter client (`lib/src/screens`, `lib/src/state`, `lib/src/widgets`).
- `backend/`: FastAPI service (`app/main.py`, `app/services`, `app/schemas.py`).
- `data/`: local seed/content files used by backend scripts.
- `docker-compose.yml`: local Postgres + backend runtime.

## Required Commands
- Flutter analyze:
  - `cd app`
  - `flutter analyze`
- Flutter run/build:
  - `flutter run -d chrome --dart-define API_BASE_URL=http://localhost:8000`
  - `flutter build apk --release`
- Backend local compile check:
  - `python -m compileall backend`
- Backend Docker smoke:
  - `docker compose up -d`
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
