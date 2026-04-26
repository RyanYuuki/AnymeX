import 'dart:async';
import 'dart:convert';

import 'package:anymex/controllers/profile/profile_manager.dart';
import 'package:anymex/controllers/services/cloud/cloud_auth_service.dart';
import 'package:anymex/controllers/services/cloud/cloud_profile_service.dart';
import 'package:anymex/database/isar_models/custom_list.dart';
import 'package:anymex/database/isar_models/key_value.dart';
import 'package:anymex/database/kv_helper.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:anymex/database/isar_models/episode.dart';
import 'package:anymex/database/isar_models/chapter.dart';
import 'package:anymex/main.dart';
import 'package:anymex/utils/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:isar_community/isar.dart';

class CloudSyncService extends GetxController with WidgetsBindingObserver {
  CloudAuthService get _auth => Get.find<CloudAuthService>();

  String get _functionsUrl {
    final envBase =
        (dotenv.env['CLOUD_BASE_URL'] ?? dotenv.env['COMMENTS_BASE_URL'] ?? '')
            .trim();
    if (envBase.isEmpty) return '';
    final base = envBase.endsWith('/')
        ? envBase.substring(0, envBase.length - 1)
        : envBase;
    if (base.endsWith('/functions/v1')) return base;
    return '$base/functions/v1';
  }

  RxBool isSyncing = false.obs;
  RxString syncStatus = ''.obs;
  RxBool autoSyncEnabled = true.obs;

  static const _kAutoSyncKey = '__cloud_auto_sync__';

  static const _itemDebounce = Duration(seconds: 10);
  final Map<String, Timer> _itemSyncTimers = {};
  final Set<String> _pendingMediaIds = {};
  Timer? _settingsSyncTimer;
  Timer? _listSyncTimer;
  Timer? _watchHistorySyncTimer;
  Timer? _continueWatchingSyncTimer;
  DateTime? _lastPull;
  static const _minPullInterval = Duration(seconds: 30);

  static const _kInitialSyncKey = '__cloud_initial_sync_done__';

  // ---------------------------------------------------------------------------
  // Profile ID mapping: local ↔ cloud
  // ---------------------------------------------------------------------------

