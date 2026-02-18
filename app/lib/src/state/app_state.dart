import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../i18n/app_strings.dart';
import '../models/models.dart';
import '../repositories/gita_repository.dart';

class AppState extends ChangeNotifier {
  static const _completeCorpusMin = 700;
  static const _completeCorpusMax = 702;
  static const _partialCorpusThreshold = 650;
  static const _downgradeProtectionLocalThreshold = 650;
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
  static const _prefRitualLastCompletedDate = 'ritual_last_completed_local_date';
  static const _prefRitualReflections = 'ritual_reflections';
  static const _prefRitualStreakDays = 'ritual_streak_days';
  static const _prefRitualStreakLastDate = 'ritual_streak_last_date';

  final GitaRepository repository;

  bool initialized = false;
  bool onboardingComplete = false;
  bool anonymousMode = true;
  bool privacyAnonymous = true;
  String? email;
  String guidanceMode = 'comfort';
  String languageCode = 'en';
  bool voiceInputEnabled = true;
  bool voiceOutputEnabled = false;

  bool loading = false;
  String? dailyVerseError;
  String? moodOptionsError;
  String? favoritesError;
  String? journeysError;
  String? morningGreetingError;
  Verse? dailyVerse;
  MorningGreeting? morningGreeting;
  bool morningGreetingLoading = false;
  List<String> moodOptions = const <String>[];
  List<FavoriteItem> favorites = const <FavoriteItem>[];
  List<Journey> journeys = const <Journey>[];
  bool favoritesLoading = false;
  bool journeysLoading = false;
  bool versesLoading = false;
  String? versesError;
  bool versesSyncPartialWarning = false;
  String? versesSyncWarningMessage;
  List<ChapterSummary> chapters = const <ChapterSummary>[];
  final Map<int, List<Verse>> chapterVerseCache = <int, List<Verse>>{};
  int totalVersesAvailable = 0;
  int remoteVerseTotal = 0;
  bool _verseStatsLogged = false;
  List<ChatHistoryEntry> chatHistory = const <ChatHistoryEntry>[];
  String? ritualLastCompletedDate;
  List<String> ritualReflections = const <String>[];
  int ritualStreakDays = 0;
  String? ritualStreakLastDate;

  bool get ritualCompletedToday => ritualLastCompletedDate == _todayKey();

  AppState({required this.repository});

  Future<void> initialize() async {
    if (initialized) {
      return;
    }

    loading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    onboardingComplete = prefs.getBool(_prefOnboardingComplete) ?? false;
    anonymousMode = prefs.getBool(_prefAnonymousMode) ?? true;
    privacyAnonymous = prefs.getBool(_prefPrivacyAnonymous) ?? anonymousMode;
    email = prefs.getString(_prefEmail);
    guidanceMode = prefs.getString(_prefGuidanceMode) ?? 'comfort';
    final languageCandidate = prefs.getString(_prefLanguageCode) ?? 'en';
    languageCode = languageOptionFromCode(languageCandidate).code;
    voiceInputEnabled = prefs.getBool(_prefVoiceInputEnabled) ?? true;
    voiceOutputEnabled = prefs.getBool(_prefVoiceOutputEnabled) ?? false;
    chatHistory = _decodeChatHistory(prefs.getString(_prefChatHistory));
    morningGreeting =
        _decodeMorningGreeting(prefs.getString(_prefMorningGreeting));
    ritualLastCompletedDate = prefs.getString(_prefRitualLastCompletedDate);
    ritualReflections = _decodeStringList(prefs.getString(_prefRitualReflections));
    ritualStreakDays = prefs.getInt(_prefRitualStreakDays) ?? 0;
    ritualStreakLastDate = prefs.getString(_prefRitualStreakLastDate);

    await Future.wait(<Future<void>>[
      refreshDailyVerse(),
      refreshMoodOptions(),
      refreshFavorites(),
      refreshJourneys(),
      refreshVerseChapters(),
    ]);

    // Retry once after initial warm-up to reduce startup race failures.
    if (dailyVerse == null) {
      await Future<void>.delayed(const Duration(milliseconds: 750));
      await refreshDailyVerse();
    }

    loading = false;
    initialized = true;
    notifyListeners();
    unawaited(_autoGenerateMorningGreetingIfNeeded());
  }

  Future<void> refreshDailyVerse() async {
    try {
      dailyVerse = await repository.getDailyVerse();
      dailyVerseError = null;
    } catch (error) {
      dailyVerseError = error.toString();
    }
    notifyListeners();
  }

