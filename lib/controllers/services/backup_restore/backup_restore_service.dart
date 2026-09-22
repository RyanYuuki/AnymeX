import 'dart:convert';
import 'dart:io';

import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/database/isar_models/custom_list.dart';
import 'package:anymex/database/isar_models/key_value.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:anymex/screens/library/controller/library_controller.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/widgets/common/source_selector.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex_extension_runtime_bridge/AnymeXBridge.dart';
import 'package:anymex_extension_runtime_bridge/ExtensionManager.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:isar_community/isar.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../main.dart';

class SettingsCategory {
  static const common = 'Common';
  static const ui = 'UI';
  static const theme = 'Theme';
  static const player = 'Player';
  static const reader = 'Reader';
  static const accounts = 'Accounts';
  static const discord = 'Discord';
  static const downloads = 'Downloads';
  static const extensions = 'Extensions';

  static const List<String> all = [
    common,
    ui,
    theme,
    player,
    reader,
    accounts,
    discord,
    downloads,
    extensions,
  ];

  static String getCategoryForKey(String key) {
    if (key.startsWith('AuthKeys_') ||
        key.startsWith('auth') ||
        key.contains('AuthToken')) {
      return accounts;
    }
    if (key.contains('discord') || key.contains('Discord')) {
      return discord;
    }
    if (key.startsWith('ThemeKeys_') ||
        key.startsWith('Theme_') ||
        key.contains('Color') ||
        key.contains('isOled') ||
        key.contains('isLightMode') ||
        key.contains('isSystemMode') ||
        key.contains('logo')) {
      return theme;
    }
    if (key.startsWith('PlayerKeys_') ||
        key.startsWith('PlayerSettingsKeys_') ||
        key.startsWith('PlayerUiKeys_') ||
        key.contains('player') ||
        key.contains('subtitle') ||
        key.contains('autoSkip') ||
        key.contains('useLibass') ||
        key.contains('useMediaKit')) {
      return player;
    }
    if (key.startsWith('ReaderKeys_') ||
        key.startsWith('NovelReaderKeys_') ||
        key.startsWith('TapZoneKeys_') ||
        key.contains('reader') ||
        key.contains('chapter') ||
        key.contains('reading') ||
        key.contains('dualPage') ||
        key.contains('tts') ||
        key.contains('tapZone')) {
      return reader;
    }
    if (key.startsWith('LocalSourceKeys_') ||
        key.contains('watchOffline') ||
        key.contains('download')) {
      return downloads;
    }
    if (key.startsWith('SourceKeys_') ||
        key.startsWith('PluginKeys_') ||
        key.contains('activeAnimeRepo') ||
        key.contains('activeMangaRepo') ||
        key.contains('activeNovelRepo') ||
        key.contains('extension')) {
      return extensions;
    }
    if (key.startsWith('navigationTabOrder') ||
        key.startsWith('UISettings') ||
        key.startsWith('LibraryKeys_') ||
        key.contains('uiScaler') ||
        key.contains('showHomeContinueWatching') ||
        key.contains('grid') ||
        key.contains('unifiedLibrary')) {
      return ui;
    }
    return common;
  }
}

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

  Future<Map<String, dynamic>> _buildBackupData({
    bool backupSettings = true,
    bool backupAuthTokens = false,
    Set<String>? selectedSettingsCategories,
    Set<String>? selectedExtensionIds,
    bool backupAnime = true,
    bool backupManga = true,
    bool backupNovel = true,
    bool backupCustomLists = true,
  }) async {
    final animeCustomLists = backupCustomLists
        ? await _storageController.getCustomListsByType(ItemType.anime)
        : <CustomList>[];
    final mangaCustomLists = backupCustomLists
        ? await _storageController.getCustomListsByType(ItemType.manga)
        : <CustomList>[];
    final novelCustomLists = backupCustomLists
        ? await _storageController.getCustomListsByType(ItemType.novel)
        : <CustomList>[];

    final animeLibrary = backupAnime
        ? await _storageController.getAnimeLibrary()
        : <OfflineMedia>[];
    final mangaLibrary = backupManga
        ? await _storageController.getMangaLibrary()
        : <OfflineMedia>[];
    final novelLibrary = backupNovel
        ? await _storageController.getNovelLibrary()
        : <OfflineMedia>[];

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

    final settingsEntries = isar
        .collection<KeyValue>()
        .where()
        .findAllSync()
        .where((e) {
          final cat = SettingsCategory.getCategoryForKey(e.key);
          if (selectedSettingsCategories != null) {
            return selectedSettingsCategories.contains(cat);
          }
          final isAuth = cat == SettingsCategory.accounts;
          if (isAuth) return backupAuthTokens;
          return backupSettings;
        })
        .map((e) => {'key': e.key, 'value': e.value})
        .toList();

    final sourceCtrl = Get.isRegistered<SourceController>()
        ? Get.find<SourceController>()
        : null;
    final em = Get.isRegistered<ExtensionManager>()
        ? Get.find<ExtensionManager>()
        : null;

    final allSources = <Source>[];
    if (sourceCtrl != null) {
      allSources.addAll(sourceCtrl.installedExtensions);
      allSources.addAll(sourceCtrl.installedMangaExtensions);
      allSources.addAll(sourceCtrl.installedNovelExtensions);
    }

    final exportedExtensions = <Map<String, dynamic>>[];
    for (final s in allSources) {
      if (selectedExtensionIds == null || selectedExtensionIds.contains(s.id)) {
        final managerName = sourceTypeName(s);
        ItemType? type;
        if (sourceCtrl?.installedExtensions.any((e) => e.id == s.id) == true) {
          type = ItemType.anime;
        } else if (sourceCtrl?.installedMangaExtensions
                .any((e) => e.id == s.id) ==
            true) {
          type = ItemType.manga;
        } else if (sourceCtrl?.installedNovelExtensions
                .any((e) => e.id == s.id) ==
            true) {
          type = ItemType.novel;
        }

        exportedExtensions.add({
          'id': s.id,
          'name': s.name,
          'lang': s.lang,
          'version': s.version,
          'baseUrl': s.baseUrl,
          'iconUrl': s.iconUrl,
          'managerName': managerName,
          'mediaType': type?.name,
        });
      }
    }

    final repoData = <Map<String, dynamic>>[];
    if (em != null && exportedExtensions.isNotEmpty) {
      for (final manager in em.managers) {
        for (final type in [ItemType.anime, ItemType.manga, ItemType.novel]) {
          try {
            final repos = manager.getReposRx(type).value;
            for (final r in repos) {
              if (r.url.isNotEmpty) {
                repoData.add({
                  'url': r.url,
                  'name': r.name,
                  'type': type.name,
                  'managerId': manager.id,
                  'managerName': manager.name,
                });
              }
            }
          } catch (_) {}
        }
      }
    }

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
      'settings': settingsEntries,
      'extensions': exportedExtensions,
      'repositories': repoData,
    };
  }

  Future<void> _applyBackupData(
    Map<String, dynamic> data, {
    bool merge = false,
    bool restoreSettings = true,
    bool restoreAuthTokens = false,
    Set<String>? selectedSettingsCategories,
    Set<String>? selectedExtensionIds,
    bool restoreAnime = true,
    bool restoreManga = true,
    bool restoreNovel = true,
    bool restoreCustomLists = true,
  }) async {
    if (!merge &&
        restoreAnime &&
        restoreManga &&
        restoreNovel &&
        restoreCustomLists) {
      await _storageController.clearCache();
    }

    final animeList = restoreAnime
        ? ((data['animeLibrary'] as List?)
                ?.map((e) => OfflineMedia.fromJson(
                    (e as Map<String, dynamic>)..["mediaTypeIndex"] = 1))
                .toList() ??
            [])
        : <OfflineMedia>[];

    final mangaList = restoreManga
        ? ((data['mangaLibrary'] as List?)
                ?.map((e) => OfflineMedia.fromJson(
                    (e as Map<String, dynamic>)..["mediaTypeIndex"] = 0))
                .toList() ??
            [])
        : <OfflineMedia>[];

    final novelList = restoreNovel
        ? ((data['novelLibrary'] as List?)
                ?.map((e) => OfflineMedia.fromJson(
                    (e as Map<String, dynamic>)..["mediaTypeIndex"] = 2))
                .toList() ??
            [])
        : <OfflineMedia>[];

    if (animeList.isNotEmpty || mangaList.isNotEmpty || novelList.isNotEmpty) {
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
    }

    if (!merge && restoreCustomLists) {
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

    final settingsList = data['settings'] as List? ?? [];
    await isar.writeTxn(() async {
      for (var setting in settingsList) {
        final key = setting['key'] as String?;
        if (key == null) continue;

        final category = SettingsCategory.getCategoryForKey(key);
        if (selectedSettingsCategories != null) {
          if (!selectedSettingsCategories.contains(category)) continue;
        } else {
          final isAuth = category == SettingsCategory.accounts;
          if (isAuth && !restoreAuthTokens) continue;
          if (!isAuth && !restoreSettings) continue;
        }

        final kv = KeyValue()
          ..key = key
          ..value = setting['value'];
        await isar.collection<KeyValue>().put(kv);
      }
    });

    final repos = data['repositories'] as List? ?? [];
    if (repos.isNotEmpty && Get.isRegistered<ExtensionManager>()) {
      final em = Get.find<ExtensionManager>();
      for (final r in repos) {
        final url = r['url'] as String?;
        final typeName = r['type'] as String?;
        final managerId = r['managerId'] as String?;
        if (url != null && typeName != null && managerId != null) {
          final type =
              ItemType.values.firstWhereOrNull((t) => t.name == typeName) ??
                  ItemType.anime;
          try {
            await em.addRepos([url], type, managerId);
          } catch (_) {}
        }
      }
    }

    final extensions = data['extensions'] as List? ?? [];
    if (extensions.isNotEmpty && Get.isRegistered<SourceController>()) {
      final sourceCtrl = Get.find<SourceController>();
      try {
        await sourceCtrl.fetchRepos();
      } catch (_) {}

      for (final ext in extensions) {
        final extId = ext['id'] as String?;
        final managerName = ext['managerName'] as String? ?? '';
        if (extId == null) continue;
        if (selectedExtensionIds != null &&
            !selectedExtensionIds.contains(extId)) {
          continue;
        }

        final isPluginDependent = managerName == 'Aniyomi' ||
            managerName == 'CloudStream' ||
            managerName == 'Kotatsu';
        if (Platform.isIOS && isPluginDependent) {
          continue;
        }

        if (isPluginDependent && !AnymeXRuntimeBridge.isPluginInstalled) {
          continue;
        }

        final allAvailable = [
          ...sourceCtrl.availableExtensions,
          ...sourceCtrl.availableMangaExtensions,
          ...sourceCtrl.availableNovelExtensions,
        ];
        final matchingSource =
            allAvailable.firstWhereOrNull((s) => s.id == extId);
        if (matchingSource != null) {
          try {
            await matchingSource.install();
            await sourceCtrl.refreshSourceState(matchingSource);
          } catch (e) {
            Logger.i("Auto-install extension error: $e");
          }
        }
      }
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
    bool backupSettings = true,
    bool backupAuthTokens = false,
    Set<String>? selectedSettingsCategories,
    Set<String>? selectedExtensionIds,
    bool backupAnime = true,
    bool backupManga = true,
    bool backupNovel = true,
    bool backupCustomLists = true,
  }) async {
    try {
      if (Platform.isAndroid && requestPath) {
        final hasPermission = await _requestStoragePermission();
        if (!hasPermission) {
          Logger.i('Storage permission denied');
          throw Exception('Storage permission is required to save files');
        }
      }

      final data = await _buildBackupData(
        backupSettings: backupSettings,
        backupAuthTokens: backupAuthTokens,
        selectedSettingsCategories: selectedSettingsCategories,
        selectedExtensionIds: selectedExtensionIds,
        backupAnime: backupAnime,
        backupManga: backupManga,
        backupNovel: backupNovel,
        backupCustomLists: backupCustomLists,
      );
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

  Future<void> restoreBackup(
    String filePath, {
    String? password,
    bool merge = false,
    bool restoreSettings = true,
    bool restoreAuthTokens = false,
    Set<String>? selectedSettingsCategories,
    Set<String>? selectedExtensionIds,
    bool restoreAnime = true,
    bool restoreManga = true,
    bool restoreNovel = true,
    bool restoreCustomLists = true,
  }) async {
    try {
      final file = File(filePath);

      if (!await file.exists()) {
        throw Exception('Backup file not found');
      }

      final content = await file.readAsString();

      final data = password != null && password.isNotEmpty
          ? _decryptData(content, password)
          : jsonDecode(content) as Map<String, dynamic>;

      await _applyBackupData(
        data,
        merge: merge,
        restoreSettings: restoreSettings,
        restoreAuthTokens: restoreAuthTokens,
        selectedSettingsCategories: selectedSettingsCategories,
        selectedExtensionIds: selectedExtensionIds,
        restoreAnime: restoreAnime,
        restoreManga: restoreManga,
        restoreNovel: restoreNovel,
        restoreCustomLists: restoreCustomLists,
      );

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

      final settingsList = data['settings'] as List? ?? [];
      final availableCategories = <String>{};
      for (var s in settingsList) {
        final k = s['key'] as String?;
        if (k != null) {
          availableCategories.add(SettingsCategory.getCategoryForKey(k));
        }
      }

      final extensionsList = (data['extensions'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final hasPluginExtensions = extensionsList.any((e) {
        final manager = e['managerName'] as String? ?? '';
        return manager == 'Aniyomi' ||
            manager == 'CloudStream' ||
            manager == 'Kotatsu';
      });

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
        'hasSettings': settingsList.any((e) =>
            SettingsCategory.getCategoryForKey(e['key'] as String? ?? '') !=
            SettingsCategory.accounts),
        'hasAuthTokens': settingsList.any((e) =>
            SettingsCategory.getCategoryForKey(e['key'] as String? ?? '') ==
            SettingsCategory.accounts),
        'settingsCategories': availableCategories.toList(),
        'extensions': extensionsList,
        'hasPluginExtensions': hasPluginExtensions,
        'hasAnime': (data['animeLibrary'] as List?)?.isNotEmpty ?? false,
        'hasManga': (data['mangaLibrary'] as List?)?.isNotEmpty ?? false,
        'hasNovel': (data['novelLibrary'] as List?)?.isNotEmpty ?? false,
        'hasCustomLists':
            ((data['animeCustomLists'] as List?)?.isNotEmpty ?? false) ||
                ((data['mangaCustomLists'] as List?)?.isNotEmpty ?? false) ||
                ((data['novelCustomLists'] as List?)?.isNotEmpty ?? false),
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
