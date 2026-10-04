import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/database/isar_models/custom_list.dart';
import 'package:anymex/database/isar_models/daily_activity.dart';
import 'package:anymex/database/isar_models/key_value.dart';
import 'package:anymex/database/isar_models/media_stats.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:anymex/screens/library/controller/library_controller.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex_extension_runtime_bridge/Settings/KvStore.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart'
    hide isar;
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:isar_community/isar.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../main.dart';

enum SettingCategory {
  appearance,
  player,
  reader,
  extensions,
  downloads,
  general,
  authTokens,
}

SettingCategory categorizeSettingKey(String key) {
  final lower = key.toLowerCase();
  if (key.startsWith('AuthKeys_') ||
      AuthKeys.values.any((e) => e.name == key) ||
      lower.contains('token') ||
      lower.contains('auth') ||
      lower.contains('session')) {
    return SettingCategory.authTokens;
  }
  if (ThemeKeys.values.any((e) => e.name == key) ||
      UISettingsKeys.values.any((e) => e.name == key) ||
      key.startsWith('ThemeKeys_') ||
      key.startsWith('UISettingsKeys_') ||
      key == 'uiSettings' ||
      key == 'themeSettings' ||
      lower.contains('theme') ||
      lower.contains('oled') ||
      lower.contains('color')) {
    return SettingCategory.appearance;
  }
  if (PlayerKeys.values.any((e) => e.name == key) ||
      PlayerUiKeys.values.any((e) => e.name == key) ||
      PlayerSettingsKeys.values.any((e) => e.name == key) ||
      key.startsWith('PlayerKeys_') ||
      key.startsWith('PlayerUiKeys_') ||
      key.startsWith('PlayerSettingsKeys_') ||
      key == 'playerSettings' ||
      lower.contains('player') ||
      lower.contains('subtitle') ||
      lower.contains('shader') ||
      lower.contains('libass')) {
    return SettingCategory.player;
  }
  if (ReaderKeys.values.any((e) => e.name == key) ||
      NovelReaderKeys.values.any((e) => e.name == key) ||
      TapZoneKeys.values.any((e) => e.name == key) ||
      key.startsWith('ReaderKeys_') ||
      key.startsWith('NovelReaderKeys_') ||
      key.startsWith('TapZoneKeys_') ||
      lower.contains('reader') ||
      lower.contains('tapzone')) {
    return SettingCategory.reader;
  }
  if (SourceKeys.values.any((e) => e.name == key) ||
      PluginKeys.values.any((e) => e.name == key) ||
      key.startsWith('SourceKeys_') ||
      key.startsWith('PluginKeys_') ||
      lower.contains('extension') ||
      lower.contains('plugin') ||
      lower.contains('repo')) {
    return SettingCategory.extensions;
  }
  if (DownloadKeys.values.any((e) => e.name == key) ||
      LocalSourceKeys.values.any((e) => e.name == key) ||
      key.startsWith('DownloadKeys_') ||
      key.startsWith('LocalSourceKeys_') ||
      lower.contains('download')) {
    return SettingCategory.downloads;
  }
  return SettingCategory.general;
}

class SettingsOptions {
  bool appearance;
  bool player;
  bool reader;
  bool extensions;
  bool downloads;
  bool general;
  bool authTokens;

  SettingsOptions({
    this.appearance = true,
    this.player = true,
    this.reader = true,
    this.extensions = true,
    this.downloads = true,
    this.general = true,
    this.authTokens = false,
  });

  bool get hasAnySelected =>
      appearance ||
      player ||
      reader ||
      extensions ||
      downloads ||
      general ||
      authTokens;

  factory SettingsOptions.fromJson(Map<String, dynamic> json) =>
      SettingsOptions(
        appearance: json['appearance'] ?? true,
        player: json['player'] ?? true,
        reader: json['reader'] ?? true,
        extensions: json['extensions'] ?? true,
        downloads: json['downloads'] ?? true,
        general: json['general'] ?? true,
        authTokens: json['authTokens'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'appearance': appearance,
        'player': player,
        'reader': reader,
        'extensions': extensions,
        'downloads': downloads,
        'general': general,
        'authTokens': authTokens,
      };
}

extension DailyActivityJson on DailyActivity {
  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'watchTimeMinutes': watchTimeMinutes,
        'readTimeMinutes': readTimeMinutes,
        'episodesWatched': episodesWatched,
        'chaptersRead': chaptersRead,
        'activeMediaIds': activeMediaIds,
      };

  static DailyActivity fromJson(Map<String, dynamic> json) {
    return DailyActivity()
      ..date =
          DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now()
      ..watchTimeMinutes = json['watchTimeMinutes'] as int? ?? 0
      ..readTimeMinutes = json['readTimeMinutes'] as int? ?? 0
      ..episodesWatched = json['episodesWatched'] as int? ?? 0
      ..chaptersRead = json['chaptersRead'] as int? ?? 0
      ..activeMediaIds =
          (json['activeMediaIds'] as List?)?.cast<String>() ?? [];
  }
}

