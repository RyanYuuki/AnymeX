import 'dart:async';
import 'dart:convert';
import 'package:anymex/controllers/sync/gist_sync_service.dart';
import 'package:anymex/database/isar_models/chapter.dart';
import 'package:anymex/database/isar_models/episode.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/media_syncer.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

const _kTokenKey = 'gist_sync_github_token';
const _kUsernameKey = 'gist_sync_github_username';
const _kDefaultGithubCallbackScheme = 'anymex';

class GistSyncController extends GetxController {
  final isLoggedIn = false.obs;
  final isAuthenticating = false.obs;
  final isSyncing = false.obs;
  final syncEnabled = true.obs;
  final lastSyncTime = Rx<DateTime?>(null);
  final lastSyncDurationMs = RxnInt();
  final lastSyncSuccessful = RxnBool();
  final lastSyncError = RxnString();
  final githubUsername = RxnString();
  RxBool get isConnected => isLoggedIn;
  final _service = GistSyncService();
  final _storage = const FlutterSecureStorage();
  int _activeSyncOps = 0;

  String? get _githubRedirectUri {
    final configured = (dotenv.env['GITHUB_CALLBACK_SCHEME'] ?? '').trim();
    return configured.isEmpty ? null : configured;
  }

  String get _githubCallbackScheme {
    final scheme = Uri.tryParse(_githubRedirectUri ?? '')?.scheme;
    return (scheme == null || scheme.isEmpty)
        ? _kDefaultGithubCallbackScheme
        : scheme;
  }

