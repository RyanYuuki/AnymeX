import 'package:anymex/controllers/cacher/cache_controller.dart';
import 'package:anymex/controllers/service_handler/params.dart';
import 'package:anymex/controllers/services/anilist/anilist_data.dart';
import 'package:anymex/controllers/services/mal/mal_service.dart';
import 'package:anymex/controllers/services/mangabaka/mangabaka_service.dart';
import 'package:anymex/controllers/services/simkl/simkl_service.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/models/Anilist/anilist_media_user.dart';
import 'package:anymex/models/Anilist/anilist_profile.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Service/base_service.dart';
import 'package:anymex/models/Service/online_service.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum ServicesType {
  anilist,
  mal,
  simkl,
  extensions,
  mangabaka;

  bool get isMal => this == ServicesType.mal;
  bool get isAL => this == ServicesType.anilist;
  bool get isSimkl => this == ServicesType.simkl;
  bool get isMangaBaka => this == ServicesType.mangabaka;

  BaseService get service {
    switch (this) {
      case ServicesType.anilist:
        return Get.find<AnilistData>();
      case ServicesType.mal:
        return Get.find<MalService>();
      case ServicesType.simkl:
        return Get.find<SimklService>();
      case ServicesType.mangabaka:
        return Get.find<MangaBakaService>();
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
      case ServicesType.mangabaka:
        return Get.find<MangaBakaService>();
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
  final mangaBakaService = Get.find<MangaBakaService>();
  final extensionService = Get.find<SourceController>();

  BaseService get service {
    switch (serviceType.value) {
      case ServicesType.anilist:
        return anilistService;
      case ServicesType.mal:
        return malService;
      case ServicesType.simkl:
        return simklService;
      case ServicesType.mangabaka:
        return mangaBakaService;
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
      case ServicesType.mangabaka:
        return mangaBakaService;
      default:
        return anilistService;
    }
  }

  Rx<Profile> get profileData =>
      serviceType.value == ServicesType.extensions
          ? Profile(name: onlineService.profileData.value.name ?? 'Guest').obs
          : onlineService.profileData;

  RxList<TrackedMedia> get animeList => onlineService.animeList;
  RxList<TrackedMedia> get mangaList => onlineService.mangaList;
  Rx<TrackedMedia> get currentMedia => onlineService.currentMedia;
  RxBool get isLoggedIn => onlineService.isLoggedIn;

  Future<void> login(BuildContext context) => onlineService.login(context);
  Future<void> logout() => onlineService.logout();

  @override
  Future<void> refresh() => onlineService.refresh();

  Future<void> autoLogin() => Future.wait([
        malService.autoLogin(),
        anilistService.autoLogin(),
        simklService.autoLogin(),
        mangaBakaService.autoLogin(),
      ]);

  Future<void> updateListEntry(UpdateListEntryParams params) async =>
      onlineService.updateListEntry(params);

  RxList<Widget> animeWidgets(BuildContext context) =>
      service.animeWidgets(context);

  RxList<Widget> mangaWidgets(BuildContext context) =>
      service.mangaWidgets(context);

  RxList<Widget> homeWidgets(BuildContext context) =>
      service.homeWidgets(context);

  RxList<Widget> novelWidgets(BuildContext context) {
    if (serviceType.value == ServicesType.anilist) {
      return anilistService.mangaWidgets(context);
    } else if (serviceType.value == ServicesType.mal) {
      return malService.mangaWidgets(context);
    } else {
      return extensionService.novelSections;
    }
  }

  Source? getSourceForMedia(Media media) {
    if (media.serviceType == ServicesType.extensions) {
      return extensionService.installedNovelExtensions.firstWhere(
        (source) => source.name == media.sourceName,
        orElse: () => extensionService.installedNovelExtensions.first,
      );
    }
    return null;
  }

  @override
  void onInit() {
    super.onInit();
    serviceType.value =
        ServicesType.values[ServiceKeys.serviceType.get<int>(0)];
  }

  @override
  void onReady() {
    super.onReady();
    fetchHomePage();
    autoLogin();
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
      Logger.i('Cache Error => $e');
      return service.fetchDetails(params);
    }
  }

  Future<List<Media>?> search(SearchParams params) async =>
      service.search(params);

  void changeService(ServicesType type) {
    ServiceKeys.serviceType.set(type.index);
    serviceType.value = type;
    fetchHomePage();
  }
}
