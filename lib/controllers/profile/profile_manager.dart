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
}