extension MediaStatsJson on MediaStats {
  Map<String, dynamic> toJson() => {
        'mediaId': mediaId,
        'title': title,
        'type': type,
        'poster': poster,
        'cover': cover,
        'totalTimeMinutes': totalTimeMinutes,
        'totalUnitsConsumed': totalUnitsConsumed,
        'lastInteracted': lastInteracted.toIso8601String(),
        'interactionCount': interactionCount,
      };

  static MediaStats fromJson(Map<String, dynamic> json) {
    return MediaStats()
      ..mediaId = json['mediaId'] as String? ?? ''
      ..title = json['title'] as String? ?? ''
      ..type = json['type'] as String? ?? ''
      ..poster = json['poster'] as String?
      ..cover = json['cover'] as String?
      ..totalTimeMinutes = json['totalTimeMinutes'] as int? ?? 0
      ..totalUnitsConsumed = json['totalUnitsConsumed'] as int? ?? 0
      ..lastInteracted =
          DateTime.tryParse(json['lastInteracted'] as String? ?? '') ??
              DateTime.now()
      ..interactionCount = json['interactionCount'] as int? ?? 0;
  }
}

class BackupOptions {
  bool anime;
  bool manga;
  bool novel;
  bool customLists;
  bool stats;
  SettingsOptions settings;
  bool extensionsData;
  bool extensionFiles;
  bool runtimeHost;

  BackupOptions({
    this.anime = true,
    this.manga = true,
    this.novel = true,
    this.customLists = true,
    this.stats = true,
    SettingsOptions? settings,
    this.extensionsData = true,
    this.extensionFiles = true,
    this.runtimeHost = false,
  }) : settings = settings ?? SettingsOptions();

  bool get hasAnySelected =>
      anime ||
      manga ||
      novel ||
      customLists ||
      stats ||
      settings.hasAnySelected ||
      extensionsData ||
      extensionFiles ||
      runtimeHost;

  factory BackupOptions.fromJson(Map<String, dynamic> json) => BackupOptions(
        anime: json['anime'] ?? true,
        manga: json['manga'] ?? true,
        novel: json['novel'] ?? true,
        customLists: json['customLists'] ?? true,
        stats: json['stats'] ?? true,
        settings: json['settings'] != null
            ? SettingsOptions.fromJson(
                Map<String, dynamic>.from(json['settings']))
            : SettingsOptions(),
        extensionsData: json['extensionsData'] ?? true,
        extensionFiles: json['extensionFiles'] ?? true,
        runtimeHost: json['runtimeHost'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'anime': anime,
        'manga': manga,
        'novel': novel,
        'customLists': customLists,
        'stats': stats,
        'settings': settings.toJson(),
        'extensionsData': extensionsData,
        'extensionFiles': extensionFiles,
        'runtimeHost': runtimeHost,
      };
}

class RestoreOptions {
  bool anime;
  bool manga;
  bool novel;
  bool customLists;
  bool stats;
  SettingsOptions settings;
  bool extensionsData;
  bool extensionFiles;
  bool runtimeHost;

  RestoreOptions({
    this.anime = true,
    this.manga = true,
    this.novel = true,
    this.customLists = true,
    this.stats = true,
    SettingsOptions? settings,
    this.extensionsData = true,
    this.extensionFiles = true,
    this.runtimeHost = true,
  }) : settings = settings ?? SettingsOptions();

  bool get hasAnySelected =>
      anime ||
      manga ||
      novel ||
      customLists ||
      stats ||
      settings.hasAnySelected ||
      extensionsData ||
      extensionFiles ||
      runtimeHost;

  factory RestoreOptions.fromJson(Map<String, dynamic> json) => RestoreOptions(
        anime: json['anime'] ?? true,
        manga: json['manga'] ?? true,
        novel: json['novel'] ?? true,
        customLists: json['customLists'] ?? true,
        stats: json['stats'] ?? true,
        settings: json['settings'] != null
            ? SettingsOptions.fromJson(
                Map<String, dynamic>.from(json['settings']))
            : SettingsOptions(),
        extensionsData: json['extensionsData'] ?? true,
        extensionFiles: json['extensionFiles'] ?? true,
        runtimeHost: json['runtimeHost'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'anime': anime,
        'manga': manga,
        'novel': novel,
        'customLists': customLists,
        'stats': stats,
        'settings': settings.toJson(),
        'extensionsData': extensionsData,
        'extensionFiles': extensionFiles,
        'runtimeHost': runtimeHost,
      };
}

class RuntimeHostInfo {
  final bool isInstalled;
  final String filePath;
  final int fileSize;
  final String version;
  final bool isDesktop;

  const RuntimeHostInfo({
    required this.isInstalled,
    required this.filePath,
    required this.fileSize,
    required this.version,
    required this.isDesktop,
  });
}

class ExtensionFilesInfo {
  final int count;
  final int totalSize;

  const ExtensionFilesInfo({
    required this.count,
    required this.totalSize,
  });
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

