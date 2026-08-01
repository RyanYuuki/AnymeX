import 'dart:async';
import 'dart:convert';

import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/watchium/watchium_models.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

class WatchiumService extends GetxController {
  static const _joinTimeout = Duration(seconds: 10);

  IO.Socket? _socket;
  String? _token;
  String? _userId;
  String? _currentRoomCode;
  bool _isHost = false;
  Timer? _heartbeatTimer;
  String? _lastClientId;

  /// Completer for awaiting join confirmation (party:state or party:error).
  /// Completes true on party:state, false on party:error with JOIN_FAILED, or timeout.
  Completer<bool>? _joinCompleter;

  /// Password to use for the next join attempt.
  String? _pendingPassword;

  /// Password of the currently joined room (for auto-rejoin after disconnect).
  String? _roomPassword;

  // Reactive state
  final Rx<WatchiumRoomState?> roomState = Rx(null);
  final RxList<WatchiumChatMessage> chatMessages = RxList();
  final RxList<WatchiumReaction> reactions = RxList();
  final RxBool isConnected = false.obs;
  final RxBool isConnecting = false.obs;
  final RxString error = ''.obs;
  final RxBool isHost = false.obs;
  final RxString roomCode = ''.obs;
  final RxBool hasPassword = false.obs;

  String get serverUrl =>
      dotenv.env['WATCHIUM_SERVER_URL'] ??
          WatchiumKeys.serverUrl.get<String>('');

  String get _apiToken =>
      dotenv.env['WATCHIUM_API_TOKEN'] ?? '';

  /// True when we have a confirmed room (party:state received and we're connected).
  final RxBool inRoom = false.obs;

  /// True when a join request is in-flight (waiting for party:state or party:error).
  final RxBool isJoining = false.obs;

  /// True when the in-player watch party side pane is open.
  final RxBool isPartyPaneOpened = false.obs;

  /// Id of the locally logged-in user, or null when not authenticated.
  String? get currentUserId => _userId;

  /// True if the current user is a co-host (not host).
  bool get isCohost {
    if (_userId == null) return false;
    final me = roomState.value?.members
        .where((m) => m.userId == _userId && m.role == 'cohost');
    return me != null && me.isNotEmpty;
  }

  /// True if the user can manage chat settings (host or cohost).
  bool get canModerateChat => isHost.value || isCohost;

  /// Whether the member is following the host's playback (seek/play/pause locked).
  /// Stored locally — each member chooses their own mode. Default true.
  final RxBool followHost = (WatchiumKeys.followHost.get<bool>(true)).obs;

  void setFollowHost(bool value) {
    followHost.value = value;
    WatchiumKeys.followHost.set(value);
  }

