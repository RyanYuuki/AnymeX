import 'dart:convert';

import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
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
const int kMaxLockAttempts = 5;
const int kLockoutMinutes = 5;

const String _kProfilesKey = '__app_profiles__';
const String _kCurrentProfileIdKey = '__current_profile_id__';
const String _kAutoStartProfileIdKey = '__auto_start_profile_id__';
const String _kMultiProfileEnabledKey = '__multi_profile_enabled__';

class ProfileManager extends GetxController {
  RxList<AppProfile> profiles = <AppProfile>[].obs;
  Rx<AppProfile?> currentProfile = Rx<AppProfile?>(null);
  RxString currentProfileId = ''.obs;
  RxBool isProfileReady = false.obs;
  RxString autoStartProfileId = ''.obs;
  RxBool showProfileSelection = false.obs;
  RxBool isMultiProfileEnabled = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadProfiles();
  }

  void _loadProfiles() {
    final raw = _readGlobal(_kProfilesKey);
    if (raw != null && raw.isNotEmpty) {
      profiles.value = AppProfile.fromJsonList(raw);
    }

    final savedAutoStart = _readGlobal(_kAutoStartProfileIdKey);
    if (savedAutoStart != null && savedAutoStart.isNotEmpty) {
      autoStartProfileId.value = savedAutoStart;
    }

    final savedMultiProfile = _readGlobal(_kMultiProfileEnabledKey);
    if (savedMultiProfile == 'true') {
      isMultiProfileEnabled.value = true;
    }

    final savedId = _readGlobal(_kCurrentProfileIdKey);
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
    _writeGlobal(_kProfilesKey, AppProfile.toJsonList(profiles.toList()));
  }

  void _saveCurrentProfileId() {
    _writeGlobal(_kCurrentProfileIdKey, currentProfileId.value);
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
    if (profiles.isNotEmpty) {
      isMultiProfileEnabled.value = true;
      _writeGlobal(_kMultiProfileEnabledKey, 'true');
    }
    return profile;
  }

  AppProfile createDefaultProfile() {
    final profile = AppProfile(
      id: 'prof_${DateTime.now().millisecondsSinceEpoch}',
      name: 'My Profile',
    );

    profiles.add(profile);
    _saveProfiles();
    return profile;
  }

  Future<void> skipMultiProfileSetup() async {
    final profile = createDefaultProfile();
    await switchToProfile(profile.id);
    isMultiProfileEnabled.value = false;
    _writeGlobal(_kMultiProfileEnabledKey, 'false');
  }

  void enableMultiProfile() {
    isMultiProfileEnabled.value = true;
    _writeGlobal(_kMultiProfileEnabledKey, 'true');
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

    if (autoStart) {
      _writeGlobal(_kAutoStartProfileIdKey, profile.id);
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
      handler.autoLogin().then((_) {
        handler.fetchHomePage();
      }).then((_) {
        updateServiceBadges();
      });
    } catch (e) {
      Logger.i('Error re-authenticating on profile switch: $e');
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
        lockHash: hash,
        lockType: 'pin',
        failedAttempts: 0,
        lockedUntil: null));
    return true;
  }

  bool setPassword(String profileId, String password) {
    if (password.length < 4 || password.length > 32) return false;

    final profile = profiles.firstWhereOrNull((p) => p.id == profileId);
    if (profile == null) return false;

    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes).toString();

    _updateProfile(profile.copyWith(
        lockHash: hash,
        lockType: 'password',
        failedAttempts: 0,
        lockedUntil: null));
    return true;
  }

  bool setPattern(String profileId, List<int> pattern) {
    if (pattern.length < 4) return false;

    final profile = profiles.firstWhereOrNull((p) => p.id == profileId);
    if (profile == null) return false;

    final patternStr = pattern.join(',');
    final bytes = utf8.encode(patternStr);
    final hash = sha256.convert(bytes).toString();

    _updateProfile(profile.copyWith(
        lockHash: hash,
        lockType: 'pattern',
        failedAttempts: 0,
        lockedUntil: null));
    return true;
  }

  bool removeLock(String profileId) {
    final profile = profiles.firstWhereOrNull((p) => p.id == profileId);
    if (profile == null) return false;

    _updateProfile(profile.copyWith(clearLock: true));
    return true;
  }

  bool? verifyLock(String profileId, String input) {
    final profile = profiles.firstWhereOrNull((p) => p.id == profileId);
    if (profile == null) return false;

    if (profile.isLocked) return null;

    final bytes = utf8.encode(input);
    final hash = sha256.convert(bytes).toString();

    if (hash == profile.lockHash) {
      _updateProfile(
          profile.copyWith(failedAttempts: 0, lockedUntil: null));
      return true;
    } else {
      final newAttempts = profile.failedAttempts + 1;
      DateTime? lockedUntil;

      if (newAttempts >= kMaxLockAttempts) {
        lockedUntil =
            DateTime.now().add(Duration(minutes: kLockoutMinutes));
      }

      _updateProfile(profile.copyWith(
        failedAttempts: newAttempts,
        lockedUntil: lockedUntil,
      ));
      return false;
    }
  }

  bool setAniListLinked(bool linked) {
    if (currentProfile.value == null) return false;
    _updateProfile(currentProfile.value!.copyWith(anilistLinked: linked));
    return true;
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

    profiles.removeWhere((p) => p.id == profileId);
    _saveProfiles();

    if (autoStartProfileId.value == profileId) {
      _writeGlobal(_kAutoStartProfileIdKey, '');
      autoStartProfileId.value = '';
    }

    return true;
  }

  void resetAutoStart() {
    _writeGlobal(_kAutoStartProfileIdKey, '');
    autoStartProfileId.value = '';
  }

  void requestProfileSelection() {
    showProfileSelection.value = true;
  }

  void clearProfileSelectionRequest() {
    showProfileSelection.value = false;
  }

  void _updateProfile(AppProfile updated) {
    final index = profiles.indexWhere((p) => p.id == updated.id);
    if (index == -1) return;

    profiles[index] = updated;
    profiles.refresh();
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

  void updateProfileAvatar(String profileId, String avatarPath) {
    final profile = profiles.firstWhereOrNull((p) => p.id == profileId);
    if (profile == null) return;
    _updateProfile(profile.copyWith(avatarPath: avatarPath));
  }

  void restoreProfileFromBackup(String profileId, AppProfile source) {
    final index = profiles.indexWhere((p) => p.id == profileId);
    if (index == -1) return;
    final updated = profiles[index].copyWith(
      lockHash: source.lockHash,
      lockType: source.lockType,
      anilistLinked: source.anilistLinked,
      malLinked: source.malLinked,
      simklLinked: source.simklLinked,
    );
    _updateProfile(updated);
  }

  static String? _readGlobal(String key) {
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

  static void _writeGlobal(String key, String value) {
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
}
