import 'dart:convert';
import 'dart:io';

import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/database/isar_models/custom_list.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:anymex/database/isar_models/key_value.dart';
import 'package:anymex/database/isar_models/daily_activity.dart';
import 'package:anymex/database/isar_models/media_stats.dart';
import 'package:anymex/main.dart';
import 'package:anymex/screens/library/controller/library_controller.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:get/get.dart';
import 'package:isar_community/isar.dart';

import 'package:package_info_plus/package_info_plus.dart';

import 'cloud_sync_provider.dart';
import 'webdav_provider.dart';

import 'package:flutter/widgets.dart';

enum CloudSyncStatus { idle, syncing, success, error }

class CloudSyncController extends GetxController with WidgetsBindingObserver {
  static const String syncFileName = 'anymex_cloud_sync.json.gz';
  static const int syncSchemaVersion = 1;

  final selectedProvider = 'webdav'.obs;

  // WebDAV credentials
  final webdavUrl = ''.obs;
  final webdavUsername = ''.obs;
  final webdavPassword = ''.obs;

  // Sync state
  final isConnected = false.obs;
  final syncStatus = CloudSyncStatus.idle.obs;
  final isBusy = false.obs;
  final statusMessage = ''.obs;
  final lastSyncTime = Rx<DateTime?>(null);

  // Sync settings
  final autoSyncOnLaunch = true.obs;
  final autoSyncOnExit = true.obs;
  final syncLibrary = true.obs;
  final syncHistory = true.obs;
  final syncSettings = true.obs;
  final syncStats = false.obs;

  CloudSyncProvider? _activeProvider;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _loadPreferences();

