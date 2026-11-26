import 'dart:async';
import 'dart:io';
import 'package:anymex/utils/logger.dart';
import 'package:anymex_extension_runtime_bridge/AnymeXBridge.dart';
import 'package:anymex_extension_runtime_bridge/ExtensionManager.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:anymex/utils/app_directories.dart';

class CrashDetector {
  static const MethodChannel _channel =
      MethodChannel('com.ryan.anymex/crash_detector');

  static final RxBool isBridgeBlocked = false.obs;

  static Future<void> markBridgeLoadStart() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('markBridgeLoadStart');
    } catch (_) {}
  }

  static Future<void> markBridgeLoadComplete() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('markBridgeLoadComplete');
    } catch (_) {}
  }

  static Future<bool> checkBridgeBlocked() async {
    if (!Platform.isAndroid) return false;
    try {
      final blocked = await _channel.invokeMethod<bool>('isBridgeBlocked') ?? false;
      isBridgeBlocked.value = blocked;
      return blocked;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setBridgeBlocked(bool blocked) async {
    if (!Platform.isAndroid) return;
    isBridgeBlocked.value = blocked;
    try {
      await _channel.invokeMethod('setBridgeBlocked', {'blocked': blocked});
    } catch (_) {}
  }

  static Future<Map<String, dynamic>?> consumeCrashReport() async {
    if (!Platform.isAndroid) return null;
    try {
      final result =
          await _channel.invokeMapMethod<String, dynamic>('consumeCrashReport');
      if (result != null && result['bridgeBlocked'] == true) {
        isBridgeBlocked.value = true;
      }
      return result;
    } catch (_) {
      return null;
    }
  }

  static Future<File> _defaultRuntimeApkFile() async {
    final docsDir = await getAppDocumentsDirectory();
    return File(p.join(docsDir.path, 'AnymeX', 'Runtime', 'anymex_runtime_host.apk'));
  }

  static Future<File> _quarantinedRuntimeApkFile() async {
    final docsDir = await getAppDocumentsDirectory();
    return File(p.join(
        docsDir.path, 'AnymeX', 'Runtime', 'anymex_runtime_host.apk.quarantined'));
  }

  static Future<void> quarantineRuntimeHostApkIfBlocked() async {
    if (!Platform.isAndroid) return;
    try {
      final apkFile = await _defaultRuntimeApkFile();
      final quarantinedFile = await _quarantinedRuntimeApkFile();
      if (await apkFile.exists()) {
        if (await quarantinedFile.exists()) {
          await quarantinedFile.delete();
        }
        await apkFile.rename(quarantinedFile.path);
      }
    } catch (e) {
      Logger.e('Failed to quarantine runtime host APK: $e',
          loggerName: 'BRIDGE_GUARD');
    }
  }

  static Future<void> restoreRuntimeHostApk() async {
    if (!Platform.isAndroid) return;
    try {
      final apkFile = await _defaultRuntimeApkFile();
      final quarantinedFile = await _quarantinedRuntimeApkFile();
      if (await quarantinedFile.exists()) {
        if (await apkFile.exists()) {
          await apkFile.delete();
        }
        await quarantinedFile.rename(apkFile.path);
      }
    } catch (e) {
      Logger.e('Failed to restore runtime host APK: $e',
          loggerName: 'BRIDGE_GUARD');
    }
  }

  static Future<void> restoreAndRetryRuntimeHost() async {
    if (!Platform.isAndroid) return;
    await setBridgeBlocked(false);
    await restoreRuntimeHostApk();
    await markBridgeLoadStart();
    Logger.i('Retrying Runtime Host initialization...', 'BRIDGE_GUARD');
    await Logger.flush();
    try {
      await AnymeXRuntimeBridge.checkAndInitialize();
      if (Get.isRegistered<ExtensionManager>()) {
        await Get.find<ExtensionManager>()
            .onRuntimeBridgeInitialization(force: true);
      }
    } finally {
      await markBridgeLoadComplete();
    }
  }
}
