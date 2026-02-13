import 'dart:convert';
import 'dart:io';

import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/database/isar_models/custom_list.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:anymex/screens/library/controller/library_controller.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:crypto/crypto.dart';
import 'package:dartotsu_extension_bridge/Models/Source.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../main.dart';

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

  Future<Map<String, dynamic>> _buildBackupData() async {
    final animeCustomLists =
        await _storageController.getCustomListsByType(ItemType.anime);
    final mangaCustomLists =
        await _storageController.getCustomListsByType(ItemType.manga);
    final novelCustomLists =
        await _storageController.getCustomListsByType(ItemType.novel);

    final animeLibrary = await _storageController.getAnimeLibrary();
    final mangaLibrary = await _storageController.getMangaLibrary();
    final novelLibrary = await _storageController.getNovelLibrary();

    final animeCount = animeCustomLists.fold<int>(
      0,
      (sum, list) => sum + (list.mediaIds?.length ?? 0),
    );

    final mangaCount = mangaCustomLists.fold<int>(
      0,
      (sum, list) => sum + (list.mediaIds?.length ?? 0),
    );

    final novelCount = novelCustomLists.fold<int>(
      0,
      (sum, list) => sum + (list.mediaIds?.length ?? 0),
    );

    return {
      'date': DateFormat('dd MM yyyy hh:mm a').format(DateTime.now()),
      'appVersion': '',
      'username': serviceHandler.onlineService.profileData.value.name ??
          serviceHandler.onlineService.profileData.value.userName,
      'avatar': serviceHandler.onlineService.profileData.value.avatar,
      'animeCount': animeCount,
      'mangaCount': mangaCount,
      'novelCount': novelCount,
      'animeLibrary': animeLibrary.map((e) => e.toJson()).toList(),
      'mangaLibrary': mangaLibrary.map((e) => e.toJson()).toList(),
      'novelLibrary': novelLibrary.map((e) => e.toJson()).toList(),
      'animeCustomLists': animeCustomLists.map((e) => e.toJson()).toList(),
      'mangaCustomLists': mangaCustomLists.map((e) => e.toJson()).toList(),
      'novelCustomLists': novelCustomLists.map((e) => e.toJson()).toList(),
    };
  }

  Future<void> _applyBackupData(Map<String, dynamic> data,
      {bool merge = false}) async {
    if (!merge) {
      await _storageController.clearCache();
    }

    final animeList = (data['animeLibrary'] as List?)
            ?.map((e) => OfflineMedia.fromJson(
                (e as Map<String, dynamic>)..["mediaTypeIndex"] = 1))
            .toList() ??
        [];

    final mangaList = (data['mangaLibrary'] as List?)
            ?.map((e) => OfflineMedia.fromJson(
                (e as Map<String, dynamic>)..["mediaTypeIndex"] = 0))
            .toList() ??
        [];

    final novelList = (data['novelLibrary'] as List?)
            ?.map((e) => OfflineMedia.fromJson(
                (e as Map<String, dynamic>)..["mediaTypeIndex"] = 2))
            .toList() ??
        [];

    await isar.writeTxn(() async {
      if (merge) {
        for (var anime in animeList) {
          if (_storageController.getMediaById(anime.mediaId ?? '') == null) {
            await isar.offlineMedias.put(anime);
          }
        }

        for (var manga in mangaList) {
          if (_storageController.getMediaById(manga.mediaId ?? '') == null) {
            await isar.offlineMedias.put(manga);
          }
        }

        for (var novel in novelList) {
          if (_storageController.getMediaById(novel.mediaId ?? '') == null) {
            await isar.offlineMedias.put(novel);
          }
        }
      } else {
        await isar.offlineMedias.putAll([
          ...animeList,
          ...mangaList,
          ...novelList,
        ]);
      }
    });

    if (!merge) {
      final animeCustomLists = (data['animeCustomLists'] as List?)
              ?.map((e) => CustomList.fromJson(
                  (e as Map<String, dynamic>)..['mediaTypeIndex'] = 1))
              .toList() ??
          [];

      final mangaCustomLists = (data['mangaCustomLists'] as List?)
              ?.map((e) => CustomList.fromJson(
                  (e as Map<String, dynamic>)..['mediaTypeIndex'] = 0))
              .toList() ??
          [];

      final novelCustomLists = (data['novelCustomLists'] as List?)
              ?.map((e) => CustomList.fromJson(
                  (e as Map<String, dynamic>)..['mediaTypeIndex'] = 2))
              .toList() ??
          [];

      await isar.writeTxn(() async {
        await isar.customLists.putAll([
          ...animeCustomLists,
          ...mangaCustomLists,
          ...novelCustomLists,
        ]);
      });
    }

    Get.delete<LibraryController>();
  }

  String _encryptData(Map<String, dynamic> data, String password) {
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

  Map<String, dynamic> _decryptData(String encryptedData, String password) {
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

      final data = await _buildBackupData();
      final packageInfo = await PackageInfo.fromPlatform();
      data['appVersion'] = packageInfo.version;

      final content = password != null && password.isNotEmpty
          ? _encryptData(data, password)
          : jsonEncode(data);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'anymex_backup_$timestamp.anymex';

      String? outputPath;

      if (requestPath) {
        if (Platform.isIOS || Platform.isAndroid) {
          outputPath = await FilePicker.platform.saveFile(
            dialogTitle: 'Save Backup File',
            fileName: fileName,
            bytes: utf8.encode(content),
            type: FileType.custom,
            allowedExtensions: ['anymex'],
          );
        } else {
          outputPath = await FilePicker.platform.saveFile(
            dialogTitle: 'Save Backup File',
            fileName: fileName,
            type: FileType.custom,
            allowedExtensions: ['anymex'],
          );
        }

        if (outputPath != null) {
          final outputFile = File(outputPath);
          await outputFile.writeAsString(content, flush: true);

          if (await outputFile.exists()) {
            final fileSize = await outputFile.length();
            Logger.i(
                'Backup saved successfully to: $outputPath ($fileSize bytes)');
            lastBackupPath.value = outputPath;
            return outputPath;
          } else {
            throw Exception('Failed to verify backup file creation');
          }
        } else {
          Logger.i('User cancelled backup save');
          return null;
        }
      } else {
        if (Platform.isIOS) {
          try {
            final directory = await getApplicationDocumentsDirectory();
            final fallbackPath = '${directory.path}/$fileName';
            final fallbackFile = File(fallbackPath);
            await fallbackFile.writeAsString(content, flush: true);
            Logger.i('Backup saved to iOS sandbox: $fallbackPath');
            lastBackupPath.value = fallbackPath;
            return fallbackPath;
          } catch (fallbackError) {
            Logger.i('Failed to save to iOS sandbox: $fallbackError');
            throw Exception('Failed to save backup: $fallbackError');
          }
        } else {
          final directory = Platform.isAndroid
              ? Directory('/storage/emulated/0/Download')
              : await getApplicationDocumentsDirectory();

          final fallbackPath = '${directory.path}/$fileName';
          final fallbackFile = File(fallbackPath);
          await fallbackFile.writeAsString(content, flush: true);
          Logger.i('Backup saved to: $fallbackPath');
          lastBackupPath.value = fallbackPath;
          return fallbackPath;
        }
      }
    } catch (e) {
      Logger.i('Export backup failed: $e');
      rethrow;
    }
  }

  Future<void> restoreBackup(String filePath,
      {String? password, bool merge = false}) async {
    try {
      final file = File(filePath);

      if (!await file.exists()) {
        throw Exception('Backup file not found');
      }

      final content = await file.readAsString();

      final data = password != null && password.isNotEmpty
          ? _decryptData(content, password)
          : jsonDecode(content) as Map<String, dynamic>;

      await _applyBackupData(data, merge: merge);

      Logger.i('Backup restored successfully from: $filePath');
    } catch (e) {
      Logger.i('Backup restoration failed: $e');
      rethrow;
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
        type: FileType.any,
        dialogTitle: 'Select Anymex Backup File',
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.first;

        if (pickedFile.path != null) {
          final ext = pickedFile.path?.split('.').last.toLowerCase();
          if (ext != "anymex") {
            snackBar('Invalid file format. Please select a .anymex file');
            return "";
          }

          return pickedFile.path;
        } else if (pickedFile.bytes != null) {
          final tempDir = await getTemporaryDirectory();
          final tempFile = File('${tempDir.path}/${pickedFile.name}');
          await tempFile.writeAsBytes(pickedFile.bytes!);
          return tempFile.path;
        }
      } else {
        if (Platform.isIOS) {
          try {
            final directory = await getApplicationDocumentsDirectory();
            final sandboxFiles = directory
                .listSync()
                .where((f) => f.path.endsWith('.anymex'))
                .toList();

            if (sandboxFiles.isNotEmpty) {
              sandboxFiles.sort((a, b) =>
                  b.statSync().modified.compareTo(a.statSync().modified));
              Logger.i(
                  'Found backup in iOS sandbox: ${sandboxFiles.first.path}');
              return sandboxFiles.first.path;
            }
          } catch (sandboxError) {
            Logger.i('Failed to check iOS sandbox: $sandboxError');
          }
        }
      }

      return null;
    } catch (e) {
      Logger.i('File picker error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getBackupInfo(String filePath,
      {String? password}) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final content = await file.readAsString();

      final data = password != null && password.isNotEmpty
          ? _decryptData(content, password)
          : jsonDecode(content) as Map<String, dynamic>;

      final animeCount = data['animeCount'] ?? 0;
      final mangaCount = data['mangaCount'] ?? 0;
      final novelCount = data['novelCount'] ?? 0;

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

  Future<Map<String, dynamic>> getLibraryStats() async {
    final animeCustomLists =
        await _storageController.getCustomListsByType(ItemType.anime);
    final mangaCustomLists =
        await _storageController.getCustomListsByType(ItemType.manga);
    final novelCustomLists =
        await _storageController.getCustomListsByType(ItemType.novel);

    final animeCount = animeCustomLists.fold<int>(
      0,
      (sum, list) => sum + (list.mediaIds?.length ?? 0),
    );

    final mangaCount = mangaCustomLists.fold<int>(
      0,
      (sum, list) => sum + (list.mediaIds?.length ?? 0),
    );

    final novelCount = novelCustomLists.fold<int>(
      0,
      (sum, list) => sum + (list.mediaIds?.length ?? 0),
    );

    final animeLibrary = await _storageController.getAnimeLibrary();
    final mangaLibrary = await _storageController.getMangaLibrary();
    final novelLibrary = await _storageController.getNovelLibrary();

    return {
      'animeCount': animeCount,
      'mangaCount': mangaCount,
      'novelCount': novelCount,
      'totalMedia':
          animeLibrary.length + mangaLibrary.length + novelLibrary.length,
      'animeCustomLists': animeCustomLists.length,
      'mangaCustomLists': mangaCustomLists.length,
      'novelCustomLists': novelCustomLists.length,
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
