import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ignore_for_file: avoid_print

import '../data/journey_catalog.dart';
import '../errors/app_error_mapper.dart';
import '../i18n/app_strings.dart';
import '../models/models.dart';
import '../repositories/gita_repository.dart';
import '../services/verse_notification_service.dart';

class AppState extends ChangeNotifier {
  static const _prefOnboardingComplete = 'onboarding_complete';
  static const _prefAnonymousMode = 'anonymous_mode';
  static const _prefEmail = 'email';
  static const _prefGuidanceMode = 'guidance_mode';
  static const _prefPrivacyAnonymous = 'privacy_anonymous';
  static const _prefLanguageCode = 'language_code';
  static const _prefVoiceInputEnabled = 'voice_input_enabled';
  static const _prefVoiceOutputEnabled = 'voice_output_enabled';
  static const _prefChatHistory = 'chat_history';
  static const _prefMorningGreeting = 'morning_greeting';
  static const _prefMorningGreetingLocalDate = 'morning_greeting_local_date';
  static const _prefRitualLastCompletedDate =
      'ritual_last_completed_local_date';
  static const _prefRitualReflections = 'ritual_reflections';
  static const _prefJournalEntries = 'journal_entries';
  static const _prefBookmarkCollections = 'bookmark_collections';
  static const _prefJourneyProgress = 'journey_progress';
  static const _prefVerseNotificationsEnabled = 'verse_notifications_enabled';
  static const _prefVerseNotificationsPaused = 'verse_notifications_paused';
  static const _prefVerseNotificationWindow = 'verse_notification_window';
  static const _prefVerseNotificationCustomHour =
      'verse_notification_custom_hour';
  static const _prefVerseNotificationCustomMinute =
      'verse_notification_custom_minute';
  static const _prefOfflineMode = 'offline_mode';

  static const notificationWindowMorning = 'morning';
  static const notificationWindowEvening = 'evening';
  static const notificationWindowCustom = 'custom';
  static const _defaultNotificationHour = 7;
  static const _defaultNotificationMinute = 30;
  static const _morningWindowHour = 7;
  static const _morningWindowMinute = 30;
  static const _eveningWindowHour = 19;
  static const _eveningWindowMinute = 0;

  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  final GitaRepository repository;
  final VerseNotificationService _verseNotificationService =
      VerseNotificationService();

  bool initialized = false;
  bool onboardingComplete = false;
  bool anonymousMode = true;
  bool privacyAnonymous = true;
  String? email;
  String guidanceMode = 'comfort';
  String languageCode = 'en';
  bool voiceInputEnabled = true;
  bool voiceOutputEnabled = false;
  bool verseNotificationsEnabled = false;
  bool verseNotificationsPaused = false;
  String verseNotificationWindow = notificationWindowMorning;
  int verseNotificationCustomHour = _defaultNotificationHour;
  int verseNotificationCustomMinute = _defaultNotificationMinute;
  bool offlineMode = false;
  int _connectivityFailStreak = 0;

  bool loading = false;
  bool _favoritesLoading = false;
  String? dailyVerseError;
  String? moodOptionsError;
  String? favoritesError;
  String? journeysError;
  String? chaptersError;
  String? morningGreetingError;
  Verse? dailyVerse;
  MorningGreeting? morningGreeting;
  bool morningGreetingLoading = false;
  List<String> moodOptions = const <String>[];
  List<FavoriteItem> favorites = const <FavoriteItem>[];
  List<Journey> journeys = const <Journey>[];
  List<ChapterSummary> chapters = const <ChapterSummary>[];
  final Map<int, List<Verse>> chapterVerses = <int, List<Verse>>{};
  final Map<int, String> chapterVersesErrors = <int, String>{};
  final Set<int> _chapterVersesLoading = <int>{};
  List<ChatHistoryEntry> chatHistory = const <ChatHistoryEntry>[];
  String? ritualLastCompletedDate;
  List<String> ritualReflections = const <String>[];
  List<JournalEntry> journalEntries = const <JournalEntry>[];
  List<BookmarkCollection> bookmarkCollections = const <BookmarkCollection>[];
  final Map<String, Set<int>> _journeyProgressById = <String, Set<int>>{};
  bool chaptersLoading = false;

