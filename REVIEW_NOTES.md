# Code Review Notes — Claude (Reviewer) -> Codex (Coder)

**Date:** 2026-02-17
**Scope:** Full audit of gita_companion backend + Flutter app
**Reviewer:** Claude Opus 4.6 (acting as Senior Reviewer)
**Coder:** Codex (implement fixes below)

---

## CRITICAL BUGS (Fix Immediately)

### BUG-1: setState() called after dispose() in mood_screen.dart
**File:** `app/lib/src/screens/mood_screen.dart:53-57`
**Problem:** The `_submit()` method calls `setState()` in both `catch` and `finally` blocks after an async `repository.moodGuidance()` call. If the user navigates away during the API call, the widget is disposed and `setState()` throws.
**Fix:** Add `if (!mounted) return;` guard before each `setState()` call after the async gap.

```dart
// Line 53: wrap in mounted check
if (mounted) setState(() => _guidance = response);

// Line 55: wrap in mounted check
if (mounted) setState(() => _error = error.toString());

// Line 57: wrap in mounted check
if (mounted) setState(() => _loading = false);
```

### BUG-2: VoiceService.speak() sets _speaking=false prematurely
**File:** `app/lib/src/services/voice_service.dart:69-74`
**Problem:** `_tts.speak()` returns when the utterance is *queued*, not when it *finishes*. Even with `awaitSpeakCompletion(true)`, setting `_speaking = false` on line 74 may race with the completion handler. Also, if `speak()` throws, `_speaking` stays true forever.
**Fix:** Use TTS completion handler:
```dart
Future<void> speak({required String text, required String localeId}) async {
  if (text.trim().isEmpty) return;
  await _tts.stop();
  _speaking = true;
  await _tts.setLanguage(localeId);
  await _tts.setSpeechRate(0.47);
  await _tts.setPitch(1.0);
  try {
    await _tts.speak(text);
  } finally {
    _speaking = false;
  }
}
```

### BUG-3: DropdownButtonFormField uses non-existent `initialValue` parameter
**File:** `app/lib/src/screens/settings_screen.dart:51`
**Problem:** `DropdownButtonFormField` does NOT have an `initialValue` parameter. The correct parameter is `value`. This will cause a compile error.
**Fix:** Change `initialValue` to `value`:
```dart
DropdownButtonFormField<String>(
  value: languageOptionFromCode(appState.languageCode).code,
  ...
)
```

---

## HIGH PRIORITY (Reliability + UX)

### HIGH-1: ClaudeChatProvider doesn't use conversation history properly
**File:** `backend/app/services/claude_provider.py:141-154`
**Problem:** The Anthropic Messages API supports multi-turn conversation natively via the `messages` array. But `ClaudeChatProvider` packs the ENTIRE conversation into a single user message string, losing the native multi-turn structure. This degrades Claude's ability to follow conversational context.
**Fix:** Build proper `messages` array:
```python
messages = _serialize_history(history) + [{"role": "user", "content": prompt}]
```
And move the system instructions into the `system` parameter of the API call.

### HIGH-2: Chat history cap of 80 entries but no size-based pruning
**File:** `app/lib/src/state/app_state.dart:212-213`
**Problem:** Chat history is capped at 80 entries and serialized as JSON into SharedPreferences. With long messages, this could easily hit the SharedPreferences string size limit (~1MB on some Android devices). No size-based pruning exists.
**Fix:** Add a byte-size check. If serialized JSON > 500KB, prune from oldest entries.

### HIGH-3: Missing `mounted` check in AskScreen after async operations
**File:** `app/lib/src/screens/ask_screen.dart:110-136`
**Problem:** After `await appState.repository.chat(...)` completes, `setState()` is called without checking `mounted`. Same pattern as BUG-1.
**Fix:** Add `if (!mounted) return;` after line 102 (the `await` call) before the `setState()` on line 110.

---

## MEDIUM PRIORITY (Code Quality)

### MED-1: Missing languages in app_strings.dart
**File:** `app/lib/src/i18n/app_strings.dart`
**Problem:** `LanguageCode` on backend supports 7 languages (en, hi, te, ta, kn, ml, es) but `app_strings.dart` only has translations for en, hi, te. Users selecting Tamil, Kannada, Malayalam, or Spanish will see English fallback keys everywhere.
**Fix:** Add at minimum the `ta`, `kn`, `ml`, `es` entries to `_values` map and `_moodValues` map. Even basic translations are better than raw keys.

