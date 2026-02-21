import 'dart:async';
import 'dart:io';
import 'package:anymex/controllers/sync/cloud_sync_service.dart';
import 'package:anymex/database/isar_models/chapter.dart';
import 'package:anymex/database/isar_models/episode.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

const _kAccessTokenKey = 'cloud_sync_access_token';
const _kExpiryKey = 'cloud_sync_token_expiry';

extension CloudSyncLocator on CloudSyncController {
  static CloudSyncController get instance => Get.find<CloudSyncController>();
}

class CloudSyncController extends GetxController {
  static const _driveScopes = [
    'https://www.googleapis.com/auth/drive.appdata',
  ];

  final isSignedIn = false.obs;
  final isAuthenticating = false.obs;
  final lastAuthError = RxnString();
  final isSyncing = false.obs;
  final lastSyncTime = Rx<DateTime?>(null);
  final syncEnabled = true.obs;
  final _service = CloudSyncService();
  final _storage = const FlutterSecureStorage();

  GoogleSignIn? _googleSignIn;
  GoogleSignInAccount? _account;

  @override
  void onInit() {
    super.onInit();
    if (_isPlatformSupported) {
      _googleSignIn = GoogleSignIn(scopes: _driveScopes);
      _restoreSession();
    }
  }

  bool get _isPlatformSupported =>
      Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

  Future<void> signIn() async {
    if (!_isPlatformSupported ||
        _googleSignIn == null ||
        isAuthenticating.value) {
      return;
    }
    lastAuthError.value = null;
    isAuthenticating.value = true;
    try {
      _account = await _googleSignIn!.signIn();
      if (_account != null) {
        await _refreshAndApply();
      }
    } on PlatformException catch (e, st) {
      _handleSignInPlatformException(e, st);
    } catch (e, st) {
      Logger.e('[CloudSyncController] signIn error: $e', stackTrace: st);
      final errorText = _truncateError(e.toString());
      lastAuthError.value = errorText;
      snackBar(
        'Google sign-in failed: $errorText',
        duration: 7000,
        maxLines: 6,
      );
    } finally {
      isAuthenticating.value = false;
    }
  }

  void _handleSignInPlatformException(PlatformException e, StackTrace st) {
    Logger.e('[CloudSyncController] signIn error: $e', stackTrace: st);
    final errorText = _platformErrorText(e);
    lastAuthError.value = errorText;

    if (e.code == 'sign_in_canceled') {
      snackBar(
        'Google sign-in canceled: $errorText',
        duration: 3500,
        maxLines: 4,
      );
      return;
    }

    snackBar(
      'Google sign-in failed: $errorText',
      duration: 8000,
      maxLines: 7,
    );
  }

  Future<void> signOut() async {
    if (!_isPlatformSupported || _googleSignIn == null) return;
    await _googleSignIn!.signOut();
    _account = null;
    _service.clear();
    isSignedIn.value = false;
    lastAuthError.value = null;
    await _storage.delete(key: _kAccessTokenKey);
    await _storage.delete(key: _kExpiryKey);
  }

  Future<void> _restoreSession() async {
    try {
      _account = await _googleSignIn!.signInSilently();
      if (_account != null) await _refreshAndApply();
    } catch (e) {
      Logger.e('[CloudSyncController] _restoreSession: $e');
    }
  }

  Future<void> _refreshAndApply() async {
    if (_account == null) return;
    try {
      final auth = await _account!.authentication;
      final token = auth.accessToken;
      if (token == null) return;
      final expiry = DateTime.now().add(const Duration(minutes: 55));
      _service.setCredentials(token, expiry);
      isSignedIn.value = true;
      lastAuthError.value = null;
      await _storage.write(key: _kAccessTokenKey, value: token);
      await _storage.write(
          key: _kExpiryKey, value: expiry.millisecondsSinceEpoch.toString());
    } catch (e) {
      Logger.e('[CloudSyncController] _refreshAndApply: $e');
      isSignedIn.value = false;
    }
  }

  Future<bool> _ensureAuth() async {
    if (!_isPlatformSupported || !syncEnabled.value) return false;
    if (!isSignedIn.value) return false;
    try {
      await _refreshAndApply();
      return _service.isReady;
    } catch (e) {
      Logger.e('[CloudSyncController] _ensureAuth: $e');
      return false;
    }
  }

