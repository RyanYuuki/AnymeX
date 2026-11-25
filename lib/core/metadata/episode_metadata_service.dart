import 'dart:async';
import 'dart:convert';
import 'package:anymex/core/metadata/models/episode_metadata.dart';
import 'package:anymex/core/metadata/providers/anilist_metadata_provider.dart';
import 'package:anymex/core/metadata/providers/anify_metadata_provider.dart';
import 'package:anymex/core/metadata/providers/anizip_metadata_provider.dart';
import 'package:anymex/core/metadata/providers/episode_metadata_provider.dart';
import 'package:anymex/core/metadata/providers/kitsu_metadata_provider.dart';
import 'package:anymex/core/metadata/providers/simkl_metadata_provider.dart';
import 'package:anymex/core/metadata/providers/tenrai_metadata_provider.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/utils/logger.dart';
import 'package:get/get.dart';

class EpisodeMetadataService extends GetxController {
  static EpisodeMetadataService get instance {
    if (!Get.isRegistered<EpisodeMetadataService>()) {
      Get.put(EpisodeMetadataService());
    }
    return Get.find<EpisodeMetadataService>();
  }

  static const List<String> defaultProviderOrder = [
    'anizip',
    'kitsu',
    'simkl',
    'anilist',
    'tenrai',
    'anify',
  ];

  late final List<EpisodeMetadataProvider> registeredProviders;

  final RxList<String> providerOrder = <String>[].obs;
  final RxList<String> disabledProviders = <String>[].obs;
  final RxString selectedSource = 'auto'.obs;

  final Map<String, (DateTime, Map<String, Map<String, EpisodeMetadataItem>>)> _memoryCache = {};

  @override
  void onInit() {
    super.onInit();
    registeredProviders = [
      AniZipMetadataProvider(),
      KitsuMetadataProvider(),
      SimklMetadataProvider(),
      AniListMetadataProvider(),
      TenraiMetadataProvider(),
      AnifyMetadataProvider(),
    ];
    _loadPreferences();
  }

  void _loadPreferences() {
    try {
      final savedOrderJson = UISettingsKeys.episodeMetaOrder.get<String>();
      if (savedOrderJson.isNotEmpty) {
        final decoded = jsonDecode(savedOrderJson);
        if (decoded is List) {
          final list = decoded.map((e) => e.toString()).toList();
          for (final id in defaultProviderOrder) {
            if (!list.contains(id)) list.add(id);
          }
          providerOrder.assignAll(list);
        } else {
          providerOrder.assignAll(defaultProviderOrder);
        }
      } else {
        providerOrder.assignAll(defaultProviderOrder);
      }

      final savedDisabledJson = UISettingsKeys.episodeMetaDisabled.get<String>();
      if (savedDisabledJson.isNotEmpty) {
        final decoded = jsonDecode(savedDisabledJson);
        if (decoded is List) {
          disabledProviders.assignAll(decoded.map((e) => e.toString()));
        }
      }

      final savedSource = UISettingsKeys.selectedEpisodeMetaSource.get<String>();
      if (savedSource.isNotEmpty) {
        selectedSource.value = savedSource;
      }
    } catch (_) {
      providerOrder.assignAll(defaultProviderOrder);
    }
  }

  void savePreferences() {
    UISettingsKeys.episodeMetaOrder.set(jsonEncode(providerOrder));
    UISettingsKeys.episodeMetaDisabled.set(jsonEncode(disabledProviders));
    UISettingsKeys.selectedEpisodeMetaSource.set(selectedSource.value);
  }

  void setProviderEnabled(String providerId, bool enabled) {
    if (enabled) {
      disabledProviders.remove(providerId);
    } else {
      if (!disabledProviders.contains(providerId)) {
        disabledProviders.add(providerId);
      }
    }
    savePreferences();
  }

  bool isProviderEnabled(String providerId) {
    return !disabledProviders.contains(providerId);
  }

  void updateOrder(List<String> newOrder) {
    providerOrder.assignAll(newOrder);
    savePreferences();
  }

