import 'dart:async';
import 'dart:convert';

import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/watchium/watchium_models.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

class WatchiumService extends GetxController {
  static const _defaultServerUrl = 'https://anymex.duckdns.org:3001';

  IO.Socket? _socket;
  String? _token;
  String? _userId;
  String? _currentRoomCode;
  bool _isHost = false;
  Timer? _heartbeatTimer;
  String? _lastClientId;

  // Reactive state
  final Rx<WatchiumRoomState?> roomState = Rx(null);
  final RxList<WatchiumChatMessage> chatMessages = RxList();
  final RxList<WatchiumReaction> reactions = RxList();
  final RxBool isConnected = false.obs;
  final RxBool isConnecting = false.obs;
  final RxString error = ''.obs;
  final RxBool isHost = false.obs;
  final RxString roomCode = ''.obs;

  String get serverUrl =>
      WatchiumKeys.serverUrl.get<String>(_defaultServerUrl);

  final RxBool inRoom = false.obs;

  void _updateInRoom() {
    inRoom.value = _currentRoomCode != null && _socket?.connected == true;
  }

  // ---- Auth ----

  Future<bool> login() async {
    try {
      final serviceHandler = Get.find<ServiceHandler>();
      final profile = serviceHandler.profileData.value;
      final activeService = serviceHandler.activeOrLoggedInOnlineService;

      if (activeService == null || !activeService.isLoggedIn.value) {
        error.value = 'You must be logged in to use Watch Together';
        return false;
      }

      String provider = 'anilist';
      String providerUserId = profile.id ?? '';
      String username = profile.name ?? 'Unknown';
      String? avatarUrl = profile.avatar;

      if (serviceHandler.serviceType.value == ServicesType.anilist) {
        provider = 'anilist';
      } else if (serviceHandler.serviceType.value == ServicesType.mal) {
        provider = 'mal';
      } else if (serviceHandler.serviceType.value == ServicesType.simkl) {
        provider = 'simkl';
      }

      final response = await http.post(
        Uri.parse('$serverUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'provider': provider,
          'providerUserId': providerUserId,
          'username': username,
          'avatarUrl': avatarUrl,
        }),
      );

      if (response.statusCode != 200) {
        error.value = 'Login failed: ${response.statusCode}';
        return false;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _token = data['token'] as String;
      _userId = (data['user'] as Map<String, dynamic>)['id'] as String;
      error.value = '';
      return true;
    } catch (e) {
      error.value = 'Login failed: $e';
      return false;
    }
  }

  // ---- Socket Connection ----

