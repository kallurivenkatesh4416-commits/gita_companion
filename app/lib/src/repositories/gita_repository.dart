import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../models/models.dart';

class GitaRepository {
  static const String _offlineVerseBundlePath = 'assets/data/gita_verses_sample.json';
  static const String _prefOfflineChapters = 'offline_chapters_cache_v1';
  static const String _prefOfflineVersesPrefix = 'offline_verses_chapter_';
  static const String _prefOfflineDailyVerse = 'offline_daily_verse_cache_v1';

  final ApiClient _apiClient;
  List<ChapterSummary>? _chaptersCache;
  final Map<int, List<Verse>> _chapterVerseCache = <int, List<Verse>>{};
  final Map<int, Verse> _verseByIdCache = <int, Verse>{};
  List<Verse>? _bundledVerses;
  bool lastRequestUsedOfflineData = false;

  GitaRepository(this._apiClient);

  Future<void> healthCheck() => _apiClient.healthCheck();

  Future<Verse> getDailyVerse() async {
    try {
      final verse = await _apiClient.fetchDailyVerse();
      lastRequestUsedOfflineData = false;
      _verseByIdCache[verse.id] = verse;
      await _persistDailyVerse(verse);
      return verse;
    } catch (_) {
      final cached = await _loadCachedDailyVerse();
      if (cached != null) {
        _verseByIdCache[cached.id] = cached;
        lastRequestUsedOfflineData = true;
        return cached;
      }

      final bundled = await _loadBundledVerses();
      if (bundled.isNotEmpty) {
        final verse = bundled.first;
        _verseByIdCache[verse.id] = verse;
        lastRequestUsedOfflineData = true;
        return verse;
      }
      rethrow;
    }
  }

  Future<List<ChapterSummary>> getChapters({bool forceRefresh = false}) async {
    if (!forceRefresh && _chaptersCache != null) {
      lastRequestUsedOfflineData = false;
      return _chaptersCache!;
    }

    try {
      final chapters = await _apiClient.fetchChapters();
      _chaptersCache = chapters;
      lastRequestUsedOfflineData = false;
      await _persistChapters(chapters);
      return chapters;
    } catch (_) {
      final cached = await _loadCachedChapters();
      if (cached.isNotEmpty) {
        _chaptersCache = cached;
        lastRequestUsedOfflineData = true;
        return cached;
      }

      final bundled = await _loadBundledChapters();
      if (bundled.isNotEmpty) {
        _chaptersCache = bundled;
        lastRequestUsedOfflineData = true;
        return bundled;
      }
      rethrow;
    }
  }

  Future<List<Verse>> getVersesByChapter(
    int chapter, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _chapterVerseCache.containsKey(chapter)) {
      lastRequestUsedOfflineData = false;
      return _chapterVerseCache[chapter]!;
    }

