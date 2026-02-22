import 'dart:async';
import 'dart:convert';
import 'package:anymex/controllers/sync/gist_sync_service.dart';
import 'package:anymex/database/isar_models/chapter.dart';
import 'package:anymex/database/isar_models/episode.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

const _kTokenKey = 'gist_sync_github_token';
const _kUsernameKey = 'gist_sync_github_username';

String get _clientId {
  try {
    return const String.fromEnvironment('GITHUB_CLIENT_ID', defaultValue: '');
  } catch (_) {
    return '';
  }
}

enum _PollStatus { pending, success, expired, denied, error }

class _PollResult {
  final _PollStatus status;
  final String? accessToken;
  _PollResult(this.status, {this.accessToken});
}

class GistDeviceCodeInfo {
  final String userCode;
  final String verificationUri;
  final int expiresIn;

  const GistDeviceCodeInfo({
    required this.userCode,
    required this.verificationUri,
    required this.expiresIn,
  });
}

class GistSyncController extends GetxController {
  final isConnected = false.obs;
  final isAuthenticating = false.obs;
  final isSyncing = false.obs;
  final syncEnabled = true.obs;
  final lastSyncTime = Rx<DateTime?>(null);
  final authError = RxnString();
  final githubUsername = RxnString();
  final deviceCodeInfo = Rx<GistDeviceCodeInfo?>(null);
  RxBool get isSignedIn => isConnected;
  final _service = GistSyncService();
  final _storage = const FlutterSecureStorage();

  @override
  void onInit() {
    super.onInit();
    _restoreToken();
  }

  Future<void> _restoreToken() async {
    try {
      final token = await _storage.read(key: _kTokenKey);
      final username = await _storage.read(key: _kUsernameKey);
      if (token != null && token.isNotEmpty) {
        _service.setToken(token);
        isConnected.value = true;
        githubUsername.value = username;
        Logger.i('[GistSync] Session restored for $username');
      }
    } catch (e) {
      Logger.e('[GistSync] _restoreToken: $e');
    }
  }
  
  Future<GistDeviceCodeInfo?> startDeviceFlow() async {
    if (_clientId.isEmpty) {
      authError.value =
          'GITHUB_CLIENT_ID is not configured. Add it to your .env file.';
      return null;
    }

    isAuthenticating.value = true;
    authError.value = null;
    deviceCodeInfo.value = null;

    try {
      final resp = await http.post(
        Uri.parse('https://github.com/login/device/code'),
        headers: {'Accept': 'application/json'},
        body: {
          'client_id': _clientId,
          'scope': 'gist',
        },
      );

      if (resp.statusCode != 200) {
        authError.value = 'Failed to start login (${resp.statusCode})';
        isAuthenticating.value = false;
        return null;
      }

      final data = json.decode(resp.body) as Map<String, dynamic>;
      final deviceCode = data['device_code'] as String;
      final userCode = data['user_code'] as String;
      final verificationUri = data['verification_uri'] as String;
      final expiresIn = data['expires_in'] as int;
      final interval = (data['interval'] as int?) ?? 5;

      final info = GistDeviceCodeInfo(
        userCode: userCode,
        verificationUri: verificationUri,
        expiresIn: expiresIn,
      );
      deviceCodeInfo.value = info;

      _pollForToken(deviceCode, interval, expiresIn);

      return info;
    } catch (e) {
      authError.value = 'Login error: $e';
      isAuthenticating.value = false;
      Logger.e('[GistSync] startDeviceFlow: $e');
      return null;
    }
  }

  void cancelDeviceFlow() {
    isAuthenticating.value = false;
    deviceCodeInfo.value = null;
    authError.value = null;
    _pollCancelled = true;
  }

  bool _pollCancelled = false;

  Future<void> _pollForToken(
      String deviceCode, int intervalSeconds, int expiresIn) async {
    _pollCancelled = false;
    final deadline = DateTime.now().add(Duration(seconds: expiresIn));

    while (DateTime.now().isBefore(deadline) && !_pollCancelled) {
      await Future.delayed(Duration(seconds: intervalSeconds));
      if (_pollCancelled) break;

      final result = await _checkToken(deviceCode);

      switch (result.status) {
        case _PollStatus.pending:
          continue;
        case _PollStatus.success:
          await _onTokenReceived(result.accessToken!);
          return;
        case _PollStatus.denied:
          authError.value = 'Access denied by user.';
          isAuthenticating.value = false;
          deviceCodeInfo.value = null;
          return;
        case _PollStatus.expired:
          authError.value = 'Code expired. Please try again.';
          isAuthenticating.value = false;
          deviceCodeInfo.value = null;
          return;
        case _PollStatus.error:
          authError.value = 'Authentication error. Please try again.';
          isAuthenticating.value = false;
          deviceCodeInfo.value = null;
          return;
      }
    }

    if (!_pollCancelled) {
      authError.value = 'Code expired. Please try again.';
      isAuthenticating.value = false;
      deviceCodeInfo.value = null;
    }
  }

  Future<_PollResult> _checkToken(String deviceCode) async {
    try {
      final resp = await http.post(
        Uri.parse('https://github.com/login/oauth/access_token'),
        headers: {'Accept': 'application/json'},
        body: {
          'client_id': _clientId,
          'device_code': deviceCode,
          'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
        },
      );

      if (resp.statusCode != 200) return _PollResult(_PollStatus.error);

      final data = json.decode(resp.body) as Map<String, dynamic>;
      final error = data['error'] as String?;

      if (error == null) {
        final token = data['access_token'] as String?;
        if (token != null && token.isNotEmpty) {
          return _PollResult(_PollStatus.success, accessToken: token);
        }
        return _PollResult(_PollStatus.error);
      }

      switch (error) {
        case 'authorization_pending':
          return _PollResult(_PollStatus.pending);
        case 'slow_down':
          await Future.delayed(const Duration(seconds: 5));
          return _PollResult(_PollStatus.pending);
        case 'expired_token':
          return _PollResult(_PollStatus.expired);
        case 'access_denied':
          return _PollResult(_PollStatus.denied);
        default:
          return _PollResult(_PollStatus.error);
      }
    } catch (e) {
      Logger.e('[GistSync] _checkToken: $e');
      return _PollResult(_PollStatus.error);
    }
  }

