import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../repositories/gita_repository.dart';

class AppState extends ChangeNotifier {
  static const _prefOnboardingComplete = 'onboarding_complete';
  static const _prefAnonymousMode = 'anonymous_mode';
  static const _prefEmail = 'email';
  static const _prefGuidanceMode = 'guidance_mode';
  static const _prefPrivacyAnonymous = 'privacy_anonymous';

  final GitaRepository repository;

  bool initialized = false;
  bool onboardingComplete = false;
  bool anonymousMode = true;
  bool privacyAnonymous = true;
  String? email;
  String guidanceMode = 'comfort';

  bool loading = false;
  String? errorMessage;
  Verse? dailyVerse;
  List<String> moodOptions = const <String>[];
  List<FavoriteItem> favorites = const <FavoriteItem>[];
  List<Journey> journeys = const <Journey>[];

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

    await Future.wait(<Future<void>>[
      refreshDailyVerse(),
      refreshMoodOptions(),
      refreshFavorites(),
      refreshJourneys(),
    ]);

    loading = false;
    initialized = true;
    notifyListeners();
  }

  Future<void> refreshDailyVerse() async {
    try {
      dailyVerse = await repository.getDailyVerse();
      errorMessage = null;
    } catch (error) {
      errorMessage = error.toString();
    }
    notifyListeners();
  }

  Future<void> refreshMoodOptions() async {
    try {
      moodOptions = await repository.getMoodOptions();
      errorMessage = null;
    } catch (error) {
      moodOptions = const <String>[];
      errorMessage = error.toString();
    }
    notifyListeners();
  }

  Future<void> refreshFavorites() async {
    try {
      favorites = await repository.getFavorites();
      errorMessage = null;
    } catch (error) {
      favorites = const <FavoriteItem>[];
      errorMessage = error.toString();
    }
    notifyListeners();
  }

  Future<void> refreshJourneys() async {
    try {
      journeys = await repository.getJourneys();
      errorMessage = null;
    } catch (error) {
      journeys = const <Journey>[];
      errorMessage = error.toString();
    }
    notifyListeners();
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefGuidanceMode, mode);
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

  Future<void> deleteLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefOnboardingComplete);
    await prefs.remove(_prefAnonymousMode);
    await prefs.remove(_prefEmail);
    await prefs.remove(_prefGuidanceMode);
    await prefs.remove(_prefPrivacyAnonymous);

    onboardingComplete = false;
    anonymousMode = true;
    privacyAnonymous = true;
    email = null;
    guidanceMode = 'comfort';
    notifyListeners();
  }
}
