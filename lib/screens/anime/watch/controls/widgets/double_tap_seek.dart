import 'package:anymex/widgets/animation/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'dart:async';

class DoubleTapSeekWidget extends StatefulWidget {
  final PlayerController controller;

  const DoubleTapSeekWidget({
    super.key,
    required this.controller,
  });

  @override
  State<DoubleTapSeekWidget> createState() => _DoubleTapSeekWidgetState();
}

class _DoubleTapSeekWidgetState extends State<DoubleTapSeekWidget> {
  int _leftTapCount = 0;
  int _rightTapCount = 0;
  Timer? _leftHideTimer;
  Timer? _rightHideTimer;
  Timer? _seekModeTimer;
  Timer? _seekDebounceTimer; // New timer for debounced seeking

  bool _isInSeekMode = false;
  static const Duration _seekModeTimeout = Duration(milliseconds: 1500);
  static const Duration _indicatorTimeout = Duration(milliseconds: 1000);
  static const Duration _seekDebounceTimeout =
      Duration(milliseconds: 500); // Debounce delay

  void _handleLeftSeek() {
    HapticFeedback.lightImpact();
    _performSeek(isLeft: true);
  }

  void _handleRightSeek() {
    HapticFeedback.lightImpact();
    _performSeek(isLeft: false);
  }

  void _performSeek({required bool isLeft}) {
    setState(() {
      _isInSeekMode = true;
      if (isLeft) {
        _leftTapCount += 1;
        _rightTapCount = 0;
      } else {
        _rightTapCount += 1;
        _leftTapCount = 0;
      }
    });

    // Cancel existing seek timer to debounce
    _seekDebounceTimer?.cancel();

    // Start new debounce timer - only seek when this completes
    _seekDebounceTimer = Timer(_seekDebounceTimeout, () {
      _executeSeek(isLeft: isLeft);
    });

    _seekModeTimer?.cancel();
    if (isLeft) {
      _leftHideTimer?.cancel();
    } else {
      _rightHideTimer?.cancel();
    }

    if (isLeft) {
      _leftHideTimer = Timer(_indicatorTimeout, () {
        if (mounted) {
          setState(() {
            _leftTapCount = 0;
          });
        }
      });
    } else {
      _rightHideTimer = Timer(_indicatorTimeout, () {
        if (mounted) {
          setState(() {
            _rightTapCount = 0;
          });
        }
      });
    }

    _seekModeTimer = Timer(_seekModeTimeout, () {
      if (mounted) {
        setState(() {
          _isInSeekMode = false;
          _leftTapCount = 0;
          _rightTapCount = 0;
        });
      }
    });
  }

  void _executeSeek({required bool isLeft}) {
    if (!mounted) return;

    final tapCount = isLeft ? _leftTapCount : _rightTapCount;
    if (tapCount == 0) return; // No taps to process

    final seekAmount =
        Duration(seconds: widget.controller.seekDuration.value * tapCount);
    final currentPos = widget.controller.currentPosition.value;
    final newPosition =
        isLeft ? currentPos - seekAmount : currentPos + seekAmount;
    final clampedPosition = Duration(
      milliseconds: newPosition.inMilliseconds
          .clamp(0, widget.controller.episodeDuration.value.inMilliseconds),
    );

    widget.controller.seekTo(clampedPosition);
  }

  Widget _buildSeekIndicator({
    required bool isLeft,
    required int tapCount,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (tapCount == 0) return const SizedBox.shrink();

    final totalSeekSeconds = 10 * tapCount;

    return AnimatedItemWrapper(
        slideDistance: 5,
        key: Key(tapCount.toString()),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.25,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: isLeft ? Alignment.centerLeft : Alignment.centerRight,
              end: isLeft ? Alignment.center : Alignment.centerLeft,
              colors: [
                colorScheme.surface.withOpacity(0.15),
                Colors.transparent,
              ],
              stops: const [0.0, 0.7],
            ),
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.primary.withOpacity(0.15),
                        ),
                      ),
                      Icon(
                        isLeft
                            ? Icons.fast_rewind_rounded
                            : Icons.fast_forward_rounded,
                        size: 32,
                        color: colorScheme.primary.withOpacity(1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          colorScheme.surfaceContainerHighest.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isLeft ? Icons.remove : Icons.add,
                          size: 16,
                          color: colorScheme.onSurface,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${totalSeekSeconds}s',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
  }

  void _handleDoubleTap(TapDownDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tapX = details.localPosition.dx;

    if (tapX < screenWidth * 0.3) {
      _handleLeftSeek();
    } else if (tapX > screenWidth * 0.7) {
      _handleRightSeek();
    }
  }

  void _handleSingleTap(TapDownDetails details) {
    if (_isInSeekMode) {
      final screenWidth = MediaQuery.of(context).size.width;
      final tapX = details.localPosition.dx;

      if (tapX < screenWidth * 0.3) {
        _handleLeftSeek();
      } else if (tapX > screenWidth * 0.7) {
        _handleRightSeek();
      } else {
        widget.controller.toggleControls();
      }
    } else {
      widget.controller.toggleControls();
    }
  }

  void _handleKeyboard(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _handleLeftSeek();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _handleRightSeek();
      } else if (event.logicalKey == LogicalKeyboardKey.space) {
        widget.controller.togglePlayPause();
      }
    }
  }

  @override
  void dispose() {
    _leftHideTimer?.cancel();
    _rightHideTimer?.cancel();
    _seekModeTimer?.cancel();
    _seekDebounceTimer?.cancel(); // Cancel debounce timer
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        onKeyEvent: _handleKeyboard,
        child: GestureDetector(
          onTapDown: _handleSingleTap,
          onDoubleTapDown: _handleDoubleTap,
          child: Container(
            color: Colors.transparent,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: _buildSeekIndicator(
                    isLeft: true,
                    tapCount: _leftTapCount,
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: _buildSeekIndicator(
                    isLeft: false,
                    tapCount: _rightTapCount,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