  void setSelectedSource(String source) {
    selectedSource.value = source;
    savePreferences();
  }

  void resetDefaults() {
    providerOrder.assignAll(defaultProviderOrder);
    disabledProviders.clear();
    selectedSource.value = 'auto';
    savePreferences();
  }

  void clearCache() {
    _memoryCache.clear();
  }

  List<EpisodeMetadataProvider> getOrderedActiveProviders({String? explicitSource}) {
    final effectiveSource = explicitSource ?? selectedSource.value;
    if (effectiveSource == 'none') {
      return const [];
    }

    if (effectiveSource != 'auto') {
      final found = registeredProviders.firstWhereOrNull((p) => p.id == effectiveSource);
      return found != null ? [found] : const [];
    }

    final rankMap = <String, int>{};
    for (int i = 0; i < providerOrder.length; i++) {
      rankMap[providerOrder[i]] = i;
    }

    final list = registeredProviders.where((p) => isProviderEnabled(p.id)).toList();
    list.sort((a, b) => (rankMap[a.id] ?? 999).compareTo(rankMap[b.id] ?? 999));
    return list;
  }

  Stream<Map<String, EpisodeMetadataItem>> streamMetadata(
    MetadataTargetIds ids, {
    String? explicitSource,
  }) async* {
    if (!ids.hasAnyId) return;

    final targetSource = explicitSource ?? selectedSource.value;
    if (targetSource == 'none') {
      yield const {};
      return;
    }

    final cacheKey = '${ids.cacheKey}:$targetSource';
    final cached = _memoryCache[cacheKey];
    if (cached != null) {
      final isFresh = DateTime.now().difference(cached.$1) < const Duration(minutes: 30);
      if (isFresh) {
        yield mergeResults(cached.$2);
        return;
      }
    }

    final activeProviders = getOrderedActiveProviders(explicitSource: targetSource)
        .where((p) => p.supports(ids))
        .toList();

    if (activeProviders.isEmpty) {
      yield const {};
      return;
    }

    final accumulator = <String, Map<String, EpisodeMetadataItem>>{};

    for (final provider in activeProviders) {
      try {
        final episodes = await provider.fetchEpisodes(ids);
        if (episodes.isNotEmpty) {
          accumulator[provider.id] = episodes;
          yield mergeResults(accumulator);
        }
      } catch (e) {
        Logger.i('EpisodeMetadataProvider [${provider.id}] error: $e');
      }
    }

    if (accumulator.isNotEmpty) {
      _memoryCache[cacheKey] = (DateTime.now(), accumulator);
    }
  }

  Future<Map<String, EpisodeMetadataItem>> fetchMergedMetadata(
    MetadataTargetIds ids, {
    String? explicitSource,
  }) async {
    Map<String, EpisodeMetadataItem> lastEmitted = const {};
    await for (final update in streamMetadata(ids, explicitSource: explicitSource)) {
      lastEmitted = update;
    }
    return lastEmitted;
  }

  Map<String, EpisodeMetadataItem> mergeResults(
    Map<String, Map<String, EpisodeMetadataItem>> results,
  ) {
    final activeOrder = providerOrder.toList();
    final orderedResults = <Map<String, EpisodeMetadataItem>>[];

    for (final id in activeOrder) {
      if (results.containsKey(id)) {
        orderedResults.add(results[id]!);
      }
    }

    for (final entry in results.entries) {
      if (!activeOrder.contains(entry.key)) {
        orderedResults.add(entry.value);
      }
    }

    final allKeys = <String>{};
    for (final map in orderedResults) {
      allKeys.addAll(map.keys);
    }

    final merged = <String, EpisodeMetadataItem>{};
    for (final key in allKeys) {
      EpisodeMetadataItem item = EpisodeMetadataItem(number: key);
      for (final map in orderedResults) {
        final sourceItem = map[key];
        if (sourceItem != null) {
          item = item.mergeWith(sourceItem);
        }
      }
      merged[key] = item;
    }

    return merged;
  }
}
