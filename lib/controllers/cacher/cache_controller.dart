import 'dart:convert';

import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:get/get.dart';

final cacheController = Get.find<CacheController>();

class CacheController extends GetxController {
  RxList<String> cachedAnilistData = <String>[].obs;
  RxList<String> cachedMalData = <String>[].obs;
  RxList<String> cachedSimklData = <String>[].obs;
  RxList<String> cachedExtensionData = <String>[].obs;

  RxString detailsData = ''.obs;

  RxList<String> get currentPool => getCacheContainer();

  void addCache(Map<String, dynamic> data, [ServicesType? serviceType]) {
    if (!data.containsKey('id') ||
        data['id'] == null ||
        data['id'].toString().isEmpty) {
      Logger.i('Error: Invalid or missing ID in data');
      return;
    }

    final targetService = serviceType ??
        (data['title'] is Map
            ? ServicesType.anilist
            : Get.find<ServiceHandler>().serviceType.value);
    final pool = getCacheContainer(targetService);
    final String id = data['id'].toString();
    final String encodedData = jsonEncode(data);

    detailsData.value = encodedData;

    final index = pool.indexWhere((item) {
      try {
        final map = jsonDecode(item);
        return map is Map && map['id']?.toString() == id;
      } catch (_) {
        return false;
      }
    });

    if (index == -1) {
      pool.add(encodedData);
      Logger.i('Added new entry to cache: ID $id');
    } else {
      pool[index] = encodedData;
      Logger.i('Updated existing entry in cache: ID $id');
    }
  }

  List<Media> getStoredAnime([ServicesType? serviceType]) {
    final pool = getCacheContainer(serviceType);
    return pool
        .map((e) => cacheDataParser(e, serviceType))
        .whereType<Media>()
        .toList()
        .reversed
        .toList();
  }

  Media? getCacheById(String id, [ServicesType? serviceType]) {
    if (serviceType != null) {
      final match =
          _findInPool(getCacheContainer(serviceType), id, serviceType);
      if (match != null) return match;
    }

    final currentService = Get.find<ServiceHandler>().serviceType.value;
    final currentMatch =
        _findInPool(getCacheContainer(currentService), id, currentService);
    if (currentMatch != null) return currentMatch;

    for (final type in ServicesType.values) {
      if (type == serviceType || type == currentService) continue;
      final match = _findInPool(getCacheContainer(type), id, type);
      if (match != null) return match;
    }
    return null;
  }

  Media? _findInPool(List<String> pool, String id, ServicesType serviceType) {
    for (final item in pool) {
      try {
        final decoded = jsonDecode(item);
        if (decoded is Map && decoded['id']?.toString() == id) {
          return cacheDataParser(item, serviceType);
        }
      } catch (e) {
        Logger.i('Error matching cache entry: $e');
      }
    }
    return null;
  }

  Media? cacheDataParser(String data, [ServicesType? serviceType]) {
    try {
      final service =
          serviceType ?? Get.find<ServiceHandler>().serviceType.value;
      Map<String, dynamic> parsedMap = jsonDecode(data);
      if (parsedMap['title'] is Map) {
        return Media.fromJson(parsedMap);
      }
      switch (service) {
        case ServicesType.anilist:
          return Media.fromJson(parsedMap);
        case ServicesType.mal:
          return Media.fromFullMAL(parsedMap);
        case ServicesType.simkl:
          final dynamic marker = parsedMap['__isMovie'];
          final bool isMovie = marker is bool ? marker : true;
          return Media.fromSimkl(parsedMap, isMovie);
        case ServicesType.extensions:
          parsedMap['status'] =
              parseStatusToInt(parsedMap['status']?.toString() ?? '');
          return Media.froDMedia(
              DMedia.fromJson(Map.from(parsedMap)),
              serviceHandler.extensionService.lastUpdatedSource.value == "ANIME"
                  ? ItemType.anime
                  : ItemType.manga);
      }
    } catch (e) {
      Logger.i('Cache parsing error: $e');
      return null;
    }
  }

  RxList<String> getCacheContainer([ServicesType? serviceType]) {
    final service = serviceType ?? Get.find<ServiceHandler>().serviceType.value;
    switch (service) {
      case ServicesType.anilist:
        return cachedAnilistData;
      case ServicesType.mal:
        return cachedMalData;
      case ServicesType.simkl:
        return cachedSimklData;
      case ServicesType.extensions:
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
