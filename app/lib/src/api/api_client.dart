import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/models.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? responseBody;

  const ApiException(
    this.message, {
    this.statusCode,
    this.responseBody,
  });

  @override
  String toString() => message;
}

class ChatStreamEvent {
  final String? token;
  final ChatResponse? response;

  const ChatStreamEvent._({
    this.token,
    this.response,
  });

  factory ChatStreamEvent.token(String token) {
    return ChatStreamEvent._(token: token);
  }

  factory ChatStreamEvent.done(ChatResponse response) {
    return ChatStreamEvent._(response: response);
  }
}

class ApiClient {
  static const Duration _requestTimeout = Duration(seconds: 20);

  final String baseUrl;
  final http.Client _httpClient;

  ApiClient({String? baseUrl, http.Client? httpClient})
      : baseUrl = _resolveBaseUrl(baseUrl),
        _httpClient = httpClient ?? http.Client() {
    if (kDebugMode) {
      debugPrint('ApiClient baseUrl: ${this.baseUrl}');
    }
  }


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
      return 'http://127.0.0.1:8000';
    }

    return 'http://localhost:8000';
  }

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Uri _uriWithQuery(String path, Map<String, String> query) {
    return _uri(path).replace(queryParameters: query);
  }

  Future<http.Response> _get(Uri uri) {
    return _httpClient.get(uri).timeout(_requestTimeout);
  }

  Future<http.Response> _post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) {
    return _httpClient
        .post(uri, headers: headers, body: body)
        .timeout(_requestTimeout);
  }

  Future<http.Response> _delete(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) {
    return _httpClient
        .delete(uri, headers: headers, body: body)
        .timeout(_requestTimeout);
  }

  Future<void> healthCheck() async {
    final response = await _get(_uri('/health'));
    _ensureOk(response);
  }

  Future<Verse> fetchDailyVerse() async {
    final response = await _get(_uri('/daily-verse'));
    _ensureOk(response);
    return Verse.fromJson(_decodeMap(response.body));
  }

  Future<List<ChapterSummary>> fetchChapters() async {
    final response = await _get(_uri('/chapters'));
    _ensureOk(response);
    final body = _decodeList(response.body);
    return body
        .map((item) => ChapterSummary.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<List<Verse>> fetchVerses({int? chapter}) async {
    final uri = chapter == null
        ? _uri('/verses')
        : _uriWithQuery('/verses', <String, String>{
            'chapter': chapter.toString(),
          });

    final response = await _get(uri);
    _ensureOk(response);
    final body = _decodeList(response.body);
    return body
        .map((item) => Verse.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<List<String>> fetchMoodOptions() async {
    final response = await _get(_uri('/moods'));
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
    final response = await _post(
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
    final response = await _post(
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

  Stream<ChatStreamEvent> streamChat({
    required String message,
    required String mode,
    required String language,
    List<ChatTurn> history = const <ChatTurn>[],
  }) async* {
    final request = http.Request('POST', _uri('/chat/stream'));
    request.headers.addAll(<String, String>{
      'Content-Type': 'application/json',
      'Accept': 'text/event-stream',
    });
    request.body = jsonEncode(
      <String, dynamic>{
        'message': message,
        'mode': mode,
        'language': language,
        'history':
            history.map((turn) => turn.toJson()).toList(growable: false),
      },
    );

    final streamedResponse =
        await _httpClient.send(request).timeout(_requestTimeout);
    if (streamedResponse.statusCode < 200 || streamedResponse.statusCode >= 300) {
      final body = await streamedResponse.stream.bytesToString();
      throw ApiException(
        'Request failed (${streamedResponse.statusCode})',
        statusCode: streamedResponse.statusCode,
        responseBody: body,
      );
    }

    String? currentEvent;
    final dataBuffer = StringBuffer();
    int? statusCodeFrom(dynamic raw) {
      if (raw is int) {
        return raw;
      }
      if (raw is num) {
        return raw.toInt();
      }
      return int.tryParse(raw?.toString() ?? '');
    }

    Map<String, dynamic>? consumePayload() {
      if (dataBuffer.isEmpty) {
        currentEvent = null;
        return null;
      }

      final rawPayload = dataBuffer.toString();
      dataBuffer.clear();
      Map<String, dynamic> payload;
      try {
        final decoded = jsonDecode(rawPayload);
        if (decoded is Map<String, dynamic>) {
          payload = decoded;
        } else {
          payload = <String, dynamic>{};
        }
      } catch (_) {
        payload = <String, dynamic>{'message': rawPayload};
      }
      return payload;
    }

    await for (final line in streamedResponse.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())) {
      if (line.isEmpty) {
        final eventName = (currentEvent ?? 'message').trim();
        final payload = consumePayload();
        currentEvent = null;
        if (payload == null) {
          continue;
        }

        if (eventName == 'token') {
          final token = payload['token']?.toString() ?? '';
          if (token.isNotEmpty) {
            yield ChatStreamEvent.token(token);
          }
          continue;
        }

        if (eventName == 'done') {
          yield ChatStreamEvent.done(ChatResponse.fromJson(payload));
          continue;
        }

        if (eventName == 'error') {
          final message = payload['message']?.toString().trim();
          throw ApiException(
            message == null || message.isEmpty ? 'Streaming failed' : message,
            statusCode: statusCodeFrom(payload['status_code']),
          );
        }
        continue;
      }

      if (line.startsWith('event:')) {
        currentEvent = line.substring('event:'.length).trim();
        continue;
      }

      if (line.startsWith('data:')) {
        if (dataBuffer.isNotEmpty) {
          dataBuffer.write('\n');
        }
        dataBuffer.write(line.substring('data:'.length).trimLeft());
      }
    }

    final trailingEventName = (currentEvent ?? 'message').trim();
    final trailingPayload = consumePayload();
    if (trailingPayload != null) {
      if (trailingEventName == 'token') {
        final token = trailingPayload['token']?.toString() ?? '';
        if (token.isNotEmpty) {
          yield ChatStreamEvent.token(token);
        }
      } else if (trailingEventName == 'done') {
        yield ChatStreamEvent.done(ChatResponse.fromJson(trailingPayload));
      } else if (trailingEventName == 'error') {
        final message = trailingPayload['message']?.toString().trim();
        throw ApiException(
          message == null || message.isEmpty ? 'Streaming failed' : message,
          statusCode: statusCodeFrom(trailingPayload['status_code']),
        );
      }
    }
  }

  Future<GuidanceResponse> moodGuidance({
    required List<String> moods,
    required String mode,
    required String language,
    String? note,
  }) async {
    final response = await _post(
      _uri('/moods/guidance'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(
          {'moods': moods, 'note': note, 'mode': mode, 'language': language}),
    );
    _ensureOk(response);
    return GuidanceResponse.fromJson(_decodeMap(response.body));
  }

  Future<Verse> fetchVerseById(int verseId) async {
    final response = await _get(_uri('/verses/$verseId'));
    _ensureOk(response);
    return Verse.fromJson(_decodeMap(response.body));
  }

  Future<List<FavoriteItem>> fetchFavorites() async {
    final response = await _get(_uri('/favorites'));
    _ensureOk(response);
    final body = _decodeList(response.body);
    return body
        .map((item) => FavoriteItem.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<FavoriteItem> addFavorite(int verseId) async {
    final response = await _post(
      _uri('/favorites'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'verse_id': verseId}),
    );
    _ensureOk(response);
    return FavoriteItem.fromJson(_decodeMap(response.body));
  }

  Future<void> removeFavorite(int verseId) async {
    final response = await _delete(_uri('/favorites/$verseId'));
    _ensureOk(response);
  }

  Future<List<Journey>> fetchJourneys() async {
    final response = await _get(_uri('/journeys'));
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
    final response = await _post(
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
      'Request failed (${response.statusCode})',
      statusCode: response.statusCode,
      responseBody: response.body,
    );
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