  Future<void> refreshMoodOptions() async {
    try {
      moodOptions = await repository.getMoodOptions();
      moodOptionsError = null;
    } catch (error) {
      moodOptions = const <String>[];
      moodOptionsError = error.toString();
    }
    notifyListeners();
  }

  Future<void> refreshFavorites() async {
    favoritesLoading = true;
    notifyListeners();
    try {
      favorites = await repository.getFavorites();
      favoritesError = null;
    } catch (error) {
      favorites = const <FavoriteItem>[];
      favoritesError = error.toString();
    } finally {
      favoritesLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshJourneys() async {
    journeysLoading = true;
    notifyListeners();
    try {
      journeys = await repository.getJourneys();
      journeysError = null;
    } catch (error) {
      journeys = const <Journey>[];
      journeysError = error.toString();
    } finally {
      journeysLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshVerseChapters() async {
    versesLoading = true;
    notifyListeners();
    try {
      chapters = await repository.getChapters();
      totalVersesAvailable = _cachedVerseCount();
      versesError = null;
    } catch (error) {
      chapters = List<ChapterSummary>.generate(
        18,
        (index) => ChapterSummary(chapter: index + 1, verseCount: 0),
        growable: false,
      );
      versesError = error.toString();
    } finally {
      versesLoading = false;
      notifyListeners();
    }
  }

  List<Verse> chapterVersesFor(int chapter) {
    return chapterVerseCache[chapter] ?? const <Verse>[];
  }

  Future<void> refreshChapterVerses(
    int chapter, {
    bool force = false,
    int pageSize = 200,
  }) async {
    if (!force && chapterVerseCache.containsKey(chapter)) {
      return;
    }

    versesLoading = true;
    notifyListeners();

    final loadedByKey = <String, Verse>{};
    var offset = 0;
    var hasMore = true;
    var remoteTotal = 0;
    try {
      while (hasMore) {
        final page = await repository.getChapterVerses(
          chapter: chapter,
          offset: offset,
          limit: pageSize,
        );

        final itemsReturned = page.items.length;
        debugPrint(
          'chapter_page chapter=$chapter offset=$offset '
          'received=$itemsReturned has_more=${page.hasMore}',
        );
        remoteTotal = page.total;
        if (itemsReturned == 0) {
          break;
        }
        for (final verse in page.items) {
          loadedByKey[_verseDedupeKey(verse)] = verse;
        }
        offset += itemsReturned;
        hasMore = page.hasMore;
      }

      final loaded = loadedByKey.values.toList(growable: false)
        ..sort(_compareVerseOrder);
      final existing = chapterVerseCache[chapter];
      if (loaded.isNotEmpty && (existing == null || loaded.length >= existing.length)) {
        chapterVerseCache[chapter] = List<Verse>.unmodifiable(loaded);
      } else if (remoteTotal > 0 && existing != null && remoteTotal >= existing.length) {
        chapterVerseCache[chapter] = List<Verse>.unmodifiable(loaded);
      } else if (existing != null && loaded.length < existing.length) {
        debugPrint(
          'Skipping partial chapter overwrite for chapter $chapter '
          '(loaded=${loaded.length}, existing=${existing.length})',
        );
      }
      totalVersesAvailable = _cachedVerseCount();
      versesError = null;
    } catch (error) {
      versesError = error.toString();
    } finally {
      versesLoading = false;
      notifyListeners();
    }
  }

  Future<void> syncAllVerses({
    bool force = false,
    bool allowDowngradeOverwrite = false,
    int pageSize = 200,
  }) async {
    if (!force &&
        chapterVerseCache.isNotEmpty &&
        _isCompleteCorpusTotal(totalVersesAvailable)) {
      return;
    }

    versesLoading = true;
    notifyListeners();

    final loadedByKey = <String, Verse>{};
    var offset = 0;
    var remoteTotal = 0;
    var actionTaken = 'no_change';
    final localTotal = _cachedVerseCount();
    try {
      final stats = await repository.getVerseStats();
      remoteTotal = stats.totalVerses;
      remoteVerseTotal = remoteTotal;
      if (!_verseStatsLogged) {
        debugPrint('verse_totals local=$localTotal remote=$remoteTotal');
        _verseStatsLogged = true;
      }

      while (true) {
        final page = await repository.getVersesPage(
          offset: offset,
          limit: pageSize,
        );
        final itemsReturned = page.length;
        debugPrint('verse_page offset=$offset received=$itemsReturned');
        if (itemsReturned == 0) {
          break;
        }
        for (final verse in page) {
          loadedByKey[_verseDedupeKey(verse)] = verse;
        }
        offset += itemsReturned;
        if (itemsReturned < pageSize || (remoteTotal > 0 && offset >= remoteTotal)) {
          break;
        }
      }

      final loaded = loadedByKey.values.toList(growable: false)
        ..sort(_compareVerseOrder);
      final loadedTotal = loaded.length;
      final effectiveRemoteTotal = remoteTotal > 0 ? remoteTotal : loadedTotal;
      final remoteIsPartial =
          effectiveRemoteTotal > 0 && effectiveRemoteTotal < _partialCorpusThreshold;
      final shouldBlockOverwrite = !allowDowngradeOverwrite &&
          localTotal >= _downgradeProtectionLocalThreshold &&
          effectiveRemoteTotal < (localTotal * 0.9).floor();

      versesSyncPartialWarning = false;
      versesSyncWarningMessage = null;

      if (localTotal == 0) {
        if (loadedTotal > 0) {
          chapterVerseCache
            ..clear()
            ..addAll(_groupVersesByChapter(loaded));
          totalVersesAvailable = loadedTotal;
          actionTaken = 'initial_load';
        } else {
          actionTaken = 'initial_empty';
        }
      } else if (shouldBlockOverwrite) {
        totalVersesAvailable = localTotal;
        actionTaken = 'blocked_partial_remote';
        versesSyncPartialWarning = true;
        versesSyncWarningMessage = AppStrings(languageCode)
            .t('verses_sync_incomplete_server_keep_offline');
      } else if (allowDowngradeOverwrite && loadedTotal > 0) {
        chapterVerseCache
          ..clear()
          ..addAll(_groupVersesByChapter(loaded));
        totalVersesAvailable = loadedTotal;
        actionTaken = 'force_resync_overwrite';
      } else if (effectiveRemoteTotal >= localTotal && loadedTotal > 0) {
        chapterVerseCache
          ..clear()
          ..addAll(_groupVersesByChapter(loaded));
        totalVersesAvailable = loadedTotal;
        actionTaken = 'refreshed';
      } else {
        totalVersesAvailable = localTotal;
        actionTaken = 'kept_local';
      }

      if (!versesSyncPartialWarning && remoteIsPartial) {
        versesSyncPartialWarning = true;
        versesSyncWarningMessage =
            AppStrings(languageCode).t('verses_sync_partial_server_warning');
      }
      versesError = null;
      debugPrint(
        'verse_sync_guard localTotal=$localTotal '
        'remoteTotal=$effectiveRemoteTotal action=$actionTaken '
        'allowDowngradeOverwrite=$allowDowngradeOverwrite',
      );
    } catch (error) {
      versesError = error.toString();
    } finally {
      versesLoading = false;
      notifyListeners();
    }
  }

  Future<Verse?> randomVerse() async {
    if (chapterVerseCache.isEmpty) {
      await syncAllVerses();
    }
    final all = chapterVerseCache.values
        .expand((verses) => verses)
        .toList(growable: false);
    if (all.isNotEmpty) {
      return all[Random().nextInt(all.length)];
    }
    return dailyVerse;
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
      if (!suppressErrors) {
        morningGreetingError = null;
      }
    } catch (error) {
      if (!suppressErrors) {
        morningGreetingError = error.toString();
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
    await prefs.remove(_prefEmail);

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
    await prefs.setString(_prefEmail, trimmed);

    notifyListeners();
  }

  Future<void> setGuidanceMode(String mode) async {
    guidanceMode = mode;
    morningGreeting = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefGuidanceMode, mode);
    await prefs.remove(_prefMorningGreeting);
    await prefs.remove(_prefMorningGreetingLocalDate);
    await generateMorningGreeting(force: true, suppressErrors: true);
    notifyListeners();
  }

  Future<void> setLanguageCode(String code) async {
    languageCode = languageOptionFromCode(code).code;
    morningGreeting = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefLanguageCode, languageCode);
    await prefs.remove(_prefMorningGreeting);
    await prefs.remove(_prefMorningGreetingLocalDate);
    await generateMorningGreeting(force: true, suppressErrors: true);
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
    HapticFeedback.lightImpact();
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefChatHistory);
    notifyListeners();
  }

  Future<void> completeRitual({String? reflection}) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final alreadyCompletedToday = ritualLastCompletedDate == today;
    ritualLastCompletedDate = today;
    await prefs.setString(_prefRitualLastCompletedDate, ritualLastCompletedDate!);

    if (!alreadyCompletedToday) {
      if (ritualStreakLastDate != null && _isYesterday(ritualStreakLastDate!, today)) {
        ritualStreakDays += 1;
      } else {
        ritualStreakDays = 1;
      }
      ritualStreakLastDate = today;
      await prefs.setInt(_prefRitualStreakDays, ritualStreakDays);
      await prefs.setString(_prefRitualStreakLastDate, ritualStreakLastDate!);
    }

    final text = reflection?.trim();
    if (text != null && text.isNotEmpty) {
      final updated = <String>[text, ...ritualReflections];
      ritualReflections = updated.take(30).toList(growable: false);
      await prefs.setString(_prefRitualReflections, jsonEncode(ritualReflections));
    }

    notifyListeners();
  }

  Future<void> deleteLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefOnboardingComplete);
    await prefs.remove(_prefAnonymousMode);
    await prefs.remove(_prefEmail);
    await prefs.remove(_prefGuidanceMode);
    await prefs.remove(_prefPrivacyAnonymous);
    await prefs.remove(_prefLanguageCode);
    await prefs.remove(_prefVoiceInputEnabled);
    await prefs.remove(_prefVoiceOutputEnabled);
    await prefs.remove(_prefChatHistory);
    await prefs.remove(_prefMorningGreeting);
    await prefs.remove(_prefMorningGreetingLocalDate);
    await prefs.remove(_prefRitualLastCompletedDate);
    await prefs.remove(_prefRitualReflections);
    await prefs.remove(_prefRitualStreakDays);
    await prefs.remove(_prefRitualStreakLastDate);

