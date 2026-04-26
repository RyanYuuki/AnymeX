import 'dart:async';
import 'dart:convert';

import 'package:anymex/controllers/services/cloud/cloud_auth_service.dart';
import 'package:anymex/controllers/profile/profile_manager.dart';
import 'package:anymex/controllers/services/cloud/cloud_sync_service.dart';
import 'package:anymex/utils/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class CloudRealtimeService extends GetxController {
  CloudAuthService get _auth => Get.find<CloudAuthService>();

  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  String? _subscribedProfileId;

  RxBool isConnected = false.obs;
  RxString lastEvent = ''.obs;

  /// Connect and subscribe to realtime for a given cloud profile ID.
  /// Only one profile subscription active at a time.
  Future<void> subscribe(String cloudProfileId) async {
    if (cloudProfileId == _subscribedProfileId) return;

    _unsubscribe();
    _subscribedProfileId = cloudProfileId;

    await _connect();
  }

  /// Unsubscribe and disconnect.
  void unsubscribe() {
    _unsubscribe();
  }

  Future<void> _connect() async {
    if (!_auth.isCloudMode || _subscribedProfileId == null) return;

    try {
      final supabaseUrl = dotenv.env['CLOUD_BASE_URL']?.trim() ?? '';
      if (supabaseUrl.isEmpty) return;

      final anonKey = dotenv.env['SUPABASE_ANON_KEY']?.trim() ?? '';

      // Build realtime WS URL from Supabase project URL
      // supabaseUrl = https://xxxxx.supabase.co -> wss://xxxxx.supabase.co/realtime/v1/websocket
      final wsBase = supabaseUrl
          .replaceFirst('https://', 'wss://')
          .replaceFirst('http://', 'ws://');
      final uri = Uri.parse(
        '$wsBase/realtime/v1/websocket?apikey=$anonKey&vsn=1.0.0'
      );

      _channel = WebSocketChannel.connect(uri);

      isConnected.value = true;
      Logger.i('Cloud realtime: connected');

      // Listen for messages
      _channel!.stream.listen(
        _onMessage,
        onDone: _onDisconnected,
        onError: _onError,
      );

      // Send phoenix join
      _send({
        'topic': 'realtime',
        'event': 'phx_join',
        'payload': {},
        'ref': null,
      });

      // Subscribe to profile_sync_meta changes (ping for data changes)
      await Future.delayed(const Duration(milliseconds: 300));
      _send({
        'topic': 'profile_sync:$_subscribedProfileId',
        'event': 'phx_join',
        'payload': {
          'config': {
            'broadcast': {'self': false},
            'presence': {'key': ''},
            'postgres_changes': {
              'schema': 'public',
              'table': 'profile_sync_meta',
              'filter': 'profile_id=eq.$_subscribedProfileId',
            }
          }
        },
        'ref': null,
      });

      // Subscribe to profile changes
      _send({
        'topic': 'profile:$_subscribedProfileId',
        'event': 'phx_join',
        'payload': {
          'config': {
            'broadcast': {'self': false},
            'presence': {'key': ''},
            'postgres_changes': {
              'schema': 'public',
              'table': 'app_profiles',
              'filter': 'id=eq.$_subscribedProfileId',
            }
          }
        },
        'ref': null,
      });

      // Start heartbeat
      _startPing();
    } catch (e) {
      Logger.i('Cloud realtime connect error: $e');
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String);

      // Phoenix acknowledgement — ignore
      if (data['event'] == 'phx_reply') return;

      // Check for postgres_changes payload
      if (data['event'] == 'postgres_changes') {
        final payload = data['payload'] as Map<String, dynamic>?;
        if (payload == null) return;

        final table = payload['table'] as String? ?? '';
        final new_ = payload['new'] as Map<String, dynamic>?;
        final eventType = payload['type'] as String? ?? '';

        if (table == 'profile_sync_meta' && new_ != null) {
          final dataType = new_['data_type'] as String? ?? 'unknown';
          final version = new_['version'] as int? ?? 0;
          lastEvent.value = 'Sync: $dataType v$version';
          Logger.i('Cloud realtime ping: $dataType v$version');

          // Trigger a pull — debounce to avoid flooding
          _triggerPull();
        }

        if (table == 'app_profiles') {
          lastEvent.value = 'Profile updated';
          Logger.i('Cloud realtime: profile data changed');
          _triggerPull();
        }
      }
    } catch (_) {
      // Ignore malformed messages
    }
  }

  void _triggerPull() {
    try {
      if (!Get.isRegistered<CloudSyncService>()) return;
      if (!_auth.isCloudMode) return;

      final sync = Get.find<CloudSyncService>();
      final manager = Get.find<ProfileManager>();
      final profileId = manager.currentProfileId.value;
      if (profileId.isNotEmpty) {
        sync.pullAllForProfile(profileId);
      }
    } catch (e) {
      Logger.i('Cloud realtime trigger pull error: $e');
    }
  }

  void _onDisconnected() {
    isConnected.value = false;
    Logger.i('Cloud realtime: disconnected');
    _scheduleReconnect();
  }

  void _onError(error) {
    isConnected.value = false;
    Logger.i('Cloud realtime error: $error');
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 10), () {
      Logger.i('Cloud realtime: attempting reconnect...');
      _connect();
    });
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _send({'topic': 'phoenix', 'event': 'heartbeat', 'payload': {}, 'ref': null});
    });
  }

  void _send(Map<String, dynamic> message) {
    try {
      _channel?.sink.add(jsonEncode(message));
    } catch (e) {
      Logger.i('Cloud realtime send error: $e');
    }
  }

  void _unsubscribe() {
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    try {
      if (_channel != null) {
        _send({'topic': 'realtime', 'event': 'phx_leave', 'payload': {}, 'ref': null});
        _channel?.sink.close();
        _channel = null;
      }
    } catch (_) {}
    _subscribedProfileId = null;
    isConnected.value = false;
  }

  @override
  void onClose() {
    _unsubscribe();
    super.onClose();
  }
}
