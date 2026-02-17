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
  }) {
    return _apiClient.askQuestion(question: question, mode: mode);
  }

  Future<ChatResponse> chat({
    required String message,
    required String mode,
    List<ChatTurn> history = const <ChatTurn>[],
  }) {
    return _apiClient.chat(message: message, mode: mode, history: history);
  }

  Future<GuidanceResponse> moodGuidance({
    required List<String> moods,
    required String mode,
    String? note,
  }) {
    return _apiClient.moodGuidance(moods: moods, mode: mode, note: note);
  }

  Future<Verse> getVerseById(int verseId) => _apiClient.fetchVerseById(verseId);

  Future<List<FavoriteItem>> getFavorites() => _apiClient.fetchFavorites();

  Future<FavoriteItem> addFavorite(int verseId) => _apiClient.addFavorite(verseId);

  Future<void> removeFavorite(int verseId) => _apiClient.removeFavorite(verseId);

  Future<List<Journey>> getJourneys() => _apiClient.fetchJourneys();
}
