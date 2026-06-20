import 'dart:io';

import 'package:anymex/database/isar_models/custom_list.dart';
import 'package:anymex/database/isar_models/key_value.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart'
    hide isar;
import 'package:isar_community/isar.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

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
        CustomListSchema
      ],
      directory: dir.path,
      name: 'AnymeX',
      inspector: true,
    );
  }

  Future<void> init() async {
    Directory? dir;
    try {
      dir = await getDatabaseDirectory();
      isar = _openIsar(dir!);
    } catch (e) {
      try {
        dir = await getDatabaseDirectory();
        final dbFile = File(path.join(dir!.path, 'AnymeX.isar'));
        final lockFile = File(path.join(dir.path, 'AnymeX.isar.lock'));
        if (await dbFile.exists()) await dbFile.delete();
        if (await lockFile.exists()) await lockFile.delete();
        isar = _openIsar(dir);
      } catch (e2) {
        try {
          final tempDir = await getTemporaryDirectory();
          dir = Directory(path.join(tempDir.path,
              'anymex_temp_db_${DateTime.now().millisecondsSinceEpoch}'));
          await dir.create(recursive: true);
          isar = _openIsar(dir);
        } catch (e3) {
          rethrow;
        }
      }
    }

    try {
      await AnymeXExtensionBridge.init(
        isarInstance: isar,
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
    } catch (e) {
      Logger.e(e.toString());
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
    final dir = await getApplicationDocumentsDirectory();
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      return dir;
    } else {
      String dbDir = path.join(dir.path, 'AnymeX', 'databases');
      await Directory(dbDir).create(recursive: true);
      return Directory(dbDir);
    }
  }

  Future<Isar> initDB(String? path, {bool inspector = false}) async {
    return isar;
  }
}
