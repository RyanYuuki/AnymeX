import 'package:anymex/controllers/cacher/cache_controller.dart';
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

enum ServicesType { anilist, mal, simkl, extensions }

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

  Future<void> updateListEntry({
    required String listId,
    double? score,
    String? status,
    int? progress,
    bool isAnime = true,
  }) async =>
      onlineService.updateListEntry(
          listId: listId,
          score: score,
          status: status,
          progress: progress,
          isAnime: isAnime);

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

  Future<Media> fetchDetails(dynamic id) async {
    Media? data = cacheController.getCacheByAnimeId(id);
    return data ?? service.fetchDetails(id);
  }

  Future<List<Media>?> search(String query,
          {bool isManga = false, Map<String, dynamic>? filters}) async =>
      service.search(query, isManga: isManga, filters: filters);

  void changeService(ServicesType type) {
    final box = Hive.box('themeData');
    box.put("serviceType", type.index);
    serviceType.value = type;
    fetchHomePage();
  }
}
