import 'dart:ui';
import 'package:anymex/controllers/security/app_lock_controller.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_container.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
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
            controller.isBiometricsSupported.value) {
          controller.unlockWithBiometrics();
        }
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _onDigitPressed(String digit) {
    final controller = Get.find<AppLockController>();
    if (controller.cooldownSecondsRemaining.value > 0) return;
    if (_enteredPin.length >= 4) return;

    HapticFeedback.lightImpact();
    setState(() {
      _enteredPin += digit;
      _isError = false;
      _errorMessage = null;
    });

    if (_enteredPin.length == 4) {
      _verifyPin();
    }
  }

  void _onBackspacePressed() {
    final controller = Get.find<AppLockController>();
    if (controller.cooldownSecondsRemaining.value > 0) return;
    if (_enteredPin.isEmpty) return;

    HapticFeedback.lightImpact();
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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final controller = Get.find<AppLockController>();

    return Obx(() {
      final isCooldown = controller.cooldownSecondsRemaining.value > 0;
      final statusText = isCooldown
          ? 'Too many attempts. Try again in ${controller.cooldownSecondsRemaining.value}s'
          : (_errorMessage ?? 'Enter your 4-digit PIN');
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
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: (isCooldown ? Colors.redAccent : colors.primary).withOpacity(0.12),
                              border: Border.all(
                                color: (isCooldown ? Colors.redAccent : colors.primary).withOpacity(0.35),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (isCooldown ? Colors.redAccent : colors.primary).withOpacity(0.18),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              isCooldown ? Icons.hourglass_top_rounded : Icons.lock_rounded,
                              size: 40,
                              color: isCooldown ? Colors.redAccent : colors.primary,
                            ),
                          ),
                          const SizedBox(height: 20),
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
                              color: isErrorState ? Colors.redAccent : colors.onSurfaceVariant,
                              fontWeight: isErrorState ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 28),
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
                              children: List.generate(4, (index) {
                                final isFilled = index < _enteredPin.length;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  margin: const EdgeInsets.symmetric(horizontal: 10),
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _isError
                                        ? Colors.redAccent
                                        : (isFilled ? colors.primary : Colors.transparent),
                                    border: Border.all(
                                      color: _isError
                                          ? Colors.redAccent
                                          : (isFilled
                                              ? colors.primary
                                              : colors.onSurfaceVariant.withOpacity(0.4)),
                                      width: 2,
                                    ),
                                    boxShadow: isFilled && !_isError
                                        ? [
                                            BoxShadow(
                                              color: colors.primary.withOpacity(0.4),
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
                          const SizedBox(height: 36),
                          Opacity(
                            opacity: isCooldown ? 0.35 : 1.0,
                            child: IgnorePointer(
                              ignoring: isCooldown,
                              child: _buildKeypad(context, controller),
                            ),
                          ),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKeypadButton(context, '1'),
            _buildKeypadButton(context, '2'),
            _buildKeypadButton(context, '3'),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKeypadButton(context, '4'),
            _buildKeypadButton(context, '5'),
            _buildKeypadButton(context, '6'),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKeypadButton(context, '7'),
            _buildKeypadButton(context, '8'),
            _buildKeypadButton(context, '9'),
          ],
        ),
        const SizedBox(height: 14),
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
            _buildKeypadButton(context, '0'),
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
