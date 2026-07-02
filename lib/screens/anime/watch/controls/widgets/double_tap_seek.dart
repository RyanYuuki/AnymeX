import 'dart:io';

import 'package:anymex/widgets/animation/animations.dart';
import 'package:flutter/material.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:flutter/services.dart';
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/screens/anime/watch/controller/player_utils.dart';
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

  static const Duration _seekModeTimeout = Duration(milliseconds: 1500);
  static const Duration _indicatorTimeout = Duration(milliseconds: 1000);
  static const Duration _seekDebounceTimeout = Duration(milliseconds: 500);
  static const Duration _setRateDebounceTimeout = Duration(milliseconds: 200);

  bool _isHolding = false;
  double _currentSpeed = 1.0;
  double _previousSpeed = 1.0;
  double _pendingSpeed = 1.0;
  bool _hadControlsBeforeHold = false;
  Timer? _holdStartTimer;

  double _initialSwipeY = 0.0;
  bool _isDragging = false;
  bool _longPressStarted = false;

  bool _isHorizontalDragging = false;
  bool _showSeekTime = false;
  Duration _dragCurrentPosition = Duration.zero;
  Duration _dragStartPlayerPosition = Duration.zero;
  int _dragSeekDirection = 0;
  bool _wasPlayingBeforeSeek = false;

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
    if (widget.controller.isLocked.value) return;
    HapticFeedback.lightImpact();
    _performSeek(isLeft: true);
  }

  void _handleRightSeek() {
    if (widget.controller.isLocked.value) return;
    HapticFeedback.lightImpact();
    _performSeek(isLeft: false);
  }

  void _performSeek({required bool isLeft}) {
    if (widget.controller.isLocked.value) return;

    setState(() {
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
    if (widget.controller.isLocked.value) return;
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

        _setPlaybackRate(_currentSpeed, instant: true);

        _speedAnimationController.forward();
        _glowAnimationController.repeat(reverse: true);

        HapticFeedback.mediumImpact();
      }
    });
  }

  void _endHold() {
    if (widget.controller.isLocked.value) return;
    _longPressStarted = false;
    _holdStartTimer?.cancel();

    if (_isHolding) {
      setState(() {
        _isHolding = false;
        _currentSpeed = _previousSpeed;
      });

      _setPlaybackRate(_previousSpeed, instant: true);

      if (_hadControlsBeforeHold) {
        widget.controller.toggleControls(val: true);
      }

      _speedAnimationController.reverse();
      _glowAnimationController.reset();

      HapticFeedback.lightImpact();
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && !_isHolding) {
          _setPlaybackRate(_previousSpeed, instant: true);
        }
      });
    }
  }

  void _setPlaybackRate(double rate, {bool instant = false}) {
    if (widget.controller.isLocked.value) return;
    try {
      _pendingSpeed = rate;

      _setRateDebounceTimer?.cancel();

      if (instant) {
        widget.controller.setRate(rate);

        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            double currentRate = widget.controller.playbackSpeed.value;
            if ((currentRate - rate).abs() > 0.1) {
              widget.controller.setRate(rate);
            }
          }
        });
      } else {
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
      }
    } catch (e) {
      debugPrint('Error setting playback rate: $e');
    }
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    if (widget.controller.isLocked.value) return;
    if (_isHolding || _longPressStarted) return;

    _isHorizontalDragging = true;
    _dragStartPlayerPosition = widget.controller.currentPosition.value;
    _dragCurrentPosition = _dragStartPlayerPosition;
    _dragSeekDirection = 0;
    _wasPlayingBeforeSeek = widget.controller.isPlaying.value;

    if (_wasPlayingBeforeSeek) {
      widget.controller.pause();
    }
    if (widget.controller.showControls.value) {
      widget.controller.toggleControls(val: false);
    }

    setState(() => _showSeekTime = true);
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!_isHorizontalDragging) return;
    if (widget.controller.isLocked.value) return;

    final screenWidth = MediaQuery.of(context).size.width;
    const sensitivity = 0.80;
    final totalMs = widget.controller.episodeDuration.value.inMilliseconds;
    if (totalMs <= 0) return;

    final msPerPixel = (totalMs * sensitivity) / screenWidth;
    final deltaMs = (details.delta.dx * msPerPixel).round();

    final newMs =
        (_dragCurrentPosition.inMilliseconds + deltaMs).clamp(0, totalMs);
    final newPosition = Duration(milliseconds: newMs);
    final direction = deltaMs > 0 ? 1 : (deltaMs < 0 ? -1 : _dragSeekDirection);

    setState(() {
      _dragSeekDirection = direction;
      _dragCurrentPosition = newPosition;
    });

    widget.controller.seekTo(newPosition);
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (!_isHorizontalDragging) return;

    _isHorizontalDragging = false;

    setState(() => _showSeekTime = false);

    if (_wasPlayingBeforeSeek) {
      widget.controller.play();
    }
  }

  void _updateSpeedFromSwipe(double deltaY) {
    if (widget.controller.isLocked.value) return;
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
                        color: colorScheme.surface.opaque(0.15),
                        border: Border.all(
                          color: colorScheme.primary
                              .opaque(_glowAnimation.value * 0.5),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary
                                .opaque(_glowAnimation.value * 0.2),
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
                            color: colorScheme.primary.opaque(0.9),
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
                                colorScheme.primary.opaque(0.18),
                                colorScheme.tertiary.opaque(0.18),
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

  Widget _buildDragSeekHud() {
    if (!_showSeekTime) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final totalMs = widget.controller.episodeDuration.value.inMilliseconds;
    final progress = totalMs > 0
        ? (_dragCurrentPosition.inMilliseconds / totalMs).clamp(0.0, 1.0)
        : 0.0;
    final isForward = _dragSeekDirection >= 0;
    final icon =
        isForward ? Icons.fast_forward_rounded : Icons.fast_rewind_rounded;
    final accent = colorScheme.secondaryContainer;
    final container = colorScheme.secondary;
    final onContainer = colorScheme.onSecondary;
    final surface = colorScheme.surfaceContainerHighest;
    final border = colorScheme.outlineVariant.withValues(alpha: 0.34);

    return Align(
      alignment: Alignment.topCenter,
      child: AnimatedOpacity(
        opacity: _showSeekTime ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: AnimatedSlide(
          offset: _showSeekTime ? Offset.zero : const Offset(0, -0.18),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: Padding(
            padding: const EdgeInsets.only(top: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Container(
                width: 248,
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: border),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.24),
                      blurRadius: 32,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.28),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: progress,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              color: colorScheme.secondaryContainer,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 10,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: container,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              switchInCurve: Curves.easeOutBack,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (child, animation) =>
                                  ScaleTransition(
                                scale: animation,
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              ),
                              child: Icon(
                                icon,
                                key: ValueKey(icon),
                                color: onContainer,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  PlayerUtils.formatDuration(
                                      _dragCurrentPosition),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  '/ ${PlayerUtils.formatDuration(widget.controller.episodeDuration.value)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
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

    final totalSeekSeconds =
        widget.controller.playerSettings.seekDuration * tapCount;

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
                colorScheme.surface.opaque(0.15),
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
                    color: colorScheme.shadow.opaque(0.15),
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
                          color: colorScheme.primary.opaque(0.15),
                        ),
                      ),
                      Icon(
                        isLeft
                            ? Icons.fast_rewind_rounded
                            : Icons.fast_forward_rounded,
                        size: 32,
                        color: colorScheme.primary.opaque(1),
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
                      color: colorScheme.surfaceContainerHighest.opaque(0.9),
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

  void _handleSingleTap() {
    if (widget.controller.isLocked.value) {
      widget.controller.toggleControls();
      return;
    }
    widget.controller.toggleControls();
  }

  void _handleKeyboard(KeyEvent event) {
    if (widget.controller.isLocked.value) return;
    if (event is KeyDownEvent) {
      final isControlPressed = HardwareKeyboard.instance.isControlPressed;
      if (isControlPressed) {
        if (event.logicalKey == LogicalKeyboardKey.digit1) {
          widget.controller.applyShaderByIndex(0);
        } else if (event.logicalKey == LogicalKeyboardKey.digit2) {
          widget.controller.applyShaderByIndex(1);
        } else if (event.logicalKey == LogicalKeyboardKey.digit3) {
          widget.controller.applyShaderByIndex(2);
        } else if (event.logicalKey == LogicalKeyboardKey.digit4) {
          widget.controller.applyShaderByIndex(3);
        } else if (event.logicalKey == LogicalKeyboardKey.digit5) {
          widget.controller.applyShaderByIndex(4);
        } else if (event.logicalKey == LogicalKeyboardKey.digit6) {
          widget.controller.applyShaderByIndex(5);
        } else if (event.logicalKey == LogicalKeyboardKey.digit0) {
          widget.controller.clearShaders();
        }
      } else {
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          _handleLeftSeek();
        } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          _handleRightSeek();
        } else if (event.logicalKey == LogicalKeyboardKey.space) {
          widget.controller.togglePlayPause();
        }
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
              onHorizontalDragStart: _onHorizontalDragStart,
              onHorizontalDragUpdate: _onHorizontalDragUpdate,
              onHorizontalDragEnd: _onHorizontalDragEnd,
              onLongPressStart: (details) {
                _initialSwipeY = details.globalPosition.dy;
                _startHold();
              },
              onLongPressEnd: (details) => _endHold(),
              onLongPressCancel: () => _endHold(),
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
                    Row(
                      children: [
                        Expanded(
                          flex: 35,
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: _handleSingleTap,
                            onDoubleTapDown: (details) => _handleLeftSeek(),
                            child: Container(color: Colors.transparent),
                          ),
                        ),
                        Expanded(
                          flex: 30,
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: _handleSingleTap,
                            child: Container(color: Colors.transparent),
                          ),
                        ),
                        Expanded(
                          flex: 35,
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: _handleSingleTap,
                            onDoubleTapDown: (details) => _handleRightSeek(),
                            child: Container(color: Colors.transparent),
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: IgnorePointer(
                        child: _buildSeekIndicator(
                          isLeft: true,
                          tapCount: _leftTapCount,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: IgnorePointer(
                        child: _buildSeekIndicator(
                          isLeft: false,
                          tapCount: _rightTapCount,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: MediaQuery.of(context).size.height * 0.05,
                      child: IgnorePointer(child: _buildSpeedIndicator()),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      child: IgnorePointer(child: _buildDragSeekHud()),
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
