import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:anymex/controllers/security/app_lock_controller.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_animated_logo.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_container.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class AppLockGate extends StatelessWidget {
  final Widget child;

  const AppLockGate({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GetX<AppLockController>(
      init: Get.isRegistered<AppLockController>()
          ? Get.find<AppLockController>()
          : Get.put(AppLockController()),
      builder: (controller) {
        return Stack(
          fit: StackFit.expand,
          children: [
            child,
            if (controller.showPrivacyShield.value && !controller.isLocked.value)
              const _PrivacyShieldView(),
            if (controller.isLocked.value)
              const _AppLockOverlayView(),
          ],
        );
      },
    );
  }
}

class _PrivacyShieldView extends StatelessWidget {
  const _PrivacyShieldView();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              color: colors.surface.withOpacity(0.85),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.primary.withOpacity(0.12),
                    border: Border.all(
                      color: colors.primary.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.shield_rounded,
                    size: 38,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                AnymeXText(
                  'AnymeX Privacy Shield',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppLockOverlayView extends StatefulWidget {
  const _AppLockOverlayView();

  @override
  State<_AppLockOverlayView> createState() => _AppLockOverlayViewState();
}

class _AppLockOverlayViewState extends State<_AppLockOverlayView>
    with SingleTickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode();
  String _enteredPin = '';
  bool _isError = false;
  String? _errorMessage;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  Timer? _longPressTimer;
  double _longPressProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
        final controller = Get.find<AppLockController>();
        if (controller.biometricsEnabled.value &&
            controller.isBiometricsSupported.value &&
            controller.cooldownSecondsRemaining.value == 0) {
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted && controller.isLocked.value) {
              controller.unlockWithBiometrics();
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _focusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  int get _requiredPinLength {
    final controller = Get.find<AppLockController>();
    return controller.lockType.value == AppLockType.pin6 ? 6 : 4;
  }

  void _onDigitPressed(String digit) {
    final controller = Get.find<AppLockController>();
    if (controller.cooldownSecondsRemaining.value > 0) return;
    if (_enteredPin.length >= _requiredPinLength) return;

    controller.vibrateLight();
    setState(() {
      _enteredPin += digit;
      _isError = false;
      _errorMessage = null;
    });

    if (_enteredPin.length == _requiredPinLength) {
      _verifyPin();
    }
  }

  void _onBackspacePressed() {
    final controller = Get.find<AppLockController>();
    if (controller.cooldownSecondsRemaining.value > 0) return;
    if (_enteredPin.isEmpty) return;

    controller.vibrateLight();
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _isError = false;
      _errorMessage = null;
    });
  }

  void _verifyPin() {
    final controller = Get.find<AppLockController>();
    final success = controller.unlockWithPin(_enteredPin);

    if (!success) {
      setState(() {
        _isError = true;
        _errorMessage = controller.cooldownSecondsRemaining.value > 0
            ? 'Too many attempts. Try again later.'
            : 'Incorrect PIN';
      });
      _shakeController.forward(from: 0.0);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _enteredPin = '';
          });
        }
      });
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    final controller = Get.find<AppLockController>();
    if (controller.cooldownSecondsRemaining.value > 0) {
      return KeyEventResult.ignored;
    }
    if (event is KeyDownEvent) {
      final key = event.logicalKey;
      if (key == LogicalKeyboardKey.backspace) {
        _onBackspacePressed();
        return KeyEventResult.handled;
      }
      final char = event.character;
      if (char != null && RegExp(r'^[0-9]$').hasMatch(char)) {
        _onDigitPressed(char);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  void _startLongPressTimer() {
    final controller = Get.find<AppLockController>();
    _longPressTimer?.cancel();
    _longPressProgress = 0.0;
    const totalTicks = 50; // 50 * 100ms = 5000ms = 5s
    int tick = 0;

    _longPressTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      tick++;
      if (mounted) {
        setState(() {
          _longPressProgress = tick / totalTicks;
        });
      }
      if (tick % 10 == 0) {
        controller.vibrateLight();
      }
      if (tick >= totalTicks) {
        t.cancel();
        _cancelLongPressTimer();
        controller.vibrateMedium();
        _showSecretResetDialog(context, controller);
      }
    });
  }

  void _cancelLongPressTimer() {
    _longPressTimer?.cancel();
    if (_longPressProgress != 0.0 && mounted) {
      setState(() {
        _longPressProgress = 0.0;
      });
    }
  }

  void _showSecretResetDialog(BuildContext context, AppLockController controller) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AnymeXDialog(
        title: 'Emergency Reset',
        confirmText: 'Reset App Lock',
        contentWidget: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnymeXText(
              'Emergency bypass activated.\n\n'
              'Resetting App Lock will remove your passcode protection.\n'
              'Your downloaded files, library, and settings will remain completely safe.\n\n'
              'Do you want to reset App Lock now?',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ],
        ),
        onConfirm: () {
          controller.emergencyReset();
          snackBar('App Lock has been reset.');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final controller = Get.find<AppLockController>();

    return Obx(() {
      final isCooldown = controller.cooldownSecondsRemaining.value > 0;
      final lockType = controller.lockType.value;
      final isPattern = lockType == AppLockType.pattern;

      final defaultSubtitle = isPattern
          ? 'Draw your pattern'
          : (lockType == AppLockType.pin6
              ? 'Enter your 6-digit PIN'
              : 'Enter your 4-digit PIN');

      final statusText = isCooldown
          ? 'Too many attempts. Try again in ${controller.cooldownSecondsRemaining.value}s'
          : (_errorMessage ?? defaultSubtitle);
      final isErrorState = _isError || isCooldown;

      return Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: Material(
          color: Colors.transparent,
          child: Stack(
            fit: StackFit.expand,
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  color: colors.surface.withOpacity(0.92),
                ),
              ),
              SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              const AnymeXAnimatedLogo(
                                size: 85,
                                autoPlay: true,
                              ),
                              Positioned(
                                right: -4,
                                bottom: -4,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isCooldown
                                        ? Colors.redAccent
                                        : colors.primary,
                                    boxShadow: [
                                      BoxShadow(
                                        color: (isCooldown
                                                ? Colors.redAccent
                                                : colors.primary)
                                            .withOpacity(0.4),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    isCooldown
                                        ? Icons.hourglass_top_rounded
                                        : Icons.lock_rounded,
                                    size: 14,
                                    color: isCooldown
                                        ? Colors.white
                                        : colors.onPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          AnymeXText(
                            'AnymeX Locked',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          AnymeXText(
                            statusText,
                            style: TextStyle(
                              fontSize: 13,
                              color: isErrorState
                                  ? Colors.redAccent
                                  : colors.onSurfaceVariant,
                              fontWeight: isErrorState
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (!isPattern) ...[
                            AnimatedBuilder(
                              animation: _shakeAnimation,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(_shakeAnimation.value, 0),
                                  child: child,
                                );
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children:
                                    List.generate(_requiredPinLength, (index) {
                                  final isFilled = index < _enteredPin.length;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 160),
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    width: 15,
                                    height: 15,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _isError
                                          ? Colors.redAccent
                                          : (isFilled
                                              ? colors.primary
                                              : Colors.transparent),
                                      border: Border.all(
                                        color: _isError
                                            ? Colors.redAccent
                                            : (isFilled
                                                ? colors.primary
                                                : colors.onSurfaceVariant
                                                    .withOpacity(0.4)),
                                        width: 2,
                                      ),
                                      boxShadow: isFilled && !_isError
                                          ? [
                                              BoxShadow(
                                                color: colors.primary
                                                    .withOpacity(0.4),
                                                blurRadius: 8,
                                                spreadRadius: 1,
                                              ),
                                            ]
                                          : null,
                                    ),
                                  );
                                }),
                              ),
                            ),
                            const SizedBox(height: 32),
                            Opacity(
                              opacity: isCooldown ? 0.35 : 1.0,
                              child: IgnorePointer(
                                ignoring: isCooldown,
                                child: _buildKeypad(context, controller),
                              ),
                            ),
                          ] else ...[
                            Opacity(
                              opacity: isCooldown ? 0.35 : 1.0,
                              child: IgnorePointer(
                                ignoring: isCooldown,
                                child: _PatternLockView(
                                  isError: _isError,
                                  onPatternComplete: (patternString) {
                                    final success = controller
                                        .unlockWithPin(patternString);
                                    if (!success) {
                                      setState(() {
                                        _isError = true;
                                        _errorMessage = controller
                                                    .cooldownSecondsRemaining
                                                    .value >
                                                0
                                            ? 'Too many attempts. Try again later.'
                                            : 'Incorrect Pattern';
                                      });
                                      _shakeController.forward(from: 0.0);
                                    }
                                  },
                                  onSecretDotLongPress: () {
                                    _showSecretResetDialog(context, controller);
                                  },
                                ),
                              ),
                            ),
                          ],
                          if (controller.allowEmergencyReset.value) ...[
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () =>
                                  _showSecretResetDialog(context, controller),
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    colors.onSurfaceVariant.withOpacity(0.8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                              ),
                              child: AnymeXText(
                                isPattern
                                    ? 'Forgot Pattern?'
                                    : 'Forgot PIN / Passcode?',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      colors.onSurfaceVariant.withOpacity(0.8),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildKeypad(BuildContext context, AppLockController controller) {
    final secretDigit = controller.secretPinDigit.value;
    final allowReset = controller.allowEmergencyReset.value;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKeypadDigit(
                context, '1', controller, secretDigit, allowReset),
            _buildKeypadDigit(
                context, '2', controller, secretDigit, allowReset),
            _buildKeypadDigit(
                context, '3', controller, secretDigit, allowReset),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKeypadDigit(
                context, '4', controller, secretDigit, allowReset),
            _buildKeypadDigit(
                context, '5', controller, secretDigit, allowReset),
            _buildKeypadDigit(
                context, '6', controller, secretDigit, allowReset),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKeypadDigit(
                context, '7', controller, secretDigit, allowReset),
            _buildKeypadDigit(
                context, '8', controller, secretDigit, allowReset),
            _buildKeypadDigit(
                context, '9', controller, secretDigit, allowReset),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Obx(() {
              if (controller.biometricsEnabled.value &&
                  controller.isBiometricsSupported.value) {
                return _buildIconButton(
                  context,
                  icon: Icons.fingerprint_rounded,
                  tooltip: 'Unlock with Biometrics',
                  onTap: () => controller.unlockWithBiometrics(),
                );
              }
              return const SizedBox(width: 68, height: 68);
            }),
            _buildKeypadDigit(
                context, '0', controller, secretDigit, allowReset),
            _buildIconButton(
              context,
              icon: Icons.backspace_outlined,
              tooltip: 'Delete',
              onTap: _onBackspacePressed,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeypadDigit(
    BuildContext context,
    String digit,
    AppLockController controller,
    String secretDigit,
    bool allowReset,
  ) {
    if (allowReset && digit == secretDigit) {
      return _buildSecretHoldKeypadButton(context, digit);
    }
    return _buildKeypadButton(context, digit);
  }

  Widget _buildKeypadButton(BuildContext context, String text) {
    final colors = context.colors;
    return AnymeXContainer(
      width: 68,
      height: 68,
      radius: 34,
      color: colors.surfaceContainerHighest.withOpacity(0.4),
      child: InkWell(
        borderRadius: BorderRadius.circular(34),
        onTap: () => _onDigitPressed(text),
        child: Center(
          child: AnymeXText(
            text,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecretHoldKeypadButton(BuildContext context, String digit) {
    final colors = context.colors;
    return GestureDetector(
      onTapDown: (_) => _startLongPressTimer(),
      onTapUp: (_) {
        _cancelLongPressTimer();
        _onDigitPressed(digit);
      },
      onTapCancel: _cancelLongPressTimer,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_longPressProgress > 0)
            SizedBox(
              width: 72,
              height: 72,
              child: CircularProgressIndicator(
                value: _longPressProgress,
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
              ),
            ),
          AnymeXContainer(
            width: 68,
            height: 68,
            radius: 34,
            color: colors.surfaceContainerHighest.withOpacity(0.4),
            child: Center(
              child: AnymeXText(
                digit,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    return Tooltip(
      message: tooltip,
      child: AnymeXContainer(
        width: 68,
        height: 68,
        radius: 34,
        color: colors.surfaceContainerHighest.withOpacity(0.25),
        child: InkWell(
          borderRadius: BorderRadius.circular(34),
          onTap: onTap,
          child: Center(
            child: Icon(
              icon,
              size: 26,
              color: colors.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _PatternLockView extends StatefulWidget {
  final bool isError;
  final ValueChanged<String> onPatternComplete;
  final VoidCallback onSecretDotLongPress;

  const _PatternLockView({
    required this.isError,
    required this.onPatternComplete,
    required this.onSecretDotLongPress,
  });

  @override
  State<_PatternLockView> createState() => _PatternLockViewState();
}

class _PatternLockViewState extends State<_PatternLockView> {
  final List<int> _selectedDots = [];
  Offset? _currentTouch;
  Timer? _secretDotTimer;
  double _secretDotProgress = 0.0;

  @override
  void dispose() {
    _secretDotTimer?.cancel();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details, BoxConstraints constraints) {
    _handleTouch(details.localPosition, constraints.maxWidth, isStart: true);
  }

  void _onPanUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    _handleTouch(details.localPosition, constraints.maxWidth);
  }

  void _onPanEnd(DragEndDetails details) {
    _secretDotTimer?.cancel();
    _secretDotProgress = 0.0;

    if (_selectedDots.length >= 4) {
      final patternString = _selectedDots.join('-');
      widget.onPatternComplete(patternString);
    }

    setState(() {
      _currentTouch = null;
      _selectedDots.clear();
    });
  }

  void _handleTouch(Offset localPos, double size, {bool isStart = false}) {
    final controller = Get.find<AppLockController>();
    final cellSize = size / 3;

    int? hitIndex;
    for (int i = 0; i < 9; i++) {
      final row = i ~/ 3;
      final col = i % 3;
      final center = Offset((col + 0.5) * cellSize, (row + 0.5) * cellSize);
      if ((localPos - center).distance <= 32) {
        hitIndex = i;
        break;
      }
    }

    final secretDot = controller.secretPatternDot.value;
    final allowReset = controller.allowEmergencyReset.value;

    if (allowReset && isStart && hitIndex == secretDot) {
      _startSecretDotLongPressTimer();
    } else if (hitIndex != secretDot) {
      _secretDotTimer?.cancel();
      _secretDotProgress = 0.0;
    }

    if (hitIndex != null && !_selectedDots.contains(hitIndex)) {
      controller.vibrateLight();
      setState(() {
        _selectedDots.add(hitIndex!);
        _currentTouch = localPos;
      });
    } else {
      setState(() {
        _currentTouch = localPos;
      });
    }
  }

  void _startSecretDotLongPressTimer() {
    final controller = Get.find<AppLockController>();
    _secretDotTimer?.cancel();
    _secretDotProgress = 0.0;
    int tick = 0;
    const totalTicks = 50;

    _secretDotTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      tick++;
      if (mounted) {
        setState(() {
          _secretDotProgress = tick / totalTicks;
        });
      }
      if (tick % 10 == 0) controller.vibrateLight();
      if (tick >= totalTicks) {
        t.cancel();
        _secretDotTimer?.cancel();
        _secretDotProgress = 0.0;
        controller.vibrateMedium();
        widget.onSecretDotLongPress();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final controller = Get.find<AppLockController>();
    const double size = 280;

    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              onPanStart: (d) => _onPanStart(d, constraints),
              onPanUpdate: (d) => _onPanUpdate(d, constraints),
              onPanEnd: _onPanEnd,
              child: Obx(
                () => CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _PatternPainter(
                    selectedDots: _selectedDots,
                    currentTouch: _currentTouch,
                    isError: widget.isError,
                    primaryColor: colors.primary,
                    dotColor: colors.onSurfaceVariant.withOpacity(0.35),
                    secretDotProgress: _secretDotProgress,
                    secretDotIndex: controller.secretPatternDot.value,
                    dotStyle: controller.patternDotStyle.value,
                    showPatternTrail: controller.showPatternTrail.value,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  final List<int> selectedDots;
  final Offset? currentTouch;
  final bool isError;
  final Color primaryColor;
  final Color dotColor;
  final double secretDotProgress;
  final int secretDotIndex;
  final PatternDotStyle dotStyle;
  final bool showPatternTrail;

  _PatternPainter({
    required this.selectedDots,
    required this.currentTouch,
    required this.isError,
    required this.primaryColor,
    required this.dotColor,
    required this.secretDotProgress,
    required this.secretDotIndex,
    required this.dotStyle,
    required this.showPatternTrail,
  });

  void _drawDiamond(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - size)
      ..lineTo(center.dx + size, center.dy)
      ..lineTo(center.dx, center.dy + size)
      ..lineTo(center.dx - size, center.dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    final s = size;
    path.moveTo(center.dx, center.dy + s * 0.6);
    path.cubicTo(
      center.dx - s * 1.1,
      center.dy - s * 0.1,
      center.dx - s * 1.1,
      center.dy - s * 0.8,
      center.dx,
      center.dy - s * 0.3,
    );
    path.cubicTo(
      center.dx + s * 1.1,
      center.dy - s * 0.8,
      center.dx + s * 1.1,
      center.dy - s * 0.1,
      center.dx,
      center.dy + s * 0.6,
    );
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawStar(Canvas canvas, Offset center, double outerR, double innerR,
      Paint paint) {
    final path = Path();
    const points = 5;
    const step = math.pi / points;
    for (int i = 0; i < points * 2; i++) {
      final r = i.isEven ? outerR : innerR;
      final angle = i * step - math.pi / 2;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / 3;
    final activeColor = isError ? Colors.redAccent : primaryColor;

    final List<Offset> dotCenters = List.generate(9, (i) {
      final row = i ~/ 3;
      final col = i % 3;
      return Offset((col + 0.5) * cellSize, (row + 0.5) * cellSize);
    });

    if (showPatternTrail && selectedDots.length > 1) {
      final linePaint = Paint()
        ..color = activeColor.withOpacity(0.7)
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < selectedDots.length - 1; i++) {
        canvas.drawLine(
          dotCenters[selectedDots[i]],
          dotCenters[selectedDots[i + 1]],
          linePaint,
        );
      }
    }

    if (showPatternTrail && selectedDots.isNotEmpty && currentTouch != null) {
      final rubberBandPaint = Paint()
        ..color = activeColor.withOpacity(0.5)
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        dotCenters[selectedDots.last],
        currentTouch!,
        rubberBandPaint,
      );
    }

    for (int i = 0; i < 9; i++) {
      final center = dotCenters[i];
      final isSelected = selectedDots.contains(i);

      if (i == secretDotIndex && secretDotProgress > 0) {
        final progressPaint = Paint()
          ..color = primaryColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: 26),
          -1.57,
          6.28 * secretDotProgress,
          false,
          progressPaint,
        );
      }

      if (isSelected) {
        switch (dotStyle) {
          case PatternDotStyle.circle:
            final outerPaint = Paint()
              ..color = activeColor.withOpacity(0.2)
              ..style = PaintingStyle.fill;
            canvas.drawCircle(center, 22, outerPaint);

            final ringPaint = Paint()
              ..color = activeColor
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.0;
            canvas.drawCircle(center, 22, ringPaint);

            final innerPaint = Paint()..color = activeColor;
            canvas.drawCircle(center, 7, innerPaint);
            break;

          case PatternDotStyle.glow:
            final glowPaint = Paint()
              ..color = activeColor.withOpacity(0.3)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
            canvas.drawCircle(center, 24, glowPaint);

            final ringPaint = Paint()
              ..color = activeColor
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.0;
            canvas.drawCircle(center, 20, ringPaint);

            final corePaint = Paint()..color = activeColor;
            canvas.drawCircle(center, 8, corePaint);
            break;

          case PatternDotStyle.diamond:
            final outerPaint = Paint()
              ..color = activeColor.withOpacity(0.2)
              ..style = PaintingStyle.fill;
            _drawDiamond(canvas, center, 22, outerPaint);

            final ringPaint = Paint()
              ..color = activeColor
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.0;
            _drawDiamond(canvas, center, 22, ringPaint);

            final innerPaint = Paint()..color = activeColor;
            _drawDiamond(canvas, center, 7, innerPaint);
            break;

          case PatternDotStyle.heart:
            final outerPaint = Paint()
              ..color = activeColor.withOpacity(0.25)
              ..style = PaintingStyle.fill;
            _drawHeart(canvas, center, 18, outerPaint);

            final ringPaint = Paint()
              ..color = activeColor
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.0;
            _drawHeart(canvas, center, 18, ringPaint);

            final innerPaint = Paint()..color = activeColor;
            _drawHeart(canvas, center, 8, innerPaint);
            break;

          case PatternDotStyle.star:
            final outerPaint = Paint()
              ..color = activeColor.withOpacity(0.25)
              ..style = PaintingStyle.fill;
            _drawStar(canvas, center, 22, 11, outerPaint);

            final ringPaint = Paint()
              ..color = activeColor
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.0;
            _drawStar(canvas, center, 22, 11, ringPaint);

            final innerPaint = Paint()..color = activeColor;
            _drawStar(canvas, center, 8, 4, innerPaint);
            break;
        }
      } else {
        switch (dotStyle) {
          case PatternDotStyle.circle:
            final dotPaint = Paint()..color = dotColor;
            canvas.drawCircle(center, 6, dotPaint);
            break;

          case PatternDotStyle.glow:
            final glowPaint = Paint()
              ..color = dotColor.withOpacity(0.25)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
            canvas.drawCircle(center, 10, glowPaint);
            final dotPaint = Paint()..color = dotColor;
            canvas.drawCircle(center, 5, dotPaint);
            break;

          case PatternDotStyle.diamond:
            final dotPaint = Paint()..color = dotColor;
            _drawDiamond(canvas, center, 6, dotPaint);
            break;

          case PatternDotStyle.heart:
            final dotPaint = Paint()..color = dotColor;
            _drawHeart(canvas, center, 6, dotPaint);
            break;

          case PatternDotStyle.star:
            final dotPaint = Paint()..color = dotColor;
            _drawStar(canvas, center, 7, 3.5, dotPaint);
            break;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PatternPainter oldDelegate) {
    return true;
  }
}
