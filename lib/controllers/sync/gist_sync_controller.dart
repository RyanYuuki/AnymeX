import 'dart:convert';
import 'package:anymex/controllers/sync/gist_sync_service.dart';
import 'package:anymex/database/isar_models/chapter.dart';
import 'package:anymex/database/isar_models/episode.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

const _kTokenKey = 'gist_sync_github_token';
const _kUsernameKey = 'gist_sync_github_username';

class GistSyncController extends GetxController {
  final isLoggedIn = false.obs;
  final isAuthenticating = false.obs;
  final isSyncing = false.obs;
  final syncEnabled = true.obs;
  final lastSyncTime = Rx<DateTime?>(null);
  final githubUsername = RxnString();
  RxBool get isConnected => isLoggedIn;
  final _service = GistSyncService();
  final _storage = const FlutterSecureStorage();

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
  
  @override
  Future<void> login(BuildContext context) async {
    final clientId = dotenv.env['GITHUB_CLIENT_ID'] ?? '';
    final clientSecret = dotenv.env['GITHUB_CLIENT_SECRET'] ?? '';

    if (clientId.isEmpty) {
      Logger.i('[GistSync] GITHUB_CLIENT_ID not set in .env');
      errorSnackBar('GitHub client ID not configured.');
      return;
    }

    final url =
        'https://github.com/login/oauth/authorize'
        '?client_id=$clientId'
        '&scope=gist'
        '&redirect_uri=anymex://oauth/github';

    try {
      final result = await FlutterWebAuth2.authenticate(
        url: url,
        callbackUrlScheme: 'anymex',
      );

      final code = Uri.parse(result).queryParameters['code'];
      if (code != null) {
        Logger.i('[GistSync] Authorization code received');
        await _exchangeCodeForToken(code, clientId, clientSecret);
      }
    } catch (e) {
      Logger.i('[GistSync] Error during GitHub login: $e');
    }
  }

  Future<void> _exchangeCodeForToken(
      String code, String clientId, String clientSecret) async {
    try {
      final response = await http.post(
        Uri.parse('https://github.com/login/oauth/access_token'),
        headers: {'Accept': 'application/json'},
        body: {
          'client_id': clientId,
          'client_secret': clientSecret,
          'code': code,
          'redirect_uri': 'anymex://oauth/github',
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
          username =
              (json.decode(userResp.body) as Map<String, dynamic>)['login']
                  as String?;
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
  }
  
  bool get _canSync =>
      isLoggedIn.value && syncEnabled.value && _service.isReady;
  
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
    isSyncing.value = true;
    try {
      await fn();
      lastSyncTime.value = DateTime.now();
    } catch (e) {
      Logger.i('[GistSync] _doUpload: $e');
    } finally {
      isSyncing.value = false;
    }
  }
}
