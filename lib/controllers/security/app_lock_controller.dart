import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/utils/logger.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';

AppLockController get appLockController => Get.find<AppLockController>();

class AppLockController extends GetxController with WidgetsBindingObserver {
  final LocalAuthentication _localAuth = LocalAuthentication();

  final RxBool isLocked = false.obs;
  final RxBool isEnabled = false.obs;
  final RxBool biometricsEnabled = false.obs;
  final RxInt timeoutSeconds = 0.obs;
  final RxBool hideInRecentApps = true.obs;
  final RxBool showPrivacyShield = false.obs;
  final RxBool hapticsEnabled = true.obs;
  final Rx<AppLockType> lockType = AppLockType.pin4.obs;
  final RxBool allowEmergencyReset = true.obs;
  final RxString secretPinDigit = '0'.obs;
  final RxInt secretPatternDot = 4.obs;
  final Rx<PatternDotStyle> patternDotStyle = PatternDotStyle.circle.obs;
  final RxBool showPatternTrail = true.obs;

  final RxBool isBiometricsSupported = false.obs;
  final RxList<BiometricType> availableBiometrics = <BiometricType>[].obs;

  final RxInt failedAttempts = 0.obs;
  final RxInt cooldownSecondsRemaining = 0.obs;
  Timer? _cooldownTimer;

  DateTime? _lastBackgroundTime;
  bool _isAuthenticating = false;
  bool _isAppInBackground = false;
  Timer? _backgroundLockTimer;

  static const String _salt = 'anymex_security_salt_2026_x';

  static String hashPin(String pin) {
    final bytes = utf8.encode('$_salt$pin');
    return sha256.convert(bytes).toString();
  }

  bool get isAuthenticating => _isAuthenticating;

