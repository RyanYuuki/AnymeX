import 'dart:async';
import 'dart:convert';
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

  final RxBool isBiometricsSupported = false.obs;
  final RxList<BiometricType> availableBiometrics = <BiometricType>[].obs;

  final RxInt failedAttempts = 0.obs;
  final RxInt cooldownSecondsRemaining = 0.obs;
  Timer? _cooldownTimer;

  DateTime? _lastBackgroundTime;
  bool _isAuthenticating = false;

  static const String _salt = 'anymex_security_salt_2026_x';

  static String hashPin(String pin) {
    final bytes = utf8.encode('$_salt$pin');
    return sha256.convert(bytes).toString();
  }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
    _checkBiometricSupport();
  }

  @override
  void onClose() {
    _cooldownTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  void _loadSettings() {
    try {
      isEnabled.value = AppLockKeys.isEnabled.get<bool>(false);
      biometricsEnabled.value = AppLockKeys.biometricsEnabled.get<bool>(false);
      timeoutSeconds.value = AppLockKeys.timeoutSeconds.get<int>(0);
      hideInRecentApps.value = AppLockKeys.hideInRecentApps.get<bool>(true);

      if (isEnabled.value && timeoutSeconds.value != -2) {
        isLocked.value = true;
      }
    } catch (e) {
      Logger.e('Error loading app lock settings: $e');
    }
  }

  Future<void> _checkBiometricSupport() async {
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
    isEnabled.value = false;
    biometricsEnabled.value = false;
    isLocked.value = false;
    showPrivacyShield.value = false;
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
    AppLockKeys.timeoutSeconds.set(seconds);
    timeoutSeconds.value = seconds;
  }

  void setHideInRecentApps(bool hide) {
    AppLockKeys.hideInRecentApps.set(hide);
    hideInRecentApps.value = hide;
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
      isLocked.value = false;
      showPrivacyShield.value = false;
      HapticFeedback.mediumImpact();
      return true;
    } else {
      failedAttempts.value++;
      if (failedAttempts.value >= 5) {
        _startCooldown(30);
        failedAttempts.value = 0;
      }
      HapticFeedback.vibrate();
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

  Future<bool> unlockWithBiometrics() async {
    if (!isEnabled.value || !biometricsEnabled.value || !isBiometricsSupported.value) {
      return false;
    }
    if (cooldownSecondsRemaining.value > 0) return false;
    if (_isAuthenticating) return false;

    try {
      _isAuthenticating = true;
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Authenticate to unlock AnymeX',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );

      if (didAuthenticate) {
        failedAttempts.value = 0;
        cooldownSecondsRemaining.value = 0;
        _cooldownTimer?.cancel();
        isLocked.value = false;
        showPrivacyShield.value = false;
        HapticFeedback.mediumImpact();
        return true;
      }
      return false;
    } catch (e) {
      Logger.d('Biometric authentication failed: $e');
      return false;
    } finally {
      _isAuthenticating = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!isEnabled.value) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _lastBackgroundTime = DateTime.now();

      if (hideInRecentApps.value) {
        showPrivacyShield.value = true;
      }

      if (timeoutSeconds.value == 0) {
        isLocked.value = true;
      }
    } else if (state == AppLifecycleState.resumed) {
      showPrivacyShield.value = false;

      if (timeoutSeconds.value >= 0 && !isLocked.value && _lastBackgroundTime != null) {
        final elapsedSeconds =
            DateTime.now().difference(_lastBackgroundTime!).inSeconds;
        if (elapsedSeconds >= timeoutSeconds.value) {
          isLocked.value = true;
        }
      }

      if (isLocked.value &&
          biometricsEnabled.value &&
          isBiometricsSupported.value &&
          cooldownSecondsRemaining.value == 0) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (isLocked.value && !_isAuthenticating && cooldownSecondsRemaining.value == 0) {
            unlockWithBiometrics();
          }
        });
      }
    }
  }
}
