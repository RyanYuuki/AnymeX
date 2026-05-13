import 'dart:io';

import 'package:anymex/controllers/services/storage/anymex_cache_manager.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/database/isar_models/custom_list.dart';
import 'package:anymex/database/isar_models/key_value.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:anymex/database/kv_helper.dart';
import 'package:anymex/main.dart';
import 'package:isar_community/isar.dart';
import 'package:anymex/utils/logger.dart';
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

  Future<void> clearImageCache() async {
    await AnymeXCacheManager.instance.emptyCache();

    final dirs = await _getAllKnownCacheDirectories();
    for (final dir in dirs) {
      await _deleteDirectoryIfExists(dir);
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
    try {
      final prefix = KvHelper.profilePrefix;
      final pid = prefix.isNotEmpty
          ? prefix.substring(0, prefix.length - 1)
          : null;

      isar.writeTxnSync(() {
        if (pid != null) {
          final mediaToDelete = isar.offlineMedias
              .filter()
              .profileIdEqualTo(pid)
              .findAllSync();
          for (final m in mediaToDelete) {
            isar.offlineMedias.deleteSync(m.id);
          }

          final listsToDelete = isar.customLists
              .filter()
              .profileIdEqualTo(pid)
              .findAllSync();
          for (final l in listsToDelete) {
            isar.customLists.deleteSync(l.id);
          }

          final allKeys =
              isar.collection<KeyValue>().where().findAllSync();
          final toDelete = allKeys
              .where((kv) => kv.key.startsWith(prefix))
              .toList();
          for (final kv in toDelete) {
            isar.collection<KeyValue>().deleteSync(kv.id);
          }
        } else {
          isar.clearSync();
        }
      });
    } catch (e) {
      Logger.i('Error during profile data reset: $e');
      rethrow;
    }
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
    await for (final entity
        in directory.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }

  Future<List<Directory>> _getAllKnownCacheDirectories() async {
    return [
      await AnymeXCacheManager.getCacheDirectory(),
      await AnymeXCacheManager.getResizedCacheDirectory(),
      await AnymeXCacheManager.getLegacyCacheDirectory(),
      await AnymeXCacheManager.getLegacyResizedCacheDirectory(),
    ];
  }

  Future<void> _deleteDirectoryIfExists(Directory directory) async {
    if (!await directory.exists()) return;
    try {
      await directory.delete(recursive: true);
    } catch (_) {}
  }
}