  Future<void> pushEpisodeProgress({
    required String mediaId,
    String? malId,
    required Episode episode,
  }) async {
    if (!await _ensureAuth()) return;
    if (isSyncing.value) return;
    unawaited(_doUpload(() async {
      final entry = CloudProgressEntry(
        mediaId: mediaId,
        malId: malId,
        mediaType: 'anime',
        episodeNumber: episode.number,
        timestampMs: episode.timeStampInMilliseconds,
        durationMs: episode.durationInMilliseconds,
        updatedAt:
            episode.lastWatchedTime ?? DateTime.now().millisecondsSinceEpoch,
      );
      await _service.upsert(entry);
    }));
  }

  Future<void> pushChapterProgress({
    required String mediaId,
    String? malId,
    required String mediaType,
    required Chapter chapter,
  }) async {
    if (!await _ensureAuth()) return;
    if (isSyncing.value) return;
    unawaited(_doUpload(() async {
      final entry = CloudProgressEntry(
        mediaId: mediaId,
        malId: malId,
        mediaType: mediaType,
        chapterNumber: chapter.number,
        pageNumber: chapter.pageNumber,
        totalPages: chapter.totalPages,
        scrollOffset: chapter.currentOffset,
        maxScrollOffset: chapter.maxOffset,
        updatedAt:
            chapter.lastReadTime ?? DateTime.now().millisecondsSinceEpoch,
      );
      await _service.upsert(entry);
    }));
  }

  Future<int?> fetchNewerEpisodeTimestamp({
    required String mediaId,
    String? malId,
    required String episodeNumber,
    required int localTimestampMs,
  }) async {
    if (!await _ensureAuth()) return null;
    try {
      final entry = await _service.fetch(mediaId, malId: malId);
      if (entry == null) return null;
      if (entry.mediaType != 'anime') return null;
      if (entry.episodeNumber != episodeNumber) return null;
      final cloud = entry.timestampMs ?? 0;
      if (cloud > localTimestampMs) {
        Logger.i(
            '[CloudSync] Newer timestamp found: ${cloud}ms > ${localTimestampMs}ms');
        return cloud;
      }
      return null;
    } catch (e) {
      Logger.e('[CloudSyncController] fetchNewerEpisodeTimestamp: $e');
      return null;
    }
  }

  Future<CloudProgressEntry?> fetchNewerChapterProgress({
    required String mediaId,
    String? malId,
    required String mediaType,
    required double chapterNumber,
    required int localUpdatedAt,
  }) async {
    if (!await _ensureAuth()) return null;
    try {
      final entry = await _service.fetch(mediaId, malId: malId);
      if (entry == null) return null;
      if (entry.mediaType != mediaType) return null;
      if (entry.chapterNumber != chapterNumber) return null;
      if (entry.updatedAt > localUpdatedAt) {
        Logger.i(
            '[CloudSync] Newer chapter progress found for $mediaId ch$chapterNumber');
        return entry;
      }
      return null;
    } catch (e) {
      Logger.e('[CloudSyncController] fetchNewerChapterProgress: $e');
      return null;
    }
  }

  Future<void> _doUpload(Future<void> Function() fn) async {
    isSyncing.value = true;
    try {
      await fn();
      lastSyncTime.value = DateTime.now();
    } catch (e) {
      Logger.e('[CloudSyncController] upload error: $e');
    } finally {
      isSyncing.value = false;
    }
  }

  String _platformErrorText(PlatformException e) {
    final parts = <String>['code=${e.code}'];
    final msg = e.message?.trim();
    if (msg != null && msg.isNotEmpty) {
      parts.add(_truncateError(msg));
    }

    final details = e.details?.toString().trim();
    if (details != null &&
        details.isNotEmpty &&
        details != 'null' &&
        (msg == null || !msg.contains(details))) {
      parts.add(_truncateError(details));
    }
    return parts.join(' | ');
  }

  String _truncateError(String text, {int max = 220}) {
    if (text.length <= max) return text;
    return '${text.substring(0, max)}...';
  }
}
