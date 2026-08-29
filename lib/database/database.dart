import 'dart:io';

import 'package:anymex/database/isar_models/custom_list.dart';
import 'package:anymex/database/isar_models/key_value.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:anymex/database/isar_models/daily_activity.dart';
import 'package:anymex/database/isar_models/media_stats.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart'
    hide isar;
import 'package:isar_community/isar.dart';
import 'package:get/get.dart';
import 'package:anymex/controllers/network/network_manager.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../widgets/non_widgets/snackbar.dart';
import '../main.dart';

class Database {
  Isar _openIsar(Directory dir) {
    return Isar.openSync(
      [
        // BS START
        ...AnymeXExtensionBridge.isarSchema,
        // BS END

        // ANYMEX STUFFS
        KeyValueSchema,
        OfflineMediaSchema,
        CustomListSchema,
        DailyActivitySchema,
        MediaStatsSchema
      ],
      directory: dir.path,
      name: 'AnymeX',
      inspector: true,
    );
  }

  Future<void> init() async {
    Directory? dir;
    try {
      final existingInstance = Isar.getInstance('AnymeX');
      if (existingInstance != null && existingInstance.isOpen) {
        isar = existingInstance;
      } else {
        dir = await getDatabaseDirectory();
        isar = _openIsar(dir!);
      }
    } catch (e) {
      Logger.e('Primary Isar open failed: $e. Attempting lock recovery...');
      try {
        dir = await getDatabaseDirectory();
        await _deleteLockFiles(dir!);
        final existingInstance = Isar.getInstance('AnymeX');
        if (existingInstance != null && existingInstance.isOpen) {
          isar = existingInstance;
        } else {
          isar = _openIsar(dir);
        }
      } catch (e2) {
        Logger.e('Lock recovery failed: $e2. Creating backup before recovery...');
        try {
          dir = await getDatabaseDirectory();
          final dbFile = File(path.join(dir!.path, 'AnymeX.isar'));
          if (await dbFile.exists()) {
            final backupPath = path.join(
              dir.path,
              'AnymeX.isar.corrupted_bak_${DateTime.now().millisecondsSinceEpoch}',
            );
            try {
              // Move rather than copy. Copying leaves the unreadable database
              // exactly where it was, so the _openIsar below fails for the same
              // reason and this branch can never actually recover -- while a
              // full-size backup piles up on every single launch.
              await dbFile.rename(backupPath);
            } catch (_) {}
          }
          await _deleteLockFiles(dir);
          isar = _openIsar(dir);
        } catch (e3) {
          rethrow;
        }
      }
    }

    try {
      final networkManager = Get.put(NetworkManager());
      await AnymeXExtensionBridge.init(
        isarInstance: isar,
        http: networkManager.compatibleClient,
        getDirectory: ({
          String? subPath,
          bool useCustomPath = false,
          bool useSystemPath = false,
        }) async {
          final d = Directory(path.join(dir!.path, subPath ?? ''));

          if (!await d.exists()) {
            await d.create(recursive: true);
          }

          return d;
        },
      );
      AnymeXExtensionBridge.onLog = (log, show) {
        if (show) {
          snackBar(log);
        }
      };
    } catch (e) {
      Logger.e(e.toString());
    }
  }

  /// Removes whichever lock file the bundled Isar build left behind. Isar 3
  /// writes `<name>.isar.lock`; the libmdbx backend used by isar_community
  /// writes `<name>.isar-lck`. Clearing only one of them leaves a stale lock
  /// that keeps the retry failing.
  Future<void> _deleteLockFiles(Directory dir) async {
    for (final name in const ['AnymeX.isar.lock', 'AnymeX.isar-lck']) {
      final lockFile = File(path.join(dir.path, name));
      try {
        if (await lockFile.exists()) await lockFile.delete();
      } catch (_) {}
    }
  }