  String? _getCloudProfileId(String localProfileId) {
    try {
      final col = isar.collection<KeyValue>();
      final result = col
          .filter()
          .keyEqualTo('__cloud_profile_map__$localProfileId')
          .findFirstSync();
      if (result?.value == null) return null;
      final data = jsonDecode(result!.value!);
      return data['cloud_id'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Public accessor for cloud profile ID mapping.
  /// Returns the cloud UUID for a given local profile ID, or null if unmapped.
  String? getCloudProfileId(String localProfileId) =>
      _getCloudProfileId(localProfileId);

  void _setCloudProfileId(String localProfileId, String cloudProfileId) {
    try {
      final kv = KeyValue()
        ..key = '__cloud_profile_map__$localProfileId'
        ..value = jsonEncode({'cloud_id': cloudProfileId});
      isar.writeTxnSync(() => isar.collection<KeyValue>().putSync(kv));
    } catch (e) {
      Logger.i('Error saving cloud profile map: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Version tracking helpers
  // ---------------------------------------------------------------------------

  static const _kVersionPrefix = '__cloud_version__';

  int? _getLocalVersion(String resource) {
    try {
      final col = isar.collection<KeyValue>();
      final result =
          col.filter().keyEqualTo('$_kVersionPrefix$resource').findFirstSync();
      if (result?.value == null) return null;
      final data = jsonDecode(result!.value!);
      return data['val'] as int?;
    } catch (_) {
      return null;
    }
  }

  void _setLocalVersion(String resource, int version) {
    try {
      final kv = KeyValue()
        ..key = '$_kVersionPrefix$resource'
        ..value = jsonEncode({'val': version});
      isar.writeTxnSync(() => isar.collection<KeyValue>().putSync(kv));
    } catch (e) {
      Logger.i('Error saving version for $resource: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _loadAutoSync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _pullOnResume();
    }
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      _flushOnPause();
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final timer in _itemSyncTimers.values) {
      timer.cancel();
    }
    _itemSyncTimers.clear();
    _settingsSyncTimer?.cancel();
    _listSyncTimer?.cancel();
    _watchHistorySyncTimer?.cancel();
    _continueWatchingSyncTimer?.cancel();
    super.onClose();
  }

  void _loadAutoSync() {
    try {
      final col = isar.collection<KeyValue>();
      final result =
          col.filter().keyEqualTo(_kAutoSyncKey).findFirstSync();
      if (result?.value != null) {
        final data = jsonDecode(result!.value!);
        autoSyncEnabled.value = data['val'] != false;
      }
    } catch (_) {
      autoSyncEnabled.value = true;
    }
  }

  void setAutoSync(bool enabled) {
    autoSyncEnabled.value = enabled;
    try {
      final kv = KeyValue()
        ..key = _kAutoSyncKey
        ..value = jsonEncode({'val': enabled});
      isar.writeTxnSync(() => isar.collection<KeyValue>().putSync(kv));
    } catch (e) {
      Logger.i('Error saving auto-sync pref: $e');
    }
  }

  Future<void> _pullOnResume() async {
    if (!_auth.isCloudMode || !autoSyncEnabled.value) return;
    if (_lastPull != null &&
        DateTime.now().difference(_lastPull!) < _minPullInterval) {
      return;
    }
    try {
      final manager = Get.find<ProfileManager>();
      final profileId = manager.currentProfileId.value;
      if (profileId.isEmpty) return;
      await _pushDirtyThenPull(profileId);
    } catch (e) {
      Logger.i('Pull on resume error: $e');
    }
  }

  Future<void> _flushOnPause() async {
    if (!_auth.isCloudMode || !autoSyncEnabled.value) return;
    await flushPendingSyncs();
  }

  // ---------------------------------------------------------------------------
  // Initial sync tracking per profile
  // ---------------------------------------------------------------------------

  Future<bool> hasEverSynced(String profileId) async {
    try {
      final key = '${profileId}_$_kInitialSyncKey';
      final col = isar.collection<KeyValue>();
      final result = await col.filter().keyEqualTo(key).findFirst();
      if (result?.value == null) return false;
      final data = jsonDecode(result!.value!);
      return data['val'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> markSynced(String profileId) async {
    try {
      final key = '${profileId}_$_kInitialSyncKey';
      final kv = KeyValue()
        ..key = key
        ..value = jsonEncode({'val': true});
      await isar.writeTxn(() => isar.collection<KeyValue>().put(kv));
    } catch (e) {
      Logger.i('Error marking profile synced: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Debounced scheduling
  // ---------------------------------------------------------------------------

  void scheduleItemSync(String mediaId, int mediaTypeIndex) {
    if (!_auth.isCloudMode || !autoSyncEnabled.value) return;
    _pendingMediaIds.add(mediaId);
    _itemSyncTimers[mediaId]?.cancel();
    _itemSyncTimers[mediaId] = Timer(_itemDebounce, () async {
      await _pushItemFromDb(mediaId);
      _pendingMediaIds.remove(mediaId);
      _itemSyncTimers.remove(mediaId);
    });
  }

  void scheduleSettingsSync() {
    if (!_auth.isCloudMode || !autoSyncEnabled.value) return;
    _settingsSyncTimer?.cancel();
    _settingsSyncTimer = Timer(_itemDebounce, () async {
      await _pushSettingsOnly();
      _settingsSyncTimer = null;
    });
  }

  void scheduleListSync(String mediaType) {
    if (!_auth.isCloudMode || !autoSyncEnabled.value) return;
    _listSyncTimer?.cancel();
    _listSyncTimer = Timer(_itemDebounce, () async {
      await _pushListFromDb(mediaType);
      _listSyncTimer = null;
    });
  }

  void scheduleWatchHistorySync() {
    if (!_auth.isCloudMode || !autoSyncEnabled.value) return;
    _watchHistorySyncTimer?.cancel();
    _watchHistorySyncTimer = Timer(_itemDebounce, () async {
      await _pushWatchHistoryFromDb();
      _watchHistorySyncTimer = null;
    });
  }

  void scheduleContinueWatchingSync() {
    if (!_auth.isCloudMode || !autoSyncEnabled.value) return;
    _continueWatchingSyncTimer?.cancel();
    _continueWatchingSyncTimer = Timer(_itemDebounce, () async {
      await _pushContinueWatchingFromDb();
      _continueWatchingSyncTimer = null;
    });
  }

  // ---------------------------------------------------------------------------
  // Flush / push helpers (internal)
  // ---------------------------------------------------------------------------

  Future<void> flushPendingSyncs() async {
    for (final timer in _itemSyncTimers.values) {
      timer.cancel();
    }
    _itemSyncTimers.clear();
    _settingsSyncTimer?.cancel();
    _settingsSyncTimer = null;
    _listSyncTimer?.cancel();
    _listSyncTimer = null;
    _watchHistorySyncTimer?.cancel();
    _watchHistorySyncTimer = null;
    _continueWatchingSyncTimer?.cancel();
    _continueWatchingSyncTimer = null;

    if (!_auth.isCloudMode) return;

    try {
      final manager = Get.find<ProfileManager>();
      final localProfileId = manager.currentProfileId.value;
      if (localProfileId.isEmpty) return;
      final cloudId = _getCloudProfileId(localProfileId) ?? localProfileId;
      if (cloudId.isEmpty) return;

      // If there's nothing pending and nothing dirty, skip
      if (_pendingMediaIds.isEmpty) return;

      final mediaTypeMap = {0: 'manga', 1: 'anime', 2: 'novel'};
      final grouped = <String, List<String>>{
        'anime': [],
        'manga': [],
        'novel': []
      };

      for (final mediaId in _pendingMediaIds) {
        final item = await isar.offlineMedias
            .filter()
            .mediaIdEqualTo(mediaId)
            .and()
            .profileIdEqualTo(localProfileId)
            .findFirst();
        if (item != null) {
          final type = mediaTypeMap[item.mediaTypeIndex] ?? 'anime';
          grouped[type]!.add(mediaId);
        }
      }

      for (final entry in grouped.entries) {
        final mediaIds = entry.value;
        if (mediaIds.isEmpty) continue;
        final items = await isar.offlineMedias
            .filter()
            .anyOf(mediaIds, (q, id) => q.mediaIdEqualTo(id))
            .and()
            .profileIdEqualTo(localProfileId)
            .findAll();
        if (items.isNotEmpty) {
          await pushLibrary(cloudId, entry.key, items);
        }
      }

      _pendingMediaIds.clear();
    } catch (e) {
      Logger.i('Flush pending syncs error: $e');
    }
  }

  Future<void> _pushItemFromDb(String mediaId) async {
    try {
      final manager = Get.find<ProfileManager>();
      final localProfileId = manager.currentProfileId.value;
      if (localProfileId.isEmpty) return;
      final cloudId = _getCloudProfileId(localProfileId) ?? localProfileId;
      if (cloudId.isEmpty) return;

      final item = await isar.offlineMedias
          .filter()
          .mediaIdEqualTo(mediaId)
          .and()
          .profileIdEqualTo(localProfileId)
          .findFirst();

      if (item == null) return;

      final mediaTypeMap = {0: 'manga', 1: 'anime', 2: 'novel'};
      final mediaType = mediaTypeMap[item.mediaTypeIndex] ?? 'anime';
      await pushLibrary(cloudId, mediaType, [item]);

      // Also sync watch history & continue watching since library changed
      await _pushWatchHistoryFromDb();
      await _pushContinueWatchingFromDb();
    } catch (e) {
      Logger.i('Push single item error: $e');
    }
  }

  Future<void> _pushListFromDb(String mediaType) async {
    try {
      final manager = Get.find<ProfileManager>();
      final localProfileId = manager.currentProfileId.value;
      if (localProfileId.isEmpty) return;
      final cloudId = _getCloudProfileId(localProfileId) ?? localProfileId;
      if (cloudId.isEmpty) return;

      final indexMap = {'anime': 1, 'manga': 0, 'novel': 2};
      final index = indexMap[mediaType] ?? 1;
      final lists = await isar.customLists
          .filter()
          .profileIdEqualTo(localProfileId)
          .and()
          .mediaTypeIndexEqualTo(index)
          .findAll();

      await pushCustomLists(cloudId, mediaType, lists);
    } catch (e) {
      Logger.i('Push list error: $e');
    }
  }

  Future<void> _pushWatchHistoryFromDb() async {
    try {
      final manager = Get.find<ProfileManager>();
      final localProfileId = manager.currentProfileId.value;
      if (localProfileId.isEmpty) return;
      final cloudId = _getCloudProfileId(localProfileId) ?? localProfileId;
      if (cloudId.isEmpty) return;

      // Watch history is derived from library items with progress
      final items = await isar.offlineMedias
          .filter()
          .profileIdEqualTo(localProfileId)
          .findAll();

      final entries = <Map<String, dynamic>>[];
      for (final item in items) {
        if (item.currentEpisode != null || item.currentChapter != null) {
          entries.add({
            'mediaId': item.mediaId,
            'name': item.name ?? item.english ?? '',
            'poster': item.poster ?? item.cover ?? '',
            'currentEpisode': item.currentEpisode?.toJson(),
            'currentChapter': item.currentChapter?.toJson(),
            'mediaType': item.mediaTypeIndex ?? 0,
            'totalEpisodes': item.totalEpisodes,
            'totalChapters': item.totalChapters,
          });
        }
      }

      if (entries.isNotEmpty) {
        await pushWatchHistory(cloudProfileId: cloudId, entries: entries);
      }
    } catch (e) {
      Logger.i('Push watch history from db error: $e');
    }
  }

  Future<void> _pushContinueWatchingFromDb() async {
    try {
      final manager = Get.find<ProfileManager>();
      final localProfileId = manager.currentProfileId.value;
      if (localProfileId.isEmpty) return;
      final cloudId = _getCloudProfileId(localProfileId) ?? localProfileId;
      if (cloudId.isEmpty) return;

      // Continue watching = anime/manga with progress but not completed
      final items = await isar.offlineMedias
          .filter()
          .profileIdEqualTo(localProfileId)
          .and()
          .mediaTypeIndexEqualTo(1) // anime
          .findAll();

      final cwItems = <Map<String, dynamic>>[];
      for (final item in items) {
        if (item.currentEpisode != null && item.name != null) {
          cwItems.add({
            'mediaId': item.mediaId,
            'name': item.name ?? item.english ?? '',
            'poster': item.poster ?? item.cover ?? '',
            'currentEpisode': item.currentEpisode?.toJson(),
            'totalEpisodes': item.totalEpisodes,
          });
        }
      }

      if (cwItems.isNotEmpty) {
        await pushContinueWatching(cloudProfileId: cloudId, items: cwItems);
      }
    } catch (e) {
      Logger.i('Push continue watching from db error: $e');
    }
  }

  Future<void> _pushSettingsOnly() async {
    try {
      final manager = Get.find<ProfileManager>();
      final localProfileId = manager.currentProfileId.value;
      if (localProfileId.isEmpty) return;
      final cloudId = _getCloudProfileId(localProfileId) ?? localProfileId;
      if (cloudId.isEmpty) return;
      await pushSettings(cloudId);
    } catch (e) {
      Logger.i('Push settings error: $e');
    }
  }

  Future<void> _pushDirtyThenPull(String localProfileId) async {
    try {
      final cloudId = _getCloudProfileId(localProfileId) ?? localProfileId;
      if (cloudId.isEmpty) return;

      isSyncing.value = true;
      await flushPendingSyncs();
      await pullAllForProfile(localProfileId);
      _lastPull = DateTime.now();
    } finally {
      isSyncing.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Sync Status
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>?> getSyncStatus(String cloudProfileId) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$_functionsUrl/sync/${_auth.username.value}/profile/$cloudProfileId/status'),
        headers: _auth.authHeaders,
      );

      if (response.statusCode == 401) {
        await _handle401();
        return null;
      }

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return Map<String, dynamic>.from(data['sync_meta']);
      }
      return null;
    } catch (e) {
      Logger.i('Get sync status error: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Settings sync
  // ---------------------------------------------------------------------------

  Future<bool> pushSettings(String cloudProfileId) async {
    try {
      final prefix = KvHelper.profilePrefix;
      final col = isar.collection<KeyValue>();
      final allKeys = col.where().findAllSync();

      final settings = <String, dynamic>{};
      for (final kv in allKeys) {
        final key = kv.key;
        if (key.startsWith('__') && key.endsWith('__')) continue;
        if (prefix.isNotEmpty && !key.startsWith(prefix)) continue;

        final suffix = prefix.isNotEmpty && key.startsWith(prefix)
            ? key.substring(prefix.length)
            : key;

        // Skip auth token keys — they are synced via dedicated pushTokens endpoint
        if (suffix == 'authToken' ||
            suffix == 'malAuthToken' ||
            suffix == 'malRefreshToken' ||
            suffix == 'malSessionId' ||
            suffix == 'simklAuthToken') continue;

        // Decode the stored value to get the actual typed value
        try {
          final decoded = jsonDecode(kv.value ?? '');
          if (decoded is Map && decoded.containsKey('val')) {
            settings[suffix] = decoded['val'];
          } else {
            settings[suffix] = kv.value ?? '';
          }
        } catch (_) {
          settings[suffix] = kv.value ?? '';
        }
      }

      final clientVersion = _getLocalVersion('settings');

      final response = await http.post(
        Uri.parse(
            '$_functionsUrl/sync/${_auth.username.value}/profile/$cloudProfileId/settings'),
        headers: _auth.authHeaders,
        body: jsonEncode({
          'settings': settings,
          if (clientVersion != null) 'client_version': clientVersion,
        }),
      );

      if (response.statusCode == 401) {
        await _handle401();
        return false;
      }

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 &&
          data['success'] == true &&
          !data['conflict']) {
        // Update local version
        final serverVersion = data['version'] as int?;
        if (serverVersion != null) {
          _setLocalVersion('settings', serverVersion);
        }
        return true;
      }
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      Logger.i('Push settings error: $e');
      return false;
    }
  }

  Future<bool> pullSettings(String cloudProfileId) async {
    try {
      final sinceVersion = _getLocalVersion('settings');
      var url =
          '$_functionsUrl/sync/${_auth.username.value}/profile/$cloudProfileId/settings';
      if (sinceVersion != null) {
        url += '?since_version=$sinceVersion';
      }

      final response = await http.get(Uri.parse(url), headers: _auth.authHeaders);

      if (response.statusCode == 401) {
        await _handle401();
        return false;
      }

      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['success'] != true) {
        return false;
      }

      final settings = Map<String, dynamic>.from(data['settings']);
      final prefix = KvHelper.profilePrefix;

      await isar.writeTxn(() async {
        for (final entry in settings.entries) {
          // Skip auth token keys — they are restored via restoreServiceTokens
          if (entry.key == 'authToken' ||
              entry.key == 'malAuthToken' ||
              entry.key == 'malRefreshToken' ||
              entry.key == 'malSessionId' ||
              entry.key == 'simklAuthToken') continue;

          final fullKey = prefix.isEmpty ? entry.key : '$prefix${entry.key}';
          final rawValue = entry.value;
          // Server returns retyped values — store as jsonEncode({'val': value})
          // to preserve the original type (string, number, boolean, json)
          final kv = KeyValue()
            ..key = fullKey
            ..value = jsonEncode({'val': rawValue});
          await isar.collection<KeyValue>().put(kv);
        }
      });

      // Update local version
      final serverVersion = data['version'] as int?;
      if (serverVersion != null) {
        _setLocalVersion('settings', serverVersion);
      }

      return true;
    } catch (e) {
      Logger.i('Pull settings error: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Library sync
  // ---------------------------------------------------------------------------

  Future<bool> pushLibrary(
    String cloudProfileId,
    String mediaType,
    List<OfflineMedia> items, {
    List<String>? removeMediaIds,
  }) async {
    try {
      final upsertItems = items.map((m) => _mediaToCloudJson(m)).toList();
      final clientVersion = _getLocalVersion('library_$mediaType');

      final response = await http.post(
        Uri.parse(
            '$_functionsUrl/sync/${_auth.username.value}/profile/$cloudProfileId/library/$mediaType'),
        headers: _auth.authHeaders,
        body: jsonEncode({
          'upsert': upsertItems,
          if (removeMediaIds != null) 'remove': removeMediaIds,
          if (clientVersion != null) 'client_version': clientVersion,
        }),
      );

      if (response.statusCode == 401) {
        await _handle401();
        return false;
      }

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final serverVersion = data['version'] as int?;
        if (serverVersion != null) {
          _setLocalVersion('library_$mediaType', serverVersion);
        }
        return true;
      }
      return false;
    } catch (e) {
      Logger.i('Push library error: $e');
      return false;
    }
  }

  Future<List<OfflineMedia>> pullLibrary(
    String cloudProfileId,
    String mediaType, {
    String? localProfileId,
    int? sinceVersion,
  }) async {
    try {
      var url =
          '$_functionsUrl/sync/${_auth.username.value}/profile/$cloudProfileId/library/$mediaType';
      final params = <String, String>{};
      if (sinceVersion != null) {
        params['since_version'] = sinceVersion.toString();
      }
      params['limit'] = '9999';
      params['page'] = '1';
      if (params.isNotEmpty) {
        url += '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
      }

      final response = await http.get(Uri.parse(url), headers: _auth.authHeaders);

      if (response.statusCode == 401) {
        await _handle401();
        return [];
      }

      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['success'] != true) {
        return [];
      }

      final library = List<Map<String, dynamic>>.from(data['library'] ?? []);
      final targetProfileId = localProfileId ?? cloudProfileId;
      return library
          .map((item) => _cloudJsonToMedia(item, profileId: targetProfileId))
          .toList();
    } catch (e) {
      Logger.i('Pull library error: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Custom Lists sync
  // ---------------------------------------------------------------------------

  Future<bool> pushCustomLists(
    String cloudProfileId,
    String mediaType,
    List<CustomList> lists,
  ) async {
    try {
      final listsJson = lists.map((l) => {
            'list_name': l.listName,
            'media_type_index': l.mediaTypeIndex,
            'media_ids': l.mediaIds ?? [],
          }).toList();

      final clientVersion = _getLocalVersion('custom_lists_$mediaType');

      final response = await http.post(
        Uri.parse(
            '$_functionsUrl/sync/${_auth.username.value}/profile/$cloudProfileId/custom-lists/$mediaType'),
        headers: _auth.authHeaders,
        body: jsonEncode({
          'lists': listsJson,
          if (clientVersion != null) 'client_version': clientVersion,
        }),
      );

      if (response.statusCode == 401) {
        await _handle401();
        return false;
      }

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final serverVersion = data['version'] as int?;
        if (serverVersion != null) {
          _setLocalVersion('custom_lists_$mediaType', serverVersion);
        }
        return true;
      }
      return false;
    } catch (e) {
      Logger.i('Push custom lists error: $e');
      return false;
    }
  }

  Future<List<CustomList>> pullCustomLists(
    String cloudProfileId,
    String mediaType, {
    String? localProfileId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$_functionsUrl/sync/${_auth.username.value}/profile/$cloudProfileId/custom-lists/$mediaType'),
        headers: _auth.authHeaders,
      );

      if (response.statusCode == 401) {
        await _handle401();
        return [];
      }

      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['success'] != true) {
        return [];
      }

      final lists = List<Map<String, dynamic>>.from(data['lists'] ?? []);
      final targetProfileId = localProfileId ?? cloudProfileId;
      final serverVersion = data['version'] as int?;
      if (serverVersion != null) {
        _setLocalVersion('custom_lists_$mediaType', serverVersion);
      }

      return lists
          .map((l) => CustomList(
                listName: l['list_name'] as String? ?? 'Default',
                mediaIds: (l['media_ids'] as List?)
                        ?.map((e) => e.toString())
                        .toList() ??
                    [],
                mediaTypeIndex: l['media_type_index'] as int? ?? 0,
                profileId: targetProfileId,
              ))
          .toList();
    } catch (e) {
      Logger.i('Pull custom lists error: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Token sync (NO CLIENT ENCRYPTION — raw tokens)
  // ---------------------------------------------------------------------------

  Future<bool> pushTokens({
    required String cloudProfileId,
    required String service,
    required Map<String, dynamic> tokens,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
            '$_functionsUrl/sync/${_auth.username.value}/profile/$cloudProfileId/tokens'),
        headers: _auth.authHeaders,
        body: jsonEncode({
          'service': service,
          'tokens': tokens,
        }),
      );

      if (response.statusCode == 401) {
        await _handle401();
        return false;
      }

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      Logger.i('Push tokens error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> pullTokens({
    required String cloudProfileId,
    required String service,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$_functionsUrl/sync/${_auth.username.value}/profile/$cloudProfileId/tokens'),
        headers: _auth.authHeaders,
      );

      if (response.statusCode == 401) {
        await _handle401();
        return null;
      }

      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['success'] != true) {
        return null;
      }

      final allTokens = Map<String, dynamic>.from(data['tokens'] ?? {});
      final serviceTokens = allTokens[service];
      if (serviceTokens == null) return null;

      // Map cloud token keys to local keys
      switch (service) {
        case 'anilist':
          return {'authToken': serviceTokens['access_token']};
        case 'mal':
          return {
            'authToken': serviceTokens['access_token'],
            'refreshToken': serviceTokens['refresh_token'],
            'sessionId': serviceTokens['session_id'],
          };
        case 'simkl':
          return {'authToken': serviceTokens['access_token']};
      }
      return null;
    } catch (e) {
      Logger.i('Pull tokens error: $e');
      return null;
    }
  }

  Future<bool> deleteTokens({
    required String cloudProfileId,
    required String service,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse(
            '$_functionsUrl/sync/${_auth.username.value}/profile/$cloudProfileId/tokens/$service'),
        headers: _auth.authHeaders,
      );

      if (response.statusCode == 401) {
        await _handle401();
        return false;
      }

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      Logger.i('Delete tokens error: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Watch History sync
  // ---------------------------------------------------------------------------

  Future<bool> pushWatchHistory({
    required String cloudProfileId,
    required List<Map<String, dynamic>> entries,
    List<String>? remove,
  }) async {
    try {
      final clientVersion = _getLocalVersion('watch_history');

      final response = await http.post(
        Uri.parse(
            '$_functionsUrl/sync/${_auth.username.value}/profile/$cloudProfileId/watch-history'),
        headers: _auth.authHeaders,
        body: jsonEncode({
          'entries': entries,
          if (remove != null) 'remove': remove,
          if (clientVersion != null) 'client_version': clientVersion,
        }),
      );

      if (response.statusCode == 401) {
        await _handle401();
        return false;
      }

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final serverVersion = data['version'] as int?;
        if (serverVersion != null) {
          _setLocalVersion('watch_history', serverVersion);
        }
        return true;
      }
      return false;
    } catch (e) {
      Logger.i('Push watch history error: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Continue Watching sync
  // ---------------------------------------------------------------------------

  Future<bool> pushContinueWatching({
    required String cloudProfileId,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final clientVersion = _getLocalVersion('continue_watching');

      final response = await http.post(
        Uri.parse(
            '$_functionsUrl/sync/${_auth.username.value}/profile/$cloudProfileId/continue-watching'),
        headers: _auth.authHeaders,
        body: jsonEncode({
          'items': items,
          if (clientVersion != null) 'client_version': clientVersion,
        }),
      );

      if (response.statusCode == 401) {
        await _handle401();
        return false;
      }

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final serverVersion = data['version'] as int?;
        if (serverVersion != null) {
          _setLocalVersion('continue_watching', serverVersion);
        }
        return true;
      }
      return false;
    } catch (e) {
      Logger.i('Push continue watching error: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Batch sync (offline catchup)
  // ---------------------------------------------------------------------------

  Future<bool> batchSync({
    required String cloudProfileId,
    required String localProfileId,
  }) async {
    try {
      final batchBody = <String, dynamic>{};

      // Settings
      final prefix = KvHelper.profilePrefix;
      final col = isar.collection<KeyValue>();
      final allKeys = col.where().findAllSync();
      final settings = <String, dynamic>{};
      for (final kv in allKeys) {
        final key = kv.key;
        if (key.startsWith('__') && key.endsWith('__')) continue;
        if (prefix.isNotEmpty && !key.startsWith(prefix)) continue;
        final batchSuffix = prefix.isNotEmpty && key.startsWith(prefix)
            ? key.substring(prefix.length)
            : key;
        // Skip auth token keys — synced via dedicated pushTokens endpoint
        if (batchSuffix == 'authToken' ||
            batchSuffix == 'malAuthToken' ||
            batchSuffix == 'malRefreshToken' ||
            batchSuffix == 'malSessionId' ||
            batchSuffix == 'simklAuthToken') continue;
        try {
          final decoded = jsonDecode(kv.value ?? '');
          if (decoded is Map && decoded.containsKey('val')) {
            settings[batchSuffix] = decoded['val'];
          } else {
            settings[batchSuffix] = kv.value ?? '';
          }
        } catch (_) {
          settings[batchSuffix] = kv.value ?? '';
        }
      }
      batchBody['settings'] = settings;

      // Library items per media type
      final mediaTypeMap = {0: 'manga', 1: 'anime', 2: 'novel'};
      final typeIndexMap = {'anime': 1, 'manga': 0, 'novel': 2};

      for (final entry in mediaTypeMap.entries) {
        final typeKey = entry.value;
        final items = await isar.offlineMedias
            .filter()
            .profileIdEqualTo(localProfileId)
            .and()
            .mediaTypeIndexEqualTo(entry.key)
            .findAll();
        if (items.isNotEmpty) {
          batchBody['${typeKey}_library'] = {
            'upsert': items.map((m) => _mediaToCloudJson(m)).toList(),
          };
        }
      }

      // Custom lists per media type
      for (final typeKey in ['anime', 'manga', 'novel']) {
        final index = typeIndexMap[typeKey] ?? 0;
        final lists = await isar.customLists
            .filter()
            .profileIdEqualTo(localProfileId)
            .and()
            .mediaTypeIndexEqualTo(index)
            .findAll();
        if (lists.isNotEmpty) {
          batchBody['custom_lists'] ??= {};
          (batchBody['custom_lists'] as Map)[typeKey] = lists
              .map((l) => {
                    'list_name': l.listName,
                    'media_type_index': l.mediaTypeIndex,
                    'media_ids': l.mediaIds ?? [],
                  })
              .toList();
        }
      }

      // Tokens
      final anilistToken = _getLocalToken('authToken');
      if (anilistToken != null) {
        batchBody['tokens'] = {
          'anilist': {'access_token': anilistToken},
        };
      }
      final malToken = _getLocalToken('malAuthToken');
      if (malToken != null) {
        batchBody['tokens'] ??= {};
        (batchBody['tokens'] as Map)['mal'] = {
          'access_token': malToken,
          'refresh_token': _getLocalToken('malRefreshToken'),
          'session_id': _getLocalToken('malSessionId'),
        };
      }
      final simklToken = _getLocalToken('simklAuthToken');
      if (simklToken != null) {
        batchBody['tokens'] ??= {};
        (batchBody['tokens'] as Map)['simkl'] = {
          'access_token': simklToken,
        };
      }

      final response = await http.post(
        Uri.parse(
            '$_functionsUrl/sync/${_auth.username.value}/profile/$cloudProfileId/batch'),
        headers: _auth.authHeaders,
        body: jsonEncode(batchBody),
      );

      if (response.statusCode == 401) {
        await _handle401();
        return false;
      }

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        // Update local versions from batch results
        final results =
            Map<String, dynamic>.from(data['results'] ?? {});
        for (final key in results.keys) {
          final result = Map<String, dynamic>.from(results[key]);
          final version = result['version'] as int?;
          if (version != null) {
            _setLocalVersion(key, version);
          }
        }
        return true;
      }
      return false;
    } catch (e) {
      Logger.i('Batch sync error: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Media ↔ Cloud JSON converters
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _mediaToCloudJson(OfflineMedia m) {
    return {
      'media_id': m.mediaId,
      'jname': m.jname,
      'name': m.name,
      'english': m.english,
      'japanese': m.japanese,
      'description': m.description,
      'poster': m.poster,
      'cover': m.cover,
      'total_episodes': m.totalEpisodes,
      'total_chapters': m.totalChapters,
      'type': m.type,
      'season': m.season,
      'premiered': m.premiered,
      'duration': m.duration,
      'status': m.status,
      'rating': m.rating,
      'popularity': m.popularity,
      'format': m.format,
      'aired': m.aired,
      'genres': m.genres ?? [],
      'studios': m.studios ?? [],
      'service_index': m.serviceIndex ?? 0,
      'media_type_index': m.mediaTypeIndex ?? 0,
      'current_episode': m.currentEpisode?.toJson(),
      'current_chapter': m.currentChapter?.toJson(),
      'watched_episodes':
          m.watchedEpisodes?.map((e) => e.toJson()).toList() ?? [],
      'read_chapters': m.readChapters?.map((c) => c.toJson()).toList() ?? [],
      'chapters': m.chapters?.map((c) => c.toJson()).toList() ?? [],
      'episodes': m.episodes?.map((e) => e.toJson()).toList() ?? [],
    };
  }

  OfflineMedia _cloudJsonToMedia(Map<String, dynamic> json,
      {String? profileId}) {
    Episode? parseEp(dynamic e) {
      if (e == null) return null;
      return Episode.fromJson(e as Map<String, dynamic>);
    }

    Chapter? parseCh(dynamic c) {
      if (c == null) return null;
      return Chapter.fromJson(c as Map<String, dynamic>);
    }

    return OfflineMedia(
      mediaId: json['media_id'] as String?,
      jname: json['jname'] as String?,
      name: json['name'] as String?,
      english: json['english'] as String?,
      japanese: json['japanese'] as String?,
      description: json['description'] as String?,
      poster: json['poster'] as String?,
      cover: json['cover'] as String?,
      totalEpisodes: json['total_episodes']?.toString(),
      totalChapters: json['total_chapters']?.toString(),
      type: json['type'] as String?,
      season: json['season'] as String?,
      premiered: json['premiered'] as String?,
      duration: json['duration'] as String?,
      status: json['status'] as String?,
      rating: json['rating'] as String?,
      popularity: json['popularity'] as String?,
      format: json['format'] as String?,
      aired: json['aired'] as String?,
      genres: (json['genres'] as List?)?.cast<String>(),
      studios: (json['studios'] as List?)?.cast<String>(),
      serviceIndex: json['service_index'] as int?,
      mediaTypeIndex: json['media_type_index'] as int? ?? 0,
      // Use LOCAL profile ID, never the cloud ID
      profileId: profileId ?? json['profile_id'] as String?,
      currentEpisode: json['current_episode'] != null
          ? parseEp(json['current_episode'])
          : null,
      currentChapter: json['current_chapter'] != null
          ? parseCh(json['current_chapter'])
          : null,
      watchedEpisodes: (json['watched_episodes'] as List?)
              ?.map(parseEp)
              .whereType<Episode>()
              .toList() ??
          [],
      readChapters: (json['read_chapters'] as List?)
              ?.map(parseCh)
              .whereType<Chapter>()
              .toList() ??
          [],
      chapters: (json['chapters'] as List?)
              ?.map(parseCh)
              .whereType<Chapter>()
              .toList() ??
          [],
      episodes: (json['episodes'] as List?)
              ?.map(parseEp)
              .whereType<Episode>()
              .toList() ??
          [],
    );
  }

  // ---------------------------------------------------------------------------
  // Full sync: push then pull (bidirectional)
  // ---------------------------------------------------------------------------

  Future<bool> fullSyncPush({
    required String localProfileId,
    required String cloudProfileId,
  }) async {
    isSyncing.value = true;
    syncStatus.value = 'Syncing settings...';

    try {
      // Push settings
      if (!await pushSettings(cloudProfileId)) {
        syncStatus.value = 'Failed to sync settings';
        return false;
      }

      // Push library for each media type
      for (final entry in [
        {'type': 'anime', 'index': 1},
        {'type': 'manga', 'index': 0},
        {'type': 'novel', 'index': 2},
      ]) {
        syncStatus.value = 'Syncing ${entry['type']}...';
        final items = await isar
            .offlineMedias
            .filter()
            .profileIdEqualTo(localProfileId)
            .and()
            .mediaTypeIndexEqualTo(entry['index'] as int)
            .findAll();

        if (items.isNotEmpty) {
          await pushLibrary(cloudProfileId, entry['type'] as String, items);
        }
      }

      // Push custom lists for each media type
      for (final entry in [
        {'type': 'anime', 'index': 1},
        {'type': 'manga', 'index': 0},
        {'type': 'novel', 'index': 2},
      ]) {
        syncStatus.value = 'Syncing ${entry['type']} lists...';
        final lists = await isar
            .customLists
            .filter()
            .profileIdEqualTo(localProfileId)
            .and()
            .mediaTypeIndexEqualTo(entry['index'] as int)
            .findAll();

        if (lists.isNotEmpty) {
          await pushCustomLists(
              cloudProfileId, entry['type'] as String, lists);
        }
      }

      // Push tokens (raw — no client encryption)
      syncStatus.value = 'Syncing tokens...';

      final anilistToken = _getLocalToken('authToken');
      if (anilistToken != null) {
        await pushTokens(
          cloudProfileId: cloudProfileId,
          service: 'anilist',
          tokens: {'access_token': anilistToken},
        );
      }

      final malToken = _getLocalToken('malAuthToken');
      final malRefresh = _getLocalToken('malRefreshToken');
      final malSession = _getLocalToken('malSessionId');
      if (malToken != null || malRefresh != null) {
        await pushTokens(
          cloudProfileId: cloudProfileId,
          service: 'mal',
          tokens: {
            'access_token': malToken,
            'refresh_token': malRefresh,
            'session_id': malSession,
          },
        );
      }

      final simklToken = _getLocalToken('simklAuthToken');
      if (simklToken != null) {
        await pushTokens(
          cloudProfileId: cloudProfileId,
          service: 'simkl',
          tokens: {'access_token': simklToken},
        );
      }

      // Push watch history & continue watching
      syncStatus.value = 'Syncing watch history...';
      await _pushWatchHistoryFromDb();
      await _pushContinueWatchingFromDb();

      // Pull after push (bidirectional sync)
      syncStatus.value = 'Pulling latest data...';
      await pullAllForProfile(localProfileId);

      syncStatus.value = 'Sync complete!';
      return true;
    } catch (e) {
      Logger.i('Full sync push error: $e');
      syncStatus.value = 'Sync failed';
      return false;
    } finally {
      isSyncing.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Local token helpers
  // ---------------------------------------------------------------------------

  String? _getLocalToken(String key) {
    try {
      final prefix = KvHelper.profilePrefix;
      final fullKey = prefix.isEmpty ? key : '$prefix$key';
      final col = isar.collection<KeyValue>();
      final result = col.filter().keyEqualTo(fullKey).findFirstSync();
      if (result?.value == null) return null;
      final data = jsonDecode(result!.value!);
      return data['val']?.toString();
    } catch (e) {
      return null;
    }
  }

  void _setLocalToken(String key, String value) {
    try {
      final prefix = KvHelper.profilePrefix;
      final fullKey = prefix.isEmpty ? key : '$prefix$key';
      final kv = KeyValue()
        ..key = fullKey
        ..value = jsonEncode({'val': value});
      isar.writeTxnSync(() => isar.collection<KeyValue>().putSync(kv));
    } catch (e) {
      Logger.i('Error setting local token: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Auto-sync service tokens (simplified — no encryption)
  // ---------------------------------------------------------------------------

  Future<void> autoSyncServiceTokens(String service) async {
    try {
      if (!_auth.isCloudMode) return;

      final manager = Get.find<ProfileManager>();
      final localProfileId = manager.currentProfileId.value;
      if (localProfileId.isEmpty) return;

      final cloudId = _getCloudProfileId(localProfileId) ?? localProfileId;
      if (cloudId.isEmpty) return;

      Map<String, dynamic>? tokens;
      switch (service) {
        case 'anilist':
          final t = _getLocalToken('authToken');
          if (t != null) tokens = {'access_token': t};
          break;
        case 'mal':
          final a = _getLocalToken('malAuthToken');
          final r = _getLocalToken('malRefreshToken');
          final s = _getLocalToken('malSessionId');
          if (a != null || r != null) {
            tokens = {'access_token': a, 'refresh_token': r, 'session_id': s};
          }
          break;
        case 'simkl':
          final t = _getLocalToken('simklAuthToken');
          if (t != null) tokens = {'access_token': t};
          break;
      }

      if (tokens != null) {
        await pushTokens(
          cloudProfileId: cloudId,
          service: service,
          tokens: tokens,
        );
      }

      // Update profile metadata on cloud (anilist_linked, mal_linked, simkl_linked)
      try {
        final profileService = Get.find<CloudProfileService>();
        final linkedValue = tokens != null;
        switch (service) {
          case 'anilist':
            await profileService.updateProfile(
                profileId: cloudId, anilistLinked: linkedValue);
            break;
          case 'mal':
            await profileService.updateProfile(
                profileId: cloudId, malLinked: linkedValue);
            break;
          case 'simkl':
            await profileService.updateProfile(
                profileId: cloudId, simklLinked: linkedValue);
            break;
        }
      } catch (_) {}
    } catch (e) {
      Logger.i('Auto sync $service tokens error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Restore service tokens from cloud (simplified — no encryption)
  // ---------------------------------------------------------------------------

  Future<void> restoreServiceTokens(String localProfileId) async {
    try {
      if (!_auth.isCloudMode) return;

      final cloudId = _getCloudProfileId(localProfileId) ?? localProfileId;
      if (cloudId.isEmpty) return;

      for (final service in ['anilist', 'mal', 'simkl']) {
        final tokens =
            await pullTokens(cloudProfileId: cloudId, service: service);
        if (tokens == null) continue;

        switch (service) {
          case 'anilist':
            final t = tokens['access_token']?.toString();
            if (t != null) _setLocalToken('authToken', t);
            break;
          case 'mal':
            final a = tokens['access_token']?.toString();
            final r = tokens['refresh_token']?.toString();
            final s = tokens['session_id']?.toString();
            if (a != null) _setLocalToken('malAuthToken', a);
            if (r != null) _setLocalToken('malRefreshToken', r);
            if (s != null) _setLocalToken('malSessionId', s);
            break;
          case 'simkl':
            final t = tokens['access_token']?.toString();
            if (t != null) _setLocalToken('simklAuthToken', t);
            break;
        }
      }
    } catch (e) {
      Logger.i('Restore tokens error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Pull all data for a profile (takes LOCAL profile ID)
  // ---------------------------------------------------------------------------

  Future<void> pullAllForProfile(String localProfileId) async {
    try {
      if (!_auth.isCloudMode) return;
      if (localProfileId.isEmpty) return;

      final cloudId = _getCloudProfileId(localProfileId) ?? localProfileId;
      if (cloudId.isEmpty) return;

      isSyncing.value = true;
      syncStatus.value = 'Pulling settings...';

      await pullSettings(cloudId);

      // Restore service tokens (Anilist, MAL, Simkl) from cloud
      syncStatus.value = 'Restoring tokens...';
      await restoreServiceTokens(localProfileId);

      // Pull library for each media type — use localProfileId for Isar
      for (final entry in [
        {'type': 'anime', 'index': 1},
        {'type': 'manga', 'index': 0},
        {'type': 'novel', 'index': 2},
      ]) {
        syncStatus.value = 'Pulling ${entry['type']}...';
        final sinceVersion = _getLocalVersion('library_${entry['type']}');
        final items = await pullLibrary(
          cloudId,
          entry['type'] as String,
          localProfileId: localProfileId,
          sinceVersion: sinceVersion,
        );
        if (items.isNotEmpty) {
          await isar.writeTxn(() async {
            final existing = await isar.offlineMedias
                .filter()
                .profileIdEqualTo(localProfileId)
                .and()
                .mediaTypeIndexEqualTo(entry['index'] as int)
                .findAll();
            for (final e in existing) {
              await isar.offlineMedias.delete(e.id);
            }
            for (final item in items) {
              await isar.offlineMedias.put(item);
            }
          });
        }
      }

      // Pull custom lists — use localProfileId for Isar
      for (final entry in [
        {'type': 'anime', 'index': 1},
        {'type': 'manga', 'index': 0},
        {'type': 'novel', 'index': 2},
      ]) {
        syncStatus.value = 'Pulling ${entry['type']} lists...';
        final lists = await pullCustomLists(
          cloudId,
          entry['type'] as String,
          localProfileId: localProfileId,
        );
        if (lists.isNotEmpty) {
          await isar.writeTxn(() async {
            final existing = await isar.customLists
                .filter()
                .profileIdEqualTo(localProfileId)
                .and()
                .mediaTypeIndexEqualTo(entry['index'] as int)
                .findAll();
            for (final e in existing) {
              await isar.customLists.delete(e.id);
            }
            for (final list in lists) {
              await isar.customLists.put(list);
            }
          });
        }
      }

      _pendingMediaIds.clear();
      syncStatus.value = 'Pull complete!';
    } catch (e) {
      Logger.i('Pull all for profile error: $e');
      syncStatus.value = 'Pull failed';
    } finally {
      isSyncing.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // 401 handling — delegate to CloudAuthService retry mechanism
  // ---------------------------------------------------------------------------

  Future<void> _handle401() async {
    try {
      final refreshed = await _auth.refreshAuthToken();
      if (!refreshed) {
        Logger.i('Cloud token refresh failed on 401');
      }
    } catch (e) {
      Logger.i('Error handling 401: $e');
    }
  }
}