  bool get ritualCompletedToday => ritualLastCompletedDate == _todayKey();
  bool get favoritesLoading => _favoritesLoading;
  bool get versesLoading => chaptersLoading || _chapterVersesLoading.isNotEmpty;
  String? get versesError {
    if (chaptersError != null) {
      return chaptersError;
    }
    if (chapterVersesErrors.isEmpty) {
      return null;
    }
    return chapterVersesErrors.values.first;
  }
  bool get versesSyncPartialWarning => chapterVersesErrors.isNotEmpty;
  String? get versesSyncWarningMessage =>
      chapterVersesErrors.isEmpty ? null : chapterVersesErrors.values.first;
  int get totalVersesAvailable => chapterVerses.values.fold<int>(
        0,
        (total, verses) => total + verses.length,
      );
  Map<int, List<Verse>> get chapterVerseCache => chapterVerses;
  bool isChapterLoading(int chapter) => _chapterVersesLoading.contains(chapter);
  Set<int> journeyCompletedDays(String journeyId) =>
      _journeyProgressById[journeyId] ?? const <int>{};
  int journeyCompletedCount(String journeyId) =>
      _journeyProgressById[journeyId]?.length ?? 0;
  bool isJourneyDayCompleted(String journeyId, int day) =>
      _journeyProgressById[journeyId]?.contains(day) ?? false;

  AppState({required this.repository});

  Future<void> initialize() async {
    if (initialized) {
      return;
    }

    loading = true;
    notifyListeners();

    // ── Phase 1: Load all persisted (local) data synchronously ──────────────
    // This is fast (disk only) and lets us paint the first frame immediately.
    final prefs = await SharedPreferences.getInstance();
    onboardingComplete = prefs.getBool(_prefOnboardingComplete) ?? false;
    anonymousMode = prefs.getBool(_prefAnonymousMode) ?? true;
    privacyAnonymous = prefs.getBool(_prefPrivacyAnonymous) ?? anonymousMode;
    email = await _secure.read(key: _prefEmail);
    guidanceMode =
        guidanceModeFromCode(prefs.getString(_prefGuidanceMode) ?? 'comfort');
    final languageCandidate = prefs.getString(_prefLanguageCode) ?? 'en';
    languageCode = languageOptionFromCode(languageCandidate).code;
    voiceInputEnabled = prefs.getBool(_prefVoiceInputEnabled) ?? true;
    voiceOutputEnabled = prefs.getBool(_prefVoiceOutputEnabled) ?? false;
    verseNotificationsEnabled =
        prefs.getBool(_prefVerseNotificationsEnabled) ?? false;
    verseNotificationsPaused = prefs.getBool(_prefVerseNotificationsPaused) ?? false;
    verseNotificationWindow = _normalizeNotificationWindow(
      prefs.getString(_prefVerseNotificationWindow) ?? notificationWindowMorning,
    );
    verseNotificationCustomHour = _normalizeHour(
      prefs.getInt(_prefVerseNotificationCustomHour) ?? _defaultNotificationHour,
    );
    verseNotificationCustomMinute = _normalizeMinute(
      prefs.getInt(_prefVerseNotificationCustomMinute) ??
          _defaultNotificationMinute,
    );
    // Restore persisted offline mode so the UI is consistent after a crash.
    offlineMode = prefs.getBool(_prefOfflineMode) ?? false;
    chatHistory = _decodeChatHistory(await _secure.read(key: _prefChatHistory));
    morningGreeting =
        _decodeMorningGreeting(await _secure.read(key: _prefMorningGreeting));
    ritualLastCompletedDate = prefs.getString(_prefRitualLastCompletedDate);
    ritualReflections =
        _decodeStringList(await _secure.read(key: _prefRitualReflections));
    journalEntries =
        _decodeJournalEntries(await _secure.read(key: _prefJournalEntries));
    bookmarkCollections =
        _decodeBookmarkCollections(await _secure.read(key: _prefBookmarkCollections));
    _journeyProgressById
      ..clear()
      ..addAll(_decodeJourneyProgress(prefs.getString(_prefJourneyProgress)));
    await _migrateLegacyRitualReflectionsIfNeeded();
    await _verseNotificationService.initialize();

    // ── Phase 2: Paint first frame ───────────────────────────────────────────
    // The home screen renders immediately with persisted data (or empty states
    // with skeleton loaders). Network fetches run concurrently below.
    loading = false;
    initialized = true;
    notifyListeners();

    // ── Phase 3: Background network fetches (non-blocking) ──────────────────
    // refreshJourneys is local-only so it finishes instantly.
    await Future.wait(<Future<void>>[
      refreshDailyVerse(),
      refreshMoodOptions(),
      refreshFavorites(),
      refreshJourneys(),
      refreshChapters(),
    ]);

    await _syncVerseNotifications();
    unawaited(_autoGenerateMorningGreetingIfNeeded());
  }

