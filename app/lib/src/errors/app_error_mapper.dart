import 'dart:async';

import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../i18n/app_strings.dart';

class AppErrorMapper {
  const AppErrorMapper._();

  static bool isConnectivityIssue(Object error) {
    final errorText = error.toString().toLowerCase();
    return error is TimeoutException ||
        errorText.contains('timed out') ||
        errorText.contains('socketexception') ||
        errorText.contains('failed host lookup') ||
        errorText.contains('network is unreachable') ||
        errorText.contains('connection refused');
  }

  static String toUserMessage(
    Object error,
    AppStrings strings, {
    StackTrace? stackTrace,
    String? context,
  }) {
    _log(error, stackTrace: stackTrace, context: context);

    final statusCode = _statusCode(error);
    final errorText = error.toString().toLowerCase();

    if (error is TimeoutException || errorText.contains('timed out')) {
      return strings.t('error_network_timeout');
    }

    if (errorText.contains('socketexception') ||
        errorText.contains('failed host lookup') ||
        errorText.contains('network is unreachable') ||
        errorText.contains('connection refused')) {
      return strings.t('error_network_unavailable');
    }

    if (statusCode == 401 ||
        statusCode == 403 ||
        errorText.contains('unauthorized') ||
        errorText.contains('forbidden')) {
      return strings.t('error_auth');
    }

    if (statusCode != null && statusCode >= 500) {
      return strings.t('error_server');
    }

    if (statusCode != null && statusCode >= 400) {
      return strings.t('error_request');
    }

    return strings.t('error_generic');
  }

  static int? _statusCode(Object error) {
    if (error is ApiException) {
      return error.statusCode;
    }

    final message = error.toString();
    final match = RegExp(r'request failed \((\d{3})\)', caseSensitive: false)
        .firstMatch(message);
    if (match == null) {
      return null;
    }

    return int.tryParse(match.group(1) ?? '');
  }

  static void _log(
    Object error, {
    StackTrace? stackTrace,
    String? context,
  }) {
    final prefix = context == null ? '[AppError]' : '[AppError][$context]';
    debugPrint('$prefix $error');

    if (error is ApiException && error.responseBody != null) {
      debugPrint('$prefix response: ${error.responseBody}');
    }

    if (stackTrace != null) {
      debugPrintStack(label: prefix, stackTrace: stackTrace);
    }
  }
}
