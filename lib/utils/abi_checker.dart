import 'dart:io';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';

class AppAbiDetector {
  static const MethodChannel _channel = MethodChannel('app/architecture');

  static Future<String> getCurrentAppAbi() async {
    if (!Platform.isAndroid) {
      return 'not_android';
    }

    try {
      final String? nativeAbi =
          await _channel.invokeMethod('getCurrentArchitecture');
      if (nativeAbi != null && nativeAbi != 'unknown') {
        return nativeAbi;
      }
    } catch (e) {
      print('Native ABI detection failed: $e');
    }

    try {
      final dartVersion = Platform.version;
      if (dartVersion.contains('arm64') || dartVersion.contains('aarch64')) {
        return 'arm64';
      } else if (dartVersion.contains('arm')) {
        return 'arm32';
      }
    } catch (e) {
      print('Dart version check failed: $e');
    }

    try {
      final result = await Process.run('getprop', ['ro.product.cpu.abi']);
      if (result.exitCode == 0) {
        final abi = result.stdout.toString().trim();
        if (abi.contains('arm64') || abi.contains('v8a')) {
          return 'arm64';
        } else if (abi.contains('arm') || abi.contains('v7a')) {
          return 'arm32';
        } else if (abi.contains('x86_64')) {
          return 'x86_64';
        } else if (abi.contains('x86')) {
          return 'x86';
        }
      }
    } catch (e) {
      print('System property check failed: $e');
    }

    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final supportedAbis = androidInfo.supportedAbis;

      if (supportedAbis.contains('arm64-v8a') &&
          androidInfo.version.sdkInt >= 21) {
        return 'arm64';
      } else if (supportedAbis.contains('armeabi-v7a')) {
        return 'arm32';
      } else if (supportedAbis.contains('x86_64')) {
        return 'x86_64';
      } else if (supportedAbis.contains('x86')) {
        return 'x86';
      }
    } catch (e) {
      print('Device info fallback failed: $e');
    }

    return 'unknown';
  }

  static String getArchitectureName(String abi) {
    switch (abi) {
      case 'arm64':
        return '64-bit ARM (ARM64)';
      case 'arm32':
        return '32-bit ARM (ARM32)';
      case 'x86_64':
        return '64-bit Intel (x86_64)';
      case 'x86':
        return '32-bit Intel (x86)';
      case 'not_android':
        return 'Not Android Platform';
      case 'unknown':
      default:
        return 'Unknown Architecture';
    }
  }

  static bool is64Bit(String abi) {
    return abi == 'arm64' || abi == 'x86_64';
  }
}