  Future<bool> requestPermission() async {
    Permission permission = Permission.manageExternalStorage;
    if (Platform.isAndroid) {
      if (await permission.isGranted) {
        return true;
      } else {
        final result = await permission.request();
        if (result == PermissionStatus.granted) {
          return true;
        }
        return false;
      }
    }
    return true;
  }

  Future<Directory?> getDatabaseDirectory() async {
    // On macOS the database must not live in ~/Documents. When iCloud
    // "Desktop & Documents Folders" sync is on, macOS reclaims space by
    // evicting inactive files to dataless placeholders (`ls -lO` reports them
    // as `compressed,dataless`). libmdbx memory-maps its file and cannot map a
    // placeholder, so the open below throws, the recovery path treats a
    // perfectly good database as corrupt, and the app comes up to a grey
    // screen that no relaunch clears. Application Support is app-private and
    // never synced, so it is never evicted. iOS keeps Documents, where the
    // database stays reachable through the Files app.
    final dir = Platform.isMacOS
        ? await getApplicationSupportDirectory()
        : await getApplicationDocumentsDirectory();

    if (Platform.isMacOS) {
      await _migrateLegacyMacosDatabase(dir);
      return dir;
    }
    if (Platform.isAndroid || Platform.isIOS) {
      return dir;
    }
    String dbDir = path.join(dir.path, 'AnymeX', 'databases');
    await Directory(dbDir).create(recursive: true);
    return Directory(dbDir);
  }

  /// One-shot migration for macOS installs whose data still sits in the legacy
  /// ~/Documents location. Moves the database, its lock file and the AnymeX
  /// support folder (extensions, runtime) across so libraries and installed
  /// extensions survive the change. Anything already present at the new
  /// location wins, and a failure leaves the legacy copy untouched, so the
  /// migration is safe to retry on the next launch.
  Future<void> _migrateLegacyMacosDatabase(Directory newDir) async {
    try {
      final legacyDir = await getApplicationDocumentsDirectory();
      if (legacyDir.path == newDir.path) return;

      for (final name in const [
        'AnymeX.isar',
        'AnymeX.isar-lck',
        'AnymeX.isar.lock',
      ]) {
        await _moveAcross(
          File(path.join(legacyDir.path, name)),
          File(path.join(newDir.path, name)),
        );
      }

      final legacySupport = Directory(path.join(legacyDir.path, 'AnymeX'));
      final newSupport = Directory(path.join(newDir.path, 'AnymeX'));
      if (await legacySupport.exists() && !await newSupport.exists()) {
        // Collect the listing up front: _moveAcross deletes as it goes, and
        // mutating the tree while the walk is still streaming skips entries.
        final entities =
            await legacySupport.list(recursive: true, followLinks: false).toList();
        for (final entity in entities) {
          if (entity is! File) continue;
          final relative = path.relative(entity.path, from: legacySupport.path);
          await _moveAcross(entity, File(path.join(newSupport.path, relative)));
        }
        try {
          await legacySupport.delete(recursive: true);
        } catch (_) {}
      }
    } catch (e) {
      Logger.e('macOS database migration skipped: $e');
    }
  }

  /// Copies [from] to [to] and only then removes [from].
  ///
  /// The copy is what forces iCloud to materialize a dataless placeholder: a
  /// plain rename would carry the placeholder out of the sync root, where its
  /// contents can no longer be fetched. A failed or short copy leaves the
  /// legacy file exactly where it was.
  Future<void> _moveAcross(File from, File to) async {
    try {
      if (!await from.exists() || await to.exists()) return;
      await to.parent.create(recursive: true);
      await from.copy(to.path);
      if (await to.length() != await from.length()) {
        try {
          await to.delete();
        } catch (_) {}
        return;
      }
      await from.delete();
    } catch (_) {
      // Leave the legacy copy in place; the migration retries next launch.
    }
  }

  Future<Isar> initDB(String? path, {bool inspector = false}) async {
    return isar;
  }
}