    try {
      final verses = await _apiClient.fetchVerses(chapter: chapter);
      _storeChapterVerses(chapter, verses);
      lastRequestUsedOfflineData = false;
      await _persistVersesForChapter(chapter, verses);
      return verses;
    } catch (_) {
      final cached = await _loadCachedVersesForChapter(chapter);
      if (cached.isNotEmpty) {
        _storeChapterVerses(chapter, cached);
        lastRequestUsedOfflineData = true;
        return cached;
      }

      final bundled = await _loadBundledVersesForChapter(chapter);
      if (bundled.isNotEmpty) {
        _storeChapterVerses(chapter, bundled);
        lastRequestUsedOfflineData = true;
        return bundled;
      }
      rethrow;
    }
  }

  Future<List<String>> getMoodOptions() => _apiClient.fetchMoodOptions();

  Future<GuidanceResponse> ask({
    required String question,
    required String mode,
    required String language,
  }) {
    return _apiClient.askQuestion(
      question: question,
      mode: mode,
      language: language,
    );
  }

  Future<ChatResponse> chat({
    required String message,
    required String mode,
    required String language,
    List<ChatTurn> history = const <ChatTurn>[],
  }) {
    return _apiClient.chat(
      message: message,
      mode: mode,
      language: language,
      history: history,
    );
  }

  Stream<ChatStreamEvent> streamChat({
    required String message,
    required String mode,
    required String language,
    List<ChatTurn> history = const <ChatTurn>[],
  }) {
    return _apiClient.streamChat(
      message: message,
      mode: mode,
      language: language,
      history: history,
    );
  }

  Future<GuidanceResponse> moodGuidance({
    required List<String> moods,
    required String mode,
    required String language,
    String? note,
  }) {
    return _apiClient.moodGuidance(
      moods: moods,
      mode: mode,
      language: language,
      note: note,
    );
  }

  Future<Verse> getVerseById(
    int verseId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _verseByIdCache.containsKey(verseId)) {
      lastRequestUsedOfflineData = false;
      return _verseByIdCache[verseId]!;
    }

    try {
      final verse = await _apiClient.fetchVerseById(verseId);
      _verseByIdCache[verse.id] = verse;
      lastRequestUsedOfflineData = false;
      return verse;
    } catch (_) {
      final cached = await _findVerseInOfflineSources(verseId);
      if (cached != null) {
        _verseByIdCache[cached.id] = cached;
        lastRequestUsedOfflineData = true;
        return cached;
      }
      rethrow;
    }
  }

  Future<List<Verse>> getVersesPage({
    required int offset,
    int limit = 200,
  }) {
    return _apiClient.fetchVersesPage(offset: offset, limit: limit);
  }

  Future<VerseStats> getVerseStats() => _apiClient.fetchVerseStats();

  Future<List<ChapterSummary>> getChapters() => _apiClient.fetchChapters();

  Future<ChapterVersesPage> getChapterVerses({
    required int chapter,
    required int offset,
    int limit = 200,
  }) {
    return _apiClient.fetchChapterVerses(
      chapter: chapter,
      offset: offset,
      limit: limit,
    );
  }

  Future<List<FavoriteItem>> getFavorites() => _apiClient.fetchFavorites();

  Future<FavoriteItem> addFavorite(int verseId) =>
      _apiClient.addFavorite(verseId);

  Future<void> removeFavorite(int verseId) =>
      _apiClient.removeFavorite(verseId);

  Future<List<Journey>> getJourneys() => _apiClient.fetchJourneys();

  Future<MorningGreeting> getMorningGreeting({
    required String mode,
    required String language,
  }) {
    return _apiClient.fetchMorningGreeting(mode: mode, language: language);
  }

  Future<void> _persistChapters(List<ChapterSummary> chapters) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = chapters
        .map((chapter) => <String, dynamic>{
              'chapter': chapter.chapter,
              'name': chapter.name,
              'verse_count': chapter.verseCount,
              'summary': chapter.summary,
            })
        .toList(growable: false);
    await prefs.setString(_prefOfflineChapters, jsonEncode(payload));
  }

  Future<List<ChapterSummary>> _loadCachedChapters() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefOfflineChapters);
    if (raw == null || raw.isEmpty) {
      return const <ChapterSummary>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) {
        return const <ChapterSummary>[];
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(ChapterSummary.fromJson)
          .toList(growable: false);
    } catch (_) {
      return const <ChapterSummary>[];
    }
  }

  Future<void> _persistVersesForChapter(int chapter, List<Verse> verses) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = verses
        .map((verse) => <String, dynamic>{
              'id': verse.id,
              'chapter': verse.chapter,
              'verse_number': verse.verseNumber,
              'ref': verse.ref,
              'sanskrit': verse.sanskrit,
              'transliteration': verse.transliteration,
              'translation': verse.translation,
              'tags': verse.tags,
            })
        .toList(growable: false);
    await prefs.setString(
      '$_prefOfflineVersesPrefix$chapter',
      jsonEncode(payload),
    );
  }

  Future<void> _persistDailyVerse(Verse verse) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = <String, dynamic>{
      'id': verse.id,
      'chapter': verse.chapter,
      'verse_number': verse.verseNumber,
      'ref': verse.ref,
      'sanskrit': verse.sanskrit,
      'transliteration': verse.transliteration,
      'translation': verse.translation,
      'tags': verse.tags,
    };
    await prefs.setString(_prefOfflineDailyVerse, jsonEncode(payload));
  }

  Future<Verse?> _loadCachedDailyVerse() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefOfflineDailyVerse);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return Verse.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<List<Verse>> _loadCachedVersesForChapter(int chapter) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefOfflineVersesPrefix$chapter');
    if (raw == null || raw.isEmpty) {
      return const <Verse>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) {
        return const <Verse>[];
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(Verse.fromJson)
          .toList(growable: false);
    } catch (_) {
      return const <Verse>[];
    }
  }

  Future<List<Verse>> _loadBundledVerses() async {
    if (_bundledVerses != null) {
      return _bundledVerses!;
    }

    try {
      final raw = await rootBundle.loadString(_offlineVerseBundlePath);
      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) {
        _bundledVerses = const <Verse>[];
        return _bundledVerses!;
      }

      int syntheticId = 900000;
      _bundledVerses = decoded
          .whereType<Map<String, dynamic>>()
          .map((entry) {
            final chapter = (entry['chapter'] as num?)?.toInt() ?? 0;
            final verseNumber = (entry['verse'] as num?)?.toInt() ?? 0;
            final ref = entry['ref'] as String? ?? '$chapter.$verseNumber';
            syntheticId += 1;
            return Verse(
              id: syntheticId,
              chapter: chapter,
              verseNumber: verseNumber,
              ref: ref,
              sanskrit: entry['sanskrit'] as String? ?? '',
              transliteration: entry['transliteration'] as String? ?? '',
              translation: entry['translation'] as String? ?? '',
              tags: (entry['tags'] as List<dynamic>? ?? const <dynamic>[])
                  .map((item) => item.toString())
                  .toList(growable: false),
            );
          })
          .where((verse) => verse.chapter > 0 && verse.verseNumber > 0)
          .toList(growable: false);
      return _bundledVerses!;
    } catch (_) {
      _bundledVerses = const <Verse>[];
      return _bundledVerses!;
    }
  }

  Future<List<ChapterSummary>> _loadBundledChapters() async {
    final verses = await _loadBundledVerses();
    if (verses.isEmpty) {
      return const <ChapterSummary>[];
    }

    final grouped = <int, int>{};
    for (final verse in verses) {
      grouped[verse.chapter] = (grouped[verse.chapter] ?? 0) + 1;
    }

    final chapters = grouped.entries.toList(growable: false)
      ..sort((a, b) => a.key.compareTo(b.key));

    return chapters
        .map(
          (entry) => ChapterSummary(
            chapter: entry.key,
            name: 'Chapter ${entry.key}',
            verseCount: entry.value,
            summary: '',
          ),
        )
        .toList(growable: false);
  }

  Future<List<Verse>> _loadBundledVersesForChapter(int chapter) async {
    final verses = await _loadBundledVerses();
    if (verses.isEmpty) {
      return const <Verse>[];
    }

    return verses
        .where((verse) => verse.chapter == chapter)
        .toList(growable: false);
  }

  void _storeChapterVerses(int chapter, List<Verse> verses) {
    _chapterVerseCache[chapter] = verses;
    for (final verse in verses) {
      _verseByIdCache[verse.id] = verse;
    }
  }

  Future<Verse?> _findVerseInOfflineSources(int verseId) async {
    for (final chapterVerses in _chapterVerseCache.values) {
      for (final verse in chapterVerses) {
        if (verse.id == verseId) {
          return verse;
        }
      }
    }

    for (int chapter = 1; chapter <= 18; chapter += 1) {
      final cached = await _loadCachedVersesForChapter(chapter);
      for (final verse in cached) {
        if (verse.id == verseId) {
          return verse;
        }
      }
    }

    final bundled = await _loadBundledVerses();
    for (final verse in bundled) {
      if (verse.id == verseId) {
        return verse;
      }
    }
    return null;
  }
}