  void _connectSocket() {
    if (_socket?.connected == true) return;

    isConnecting.value = true;

    _socket = IO.io(
      '$serverUrl/watch',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': _token})
          .build(),
    );

    _socket!.on('connect', (_) {
      isConnected.value = true;
      isConnecting.value = false;
      error.value = '';
      _updateInRoom();
    });

    _socket!.on('disconnect', (_) {
      isConnected.value = false;
      _stopHeartbeat();
      _updateInRoom();
    });

    _socket!.on('connect_error', (err) {
      isConnected.value = false;
      isConnecting.value = false;
      error.value = 'Connection failed';
      _updateInRoom();
    });

    _socket!.on('party:state', (data) {
      final state = WatchiumRoomState.fromJson(data as Map<String, dynamic>);
      roomState.value = state;
      _isHost = state.hostUserId == _userId;
      isHost.value = _isHost;
    });

    _socket!.on('party:sync', (data) {
      final playback = data as Map<String, dynamic>;
      final pb = playback['playback'] as Map<String, dynamic>;
      final current = roomState.value;
      if (current == null) return;
      roomState.value = WatchiumRoomState(
        code: current.code,
        hostUserId: current.hostUserId,
        members: current.members,
        content: current.content,
        playback: WatchiumPlayback.fromJson(pb),
        onlyHostControls: current.onlyHostControls,
        maxMembers: current.maxMembers,
      );
    });

    _socket!.on('party:content', (data) {
      final contentData = data as Map<String, dynamic>;
      final content = WatchiumAnimeContent.fromJson(
          contentData['content'] as Map<String, dynamic>);
      final playback = WatchiumPlayback.fromJson(
          contentData['playback'] as Map<String, dynamic>);
      final current = roomState.value;
      if (current == null) return;
      roomState.value = WatchiumRoomState(
        code: current.code,
        hostUserId: current.hostUserId,
        members: current.members,
        content: content,
        playback: playback,
        onlyHostControls: current.onlyHostControls,
        maxMembers: current.maxMembers,
      );
    });

    _socket!.on('party:member', (data) {
      final memberData = data as Map<String, dynamic>;
      final current = roomState.value;
      if (current == null) return;
      final members = (memberData['members'] as List)
          .map((e) => WatchiumMember.fromJson(e as Map<String, dynamic>))
          .toList();
      roomState.value = WatchiumRoomState(
        code: current.code,
        hostUserId: memberData['hostUserId'] as String? ??
            current.hostUserId,
        members: members,
        content: current.content,
        playback: current.playback,
        onlyHostControls: current.onlyHostControls,
        maxMembers: current.maxMembers,
      );
    });

    _socket!.on('party:chat', (data) {
      final msg = WatchiumChatMessage.fromJson(data as Map<String, dynamic>);
      if (msg.clientId != _lastClientId) {
        chatMessages.add(msg);
        if (chatMessages.length > 100) chatMessages.removeAt(0);
      }
    });

    _socket!.on('party:reaction', (data) {
      final r = WatchiumReaction.fromJson(data as Map<String, dynamic>);
      reactions.add(r);
      if (reactions.length > 50) reactions.removeAt(0);
      Future.delayed(const Duration(seconds: 3), () {
        reactions.remove(r);
      });
    });

    _socket!.on('party:error', (data) {
      final errData = data as Map<String, dynamic>;
      error.value = errData['message'] as String? ?? 'Unknown error';
    });

    _socket!.on('party:closed', (data) {
      final reason = (data as Map<String, dynamic>)['reason'] as String? ??
          'closed';
      _leaveRoomInternal();
      error.value = 'Room $reason';
    });

    _socket!.connect();
  }

  // ---- Room Actions ----

  Future<String?> createRoom({
    required String animeTitle,
    required int episodeNumber,
    int? anilistId,
    int? malId,
    int? simklId,
    String? animeCoverImage,
    int? seasonNumber,
    int? totalEpisodes,
    List<WatchiumAnimeServer>? availableServers,
  }) async {
    try {
      final ok = await login();
      if (!ok) return null;

      final response = await http.post(
        Uri.parse('$serverUrl/api/watch-party'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'animeTitle': animeTitle,
          'episodeNumber': episodeNumber,
          'anilistId': anilistId,
          'malId': malId,
          'simklId': simklId,
          'animeCoverImage': animeCoverImage,
          'seasonNumber': seasonNumber,
          'totalEpisodes': totalEpisodes,
          'availableServers':
              availableServers?.map((e) => e.toJson()).toList() ?? [],
        }),
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        error.value = 'Failed to create room';
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final code = data['code'] as String;
      roomCode.value = code;
      _connectSocket();

      // Wait for socket connect, then join
      await Future.delayed(const Duration(seconds: 1));
      _socket?.emitWithAck('party:join', {'code': code});
      _currentRoomCode = code;
      _updateInRoom();
      return code;
    } catch (e) {
      error.value = 'Failed to create room: $e';
      return null;
    }
  }

  Future<bool> joinRoom(String code) async {
    try {
      final ok = await login();
      if (!ok) return false;

      roomCode.value = code;
      _connectSocket();

      await Future.delayed(const Duration(seconds: 1));
      _socket?.emitWithAck('party:join', {'code': code});
      _currentRoomCode = code;
      _updateInRoom();
      return true;
    } catch (e) {
      error.value = 'Failed to join room: $e';
      return false;
    }
  }

