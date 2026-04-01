import 'dart:async';
import 'dart:convert';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TouchGrassService extends GetxService with WidgetsBindingObserver {
  final enabled = false.obs;
  final reminderMinutes = 180.obs;
  final dailyUsage = <String, int>{}.obs;

  Timer? _timer;
  DateTime? _sessionStart;
  int _accumulatedSeconds = 0;
  bool _dialogShown = false;
  bool _observerAdded = false;

  static const int _defaultMinutes = 180;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
    if (enabled.value) {
      _addObserver();
      _startSession();
    }
  }

  @override
  void onClose() {
    _endSession();
    _removeObserver();
    _timer?.cancel();
    super.onClose();
  }

  void _addObserver() {
    if (!_observerAdded) {
      WidgetsBinding.instance.addObserver(this);
      _observerAdded = true;
    }
  }

  void _removeObserver() {
    if (_observerAdded) {
      WidgetsBinding.instance.removeObserver(this);
      _observerAdded = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _endSession();
      _timer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      if (enabled.value) {
        _startSession();
      }
    }
  }

  void _loadSettings() {
    enabled.value = TouchGrassKeys.enabled.get<bool>(false);
    reminderMinutes.value =
        TouchGrassKeys.reminderMinutes.get<int>(_defaultMinutes);

    final raw = TouchGrassKeys.weeklyUsage.get<String?>(null);
    if (raw != null) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      dailyUsage.value = decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
    }
    _pruneOldDays();
  }

  void _pruneOldDays() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    dailyUsage.removeWhere((key, _) {
      final date = DateTime.parse(key);
      return today.difference(date).inDays > 1825;
    });
  }

  String _dateKey(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day).toIso8601String();

  int get currentSessionMinutes {
    if (_sessionStart == null) return 0;
    return (DateTime.now().difference(_sessionStart!).inSeconds / 60).round();
  }

  int get todaySavedMinutes => dailyUsage[_dateKey(DateTime.now())] ?? 0;

  void _startSession() {
    _sessionStart = DateTime.now();
    _accumulatedSeconds = 0;
    _dialogShown = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!enabled.value || _sessionStart == null) return;

      final elapsed = DateTime.now().difference(_sessionStart!).inSeconds;

      final totalMinutes = (elapsed / 60).round();
      final currentLogged = (_accumulatedSeconds / 60).round();
      final toAdd = totalMinutes - currentLogged;
      if (toAdd > 0) {
        final key = _dateKey(DateTime.now());
        dailyUsage[key] = (dailyUsage[key] ?? 0) + toAdd;
        _accumulatedSeconds = totalMinutes * 60;
        dailyUsage.refresh();
        _persistUsage();
      }

      final threshold = reminderMinutes.value * 60;
      if (elapsed >= threshold && !_dialogShown) {
        _dialogShown = true;
        _endSession();
        _timer?.cancel();
        _showReminder();
      }
    });
  }

  void _endSession() {
    if (_sessionStart == null) return;
    final elapsed = DateTime.now().difference(_sessionStart!).inSeconds;
    final totalMinutes = (elapsed / 60).round();
    final currentLogged = (_accumulatedSeconds / 60).round();
    final toAdd = totalMinutes - currentLogged;
    if (toAdd > 0) {
      final key = _dateKey(DateTime.now());
      dailyUsage[key] = (dailyUsage[key] ?? 0) + toAdd;
      dailyUsage.refresh();
    }
    _accumulatedSeconds = 0;
    _sessionStart = null;
    _persistUsage();
  }

  void _persistUsage() {
    _pruneOldDays();
    TouchGrassKeys.weeklyUsage
        .set(jsonEncode(dailyUsage.map((k, v) => MapEntry(k, v))));
  }

  String _formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  void _showReminder() {
    final context = Get.overlayContext;
    if (context == null) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _buildReminderDialog(ctx),
    );
  }

  void showTestReminder() {
    final context = Get.overlayContext;
    if (context == null) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _buildReminderDialog(ctx),
    );
  }

  Widget _buildReminderDialog(BuildContext ctx) {
    final colors = ctx.colors;
    final duration = _formatDuration(reminderMinutes.value);

    return Dialog(
      backgroundColor: colors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: colors.outline.opaque(0.1)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colors.primary,
                    colors.primary.withValues(alpha: 0.7),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(
                Icons.grass_rounded,
                size: 40,
                color: colors.onPrimary,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Time to Touch Grass!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: colors.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You\'ve been binging for $duration.\nTake a break, stretch, and drink some water!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: colors.onSurfaceVariant.withValues(alpha: 0.8),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _restart();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: colors.outline.opaque(0.2)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Later',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _restart();
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: colors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'I\'m Good!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _restart() {
    if (enabled.value) _startSession();
  }

  void setEnabled(bool value) {
    enabled.value = value;
    TouchGrassKeys.enabled.set(value);
    if (value) {
      _addObserver();
      _startSession();
    } else {
      _endSession();
      _timer?.cancel();
      _removeObserver();
    }
  }

  void setReminderMinutes(int minutes) {
    reminderMinutes.value = minutes;
    TouchGrassKeys.reminderMinutes.set(minutes);
    if (enabled.value) {
      _endSession();
      _startSession();
    }
  }
}