    onboardingComplete = false;
    anonymousMode = true;
    privacyAnonymous = true;
    email = null;
    guidanceMode = 'comfort';
    languageCode = 'en';
    voiceInputEnabled = true;
    voiceOutputEnabled = false;
    chatHistory = const <ChatHistoryEntry>[];
    morningGreeting = null;
    morningGreetingLoading = false;
    ritualLastCompletedDate = null;
    ritualReflections = const <String>[];
    ritualStreakDays = 0;
    ritualStreakLastDate = null;
    chapters = const <ChapterSummary>[];
    chapterVerseCache.clear();
    totalVersesAvailable = 0;
    remoteVerseTotal = 0;
    versesSyncPartialWarning = false;
    versesSyncWarningMessage = null;
    _verseStatsLogged = false;
    versesLoading = false;
    versesError = null;
    dailyVerseError = null;
    moodOptionsError = null;
    favoritesError = null;
    journeysError = null;
    morningGreetingError = null;
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
    final prefs = await SharedPreferences.getInstance();
    final payload =
        chatHistory.map((entry) => entry.toJson()).toList(growable: false);
    await prefs.setString(_prefChatHistory, jsonEncode(payload));
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
    await prefs.setString(_prefMorningGreeting, jsonEncode(greeting.toJson()));
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

