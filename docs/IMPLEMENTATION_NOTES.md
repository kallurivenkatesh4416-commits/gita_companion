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
