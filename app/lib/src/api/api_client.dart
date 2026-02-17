import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/models.dart';

class ApiException implements Exception {
  final String message;

  const ApiException(this.message);

  @override
  String toString() => message;
}

class ApiClient {
  final String baseUrl;
  final http.Client _httpClient;

  ApiClient({String? baseUrl, http.Client? httpClient})
      : baseUrl = _resolveBaseUrl(baseUrl),
        _httpClient = httpClient ?? http.Client();

  static String _resolveBaseUrl(String? override) {
    if (override != null && override.trim().isNotEmpty) {
      return override.trim();
    }

    const envBase = String.fromEnvironment('API_BASE_URL');
    if (envBase.isNotEmpty) {
      return envBase;
    }

    if (kIsWeb) {
      return 'http://localhost:8000';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }

    return 'http://localhost:8000';
  }

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<void> healthCheck() async {
    final response = await _httpClient.get(_uri('/health'));
    _ensureOk(response);
  }

  Future<Verse> fetchDailyVerse() async {
    final response = await _httpClient.get(_uri('/daily-verse'));
    _ensureOk(response);
    return Verse.fromJson(_decodeMap(response.body));
  }

  Future<List<String>> fetchMoodOptions() async {
    final response = await _httpClient.get(_uri('/moods'));
    _ensureOk(response);
    final jsonBody = _decodeMap(response.body);
    return (jsonBody['moods'] as List<dynamic>)
        .map((item) => item.toString())
        .toList(growable: false);
  }

  Future<GuidanceResponse> askQuestion({
    required String question,
    required String mode,
    required String language,
  }) async {
    final response = await _httpClient.post(
      _uri('/ask'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(
          {'question': question, 'mode': mode, 'language': language}),
    );
    _ensureOk(response);
    return GuidanceResponse.fromJson(_decodeMap(response.body));
  }

  Future<ChatResponse> chat({
    required String message,
    required String mode,
    required String language,
    List<ChatTurn> history = const <ChatTurn>[],
  }) async {
    final response = await _httpClient.post(
      _uri('/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(
        <String, dynamic>{
          'message': message,
          'mode': mode,
          'language': language,
          'history':
              history.map((turn) => turn.toJson()).toList(growable: false),
        },
      ),
    );
    _ensureOk(response);
    return ChatResponse.fromJson(_decodeMap(response.body));
  }

  Future<GuidanceResponse> moodGuidance({
    required List<String> moods,
    required String mode,
    required String language,
    String? note,
  }) async {
    final response = await _httpClient.post(
      _uri('/moods/guidance'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(
          {'moods': moods, 'note': note, 'mode': mode, 'language': language}),
    );
    _ensureOk(response);
    return GuidanceResponse.fromJson(_decodeMap(response.body));
  }

  Future<Verse> fetchVerseById(int verseId) async {
    final response = await _httpClient.get(_uri('/verses/$verseId'));
    _ensureOk(response);
    return Verse.fromJson(_decodeMap(response.body));
  }

  Future<List<FavoriteItem>> fetchFavorites() async {
    final response = await _httpClient.get(_uri('/favorites'));
    _ensureOk(response);
    final body = _decodeList(response.body);
    return body
        .map((item) => FavoriteItem.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<FavoriteItem> addFavorite(int verseId) async {
    final response = await _httpClient.post(
      _uri('/favorites'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'verse_id': verseId}),
    );
    _ensureOk(response);
    return FavoriteItem.fromJson(_decodeMap(response.body));
  }

  Future<void> removeFavorite(int verseId) async {
    final response = await _httpClient.delete(_uri('/favorites/$verseId'));
    _ensureOk(response);
  }

  Future<List<Journey>> fetchJourneys() async {
    final response = await _httpClient.get(_uri('/journeys'));
    _ensureOk(response);
    final body = _decodeList(response.body);
    return body
        .map((item) => Journey.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<MorningGreeting> fetchMorningGreeting({
    required String mode,
    required String language,
  }) async {
    final response = await _httpClient.post(
      _uri('/morning-greeting'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(<String, dynamic>{
        'mode': mode,
        'language': language,
      }),
    );
    _ensureOk(response);
    return MorningGreeting.fromJson(_decodeMap(response.body));
  }

  void _ensureOk(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw ApiException(
        'Request failed (${response.statusCode}): ${response.body}');
  }

  Map<String, dynamic> _decodeMap(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('Expected JSON object');
    }
    return decoded;
  }

  List<dynamic> _decodeList(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! List<dynamic>) {
      throw const ApiException('Expected JSON array');
    }
    return decoded;
  }
}
