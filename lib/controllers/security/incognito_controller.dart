import 'dart:async';
import 'package:anymex/controllers/discord/discord_rpc.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

IncognitoController get incognitoController => Get.find<IncognitoController>();

class IncognitoController extends GetxController with WidgetsBindingObserver {
  // Observables for settings
  final RxBool isIncognito = false.obs;
  final RxBool pauseOnlineTracking = true.obs;
  final RxBool pauseLocalHistory = true.obs;
  final RxBool pauseSearchHistory = true.obs;
  final RxBool hideHomeRecent = true.obs;
  final RxBool pauseDiscordRpc = true.obs;
  final RxBool autoExitOnClose = true.obs;

  // In-Memory volatile session cache (completely wiped when exiting or app restart)
  final Map<String, dynamic> _sessionMemory = <String, dynamic>{};

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _loadPreferences();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    clearSession();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      if (autoExitOnClose.value) {
        isIncognito.value = false;
        IncognitoKeys.isIncognito.set(false);
      }
      clearSession();
    }
  }

  void _loadPreferences() {
    pauseOnlineTracking.value =
        IncognitoKeys.pauseOnlineTracking.get<bool>(true);
    pauseLocalHistory.value =
        IncognitoKeys.pauseLocalHistory.get<bool>(true);
    pauseSearchHistory.value =
        IncognitoKeys.pauseSearchHistory.get<bool>(true);
    hideHomeRecent.value =
        IncognitoKeys.hideHomeRecent.get<bool>(true);
    pauseDiscordRpc.value =
        IncognitoKeys.pauseDiscordRpc.get<bool>(true);
    autoExitOnClose.value =
        IncognitoKeys.autoExitOnClose.get<bool>(true);

    final savedActive = IncognitoKeys.isIncognito.get<bool>(false);
    if (autoExitOnClose.value) {
      isIncognito.value = false;
      IncognitoKeys.isIncognito.set(false);
    } else {
      isIncognito.value = savedActive;
    }
  }

  // Toggles
  void toggleIncognito({bool? value, bool showToast = true}) {
    final nextState = value ?? !isIncognito.value;
    isIncognito.value = nextState;
    IncognitoKeys.isIncognito.set(nextState);

    if (nextState) {
      if (showToast) {
        snackBar('Incognito Mode activated (Private Browsing)',
            duration: 1500);
      }
      _onIncognitoActivated();
    } else {
      clearSession();
      if (showToast) {
        snackBar('Incognito Mode deactivated. Session cleared.',
            duration: 1500);
      }
    }
  }

  void _onIncognitoActivated() {
    if (pauseDiscordRpc.value) {
      try {
        if (Get.isRegistered<DiscordRPCController>()) {
          Get.find<DiscordRPCController>().clearPresence();
        }
      } catch (e) {
        Logger.e('Error clearing Discord RPC on incognito: $e');
      }
    }
  }

  void setPauseOnlineTracking(bool val) {
    pauseOnlineTracking.value = val;
    IncognitoKeys.pauseOnlineTracking.set(val);
  }

  void setPauseLocalHistory(bool val) {
    pauseLocalHistory.value = val;
    IncognitoKeys.pauseLocalHistory.set(val);
  }

  void setPauseSearchHistory(bool val) {
    pauseSearchHistory.value = val;
    IncognitoKeys.pauseSearchHistory.set(val);
  }

  void setHideHomeRecent(bool val) {
    hideHomeRecent.value = val;
    IncognitoKeys.hideHomeRecent.set(val);
  }

  void setPauseDiscordRpc(bool val) {
    pauseDiscordRpc.value = val;
    IncognitoKeys.pauseDiscordRpc.set(val);
    if (isIncognito.value && val) {
      _onIncognitoActivated();
    }
  }

  void setAutoExitOnClose(bool val) {
    autoExitOnClose.value = val;
    IncognitoKeys.autoExitOnClose.set(val);
  }

  void clearSession({bool showToast = false}) {
    _sessionMemory.clear();
    if (showToast) {
      snackBar('Incognito session memory wiped completely', duration: 1500);
    }
  }

  // Temporary Session Storage Methods
  void saveSessionData(String key, dynamic value) {
    _sessionMemory[key] = value;
  }

  dynamic getSessionData(String key) {
    return _sessionMemory[key];
  }

  bool hasSessionData(String key) {
    return _sessionMemory.containsKey(key);
  }

  // Convenience getters
  bool get shouldRecordHistory => !(isIncognito.value && pauseLocalHistory.value);
  bool get shouldSyncTrackers => !(isIncognito.value && pauseOnlineTracking.value);
  bool get shouldSaveSearch => !(isIncognito.value && pauseSearchHistory.value);
  bool get shouldBroadcastDiscord => !(isIncognito.value && pauseDiscordRpc.value);
  bool get shouldHideHomeRecent => isIncognito.value && hideHomeRecent.value;
}
