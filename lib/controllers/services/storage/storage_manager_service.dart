import 'dart:io';

import 'package:anymex/controllers/services/storage/anymex_cache_manager.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:path_provider/path_provider.dart';
import 'package:anymex/main.dart';
import 'package:flutter/painting.dart';

class StorageManagerService {
  static const double defaultThresholdGb = 5.0;
  static const double minThresholdGb = 0.5;
  static const double maxThresholdGb = 20.0;
  static const int _bytesPerGb = 1024 * 1024 * 1024;

  double getThresholdGb() {
    final stored = General.imageCacheThresholdGb.get<num>(defaultThresholdGb);
    return stored.toDouble();
  }

  void setThresholdGb(double value) {
    final clamped = value.clamp(minThresholdGb, maxThresholdGb).toDouble();
    General.imageCacheThresholdGb.set(clamped);
  }

  Future<int> getImageCacheSizeBytes() async {
    final dirs = await _getAllKnownCacheDirectories();
    int total = 0;
    for (final dir in dirs) {
      if (await dir.exists()) {
        total += await _computeDirectorySize(dir);
      }
    }
    return total;
  }

  Future<int> getImageCacheSize() async {
    final dirs = [
      await AnymeXCacheManager.getCacheDirectory(),
      await AnymeXCacheManager.getResizedCacheDirectory(),
      await AnymeXCacheManager.getLegacyCacheDirectory(),
      await AnymeXCacheManager.getLegacyResizedCacheDirectory(),
    ];
    int total = 0;
    for (final dir in dirs) {
      total += await _computeDirectorySize(dir);
    }
    return total;
  }

  Future<int> getTorrentCacheSize() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final torrentDir = Directory('${docsDir.path}/torrent_cache');
    return await _computeDirectorySize(torrentDir);
  }

  Future<int> getSnapshotsCacheSize() async {
    final supportDir = await getApplicationSupportDirectory();
    final snapshotsDir = Directory('${supportDir.path}/snapshots');
    return await _computeDirectorySize(snapshotsDir);
  }

  Future<int> getOtherTempCacheSize() async {
    final tempDir = await getTemporaryDirectory();
    final totalTemp = await _computeDirectorySize(tempDir);
    final imageCache = await getImageCacheSize();
    final other = totalTemp - imageCache;
    return other < 0 ? 0 : other;
  }

  Future<void> clearImageCacheOnly() async {
    await AnymeXCacheManager.instance.emptyCache();
    final dirs = [
      await AnymeXCacheManager.getCacheDirectory(),
      await AnymeXCacheManager.getResizedCacheDirectory(),
      await AnymeXCacheManager.getLegacyCacheDirectory(),
      await AnymeXCacheManager.getLegacyResizedCacheDirectory(),
    ];
    for (final dir in dirs) {
      await _clearDirectoryContents(dir);
    }
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  Future<void> clearTorrentCacheOnly() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final torrentDir = Directory('${docsDir.path}/torrent_cache');
    await _clearDirectoryContents(torrentDir);
  }

  Future<void> clearSnapshotsOnly() async {
    final supportDir = await getApplicationSupportDirectory();
    final snapshotsDir = Directory('${supportDir.path}/snapshots');
    await _clearDirectoryContents(snapshotsDir);
  }

  Future<void> clearOtherTempOnly() async {
    final tempDir = await getTemporaryDirectory();
    final imageDirs = [
      (await AnymeXCacheManager.getCacheDirectory()).path,
      (await AnymeXCacheManager.getResizedCacheDirectory()).path,
      (await AnymeXCacheManager.getLegacyCacheDirectory()).path,
      (await AnymeXCacheManager.getLegacyResizedCacheDirectory()).path,
    ];
    if (await tempDir.exists()) {
      try {
        final entities = tempDir.listSync(recursive: false, followLinks: false);
        for (final entity in entities) {
          if (imageDirs.contains(entity.path)) continue;
          try {
            await entity.delete(recursive: true);
          } catch (_) {}
        }
      } catch (_) {}
    }
  }

  Future<void> clearImageCache() async {
    await AnymeXCacheManager.instance.emptyCache();

    final dirs = await _getAllKnownCacheDirectories();
    for (final dir in dirs) {
      await _clearDirectoryContents(dir);
    }

    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  Future<bool> enforceImageCacheLimit() async {
    final thresholdBytes = (getThresholdGb() * _bytesPerGb).round();
    final cacheBytes = await getImageCacheSizeBytes();
    if (cacheBytes < thresholdBytes) return false;
    await clearImageCache();
    return true;
  }

  Future<void> factoryResetIsar() async {
    await isar.writeTxn(() async {
      await isar.clear();
    });
  }

  String formatBytes(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    if (bytes <= 0) return '0 B';
    double size = bytes.toDouble();
    int unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    final value =
        size >= 10 ? size.toStringAsFixed(1) : size.toStringAsFixed(2);
    return '$value ${units[unitIndex]}';
  }

  Future<int> _computeDirectorySize(Directory directory) async {
    int total = 0;
    try {
      if (await directory.exists()) {
        await for (final entity
            in directory.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            try {
              total += await entity.length();
            } catch (_) {}
          }
        }
      }
    } catch (_) {}
    return total;
  }

  Future<List<Directory>> _getAllKnownCacheDirectories() async {
    final tempDir = await getTemporaryDirectory();
    final docsDir = await getApplicationDocumentsDirectory();
    final torrentDir = Directory('${docsDir.path}/torrent_cache');
    return [
      tempDir,
      if (await torrentDir.exists()) torrentDir,
    ];
  }

  Future<void> _clearDirectoryContents(Directory directory) async {
    if (!await directory.exists()) return;
    try {
      final entities = directory.listSync(recursive: false, followLinks: false);
      for (final entity in entities) {
        try {
          await entity.delete(recursive: true);
        } catch (_) {}
      }
    } catch (_) {}
  }
}
