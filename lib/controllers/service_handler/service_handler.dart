import 'package:anymex/utils/logger.dart';

import 'package:anymex/controllers/cacher/cache_controller.dart';
import 'package:anymex/controllers/service_handler/params.dart';
import 'package:anymex/controllers/services/anilist/anilist_data.dart';
import 'package:anymex/controllers/services/mal/mal_service.dart';
import 'package:anymex/controllers/services/simkl/simkl_service.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/models/Anilist/anilist_media_user.dart';
import 'package:anymex/models/Anilist/anilist_profile.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Service/base_service.dart';
import 'package:anymex/models/Service/online_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

enum ServicesType {
  anilist,
  mal,
  simkl,
  extensions;

  BaseService get service {
    switch (this) {
      case ServicesType.anilist:
        return Get.find<AnilistData>();
      case ServicesType.mal:
        return Get.find<MalService>();
      case ServicesType.simkl:
        return Get.find<SimklService>();
      case ServicesType.extensions:
        return Get.find<SourceController>();
    }
  }

  OnlineService get onlineService {
    switch (this) {
      case ServicesType.anilist:
        return Get.find<AnilistData>();
      case ServicesType.mal:
        return Get.find<MalService>();
      case ServicesType.simkl:
        return Get.find<SimklService>();
      default:
        return Get.find<AnilistData>();
    }
  }
}

final serviceHandler = Get.find<ServiceHandler>();

class ServiceHandler extends GetxController {
  final serviceType = ServicesType.anilist.obs;
  final anilistService = Get.find<AnilistData>();
  final malService = Get.find<MalService>();
  final simklService = Get.find<SimklService>();
  final extensionService = Get.find<SourceController>();

  BaseService get service {
    switch (serviceType.value) {
      case ServicesType.anilist:
        return anilistService;
      case ServicesType.mal:
        return malService;
      case ServicesType.simkl:
        return simklService;
      case ServicesType.extensions:
        return extensionService;
    }
  }

  OnlineService get onlineService {
    switch (serviceType.value) {
      case ServicesType.anilist:
        return anilistService;
      case ServicesType.mal:
        return malService;
      case ServicesType.simkl:
        return simklService;
      default:
        return anilistService;
    }
  }

  Rx<Profile> get profileData => serviceType.value == ServicesType.extensions
      ? Profile(name: onlineService.profileData.value.name ?? 'Guest').obs
      : onlineService.profileData;
  RxList<TrackedMedia> get animeList => onlineService.animeList;
  RxList<TrackedMedia> get mangaList => onlineService.mangaList;

  Rx<TrackedMedia> get currentMedia => onlineService.currentMedia;

  RxBool get isLoggedIn => onlineService.isLoggedIn;

  // Online Services Method
  Future<void> login() => onlineService.login();
  Future<void> logout() => onlineService.logout();
  Future<void> autoLogin() => Future.wait([
        malService.autoLogin(),
        anilistService.autoLogin(),
        simklService.autoLogin(),
      ]);
  @override
  Future<void> refresh() => onlineService.refresh();

  Future<void> updateListEntry(
    UpdateListEntryParams params,
  ) async =>
      await onlineService.updateListEntry(params);

  RxList<Widget> animeWidgets(BuildContext context) =>
      service.animeWidgets(context);
  RxList<Widget> mangaWidgets(BuildContext context) =>
      service.mangaWidgets(context);
  RxList<Widget> homeWidgets(BuildContext context) =>
      service.homeWidgets(context);

  @override
  void onInit() {
    super.onInit();
    _initServices();
  }

  Future<void> _initServices() async {
    final box = Hive.box('themeData');
    serviceType.value =
        ServicesType.values[box.get("serviceType", defaultValue: 0)];
    await fetchHomePage();
    await autoLogin();
  }

  Future<void> fetchHomePage() => service.fetchHomePage();

  Future<Media> fetchDetails(FetchDetailsParams params) async {
    try {
      if (serviceType.value == ServicesType.extensions) {
        return service.fetchDetails(params);
      }
      Media? data = cacheController.getCacheById(params.id);
      return data ?? service.fetchDetails(params);
    } catch (e) {
      Logger.i("Cache Error => $e");
      return service.fetchDetails(params);
    }
  }

  Future<List<Media>?> search(SearchParams params) async =>
      service.search(params);

  void changeService(ServicesType type) {
    final box = Hive.box('themeData');
    box.put("serviceType", type.index);
    serviceType.value = type;
    fetchHomePage();
  }
}