  Future<RuntimeHostInfo> getRuntimeHostInfo() async {
    try {
      final paths = RuntimePaths();
      String? savedPath;
      if (Platform.isAndroid) {
        try {
          savedPath = getVal<String>('runtime_host_path');
        } catch (_) {}
      }

      final bridgePath = (Platform.isAndroid &&
              savedPath != null &&
              savedPath.isNotEmpty &&
              await File(savedPath).exists())
          ? savedPath
          : await paths.bridgePath;

      final file = File(bridgePath);
      final exists = await file.exists();
      int size = 0;
      if (exists) {
        size = await file.length();
      }
      return RuntimeHostInfo(
        isInstalled: exists,
        filePath: bridgePath,
        fileSize: size,
        version: AnymeXRuntimeBridge.installedVersion,
        isDesktop: !Platform.isAndroid,
      );
    } catch (_) {
      return RuntimeHostInfo(
        isInstalled: false,
        filePath: '',
        fileSize: 0,
        version: '',
        isDesktop: !Platform.isAndroid,
      );
    }
  }

  Future<ExtensionFilesInfo> getExtensionFilesInfo() async {
    try {
      final dir = await RuntimePaths().extensionsDir;
      if (!await dir.exists()) {
        return const ExtensionFilesInfo(count: 0, totalSize: 0);
      }
      int count = 0;
      int totalSize = 0;
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          count++;
          totalSize += await entity.length();
        }
      }
      return ExtensionFilesInfo(count: count, totalSize: totalSize);
    } catch (_) {
      return const ExtensionFilesInfo(count: 0, totalSize: 0);
    }
  }

  int getExtensionsDataCount() {
    try {
      return isar.kvEntrys.countSync();
    } catch (_) {
      return 0;
    }
  }

  Future<Map<String, dynamic>> _buildBackupData({
    required BackupOptions options,
  }) async {
    final animeCustomLists = options.customLists || options.anime
        ? await _storageController.getCustomListsByType(ItemType.anime)
        : <CustomList>[];
    final mangaCustomLists = options.customLists || options.manga
        ? await _storageController.getCustomListsByType(ItemType.manga)
        : <CustomList>[];
    final novelCustomLists = options.customLists || options.novel
        ? await _storageController.getCustomListsByType(ItemType.novel)
        : <CustomList>[];

    final animeLibrary = options.anime
        ? await _storageController.getAnimeLibrary()
        : <OfflineMedia>[];
    final mangaLibrary = options.manga
        ? await _storageController.getMangaLibrary()
        : <OfflineMedia>[];
    final novelLibrary = options.novel
        ? await _storageController.getNovelLibrary()
        : <OfflineMedia>[];

    final animeCount = animeLibrary.length;
    final mangaCount = mangaLibrary.length;
    final novelCount = novelLibrary.length;

    final settingsList = options.settings.hasAnySelected
        ? isar
            .collection<KeyValue>()
            .where()
            .findAllSync()
            .where((e) {
              final cat = categorizeSettingKey(e.key);
              switch (cat) {
                case SettingCategory.appearance:
                  return options.settings.appearance;
                case SettingCategory.player:
                  return options.settings.player;
                case SettingCategory.reader:
                  return options.settings.reader;
                case SettingCategory.extensions:
                  return options.settings.extensions;
                case SettingCategory.downloads:
                  return options.settings.downloads;
                case SettingCategory.general:
                  return options.settings.general;
                case SettingCategory.authTokens:
                  return options.settings.authTokens;
              }
            })
            .map((e) => {
                  'key': e.key,
                  'value': e.value,
                  'category': categorizeSettingKey(e.key).name,
                })
            .toList()
        : <Map<String, dynamic>>[];

    final dailyActivities = options.stats
        ? isar.dailyActivitys
            .where()
            .findAllSync()
            .map((e) => e.toJson())
            .toList()
        : <Map<String, dynamic>>[];

    final mediaStats = options.stats
        ? isar.mediaStats
            .where()
            .findAllSync()
            .map((e) => e.toJson())
            .toList()
        : <Map<String, dynamic>>[];

    final kvEntries = options.extensionsData
        ? isar.kvEntrys.where().findAllSync().map((e) => {
              'key': e.key,
              'value': e.value,
            }).toList()
        : <Map<String, dynamic>>[];

    return {
      'date': DateFormat('dd MM yyyy hh:mm a').format(DateTime.now()),
      'appVersion': '',
      'username': serviceHandler.onlineService.profileData.value.name ??
          serviceHandler.onlineService.profileData.value.userName,
      'avatar': serviceHandler.onlineService.profileData.value.avatar,
      'animeCount': animeCount,
      'mangaCount': mangaCount,
      'novelCount': novelCount,
      'hasAnime': options.anime && animeLibrary.isNotEmpty,
      'hasManga': options.manga && mangaLibrary.isNotEmpty,
      'hasNovel': options.novel && novelLibrary.isNotEmpty,
      'hasCustomLists': options.customLists &&
          (animeCustomLists.isNotEmpty ||
              mangaCustomLists.isNotEmpty ||
              novelCustomLists.isNotEmpty),
      'hasSettings': options.settings.hasAnySelected,
      'hasAppearance': options.settings.appearance,
      'hasPlayer': options.settings.player,
      'hasReader': options.settings.reader,
      'hasExtSettings': options.settings.extensions,
      'hasDownloadSettings': options.settings.downloads,
      'hasGeneralSettings': options.settings.general,
      'hasAuthTokens': options.settings.authTokens,
      'hasStats': options.stats,
      'hasExtensionsData': options.extensionsData,
      'hasExtensionFiles': options.extensionFiles,
      'hasRuntimeHost': options.runtimeHost,
      'runtimeHostPlatform': Platform.operatingSystem,
      'animeLibrary':
          options.anime ? animeLibrary.map((e) => e.toJson()).toList() : [],
      'mangaLibrary':
          options.manga ? mangaLibrary.map((e) => e.toJson()).toList() : [],
      'novelLibrary':
          options.novel ? novelLibrary.map((e) => e.toJson()).toList() : [],
      'animeCustomLists': options.customLists
          ? animeCustomLists.map((e) => e.toJson()).toList()
          : [],
      'mangaCustomLists': options.customLists
          ? mangaCustomLists.map((e) => e.toJson()).toList()
          : [],
      'novelCustomLists': options.customLists
          ? novelCustomLists.map((e) => e.toJson()).toList()
          : [],
      'settings': settingsList,
      'dailyActivities': dailyActivities,
      'mediaStats': mediaStats,
      'kvEntries': kvEntries,
    };
  }

