import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class VolumeKeyHandler {
  static const MethodChannel _channel = MethodChannel('com.ryan.anymex/volume');
  static const EventChannel _eventChannel =
      EventChannel('com.ryan.anymex/volume_events');

  Stream<String>? _stream;

  Future<void> enableInterception() async {
    try {
      if (defaultTargetPlatform != TargetPlatform.android) return;
      await _channel.invokeMethod('enable');
    } catch (e) {
      debugPrint('Failed to enable volume key interception: $e');
    }
  }

  Future<void> disableInterception() async {
    try {
      if (defaultTargetPlatform != TargetPlatform.android) return;
      await _channel.invokeMethod('disable');
    } catch (e) {
      debugPrint('Failed to disable volume key interception: $e');
    }
  }

  Stream<String> get volumeEvents {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return const Stream.empty();
    }
    _stream ??=
        _eventChannel.receiveBroadcastStream().map((event) => event.toString());
    return _stream!;
  }
}
