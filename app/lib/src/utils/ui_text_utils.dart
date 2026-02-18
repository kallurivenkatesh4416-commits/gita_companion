import 'package:flutter/foundation.dart';

import '../i18n/app_strings.dart';

String sanitizeAiText(String raw) {
  if (raw.trim().isEmpty) {
    return '';
  }

  final blockedPrefixes = <String>[
    'your question was',
    'prompt:',
    'input:',
    'output:',
    'json',
    'trace',
    '{',
    '}',
    '[',
    ']',
    '```',
  ];

  final cleanedLines = raw
      .replaceAll('\r\n', '\n')
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .where((line) {
        final lower = line.toLowerCase();
        return blockedPrefixes.every((prefix) => !lower.startsWith(prefix));
      })
      .toList(growable: false);

  final cleaned = cleanedLines.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  return cleaned;
}

String firstGentleLine(String raw) {
  final cleaned = sanitizeAiText(raw);
  if (cleaned.isEmpty) {
    return '';
  }
  final parts = cleaned.split(RegExp(r'(?<=[.!?])\s+'));
  return parts.first.trim();
}

String mapFriendlyError(
  Object error, {
  required AppStrings strings,
  String context = 'general',
}) {
  final text = error.toString().toLowerCase();
  debugPrint('Error[$context]: $error');

  if (context == 'mood' &&
      (text.contains('404') || text.contains('no verses found'))) {
    return strings.t('friendly_mood_no_verse');
  }
  if (text.contains('request failed') ||
      text.contains('exception') ||
      text.contains('trace') ||
      text.contains('detail')) {
    if (context == 'mood') {
      return strings.t('friendly_mood_no_verse');
    }
    if (context == 'verses') {
      return strings.t('friendly_verses_load_error');
    }
    return strings.t('friendly_general_error');
  }
  if (text.contains('something went wrong')) {
    if (context == 'mood') {
      return strings.t('friendly_mood_no_verse');
    }
    if (context == 'verses') {
      return strings.t('friendly_verses_load_error');
    }
    return strings.t('friendly_general_error');
  }
  if (text.contains('timeout') || text.contains('timed out')) {
    return strings.t('friendly_network_timeout');
  }
  if (text.contains('401') || text.contains('403') || text.contains('auth')) {
    return strings.t('friendly_auth_error');
  }
  if (text.contains('500') || text.contains('server')) {
    return strings.t('friendly_server_error');
  }
  if (text.contains('socket') ||
      text.contains('connection') ||
      text.contains('failed host lookup')) {
    return strings.t('friendly_network_error');
  }
  if (context == 'verses') {
    return strings.t('friendly_verses_load_error');
  }
  return strings.t('friendly_general_error');
}