  int _cachedVerseCount() {
    return chapterVerseCache.values.fold<int>(
      0,
      (sum, verses) => sum + verses.length,
    );
  }

  bool _isCompleteCorpusTotal(int total) {
    return total >= _completeCorpusMin && total <= _completeCorpusMax;
  }

  String _verseDedupeKey(Verse verse) {
    if (verse.id > 0) {
      return 'id:${verse.id}';
    }
    return 'ref:${verse.ref}';
  }

  int _safeVerseNumber(Verse verse) {
    if (verse.verseNumber > 0) {
      return verse.verseNumber;
    }
    final pieces = verse.ref.split('.');
    if (pieces.isNotEmpty) {
      final parsed = int.tryParse(pieces.last.trim());
      if (parsed != null) {
        return parsed;
      }
    }
    return 1 << 30;
  }

  int _compareVerseOrder(Verse a, Verse b) {
    final chapterCompare = a.chapter.compareTo(b.chapter);
    if (chapterCompare != 0) {
      return chapterCompare;
    }
    final verseCompare = _safeVerseNumber(a).compareTo(_safeVerseNumber(b));
    if (verseCompare != 0) {
      return verseCompare;
    }
    return a.id.compareTo(b.id);
  }

  Map<int, List<Verse>> _groupVersesByChapter(List<Verse> verses) {
    final grouped = <int, List<Verse>>{};
    for (final verse in verses) {
      grouped.putIfAbsent(verse.chapter, () => <Verse>[]).add(verse);
    }
    return grouped.map((chapter, values) {
      values.sort(_compareVerseOrder);
      return MapEntry(chapter, List<Verse>.unmodifiable(values));
    });
  }

  bool _isYesterday(String earlier, String later) {
    final first = DateTime.tryParse(earlier);
    final second = DateTime.tryParse(later);
    if (first == null || second == null) {
      return false;
    }
    return second.difference(first).inDays == 1;
  }

  String _todayKey() {
    final now = DateTime.now();
    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