  void leaveRoom() {
    if (_currentRoomCode == null) return;
    _socket?.emit('party:leave', {'code': _currentRoomCode});
    _leaveRoomInternal();
  }

  void _leaveRoomInternal() {
    _stopHeartbeat();
    _currentRoomCode = null;
    _isHost = false;
    isHost.value = false;
    inRoom.value = false;
    roomState.value = null;
    chatMessages.clear();
    reactions.clear();
  }

  void disconnect() {
    leaveRoom();
    _socket?.dispose();
    _socket = null;
    isConnected.value = false;
    inRoom.value = false;
    _token = null;
    _userId = null;
  }

  // ---- Playback Sync (Host) ----

  void sendControl(String action, {double? positionSec, double? rate}) {
    if (_currentRoomCode == null || !_isHost) return;
    _socket?.emit('party:control', {
      'code': _currentRoomCode,
      'action': action,
      if (positionSec != null) 'positionSec': positionSec,
      if (rate != null) 'rate': rate,
    });
  }

  void sendPlay() => sendControl('play');
  void sendPause() => sendControl('pause');
  void sendSeek(double positionSec) =>
      sendControl('seek', positionSec: positionSec);
  void sendRate(double rate) => sendControl('rate', rate: rate);

  void startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_currentRoomCode == null || !_isHost) return;
      _socket?.emit('party:heartbeat', {
        'code': _currentRoomCode,
      });
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  // ---- Content (Host sets anime) ----

  void setContent(WatchiumAnimeContent content) {
    if (_currentRoomCode == null || !_isHost) return;
    _socket?.emit('party:content', {
      'code': _currentRoomCode,
      'content': content.toJson(),
    });
  }

  // ---- Server Selection ----

  void selectServer(String serverId) {
    if (_currentRoomCode == null) return;
    _socket?.emit('party:server-select', {
      'code': _currentRoomCode,
      'serverId': serverId,
    });
  }

  // ---- Chat ----

  void sendChat(String text) {
    if (_currentRoomCode == null) return;
    _lastClientId = DateTime.now().millisecondsSinceEpoch.toString();
    _socket?.emit('party:chat', {
      'code': _currentRoomCode,
      'text': text,
      'clientId': _lastClientId,
    });
  }

  // ---- Reactions ----

  void sendReaction(String emoji) {
    if (_currentRoomCode == null) return;
    _lastClientId = DateTime.now().millisecondsSinceEpoch.toString();
    _socket?.emit('party:reaction', {
      'code': _currentRoomCode,
      'emoji': emoji,
      'clientId': _lastClientId,
    });
  }

  // ---- List Rooms ----

  final RxList<WatchiumRoomState> publicRooms = RxList();
  final RxBool isLoadingRooms = false.obs;

  Future<List<WatchiumRoomState>> listRooms() async {
    try {
      final ok = await login();
      if (!ok) return [];

      final response = await http.get(
        Uri.parse('$serverUrl/api/watch-party'),
        headers: {
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final rooms = (data['rooms'] as List)
          .map((e) => WatchiumRoomState.fromJson(e as Map<String, dynamic>))
          .toList();
      publicRooms.assignAll(rooms);
      return rooms;
    } catch (e) {
      error.value = 'Failed to list rooms: $e';
      return [];
    }
  }

  // ---- Get Room Info (for deep link join) ----

  Future<WatchiumRoomState?> getRoomInfo(String code) async {
    try {
      final ok = await login();
      if (!ok) return null;

      final response = await http.get(
        Uri.parse('$serverUrl/api/watch-party/$code'),
        headers: {
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return WatchiumRoomState.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  // ---- Deep Link Join ----

  Future<bool> handleDeepLinkJoin(String code) async {
    final ok = await joinRoom(code);
    if (!ok) return false;
    return true;
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}
