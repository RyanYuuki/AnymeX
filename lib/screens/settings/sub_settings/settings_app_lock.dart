import 'dart:math' as math;
import 'package:anymex/controllers/security/app_lock_controller.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class SettingsAppLock extends StatefulWidget {
  const SettingsAppLock({super.key});

  @override
  State<SettingsAppLock> createState() => _SettingsAppLockState();
}

class _SettingsAppLockState extends State<SettingsAppLock> {
  final AppLockController _controller = Get.find<AppLockController>();

  final List<Map<String, dynamic>> _timeoutOptions = [
    {'title': 'Immediately', 'seconds': 0, 'subtitle': 'Lock as soon as app goes to background'},
    {'title': '30 seconds', 'seconds': 30, 'subtitle': 'Lock after 30 seconds in background'},
    {'title': '1 minute', 'seconds': 60, 'subtitle': 'Lock after 1 minute in background'},
    {'title': '2 minutes', 'seconds': 120, 'subtitle': 'Lock after 2 minutes in background'},
    {'title': '5 minutes', 'seconds': 300, 'subtitle': 'Lock after 5 minutes in background'},
    {'title': '15 minutes', 'seconds': 900, 'subtitle': 'Lock after 15 minutes in background'},
    {'title': '30 minutes', 'seconds': 1800, 'subtitle': 'Lock after 30 minutes in background'},
    {'title': '1 hour', 'seconds': 3600, 'subtitle': 'Lock after 1 hour in background'},
    {'title': 'On App Restart Only', 'seconds': -1, 'subtitle': 'Only lock when app is closed and reopened'},
    {'title': 'Never', 'seconds': -2, 'subtitle': 'Never auto-lock (lock manually only)'},
  ];

  String _getTimeoutTitle(int seconds) {
    for (final opt in _timeoutOptions) {
      if (opt['seconds'] == seconds) return opt['title'] as String;
    }
    return '$seconds seconds';
  }

  String _getLockTypeName(AppLockType type) {
    switch (type) {
      case AppLockType.pin4:
        return '4-Digit PIN';
      case AppLockType.pin6:
        return '6-Digit PIN';
      case AppLockType.pattern:
        return 'Pattern Lock';
    }
  }

  String _getDotStyleName(PatternDotStyle style) {
    switch (style) {
      case PatternDotStyle.circle:
        return 'Classic Circle';
      case PatternDotStyle.glow:
        return 'Glowing Orb';
      case PatternDotStyle.diamond:
        return 'Neon Diamond';
      case PatternDotStyle.heart:
        return 'Anime Heart';
      case PatternDotStyle.star:
        return 'Anime Star';
    }
  }

  String _getPatternDotName(int dotIndex) {
    final names = [
      'Top-Left (1)',
      'Top-Center (2)',
      'Top-Right (3)',
      'Middle-Left (4)',
      'Center Dot (5)',
      'Middle-Right (6)',
      'Bottom-Left (7)',
      'Bottom-Center (8)',
      'Bottom-Right (9)',
    ];
    if (dotIndex >= 0 && dotIndex < names.length) {
      return names[dotIndex];
    }
    return 'Dot ${dotIndex + 1}';
  }