  Future<void> refreshDailyVerse() async {
    try {
      dailyVerse = await repository.getDailyVerse();
      dailyVerseError = null;
      offlineMode = repository.lastRequestUsedOfflineData &&
          repository.lastRequestOfflineFallbackFromConnectivity;
      if (!offlineMode) _connectivityFailStreak = 0;
    } catch (error, stackTrace) {
      dailyVerseError = _friendlyError(
        error,
        stackTrace,
        context: 'refreshDailyVerse',
      );
      _markOfflineFromError(error);
    }
    await _syncVerseNotifications();
    notifyListeners();
  }

  Future<void> refreshMoodOptions() async {
    try {
      moodOptions = await repository.getMoodOptions();
      moodOptionsError = null;
      if (offlineMode) unawaited(_persistOfflineMode(false));
      offlineMode = false;
      _connectivityFailStreak = 0;
    } catch (error, stackTrace) {
      moodOptions = const <String>[];
      moodOptionsError = _friendlyError(
        error,
        stackTrace,
        context: 'refreshMoodOptions',
      );
      _markOfflineFromError(error);
    }
    notifyListeners();
  }

  Future<void> refreshFavorites() async {
    _favoritesLoading = true;
    notifyListeners();

    try {
      favorites = await repository.getFavorites();
      favoritesError = null;
      if (offlineMode) unawaited(_persistOfflineMode(false));
      offlineMode = false;
      _connectivityFailStreak = 0;
    } catch (error, stackTrace) {
      favorites = const <FavoriteItem>[];
      favoritesError = _friendlyError(
        error,
        stackTrace,
        context: 'refreshFavorites',
      );
      _markOfflineFromError(error);
    } finally {
      _favoritesLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshJourneys() async {
    journeys = builtInJourneys
        .map(_withComputedJourneyStatus)
        .toList(growable: false);
    journeysError = null;
    notifyListeners();
  }

  double journeyCompletionRatio(String journeyId, int totalDays) {
    if (totalDays <= 0) {
      return 0;
    }
    final completed = journeyCompletedCount(journeyId);
    return (completed / totalDays).clamp(0, 1).toDouble();
  }

  int journeyNextDay(String journeyId, int totalDays) {
    final completedDays = journeyCompletedDays(journeyId);
    for (var day = 1; day <= totalDays; day++) {
      if (!completedDays.contains(day)) {
        return day;
      }
    }
    return totalDays;
  }

  Future<void> setJourneyDayCompleted({
    required String journeyId,
    required int day,
    required bool completed,
  }) async {
    if (day < 1) {
      return;
    }

    final updated = <int>{...journeyCompletedDays(journeyId)};
    if (completed) {
      updated.add(day);
    } else {
      updated.remove(day);
    }

    if (updated.isEmpty) {
      _journeyProgressById.remove(journeyId);
    } else {
      _journeyProgressById[journeyId] = updated;
    }

    await _persistJourneyProgress();
    journeys = journeys
        .map((journey) => journey.id == journeyId
            ? _withComputedJourneyStatus(journey)
            : journey)
        .toList(growable: false);
    notifyListeners();
  }

  Journey _withComputedJourneyStatus(Journey journey) {
    final completedDays = journeyCompletedCount(journey.id);
    final status = completedDays <= 0
        ? 'not_started'
        : (completedDays >= journey.days ? 'completed' : 'in_progress');
    return journey.copyWith(status: status);
  }

  Future<void> refreshChapters({bool forceRefresh = false}) async {
    chaptersLoading = true;
    notifyListeners();

    try {
      chapters = await repository.getChapters(forceRefresh: forceRefresh);
      chaptersError = null;
      offlineMode = repository.lastRequestUsedOfflineData &&
          repository.lastRequestOfflineFallbackFromConnectivity;
      if (!offlineMode) _connectivityFailStreak = 0;
    } catch (error, stackTrace) {
      if (chapters.isEmpty) {
        chaptersError = _friendlyError(
          error,
          stackTrace,
          context: 'refreshChapters',
        );
      }
      _markOfflineFromError(error);
    } finally {
      chaptersLoading = false;
      notifyListeners();
    }
  }

  List<Verse> versesForChapter(int chapter) {
    return chapterVerses[chapter] ?? const <Verse>[];
  }

  List<Verse> chapterVersesFor(int chapter) => versesForChapter(chapter);

  String? chapterError(int chapter) => chapterVersesErrors[chapter];

  Future<void> loadChapterVerses(
    int chapter, {
    bool forceRefresh = false,
  }) async {
    if (_chapterVersesLoading.contains(chapter)) {
      return;
    }

    if (!forceRefresh && chapterVerses.containsKey(chapter)) {
      return;
    }

    _chapterVersesLoading.add(chapter);
    chapterVersesErrors.remove(chapter);
    notifyListeners();

    try {
      chapterVerses[chapter] = await repository.getVersesByChapter(
        chapter,
        forceRefresh: forceRefresh,
      );
      offlineMode = repository.lastRequestUsedOfflineData &&
          repository.lastRequestOfflineFallbackFromConnectivity;
      if (!offlineMode) _connectivityFailStreak = 0;
    } catch (error, stackTrace) {
      chapterVersesErrors[chapter] = _friendlyError(
        error,
        stackTrace,
        context: 'loadChapterVerses:$chapter',
      );
      _markOfflineFromError(error);
    } finally {
      _chapterVersesLoading.remove(chapter);
      notifyListeners();
    }
  }

  Future<void> refreshChapterVerses(int chapter, {bool force = false}) async {
    await loadChapterVerses(chapter, forceRefresh: force);
  }

  Future<void> refreshVerseChapters() async {
    await refreshChapters(forceRefresh: true);
  }

  Future<void> syncAllVerses({
    bool force = false,
    bool allowDowngradeOverwrite = false,
  }) async {
    if (chapters.isEmpty || force) {
      await refreshChapters(forceRefresh: force);
    }

    final chapterList = List<ChapterSummary>.from(chapters);
    for (final chapter in chapterList) {
      await loadChapterVerses(
        chapter.chapter,
        forceRefresh: force,
      );
    }

    if (allowDowngradeOverwrite) {
      // Compatibility no-op: sync is driven by forceRefresh.
    }
  }

  Future<void> generateMorningGreeting({
    bool force = true,
    bool suppressErrors = false,
  }) async {
    if (morningGreetingLoading) {
      return;
    }

    if (!force && morningGreeting != null) {
      return;
    }

    morningGreetingLoading = true;
    notifyListeners();

    try {
      morningGreeting = await repository.getMorningGreeting(
        mode: guidanceMode,
        language: languageCode,
      );
      await _persistMorningGreeting(morningGreeting!);
      if (offlineMode) unawaited(_persistOfflineMode(false));
      offlineMode = false;
      _connectivityFailStreak = 0;
      if (!suppressErrors) {
        morningGreetingError = null;
      }
    } catch (error, stackTrace) {
      _markOfflineFromError(error);
      if (!suppressErrors) {
        morningGreetingError = _friendlyError(
          error,
          stackTrace,
          context: 'generateMorningGreeting',
        );
      } else {
        // Errors are suppressed for auto-generate (background path) to avoid
        // disrupting the home screen, but we log them for debugging.
        debugPrint(
          'AppState.generateMorningGreeting (suppressed): $error\n$stackTrace',
        );
      }
    } finally {
      morningGreetingLoading = false;
      notifyListeners();
    }
  }

  Future<void> completeOnboardingAnonymous() async {
    final prefs = await SharedPreferences.getInstance();
    onboardingComplete = true;
    anonymousMode = true;
    privacyAnonymous = true;
    email = null;

    await prefs.setBool(_prefOnboardingComplete, true);
    await prefs.setBool(_prefAnonymousMode, true);
    await prefs.setBool(_prefPrivacyAnonymous, true);
    await _secure.delete(key: _prefEmail);

    notifyListeners();
  }

  Future<void> completeOnboardingWithEmail(String newEmail) async {
    final trimmed = newEmail.trim();
    final prefs = await SharedPreferences.getInstance();

    onboardingComplete = true;
    anonymousMode = false;
    privacyAnonymous = false;
    email = trimmed;

    await prefs.setBool(_prefOnboardingComplete, true);
    await prefs.setBool(_prefAnonymousMode, false);
    await prefs.setBool(_prefPrivacyAnonymous, false);
    await _secure.write(key: _prefEmail, value: trimmed);

    notifyListeners();
  }

  Future<bool> setOnboardingPreferences({
    required String mode,
    required String language,
    required bool notificationsEnabled,
    required String notificationWindow,
    int? notificationCustomHour,
    int? notificationCustomMinute,
  }) async {
    guidanceMode = guidanceModeFromCode(mode);
    languageCode = languageOptionFromCode(language).code;
    verseNotificationWindow = _normalizeNotificationWindow(notificationWindow);
    verseNotificationCustomHour = _normalizeHour(
      notificationCustomHour ?? verseNotificationCustomHour,
    );
    verseNotificationCustomMinute = _normalizeMinute(
      notificationCustomMinute ?? verseNotificationCustomMinute,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefGuidanceMode, guidanceMode);
    await prefs.setString(_prefLanguageCode, languageCode);
    await prefs.setString(_prefVerseNotificationWindow, verseNotificationWindow);
    await prefs.setInt(
      _prefVerseNotificationCustomHour,
      verseNotificationCustomHour,
    );
    await prefs.setInt(
      _prefVerseNotificationCustomMinute,
      verseNotificationCustomMinute,
    );
    final enabled = await _setVerseNotificationsEnabled(
      notificationsEnabled,
      prefs: prefs,
    );
    notifyListeners();
    return enabled;
  }

  Future<bool> setVerseNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = await _setVerseNotificationsEnabled(value, prefs: prefs);
    notifyListeners();
    return enabled;
  }

  Future<void> setVerseNotificationsPaused(bool value) async {
    verseNotificationsPaused = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefVerseNotificationsPaused, value);
    await _syncVerseNotifications();
    notifyListeners();
  }