  Future<void> _onTokenReceived(String token) async {
    try {
      final userResp = await http.get(
        Uri.parse('https://api.github.com/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/vnd.github+json',
        },
      );
      String? username;
      if (userResp.statusCode == 200) {
        final data = json.decode(userResp.body) as Map<String, dynamic>;
        username = data['login'] as String?;
      }

      _service.setToken(token);
      await _storage.write(key: _kTokenKey, value: token);
      if (username != null) {
        await _storage.write(key: _kUsernameKey, value: username);
        githubUsername.value = username;
      }

      isConnected.value = true;
      isAuthenticating.value = false;
      deviceCodeInfo.value = null;
      authError.value = null;
      successSnackBar('Connected as $username!');
    } catch (e) {
      authError.value = 'Failed to finalise login: $e';
      isAuthenticating.value = false;
      Logger.e('[GistSync] _onTokenReceived: $e');
    }
  }

  Future<void> signOut() async {
    _service.clear();
    await _storage.delete(key: _kTokenKey);
    await _storage.delete(key: _kUsernameKey);
    isConnected.value = false;
    githubUsername.value = null;
    lastSyncTime.value = null;
    authError.value = null;
    deviceCodeInfo.value = null;
  }

  bool get _canSync =>
      isConnected.value && syncEnabled.value && _service.isReady;

  void pushEpisodeProgress({
    required String mediaId,
    String? malId,
    String? serviceType,
    required Episode episode,
    bool isCompleted = false,
  }) {
    if (!_canSync || mediaId.isEmpty) return;

    if (isCompleted) {
      unawaited(_doUpload(() => _service.remove(mediaId, malId: malId)));
      return;
    }

    unawaited(_doUpload(() async {
      await _service.upsert(GistProgressEntry(
        mediaId: mediaId,
        malId: malId,
        mediaType: 'anime',
        serviceType: serviceType,
        episodeNumber: episode.number,
        timestampMs: episode.timeStampInMilliseconds,
        durationMs: episode.durationInMilliseconds,
        updatedAt:
            episode.lastWatchedTime ?? DateTime.now().millisecondsSinceEpoch,
      ));
    }));
  }
  
  void pushChapterProgress({
    required String mediaId,
    String? malId,
    String? serviceType,
    required String mediaType,
    required Chapter chapter,
    bool isCompleted = false,
  }) {
    if (!_canSync || mediaId.isEmpty) return;

    if (isCompleted) {
      unawaited(_doUpload(() => _service.remove(mediaId, malId: malId)));
      return;
    }

    unawaited(_doUpload(() async {
      await _service.upsert(GistProgressEntry(
        mediaId: mediaId,
        malId: malId,
        mediaType: mediaType,
        serviceType: serviceType,
        chapterNumber: chapter.number,
        pageNumber: chapter.pageNumber,
        totalPages: chapter.totalPages,
        scrollOffset: chapter.currentOffset,
        maxScrollOffset: chapter.maxOffset,
        updatedAt:
            chapter.lastReadTime ?? DateTime.now().millisecondsSinceEpoch,
      ));
    }));
  }
  
  void removeEntry(String mediaId, {String? malId}) {
    if (!_canSync || mediaId.isEmpty) return;
    unawaited(_doUpload(() => _service.remove(mediaId, malId: malId)));
  }
  
  Future<int?> fetchNewerEpisodeTimestamp({
    required String mediaId,
    String? malId,
    required String episodeNumber,
    required int localTimestampMs,
  }) async {
    if (!_canSync) return null;
    try {
      final entry = await _service.fetch(mediaId, malId: malId);
      if (entry == null || entry.mediaType != 'anime') return null;
      if (entry.episodeNumber != episodeNumber) return null;
      final cloud = entry.timestampMs ?? 0;
      if (cloud > localTimestampMs) {
        Logger.i(
            '[GistSync] Newer timestamp: ${cloud}ms > ${localTimestampMs}ms');
        return cloud;
      }
    } catch (e) {
      Logger.e('[GistSync] fetchNewerEpisodeTimestamp: $e');
    }
    return null;
  }

  Future<GistProgressEntry?> fetchNewerChapterProgress({
    required String mediaId,
    String? malId,
    required String mediaType,
    required double chapterNumber,
    required int localUpdatedAt,
  }) async {
    if (!_canSync) return null;
    try {
      final entry = await _service.fetch(mediaId, malId: malId);
      if (entry == null || entry.mediaType != mediaType) return null;
      if (entry.chapterNumber != chapterNumber) return null;
      if (entry.updatedAt > localUpdatedAt) {
        Logger.i(
            '[GistSync] Newer chapter progress for $mediaId ch$chapterNumber');
        return entry;
      }
    } catch (e) {
      Logger.e('[GistSync] fetchNewerChapterProgress: $e');
    }
    return null;
  }

  Future<void> _doUpload(Future<void> Function() fn) async {
    isSyncing.value = true;
    try {
      await fn();
      lastSyncTime.value = DateTime.now();
    } catch (e) {
      Logger.e('[GistSync] _doUpload: $e');
    } finally {
      isSyncing.value = false;
    }
  }
}
