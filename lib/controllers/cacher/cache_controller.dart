import 'dart:convert';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/core/Eval/dart/model/m_manga.dart';
import 'package:anymex/core/Model/Manga.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:get/get.dart';

final cacheController = Get.find<CacheController>();

class CacheController extends GetxController {
  RxList<String> cachedAnilistData = <String>[].obs;
  RxList<String> cachedMalData = <String>[].obs;
  RxList<String> cachedSimklData = <String>[].obs;
  RxList<String> cachedExtensionData = <String>[].obs;

  RxString detailsData = ''.obs;

  RxList<String> get currentPool => getCacheContainer();

  void addCache(Map<String, dynamic> data) {
    final storedData = getStoredAnime();
    final index = storedData.indexWhere((e) => e.id == data['id']);
    detailsData.value = jsonEncode(data);
    if (index == -1) {
      currentPool.add(jsonEncode(data));
    } else {
      currentPool[index] = jsonEncode(data);
    }
  }

  List<Media> getStoredAnime() {
    return currentPool.map((e) => cacheDataParser(e)).toList();
  }

  Media? getCacheById(String id) {
    final pool = getCacheContainer();
    final data = pool.map((e) => cacheDataParser(e)).toList();
    return data.firstWhereOrNull((e) => e.id == id);
  }

  Media cacheDataParser(String data) {
    final service = Get.find<ServiceHandler>().serviceType;
    Map<String, dynamic> parsedMap = jsonDecode(data);
    switch (service.value) {
      case ServicesType.anilist:
        return Media.fromJson(parsedMap);
      case ServicesType.mal:
        return Media.fromFullMAL(parsedMap);
      case ServicesType.simkl:
        return Media.fromSimkl(parsedMap, true);
      default:
        parsedMap['status'] = parseStatusToInt(parsedMap['status']);
        return Media.fromManga(
            MManga.fromJson(parsedMap),
            serviceHandler.extensionService.lastUpdatedSource.value == "ANIME"
                ? MediaType.anime
                : MediaType.manga);
    }
  }

  RxList<String> getCacheContainer() {
    final service = Get.find<ServiceHandler>().serviceType;
    switch (service.value) {
      case ServicesType.anilist:
        return cachedAnilistData;
      case ServicesType.mal:
        return cachedMalData;
      case ServicesType.simkl:
        return cachedSimklData;
      default:
        return cachedExtensionData;
    }
  }
}

int parseStatusToInt(String status) {
  switch (status) {
    case 'ONGOING':
      return 0;
    case 'COMPLETED':
      return 1;
    case 'ONHIATUS':
      return 2;
    case 'CANCELED':
      return 3;
    case 'PUBLISHINGFINISHED':
      return 4;
    default:
      return -1;
  }
}
