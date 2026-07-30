import 'dart:async';
import 'dart:convert';

import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/watchium/watchium_models.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/utils/logger.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

class WatchiumService extends GetxController {
  static const _defaultServerUrl = 'http://anymex.duckdns.org:3001';

  IO.Socket? _socket;
  String? _token;
  String? _userId;
  String? _currentRoomCode;
  bool _isHost = false;
  Timer? _heartbeatTimer; // kept for backwards compatibility; sync controller manages its own timer
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
        Logger.w('Login failed: user not logged in', 'WATCHIUM');
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

      Logger.i('Logging in with provider=$provider, userId=$providerUserId, username=$username', 'WATCHIUM');

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
        Logger.w('Login failed: HTTP ${response.statusCode}', 'WATCHIUM');
        return false;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _token = data['token'] as String;
      _userId = (data['user'] as Map<String, dynamic>)['id'] as String;
      error.value = '';
      Logger.i('Login successful, userId=$_userId', 'WATCHIUM');
      return true;
    } catch (e) {
      error.value = 'Login failed: $e';
      Logger.e('Login failed with exception', error: e, loggerName: 'WATCHIUM');
      return false;
    }
  }

  // ---- Socket Connection ----

  void _connectSocket() {
    if (_socket?.connected == true) {
      Logger.d('Socket already connected, skipping', 'WATCHIUM');
      return;
    }

    isConnecting.value = true;
    Logger.i('Connecting socket to $serverUrl/watch', 'WATCHIUM');

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
      Logger.i('Socket connected (id=${_socket?.id})', 'WATCHIUM');
    });

    _socket!.on('disconnect', (_) {
      isConnected.value = false;
      _stopHeartbeat();
      _updateInRoom();
      Logger.w('Socket disconnected', 'WATCHIUM');
    });

    _socket!.on('connect_error', (err) {
      isConnected.value = false;
      isConnecting.value = false;
      error.value = 'Connection failed';
      _updateInRoom();
      Logger.e('Socket connect error', error: err, loggerName: 'WATCHIUM');
    });

    _socket!.on('party:state', (data) {
      final state = WatchiumRoomState.fromJson(data as Map<String, dynamic>);
      roomState.value = state;
      _isHost = state.hostUserId == _userId;
      isHost.value = _isHost;
      Logger.d('party:state received, host=${state.hostUserId}, members=${state.members.length}, code=${state.code}', 'WATCHIUM');
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
      Logger.d('party:sync received, positionSec=${pb['positionSec']}, isPlaying=${pb['isPlaying']}', 'WATCHIUM');
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
      Logger.d('party:content received, anime=${content.animeTitle}, episode=${content.episodeNumber}', 'WATCHIUM');
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
      Logger.d('party:member received, ${members.length} members', 'WATCHIUM');
    });

    _socket!.on('party:chat', (data) {
      final msg = WatchiumChatMessage.fromJson(data as Map<String, dynamic>);
      if (msg.clientId != _lastClientId) {
        chatMessages.add(msg);
        if (chatMessages.length > 100) chatMessages.removeAt(0);
        Logger.d('party:chat from ${msg.username}: "${msg.text}"', 'WATCHIUM');
      }
    });

    _socket!.on('party:reaction', (data) {
      final r = WatchiumReaction.fromJson(data as Map<String, dynamic>);
      reactions.add(r);
      if (reactions.length > 50) reactions.removeAt(0);
      Future.delayed(const Duration(seconds: 3), () {
        reactions.remove(r);
      });
      Logger.d('party:reaction from ${r.username}: ${r.emoji}', 'WATCHIUM');
    });

    _socket!.on('party:error', (data) {
      final errData = data as Map<String, dynamic>;
      error.value = errData['message'] as String? ?? 'Unknown error';
      Logger.w('party:error received: ${error.value}', 'WATCHIUM');
    });

    _socket!.on('party:closed', (data) {
      final reason = (data as Map<String, dynamic>)['reason'] as String? ??
          'closed';
      _leaveRoomInternal();
      error.value = 'Room $reason';
      Logger.w('party:closed, reason=$reason', 'WATCHIUM');
    });

    _socket!.connect();
    Logger.d('Socket connect() called', 'WATCHIUM');
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
    Logger.i('Creating room: anime="$animeTitle", episode=$episodeNumber', 'WATCHIUM');
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
          'content': {
            'animeId': anilistId?.toString() ?? malId?.toString() ?? '',
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
          },
        }),
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        error.value = 'Failed to create room';
        Logger.w('Create room failed: HTTP ${response.statusCode}', 'WATCHIUM');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final code = data['code'] as String;
      roomCode.value = code;
      Logger.i('Room created, code=$code', 'WATCHIUM');
      _connectSocket();

      await Future.delayed(const Duration(seconds: 1));
      _socket?.emitWithAck('party:join', {'code': code});
      _currentRoomCode = code;
      _updateInRoom();
      Logger.i('Joined room $code as host', 'WATCHIUM');
      return code;
    } catch (e) {
      error.value = 'Failed to create room: $e';
      Logger.e('Create room exception', error: e, loggerName: 'WATCHIUM');
      return null;
    }
  }

  Future<bool> joinRoom(String code) async {
    Logger.i('Joining room: code=$code', 'WATCHIUM');
    try {
      final ok = await login();
      if (!ok) return false;

      roomCode.value = code;
      _connectSocket();

      await Future.delayed(const Duration(seconds: 1));
      _socket?.emitWithAck('party:join', {'code': code});
      _currentRoomCode = code;
      _updateInRoom();
      Logger.i('Join room $code successful', 'WATCHIUM');
      return true;
    } catch (e) {
      error.value = 'Failed to join room: $e';
      Logger.e('Join room exception', error: e, loggerName: 'WATCHIUM');
      return false;
    }
  }

  void leaveRoom() {
    Logger.i('Leaving room $_currentRoomCode', 'WATCHIUM');
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
    Logger.d('Room state cleared (leave internal)', 'WATCHIUM');
  }

  void disconnect() {
    Logger.i('Disconnecting Watchium service', 'WATCHIUM');
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
    if (_currentRoomCode == null || !_isHost) {
      Logger.w('sendControl skipped: not in room or not host (action=$action)', 'WATCHIUM');
      return;
    }
    Logger.d('sendControl: action=$action, positionSec=$positionSec, rate=$rate', 'WATCHIUM');
    _socket?.emit('party:control', {
      'code': _currentRoomCode,
      'action': action,
      if (positionSec != null) 'positionSec': positionSec,
      if (rate != null) 'rate': rate,
    });
  }

  void sendPlay() { Logger.d('sendPlay', 'WATCHIUM'); sendControl('play'); }
  void sendPause() { Logger.d('sendPause', 'WATCHIUM'); sendControl('pause'); }
  void sendSeek(double positionSec) {
    Logger.d('sendSeek: $positionSec', 'WATCHIUM');
    sendControl('seek', positionSec: positionSec);
  }
  void sendRate(double rate) {
    Logger.d('sendRate: $rate', 'WATCHIUM');
    sendControl('rate', rate: rate);
  }

  /// Sends a single heartbeat with the current playback position and state.
  /// Called by [WatchiumSyncController] on a 3-second periodic timer.
  void sendHeartbeat(double positionSec, bool isPlaying) {
    if (_currentRoomCode == null || !_isHost) {
      Logger.w('sendHeartbeat skipped: not in room or not host', 'WATCHIUM');
      return;
    }
    _socket?.emit('party:heartbeat', {
      'code': _currentRoomCode,
      'positionSec': positionSec,
      'isPlaying': isPlaying,
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    Logger.d('Heartbeat stopped', 'WATCHIUM');
  }

  // ---- Content (Host sets anime) ----

  void setContent(WatchiumAnimeContent content) {
    if (_currentRoomCode == null || !_isHost) {
      Logger.w('setContent skipped: not in room or not host', 'WATCHIUM');
      return;
    }
    Logger.d('setContent: anime=${content.animeTitle}, episode=${content.episodeNumber}', 'WATCHIUM');
    _socket?.emit('party:content', {
      'code': _currentRoomCode,
      'content': content.toJson(),
    });
  }

  // ---- Server Selection ----

  void selectServer(String serverId) {
    if (_currentRoomCode == null) {
      Logger.w('selectServer skipped: not in room', 'WATCHIUM');
      return;
    }
    Logger.d('selectServer: serverId=$serverId', 'WATCHIUM');
    _socket?.emit('party:server-select', {
      'code': _currentRoomCode,
      'serverId': serverId,
    });
  }

  // ---- Chat ----

  void sendChat(String text) {
    if (_currentRoomCode == null) return;
    _lastClientId = DateTime.now().millisecondsSinceEpoch.toString();
    Logger.d('sendChat: "$text" (clientId=$_lastClientId)', 'WATCHIUM');
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
    Logger.d('sendReaction: $emoji', 'WATCHIUM');
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
    Logger.d('Listing public rooms', 'WATCHIUM');
    try {
      final ok = await login();
      if (!ok) return [];

      final response = await http.get(
        Uri.parse('$serverUrl/api/watch-party'),
        headers: {
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode != 200) {
        Logger.w('List rooms failed: HTTP ${response.statusCode}', 'WATCHIUM');
        return [];
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final rooms = (data['rooms'] as List)
          .map((e) => WatchiumRoomState.fromJson(e as Map<String, dynamic>))
          .toList();
      publicRooms.assignAll(rooms);
      Logger.i('List rooms: ${rooms.length} rooms found', 'WATCHIUM');
      return rooms;
    } catch (e) {
      error.value = 'Failed to list rooms: $e';
      Logger.e('List rooms exception', error: e, loggerName: 'WATCHIUM');
      return [];
    }
  }

  // ---- Get Room Info (for deep link join) ----

  Future<WatchiumRoomState?> getRoomInfo(String code) async {
    Logger.d('Getting room info for code=$code', 'WATCHIUM');
    try {
      final ok = await login();
      if (!ok) return null;

      final response = await http.get(
        Uri.parse('$serverUrl/api/watch-party/$code'),
        headers: {
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode != 200) {
        Logger.w('Get room info failed: HTTP ${response.statusCode}', 'WATCHIUM');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      Logger.d('Room info retrieved for code=$code', 'WATCHIUM');
      return WatchiumRoomState.fromJson(data);
    } catch (e) {
      Logger.e('Get room info exception', error: e, loggerName: 'WATCHIUM');
      return null;
    }
  }

  // ---- Deep Link Join ----

  Future<bool> handleDeepLinkJoin(String code) async {
    Logger.i('Deep link join: code=$code', 'WATCHIUM');
    final ok = await joinRoom(code);
    if (!ok) return false;
    return true;
  }

  @override
  void onClose() {
    Logger.d('WatchiumService onClose', 'WATCHIUM');
    disconnect();
    super.onClose();
  }
}
