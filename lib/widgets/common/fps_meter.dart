import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:anymex/database/kv_helper.dart';

class FpsMeter extends StatefulWidget {
  const FpsMeter({super.key});

  static final ValueNotifier<bool> isVisible = ValueNotifier<bool>(
    KvHelper.get<bool>('show_fps_meter', defaultVal: false),
  );

  @override
  State<FpsMeter> createState() => _FpsMeterState();
}

class _FpsMeterState extends State<FpsMeter> {
  double _fps = 0.0;
  final List<int> _timestamps = [];
  int _lastUiUpdate = 0;
  bool _callbackScheduled = false;

  double _top = 60.0;
  double _right = 16.0;

  @override
  void initState() {
    super.initState();
    FpsMeter.isVisible.addListener(_handleVisibilityChange);
    if (FpsMeter.isVisible.value) {
      _startMonitoring();
    }
  }

  @override
  void dispose() {
    FpsMeter.isVisible.removeListener(_handleVisibilityChange);
    super.dispose();
  }

  void _handleVisibilityChange() {
    if (FpsMeter.isVisible.value) {
      _startMonitoring();
    } else {
      _timestamps.clear();
      _callbackScheduled = false;
    }
    if (mounted) setState(() {});
  }

  void _startMonitoring() {
    if (_callbackScheduled) return;
    _callbackScheduled = true;
    _timestamps.clear();
    SchedulerBinding.instance.addPostFrameCallback(_onFrame);
  }

  void _onFrame(Duration timestamp) {
    if (!mounted || !FpsMeter.isVisible.value) {
      _callbackScheduled = false;
      return;
    }

    final now = DateTime.now().microsecondsSinceEpoch;
    if (_timestamps.isNotEmpty && now - _timestamps.last > 500000) {
      _timestamps.clear();
    }

    _timestamps.add(now);
    while (_timestamps.isNotEmpty && now - _timestamps.first > 1000000) {
      _timestamps.removeAt(0);
    }

    if (_timestamps.length > 1) {
      final duration = now - _timestamps.first;
      if (duration > 0) {
        _fps = ((_timestamps.length - 1) * 1000000) / duration;
      }
    }

    if (now - _lastUiUpdate >= 300000) {
      _lastUiUpdate = now;
      setState(() {});
    }

    SchedulerBinding.instance.addPostFrameCallback(_onFrame);
  }

  ({Color bg, Color text, Color border}) _getStatusColors(
    double fps,
    ThemeData theme,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    if (fps <= 0.0 && _timestamps.isEmpty) {
      return (
        bg: theme.colorScheme.surfaceContainer,
        text: theme.colorScheme.onSurfaceVariant,
        border: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
      );
    }
    if (fps >= 55) {
      return isDark
          ? (
              bg: const Color(0xFF133824),
              text: const Color(0xFF7BEAA2),
              border: const Color(0xFF215E3C).withValues(alpha: 0.7),
            )
          : (
              bg: const Color(0xFFD7F8E3),
              text: const Color(0xFF0F5B32),
              border: const Color(0xFFA3E7BA),
            );
    } else if (fps >= 40) {
      return isDark
          ? (
              bg: const Color(0xFF3E2D11),
              text: const Color(0xFFFFC664),
              border: const Color(0xFF6E4F18).withValues(alpha: 0.7),
            )
          : (
              bg: const Color(0xFFFFF0D4),
              text: const Color(0xFF7A4D00),
              border: const Color(0xFFFFD68A),
            );
    } else {
      return isDark
          ? (
              bg: const Color(0xFF3E1919),
              text: const Color(0xFFFF8585),
              border: const Color(0xFF6F2626).withValues(alpha: 0.7),
            )
          : (
              bg: const Color(0xFFFFDCDD),
              text: const Color(0xFF8C1D18),
              border: const Color(0xFFFFB3B5),
            );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: FpsMeter.isVisible,
      builder: (context, visible, _) {
        if (!visible) return const SizedBox.shrink();

        final mediaQuery = MediaQuery.of(context);
        final screenWidth = mediaQuery.size.width;
        final screenHeight = mediaQuery.size.height;
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final statusColors = _getStatusColors(_fps, theme);

        return Positioned(
          top: _top,
          right: _right,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _top = (_top + details.delta.dy).clamp(30.0, screenHeight - 60.0);
                _right = (_right - details.delta.dx).clamp(10.0, screenWidth - 100.0);
              });
            },
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                padding: const EdgeInsets.only(
                  left: 11,
                  top: 3.5,
                  bottom: 3.5,
                  right: 3.5,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: isDark ? 0.88 : 0.94),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant
                        .withValues(alpha: isDark ? 0.35 : 0.5),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'FPS',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColors.bg,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: statusColors.border,
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        _fps.toStringAsFixed(0),
                        style: TextStyle(
                          color: statusColors.text,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'monospace',
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
