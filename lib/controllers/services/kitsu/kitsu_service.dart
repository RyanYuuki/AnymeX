import 'package:anymex/controllers/services/kitsu/kitsu_auth.dart';
import 'package:anymex/controllers/services/kitsu/kitsu_sync.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Anilist/anilist_profile.dart';
import 'package:anymex/models/Service/base_service.dart';
import 'package:anymex/models/Service/online_service.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class KitsuService extends GetxController implements BaseService {
  final kitsuAuth = Get.find<KitsuAuth>();
  final kitsuSync = Get.find<KitsuSync>();

  @override
  RxBool isLoggedIn = false.obs;

  @override
  Rx<Profile> profileData = Profile().obs;

  @override
  Future<void> login(BuildContext context) async {
    await kitsuAuth.login();
    isLoggedIn.value = kitsuAuth.isLoggedIn.value;
    profileData.value = kitsuAuth.profileData.value;
  }

  @override
  Future<void> logout() async {
    kitsuAuth.logout();
    isLoggedIn.value = false;
    profileData.value = Profile();
  }

  @override
  Future<void> autoLogin() async {
    await kitsuAuth.autoLogin();
    isLoggedIn.value = kitsuAuth.isLoggedIn.value;
    profileData.value = kitsuAuth.profileData.value;
  }

  @override
  Future<void> refresh() async {
    if (isLoggedIn.value) {
      await kitsuAuth.fetchUserProfile();
      profileData.value = kitsuAuth.profileData.value;
    }
  }

  @override
  RxList<Widget> homeWidgets(BuildContext context) {
    return <Widget>[].obs;
  }
  
  Future<void> syncToKitsuFromCurrentService() async {
    if (!isLoggedIn.value) {
      snackBar('Please login to Kitsu first');
      return;
    }

    final currentService = serviceHandler.serviceType.value;
    if (currentService == ServicesType.extensions) {
      snackBar('Cannot sync from extensions');
      return;
    }

    await kitsuSync.batchSyncToKitsu();
  }

  Future<void> syncEntryToKitsu({
    required String listId,
    required bool isAnime,
    String? score,
    String? status,
    int? progress,
    String? malId,
  }) async {
    if (!isLoggedIn.value) return;

    await kitsuSync.syncToKitsu(
      listId: listId,
      isAnime: isAnime,
      score: score,
      status: status,
      progress: progress,
      malId: malId,
    );
  }
}
