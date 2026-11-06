import 'dart:async';
import 'package:anymex/utils/logger.dart';

class AnilistRateLimiter {
  static final AnilistRateLimiter instance = AnilistRateLimiter._();
  AnilistRateLimiter._();

  final List<Completer<void>> _queue = [];
  bool _isProcessing = false;
  DateTime? _rateLimitUntil;
  int _remaining = 90;
  DateTime? _rateLimitReset;
  DateTime _lastDispatched = DateTime.fromMillisecondsSinceEpoch(0);

  static const int _baseSpacingMs = 450;
  static const int _lowQuotaThreshold = 15;
  static const int _criticalQuotaThreshold = 5;

  DateTime? get rateLimitUntil => _rateLimitUntil;
  int get remaining => _remaining;
  DateTime? get rateLimitReset => _rateLimitReset;

  Future<void> acquire() {
    final completer = Completer<void>();
    _queue.add(completer);
    _processQueue();
    return completer.future;
  }

  Future<void> _processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    while (_queue.isNotEmpty) {
      final now = DateTime.now();

      if (_rateLimitUntil != null && now.isBefore(_rateLimitUntil!)) {
        final waitDuration = _rateLimitUntil!.difference(now);
        if (waitDuration.inMilliseconds > 0) {
          await Future.delayed(waitDuration);
        }
      }

      int delayMs = _baseSpacingMs;
      if (_remaining <= _criticalQuotaThreshold) {
        if (_rateLimitReset != null && DateTime.now().isBefore(_rateLimitReset!)) {
          final untilReset = _rateLimitReset!.difference(DateTime.now()).inMilliseconds;
          delayMs = untilReset.clamp(1000, 10000);
        } else {
          delayMs = 2000;
        }
      } else if (_remaining <= _lowQuotaThreshold) {
        delayMs = 900;
      }

      final elapsed = DateTime.now().difference(_lastDispatched).inMilliseconds;
      if (elapsed < delayMs) {
        await Future.delayed(Duration(milliseconds: delayMs - elapsed));
      }

      _lastDispatched = DateTime.now();
      if (_queue.isNotEmpty) {
        final completer = _queue.removeAt(0);
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    }

    _isProcessing = false;
  }

  void onResponse({
    required int statusCode,
    required Map<String, String> headers,
  }) {
    final remStr = _findHeader(headers, 'x-ratelimit-remaining');
    if (remStr != null) {
      final parsed = int.tryParse(remStr);
      if (parsed != null) {
        _remaining = parsed;
      }
    }

    final resetStr = _findHeader(headers, 'x-ratelimit-reset');
    if (resetStr != null) {
      final epochSec = int.tryParse(resetStr);
      if (epochSec != null && epochSec > 0) {
        _rateLimitReset = DateTime.fromMillisecondsSinceEpoch(epochSec * 1000);
      }
    }

    if (statusCode == 429) {
      _remaining = 0;
      final retryAfterStr = _findHeader(headers, 'retry-after');
      final retrySec = retryAfterStr != null ? (int.tryParse(retryAfterStr) ?? 60) : 60;
      _rateLimitUntil = DateTime.now().add(Duration(seconds: retrySec));
      Logger.i('AniList 429 received. Backing off for $retrySec seconds.');
    }
  }

  String? _findHeader(Map<String, String> headers, String target) {
    final lower = target.toLowerCase();
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == lower) {
        return entry.value;
      }
    }
    return null;
  }
}
