import 'dart:convert';

import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/controllers/services/cloud/cloud_auth_service.dart';
import 'package:anymex/controllers/services/cloud/cloud_profile_service.dart';
import 'package:anymex/controllers/services/cloud/cloud_realtime_service.dart';
import 'package:anymex/controllers/services/cloud/cloud_sync_service.dart';
import 'package:anymex/controllers/services/mal/mal_service.dart';
import 'package:anymex/controllers/services/simkl/simkl_service.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/database/isar_models/key_value.dart';
import 'package:anymex/database/kv_helper.dart';
import 'package:anymex/database/isar_models/custom_list.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:anymex/main.dart';
import 'package:anymex/models/Service/app_profile.dart';
import 'package:anymex/utils/logger.dart';
import 'package:crypto/crypto.dart';
import 'package:get/get.dart';
import 'package:isar_community/isar.dart';

const int kMaxProfiles = 5;
const int kMaxPinAttempts = 5;
const int kLockoutMinutes = 5;

const String _kProfilesKey = '__app_profiles__';
const String _kCurrentProfileIdKey = '__current_profile_id__';
const String _kAutoStartProfileIdKey = '__auto_start_profile_id__';

class ProfileManager extends GetxController {
  RxList<AppProfile> profiles = <AppProfile>[].obs;
  Rx<AppProfile?> currentProfile = Rx<AppProfile?>(null);
  RxString currentProfileId = ''.obs;
  RxBool isProfileReady = false.obs;
  RxString autoStartProfileId = ''.obs;
  RxBool showProfileSelection = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadProfiles();
  }

  void _loadProfiles() {
    final raw = readGlobal(_kProfilesKey);
    if (raw != null && raw.isNotEmpty) {
      profiles.value = AppProfile.fromJsonList(raw);
    }

    final savedAutoStart = readGlobal(_kAutoStartProfileIdKey);
    if (savedAutoStart != null && savedAutoStart.isNotEmpty) {
      autoStartProfileId.value = savedAutoStart;
    }

    final savedId = readGlobal(_kCurrentProfileIdKey);
    if (savedId != null && savedId.isNotEmpty) {
      final profile = profiles.firstWhereOrNull((p) => p.id == savedId);
      if (profile != null) {
        currentProfile.value = profile;
        currentProfileId.value = profile.id;
        KvHelper.profilePrefix = '${profile.id}_';
      }
    }
  }

  void _saveProfiles() {
    writeGlobal(_kProfilesKey, AppProfile.toJsonList(profiles.toList()));
  }

  void _saveCurrentProfileId() {
    writeGlobal(_kCurrentProfileIdKey, currentProfileId.value);
  }

  bool get hasProfiles => profiles.isNotEmpty;

  bool get hasSingleProfile => profiles.length == 1;

  bool get hasAutoStart => autoStartProfileId.value.isNotEmpty &&
      profiles.any((p) => p.id == autoStartProfileId.value);

  AppProfile? createProfile({
    required String name,
    String avatarPath = '',
  }) {
    if (profiles.length >= kMaxProfiles) return null;

    final profile = AppProfile(
      id: 'prof_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      avatarPath: avatarPath,
    );

    profiles.add(profile);
    _saveProfiles();
    return profile;
  }

  Future<AppProfile?> switchToProfile(String profileId,
      {bool autoStart = false}) async {
    final profile = profiles.firstWhereOrNull((p) => p.id == profileId);
    if (profile == null) return null;
    if (profile.isLocked) return null;

    profile.lastUsedAt = DateTime.now();
    _updateProfile(profile);

    currentProfile.value = profile;
    currentProfileId.value = profile.id;
    KvHelper.profilePrefix = '${profile.id}_';
    _saveCurrentProfileId();

    try {
      if (Get.isRegistered<CloudAuthService>()) {
        final auth = Get.find<CloudAuthService>();
        if (auth.isCloudMode) {
          final sync = Get.find<CloudSyncService>();
          final profileService = Get.find<CloudProfileService>();

          // Update last used on cloud.
          // For cloud-imported profiles, profileId IS the cloud UUID
          // so getCloudProfileId returns null — fall back to profileId.
          final cloudId = getCloudProfileId(profileId) ?? profileId;
          profileService.updateLastUsed(cloudId);

          await sync.restoreServiceTokens(profileId);
          await sync.flushPendingSyncs();

          // Check if this profile has ever been synced to cloud.
          // If version is 0 (never synced), push all local data first,
          // then pull so cloud becomes the source of truth.
          final hasSynced = await sync.hasEverSynced(profileId);
          if (!hasSynced) {
            // First time — push all local data to cloud
            await sync.fullSyncPush(
              localProfileId: profileId,
              cloudProfileId: cloudId,
            );
          } else {
            await sync.pullAllForProfile(profileId);
          }

          // Start realtime subscription for cross-device sync pings
          if (Get.isRegistered<CloudRealtimeService>()) {
            Get.find<CloudRealtimeService>().subscribe(cloudId);
          }

          // Mark initial sync as done so future switches just pull
          if (!hasSynced) {
            await sync.markSynced(profileId);
          }
        }
      }
    } catch (e) {
      Logger.i('Error triggering cloud data pull: $e');
    }

    if (autoStart) {
      writeGlobal(_kAutoStartProfileIdKey, profile.id);
      autoStartProfileId.value = profile.id;
    }

    final handler = Get.find<ServiceHandler>();
    final serviceIndex = ServiceKeys.serviceType.get<int>(0);
    handler.serviceType.value = ServicesType.values[serviceIndex];

    isProfileReady.value = true;
    showProfileSelection.value = false;

    _reauthServices();

    if (Get.isRegistered<OfflineStorageController>()) {
      Get.find<OfflineStorageController>().migrateOrphanedData();
    }

    return profile;
  }

  void _reauthServices() {
    try {
      final handler = Get.find<ServiceHandler>();

      // Before autoLogin, explicitly logout any service that does NOT have
      // a saved token for the current profile.  This prevents stale username
      // data from a previously-active profile leaking into the UI (e.g. Profile A
      // logged into AniList → switch to Profile B → B's settings still shows
      // A's AniList username because the global singleton was never cleared).
      _logoutServicesWithoutToken(handler);

      handler.autoLogin().then((_) {
        handler.fetchHomePage();
      }).then((_) {
        updateServiceBadges();
      });
    } catch (e) {
      Logger.i('Error re-authenticating on profile switch: $e');
    }
  }

  /// Checks per-profile saved tokens for each tracking service and logs out
  /// any service whose token is missing for the current profile.
  void _logoutServicesWithoutToken(ServiceHandler handler) {
    try {
      final prefix = KvHelper.profilePrefix;

      // AniList
      final anilistKey = prefix.isEmpty ? 'AuthKeys_authToken' : '${prefix}AuthKeys_authToken';
      final anilistResult = isar.collection<KeyValue>().filter().keyEqualTo(anilistKey).findFirstSync();
      final hasAnilistToken = anilistResult?.value != null;
      if (!hasAnilistToken && handler.anilistService.isLoggedIn.value) {
        handler.anilistService.logout();
      }

      // MAL
      final malKey = prefix.isEmpty ? 'AuthKeys_malAuthToken' : '${prefix}AuthKeys_malAuthToken';
      final malResult = isar.collection<KeyValue>().filter().keyEqualTo(malKey).findFirstSync();
      final hasMalToken = malResult?.value != null;
      if (!hasMalToken && handler.malService.isLoggedIn.value) {
        handler.malService.logout();
      }

      // Simkl
      final simklKey = prefix.isEmpty ? 'AuthKeys_simklAuthToken' : '${prefix}AuthKeys_simklAuthToken';
      final simklResult = isar.collection<KeyValue>().filter().keyEqualTo(simklKey).findFirstSync();
      final hasSimklToken = simklResult?.value != null;
      if (!hasSimklToken && handler.simklService.isLoggedIn.value) {
        handler.simklService.logout();
      }
    } catch (e) {
      Logger.i('Error in _logoutServicesWithoutToken: $e');
    }
  }

  bool setPin(String profileId, String pin) {
    if (pin.length < 4 || pin.length > 6) return false;
    if (!RegExp(r'^\d+$').hasMatch(pin)) return false;

    final profile = profiles.firstWhereOrNull((p) => p.id == profileId);
    if (profile == null) return false;

    final bytes = utf8.encode(pin);
    final hash = sha256.convert(bytes).toString();

    _updateProfile(profile.copyWith(
        pinHash: hash, failedPinAttempts: 0, lockedUntil: null));
    return true;
  }

  bool removePin(String profileId) {
    final profile = profiles.firstWhereOrNull((p) => p.id == profileId);
    if (profile == null) return false;

    _updateProfile(
        profile.copyWith(pinHash: null, failedPinAttempts: 0, lockedUntil: null));
    return true;
  }

  bool? verifyPin(String profileId, String pin) {
    final profile = profiles.firstWhereOrNull((p) => p.id == profileId);
    if (profile == null) return false;

    if (profile.isLocked) return null;

    final bytes = utf8.encode(pin);
    final hash = sha256.convert(bytes).toString();

    if (hash == profile.pinHash) {
      _updateProfile(
          profile.copyWith(failedPinAttempts: 0, lockedUntil: null));
      return true;
    } else {
      final newAttempts = profile.failedPinAttempts + 1;
      DateTime? lockedUntil;

      if (newAttempts >= kMaxPinAttempts) {
        lockedUntil =
            DateTime.now().add(Duration(minutes: kLockoutMinutes));
      }

      _updateProfile(profile.copyWith(
        failedPinAttempts: newAttempts,
        lockedUntil: lockedUntil,
      ));
      return false;
    }
  }

  void setAniListLinked(bool linked) {
    if (currentProfile.value == null) return;
    _updateProfile(currentProfile.value!.copyWith(anilistLinked: linked));
  }

  void setMALLinked(bool linked) {
    if (currentProfile.value == null) return;
    _updateProfile(currentProfile.value!.copyWith(malLinked: linked));
  }

  void setSimklLinked(bool linked) {
    if (currentProfile.value == null) return;
    _updateProfile(currentProfile.value!.copyWith(simklLinked: linked));
  }

  void updateServiceBadges() {
    try {
      if (!Get.isRegistered<AnilistAuth>()) return;
      final anilistAuth = Get.find<AnilistAuth>();
      setAniListLinked(anilistAuth.isLoggedIn.value);

      if (!Get.isRegistered<MalService>()) return;
      final malService = Get.find<MalService>();
      setMALLinked(malService.isLoggedIn.value);

      if (!Get.isRegistered<SimklService>()) return;
      final simklService = Get.find<SimklService>();
      setSimklLinked(simklService.isLoggedIn.value);
    } catch (e) {
      Logger.i('Error updating service badges: $e');
    }
  }

  Future<bool> deleteProfile(String profileId, {String? currentId}) async {
    if (profileId == currentId) return false;

    final profile = profiles.firstWhereOrNull((p) => p.id == profileId);
    if (profile == null) return false;

    final prefix = '${profile.id}_';
    try {
      final col = isar.collection<KeyValue>();
      final allKeys = col.where().findAllSync();
      final toDelete =
          allKeys.where((kv) => kv.key.startsWith(prefix)).toList();

      isar.writeTxnSync(() {
        for (final kv in toDelete) {
          col.deleteSync(kv.id);
        }
      });
    } catch (e) {
      Logger.i('Error deleting profile KV data: $e');
    }

    final pid = profile.id;
    try {
      isar.writeTxnSync(() {
        final mediaCol = isar.collection<OfflineMedia>();
        final mediaToDelete = mediaCol
            .filter()
            .profileIdEqualTo(pid)
            .findAllSync();
        for (final m in mediaToDelete) {
          mediaCol.deleteSync(m.id);
        }

        final listCol = isar.collection<CustomList>();
        final listsToDelete = listCol
            .filter()
            .profileIdEqualTo(pid)
            .findAllSync();
        for (final l in listsToDelete) {
          listCol.deleteSync(l.id);
        }
      });
    } catch (e) {
      Logger.i('Error deleting profile library data: $e');
    }

    // Delete from cloud if logged in
    try {
      if (Get.isRegistered<CloudAuthService>()) {
        final auth = Get.find<CloudAuthService>();
        if (auth.isCloudMode) {
          final profileService = Get.find<CloudProfileService>();
          // Resolve cloud ID: mapping exists for locally-created profiles,
          // for cloud-imported profiles the profileId IS the cloud UUID.
          final mappedId = getCloudProfileId(profileId);
          final cloudId = mappedId ?? profileId;
          await profileService.deleteProfile(cloudId);
          // Only remove mapping if one was stored
          if (mappedId != null) {
            _removeCloudProfileId(profileId);
          }
        }
      }
    } catch (e) {
      Logger.i('Error deleting cloud profile: $e');
    }

    profiles.removeWhere((p) => p.id == profileId);
    _saveProfiles();

    if (autoStartProfileId.value == profileId) {
      writeGlobal(_kAutoStartProfileIdKey, '');
      autoStartProfileId.value = '';
    }

    return true;
  }

  void resetAutoStart() {
    writeGlobal(_kAutoStartProfileIdKey, '');
    autoStartProfileId.value = '';
  }

  void requestProfileSelection() {
    showProfileSelection.value = true;
  }

  void clearProfileSelectionRequest() {
    showProfileSelection.value = false;
  }


  Future<bool> importFromCloud(List<Map<String, dynamic>> cloudProfiles) async {
    if (cloudProfiles.isEmpty) return false;

    CloudProfileService? cloudProfileService;
    try {
      cloudProfileService = Get.find<CloudProfileService>();
    } catch (_) {
      cloudProfileService = null;
    }

    bool anyNew = false;
    for (final cp in cloudProfiles) {
      final cloudId = cp['cloud_profile_id'] as String? ??
          cp['id'] as String? ?? '';
      final displayName = cp['display_name'] as String? ?? 'Profile';
      final avatarUrl = cp['avatar_url'] as String? ?? '';
      final pinHash = cp['pin_hash'] as String?;
      final createdAt = cp['created_at'] != null
          ? DateTime.tryParse(cp['created_at'].toString())
          : null;
      final lastUsed = cp['last_used_at'] != null
          ? DateTime.tryParse(cp['last_used_at'].toString())
          : null;

      // Download cloud avatar URL to local cache so the ProfileAvatar widget
      // doesn't need to fetch from the network every time.
      String localAvatar = avatarUrl;
      if (avatarUrl.isNotEmpty &&
          avatarUrl.startsWith('http') &&
          cloudProfileService != null) {
        localAvatar = await cloudProfileService.downloadAvatarToLocal(avatarUrl);
      }

      final existing = profiles.firstWhereOrNull((p) => p.id == cloudId);
      if (existing != null) {
        _updateProfile(existing.copyWith(
          name: displayName,
          avatarPath: localAvatar.isNotEmpty ? localAvatar : existing.avatarPath,
          pinHash: pinHash ?? existing.pinHash,
          lastUsedAt: lastUsed ?? existing.lastUsedAt,
        ));
      } else {
        final profile = AppProfile(
          id: cloudId,
          name: displayName,
          avatarPath: localAvatar.isNotEmpty ? localAvatar : '',
          createdAt: createdAt,
          lastUsedAt: lastUsed ?? DateTime.now(),
          pinHash: pinHash,
        )..anilistLinked = cp['anilist_linked'] as bool? ?? false
          ..malLinked = cp['mal_linked'] as bool? ?? false
          ..simklLinked = cp['simkl_linked'] as bool? ?? false;
        profiles.add(profile);
        anyNew = true;
      }
    }

    if (anyNew) {
      profiles.sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
      _saveProfiles();
    }

    return anyNew || cloudProfiles.isNotEmpty;
  }

  void _updateProfile(AppProfile updated) {
    final index = profiles.indexWhere((p) => p.id == updated.id);
    if (index == -1) return;

    profiles[index] = updated;
    if (currentProfile.value?.id == updated.id) {
      currentProfile.value = updated;
    }
    _saveProfiles();
  }

  void updateProfileName(String profileId, String newName) {
    final profile = profiles.firstWhereOrNull((p) => p.id == profileId);
    if (profile == null) return;
    _updateProfile(profile.copyWith(name: newName));
  }

  /// Reorders profiles by moving the item at [oldIndex] to [newIndex].
  /// Saves locally and syncs the new order to cloud if logged in.
  void reorderProfiles(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= profiles.length) return;
    if (newIndex < 0 || newIndex >= profiles.length) return;
    if (oldIndex == newIndex) return;

    final profile = profiles.removeAt(oldIndex);
    profiles.insert(newIndex, profile);
    _saveProfiles();

    // Sync reorder to cloud
    try {
      if (Get.isRegistered<CloudAuthService>()) {
        final auth = Get.find<CloudAuthService>();
        if (auth.isCloudMode) {
          final profileService = Get.find<CloudProfileService>();
          final cloudIds = profiles
              .map((p) => getCloudProfileId(p.id) ?? p.id)
              .toList();
          profileService.reorderProfiles(cloudIds);
        }
      }
    } catch (e) {
      Logger.i('Error reordering cloud profiles: $e');
    }
  }

  void updateProfileAvatar(String profileId, String avatarPath) {
    final profile = profiles.firstWhereOrNull((p) => p.id == profileId);
    if (profile == null) return;
    _updateProfile(profile.copyWith(avatarPath: avatarPath));
  }

  static String? readGlobal(String key) {
    try {
      final col = isar.collection<KeyValue>();
      final result = col.filter().keyEqualTo(key).findFirstSync();
      if (result?.value == null) return null;
      return jsonDecode(result!.value!)['val'] as String?;
    } catch (e) {
      Logger.i('Error reading global KV $key: $e');
      return null;
    }
  }

  static void writeGlobal(String key, String value) {
    try {
      final data = KeyValue()
        ..key = key
        ..value = jsonEncode({'val': value});

      isar.writeTxnSync(() {
        isar.collection<KeyValue>().putSync(data);
      });
    } catch (e) {
      Logger.i('Error writing global KV $key: $e');
    }
  }

  /// Get the cloud UUID for a local profile ID.
  /// Public so UI screens can resolve cloud IDs for API calls.
  static String? getCloudProfileId(String localProfileId) {
    try {
      final col = isar.collection<KeyValue>();
      final result = col.filter().keyEqualTo('__cloud_profile_map__$localProfileId').findFirstSync();
      if (result?.value == null) return null;
      final data = jsonDecode(result!.value!);
      return data['cloud_id'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Remove cloud profile mapping
  static void _removeCloudProfileId(String localProfileId) {
    try {
      final col = isar.collection<KeyValue>();
      final result = col.filter().keyEqualTo('__cloud_profile_map__$localProfileId').findFirstSync();
      if (result != null) {
        isar.writeTxnSync(() => col.deleteSync(result.id));
      }
    } catch (e) {
      Logger.i('Error removing cloud profile map: $e');
    }
  }

  /// Save cloud profile ID mapping
  static void _setCloudProfileId(String localProfileId, String cloudProfileId) {
    try {
      final kv = KeyValue()
        ..key = '__cloud_profile_map__$localProfileId'
        ..value = jsonEncode({'cloud_id': cloudProfileId});
      isar.writeTxnSync(() => isar.collection<KeyValue>().putSync(kv));
    } catch (e) {
      Logger.i('Error saving cloud profile map: $e');
    }
  }
}
