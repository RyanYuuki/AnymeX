import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:cross_platform_video_thumbnails/cross_platform_video_thumbnails.dart';

class LocalThumbnailService {
  static final Map<String, Uint8List> _memCache = {};
  static bool _initialized = false;
  static bool _isBusy = false;

  static Future<void> _ensureInitialized() async {
    if (!_initialized) {
      try {
        await CrossPlatformVideoThumbnails.initialize();
      } catch (e) {
        print("Error initializing CrossPlatformVideoThumbnails: $e");
      }
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

  static Future<Uint8List?> getThumbnail(String filePath) async {
    if (filePath.isEmpty) return null;

    if (_memCache.containsKey(filePath)) {
      return _memCache[filePath];
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
            timePosition: 5.0,
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
    } catch (e) {
      print("Error in LocalThumbnailService for $filePath: $e");
    }

    return null;
  }
}
