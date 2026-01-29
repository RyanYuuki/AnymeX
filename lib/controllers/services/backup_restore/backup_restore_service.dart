import 'dart:convert';
import 'dart:io';

import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Offline/Hive/custom_list.dart';
import 'package:anymex/models/Offline/Hive/offline_media.dart';
import 'package:anymex/utils/logger.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class BackupRestoreService extends GetxController {
  final OfflineStorageController _storageController = Get.find();

  var isBackingUp = false.obs;
  var isRestoring = false.obs;
  var backupProgress = 0.0.obs;
  var restoreProgress = 0.0.obs;
  var lastBackupPath = ''.obs;
  var statusMessage = ''.obs;

  String _generateKey(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 32);
  }

  Future<Map<String, dynamic>> _exportToJson() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final ver = packageInfo.version;
    return {
      'date': DateFormat('dd MM yyyy hh:mm a').format(DateTime.now()),
      'appVersion': ver,
      'username': serviceHandler.onlineService.profileData.value.name ??
          serviceHandler.onlineService.profileData.value.userName,
      'avatar': serviceHandler.onlineService.profileData.value.avatar,
      'animeLibrary':
          _storageController.animeLibrary.map((e) => e.toJson()).toList(),
      'mangaLibrary':
          _storageController.mangaLibrary.map((e) => e.toJson()).toList(),
      'novelLibrary':
          _storageController.novelLibrary.map((e) => e.toJson()).toList(),
      'animeCustomLists': _storageController.animeCustomLists.value
          .map((e) => e.toJson())
          .toList(),
      'mangaCustomLists': _storageController.mangaCustomLists.value
          .map((e) => e.toJson())
          .toList(),
      'novelCustomLists': _storageController.novelCustomLists.value
          .map((e) => e.toJson())
          .toList(),
    };
  }

  Future<void> _importFromJson(Map<String, dynamic> json,
      {bool merge = false}) async {
    try {
      final version = json['version'] as String?;
      Logger.i('Restoring backup version: $version');

      if (!merge) {
        _storageController.clearCache();
        await Future.delayed(const Duration(milliseconds: 100));
      }

      final animeList = (json['animeLibrary'] as List?)
              ?.map((e) => OfflineMedia.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      if (merge) {
        for (var anime in animeList) {
          if (_storageController.getAnimeById(anime.id ?? '') == null) {
            _storageController.animeLibrary.add(anime);
          }
        }
      } else {
        _storageController.animeLibrary.assignAll(animeList);
      }

      final mangaList = (json['mangaLibrary'] as List?)
              ?.map((e) => OfflineMedia.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      if (merge) {
        for (var manga in mangaList) {
          if (_storageController.getMangaById(manga.id ?? '') == null) {
            _storageController.mangaLibrary.add(manga);
          }
        }
      } else {
        _storageController.mangaLibrary.assignAll(mangaList);
      }

      final novelList = (json['novelLibrary'] as List?)
              ?.map((e) => OfflineMedia.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      if (merge) {
        for (var novel in novelList) {
          if (_storageController.getNovelById(novel.id ?? '') == null) {
            _storageController.novelLibrary.add(novel);
          }
        }
      } else {
        _storageController.novelLibrary.assignAll(novelList);
      }

      if (!merge) {
        _storageController.animeCustomLists.value =
            (json['animeCustomLists'] as List?)
                    ?.map((e) => CustomList.fromJson(e as Map<String, dynamic>))
                    .toList() ??
                [];

        _storageController.mangaCustomLists.value =
            (json['mangaCustomLists'] as List?)
                    ?.map((e) => CustomList.fromJson(e as Map<String, dynamic>))
                    .toList() ??
                [];

        _storageController.novelCustomLists.value =
            (json['novelCustomLists'] as List?)
                    ?.map((e) => CustomList.fromJson(e as Map<String, dynamic>))
                    .toList() ??
                [];
      }

      _storageController.animeLibrary.refresh();
      _storageController.mangaLibrary.refresh();
      _storageController.novelLibrary.refresh();

      _storageController.saveEverything();

      Logger.i('Data import completed successfully');
    } catch (e) {
      Logger.i('Error importing data: $e');
      rethrow;
    }
  }

  String _encryptBackup(Map<String, dynamic> data, String password) {
    final key = encrypt.Key.fromUtf8(_generateKey(password));
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final jsonString = jsonEncode(data);
    final encrypted = encrypter.encrypt(jsonString, iv: iv);

    return jsonEncode({
      'iv': base64.encode(iv.bytes),
      'data': encrypted.base64,
    });
  }

  Map<String, dynamic> _decryptBackup(String encryptedData, String password) {
    try {
      final key = encrypt.Key.fromUtf8(_generateKey(password));
      final parsed = jsonDecode(encryptedData) as Map<String, dynamic>;

      final iv = encrypt.IV.fromBase64(parsed['iv'] as String);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));

      final decrypted = encrypter.decrypt64(parsed['data'] as String, iv: iv);
      return jsonDecode(decrypted) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Invalid password or corrupted backup file');
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isGranted) {
        return true;
      }

      final status = await Permission.manageExternalStorage.request();
      if (status.isGranted) {
        return true;
      }

      if (await Permission.storage.isGranted) {
        return true;
      }

      final storageStatus = await Permission.storage.request();
      return storageStatus.isGranted;
    }
    return true;
  }

  Future<Directory> _getBackupDirectory() async {
    if (Platform.isAndroid) {
      try {
        final directory = await getExternalStorageDirectory();
        if (directory != null) {
          final pathParts = directory.path.split('/');
          final baseIndex = pathParts.indexOf('Android');
          if (baseIndex > 0) {
            final basePath = pathParts.sublist(0, baseIndex).join('/');
            final downloadsDir = Directory('$basePath/Download');
            if (await downloadsDir.exists()) {
              return downloadsDir;
            }
            final documentsDir = Directory('$basePath/Documents');
            if (await documentsDir.exists()) {
              return documentsDir;
            }
          }
        }
      } catch (e) {
        Logger.i('Failed to get external storage: $e');
      }
    }

    return await getApplicationDocumentsDirectory();
  }

  Future<String> createBackup({String? password, String? customPath}) async {
    try {
      isBackingUp.value = true;
      backupProgress.value = 0.0;
      statusMessage.value = 'Preparing backup data...';

      backupProgress.value = 0.2;
      final data = await _exportToJson();

      statusMessage.value = 'Encrypting data...';
      backupProgress.value = 0.5;

      final content = password != null && password.isNotEmpty
          ? _encryptBackup(data, password)
          : jsonEncode(data);

      statusMessage.value = 'Saving backup file...';
      backupProgress.value = 0.7;

      String filePath;
      if (customPath != null) {
        filePath = customPath;
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'anymex_backup_$timestamp.anymex';
        filePath = '${directory.path}/$fileName';
      }

      final file = File(filePath);
      await file.writeAsString(content);

      backupProgress.value = 1.0;
      statusMessage.value = 'Backup created successfully!';
      lastBackupPath.value = filePath;

      Logger.i('Backup created: $filePath');
      return filePath;
    } catch (e) {
      statusMessage.value = 'Backup failed: ${e.toString()}';
      Logger.i('Backup creation failed: $e');
      rethrow;
    } finally {
      isBackingUp.value = false;
    }
  }

  Future<void> restoreBackup(String filePath,
      {String? password, bool merge = false}) async {
    try {
      isRestoring.value = true;
      restoreProgress.value = 0.0;
      statusMessage.value = 'Reading backup file...';

      final file = File(filePath);

      if (!await file.exists()) {
        throw Exception('Backup file not found');
      }

      restoreProgress.value = 0.2;
      final content = await file.readAsString();

      statusMessage.value = 'Decrypting data...';
      restoreProgress.value = 0.4;

      final data = password != null && password.isNotEmpty
          ? _decryptBackup(content, password)
          : jsonDecode(content) as Map<String, dynamic>;

      statusMessage.value = 'Importing data...';
      restoreProgress.value = 0.6;

      await _importFromJson(data, merge: merge);

      restoreProgress.value = 1.0;
      statusMessage.value = 'Backup restored successfully!';

      Logger.i('Backup restored successfully from: $filePath');
    } catch (e) {
      statusMessage.value = 'Restore failed: ${e.toString()}';
      Logger.i('Backup restoration failed: $e');
      rethrow;
    } finally {
      isRestoring.value = false;
    }
  }

  Future<String?> pickBackupFile() async {
    try {
      if (Platform.isAndroid) {
        final hasPermission = await _requestStoragePermission();
        if (!hasPermission) {
          Logger.i('Storage permission denied');
          throw Exception('Storage permission is required to select files');
        }
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['anymex'],
        dialogTitle: 'Select Anymex Backup File',
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.first;

        if (pickedFile.path != null) {
          return pickedFile.path;
        } else if (pickedFile.bytes != null) {
          final tempDir = await getTemporaryDirectory();
          final tempFile = File('${tempDir.path}/${pickedFile.name}');
          await tempFile.writeAsBytes(pickedFile.bytes!);
          return tempFile.path;
        }
      }

      return null;
    } catch (e) {
      Logger.i('File picker error: $e');
      rethrow;
    }
  }

  Future<bool> isValidBackupFile(String filePath, {String? password}) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;

      final content = await file.readAsString();

      final data = password != null && password.isNotEmpty
          ? _decryptBackup(content, password)
          : jsonDecode(content) as Map<String, dynamic>;

      return data.containsKey('version') &&
          data.containsKey('animeLibrary') &&
          data.containsKey('mangaLibrary') &&
          data.containsKey('novelLibrary');
    } catch (e) {
      Logger.i('Backup validation failed: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getBackupInfo(String filePath,
      {String? password}) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final content = await file.readAsString();

      final data = password != null && password.isNotEmpty
          ? _decryptBackup(content, password)
          : jsonDecode(content) as Map<String, dynamic>;

      final animeCount = (data['animeLibrary'] as List?)?.length ?? 0;
      final mangaCount = (data['mangaLibrary'] as List?)?.length ?? 0;
      final novelCount = (data['novelLibrary'] as List?)?.length ?? 0;

      return {
        'date': data['date'],
        'username': data['username'],
        'avatar': data['avatar'],
        'appVersion': data['appVersion'],
        'animeLibrary': (data['animeLibrary'] ?? []).length > 6
            ? (data['animeLibrary'] ?? []).sublist(0, 6)
            : (data['animeLibrary'] ?? []),
        'mangaLibrary': (data['mangaLibrary'] ?? []).length > 6
            ? (data['mangaLibrary'] ?? []).sublist(0, 6)
            : (data['mangaLibrary'] ?? []),
        'novelLibrary': (data['novelLibrary'] ?? []).length > 6
            ? (data['novelLibrary'] ?? []).sublist(0, 6)
            : (data['novelLibrary'] ?? []),
        'animeCount': animeCount,
        'mangaCount': mangaCount,
        'novelCount': novelCount,
        'totalCount': animeCount + mangaCount + novelCount,
        'animeCustomListsCount':
            (data['animeCustomLists'] as List?)?.length ?? 0,
        'mangaCustomListsCount':
            (data['mangaCustomLists'] as List?)?.length ?? 0,
        'novelCustomListsCount':
            (data['novelCustomLists'] as List?)?.length ?? 0,
      };
    } catch (e) {
      Logger.i('Failed to get backup info: $e');
      return null;
    }
  }

  Future<bool> isBackupEncrypted(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;

      final content = await file.readAsString();
      final parsed = jsonDecode(content);

      return parsed is Map &&
          parsed.containsKey('iv') &&
          parsed.containsKey('data');
    } catch (e) {
      return false;
    }
  }

  Future<void> createAutoBackup({String? password}) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');

      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'anymex_auto_backup_$timestamp.anymex';
      final filePath = '${backupDir.path}/$fileName';

      await createBackup(password: password, customPath: filePath);

      await _cleanOldAutoBackups(backupDir);
    } catch (e) {
      Logger.i('Auto backup failed: $e');
    }
  }

  Future<void> _cleanOldAutoBackups(Directory backupDir) async {
    try {
      final files = backupDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.contains('anymex_auto_backup'))
          .toList();

      if (files.length > 5) {
        files.sort(
            (a, b) => b.statSync().modified.compareTo(a.statSync().modified));

        for (var i = 5; i < files.length; i++) {
          await files[i].delete();
          Logger.i('Deleted old auto backup: ${files[i].path}');
        }
      }
    } catch (e) {
      Logger.i('Failed to clean old backups: $e');
    }
  }

  Future<String?> exportBackupToExternal({
    String? password,
    bool requestPath = true,
  }) async {
    try {
      if (Platform.isAndroid && requestPath) {
        final hasPermission = await _requestStoragePermission();
        if (!hasPermission) {
          Logger.i('Storage permission denied');
          throw Exception('Storage permission is required to save files');
        }
      }

      String? savePath;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'anymex_backup_$timestamp.anymex';

      if (requestPath) {
        if (Platform.isAndroid || Platform.isIOS) {
          final tempDir = await getTemporaryDirectory();
          final tempPath = '${tempDir.path}/$fileName';

          final outputFile = await FilePicker.platform.saveFile(
            dialogTitle: 'Save Backup File',
            fileName: fileName,
            type: FileType.custom,
            allowedExtensions: ['anymex'],
          );

          if (outputFile != null) {
            final tempFile = File(tempPath);
            final bytes = await tempFile.readAsBytes();
            final targetFile = File(outputFile);
            await targetFile.writeAsBytes(bytes);
            await tempFile.delete();
            savePath = outputFile;
          } else {
            return tempPath;
          }
        } else {
          savePath = await FilePicker.platform.saveFile(
            dialogTitle: 'Save Backup File',
            fileName: fileName,
            type: FileType.custom,
            allowedExtensions: ['anymex'],
          );

          if (savePath == null) {
            return null;
          }

          if (!savePath.endsWith('.anymex')) {
            savePath = '$savePath.anymex';
          }
        }
      } else {
        final directory = await _getBackupDirectory();
        savePath = '${directory.path}/$fileName';
      }

      final backupPath = await createBackup(
        password: password,
        customPath: savePath,
      );

      return backupPath;
    } catch (e) {
      Logger.i('Export backup failed: $e');
      rethrow;
    }
  }

  Map<String, dynamic> getLibraryStats() {
    return {
      'animeCount': _storageController.animeLibrary.length,
      'mangaCount': _storageController.mangaLibrary.length,
      'novelCount': _storageController.novelLibrary.length,
      'totalMedia': _storageController.animeLibrary.length +
          _storageController.mangaLibrary.length +
          _storageController.novelLibrary.length,
      'animeCustomLists': _storageController.animeCustomLists.value.length,
      'mangaCustomLists': _storageController.mangaCustomLists.value.length,
      'novelCustomLists': _storageController.novelCustomLists.value.length,
    };
  }

  void resetStates() {
    isBackingUp.value = false;
    isRestoring.value = false;
    backupProgress.value = 0.0;
    restoreProgress.value = 0.0;
    statusMessage.value = '';
  }
}
