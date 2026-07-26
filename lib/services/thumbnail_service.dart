import 'dart:async';
import 'dart:typed_data';
import 'package:cross_platform_video_thumbnails/cross_platform_video_thumbnails.dart';
import 'package:anymex/utils/logger.dart';

class ThumbnailService {
  static final ThumbnailService _instance = ThumbnailService._internal();
  factory ThumbnailService() => _instance;
  ThumbnailService._internal();

  bool _initialized = false;
  final Map<String, Uint8List> _cache = {};
  static const int _maxCacheSize = 100;
  final List<String> _cacheKeysOrder = [];

  Future<void> init() async {
    if (_initialized) return;
    try {
      await CrossPlatformVideoThumbnails.initialize();
      _initialized = true;
    } catch (e) {
      Logger.log('ThumbnailService initialization error: $e');
    }
  }

  Future<Uint8List?> getThumbnail({
    required String videoPath,
    required double timeInSeconds,
    int width = 200,
    int height = 112,
  }) async {
    if (videoPath.isEmpty) return null;

    final int secKey = timeInSeconds.floor();
    final String cacheKey = '$videoPath:$secKey:${width}x$height';

    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    try {
      if (!_initialized) {
        await init();
      }

      final result = await CrossPlatformVideoThumbnails.generateThumbnail(
        videoPath,
        ThumbnailOptions(
          timePosition: timeInSeconds,
          width: width,
          height: height,
          quality: 0.7,
          format: ThumbnailFormat.jpeg,
        ),
      );

      if (result.data.isNotEmpty) {
        final bytes = Uint8List.fromList(result.data);
        _putCache(cacheKey, bytes);
        return bytes;
      }
    } catch (e) {
      // Log or swallow thumbnail exception quietly
    }

    return null;
  }

  void _putCache(String key, Uint8List data) {
    if (_cache.length >= _maxCacheSize) {
      if (_cacheKeysOrder.isNotEmpty) {
        final oldestKey = _cacheKeysOrder.removeAt(0);
        _cache.remove(oldestKey);
      }
    }
    _cache[key] = data;
    _cacheKeysOrder.add(key);
  }

  void clearCache() {
    _cache.clear();
    _cacheKeysOrder.clear();
  }
}