  /// True if the user can send chat (not disabled, not announcement mode as member).
  bool get canSendChat {
    final state = roomState.value;
    if (state == null) return false;
    if (state.chatDisabled) return false;
    if (state.announcementMode && !isHost.value && !isCohost) return false;
    return true;
  }

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
        headers: {
          'Content-Type': 'application/json',
          if (_apiToken.isNotEmpty) 'X-API-Token': _apiToken,
        },
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
          .setAuth({
            'token': _token,
            if (_apiToken.isNotEmpty) 'apiToken': _apiToken,
          })
          .build(),
    );

    _socket!.on('connect', (_) {
      isConnected.value = true;
      isConnecting.value = false;
      error.value = '';
      Logger.i('Socket connected (id=${_socket?.id})', 'WATCHIUM');

      // Auto-rejoin if we were in a room before the disconnect.
      // The server loses socket mapping on disconnect, so we must
      // re-emit party:join to get back into the room.
      final pendingRoom = _currentRoomCode;
      if (pendingRoom != null && roomState.value != null) {
        Logger.i('Auto-rejoining room $pendingRoom after reconnect', 'WATCHIUM');
        _socket!.emit('party:join', {
          'code': pendingRoom,
          if (_roomPassword != null) 'password': _roomPassword,
        });
      }

      _updateInRoom();
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
      // Fail any pending join
      _failJoinCompleter('Connection failed');
      _updateInRoom();
      Logger.e('Socket connect error', error: err, loggerName: 'WATCHIUM');
    });

    _socket!.on('party:state', (data) {
      final state = WatchiumRoomState.fromJson(data as Map<String, dynamic>);
      roomState.value = state;
      hasPassword.value = (data as Map<String, dynamic>)['hasPassword'] as bool? ?? false;
      _isHost = state.hostUserId == _userId;
      isHost.value = _isHost;
      _currentRoomCode = state.code;
      _updateInRoom();
      Logger.d('party:state received, host=${state.hostUserId}, members=${state.members.length}, code=${state.code}', 'WATCHIUM');
      // Complete the pending join completer with success
      _joinCompleter?.complete(true);
      _joinCompleter = null;
      isJoining.value = false;
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
        chatDisabled: current.chatDisabled,
        announcementMode: current.announcementMode,
        maxMembers: current.maxMembers,
        createdAt: current.createdAt,
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
        chatDisabled: current.chatDisabled,
        announcementMode: current.announcementMode,
        maxMembers: current.maxMembers,
        createdAt: current.createdAt,
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
      final newHostUserId = memberData['hostUserId'] as String? ??
          current.hostUserId;
      roomState.value = WatchiumRoomState(
        code: current.code,
        hostUserId: newHostUserId,
        members: members,
        content: current.content,
        playback: current.playback,
        onlyHostControls: current.onlyHostControls,
        chatDisabled: current.chatDisabled,
        announcementMode: current.announcementMode,
        maxMembers: current.maxMembers,
        createdAt: current.createdAt,
      );
      // Update isHost in case host was transferred
      final nowHost = newHostUserId == _userId;
      if (nowHost != _isHost) {
        _isHost = nowHost;
        isHost.value = nowHost;
        Logger.i('Host role changed: isHost=$nowHost', 'WATCHIUM');
      }
      _handleMemberChanges(current.members, members);
      Logger.d('party:member received, ${members.length} members', 'WATCHIUM');
    });

    _socket!.on('party:history', (data) {
      final messages = (data as Map<String, dynamic>)['messages'] as List;
      if (messages.isNotEmpty) {
        chatMessages.clear();
        for (final m in messages) {
          chatMessages.add(WatchiumChatMessage.fromJson(m as Map<String, dynamic>));
        }
        // Keep max 100
        while (chatMessages.length > 100) chatMessages.removeAt(0);
        Logger.i('party:history: loaded ${messages.length} messages', 'WATCHIUM');
      }
    });

    _socket!.on('party:chat', (data) {
      final msg = WatchiumChatMessage.fromJson(data as Map<String, dynamic>);
      chatMessages.add(msg);
      if (chatMessages.length > 100) chatMessages.removeAt(0);
      Logger.d('party:chat from ${msg.username}: "${msg.text}"', 'WATCHIUM');
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
      final errCode = errData['code'] as String? ?? '';
      final errMsg = errData['message'] as String? ?? 'Unknown error';
      error.value = errMsg;
      Logger.w('party:error received: code=$errCode, message=$errMsg', 'WATCHIUM');

      // If the server rate limited us, surface it to the user.
      if (errCode == 'RATE_LIMITED') {
        warningSnackBar(
          errMsg,
          title: 'Rate limited',
          duration: 4000,
        );
      }

      // If this is a join rejection, fail the completer and clear stale state
      if (errCode == 'JOIN_FAILED') {
        _failJoinCompleter(errMsg);
        // If no completer was pending, this was an auto-rejoin after reconnect.
        // The room is gone — clear all stale state so the UI reflects reality.
        if (_joinCompleter == null && roomState.value != null) {
          Logger.w('Auto-rejoin failed, clearing stale room state', 'WATCHIUM');
          _leaveRoomInternal();
        }
      }
    });

    _socket!.on('party:settings', (data) {
      final settingsData = data as Map<String, dynamic>;
      final settings = settingsData['settings'] as Map<String, dynamic>;
      final current = roomState.value;
      if (current == null) return;
      final changedByKey = settingsData['changedByKey'] as String?;
      final changedBy = settingsData['changedBy'] as String?;
      final newChatDisabled = settings['chatDisabled'] as bool? ?? current.chatDisabled;
      final newAnnouncementMode = settings['announcementMode'] as bool? ?? current.announcementMode;
      roomState.value = WatchiumRoomState(
        code: current.code,
        hostUserId: current.hostUserId,
        members: current.members,
        content: current.content,
        playback: current.playback,
        onlyHostControls: settings['onlyHostControls'] as bool? ?? current.onlyHostControls,
        chatDisabled: newChatDisabled,
        announcementMode: newAnnouncementMode,
        maxMembers: current.maxMembers,
        createdAt: current.createdAt,
      );
      Logger.i('party:settings: chatDisabled=$newChatDisabled, announcementMode=$newAnnouncementMode (changedBy=$changedBy, key=$changedByKey)', 'WATCHIUM');
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

  /// Notify (via snackbar) when a member joins or leaves the room,
  /// depending on the user's notification settings.
  void _handleMemberChanges(
      List<WatchiumMember> oldMembers, List<WatchiumMember> newMembers) {
    if (oldMembers.isEmpty || newMembers.isEmpty) return;
    final oldIds = oldMembers.map((m) => m.userId).toSet();
    final newIds = newMembers.map((m) => m.userId).toSet();

    if (WatchiumKeys.notifyOnMemberJoin.get<bool>(true)) {
      for (final m in newMembers) {
        if (!oldIds.contains(m.userId) && m.userId != _userId) {
          infoSnackBar('${m.username} joined the party',
              title: 'New member');
        }
      }
    }

    if (WatchiumKeys.notifyOnMemberLeave.get<bool>(true)) {
      for (final m in oldMembers) {
        if (!newIds.contains(m.userId) && m.userId != _userId) {
          infoSnackBar('${m.username} left the party', title: 'Member left');
        }
      }
    }
  }

  /// Fail the current join completer (if any) and clean up pending join state.
  void _failJoinCompleter(String message) {
    if (_joinCompleter != null && !_joinCompleter!.isCompleted) {
      _joinCompleter!.complete(false);
    }
    _joinCompleter = null;
    isJoining.value = false;
    // Clear any stale room state from a failed join
    if (roomState.value == null) {
      _currentRoomCode = null;
      _updateInRoom();
    }
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
    int maxMembers = 10,
    String? password,
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
          if (_apiToken.isNotEmpty) 'X-API-Token': _apiToken,
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
          'maxMembers': maxMembers,
          if (password != null && password!.isNotEmpty) 'password': password,
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

      // Connect socket and wait for join confirmation
      _connectSocket();
      final joined = await _waitForJoin(code);
      if (!joined) {
        Logger.w('Failed to join created room $code: ${error.value}', 'WATCHIUM');
        return null;
      }

      Logger.i('Joined room $code as host', 'WATCHIUM');
      return code;
    } catch (e) {
      error.value = 'Failed to create room: $e';
      Logger.e('Create room exception', error: e, loggerName: 'WATCHIUM');
      return null;
    }
  }

  Future<bool> joinRoom(String code, {String? password}) async {
    Logger.i('Joining room: code=$code', 'WATCHIUM');
    try {
      final ok = await login();
      if (!ok) return false;

      // If already in this room, do nothing
      if (_currentRoomCode == code && inRoom.value && roomState.value != null) {
        Logger.d('Already in room $code', 'WATCHIUM');
        return true;
      }

      // Leave any existing room first
      if (_currentRoomCode != null) {
        Logger.i('Leaving existing room $_currentRoomCode before joining $code', 'WATCHIUM');
        leaveRoom();
        await Future.delayed(const Duration(milliseconds: 300));
      }

      roomCode.value = code;
      _pendingPassword = password;
      _connectSocket();

      // Wait for join confirmation (party:state) or rejection (party:error)
      final joined = await _waitForJoin(code);
      if (!joined) {
        Logger.w('Join room $code failed: ${error.value}', 'WATCHIUM');
        return false;
      }

      Logger.i('Join room $code successful', 'WATCHIUM');
      return true;
    } catch (e) {
      error.value = 'Failed to join room: $e';
      Logger.e('Join room exception', error: e, loggerName: 'WATCHIUM');
      return false;
    }
  }
  /// Emit party:join and wait for party:state (success) or party:error (failure).
  /// Returns true if join was confirmed, false otherwise.
  Future<bool> _waitForJoin(String code) async {
    // Wait for socket to connect first
    if (_socket?.connected != true) {
      Logger.d('Waiting for socket to connect...', 'WATCHIUM');
      for (int i = 0; i < 50; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (_socket?.connected == true) break;
        if (error.value == 'Connection failed') {
          error.value = 'Failed to connect to server';
          return false;
        }
      }
      if (_socket?.connected != true) {
        error.value = 'Failed to connect to server';
        return false;
      }
    }

    // Set up the completer
    _joinCompleter = Completer<bool>();
    isJoining.value = true;
    error.value = '';

    // Emit the join
    Logger.d('Emitting party:join for code=$code', 'WATCHIUM');
    _socket!.emitWithAck('party:join', {
      'code': code,
      if (_pendingPassword != null) 'password': _pendingPassword,
    });
    // Store password for auto-rejoin after disconnect
    _roomPassword = _pendingPassword;
    _pendingPassword = null;

    // Wait with timeout
    final result = await _joinCompleter!.future
        .timeout(_joinTimeout, onTimeout: () {
      Logger.w('Join timed out for code=$code', 'WATCHIUM');
      return false;
    });

    if (!result) {
      // Join was rejected or timed out — clean up
      isJoining.value = false;
      // If no state was received, the room is invalid
      if (roomState.value == null || roomState.value!.code != code) {
        _currentRoomCode = null;
        _updateInRoom();
      }
    }

    return result;
  }
  void leaveRoom() {
    Logger.i('Leaving room $_currentRoomCode', 'WATCHIUM');
    if (_currentRoomCode == null) return;
    _socket?.emit('party:leave', {'code': _currentRoomCode});
    _leaveRoomInternal();
  }

  /// Leave the room and close the player screen.
  void leaveRoomAndClosePlayer() {
    leaveRoom();
    Get.back();
  }

  /// Force-leave locally without sending to server.
  /// Used when the user is stuck in a ghost/broken room state.
  void forceLeaveRoom() {
    Logger.w('Force leaving room $_currentRoomCode (local only)', 'WATCHIUM');
    _joinCompleter?.complete(false);
    _joinCompleter = null;
    isJoining.value = false;
    _leaveRoomInternal();
  }

  void _leaveRoomInternal() {
    _stopHeartbeat();
    _currentRoomCode = null;
    _roomPassword = null;
    _isHost = false;
    isHost.value = false;
    inRoom.value = false;
    isPartyPaneOpened.value = false;
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

  // ---- Kick ----

  void kickMember(String targetUserId) {
    if (_currentRoomCode == null || !_isHost) {
      Logger.w('kickMember skipped: not in room or not host', 'WATCHIUM');
      return;
    }
    Logger.i('kickMember: target=$targetUserId', 'WATCHIUM');
    _socket?.emit('party:kick', {
      'code': _currentRoomCode,
      'targetUserId': targetUserId,
    });
  }

  // ---- Transfer Host ----

  void transferHost(String targetUserId) {
    if (_currentRoomCode == null || !_isHost) {
      Logger.w('transferHost skipped: not in room or not host', 'WATCHIUM');
      return;
    }
    Logger.i('transferHost: target=$targetUserId', 'WATCHIUM');
    _socket?.emit('party:transfer-host', {
      'code': _currentRoomCode,
      'targetUserId': targetUserId,
    });
  }

  // ---- Co-host ----

  void promoteCohost(String targetUserId) {
    if (_currentRoomCode == null || !_isHost) {
      Logger.w('promoteCohost skipped: not in room or not host', 'WATCHIUM');
      return;
    }
    Logger.i('promoteCohost: target=$targetUserId', 'WATCHIUM');
    _socket?.emit('party:promote-cohost', {
      'code': _currentRoomCode,
      'targetUserId': targetUserId,
    });
  }

  void demoteCohost(String targetUserId) {
    if (_currentRoomCode == null || !_isHost) {
      Logger.w('demoteCohost skipped: not in room or not host', 'WATCHIUM');
      return;
    }
    Logger.i('demoteCohost: target=$targetUserId', 'WATCHIUM');
    _socket?.emit('party:demote-cohost', {
      'code': _currentRoomCode,
      'targetUserId': targetUserId,
    });
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

  /// Toggle a chat moderation setting (host/cohost only).
  /// [key] is 'chatDisabled' or 'announcementMode'.
  void toggleChatSetting(String key, bool value) {
    if (_currentRoomCode == null) return;
    Logger.i('toggleChatSetting: $key=$value', 'WATCHIUM');
    _socket?.emit('party:toggle-chat', {
      'code': _currentRoomCode,
      'key': key,
      'value': value,
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
          if (_apiToken.isNotEmpty) 'X-API-Token': _apiToken,
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
          if (_apiToken.isNotEmpty) 'X-API-Token': _apiToken,
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

  Future<bool> handleDeepLinkJoin(String code, {String? password}) async {
    Logger.i('Deep link join: code=$code', 'WATCHIUM');
    final ok = await joinRoom(code, password: password);
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