  Future<void> setVerseNotificationWindow(String window) async {
    verseNotificationWindow = _normalizeNotificationWindow(window);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefVerseNotificationWindow, verseNotificationWindow);
    await _syncVerseNotifications();
    notifyListeners();
  }

  Future<void> setVerseNotificationCustomTime({
    required int hour,
    required int minute,
  }) async {
    verseNotificationCustomHour = _normalizeHour(hour);
    verseNotificationCustomMinute = _normalizeMinute(minute);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _prefVerseNotificationCustomHour,
      verseNotificationCustomHour,
    );
    await prefs.setInt(
      _prefVerseNotificationCustomMinute,
      verseNotificationCustomMinute,
    );
    await _syncVerseNotifications();
    notifyListeners();
  }

  Future<void> setGuidanceMode(String mode) async {
    guidanceMode = guidanceModeFromCode(mode);
    morningGreeting = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefGuidanceMode, guidanceMode);
    await _secure.delete(key: _prefMorningGreeting);
    await prefs.remove(_prefMorningGreetingLocalDate);
    await generateMorningGreeting(force: true, suppressErrors: true);
    notifyListeners();
  }

  Future<void> setLanguageCode(String code) async {
    languageCode = languageOptionFromCode(code).code;
    morningGreeting = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefLanguageCode, languageCode);
    await _secure.delete(key: _prefMorningGreeting);
    await prefs.remove(_prefMorningGreetingLocalDate);
    await generateMorningGreeting(force: true, suppressErrors: true);
    await _syncVerseNotifications();
    notifyListeners();
  }

  Future<void> setVoiceInputEnabled(bool value) async {
    voiceInputEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefVoiceInputEnabled, value);
    notifyListeners();
  }

  Future<void> setVoiceOutputEnabled(bool value) async {
    voiceOutputEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefVoiceOutputEnabled, value);
    notifyListeners();
  }

  Future<void> setPrivacyAnonymous(bool value) async {
    privacyAnonymous = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefPrivacyAnonymous, value);
    notifyListeners();
  }

  bool isFavorite(int verseId) {
    return favorites.any((item) => item.verse.id == verseId);
  }

  Future<void> toggleFavorite(Verse verse) async {
    if (isFavorite(verse.id)) {
      await repository.removeFavorite(verse.id);
    } else {
      await repository.addFavorite(verse.id);
    }
    await refreshFavorites();
  }

  List<ChatTurn> buildChatTurns({int maxTurns = 12}) {
    final turns = chatHistory
        .where((entry) => entry.role == 'user' || entry.role == 'assistant')
        .map((entry) => entry.toTurn())
        .toList(growable: false);

    if (turns.length <= maxTurns) {
      return turns;
    }
    return turns.sublist(turns.length - maxTurns);
  }

  Future<void> addChatEntries(List<ChatHistoryEntry> entries) async {
    final merged = <ChatHistoryEntry>[...chatHistory, ...entries];
    if (merged.length > 80) {
      chatHistory = merged.sublist(merged.length - 80);
    } else {
      chatHistory = merged;
    }
    await _persistChatHistory();
    notifyListeners();
  }

  Future<void> clearChatHistory() async {
    chatHistory = const <ChatHistoryEntry>[];
    await _secure.delete(key: _prefChatHistory);
    notifyListeners();
  }

  Future<void> addJournalEntry({
    required String text,
    String? moodTag,
    int? verseId,
    String? verseRef,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final entry = JournalEntry(
      id: 'j_${DateTime.now().microsecondsSinceEpoch}',
      createdAt: DateTime.now(),
      moodTag: moodTag?.trim().isEmpty ?? true ? null : moodTag?.trim(),
      verseId: verseId,
      verseRef: verseRef?.trim().isEmpty ?? true ? null : verseRef?.trim(),
      text: trimmed,
    );

    journalEntries = <JournalEntry>[entry, ...journalEntries].take(500).toList(
          growable: false,
        );
    await _persistJournalEntries();
    notifyListeners();
  }

  Future<void> completeRitual({
    String? reflection,
    String? moodTag,
    int? linkedVerseId,
    String? linkedVerseRef,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    ritualLastCompletedDate = _todayKey();
    await prefs.setString(
        _prefRitualLastCompletedDate, ritualLastCompletedDate!);

    final text = reflection?.trim();
    if (text != null && text.isNotEmpty) {
      final updated = <String>[text, ...ritualReflections];
      ritualReflections = updated.take(30).toList(growable: false);
      await _secure.write(
          key: _prefRitualReflections, value: jsonEncode(ritualReflections));
      await addJournalEntry(
        text: text,
        moodTag: moodTag,
        verseId: linkedVerseId,
        verseRef: linkedVerseRef,
      );
    }

    notifyListeners();
  }

  // ── Bookmark Collections CRUD ──────────────────────────────────────

  Future<void> createCollection(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final collection = BookmarkCollection(
      id: 'col_${DateTime.now().microsecondsSinceEpoch}',
      name: trimmed,
      createdAt: DateTime.now(),
      items: const <BookmarkItem>[],
    );
    bookmarkCollections = <BookmarkCollection>[...bookmarkCollections, collection];
    await _persistBookmarkCollections();
    notifyListeners();
  }

  Future<void> renameCollection(String collectionId, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;

    bookmarkCollections = bookmarkCollections.map((c) {
      if (c.id == collectionId) return c.copyWith(name: trimmed);
      return c;
    }).toList(growable: false);
    await _persistBookmarkCollections();
    notifyListeners();
  }

  Future<void> deleteCollection(String collectionId) async {
    bookmarkCollections = bookmarkCollections
        .where((c) => c.id != collectionId)
        .toList(growable: false);
    await _persistBookmarkCollections();
    notifyListeners();
  }

  Future<void> addItemToCollection(
      String collectionId, BookmarkItem item) async {
    bookmarkCollections = bookmarkCollections.map((c) {
      if (c.id != collectionId) return c;
      // Prevent duplicate verse bookmarks in same collection.
      if (item.type == 'verse' &&
          c.items.any((existing) =>
              existing.type == 'verse' && existing.verseId == item.verseId)) {
        return c;
      }
      return c.copyWith(items: <BookmarkItem>[...c.items, item]);
    }).toList(growable: false);
    await _persistBookmarkCollections();
    notifyListeners();
  }

  Future<void> removeItemFromCollection(
      String collectionId, String itemId) async {
    bookmarkCollections = bookmarkCollections.map((c) {
      if (c.id != collectionId) return c;
      return c.copyWith(
        items: c.items.where((i) => i.id != itemId).toList(growable: false),
      );
    }).toList(growable: false);
    await _persistBookmarkCollections();
    notifyListeners();
  }

  /// Returns collection names that already contain this verse.
  List<String> collectionsContainingVerse(int verseId) {
    return bookmarkCollections
        .where((c) => c.items.any(
            (item) => item.type == 'verse' && item.verseId == verseId))
        .map((c) => c.name)
        .toList(growable: false);
  }

  Future<void> _persistBookmarkCollections() async {
    final payload = bookmarkCollections
        .map((c) => c.toJson())
        .toList(growable: false);
    await _secure.write(key: _prefBookmarkCollections, value: jsonEncode(payload));
  }

  List<BookmarkCollection> _decodeBookmarkCollections(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const <BookmarkCollection>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) {
        return const <BookmarkCollection>[];
      }
      return decoded
          .whereType<Map<String, dynamic>>()
          .map((item) => BookmarkCollection.fromJson(item))
          .toList(growable: false);
    } catch (_) {
      return const <BookmarkCollection>[];
    }
  }

  Future<void> deleteLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefOnboardingComplete);
    await prefs.remove(_prefAnonymousMode);
    await prefs.remove(_prefGuidanceMode);
    await prefs.remove(_prefPrivacyAnonymous);
    await prefs.remove(_prefLanguageCode);
    await prefs.remove(_prefVoiceInputEnabled);
    await prefs.remove(_prefVoiceOutputEnabled);
    await prefs.remove(_prefMorningGreetingLocalDate);
    await prefs.remove(_prefRitualLastCompletedDate);
    await prefs.remove(_prefJourneyProgress);
    await prefs.remove(_prefVerseNotificationsEnabled);
    await prefs.remove(_prefVerseNotificationsPaused);
    await prefs.remove(_prefVerseNotificationWindow);
    await prefs.remove(_prefVerseNotificationCustomHour);
    await prefs.remove(_prefVerseNotificationCustomMinute);

    await _secure.deleteAll();

    onboardingComplete = false;
    anonymousMode = true;
    privacyAnonymous = true;
    email = null;
    guidanceMode = 'comfort';
    languageCode = 'en';
    voiceInputEnabled = true;
    voiceOutputEnabled = false;
    verseNotificationsEnabled = false;
    verseNotificationsPaused = false;
    verseNotificationWindow = notificationWindowMorning;
    verseNotificationCustomHour = _defaultNotificationHour;
    verseNotificationCustomMinute = _defaultNotificationMinute;
    offlineMode = false;
    _connectivityFailStreak = 0;
    unawaited(_persistOfflineMode(false));
    chatHistory = const <ChatHistoryEntry>[];
    morningGreeting = null;
    morningGreetingLoading = false;
    ritualLastCompletedDate = null;
    ritualReflections = const <String>[];
    journalEntries = const <JournalEntry>[];
    bookmarkCollections = const <BookmarkCollection>[];
    _journeyProgressById.clear();
    dailyVerseError = null;
    moodOptionsError = null;
    favoritesError = null;
    _favoritesLoading = false;
    journeysError = null;
    chaptersError = null;
    chapters = const <ChapterSummary>[];
    chapterVerses.clear();
    chapterVersesErrors.clear();
    _chapterVersesLoading.clear();
    chaptersLoading = false;
    morningGreetingError = null;
    await _verseNotificationService.cancelDaily();
    notifyListeners();
  }

  List<ChatHistoryEntry> _decodeChatHistory(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const <ChatHistoryEntry>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) {
        return const <ChatHistoryEntry>[];
      }

      final items = <ChatHistoryEntry>[];
      for (final item in decoded) {
        if (item is Map) {
          final map = item.map(
            (key, value) => MapEntry(key.toString(), value),
          );
          items.add(ChatHistoryEntry.fromJson(map));
        }
      }
      return items;
    } catch (_) {
      return const <ChatHistoryEntry>[];
    }
  }

  Future<void> _persistChatHistory() async {
    final payload =
        chatHistory.map((entry) => entry.toJson()).toList(growable: false);
    await _secure.write(key: _prefChatHistory, value: jsonEncode(payload));
  }

  Future<void> _persistJournalEntries() async {
    final payload =
        journalEntries.map((entry) => entry.toJson()).toList(growable: false);
    await _secure.write(key: _prefJournalEntries, value: jsonEncode(payload));
  }

  Future<void> _persistJourneyProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = _journeyProgressById.map(
      (journeyId, days) {
        final ordered = days.toList(growable: false)..sort();
        return MapEntry(journeyId, ordered);
      },
    );
    await prefs.setString(_prefJourneyProgress, jsonEncode(payload));
  }

  Future<void> _autoGenerateMorningGreetingIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final lastGeneratedDate = prefs.getString(_prefMorningGreetingLocalDate);

    if (lastGeneratedDate == today && morningGreeting != null) {
      return;
    }

    await generateMorningGreeting(force: true, suppressErrors: true);
  }

  Future<void> _persistMorningGreeting(MorningGreeting greeting) async {
    final prefs = await SharedPreferences.getInstance();
    await _secure.write(key: _prefMorningGreeting, value: jsonEncode(greeting.toJson()));
    await prefs.setString(_prefMorningGreetingLocalDate, _todayKey());
  }

  MorningGreeting? _decodeMorningGreeting(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return MorningGreeting.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  List<String> _decodeStringList(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const <String>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) {
        return const <String>[];
      }
      return decoded
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const <String>[];
    }
  }

  List<JournalEntry> _decodeJournalEntries(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const <JournalEntry>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) {
        return const <JournalEntry>[];
      }

      final entries = <JournalEntry>[];
      for (final item in decoded) {
        if (item is Map) {
          final map = item.map(
            (key, value) => MapEntry(key.toString(), value),
          );
          final entry = JournalEntry.fromJson(map);
          if (entry.text.trim().isNotEmpty) {
            entries.add(entry);
          }
        }
      }
      return entries;
    } catch (_) {
      return const <JournalEntry>[];
    }
  }

  Map<String, Set<int>> _decodeJourneyProgress(String? raw) {
    if (raw == null || raw.isEmpty) {
      return <String, Set<int>>{};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return <String, Set<int>>{};
      }

      final progress = <String, Set<int>>{};
      decoded.forEach((journeyId, value) {
        if (value is! List<dynamic>) {
          return;
        }
        final daySet = value
            .map((item) => item is int ? item : int.tryParse('$item'))
            .whereType<int>()
            .where((day) => day > 0)
            .toSet();
        if (daySet.isNotEmpty) {
          progress[journeyId] = daySet;
        }
      });
      return progress;
    } catch (_) {
      return <String, Set<int>>{};
    }
  }

  Future<void> _migrateLegacyRitualReflectionsIfNeeded() async {
    if (journalEntries.isNotEmpty || ritualReflections.isEmpty) {
      return;
    }

    final now = DateTime.now();
    journalEntries = ritualReflections.asMap().entries.map((item) {
      final index = item.key;
      final text = item.value;
      return JournalEntry(
        id: 'legacy_${now.microsecondsSinceEpoch}_$index',
        createdAt: now.subtract(Duration(minutes: index)),
        text: text,
      );
    }).toList(growable: false);
    await _persistJournalEntries();
  }

  Future<bool> _setVerseNotificationsEnabled(
    bool value, {
    required SharedPreferences prefs,
  }) async {
    if (!value) {
      verseNotificationsEnabled = false;
      await prefs.setBool(_prefVerseNotificationsEnabled, false);
      await _verseNotificationService.cancelDaily();
      return false;
    }

    final granted = await _verseNotificationService.requestPermission();
    if (!granted) {
      verseNotificationsEnabled = false;
      await prefs.setBool(_prefVerseNotificationsEnabled, false);
      await _verseNotificationService.cancelDaily();
      return false;
    }

    verseNotificationsEnabled = true;
    await prefs.setBool(_prefVerseNotificationsEnabled, true);
    await _syncVerseNotifications();
    return true;
  }

  Future<void> _syncVerseNotifications() async {
    if (!verseNotificationsEnabled || verseNotificationsPaused) {
      await _verseNotificationService.cancelDaily();
      return;
    }

    final (hour, minute) = _notificationHourAndMinute();
    final strings = AppStrings(languageCode);

    try {
      await _verseNotificationService.scheduleDaily(
        hour: hour,
        minute: minute,
        title: _buildVerseNotificationTitle(strings),
        body: _buildVerseNotificationBody(strings),
      );
    } catch (error, stackTrace) {
      _verseNotificationService.logScheduleError(
        error,
        stackTrace: stackTrace,
        context: 'sync',
      );
    }
  }

  (int, int) _notificationHourAndMinute() {
    switch (verseNotificationWindow) {
      case notificationWindowMorning:
        return (_morningWindowHour, _morningWindowMinute);
      case notificationWindowEvening:
        return (_eveningWindowHour, _eveningWindowMinute);
      default:
        return (verseNotificationCustomHour, verseNotificationCustomMinute);
    }
  }

  String _normalizeNotificationWindow(String value) {
    switch (value) {
      case notificationWindowMorning:
      case notificationWindowEvening:
      case notificationWindowCustom:
        return value;
      default:
        return notificationWindowMorning;
    }
  }

  int _normalizeHour(int value) {
    if (value < 0) {
      return 0;
    }
    if (value > 23) {
      return 23;
    }
    return value;
  }

  int _normalizeMinute(int value) {
    if (value < 0) {
      return 0;
    }
    if (value > 59) {
      return 59;
    }
    return value;
  }

  String _buildVerseNotificationTitle(AppStrings strings) {
    if (dailyVerse != null) {
      return '${strings.t('notification_title')} - BG ${dailyVerse!.ref}';
    }
    return strings.t('notification_title');
  }

  String _buildVerseNotificationBody(AppStrings strings) {
    final verseLine = _shortVerseLine(
      dailyVerse?.translation ?? strings.t('notification_default_verse_line'),
    );
    final prompt = strings.t('notification_reflection_prompt');
    return '$verseLine\n${strings.t('notification_reflect_prefix')}: $prompt';
  }

  String _shortVerseLine(String text) {
    final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= 120) {
      return normalized;
    }
    return '${normalized.substring(0, 120).trimRight()}...';
  }

  String _todayKey() {
    final now = DateTime.now();
    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _friendlyError(
    Object error,
    StackTrace stackTrace, {
    required String context,
  }) {
    return AppErrorMapper.toUserMessage(
      error,
      AppStrings(languageCode),
      stackTrace: stackTrace,
      context: 'AppState.$context',
    );
  }

  void _markOfflineFromError(Object error) {
    if (AppErrorMapper.isConnectivityIssue(error)) {
      _connectivityFailStreak += 1;
      final nowOffline = (_connectivityFailStreak >= 2);
      if (nowOffline != offlineMode) {
        offlineMode = nowOffline;
        unawaited(_persistOfflineMode(offlineMode));
      }
    }
  }

  Future<void> _persistOfflineMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefOfflineMode, value);
  }
}
