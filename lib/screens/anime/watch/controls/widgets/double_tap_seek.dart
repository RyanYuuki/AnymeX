import 'dart:io';

import 'package:anymex/widgets/animation/animations.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'dart:async';

import 'package:get/get.dart';

class DoubleTapSeekWidget extends StatefulWidget {
  final PlayerController controller;

  const DoubleTapSeekWidget({
    super.key,
    required this.controller,
  });

  @override
  State<DoubleTapSeekWidget> createState() => _DoubleTapSeekWidgetState();
}

class _DoubleTapSeekWidgetState extends State<DoubleTapSeekWidget>
    with TickerProviderStateMixin {
  int _leftTapCount = 0;
  int _rightTapCount = 0;
  Timer? _leftHideTimer;
  Timer? _rightHideTimer;
  Timer? _seekModeTimer;
  Timer? _seekDebounceTimer;
  Timer? _setRateDebounceTimer;

  bool _isInSeekMode = false;
  static const Duration _seekModeTimeout = Duration(milliseconds: 1500);
  static const Duration _indicatorTimeout = Duration(milliseconds: 1000);
  static const Duration _seekDebounceTimeout = Duration(milliseconds: 500);
  static const Duration _setRateDebounceTimeout = Duration(seconds: 1);

  bool _isHolding = false;
  double _currentSpeed = 1.0;
  double _previousSpeed = 1.0;
  double _pendingSpeed = 1.0;
  bool _hadControlsBeforeHold = false;
  Timer? _holdStartTimer;

  double _initialSwipeY = 0.0;
  bool _isDragging = false;
  bool _longPressStarted = false;
  late AnimationController _speedAnimationController;
  late Animation<double> _speedScaleAnimation;
  late AnimationController _glowAnimationController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _speedAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _speedScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _speedAnimationController,
      curve: Curves.elasticOut,
    ));

    _glowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _leftHideTimer?.cancel();
    _rightHideTimer?.cancel();
    _seekModeTimer?.cancel();
    _seekDebounceTimer?.cancel();
    _holdStartTimer?.cancel();
    _setRateDebounceTimer?.cancel();
    _speedAnimationController.dispose();
    _glowAnimationController.dispose();
    super.dispose();
  }

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

    _seekDebounceTimer?.cancel();

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
    if (tapCount == 0) return;

    final seekAmount = Duration(
        seconds: widget.controller.playerSettings.seekDuration * tapCount);
    final currentPos = widget.controller.currentPosition.value;
    final newPosition =
        isLeft ? currentPos - seekAmount : currentPos + seekAmount;
    final clampedPosition = Duration(
      milliseconds: newPosition.inMilliseconds
          .clamp(0, widget.controller.episodeDuration.value.inMilliseconds),
    );

    widget.controller.seekTo(clampedPosition);
  }

  void _startHold() {
    if (!widget.controller.isPlaying.value || _isDragging) return;

    _longPressStarted = true;

    _previousSpeed = widget.controller.playbackSpeed.value;
    _hadControlsBeforeHold = widget.controller.showControls.value;

    _holdStartTimer = Timer(const Duration(milliseconds: 150), () {
      if (mounted && !_isDragging && _longPressStarted) {
        setState(() {
          _isHolding = true;
          _currentSpeed = 2.0;
        });

        widget.controller.toggleControls(val: false);

        _setPlaybackRate(_currentSpeed);

        _speedAnimationController.forward();
        _glowAnimationController.repeat(reverse: true);

        HapticFeedback.mediumImpact();
      }
    });
  }

  void _endHold() {
    _longPressStarted = false;
    _holdStartTimer?.cancel();

    if (_isHolding) {
      setState(() {
        _isHolding = false;
        _currentSpeed = _previousSpeed;
      });

      _setPlaybackRate(_previousSpeed);

      if (_hadControlsBeforeHold) {
        widget.controller.toggleControls(val: true);
      }

      _speedAnimationController.reverse();
      _glowAnimationController.reset();

      HapticFeedback.lightImpact();
      Future.delayed(const Duration(milliseconds: 1000), () {
        _setPlaybackRate(_previousSpeed);
      });
    }
  }

  void _setPlaybackRate(double rate) {
    try {
      _pendingSpeed = rate;

      _setRateDebounceTimer?.cancel();

      _setRateDebounceTimer = Timer(_setRateDebounceTimeout, () {
        if (mounted) {
          widget.controller.setRate(_pendingSpeed);

          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) {
              double currentRate = widget.controller.playbackSpeed.value;
              if ((currentRate - _pendingSpeed).abs() > 0.1) {
                widget.controller.setRate(_pendingSpeed);
              }
            }
          });
        }
      });
    } catch (e) {
      debugPrint('Error setting playback rate: $e');
    }
  }

  void _updateSpeedFromSwipe(double deltaY) {
    if (!_isHolding) return;

    const double maxSwipeDistance = 100.0;
    const double minSpeed = 2.0;
    const double maxSpeed = 5.0;

    double normalizedDelta = (-deltaY / maxSwipeDistance).clamp(0.0, 1.0);
    double newSpeed = minSpeed + (normalizedDelta * (maxSpeed - minSpeed));

    newSpeed = (newSpeed * 2).round() / 2;
    newSpeed = newSpeed.clamp(minSpeed, maxSpeed);

    if (newSpeed != _currentSpeed) {
      setState(() {
        _currentSpeed = newSpeed;
      });

      _setPlaybackRate(_currentSpeed);
      HapticFeedback.selectionClick();
    }
  }

  Widget _buildSpeedIndicator() {
    if (!_isHolding) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Align(
      alignment: Alignment.topCenter,
      child: AnimatedBuilder(
        animation: Listenable.merge([_speedScaleAnimation, _glowAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _speedScaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withOpacity(0.15),
                        border: Border.all(
                          color: colorScheme.primary
                              .withOpacity(_glowAnimation.value * 0.5),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary
                                .withOpacity(_glowAnimation.value * 0.2),
                            blurRadius: 12,
                            spreadRadius: 2,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.fast_forward_rounded,
                            size: 18,
                            color: colorScheme.primary.withOpacity(0.9),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 42,
                            child: Text(
                              '${_currentSpeed.toStringAsFixed(_currentSpeed == _currentSpeed.toInt() ? 0 : 1)}x',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                                height: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned.fill(
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor:
                            ((_currentSpeed - 2.0) / 3.0).clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.primary.withOpacity(0.18),
                                colorScheme.tertiary.withOpacity(0.18),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
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
    final tapPosition = details.globalPosition;
    final isLeft = tapPosition.dx < screenWidth / 2;

    if (isLeft) {
      _handleLeftSeek();
    } else {
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
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Obx(() {
        return MouseRegion(
          cursor: widget.controller.showControls.value
              ? SystemMouseCursors.basic
              : SystemMouseCursors.none,
          onHover: (e) => {
            if (!Platform.isAndroid && !Platform.isIOS)
              {widget.controller.toggleControls(val: true)}
          },
          child: KeyboardListener(
            focusNode: FocusNode()..requestFocus(),
            onKeyEvent: _handleKeyboard,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragStart: (details) {
                if (!_longPressStarted && !_isHolding) {
                  _isDragging = true;
                  widget.controller.onVerticalDragStart(context, details);
                } else if (_isHolding) {
                  _initialSwipeY = details.globalPosition.dy;
                }
              },
              onVerticalDragEnd: (details) {
                if (!_isHolding) {
                  _isDragging = false;
                  widget.controller.onVerticalDragEnd(context, details);
                }
              },
              onVerticalDragUpdate: (details) {
                if (_isHolding) {
                  double deltaY = details.globalPosition.dy - _initialSwipeY;
                  _updateSpeedFromSwipe(deltaY);
                } else if (_isDragging) {
                  widget.controller.onVerticalDragUpdate(context, details);
                }
              },
              onTapDown: _handleSingleTap,
              onDoubleTapDown: _handleDoubleTap,
              onLongPressStart: (details) {
                _initialSwipeY = details.globalPosition.dy;
                _startHold();
              },
              onLongPressEnd: (details) => _endHold(),
              onLongPressMoveUpdate: (details) {
                if (_isHolding) {
                  double deltaY = details.globalPosition.dy - _initialSwipeY;
                  _updateSpeedFromSwipe(deltaY);
                }
              },
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
                    Positioned(
                      left: 0,
                      right: 0,
                      top: MediaQuery.of(context).size.height * 0.05,
                      child: _buildSpeedIndicator(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
