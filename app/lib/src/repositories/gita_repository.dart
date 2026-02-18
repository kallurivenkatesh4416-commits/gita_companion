import '../api/api_client.dart';
import '../models/models.dart';

class GitaRepository {
  final ApiClient _apiClient;

  GitaRepository(this._apiClient);

  Future<void> healthCheck() => _apiClient.healthCheck();

  Future<Verse> getDailyVerse() => _apiClient.fetchDailyVerse();

  Future<List<String>> getMoodOptions() => _apiClient.fetchMoodOptions();

  Future<GuidanceResponse> ask({
    required String question,
    required String mode,
    required String language,
  }) {
    return _apiClient.askQuestion(
        question: question, mode: mode, language: language);
  }

  Future<ChatResponse> chat({
    required String message,
    required String mode,
    required String language,
    List<ChatTurn> history = const <ChatTurn>[],
  }) {
    return _apiClient.chat(
        message: message, mode: mode, language: language, history: history);
  }

  Future<GuidanceResponse> moodGuidance({
    required List<String> moods,
    required String mode,
    required String language,
    String? note,
  }) {
    return _apiClient.moodGuidance(
        moods: moods, mode: mode, language: language, note: note);
  }

  Future<Verse> getVerseById(int verseId) => _apiClient.fetchVerseById(verseId);

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
}
