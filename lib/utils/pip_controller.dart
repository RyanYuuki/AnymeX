import 'dart:io';
import 'package:flutter/services.dart';

class PipController {
  static const _channel = MethodChannel('com.ryan.anymex/pip');

  static void Function()? onPlay;
  static void Function()? onPause;
  static void Function()? onForward;
  static void Function()? onBackward;
  static void Function(bool)? onPipModeChanged;

  static void initialize() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onPipPlay':
          onPlay?.call();
          break;
        case 'onPipPause':
          onPause?.call();
          break;
        case 'onPipForward':
          onForward?.call();
          break;
        case 'onPipBackward':
          onBackward?.call();
          break;
        case 'onPipModeChanged':
          final active = call.arguments as bool? ?? false;
          onPipModeChanged?.call(active);
          break;
      }
    });
  }

  static Future<void> updatePlaybackState(bool playing) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('updatePlaybackState', {'playing': playing});
    } catch (_) {}
  }

  static Future<bool> get isAvailable async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    try {
      return await _channel.invokeMethod<bool>('isPipAvailable') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> get isActive async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    try {
      return await _channel.invokeMethod<bool>('isPipActive') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> enter(
      {int aspectWidth = 16, int aspectHeight = 9}) async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    try {
      return await _channel.invokeMethod<bool>('enterPip', {
            'width': aspectWidth,
            'height': aspectHeight,
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setAutoEnter({required bool enabled}) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('setAutoEnter', {'enabled': enabled});
    } catch (_) {}
  }
}