    // Auto-sync on launch in background without blocking app startup
    Future.delayed(const Duration(seconds: 3), () {
      if (isConnected.value && autoSyncOnLaunch.value && !isBusy.value) {
        syncNow(userInitiated: false);
      }
    });
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      if (isConnected.value && autoSyncOnExit.value && !isBusy.value) {
        syncNow(userInitiated: false);
      }
    }
  }

  void _loadPreferences() {
    try {
      selectedProvider.value =
          getVal<String>(CloudSyncKeys.provider.name) ?? 'webdav';

      webdavUrl.value =
          getVal<String>(CloudSyncKeys.webdavUrl.name) ?? '';
      webdavUsername.value =
          getVal<String>(CloudSyncKeys.webdavUsername.name) ?? '';
      webdavPassword.value =
          getVal<String>(CloudSyncKeys.webdavPassword.name) ?? '';

      autoSyncOnLaunch.value =
          getVal<bool>(CloudSyncKeys.autoSyncOnLaunch.name) ?? true;
      autoSyncOnExit.value =
          getVal<bool>(CloudSyncKeys.autoSyncOnExit.name) ?? true;

      syncLibrary.value =
          getVal<bool>(CloudSyncKeys.syncLibrary.name) ?? true;
      syncHistory.value =
          getVal<bool>(CloudSyncKeys.syncHistory.name) ?? true;
      syncSettings.value =
          getVal<bool>(CloudSyncKeys.syncSettings.name) ?? true;
      syncStats.value =
          getVal<bool>(CloudSyncKeys.syncStats.name) ?? false;

      final lastTimeStr =
          getVal<String>(CloudSyncKeys.lastSyncTime.name);
      if (lastTimeStr != null && lastTimeStr.isNotEmpty) {
        lastSyncTime.value = DateTime.tryParse(lastTimeStr);
      }

      if (webdavUrl.value.isNotEmpty &&
          webdavUsername.value.isNotEmpty &&
          webdavPassword.value.isNotEmpty) {
        _rebuildProvider();
        isConnected.value = true;
      }
    } catch (e) {
      Logger.w('CloudSyncController: failed to load preferences: $e');
    }
  }

  void _rebuildProvider() {
    if (selectedProvider.value == 'webdav') {
      _activeProvider = WebDavProvider(
        serverUrl: webdavUrl.value,
        username: webdavUsername.value,
        password: webdavPassword.value,
      );
    }
  }

  Future<bool> saveWebDavConfig({
    required String url,
    required String username,
    required String password,
  }) async {
    isBusy.value = true;
    statusMessage.value = 'Connecting to WebDAV...';

    final tempProvider = WebDavProvider(
      serverUrl: url,
      username: username,
      password: password,
    );

    final success = await tempProvider.testConnection();
    isBusy.value = false;

    if (success) {
      webdavUrl.value = url;
      webdavUsername.value = username;
      webdavPassword.value = password;
      _activeProvider = tempProvider;
      isConnected.value = true;

      setVal(CloudSyncKeys.webdavUrl.name, url);
      setVal(CloudSyncKeys.webdavUsername.name, username);
      setVal(CloudSyncKeys.webdavPassword.name, password);
      setVal(CloudSyncKeys.provider.name, 'webdav');

      statusMessage.value = 'Connected successfully';
      snackBar('WebDAV connected successfully!');
      return true;
    } else {
      statusMessage.value = 'Failed to connect. Check URL & credentials.';
      errorSnackBar('WebDAV connection failed. Please verify credentials.');
      return false;
    }
  }

  Future<void> disconnect() async {
    _activeProvider = null;
    isConnected.value = false;
    webdavUrl.value = '';
    webdavUsername.value = '';
    webdavPassword.value = '';

    setVal(CloudSyncKeys.webdavUrl.name, '');
    setVal(CloudSyncKeys.webdavUsername.name, '');
    setVal(CloudSyncKeys.webdavPassword.name, '');
    statusMessage.value = 'Disconnected';
    snackBar('Cloud sync disconnected');
  }

  Future<bool> testCurrentConnection() async {
    if (_activeProvider == null) {
      _rebuildProvider();
    }
    if (_activeProvider == null) {
      errorSnackBar('No provider configured');
      return false;
    }

    isBusy.value = true;
    statusMessage.value = 'Testing connection...';
    final success = await _activeProvider!.testConnection();
    isBusy.value = false;

    isConnected.value = success;
    if (success) {
      statusMessage.value = 'Connection healthy';
      snackBar('Connection verified!');
    } else {
      statusMessage.value = 'Connection failed';
      errorSnackBar('Could not reach cloud storage');
    }
    return success;
  }

  Future<void> syncNow({bool userInitiated = true}) async {
    if (!isConnected.value || _activeProvider == null) {
      _rebuildProvider();
      if (_activeProvider == null) {
        if (userInitiated) errorSnackBar('Configure cloud sync first');
        return;
      }
    }

    if (isBusy.value) return;

    try {
      isBusy.value = true;
      syncStatus.value = CloudSyncStatus.syncing;
      statusMessage.value = 'Syncing with cloud...';

      // 1. Gather local state
      final localData = await _buildLocalPayload();

      // 2. Check remote metadata
      final remoteMeta = await _activeProvider!.getFileMetadata(syncFileName);

      if (remoteMeta == null) {
        // First time sync: simply upload local state
        final compressed = gzip.encode(utf8.encode(jsonEncode(localData)));
        await _activeProvider!.uploadFile(syncFileName, compressed);
      } else {
        // Download remote state and merge
        final remoteBytes = await _activeProvider!.downloadFile(syncFileName);
        if (remoteBytes != null && remoteBytes.isNotEmpty) {
          final decompressed = utf8.decode(gzip.decode(remoteBytes));
          final remoteData = jsonDecode(decompressed) as Map<String, dynamic>;

          // Smart merge remote into local Isar
          await _mergeRemoteIntoLocal(remoteData);

          // Build updated merged payload to upload back to cloud
          final mergedData = await _buildLocalPayload();
          final mergedCompressed =
              gzip.encode(utf8.encode(jsonEncode(mergedData)));
          await _activeProvider!.uploadFile(syncFileName, mergedCompressed);
        } else {
          final compressed = gzip.encode(utf8.encode(jsonEncode(localData)));
          await _activeProvider!.uploadFile(syncFileName, compressed);
        }
      }

      final now = DateTime.now();
      lastSyncTime.value = now;
      setVal(CloudSyncKeys.lastSyncTime.name, now.toIso8601String());

      syncStatus.value = CloudSyncStatus.success;
      statusMessage.value = 'Synced at ${_formatTime(now)}';

      if (userInitiated) {
        snackBar('Cloud sync completed successfully!');
      }

      // Refresh UI controllers
      if (Get.isRegistered<OfflineStorageController>()) {
        Get.find<OfflineStorageController>().init();
      }
      if (Get.isRegistered<LibraryController>()) {
        Get.delete<LibraryController>();
      }
    } catch (e, stack) {
      Logger.e('CloudSync error: $e\n$stack');
      syncStatus.value = CloudSyncStatus.error;
      statusMessage.value = 'Sync error: $e';
      if (userInitiated) {
        errorSnackBar('Sync failed: ${e.toString().split('\n').first}');
      }
    } finally {
      isBusy.value = false;
    }
  }

  Future<Map<String, dynamic>> _buildLocalPayload() async {
    final animeList = syncLibrary.value
        ? await isar.offlineMedias
            .filter()
            .mediaTypeIndexEqualTo(1)
            .findAll()
        : <OfflineMedia>[];

    final mangaList = syncLibrary.value
        ? await isar.offlineMedias
            .filter()
            .mediaTypeIndexEqualTo(0)
            .findAll()
        : <OfflineMedia>[];

    final novelList = syncLibrary.value
        ? await isar.offlineMedias
            .filter()
            .mediaTypeIndexEqualTo(2)
            .findAll()
        : <OfflineMedia>[];

    final customLists = syncLibrary.value
        ? await isar.customLists.where().findAll()
        : <CustomList>[];

    // Safely gather settings (excluding any auth tokens or sessions)
    final settingsList = syncSettings.value
        ? isar
            .collection<KeyValue>()
            .where()
            .findAllSync()
            .where((e) {
              final lower = e.key.toLowerCase();
              return !e.key.startsWith('AuthKeys_') &&
                  !lower.contains('token') &&
                  !lower.contains('auth') &&
                  !lower.contains('session');
            })
            .map((e) => {'key': e.key, 'value': e.value})
            .toList()
        : <Map<String, dynamic>>[];

    // Gather daily activity and stats
    final dailyActivities = syncStats.value
        ? isar.dailyActivitys.where().findAllSync().map((e) => {
              'date': e.date.toIso8601String(),
              'watchTimeMinutes': e.watchTimeMinutes,
              'readTimeMinutes': e.readTimeMinutes,
              'episodesWatched': e.episodesWatched,
              'chaptersRead': e.chaptersRead,
              'activeMediaIds': e.activeMediaIds,
            }).toList()
        : <Map<String, dynamic>>[];

    final mediaStats = syncStats.value
        ? isar.mediaStats.where().findAllSync().map((e) => {
              'mediaId': e.mediaId,
              'title': e.title,
              'type': e.type,
              'poster': e.poster,
              'cover': e.cover,
              'totalTimeMinutes': e.totalTimeMinutes,
              'totalUnitsConsumed': e.totalUnitsConsumed,
              'lastInteracted': e.lastInteracted.toIso8601String(),
              'interactionCount': e.interactionCount,
            }).toList()
        : <Map<String, dynamic>>[];

    final packageInfo = await PackageInfo.fromPlatform();

    return {
      'schemaVersion': syncSchemaVersion,
      'appVersion': packageInfo.version,
      'platform': Platform.operatingSystem,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'anime': animeList.map((e) => e.toJson()).toList(),
      'manga': mangaList.map((e) => e.toJson()).toList(),
      'novel': novelList.map((e) => e.toJson()).toList(),
      'customLists': customLists.map((e) => e.toJson()).toList(),
      'settings': settingsList,
      'dailyActivities': dailyActivities,
      'mediaStats': mediaStats,
    };
  }

  Future<void> _mergeRemoteIntoLocal(Map<String, dynamic> remoteData) async {
    await isar.writeTxn(() async {
      // 1. Merge Anime
      if (remoteData['anime'] is List && syncLibrary.value) {
        await _mergeMediaList(
          (remoteData['anime'] as List)
              .map((e) => OfflineMedia.fromJson(
                  (Map<String, dynamic>.from(e as Map))..['mediaTypeIndex'] = 1))
              .toList(),
          1,
        );
      }

      // 2. Merge Manga
      if (remoteData['manga'] is List && syncLibrary.value) {
        await _mergeMediaList(
          (remoteData['manga'] as List)
              .map((e) => OfflineMedia.fromJson(
                  (Map<String, dynamic>.from(e as Map))..['mediaTypeIndex'] = 0))
              .toList(),
          0,
        );
      }

      // 3. Merge Novel
      if (remoteData['novel'] is List && syncLibrary.value) {
        await _mergeMediaList(
          (remoteData['novel'] as List)
              .map((e) => OfflineMedia.fromJson(
                  (Map<String, dynamic>.from(e as Map))..['mediaTypeIndex'] = 2))
              .toList(),
          2,
        );
      }

      // 4. Merge Custom Lists
      if (remoteData['customLists'] is List && syncLibrary.value) {
        final remoteLists = (remoteData['customLists'] as List)
            .map((e) => CustomList.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();

        final localLists = await isar.customLists.where().findAll();
        final localNames = localLists.map((e) => e.listName).toSet();

        for (final rList in remoteLists) {
          if (!localNames.contains(rList.listName)) {
            await isar.customLists.put(rList);
          }
        }
      }

      // 5. Merge Settings
      if (remoteData['settings'] is List && syncSettings.value) {
        final remoteSettings = remoteData['settings'] as List;
        for (final item in remoteSettings) {
          if (item is Map) {
            final key = item['key'] as String?;
            final val = item['value'] as String?;
            if (key != null && val != null) {
              final lower = key.toLowerCase();
              if (!key.startsWith('AuthKeys_') &&
                  !lower.contains('token') &&
                  !lower.contains('auth')) {
                final kv = KeyValue()
                  ..key = key
                  ..value = val;
                await isar.collection<KeyValue>().put(kv);
              }
            }
          }
        }
      }

      // 6. Merge Stats
      if (remoteData['dailyActivities'] is List && syncStats.value) {
        final remoteActivities = remoteData['dailyActivities'] as List;
        for (final item in remoteActivities) {
          if (item is Map) {
            final dtStr = item['date'] as String?;
            if (dtStr != null) {
              final dt = DateTime.tryParse(dtStr);
              if (dt != null) {
                final act = DailyActivity()
                  ..date = dt
                  ..watchTimeMinutes = item['watchTimeMinutes'] as int? ?? 0
                  ..readTimeMinutes = item['readTimeMinutes'] as int? ?? 0
                  ..episodesWatched = item['episodesWatched'] as int? ?? 0
                  ..chaptersRead = item['chaptersRead'] as int? ?? 0
                  ..activeMediaIds =
                      (item['activeMediaIds'] as List?)?.cast<String>() ?? [];
                await isar.dailyActivitys.put(act);
              }
            }
          }
        }
      }
    });
  }

  Future<void> _mergeMediaList(
      List<OfflineMedia> remoteList, int mediaTypeIndex) async {
    final localList = await isar.offlineMedias
        .filter()
        .mediaTypeIndexEqualTo(mediaTypeIndex)
        .findAll();

    final localMap = {for (final m in localList) m.mediaId: m};

    for (final remoteMedia in remoteList) {
      final key = remoteMedia.mediaId;
      if (key == null) continue;

      if (!localMap.containsKey(key)) {
        // Item exists on remote but not locally -> Add to local library
        await isar.offlineMedias.put(remoteMedia);
      } else {
        // Item exists in both -> Merge history / progress
        final local = localMap[key]!;
        bool modified = false;

        // Episode progress comparison
        if (remoteMedia.currentEpisode != null) {
          final remoteWatched =
              remoteMedia.currentEpisode?.lastWatchedTime ?? 0;
          final localWatched = local.currentEpisode?.lastWatchedTime ?? 0;

          if (remoteWatched > localWatched) {
            local.currentEpisode = remoteMedia.currentEpisode;
            modified = true;
          }
        }

        // Chapter progress comparison
        if (remoteMedia.currentChapter != null) {
          final remoteChapterTime =
              remoteMedia.currentChapter?.lastReadTime ?? 0;
          final localChapterTime =
              local.currentChapter?.lastReadTime ?? 0;

          if (remoteChapterTime > localChapterTime) {
            local.currentChapter = remoteMedia.currentChapter;
            modified = true;
          }
        }

        // Combine episodes list
        if (remoteMedia.episodes != null && remoteMedia.episodes!.isNotEmpty) {
          final existingEpNumbers =
              local.episodes?.map((e) => e.number).toSet() ?? <String>{};
          final newEps = remoteMedia.episodes!
              .where((e) => !existingEpNumbers.contains(e.number))
              .toList();
          if (newEps.isNotEmpty) {
            local.episodes = [...(local.episodes ?? []), ...newEps];
            modified = true;
          }
        }

        if (modified) {
          await isar.offlineMedias.put(local);
        }
      }
    }
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