  @override
  void onInit() {
    super.onInit();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      final token = await _storage.read(key: _kTokenKey);
      final username = await _storage.read(key: _kUsernameKey);
      if (token != null && token.isNotEmpty) {
        _service.setToken(token);
        isLoggedIn.value = true;
        githubUsername.value = username;
        Logger.i('[GistSync] Session restored for $username');
      }
    } catch (e) {
      Logger.i('[GistSync] _restoreSession: $e');
    }
  }

  Future<void> login(BuildContext context) async {
    final clientId = dotenv.env['GITHUB_CLIENT_ID'] ?? '';
    final clientSecret = dotenv.env['GITHUB_CLIENT_SECRET'] ?? '';
    final redirectUri = _githubRedirectUri;

    if (clientId.isEmpty) {
      Logger.i('[GistSync] GITHUB_CLIENT_ID not set in .env');
      errorSnackBar('GitHub client ID not configured.');
      return;
    }

    final authorizeParams = <String, String>{
      'client_id': clientId,
      'scope': 'gist',
      if (redirectUri != null) 'redirect_uri': redirectUri,
    };
    final url =
        Uri.https('github.com', '/login/oauth/authorize', authorizeParams)
            .toString();

    isAuthenticating.value = true;
    try {
      final result = await FlutterWebAuth2.authenticate(
        url: url,
        callbackUrlScheme: _githubCallbackScheme,
      );

      final code = Uri.parse(result).queryParameters['code'];
      if (code != null) {
        Logger.i('[GistSync] Authorization code received');
        await _exchangeCodeForToken(
          code,
          clientId,
          clientSecret,
          redirectUri: redirectUri,
        );
      } else {
        Logger.i('[GistSync] OAuth callback did not include code: $result');
        errorSnackBar('GitHub login failed: missing authorization code.');
      }
    } catch (e) {
      Logger.i('[GistSync] Error during GitHub login: $e');
      errorSnackBar('GitHub login was cancelled or failed.');
    } finally {
      isAuthenticating.value = false;
    }
  }

  Future<void> _exchangeCodeForToken(
    String code,
    String clientId,
    String clientSecret, {
    String? redirectUri,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://github.com/login/oauth/access_token'),
        headers: {'Accept': 'application/json'},
        body: {
          'client_id': clientId,
          'client_secret': clientSecret,
          'code': code,
          if (redirectUri != null) 'redirect_uri': redirectUri,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final token = data['access_token'] as String?;

        if (token == null || token.isEmpty) {
          final ghError =
              data['error_description'] ?? data['error'] ?? 'Unknown error';
          Logger.i('[GistSync] Token exchange error: $ghError');
          errorSnackBar('GitHub login failed: $ghError');
          return;
        }

        final userResp = await http.get(
          Uri.parse('https://api.github.com/user'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/vnd.github+json',
          },
        );
        String? username;
        if (userResp.statusCode == 200) {
          username = (json.decode(userResp.body)
              as Map<String, dynamic>)['login'] as String?;
        }

        _service.setToken(token);
        await _storage.write(key: _kTokenKey, value: token);
        if (username != null) {
          await _storage.write(key: _kUsernameKey, value: username);
          githubUsername.value = username;
        }

        isLoggedIn.value = true;
        Logger.i('[GistSync] Login successful as $username');
        successSnackBar('Connected as ${username ?? 'GitHub user'}!');
      } else {
        throw Exception(
            'Failed to exchange code for token: ${response.body}, ${response.statusCode}');
      }
    } catch (e) {
      Logger.i('[GistSync] _exchangeCodeForToken: $e');
    }
  }

  Future<void> logout() async {
    _service.clear();
    await _storage.delete(key: _kTokenKey);
    await _storage.delete(key: _kUsernameKey);
    isLoggedIn.value = false;
    githubUsername.value = null;
    lastSyncTime.value = null;
    lastSyncDurationMs.value = null;
    lastSyncSuccessful.value = null;
    lastSyncError.value = null;
  }

  bool get _canSync =>
      isLoggedIn.value && syncEnabled.value && _service.isReady;

  Future<void> manualSyncNow() async {
    if (!isLoggedIn.value || !_service.isReady) {
      errorSnackBar('Connect GitHub first to sync progress.');
      return;
    }
    if (isSyncing.value) {
      infoSnackBar('Sync already in progress.');
      return;
    }

    final stopwatch = Stopwatch()..start();
    _beginSyncOp();
    try {
      await _service.syncNow();
      _markSyncSuccess(durationMs: stopwatch.elapsedMilliseconds);
      successSnackBar(
        'Progress synced in ${_formatElapsed(stopwatch.elapsedMilliseconds)}.',
      );
    } catch (e) {
      _markSyncFailure(e, durationMs: stopwatch.elapsedMilliseconds);
      errorSnackBar(
        'Sync failed after ${_formatElapsed(stopwatch.elapsedMilliseconds)}.',
      );
    } finally {
      stopwatch.stop();
      _endSyncOp();
    }
  }

  Future<void> deleteRemoteSyncGist() async {
    if (!isLoggedIn.value || !_service.isReady) {
      errorSnackBar('Connect GitHub first before deleting sync data.');
      return;
    }
    if (isSyncing.value) {
      infoSnackBar('Another sync action is already in progress.');
      return;
    }

    final stopwatch = Stopwatch()..start();
    _beginSyncOp();
    try {
      final deleted = await _service.deleteSyncGist();
      final elapsed = stopwatch.elapsedMilliseconds;
      if (!deleted) {
        infoSnackBar('No AnymeX sync gist found to delete.');
        return;
      }

      lastSyncTime.value = null;
      lastSyncDurationMs.value = null;
      lastSyncSuccessful.value = null;
      lastSyncError.value = null;

      successSnackBar(
          'Deleted AnymeX sync gist in ${_formatElapsed(elapsed)}.');
    } catch (e) {
      _markSyncFailure(e, durationMs: stopwatch.elapsedMilliseconds);
      errorSnackBar(
        'Failed to delete sync gist after ${_formatElapsed(stopwatch.elapsedMilliseconds)}.',
      );
    } finally {
      stopwatch.stop();
      _endSyncOp();
    }
  }

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
      final resolvedMalId =
          (malId != null && malId.isNotEmpty && malId != 'null')
              ? malId
              : await MediaSyncer.mapMediaId(
                  mediaId,
                  type: MappingType.anilist,
                  isManga: false,
                );
      await _service.upsert(GistProgressEntry(
        mediaId: mediaId,
        malId: resolvedMalId,
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
      final resolvedMalId =
          (malId != null && malId.isNotEmpty && malId != 'null')
              ? malId
              : await MediaSyncer.mapMediaId(
                  mediaId,
                  type: MappingType.anilist,
                  isManga: mediaType != 'anime',
                );
      await _service.upsert(GistProgressEntry(
        mediaId: mediaId,
        malId: resolvedMalId,
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
      Logger.i('[GistSync] fetchNewerEpisodeTimestamp: $e');
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
        Logger.i('[GistSync] Newer chapter for $mediaId ch$chapterNumber');
        return entry;
      }
    } catch (e) {
      Logger.i('[GistSync] fetchNewerChapterProgress: $e');
    }
    return null;
  }

  Future<void> _doUpload(Future<void> Function() fn) async {
    final stopwatch = Stopwatch()..start();
    _beginSyncOp();
    try {
      await fn();
      _markSyncSuccess(durationMs: stopwatch.elapsedMilliseconds);
    } catch (e) {
      _markSyncFailure(e, durationMs: stopwatch.elapsedMilliseconds);
      Logger.i('[GistSync] _doUpload: $e');
    } finally {
      stopwatch.stop();
      _endSyncOp();
    }
  }

  void _beginSyncOp() {
    _activeSyncOps += 1;
    isSyncing.value = true;
  }

  void _endSyncOp() {
    if (_activeSyncOps > 0) {
      _activeSyncOps -= 1;
    }
    if (_activeSyncOps == 0) {
      isSyncing.value = false;
    }
  }

  void _markSyncSuccess({int? durationMs}) {
    lastSyncTime.value = DateTime.now();
    if (durationMs != null) {
      lastSyncDurationMs.value = durationMs;
    }
    lastSyncSuccessful.value = true;
    lastSyncError.value = null;
  }

  void _markSyncFailure(Object error, {int? durationMs}) {
    if (durationMs != null) {
      lastSyncDurationMs.value = durationMs;
    }
    lastSyncSuccessful.value = false;
    lastSyncError.value = _normalizeError(error);
  }

  String _normalizeError(Object error) {
    final raw = error.toString().trim();
    if (raw.startsWith('Exception:')) {
      return raw.replaceFirst('Exception:', '').trim();
    }
    if (raw.startsWith('StateError:')) {
      return raw.replaceFirst('StateError:', '').trim();
    }
    return raw;
  }

  String _formatElapsed(int ms) {
    if (ms < 1000) return '${ms}ms';
    final seconds = ms / 1000;
    if (seconds < 60) {
      final decimals = seconds < 10 ? 2 : 1;
      return '${seconds.toStringAsFixed(decimals)}s';
    }
    final minutes = seconds / 60;
    if (minutes < 60) {
      return '${minutes.toStringAsFixed(1)}m';
    }
    final hours = minutes / 60;
    return '${hours.toStringAsFixed(1)}h';
  }
}
