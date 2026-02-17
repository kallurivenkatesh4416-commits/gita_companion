import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../i18n/app_strings.dart';
import '../models/models.dart';
import '../repositories/gita_repository.dart';

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
  List<ChatHistoryEntry> chatHistory = const <ChatHistoryEntry>[];

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

    await Future.wait(<Future<void>>[
      refreshDailyVerse(),
      refreshMoodOptions(),
      refreshFavorites(),
      refreshJourneys(),
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
    try {
      favorites = await repository.getFavorites();
      favoritesError = null;
    } catch (error) {
      favorites = const <FavoriteItem>[];
      favoritesError = error.toString();
    }
    notifyListeners();
  }

  Future<void> refreshJourneys() async {
    try {
      journeys = await repository.getJourneys();
      journeysError = null;
    } catch (error) {
      journeys = const <Journey>[];
      journeysError = error.toString();
    }
    notifyListeners();
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

  String _todayKey() {
    final now = DateTime.now();
    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
