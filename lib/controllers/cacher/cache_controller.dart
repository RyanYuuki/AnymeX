import 'dart:convert';

import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/database/kv_helper.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:get/get.dart';

final cacheController = Get.find<CacheController>();

const _kCacheStorageKey = '__recently_opened_cache__';

class CacheController extends GetxController {
  RxList<String> cachedAnilistData = <String>[].obs;
  RxList<String> cachedMalData = <String>[].obs;
  RxList<String> cachedSimklData = <String>[].obs;
  RxList<String> cachedExtensionData = <String>[].obs;

  RxString detailsData = ''.obs;

  RxList<String> get currentPool => getCacheContainer();

  @override
  void onInit() {
    super.onInit();
    _loadFromStorage();
  }

  void saveToStorage() {
    try {
      final service = Get.find<ServiceHandler>().serviceType.value;
      final String serviceKey = service.name;
      final List<String> pool = getCacheContainer().toList();

      KvHelper.set<List<String>>('${_kCacheStorageKey}_$serviceKey', pool);
      Logger.i('Saved recently opened cache for ${service.name}: ${pool.length} items');
    } catch (e) {
      Logger.i('Error saving cache to storage: $e');
    }
  }

  void loadFromStorage() {
    _loadFromStorage();
  }

  void _loadFromStorage() {
    try {
      final service = Get.find<ServiceHandler>().serviceType.value;
      final String serviceKey = service.name;
      final List<String>? saved = KvHelper.get<List<String>>(
        '${_kCacheStorageKey}_$serviceKey',
        defaultVal: [],
      );

      if (saved != null && saved.isNotEmpty) {
        final targetPool = getCacheContainer();
        targetPool.assignAll(saved);
        Logger.i('Loaded recently opened cache for ${service.name}: ${saved.length} items');
      } else {
        final targetPool = getCacheContainer();
        targetPool.clear();
      }
    } catch (e) {
      Logger.i('Error loading cache from storage: $e');
    }
  }

  void clearAllCache() {
    try {
      final services = ['anilist', 'mal', 'simkl', 'extensions'];
      for (final service in services) {
        KvHelper.remove('${_kCacheStorageKey}_$service');
      }
      cachedAnilistData.clear();
      cachedMalData.clear();
      cachedSimklData.clear();
      cachedExtensionData.clear();
      Logger.i('Cleared all recently opened cache');
    } catch (e) {
      Logger.i('Error clearing cache: $e');
    }
  }

  void addCache(Map<String, dynamic> data) {
    if (!data.containsKey('id') ||
        data['id'] == null ||
        data['id'].toString().isEmpty) {
      Logger.i('Error: Invalid or missing ID in data');
      return;
    }

    final String id = data['id'].toString();
    final String encodedData = jsonEncode(data);

    detailsData.value = encodedData;

    final storedData = getStoredAnime();

    final index = storedData.indexWhere((e) => e.id == id);

    if (index == -1) {
      if (!currentPool.any((item) => jsonDecode(item)['id'] == id)) {
        currentPool.add(encodedData);
        Logger.i('Added new entry to cache: ID $id');
      } else {
        Logger.i('Duplicate entry in currentPool skipped: ID $id');
      }
    } else {
      if (index < currentPool.length) {
        currentPool[index] = encodedData;
        Logger.i('Updated existing entry in cache: ID $id');
      } else {
        Logger.i(
            'Warning: currentPool index out of sync for ID $id, adding as new');
        currentPool.add(encodedData);
      }
    }

    _persistCurrentPool();
  }

  void _persistCurrentPool() {
    try {
      final service = Get.find<ServiceHandler>().serviceType.value;
      final String serviceKey = service.name;
      final pool = currentPool.length > 30
          ? currentPool.sublist(currentPool.length - 30)
          : currentPool.toList();
      KvHelper.set<List<String>>('${_kCacheStorageKey}_$serviceKey', pool);
    } catch (e) {
    }
  }

  List<Media> getStoredAnime() {
    return currentPool
        .map((e) => cacheDataParser(e))
        .toList()
        .reversed
        .toList();
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
        final dynamic marker = parsedMap['__isMovie'];
        final bool isMovie = marker is bool ? marker : true;
        return Media.fromSimkl(parsedMap, isMovie);
      default:
        parsedMap['status'] = parseStatusToInt(parsedMap['status']);
        return Media.froDMedia(
            DMedia.fromJson(parsedMap),
            serviceHandler.extensionService.lastUpdatedSource.value == "ANIME"
                ? ItemType.anime
                : ItemType.manga);
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