### MED-2: Claude provider should use `system` parameter
**File:** `backend/app/services/claude_provider.py:48-53`
**Problem:** The Anthropic API has a dedicated `system` parameter for system prompts. Currently the system instructions are embedded in the user message, which is less effective.
**Fix:** Split the prompt: system instructions go in `system` param, user query + verses go in `messages`.

### MED-3: API client base URL hardcodes emulator IP for Android
**File:** `app/lib/src/api/api_client.dart:39-41`
**Problem:** `http://10.0.2.2:8000` only works for the Android emulator. On a real device (like the user's OnePlus LE2121), this will fail unless `adb reverse` is set up. This is a runtime discovery issue.
**Fix:** Add a comment documenting this. For real devices, either:
1. Use `adb reverse tcp:8000 tcp:8000` (already done by Codex in session), or
2. Default to `http://127.0.0.1:8000` for real devices when `adb reverse` is active, or
3. Make base URL configurable in Settings screen.

### MED-4: Error messages leak raw exception strings to user
**Files:** `mood_screen.dart:55`, `ask_screen.dart:126`, `app_state.dart:80`
**Problem:** `error.toString()` is shown directly to the user. This can expose stack traces, API URLs, or internal error details.
**Fix:** Wrap errors in user-friendly messages:
```dart
catch (error) {
  setState(() => _error = 'Something went wrong. Please try again.');
  debugPrint('API error: $error');
}
```

---

## LOW PRIORITY (Polish)

### LOW-1: Duplicate `_serialize_history` function
**Files:** `claude_provider.py:19-20` and `codex_provider.py:19-20`
**Problem:** Identical function defined in two files.
**Fix:** Move to a shared utility, e.g., `backend/app/services/chat_utils.py`.

### LOW-2: `nativeName` in app_strings.dart should use native script
**File:** `app/lib/src/i18n/app_strings.dart:16-34`
**Problem:** `nativeName` for Hindi says "Hindi" not "हिन्दी", Telugu says "Telugu" not "తెలుగు", etc. The purpose of `nativeName` is to show the language in its own script.
**Fix:**
```dart
AppLanguageOption(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी', ttsLocale: 'hi-IN'),
AppLanguageOption(code: 'te', name: 'Telugu', nativeName: 'తెలుగు', ttsLocale: 'te-IN'),
AppLanguageOption(code: 'ta', name: 'Tamil', nativeName: 'தமிழ்', ttsLocale: 'ta-IN'),
AppLanguageOption(code: 'kn', name: 'Kannada', nativeName: 'ಕನ್ನಡ', ttsLocale: 'kn-IN'),
AppLanguageOption(code: 'ml', name: 'Malayalam', nativeName: 'മലയാളം', ttsLocale: 'ml-IN'),
AppLanguageOption(code: 'es', name: 'Spanish', nativeName: 'Espanol', ttsLocale: 'es-ES'),
```

### LOW-3: `pubspec.yaml` — verify flutter_tts and speech_to_text are listed
Check that these dependencies are in pubspec.yaml. If missing, `flutter pub get` will fail.

---

## WHAT'S WORKING WELL (Compliments to Codex)

1. **Clean provider pattern** — Both Claude and Codex providers follow identical interface, making them drop-in replaceable.
2. **Chat persistence** — `SharedPreferences`-based chat history with proper encode/decode and 80-entry cap is solid.
3. **Voice integration** — Clean separation of `VoiceService` from UI logic. Locale-aware TTS is well done.
4. **Language service** — Backend `language_instruction()` is elegant and concise.
5. **Settings screen** — Good UX with voice toggles, language picker, and clear data options.
6. **Orchestrator health tracking** — Per-provider health with `mark_ok()`/`mark_failed()` is production-ready.

---

## ACTION ITEMS FOR CODEX (Priority Order)

1. Fix BUG-1 (mood_screen mounted check)
2. Fix BUG-3 (settings_screen initialValue -> value)
3. Fix HIGH-3 (ask_screen mounted check)
4. Fix BUG-2 (voice_service speak try/finally)
5. Fix MED-1 (add missing language translations)
6. Fix LOW-2 (native script names)
7. Fix MED-4 (user-friendly error messages)
8. Fix LOW-1 (deduplicate _serialize_history)
9. Run `flutter analyze` and fix any remaining issues
10. Run the app on device to verify

## STATUS FILE
After completing fixes, write your status to:
`C:\Users\VENKATESH\gita_companion\CODEX_STATUS.md`

Include:
- Which items you fixed
- Which items you skipped and why
- Any new issues discovered
- `flutter analyze` output summary
