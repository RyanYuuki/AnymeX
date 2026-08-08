import 'dart:convert';
import 'dart:io';

import 'package:cross_platform_video_thumbnails/cross_platform_video_thumbnails.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class LocalThumbnailService {
  static const _channel = MethodChannel('com.anymex.app/thumbnail');
  static final Map<String, Uint8List> _memCache = {};
  static final Map<String, String> _pathCache = {};
  static bool _initialized = false;
  static bool _isBusy = false;

  static Future<String?> getThumbnailPath(String filePath) async {
    if (filePath.isEmpty) return null;
    if (_pathCache.containsKey(filePath)) {
      final cachedPath = _pathCache[filePath]!;
      if (File(cachedPath).existsSync()) return cachedPath;
    }

    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final String? thumbPath = await _channel.invokeMethod('getVideoThumbnail', {
          'videoPath': filePath,
        });
        if (thumbPath != null && thumbPath.isNotEmpty && File(thumbPath).existsSync()) {
          _pathCache[filePath] = thumbPath;
          return thumbPath;
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<Uint8List?> getThumbnail(String filePath) async {
    if (filePath.isEmpty) return null;

    if (_memCache.containsKey(filePath)) {
      return _memCache[filePath];
    }

    final nativePath = await getThumbnailPath(filePath);
    if (nativePath != null) {
      try {
        final bytes = await File(nativePath).readAsBytes();
        _memCache[filePath] = bytes;
        return bytes;
      } catch (_) {}
    }

    try {
      final cacheDir = await _getCacheDirectory();
      final hash = _getFileHash(filePath);
      final cacheFilePath = p.join(cacheDir, '$hash.png');
      final cacheFile = File(cacheFilePath);

      if (await cacheFile.exists()) {
        final bytes = await cacheFile.readAsBytes();
        _memCache[filePath] = bytes;
        return bytes;
      }

      while (_isBusy) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      _isBusy = true;

      try {
        await _ensureInitialized();

        final thumbnailResult =
            await CrossPlatformVideoThumbnails.generateThumbnail(
          filePath,
          const ThumbnailOptions(
            timePosition: 30.0,
            width: 240,
            height: 160,
            quality: 0.6,
            format: ThumbnailFormat.jpeg,
          ),
        );

        final bytes = Uint8List.fromList(thumbnailResult.data);

        if (bytes.isNotEmpty) {
          _memCache[filePath] = bytes;
          await cacheFile.writeAsBytes(bytes);
          return bytes;
        }
      } finally {
        _isBusy = false;
      }
    } catch (_) {}

    return null;
  }

  static Future<void> _ensureInitialized() async {
    if (!_initialized) {
      try {
        await CrossPlatformVideoThumbnails.initialize();
      } catch (_) {}
      _initialized = true;
    }
  }

  static String _getFileHash(String filePath) {
    return sha256.convert(utf8.encode(filePath)).toString();
  }

  static Future<String> _getCacheDirectory() async {
    final tempDir = await getTemporaryDirectory();
    final thumbDir = Directory(p.join(tempDir.path, 'video_thumbnails'));
    if (!await thumbDir.exists()) {
      await thumbDir.create(recursive: true);
    }
    return thumbDir.path;
  }
}
