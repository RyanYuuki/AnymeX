import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AnymeXCacheManager {
  static const String cacheKey = 'anymex_image_cache_v1';
  static const String legacyCacheKey = 'libCachedImageData';

  static final CacheManager instance = CacheManager(
    Config(
      cacheKey,
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 5000,
    ),
  );

  static Future<Directory> getCacheDirectory() async {
    final tempDir = await getTemporaryDirectory();
    return Directory(p.join(tempDir.path, cacheKey));
  }

  static Future<Directory> getResizedCacheDirectory() async {
    final tempDir = await getTemporaryDirectory();
    return Directory(p.join(tempDir.path, '${cacheKey}resized'));
  }

  static Future<Directory> getLegacyCacheDirectory() async {
    final tempDir = await getTemporaryDirectory();
    return Directory(p.join(tempDir.path, legacyCacheKey));
  }

  static Future<Directory> getLegacyResizedCacheDirectory() async {
    final tempDir = await getTemporaryDirectory();
    return Directory(p.join(tempDir.path, '${legacyCacheKey}resized'));
  }
}