  Future<void> _applyBackupData(
    Map<String, dynamic> data, {
    bool merge = false,
    required RestoreOptions options,
  }) async {
    final hasAnimeInData =
        data.containsKey('animeLibrary') && data['animeLibrary'] != null;
    if (options.anime && hasAnimeInData) {
      final rawList = data['animeLibrary'] as List;
      final list = rawList
          .map((e) => OfflineMedia.fromJson(
              (Map<String, dynamic>.from(e as Map))..["mediaTypeIndex"] = 1))
          .toList();
      await isar.writeTxn(() async {
        if (!merge) {
          await isar.offlineMedias
              .filter()
              .mediaTypeIndexEqualTo(1)
              .deleteAll();
        }
        for (var item in list) {
          if (!merge ||
              _storageController.getMediaById(item.mediaId ?? '') == null) {
            await isar.offlineMedias.put(item);
          }
        }
      });
    }

    final hasMangaInData =
        data.containsKey('mangaLibrary') && data['mangaLibrary'] != null;
    if (options.manga && hasMangaInData) {
      final rawList = data['mangaLibrary'] as List;
      final list = rawList
          .map((e) => OfflineMedia.fromJson(
              (Map<String, dynamic>.from(e as Map))..["mediaTypeIndex"] = 0))
          .toList();
      await isar.writeTxn(() async {
        if (!merge) {
          await isar.offlineMedias
              .filter()
              .mediaTypeIndexEqualTo(0)
              .deleteAll();
        }
        for (var item in list) {
          if (!merge ||
              _storageController.getMediaById(item.mediaId ?? '') == null) {
            await isar.offlineMedias.put(item);
          }
        }
      });
    }

    final hasNovelInData =
        data.containsKey('novelLibrary') && data['novelLibrary'] != null;
    if (options.novel && hasNovelInData) {
      final rawList = data['novelLibrary'] as List;
      final list = rawList
          .map((e) => OfflineMedia.fromJson(
              (Map<String, dynamic>.from(e as Map))..["mediaTypeIndex"] = 2))
          .toList();
      await isar.writeTxn(() async {
        if (!merge) {
          await isar.offlineMedias
              .filter()
              .mediaTypeIndexEqualTo(2)
              .deleteAll();
        }
        for (var item in list) {
          if (!merge ||
              _storageController.getMediaById(item.mediaId ?? '') == null) {
            await isar.offlineMedias.put(item);
          }
        }
      });
    }

    final hasCustomListsInData = data.containsKey('animeCustomLists') ||
        data.containsKey('mangaCustomLists') ||
        data.containsKey('novelCustomLists');
    if (options.customLists && hasCustomListsInData) {
      final animeCustomLists = (data['animeCustomLists'] as List?)
              ?.map((e) => CustomList.fromJson(
                  (Map<String, dynamic>.from(e as Map))..['mediaTypeIndex'] = 1))
              .toList() ??
          [];

      final mangaCustomLists = (data['mangaCustomLists'] as List?)
              ?.map((e) => CustomList.fromJson(
                  (Map<String, dynamic>.from(e as Map))..['mediaTypeIndex'] = 0))
              .toList() ??
          [];

      final novelCustomLists = (data['novelCustomLists'] as List?)
              ?.map((e) => CustomList.fromJson(
                  (Map<String, dynamic>.from(e as Map))..['mediaTypeIndex'] = 2))
              .toList() ??
          [];

      await isar.writeTxn(() async {
        if (!merge) {
          await isar.customLists.clear();
        }
        await isar.customLists.putAll([
          ...animeCustomLists,
          ...mangaCustomLists,
          ...novelCustomLists,
        ]);
      });
    }

    if (options.settings.hasAnySelected) {
      final rawSettings = data['settings'];
      final List<Map<String, dynamic>> settingsList = [];
      if (rawSettings is List) {
        for (var item in rawSettings) {
          if (item is Map) {
            settingsList.add(Map<String, dynamic>.from(item));
          }
        }
      } else if (rawSettings is Map) {
        for (var entry in rawSettings.entries) {
          settingsList.add({
            'key': entry.key.toString(),
            'value': entry.value,
          });
        }
      }

      if (settingsList.isNotEmpty) {
        await isar.writeTxn(() async {
          for (var setting in settingsList) {
            final key = setting['key'] as String?;
            if (key == null) continue;

            final categoryName = setting['category'] as String?;
            final category = categoryName != null
                ? SettingCategory.values.firstWhere(
                    (c) => c.name == categoryName,
                    orElse: () => categorizeSettingKey(key),
                  )
                : categorizeSettingKey(key);

            bool shouldRestore = false;
            switch (category) {
              case SettingCategory.appearance:
                shouldRestore = options.settings.appearance;
                break;
              case SettingCategory.player:
                shouldRestore = options.settings.player;
                break;
              case SettingCategory.reader:
                shouldRestore = options.settings.reader;
                break;
              case SettingCategory.extensions:
                shouldRestore = options.settings.extensions;
                break;
              case SettingCategory.downloads:
                shouldRestore = options.settings.downloads;
                break;
              case SettingCategory.general:
                shouldRestore = options.settings.general;
                break;
              case SettingCategory.authTokens:
                shouldRestore = options.settings.authTokens;
                break;
            }

            if (!shouldRestore) continue;

            final kv = KeyValue()
              ..key = key
              ..value = setting['value'];
            await isar.collection<KeyValue>().put(kv);
          }
        });
      }
    }

    final hasStatsInData =
        data.containsKey('dailyActivities') || data.containsKey('mediaStats');
    if (options.stats && hasStatsInData) {
      final dailyList = (data['dailyActivities'] as List?)
              ?.map((e) => DailyActivityJson.fromJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [];

      final statsList = (data['mediaStats'] as List?)
              ?.map((e) => MediaStatsJson.fromJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [];

      await isar.writeTxn(() async {
        if (!merge) {
          await isar.dailyActivitys.clear();
          await isar.mediaStats.clear();
        }
        await isar.dailyActivitys.putAll(dailyList);
        await isar.mediaStats.putAll(statsList);
      });
    }

    if (options.extensionsData && data['kvEntries'] != null) {
      final kvEntriesData = data['kvEntries'] as List;
      final entries = kvEntriesData.map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        final entry = KvEntry();
        entry.key = map['key'] as String;
        entry.value = map['value'] as String;
        return entry;
      }).toList();

      await isar.writeTxn(() async {
        if (!merge) {
          await isar.kvEntrys.clear();
        }
        await isar.kvEntrys.putAll(entries);
      });
    }

    if (Get.isRegistered<LibraryController>()) {
      Get.delete<LibraryController>();
    }
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
    } catch (_) {
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

  bool _isZip(List<int> bytes) {
    return bytes.length >= 4 &&
        bytes[0] == 0x50 &&
        bytes[1] == 0x4B &&
        (bytes[2] == 0x03 || bytes[2] == 0x05);
  }

  bool _isEncryptedJson(String content) {
    try {
      final parsed = jsonDecode(content);
      return parsed is Map &&
          parsed.containsKey('iv') &&
          parsed.containsKey('data');
    } catch (_) {
      return false;
    }
  }

  Future<String?> exportBackupToExternal({
    String? password,
    bool requestPath = true,
    required BackupOptions options,
  }) async {
    try {
      if (Platform.isAndroid && requestPath) {
        final hasPermission = await _requestStoragePermission();
        if (!hasPermission) {
          Logger.i('Storage permission denied');
          throw Exception('Storage permission is required to save files');
        }
      }

      final data = await _buildBackupData(options: options);
      final packageInfo = await PackageInfo.fromPlatform();
      data['appVersion'] = packageInfo.version;

      final jsonString = password != null && password.isNotEmpty
          ? _encryptData(data, password)
          : jsonEncode(data);

      final archive = Archive();
      final dataBytes = utf8.encode(jsonString);
      archive.addFile(ArchiveFile('backup.json', dataBytes.length, dataBytes));

      final manifest = {
        'version': 2,
        'platform': Platform.operatingSystem,
        'date': DateTime.now().toIso8601String(),
        'isEncrypted': password != null && password.isNotEmpty,
        'hasRuntimeHost': options.runtimeHost,
        'hasExtensionFiles': options.extensionFiles,
        'hasExtensionsData': options.extensionsData,
      };
      final manifestBytes = utf8.encode(jsonEncode(manifest));
      archive.addFile(
          ArchiveFile('manifest.json', manifestBytes.length, manifestBytes));

      if (options.runtimeHost) {
        final hostInfo = await getRuntimeHostInfo();
        if (hostInfo.isInstalled) {
          final hostFile = File(hostInfo.filePath);
          if (await hostFile.exists()) {
            final hostBytes = await hostFile.readAsBytes();
            final fileName = Platform.isAndroid
                ? 'anymex_runtime_host.apk'
                : 'anymex_desktop_runtime.jar';
            archive.addFile(
                ArchiveFile('runtime/$fileName', hostBytes.length, hostBytes));

            final toolsDir = await RuntimePaths().toolsDir;
            final metaFile = File(p.join(toolsDir.path, 'metadata.json'));
            if (await metaFile.exists()) {
              final metaBytes = await metaFile.readAsBytes();
              archive.addFile(ArchiveFile(
                  'runtime/metadata.json', metaBytes.length, metaBytes));
            }
          }
        }
      }

      if (options.extensionFiles) {
        final extDir = await RuntimePaths().extensionsDir;
        if (await extDir.exists()) {
          await for (final entity
              in extDir.list(recursive: true, followLinks: false)) {
            if (entity is File) {
              final relPath = p.relative(entity.path, from: extDir.path);
              final fileBytes = await entity.readAsBytes();
              archive.addFile(ArchiveFile(
                  'extensions/$relPath', fileBytes.length, fileBytes));
            }
          }
        }
      }

      final zipBytes = ZipEncoder().encode(archive);
      if (zipBytes.isEmpty) {
        throw Exception('Failed to create backup archive');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'anymex_backup_$timestamp.anymex';

      String? outputPath;

      if (requestPath) {
        if (Platform.isIOS || Platform.isAndroid) {
          outputPath = await FilePicker.platform.saveFile(
            dialogTitle: 'Save Backup File',
            fileName: fileName,
            bytes: Uint8List.fromList(zipBytes),
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
          await outputFile.writeAsBytes(zipBytes, flush: true);

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
            await fallbackFile.writeAsBytes(zipBytes, flush: true);
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
          await fallbackFile.writeAsBytes(zipBytes, flush: true);
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

  Future<void> _restoreExtensionFiles(Archive archive) async {
    final extDir = await RuntimePaths().extensionsDir;
    for (final file in archive) {
      if (file.isFile && file.name.startsWith('extensions/')) {
        final relPath = file.name.substring('extensions/'.length);
        if (relPath.isEmpty) continue;
        final targetPath = p.join(extDir.path, relPath);
        final targetFile = File(targetPath);
        await targetFile.parent.create(recursive: true);
        await targetFile.writeAsBytes(file.content as List<int>, flush: true);
      }
    }
  }

  Future<bool> _restoreRuntimeHost(Archive archive) async {
    try {
      final paths = RuntimePaths();
      final toolsDir = await paths.toolsDir;

      if (Platform.isAndroid) {
        ArchiveFile? apkFile;
        for (final file in archive) {
          if (file.isFile && file.name.toLowerCase().endsWith('.apk')) {
            apkFile = file;
            break;
          }
        }
        if (apkFile != null) {
          final targetPath = await paths.bridgePath;
          final targetFile = File(targetPath);
          await targetFile.parent.create(recursive: true);
          await targetFile.writeAsBytes(apkFile.content as List<int>,
              flush: true);

          final metaFile = archive.findFile('runtime/metadata.json');
          if (metaFile != null) {
            final metaDest = File(p.join(toolsDir.path, 'metadata.json'));
            await metaDest.writeAsBytes(metaFile.content as List<int>,
                flush: true);
          }

          await AnymeXRuntimeBridge.loadMetadata();
          await AnymeXRuntimeBridge.useLocalApk(targetPath);
          return true;
        }
      } else {
        ArchiveFile? jarFile;
        for (final file in archive) {
          if (file.isFile && file.name.toLowerCase().endsWith('.jar')) {
            jarFile = file;
            break;
          }
        }
        if (jarFile != null) {
          final targetPath = await paths.bridgePath;
          final targetFile = File(targetPath);
          await targetFile.parent.create(recursive: true);
          await targetFile.writeAsBytes(jarFile.content as List<int>,
              flush: true);

          final metaFile = archive.findFile('runtime/metadata.json');
          if (metaFile != null) {
            final metaDest = File(p.join(toolsDir.path, 'metadata.json'));
            await metaDest.writeAsBytes(metaFile.content as List<int>,
                flush: true);
          }

          await AnymeXRuntimeBridge.loadMetadata();
          await AnymeXRuntimeBridge.checkAndInitialize();
          return true;
        }
      }
    } catch (e) {
      Logger.e('Failed to restore runtime host: $e');
    }
    return false;
  }

  Future<bool> restoreBackup(
    String filePath, {
    String? password,
    bool merge = false,
    required RestoreOptions options,
  }) async {
    try {
      final file = File(filePath);

      if (!await file.exists()) {
        throw Exception('Backup file not found');
      }

      final bytes = await file.readAsBytes();
      Map<String, dynamic> data;
      Archive? archive;

      if (_isZip(bytes)) {
        archive = ZipDecoder().decodeBytes(bytes);
        final backupFile = archive.findFile('backup.json');
        if (backupFile == null) {
          throw Exception('Corrupted backup archive: backup.json missing');
        }
        final content = utf8.decode(backupFile.content as List<int>);
        data = _isEncryptedJson(content)
            ? _decryptData(content, password ?? '')
            : jsonDecode(content) as Map<String, dynamic>;
      } else {
        final content = utf8.decode(bytes);
        data = _isEncryptedJson(content)
            ? _decryptData(content, password ?? '')
            : jsonDecode(content) as Map<String, dynamic>;
      }

      await _applyBackupData(data, merge: merge, options: options);

      if (archive != null && options.extensionFiles) {
        await _restoreExtensionFiles(archive);
      }

      if (archive != null && options.runtimeHost) {
        await _restoreRuntimeHost(archive);
      }

      if (options.extensionsData || options.extensionFiles) {
        try {
          if (Get.isRegistered<ExtensionManager>()) {
            await Get.find<ExtensionManager>()
                .onRuntimeBridgeInitialization(force: true);
          }
        } catch (e) {
          Logger.e('Failed to re-initialize ExtensionManager: $e');
        }
      }

      final hostInfo = await getRuntimeHostInfo();
      final hasAnyExtensionRestored =
          (data['kvEntries'] != null && (data['kvEntries'] as List).isNotEmpty) ||
          (archive != null && options.extensionFiles);
      final needsRuntimePrompt =
          hasAnyExtensionRestored && !hostInfo.isInstalled;

      Logger.i('Backup restored successfully from: $filePath');
      return needsRuntimePrompt;
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

  Future<Map<String, dynamic>?> getBackupInfo(
    String filePath, {
    String? password,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      Map<String, dynamic> data;
      bool hasRuntimeInArchive = false;
      String runtimePlatform = '';
      int runtimeSize = 0;
      bool hasExtensionFilesInArchive = false;
      int extFileCount = 0;
      int extFileSize = 0;

      if (_isZip(bytes)) {
        final archive = ZipDecoder().decodeBytes(bytes);
        final backupFile = archive.findFile('backup.json');
        if (backupFile == null) return null;

        final content = utf8.decode(backupFile.content as List<int>);
        data = _isEncryptedJson(content)
            ? _decryptData(content, password ?? '')
            : jsonDecode(content) as Map<String, dynamic>;

        for (final f in archive) {
          if (!f.isFile) continue;
          if (f.name.startsWith('runtime/')) {
            if (f.name.endsWith('.jar') || f.name.endsWith('.apk')) {
              hasRuntimeInArchive = true;
              runtimeSize = f.size;
              runtimePlatform = f.name.endsWith('.apk') ? 'android' : 'desktop';
            }
          } else if (f.name.startsWith('extensions/')) {
            hasExtensionFilesInArchive = true;
            extFileCount++;
            extFileSize += f.size;
          }
        }
      } else {
        final content = utf8.decode(bytes);
        data = _isEncryptedJson(content)
            ? _decryptData(content, password ?? '')
            : jsonDecode(content) as Map<String, dynamic>;
      }

      final animeCount = data['animeCount'] ??
          (data['animeLibrary'] as List?)?.length ??
          0;
      final mangaCount = data['mangaCount'] ??
          (data['mangaLibrary'] as List?)?.length ??
          0;
      final novelCount = data['novelCount'] ??
          (data['novelLibrary'] as List?)?.length ??
          0;

      final animeCustomListsCount =
          (data['animeCustomLists'] as List?)?.length ?? 0;
      final mangaCustomListsCount =
          (data['mangaCustomLists'] as List?)?.length ?? 0;
      final novelCustomListsCount =
          (data['novelCustomLists'] as List?)?.length ?? 0;

      final hasAnime = (data['hasAnime'] == true) ||
          ((data['animeLibrary'] as List?)?.isNotEmpty ?? false);
      final hasManga = (data['hasManga'] == true) ||
          ((data['mangaLibrary'] as List?)?.isNotEmpty ?? false);
      final hasNovel = (data['hasNovel'] == true) ||
          ((data['novelLibrary'] as List?)?.isNotEmpty ?? false);
      final hasCustomLists = (data['hasCustomLists'] == true) ||
          (animeCustomListsCount +
                  mangaCustomListsCount +
                  novelCustomListsCount) >
              0;

      final rawSettings = data['settings'];
      final List<Map<String, dynamic>> settings = [];
      if (rawSettings is List) {
        for (var item in rawSettings) {
          if (item is Map) {
            settings.add(Map<String, dynamic>.from(item));
          }
        }
      } else if (rawSettings is Map) {
        for (var entry in rawSettings.entries) {
          settings.add({
            'key': entry.key.toString(),
            'value': entry.value,
          });
        }
      }

      final hasAppearance = (data['hasAppearance'] == true) ||
          settings.any((e) =>
              categorizeSettingKey(e['key'] as String? ?? '') ==
              SettingCategory.appearance);
      final hasPlayer = (data['hasPlayer'] == true) ||
          settings.any((e) =>
              categorizeSettingKey(e['key'] as String? ?? '') ==
              SettingCategory.player);
      final hasReader = (data['hasReader'] == true) ||
          settings.any((e) =>
              categorizeSettingKey(e['key'] as String? ?? '') ==
              SettingCategory.reader);
      final hasExtSettings = (data['hasExtSettings'] == true) ||
          settings.any((e) =>
              categorizeSettingKey(e['key'] as String? ?? '') ==
              SettingCategory.extensions);
      final hasDownloadSettings = (data['hasDownloadSettings'] == true) ||
          settings.any((e) =>
              categorizeSettingKey(e['key'] as String? ?? '') ==
              SettingCategory.downloads);
      final hasGeneralSettings = (data['hasGeneralSettings'] == true) ||
          settings.any((e) =>
              categorizeSettingKey(e['key'] as String? ?? '') ==
              SettingCategory.general);
      final hasAuthTokens = (data['hasAuthTokens'] == true) ||
          settings.any((e) =>
              categorizeSettingKey(e['key'] as String? ?? '') ==
              SettingCategory.authTokens);
      final hasSettings = hasAppearance ||
          hasPlayer ||
          hasReader ||
          hasExtSettings ||
          hasDownloadSettings ||
          hasGeneralSettings ||
          hasAuthTokens ||
          (data['hasSettings'] == true);

      final dailyList = data['dailyActivities'] as List? ?? [];
      final mediaStatsList = data['mediaStats'] as List? ?? [];
      final hasStats = (data['hasStats'] == true) ||
          dailyList.isNotEmpty ||
          mediaStatsList.isNotEmpty;

      final kvEntries = data['kvEntries'] as List? ?? [];
      final hasExtensionsData =
          (data['hasExtensionsData'] == true) || kvEntries.isNotEmpty;

      return {
        'date': data['date'] ?? 'Unknown Date',
        'username': data['username'] ?? 'User',
        'avatar': data['avatar'],
        'appVersion': data['appVersion'] ?? 'Unknown',
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
        'animeCustomListsCount': animeCustomListsCount,
        'mangaCustomListsCount': mangaCustomListsCount,
        'novelCustomListsCount': novelCustomListsCount,
        'hasAnime': hasAnime,
        'hasManga': hasManga,
        'hasNovel': hasNovel,
        'hasCustomLists': hasCustomLists,
        'hasSettings': hasSettings,
        'hasAppearance': hasAppearance,
        'hasPlayer': hasPlayer,
        'hasReader': hasReader,
        'hasExtSettings': hasExtSettings,
        'hasDownloadSettings': hasDownloadSettings,
        'hasGeneralSettings': hasGeneralSettings,
        'hasAuthTokens': hasAuthTokens,
        'hasStats': hasStats,
        'hasExtensionsData': hasExtensionsData,
        'extensionsDataCount': kvEntries.length,
        'hasExtensionFiles': hasExtensionFilesInArchive,
        'extensionFilesCount': extFileCount,
        'extensionFilesSize': extFileSize,
        'hasRuntimeHost': hasRuntimeInArchive,
        'runtimeHostPlatform': runtimePlatform.isNotEmpty
            ? runtimePlatform
            : (data['runtimeHostPlatform'] ?? ''),
        'runtimeHostSize': runtimeSize,
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

      final bytes = await file.readAsBytes();
      if (_isZip(bytes)) {
        final archive = ZipDecoder().decodeBytes(bytes);
        final manifestFile = archive.findFile('manifest.json');
        if (manifestFile != null) {
          final content = utf8.decode(manifestFile.content as List<int>);
          final manifest = jsonDecode(content);
          if (manifest is Map && manifest['isEncrypted'] == true) {
            return true;
          }
        }

        final backupFile = archive.findFile('backup.json');
        if (backupFile != null) {
          final content = utf8.decode(backupFile.content as List<int>);
          return _isEncryptedJson(content);
        }
        return false;
      } else {
        final content = utf8.decode(bytes);
        return _isEncryptedJson(content);
      }
    } catch (_) {
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

    final animeLibrary = await _storageController.getAnimeLibrary();
    final mangaLibrary = await _storageController.getMangaLibrary();
    final novelLibrary = await _storageController.getNovelLibrary();

    final animeCount = animeLibrary.length;
    final mangaCount = mangaLibrary.length;
    final novelCount = novelLibrary.length;

    return {
      'animeCount': animeCount,
      'mangaCount': mangaCount,
      'novelCount': novelCount,
      'totalMedia': animeCount + mangaCount + novelCount,
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

