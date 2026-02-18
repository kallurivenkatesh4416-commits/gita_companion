## Milestone: Share as Image (Phase 1) - Verse Cards

**Goal**: Allow users to share a beautifully formatted verse card as a PNG image from Verse Detail and Home Daily Verse.

**Key changes**:
- New offscreen widget renders verse data onto a saffron/parchment card.
- RepaintBoundary captures widget as PNG and shares it via native share sheet.
- Share button added as a secondary outlined action in verse detail.
- Small share icon added to the daily verse card on home screen.

**Files changed**:
- `app/lib/src/widgets/verse_share_card.dart` (new)
- `app/lib/src/services/share_card_service.dart` (new)
- `app/lib/src/widgets/verse_preview_card.dart` (added optional `onShare`)
- `app/lib/src/screens/verse_detail_screen.dart` (added Share button)
- `app/lib/src/screens/home_screen.dart` (wired daily verse share)
- `app/lib/src/i18n/app_strings.dart` (new keys: `share`, `preparing_image`, `share_failed`)
- `app/pubspec.yaml` (added `share_plus`, `path_provider`)

**Checks run**:
- `flutter analyze` (0 issues)
- `flutter build apk --release` (success)

**Notes/Risks**:
- Overlay-based offscreen rendering is always cleaned up via `finally`.
- Added low-memory fallback for capture (`pixelRatio: 3.0` then retry `2.0`).
- Uses local/offscreen rendering only; no network calls required.

## Milestone: UX Review Improvements (Pass 1)

**Goal**: Apply the first high-impact UX suggestions in sequence with calm, low-noise UI behavior.

**Key changes**:
- Home spacing tuned for breathing room and shorter morning greeting preview.
- Verse detail now prioritizes meaning and collapses Sanskrit/transliteration by default.
- Added previous/next verse navigation on verse detail with chapter-boundary guard.
- Settings reorganized into clear sections (Practice, Privacy & Data, About).
- Added empty-state cards with supportive visuals for Favorites and Journeys.
- Replaced spinner-only loading on Favorites/Journeys with lightweight skeleton placeholders.

**Files changed**:
- `app/lib/src/screens/home_screen.dart`
- `app/lib/src/screens/verse_detail_screen.dart`
- `app/lib/src/screens/settings_screen.dart`
- `app/lib/src/screens/favorites_screen.dart`
- `app/lib/src/screens/journeys_screen.dart`
- `app/lib/src/state/app_state.dart`
- `app/lib/src/i18n/app_strings.dart`

**Checks run**:
- `flutter analyze`
- `flutter build apk --release`

## Milestone: UX Review Improvements (Pass 2)

**Goal**: Continue implementing high-impact medium-effort UX improvements with minimal diffs.

**Key changes**:
- Verse detail now uses a sticky bottom action bar for Bookmark, Share, Ask Gita, and Recite.
- Chat now shows suggested follow-up chips after the latest assistant answer.
- Mood check-in now uses a visual selector (emoji-style mood tiles) while keeping backend behavior unchanged.
- Daily ritual flow now includes a 3-step progress header, gentle step transitions, and a completion card before auto-return.
- Added warm dark mode support with `ThemeMode.system` and dark-aware spiritual background rendering.
- Added i18n keys for new ritual/chat/verse actions in EN/HI/TE/ES (others fall back to EN).

**Files changed**:
- `app/lib/src/screens/verse_detail_screen.dart`
- `app/lib/src/screens/ask_screen.dart`
- `app/lib/src/screens/mood_screen.dart`
- `app/lib/src/screens/ritual_screen.dart`
- `app/lib/src/theme/app_theme.dart`
- `app/lib/src/widgets/spiritual_background.dart`
- `app/lib/main.dart`
- `app/lib/src/i18n/app_strings.dart`

**Checks run**:
- `flutter analyze --no-pub`
- `flutter build apk --release --no-pub`
