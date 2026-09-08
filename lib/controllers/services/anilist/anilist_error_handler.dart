import 'dart:convert';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:http/http.dart' as http;

class AnilistErrorHandler {
  static DateTime? _lastToastTime;
  static String? _lastToastMessage;

  static String? extractErrorMessage(dynamic body) {
    try {
      Map<String, dynamic>? jsonMap;
      if (body is Map<String, dynamic>) {
        jsonMap = body;
      } else if (body is String) {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          jsonMap = decoded;
        }
      }

      if (jsonMap != null) {
        if (jsonMap['errors'] is List && (jsonMap['errors'] as List).isNotEmpty) {
          final firstError = jsonMap['errors'][0];
          if (firstError is Map<String, dynamic>) {
            final msg = firstError['message']?.toString();
            if (msg != null && msg.trim().isNotEmpty) {
              return msg.trim();
            }
          }
        }
        if (jsonMap['error'] != null) {
          return jsonMap['error'].toString().trim();
        }
        if (jsonMap['message'] != null) {
          return jsonMap['message'].toString().trim();
        }
      }
    } catch (_) {}
    return null;
  }

  static void handleResponse(http.Response response, {String? defaultMessage}) {
    final isRateLimit = response.statusCode == 429;
    final apiMessage = extractErrorMessage(response.body);

    if (response.statusCode == 200) {
      if (apiMessage != null) {
        _showToast(apiMessage, isRateLimit: false);
      }
      return;
    }

    if (isRateLimit) {
      final msg = apiMessage ?? 'Chill for a min, you got rate limited.';
      _showToast(msg, isRateLimit: true);
    } else if (apiMessage != null && apiMessage.isNotEmpty) {
      _showToast(apiMessage, isRateLimit: false);
    } else if (defaultMessage != null && defaultMessage.isNotEmpty) {
      _showToast(defaultMessage, isRateLimit: false);
    } else {
      _showToast(
        'AniList request failed (${response.statusCode})',
        isRateLimit: false,
      );
    }
  }

  static void handleError(dynamic error, {String? defaultMessage}) {
    if (error == null) return;
    final errorStr = error.toString().replaceFirst('Exception: ', '').trim();
    final isRateLimit = errorStr.toLowerCase().contains('rate limit') ||
        errorStr.toLowerCase().contains('too many requests') ||
        errorStr.contains('429');

    final message = errorStr.isNotEmpty ? errorStr : (defaultMessage ?? 'AniList request failed');
    _showToast(message, isRateLimit: isRateLimit);
  }

  static void _showToast(String message, {required bool isRateLimit}) {
    final now = DateTime.now();
    if (_lastToastMessage == message &&
        _lastToastTime != null &&
        now.difference(_lastToastTime!) < const Duration(milliseconds: 3500)) {
      return;
    }
    _lastToastTime = now;
    _lastToastMessage = message;

    if (isRateLimit ||
        message.toLowerCase().contains('rate limit') ||
        message.toLowerCase().contains('too many requests')) {
      warningSnackBar(message);
    } else {
      errorSnackBar(message);
    }
  }
}
