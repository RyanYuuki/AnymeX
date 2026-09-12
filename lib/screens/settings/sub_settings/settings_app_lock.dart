import 'package:anymex/controllers/security/app_lock_controller.dart';
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
  ];

  String _getTimeoutTitle(int seconds) {
    for (final opt in _timeoutOptions) {
      if (opt['seconds'] == seconds) return opt['title'] as String;
    }
    return '$seconds seconds';
  }

  void _showSetPinDialog({required bool isInitialEnable}) {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AnymeXDialog(
          title: isInitialEnable ? 'Set 4-Digit PIN' : 'Enter New PIN',
          confirmText: 'Save PIN',
          contentWidget: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AnymeXText(
                'Enter 4-digit PIN',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: '••••',
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
              const AnymeXText(
                'Confirm 4-digit PIN',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confirmController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: '••••',
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

            if (pin.length != 4) {
              setDialogState(() => errorText = 'PIN must be exactly 4 digits');
              return;
            }
            if (pin != confirm) {
              setDialogState(() => errorText = 'PINs do not match');
              return;
            }

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

  void _showDisablePinDialog() {
    final pinController = TextEditingController();
    String? errorText;

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
              const AnymeXText(
                'Enter current 4-digit PIN to turn off App Lock:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: '••••',
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

  void _showChangePinDialog() {
    final oldPinController = TextEditingController();
    String? errorText;

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
              const AnymeXText(
                'Enter your current 4-digit PIN to proceed:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: oldPinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: '••••',
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
              _showSetPinDialog(isInitialEnable: false);
            } else {
              setDialogState(() => errorText = 'Incorrect PIN');
            }
          },
        ),
      ),
    );
  }

  void _showTimeoutPicker() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AnymeXDialog(
        title: 'Auto-Lock Timeout',
        confirmText: 'Done',
        contentWidget: Column(
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
                          ? 'Protection is active with PIN'
                          : 'Lock AnymeX with PIN and Biometrics',
                      trailing: Switch(
                        value: _controller.isEnabled.value,
                        onChanged: (val) {
                          if (val) {
                            _showSetPinDialog(isInitialEnable: true);
                          } else {
                            _showDisablePinDialog();
                          }
                        },
                      ),
                    ),
                    if (_controller.isEnabled.value) ...[
                      AnymeXTile(
                        icon: Icons.password_rounded,
                        title: 'Change PIN',
                        subtitle: 'Update your 4-digit security PIN',
                        onTap: _showChangePinDialog,
                      ),
                      if (_controller.isBiometricsSupported.value)
                        AnymeXTile(
                          icon: Icons.fingerprint_rounded,
                          title: 'Biometric Unlock',
                          subtitle: 'Unlock quickly using Fingerprint or Face ID',
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
                  AnymeXSectionBuilder(
                    title: 'Lock Behavior',
                    children: [
                      AnymeXTile(
                        icon: Icons.timer_outlined,
                        title: 'Lock After',
                        subtitle: _getTimeoutTitle(_controller.timeoutSeconds.value),
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
                    ],
                  ),
                  AnymeXSectionBuilder(
                    title: 'Instant Action',
                    children: [
                      AnymeXTile(
                        icon: Icons.lock_clock_rounded,
                        title: 'Lock App Now',
                        subtitle: 'Immediately lock AnymeX to test lock screen',
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
