import 'dart:async';
import 'dart:convert';
import 'package:anymex/controllers/network/network_manager.dart';
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
import 'package:flutter/foundation.dart';
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
    bool forceRefresh = false,
  }) async* {
    if (!ids.hasAnyId) return;

    final targetSource = explicitSource ?? selectedSource.value;
    if (targetSource == 'none') {
      yield const {};
      return;
    }

    final cacheKey = '${ids.cacheKey}:$targetSource';
    if (forceRefresh) {
      _memoryCache.remove(cacheKey);
    } else {
      final cached = _memoryCache[cacheKey];
      if (cached != null) {
        final isFresh = DateTime.now().difference(cached.$1) < const Duration(minutes: 30);
        if (isFresh) {
          yield mergeResults(cached.$2);
          return;
        }
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
    bool forceRefresh = false,
  }) async {
    Map<String, EpisodeMetadataItem> lastEmitted = const {};
    await for (final update in streamMetadata(
      ids,
      explicitSource: explicitSource,
      forceRefresh: forceRefresh,
    )) {
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

  Future<String> testAllProvidersRaw(MetadataTargetIds ids) async {
    final client = NetworkManager.instance.compatibleClient;
    final results = <String, dynamic>{};

    dynamic tryDecode(String body) {
      if (body.isEmpty) return '';
      try {
        return jsonDecode(body);
      } catch (_) {
        return body;
      }
    }

    Future<void> runTest(
      String key,
      Future<Map<String, dynamic>> Function() fn,
    ) async {
      try {
        results[key] = await fn();
      } catch (e) {
        results[key] = {'error': e.toString()};
      }
    }

    await Future.wait([
      runTest('anizip', () async {
        final queryParam = ids.anilistId != null
            ? 'anilist_id=${ids.anilistId}'
            : 'mal_id=${ids.malId}';
        final url = 'https://api.ani.zip/mappings?$queryParam';
        final resp =
            await client.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
        final decoded = tryDecode(resp.body);
        if (decoded is Map && decoded['mappings'] is Map) {
          final m = decoded['mappings'] as Map;
          ids.kitsuId ??= m['kitsu_id']?.toString();
          ids.simklId ??= m['simkl_id']?.toString();
          ids.malId ??= m['mal_id']?.toString();
          ids.anilistId ??= m['anilist_id']?.toString();
        }
        return {
          'url': url,
          'statusCode': resp.statusCode,
          'response': decoded,
        };
      }),
      runTest('anilist', () async {
        final anilistId = int.tryParse(ids.anilistId ?? '');
        if (anilistId == null) {
          return {'skipped': 'missing anilistId'};
        }
        const query = '''
query (\$id: Int) {
  Media(id: \$id, type: ANIME) {
    streamingEpisodes {
      title
      thumbnail
    }
    airingSchedule(perPage: 150) {
      nodes {
        episode
        airingAt
      }
    }
  }
}
''';
        const url = 'https://graphql.anilist.co';
        final resp = await client
            .post(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: jsonEncode({
                'query': query,
                'variables': {'id': anilistId},
              }),
            )
            .timeout(const Duration(seconds: 15));
        return {
          'url': url,
          'statusCode': resp.statusCode,
          'response': tryDecode(resp.body),
        };
      }),
      runTest('kitsu', () async {
        if (ids.anilistId == null && ids.malId == null && ids.kitsuId == null) {
          return {'skipped': 'missing kitsu/anilist/mal id'};
        }
        final query = ids.kitsuId != null
            ? '''
query {
  findAnimeById(id: ${ids.kitsuId}) {
    episodes(first: 2000) {
      nodes {
        number
        titles { localized }
        description
        thumbnail { original { url } }
        length
      }
    }
  }
}
'''
            : '''
query {
  lookupMapping(externalId: ${ids.anilistId ?? ids.malId}, externalSite: ${ids.anilistId != null ? 'ANILIST_ANIME' : 'MYANIMELIST_ANIME'}) {
    __typename
    ... on Anime {
      id
      episodes(first: 2000) {
        nodes {
          number
          titles { canonical }
          description
          thumbnail { original { url } }
          length
        }
      }
    }
  }
}
''';
        const url = 'https://kitsu.io/api/graphql';
        final resp = await client
            .post(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: jsonEncode({'query': query}),
            )
            .timeout(const Duration(seconds: 15));
        return {
          'url': url,
          'statusCode': resp.statusCode,
          'response': tryDecode(resp.body),
        };
      }),
      runTest('tenrai', () async {
        final malId = ids.malId;
        if (malId == null) {
          return {'skipped': 'missing malId'};
        }
        final url = 'https://api.tenrai.org/v1/anime/$malId/episodes?page=1';
        final resp = await client
            .get(Uri.parse(url), headers: {'Accept': 'application/json'})
            .timeout(const Duration(seconds: 12));
        return {
          'url': url,
          'statusCode': resp.statusCode,
          'response': tryDecode(resp.body),
        };
      }),
      runTest('anify', () async {
        final anilistId = ids.anilistId;
        if (anilistId == null) {
          return {'skipped': 'missing anilistId'};
        }
        final url = 'https://api.anify.eltik.cc/info/$anilistId?fields=[episodes]';
        final resp =
            await client.get(Uri.parse(url)).timeout(const Duration(seconds: 12));
        return {
          'url': url,
          'statusCode': resp.statusCode,
          'response': tryDecode(resp.body),
        };
      }),
      runTest('simkl', () async {
        String? simklId = ids.simklId;
        String? lookupUrl;
        int? lookupStatus;
        if (simklId == null && (ids.malId != null || ids.anilistId != null)) {
          final param =
              ids.malId != null ? 'mal=${ids.malId}' : 'anilist=${ids.anilistId}';
          lookupUrl =
              'https://api.simkl.com/search/id?$param&client_id=${SimklMetadataProvider.clientId}';
          final lookupResp = await client
              .get(Uri.parse(lookupUrl), headers: {'Accept': 'application/json'})
              .timeout(const Duration(seconds: 10));
          lookupStatus = lookupResp.statusCode;
          final decoded = tryDecode(lookupResp.body);
          if (decoded is List && decoded.isNotEmpty && decoded[0] is Map) {
            final idsMap = decoded[0]['ids'];
            if (idsMap is Map) {
              simklId = idsMap['simkl']?.toString();
            }
          }
        }
        if (simklId == null || simklId.isEmpty) {
          return {
            'lookupUrl': lookupUrl,
            'lookupStatusCode': lookupStatus,
            'skipped': 'could not resolve simklId',
          };
        }
        final url =
            'https://api.simkl.com/anime/episodes/$simklId?extended=full&client_id=${SimklMetadataProvider.clientId}';
        final resp = await client
            .get(Uri.parse(url), headers: {'Accept': 'application/json'})
            .timeout(const Duration(seconds: 15));
        return {
          if (lookupUrl != null) 'lookupUrl': lookupUrl,
          if (lookupStatus != null) 'lookupStatusCode': lookupStatus,
          'url': url,
          'statusCode': resp.statusCode,
          'response': tryDecode(resp.body),
        };
      }),
    ]);

    const encoder = JsonEncoder.withIndent('  ');
    debugPrint('=== EPISODE METADATA API TEST START ===');
    debugPrint(
      'Targets: anilistId=${ids.anilistId}, malId=${ids.malId}, kitsuId=${ids.kitsuId}, simklId=${ids.simklId}, title=${ids.title}',
    );
    for (final entry in results.entries) {
      debugPrint('--- [${entry.key}] ---');
      debugPrint(encoder.convert(entry.value));
    }
    debugPrint('=== EPISODE METADATA API TEST END ===');

    return encoder.convert({
      'targets': {
        'anilistId': ids.anilistId,
        'malId': ids.malId,
        'kitsuId': ids.kitsuId,
        'simklId': ids.simklId,
        'title': ids.title,
      },
      'providers': results,
    });
  }
}