  void _showLockTypeDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AnymeXDialog(
        title: 'Select Lock Type',
        confirmText: 'Done',
        contentWidget: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLockTypeOption(dialogCtx, AppLockType.pin4, '4-Digit PIN',
                'Fast and convenient numeric lock'),
            _buildLockTypeOption(dialogCtx, AppLockType.pin6, '6-Digit PIN',
                'Enhanced security numeric passcode'),
            _buildLockTypeOption(dialogCtx, AppLockType.pattern,
                'Pattern Lock (3×3 Grid)', 'Gesture-based connected pattern'),
          ],
        ),
        onConfirm: () {},
      ),
    );
  }

  Widget _buildLockTypeOption(BuildContext dialogCtx, AppLockType type,
      String title, String subtitle) {
    final isSelected = _controller.lockType.value == type;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        Navigator.of(dialogCtx).pop();
        if (_controller.lockType.value == type) return;

        if (type == AppLockType.pin4) {
          _showSetPinDialog(isInitialEnable: false, pinLength: 4);
        } else if (type == AppLockType.pin6) {
          _showSetPinDialog(isInitialEnable: false, pinLength: 6);
        } else {
          _showSetPatternDialog(isInitialEnable: false);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isSelected
                  ? context.colors.primary
                  : context.colors.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnymeXText(
                    title,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected
                          ? context.colors.primary
                          : context.colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnymeXText(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSetPinDialog(
      {required bool isInitialEnable, required int pinLength}) {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AnymeXDialog(
          title: isInitialEnable
              ? 'Set $pinLength-Digit PIN'
              : 'Enter New $pinLength-Digit PIN',
          confirmText: 'Save PIN',
          contentWidget: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnymeXText(
                'Enter $pinLength-digit PIN',
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: pinLength,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: '•' * pinLength,
                  counterText: '',
                  filled: true,
                  fillColor: context.colors.surfaceContainer,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (_) => setDialogState(() => errorText = null),
              ),
              const SizedBox(height: 14),
              AnymeXText(
                'Confirm $pinLength-digit PIN',
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confirmController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: pinLength,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: '•' * pinLength,
                  counterText: '',
                  filled: true,
                  fillColor: context.colors.surfaceContainer,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  errorText: errorText,
                ),
                onChanged: (_) => setDialogState(() => errorText = null),
              ),
            ],
          ),
          onConfirm: () {
            final pin = pinController.text.trim();
            final confirm = confirmController.text.trim();

            if (pin.length != pinLength) {
              setDialogState(
                  () => errorText = 'PIN must be exactly $pinLength digits');
              return;
            }
            if (pin != confirm) {
              setDialogState(() => errorText = 'PINs do not match');
              return;
            }

            final lockType =
                pinLength == 6 ? AppLockType.pin6 : AppLockType.pin4;
            _controller.setLockType(lockType);

            if (isInitialEnable) {
              _controller.enableAppLock(pin);
              snackBar('App Lock enabled successfully!');
            } else {
              _controller.updatePin(pin);
              snackBar('PIN updated successfully!');
            }
          },
        ),
      ),
    );
  }

  void _showSetPatternDialog({required bool isInitialEnable}) {
    String? firstPattern;
    String status = 'Draw your pattern (connect at least 4 dots)';
    String? errorMessage;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AnymeXDialog(
          title: isInitialEnable ? 'Set Pattern Lock' : 'Change Pattern Lock',
          confirmText: 'Cancel',
          onConfirm: () {},
          contentWidget: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnymeXText(
                status,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: errorMessage != null
                      ? Colors.redAccent
                      : context.colors.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 4),
                AnymeXText(
                  errorMessage!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.redAccent,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 16),
              _PatternSetupCanvas(
                dotStyle: _controller.patternDotStyle.value,
                showTrail: _controller.showPatternTrail.value,
                primaryColor: context.colors.primary,
                dotColor: context.colors.onSurfaceVariant.withOpacity(0.35),
                onPatternComplete: (dots) {
                  final patternStr = dots.join('-');
                  if (dots.length < 4) {
                    setDialogState(() {
                      errorMessage = 'Connect at least 4 dots';
                    });
                    return;
                  }

                  if (firstPattern == null) {
                    setDialogState(() {
                      firstPattern = patternStr;
                      status = 'Draw pattern again to confirm';
                      errorMessage = null;
                    });
                  } else {
                    if (patternStr == firstPattern) {
                      _controller.setLockType(AppLockType.pattern);
                      if (isInitialEnable) {
                        _controller.enableAppLock(patternStr);
                        snackBar('Pattern Lock enabled successfully!');
                      } else {
                        _controller.updatePin(patternStr);
                        snackBar('Pattern Lock updated successfully!');
                      }
                      Navigator.of(dialogCtx).pop();
                    } else {
                      setDialogState(() {
                        firstPattern = null;
                        status = 'Draw your pattern (connect at least 4 dots)';
                        errorMessage = 'Patterns did not match. Try again.';
                      });
                    }
                  }
                },
              ),
              const SizedBox(height: 12),
              if (firstPattern != null)
                TextButton.icon(
                  onPressed: () {
                    setDialogState(() {
                      firstPattern = null;
                      status = 'Draw your pattern (connect at least 4 dots)';
                      errorMessage = null;
                    });
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const AnymeXText('Redo Pattern',
                      style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDisableLockDialog() {
    if (_controller.lockType.value == AppLockType.pattern) {
      String? errorText;
      showDialog(
        context: context,
        builder: (dialogCtx) => StatefulBuilder(
          builder: (ctx, setDialogState) => AnymeXDialog(
            title: 'Disable App Lock',
            confirmText: 'Cancel',
            onConfirm: () {},
            contentWidget: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnymeXText(
                  'Draw your current pattern to turn off App Lock:',
                  style: TextStyle(
                    fontSize: 13,
                    color: errorText != null
                        ? Colors.redAccent
                        : context.colors.onSurface,
                  ),
                ),
                const SizedBox(height: 14),
                _PatternSetupCanvas(
                  dotStyle: _controller.patternDotStyle.value,
                  showTrail: _controller.showPatternTrail.value,
                  primaryColor: context.colors.primary,
                  dotColor: context.colors.onSurfaceVariant.withOpacity(0.35),
                  onPatternComplete: (dots) {
                    final patternStr = dots.join('-');
                    if (_controller.verifyPin(patternStr)) {
                      Navigator.of(dialogCtx).pop();
                      _controller.disableAppLock();
                      snackBar('App Lock disabled.');
                    } else {
                      setDialogState(() => errorText = 'Incorrect pattern');
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      final pinController = TextEditingController();
      String? errorText;
      final pinLength =
          _controller.lockType.value == AppLockType.pin6 ? 6 : 4;

      showDialog(
        context: context,
        builder: (dialogCtx) => StatefulBuilder(
          builder: (context, setDialogState) => AnymeXDialog(
            title: 'Disable App Lock',
            confirmText: 'Disable',
            contentWidget: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnymeXText(
                  'Enter current $pinLength-digit PIN to turn off App Lock:',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: pinLength,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: '•' * pinLength,
                    counterText: '',
                    filled: true,
                    fillColor: context.colors.surfaceContainer,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    errorText: errorText,
                  ),
                  onChanged: (_) => setDialogState(() => errorText = null),
                ),
              ],
            ),
            onConfirm: () {
              final pin = pinController.text.trim();
              if (_controller.verifyPin(pin)) {
                _controller.disableAppLock();
                snackBar('App Lock disabled.');
              } else {
                setDialogState(() => errorText = 'Incorrect PIN');
              }
            },
          ),
        ),
      );
    }
  }

  void _showChangeLockDialog() {
    if (_controller.lockType.value == AppLockType.pattern) {
      String? errorText;
      showDialog(
        context: context,
        builder: (dialogCtx) => StatefulBuilder(
          builder: (ctx, setDialogState) => AnymeXDialog(
            title: 'Verify Current Pattern',
            confirmText: 'Cancel',
            onConfirm: () {},
            contentWidget: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnymeXText(
                  'Draw your current pattern to proceed:',
                  style: TextStyle(
                    fontSize: 13,
                    color: errorText != null
                        ? Colors.redAccent
                        : context.colors.onSurface,
                  ),
                ),
                const SizedBox(height: 14),
                _PatternSetupCanvas(
                  dotStyle: _controller.patternDotStyle.value,
                  showTrail: _controller.showPatternTrail.value,
                  primaryColor: context.colors.primary,
                  dotColor: context.colors.onSurfaceVariant.withOpacity(0.35),
                  onPatternComplete: (dots) {
                    final patternStr = dots.join('-');
                    if (_controller.verifyPin(patternStr)) {
                      Navigator.of(dialogCtx).pop();
                      _showSetPatternDialog(isInitialEnable: false);
                    } else {
                      setDialogState(() => errorText = 'Incorrect pattern');
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      final oldPinController = TextEditingController();
      String? errorText;
      final pinLength =
          _controller.lockType.value == AppLockType.pin6 ? 6 : 4;

      showDialog(
        context: context,
        builder: (dialogCtx) => StatefulBuilder(
          builder: (context, setDialogState) => AnymeXDialog(
            title: 'Verify Current PIN',
            confirmText: 'Next',
            contentWidget: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnymeXText(
                  'Enter your current $pinLength-digit PIN to proceed:',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: oldPinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: pinLength,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: '•' * pinLength,
                    counterText: '',
                    filled: true,
                    fillColor: context.colors.surfaceContainer,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    errorText: errorText,
                  ),
                  onChanged: (_) => setDialogState(() => errorText = null),
                ),
              ],
            ),
            onConfirm: () {
              final oldPin = oldPinController.text.trim();
              if (_controller.verifyPin(oldPin)) {
                Navigator.of(dialogCtx).pop();
                _showSetPinDialog(
                    isInitialEnable: false, pinLength: pinLength);
              } else {
                setDialogState(() => errorText = 'Incorrect PIN');
              }
            },
          ),
        ),
      );
    }
  }

  void _showDotStylePicker() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AnymeXDialog(
        title: 'Pattern Dot Style',
        confirmText: 'Done',
        contentWidget: Column(
          mainAxisSize: MainAxisSize.min,
          children: PatternDotStyle.values.map((style) {
            return Obx(() {
              final isSelected = _controller.patternDotStyle.value == style;
              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  _controller.setPatternDotStyle(style);
                  Navigator.of(dialogCtx).pop();
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: isSelected
                            ? context.colors.primary
                            : context.colors.onSurfaceVariant,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AnymeXText(
                          _getDotStyleName(style),
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: isSelected
                                ? context.colors.primary
                                : context.colors.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            });
          }).toList(),
        ),
        onConfirm: () {},
      ),
    );
  }

  void _showSecretPinDigitPicker() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AnymeXDialog(
        title: 'Emergency Secret Key',
        confirmText: 'Done',
        contentWidget: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AnymeXText(
              'Select which number on the keypad triggers the emergency reset when held for 5 seconds:',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: List.generate(10, (index) {
                final digit = index.toString();
                return Obx(() {
                  final isSelected = _controller.secretPinDigit.value == digit;
                  return InkWell(
                    borderRadius: BorderRadius.circular(25),
                    onTap: () {
                      _controller.setSecretPinDigit(digit);
                      Navigator.of(dialogCtx).pop();
                      snackBar('Secret reset key set to $digit');
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? context.colors.primary
                            : context.colors.surfaceContainerHighest
                                .withOpacity(0.5),
                      ),
                      child: Center(
                        child: AnymeXText(
                          digit,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? context.colors.onPrimary
                                : context.colors.onSurface,
                          ),
                        ),
                      ),
                    ),
                  );
                });
              }),
            ),
          ],
        ),
        onConfirm: () {},
      ),
    );
  }

  void _showSecretPatternDotPicker() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AnymeXDialog(
        title: 'Emergency Secret Dot',
        confirmText: 'Done',
        contentWidget: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AnymeXText(
              'Select which dot on the 3×3 pattern grid triggers the emergency reset when held for 5 seconds:',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 180,
              height: 180,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: 9,
                itemBuilder: (ctx, index) {
                  return Obx(() {
                    final isSelected =
                        _controller.secretPatternDot.value == index;
                    return InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {
                        _controller.setSecretPatternDot(index);
                        Navigator.of(dialogCtx).pop();
                        snackBar(
                            'Secret reset dot set to ${_getPatternDotName(index)}');
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? context.colors.primary
                              : context.colors.surfaceContainerHighest
                                  .withOpacity(0.5),
                          border: Border.all(
                            color: isSelected
                                ? context.colors.primary
                                : context.colors.outline.withOpacity(0.2),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: AnymeXText(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? context.colors.onPrimary
                                  : context.colors.onSurface,
                            ),
                          ),
                        ),
                      ),
                    );
                  });
                },
              ),
            ),
          ],
        ),
        onConfirm: () {},
      ),
    );
  }

  void _showTimeoutPicker() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AnymeXDialog(
        title: 'Auto-Lock Timeout',
        confirmText: 'Done',
        contentWidget: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.55,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _timeoutOptions.map((opt) {
                final seconds = opt['seconds'] as int;
                final title = opt['title'] as String;
                final subtitle = opt['subtitle'] as String;
                return Obx(() {
                  final isSelected = _controller.timeoutSeconds.value == seconds;
                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      _controller.setTimeoutSeconds(seconds);
                      Navigator.of(dialogCtx).pop();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: isSelected
                                ? context.colors.primary
                                : context.colors.onSurfaceVariant,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AnymeXText(
                                  title,
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? context.colors.primary
                                        : context.colors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                AnymeXText(
                                  subtitle,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: context.colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                });
              }).toList(),
            ),
          ),
        ),
        onConfirm: () {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnymeXScaffold(
      showHeader: true,
      headerTitle: 'Security & App Lock',
      body: Builder(
        builder: (ctx) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16.0,
            AnymeXHeaderScope.of(ctx),
            16.0,
            30.0,
          ),
          child: Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnymeXSectionBuilder(
                  title: 'App Protection',
                  children: [
                    AnymeXTile(
                      icon: Icons.lock_outline_rounded,
                      title: 'App Lock',
                      subtitle: _controller.isEnabled.value
                          ? 'Protection is active with ${_getLockTypeName(_controller.lockType.value)}'
                          : 'Lock AnymeX with PIN, Pattern, or Biometrics',
                      trailing: Switch(
                        value: _controller.isEnabled.value,
                        onChanged: (val) {
                          if (val) {
                            if (_controller.lockType.value ==
                                AppLockType.pattern) {
                              _showSetPatternDialog(isInitialEnable: true);
                            } else {
                              final pinLength = _controller.lockType.value ==
                                      AppLockType.pin6
                                  ? 6
                                  : 4;
                              _showSetPinDialog(
                                  isInitialEnable: true,
                                  pinLength: pinLength);
                            }
                          } else {
                            _showDisableLockDialog();
                          }
                        },
                      ),
                    ),
                    if (_controller.isEnabled.value) ...[
                      AnymeXTile(
                        icon: Icons.lock_clock_rounded,
                        title: 'Lock Type',
                        subtitle:
                            _getLockTypeName(_controller.lockType.value),
                        onTap: _showLockTypeDialog,
                      ),
                      AnymeXTile(
                        icon: Icons.password_rounded,
                        title: _controller.lockType.value ==
                                AppLockType.pattern
                            ? 'Change Pattern'
                            : 'Change PIN',
                        subtitle: _controller.lockType.value ==
                                AppLockType.pattern
                            ? 'Update your 3×3 pattern lock'
                            : 'Update your security PIN',
                        onTap: _showChangeLockDialog,
                      ),
                      if (_controller.isBiometricsSupported.value)
                        AnymeXTile(
                          icon: Icons.fingerprint_rounded,
                          title: 'Biometric Unlock',
                          subtitle:
                              'Unlock quickly using Fingerprint or Face ID',
                          trailing: Switch(
                            value: _controller.biometricsEnabled.value,
                            onChanged: (val) async {
                              if (val) {
                                final verified =
                                    await _controller.unlockWithBiometrics();
                                if (verified) {
                                  _controller.setBiometricsEnabled(true);
                                  snackBar('Biometric unlock enabled');
                                } else {
                                  snackBar(
                                      'Biometric verification cancelled or failed');
                                }
                              } else {
                                _controller.setBiometricsEnabled(false);
                              }
                            },
                          ),
                        ),
                    ],
                  ],
                ),
                if (_controller.isEnabled.value) ...[
                  if (_controller.lockType.value ==
                      AppLockType.pattern) ...[
                    AnymeXSectionBuilder(
                      title: 'Pattern Customization',
                      children: [
                        AnymeXTile(
                          icon: Icons.scatter_plot_rounded,
                          title: 'Pattern Dot Style',
                          subtitle: _getDotStyleName(
                              _controller.patternDotStyle.value),
                          onTap: _showDotStylePicker,
                        ),
                        AnymeXTile(
                          icon: Icons.gesture_rounded,
                          title: 'Show Pattern Trail',
                          subtitle:
                              'Display connecting lines while drawing pattern',
                          trailing: Switch(
                            value: _controller.showPatternTrail.value,
                            onChanged: (val) {
                              _controller.setShowPatternTrail(val);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                  AnymeXSectionBuilder(
                    title: 'Emergency Recovery',
                    children: [
                      AnymeXTile(
                        icon: Icons.restore_rounded,
                        title: 'Allow Emergency Reset',
                        subtitle:
                            'Enable "Forgot Passcode" and secret 5s hold bypass',
                        trailing: Switch(
                          value: _controller.allowEmergencyReset.value,
                          onChanged: (val) {
                            _controller.setAllowEmergencyReset(val);
                          },
                        ),
                      ),
                      if (_controller.allowEmergencyReset.value) ...[
                        if (_controller.lockType.value ==
                            AppLockType.pattern)
                          AnymeXTile(
                            icon: Icons.touch_app_rounded,
                            title: 'Secret Emergency Dot',
                            subtitle: _getPatternDotName(
                                _controller.secretPatternDot.value),
                            onTap: _showSecretPatternDotPicker,
                          )
                        else
                          AnymeXTile(
                            icon: Icons.dialpad_rounded,
                            title: 'Secret Emergency Key',
                            subtitle:
                                'Key: "${_controller.secretPinDigit.value}"',
                            onTap: _showSecretPinDigitPicker,
                          ),
                        Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: context.colors.surfaceContainerHighest
                                .withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: context.colors.outline.withOpacity(0.15),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 18,
                                color: context.colors.primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: AnymeXText(
                                  _controller.lockType.value ==
                                          AppLockType.pattern
                                      ? 'If forgotten, tap "Forgot Pattern?" or press & hold ${_getPatternDotName(_controller.secretPatternDot.value)} for 5s to safely reset. Your downloads, library, and account logins will be preserved.'
                                      : 'If forgotten, tap "Forgot PIN?" or press & hold "${_controller.secretPinDigit.value}" for 5s to safely reset. Your downloads, library, and account logins will be preserved.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    height: 1.4,
                                    color: context.colors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  AnymeXSectionBuilder(
                    title: 'Lock Behavior',
                    children: [
                      AnymeXTile(
                        icon: Icons.timer_outlined,
                        title: 'Lock After',
                        subtitle: _getTimeoutTitle(
                            _controller.timeoutSeconds.value),
                        onTap: _showTimeoutPicker,
                      ),
                      AnymeXTile(
                        icon: Icons.shield_outlined,
                        title: 'Privacy Screen in App Switcher',
                        subtitle:
                            'Hide app content with privacy blur when switching apps',
                        trailing: Switch(
                          value: _controller.hideInRecentApps.value,
                          onChanged: (val) {
                            _controller.setHideInRecentApps(val);
                          },
                        ),
                      ),
                      AnymeXTile(
                        icon: Icons.vibration_rounded,
                        title: 'Haptic Feedback',
                        subtitle:
                            'Vibrate when pressing keypad or drawing pattern',
                        trailing: Switch(
                          value: _controller.hapticsEnabled.value,
                          onChanged: (val) {
                            _controller.setHapticsEnabled(val);
                          },
                        ),
                      ),
                    ],
                  ),
                  AnymeXSectionBuilder(
                    title: 'Instant Action',
                    children: [
                      AnymeXTile(
                        icon: Icons.lock_clock_rounded,
                        title: 'Lock App Now',
                        subtitle:
                            'Immediately lock AnymeX to test lock screen & custom dots',
                        onTap: () {
                          _controller.lockManually();
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PatternSetupCanvas extends StatefulWidget {
  final PatternDotStyle dotStyle;
  final bool showTrail;
  final Color primaryColor;
  final Color dotColor;
  final ValueChanged<List<int>> onPatternComplete;

  const _PatternSetupCanvas({
    required this.dotStyle,
    required this.showTrail,
    required this.primaryColor,
    required this.dotColor,
    required this.onPatternComplete,
  });

  @override
  State<_PatternSetupCanvas> createState() => _PatternSetupCanvasState();
}

class _PatternSetupCanvasState extends State<_PatternSetupCanvas> {
  final List<int> _selectedDots = [];
  Offset? _currentTouch;

  void _onPanStart(DragStartDetails details, BoxConstraints constraints) {
    _handleTouch(details.localPosition, constraints.maxWidth);
  }

  void _onPanUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    _handleTouch(details.localPosition, constraints.maxWidth);
  }

  void _onPanEnd(DragEndDetails details) {
    if (_selectedDots.isNotEmpty) {
      widget.onPatternComplete(List<int>.from(_selectedDots));
    }
    setState(() {
      _selectedDots.clear();
      _currentTouch = null;
    });
  }

  void _handleTouch(Offset localPos, double size) {
    final cellSize = size / 3;
    for (int i = 0; i < 9; i++) {
      final row = i ~/ 3;
      final col = i % 3;
      final center = Offset((col + 0.5) * cellSize, (row + 0.5) * cellSize);
      if ((localPos - center).distance <= 28) {
        if (!_selectedDots.contains(i)) {
          final controller = Get.find<AppLockController>();
          controller.vibrateLight();
          setState(() {
            _selectedDots.add(i);
            _currentTouch = localPos;
          });
        }
        return;
      }
    }
    setState(() {
      _currentTouch = localPos;
    });
  }

  @override
  Widget build(BuildContext context) {
    const double size = 240;
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
              child: CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: _PatternSetupPainter(
                  selectedDots: _selectedDots,
                  currentTouch: _currentTouch,
                  primaryColor: widget.primaryColor,
                  dotColor: widget.dotColor,
                  dotStyle: widget.dotStyle,
                  showTrail: widget.showTrail,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PatternSetupPainter extends CustomPainter {
  final List<int> selectedDots;
  final Offset? currentTouch;
  final Color primaryColor;
  final Color dotColor;
  final PatternDotStyle dotStyle;
  final bool showTrail;

  _PatternSetupPainter({
    required this.selectedDots,
    required this.currentTouch,
    required this.primaryColor,
    required this.dotColor,
    required this.dotStyle,
    required this.showTrail,
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

    final List<Offset> dotCenters = List.generate(9, (i) {
      final row = i ~/ 3;
      final col = i % 3;
      return Offset((col + 0.5) * cellSize, (row + 0.5) * cellSize);
    });

    if (showTrail && selectedDots.length > 1) {
      final linePaint = Paint()
        ..color = primaryColor.withOpacity(0.7)
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < selectedDots.length - 1; i++) {
        canvas.drawLine(
          dotCenters[selectedDots[i]],
          dotCenters[selectedDots[i + 1]],
          linePaint,
        );
      }
    }

    if (showTrail && selectedDots.isNotEmpty && currentTouch != null) {
      final rubberBandPaint = Paint()
        ..color = primaryColor.withOpacity(0.5)
        ..strokeWidth = 2.5
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

      if (isSelected) {
        switch (dotStyle) {
          case PatternDotStyle.circle:
            final outerPaint = Paint()
              ..color = primaryColor.withOpacity(0.2)
              ..style = PaintingStyle.fill;
            canvas.drawCircle(center, 18, outerPaint);

            final ringPaint = Paint()
              ..color = primaryColor
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.0;
            canvas.drawCircle(center, 18, ringPaint);

            final innerPaint = Paint()..color = primaryColor;
            canvas.drawCircle(center, 6, innerPaint);
            break;

          case PatternDotStyle.glow:
            final glowPaint = Paint()
              ..color = primaryColor.withOpacity(0.3)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
            canvas.drawCircle(center, 20, glowPaint);

            final ringPaint = Paint()
              ..color = primaryColor
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.0;
            canvas.drawCircle(center, 16, ringPaint);

            final corePaint = Paint()..color = primaryColor;
            canvas.drawCircle(center, 7, corePaint);
            break;

          case PatternDotStyle.diamond:
            final outerPaint = Paint()
              ..color = primaryColor.withOpacity(0.2)
              ..style = PaintingStyle.fill;
            _drawDiamond(canvas, center, 18, outerPaint);

            final ringPaint = Paint()
              ..color = primaryColor
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.0;
            _drawDiamond(canvas, center, 18, ringPaint);

            final innerPaint = Paint()..color = primaryColor;
            _drawDiamond(canvas, center, 6, innerPaint);
            break;

          case PatternDotStyle.heart:
            final outerPaint = Paint()
              ..color = primaryColor.withOpacity(0.25)
              ..style = PaintingStyle.fill;
            _drawHeart(canvas, center, 15, outerPaint);

            final ringPaint = Paint()
              ..color = primaryColor
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.0;
            _drawHeart(canvas, center, 15, ringPaint);

            final innerPaint = Paint()..color = primaryColor;
            _drawHeart(canvas, center, 7, innerPaint);
            break;

          case PatternDotStyle.star:
            final outerPaint = Paint()
              ..color = primaryColor.withOpacity(0.25)
              ..style = PaintingStyle.fill;
            _drawStar(canvas, center, 18, 9, outerPaint);

            final ringPaint = Paint()
              ..color = primaryColor
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.0;
            _drawStar(canvas, center, 18, 9, ringPaint);

            final innerPaint = Paint()..color = primaryColor;
            _drawStar(canvas, center, 7, 3.5, innerPaint);
            break;
        }
      } else {
        switch (dotStyle) {
          case PatternDotStyle.circle:
            final dotPaint = Paint()..color = dotColor;
            canvas.drawCircle(center, 5, dotPaint);
            break;

          case PatternDotStyle.glow:
            final glowPaint = Paint()
              ..color = dotColor.withOpacity(0.25)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
            canvas.drawCircle(center, 8, glowPaint);
            final dotPaint = Paint()..color = dotColor;
            canvas.drawCircle(center, 4, dotPaint);
            break;

          case PatternDotStyle.diamond:
            final dotPaint = Paint()..color = dotColor;
            _drawDiamond(canvas, center, 5, dotPaint);
            break;

          case PatternDotStyle.heart:
            final dotPaint = Paint()..color = dotColor;
            _drawHeart(canvas, center, 5, dotPaint);
            break;

          case PatternDotStyle.star:
            final dotPaint = Paint()..color = dotColor;
            _drawStar(canvas, center, 6, 3, dotPaint);
            break;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PatternSetupPainter oldDelegate) {
    return true;
  }
}