  String get biometricDisplayName {
    try {
      if (Platform.isIOS) {
        if (availableBiometrics.contains(BiometricType.face)) {
          return 'Face ID';
        } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
          return 'Touch ID';
        }
        return 'Face ID / Touch ID';
      } else if (Platform.isMacOS) {
        return 'Touch ID';
      } else if (Platform.isAndroid) {
        if (availableBiometrics.contains(BiometricType.face) &&
            !availableBiometrics.contains(BiometricType.fingerprint)) {
          return 'Face Unlock';
        }
        return 'Fingerprint / Face Unlock';
      }
    } catch (_) {}
    return 'Biometric Unlock';
  }

  IconData get biometricIcon {
    try {
      if (Platform.isIOS && availableBiometrics.contains(BiometricType.face)) {
        return Icons.face_rounded;
      }
    } catch (_) {}
    return Icons.fingerprint_rounded;
  }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
    checkBiometricSupport();
  }

  @override
  void onClose() {
    _cooldownTimer?.cancel();
    _backgroundLockTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  void _loadSettings() {
    try {
      isEnabled.value = AppLockKeys.isEnabled.get<bool>(false);
      biometricsEnabled.value = AppLockKeys.biometricsEnabled.get<bool>(false);
      timeoutSeconds.value = AppLockKeys.timeoutSeconds.get<int>(0);
      hideInRecentApps.value = AppLockKeys.hideInRecentApps.get<bool>(true);
      hapticsEnabled.value = AppLockKeys.hapticsEnabled.get<bool>(true);
      allowEmergencyReset.value = AppLockKeys.allowEmergencyReset.get<bool>(true);
      secretPinDigit.value = AppLockKeys.secretPinDigit.get<String>('0');
      secretPatternDot.value = AppLockKeys.secretPatternDot.get<int>(4);
      showPatternTrail.value = AppLockKeys.showPatternTrail.get<bool>(true);

      final styleIndex = AppLockKeys.patternDotStyle.get<int>(0);
      patternDotStyle.value = (styleIndex >= 0 && styleIndex < PatternDotStyle.values.length)
          ? PatternDotStyle.values[styleIndex]
          : PatternDotStyle.circle;

      final typeIndex = AppLockKeys.lockType.get<int>(0);
      lockType.value = (typeIndex >= 0 && typeIndex < AppLockType.values.length)
          ? AppLockType.values[typeIndex]
          : AppLockType.pin4;

      final timeout = timeoutSeconds.value;
      if (isEnabled.value) {
        if (timeout == -2) {
          isLocked.value = false;
        } else if (timeout == -1 || timeout == 0) {
          isLocked.value = true;
        } else if (timeout > 0) {
          final lastBg = AppLockKeys.lastBackgroundTimestamp.get<int>(0);
          if (lastBg > 0) {
            final elapsedSeconds =
                (DateTime.now().millisecondsSinceEpoch - lastBg) ~/ 1000;
            isLocked.value = elapsedSeconds >= timeout;
          } else {
            isLocked.value = true;
          }
        }
      }
    } catch (e) {
      Logger.e('Error loading app lock settings: $e');
    }
  }

  Future<void> checkBiometricSupport() async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      isBiometricsSupported.value = isSupported || canCheck;

      if (isBiometricsSupported.value) {
        final bios = await _localAuth.getAvailableBiometrics();
        availableBiometrics.assignAll(bios);
      }
    } catch (e) {
      Logger.d('Biometrics check error (normal on unsupported devices): $e');
      isBiometricsSupported.value = false;
    }
  }

  bool verifyPin(String pin) {
    final storedHash = AppLockKeys.pinHash.get<String>('');
    if (storedHash.isEmpty) return false;
    return hashPin(pin) == storedHash;
  }

  void enableAppLock(String pin) {
    final hash = hashPin(pin);
    AppLockKeys.pinHash.set(hash);
    AppLockKeys.isEnabled.set(true);
    isEnabled.value = true;
    isLocked.value = false;
  }

  void disableAppLock() {
    AppLockKeys.isEnabled.set(false);
    AppLockKeys.biometricsEnabled.set(false);
    AppLockKeys.pinHash.delete();
    AppLockKeys.lastBackgroundTimestamp.delete();
    _backgroundLockTimer?.cancel();
    _isAppInBackground = false;
    isEnabled.value = false;
    biometricsEnabled.value = false;
    isLocked.value = false;
    showPrivacyShield.value = false;
    _lastBackgroundTime = null;
  }

  void updatePin(String newPin) {
    final hash = hashPin(newPin);
    AppLockKeys.pinHash.set(hash);
  }

  void setBiometricsEnabled(bool enabled) {
    AppLockKeys.biometricsEnabled.set(enabled);
    biometricsEnabled.value = enabled;
  }

  void setTimeoutSeconds(int seconds) {
    _backgroundLockTimer?.cancel();
    AppLockKeys.timeoutSeconds.set(seconds);
    timeoutSeconds.value = seconds;
  }

  void setHideInRecentApps(bool hide) {
    AppLockKeys.hideInRecentApps.set(hide);
    hideInRecentApps.value = hide;
  }

  void setHapticsEnabled(bool enabled) {
    AppLockKeys.hapticsEnabled.set(enabled);
    hapticsEnabled.value = enabled;
  }

  void vibrateLight() {
    if (hapticsEnabled.value) {
      HapticFeedback.lightImpact();
    }
  }

  void vibrateMedium() {
    if (hapticsEnabled.value) {
      HapticFeedback.mediumImpact();
    }
  }

  void vibrateError() {
    if (hapticsEnabled.value) {
      HapticFeedback.vibrate();
    }
  }

  void setLockType(AppLockType type) {
    AppLockKeys.lockType.set(type.index);
    lockType.value = type;
  }

  void setAllowEmergencyReset(bool val) {
    AppLockKeys.allowEmergencyReset.set(val);
    allowEmergencyReset.value = val;
  }

  void setSecretPinDigit(String digit) {
    AppLockKeys.secretPinDigit.set(digit);
    secretPinDigit.value = digit;
  }

  void setSecretPatternDot(int dotIndex) {
    AppLockKeys.secretPatternDot.set(dotIndex);
    secretPatternDot.value = dotIndex;
  }

  void setPatternDotStyle(PatternDotStyle style) {
    AppLockKeys.patternDotStyle.set(style.index);
    patternDotStyle.value = style;
  }

  void setShowPatternTrail(bool show) {
    AppLockKeys.showPatternTrail.set(show);
    showPatternTrail.value = show;
  }

  void emergencyReset() {
    if (!allowEmergencyReset.value) return;
    disableAppLock();
  }

  void lockManually() {
    if (isEnabled.value) {
      isLocked.value = true;
    }
  }

  bool unlockWithPin(String pin) {
    if (cooldownSecondsRemaining.value > 0) {
      return false;
    }
    if (verifyPin(pin)) {
      failedAttempts.value = 0;
      cooldownSecondsRemaining.value = 0;
      _cooldownTimer?.cancel();
      _backgroundLockTimer?.cancel();
      _isAppInBackground = false;
      isLocked.value = false;
      showPrivacyShield.value = false;
      _lastBackgroundTime = null;
      AppLockKeys.lastBackgroundTimestamp.delete();
      vibrateMedium();
      return true;
    } else {
      failedAttempts.value++;
      if (failedAttempts.value >= 5) {
        _startCooldown(30);
        failedAttempts.value = 0;
      }
      vibrateError();
      return false;
    }
  }

  void _startCooldown(int seconds) {
    cooldownSecondsRemaining.value = seconds;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (cooldownSecondsRemaining.value > 1) {
        cooldownSecondsRemaining.value--;
      } else {
        cooldownSecondsRemaining.value = 0;
        timer.cancel();
      }
    });
  }

  Future<bool> authenticateBiometric({String reason = 'Authenticate to continue'}) async {
    if (!isBiometricsSupported.value) return false;
    if (_isAuthenticating) return false;

    try {
      _isAuthenticating = true;
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      return didAuthenticate;
    } catch (e) {
      Logger.d('Biometric authentication error: $e');
      return false;
    } finally {
      _isAuthenticating = false;
    }
  }

  Future<bool> unlockWithBiometrics() async {
    if (!isEnabled.value || !biometricsEnabled.value || !isBiometricsSupported.value) {
      return false;
    }
    if (cooldownSecondsRemaining.value > 0) return false;
    if (_isAuthenticating) return false;

    final success = await authenticateBiometric(
      reason: 'Authenticate to unlock AnymeX',
    );

    if (success) {
      failedAttempts.value = 0;
      cooldownSecondsRemaining.value = 0;
      _cooldownTimer?.cancel();
      _backgroundLockTimer?.cancel();
      _isAppInBackground = false;
      isLocked.value = false;
      showPrivacyShield.value = false;
      _lastBackgroundTime = null;
      AppLockKeys.lastBackgroundTimestamp.delete();
      HapticFeedback.mediumImpact();
      return true;
    }
    return false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!isEnabled.value) return;
    if (_isAuthenticating) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (!_isAppInBackground) {
        _isAppInBackground = true;
        final now = DateTime.now();
        _lastBackgroundTime = now;
        AppLockKeys.lastBackgroundTimestamp.set(now.millisecondsSinceEpoch);

        if (hideInRecentApps.value) {
          showPrivacyShield.value = true;
        }

        if (timeoutSeconds.value == 0) {
          isLocked.value = true;
        } else if (timeoutSeconds.value > 0 && !isLocked.value) {
          _backgroundLockTimer?.cancel();
          _backgroundLockTimer =
              Timer(Duration(seconds: timeoutSeconds.value), () {
            if (_isAppInBackground && timeoutSeconds.value > 0) {
              isLocked.value = true;
            }
          });
        }
      }
    } else if (state == AppLifecycleState.resumed) {
      _isAppInBackground = false;
      _backgroundLockTimer?.cancel();

      if (timeoutSeconds.value > 0 && !isLocked.value) {
        final lastBg = _lastBackgroundTime?.millisecondsSinceEpoch ??
            AppLockKeys.lastBackgroundTimestamp.get<int>(0);
        if (lastBg > 0) {
          final elapsedSeconds =
              (DateTime.now().millisecondsSinceEpoch - lastBg) ~/ 1000;
          if (elapsedSeconds >= timeoutSeconds.value) {
            isLocked.value = true;
          }
        }
      }

      showPrivacyShield.value = false;
    }
  }
}
