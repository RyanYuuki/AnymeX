import 'dart:convert';

import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/mal/mal_api.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/models/Anilist/anilist_media_user.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class MissingSequelController extends GetxController {
  final RxList<Media> missingAnimeSequels = <Media>[].obs;
  final RxList<Media> missingMangaSequels = <Media>[].obs;

  String _lastAnimeFingerprint = '';
  String _lastMangaFingerprint = '';
  String _cachePrefix = '';

  void ensureAnimeDetection() {
    final handler = Get.find<ServiceHandler>();
    final fp = _buildFingerprint(handler.animeList);
    if (fp == _lastAnimeFingerprint) return;
    _lastAnimeFingerprint = fp;
    _detectAnimeSequels();
  }

  void ensureMangaDetection() {
    final handler = Get.find<ServiceHandler>();
    final fp = _buildFingerprint(handler.mangaList);
    if (fp == _lastMangaFingerprint) return;
    _lastMangaFingerprint = fp;
    _detectMangaSequels();
  }

  @override
  void onInit() {
    super.onInit();
    final handler = Get.find<ServiceHandler>();
    _cachePrefix = handler.serviceType.value.name;
    ever(handler.serviceType, (_) {
      _cachePrefix = handler.serviceType.value.name;
      reset();
    });
  }

  void reset() {
    _lastAnimeFingerprint = '';
    _lastMangaFingerprint = '';
    missingAnimeSequels.clear();
    missingMangaSequels.clear();
  }

  String _buildFingerprint(RxList<TrackedMedia> fullList) {
    final completedIds = fullList
        .where((m) => m.watchingStatus == 'COMPLETED')
        .map((m) => m.id ?? '')
        .where((id) => id.isNotEmpty)
        .toList()
      ..sort();

    final allIds = fullList
        .map((m) => m.id ?? '')
        .where((id) => id.isNotEmpty)
        .toList()
      ..sort();

    return '${completedIds.join(',')}|${allIds.join(',')}';
  }

  bool _tryLoadFromCache(
    String key,
    RxList<Media> target,
    String currentFingerprint,
  ) {
    final cacheKey = '${_cachePrefix}_sequel_$key';
    final hashKey = '${_cachePrefix}_sequel_${key}_hash';

    final cachedHash = KvHelper.get<String?>(hashKey);
    if (cachedHash != null && cachedHash == currentFingerprint) {
      final cachedJson = KvHelper.get<String?>(cacheKey);
      if (cachedJson != null) {
        try {
          final list = (jsonDecode(cachedJson) as List<dynamic>)
              .map((e) => _mediaFromCacheJson(Map<String, dynamic>.from(e)))
              .whereType<Media>()
              .toList();
          target.assignAll(list);
          return true;
        } catch (e) {
          Logger.i('Failed to load cached sequels for $key: $e');
        }
      }
    }
    return false;
  }

  void _saveToCache(
    String key,
    List<Media> results,
    String fingerprint,
  ) {
    final cacheKey = '${_cachePrefix}_sequel_$key';
    final hashKey = '${_cachePrefix}_sequel_${key}_hash';

    try {
      final jsonList = results
          .map((m) => _mediaToCacheJson(m))
          .toList();
      KvHelper.set(cacheKey, jsonEncode(jsonList));
      KvHelper.set(hashKey, fingerprint);
    } catch (e) {
      Logger.i('Failed to cache sequels for $key: $e');
    }
  }

  Map<String, dynamic> _mediaToCacheJson(Media m) {
    return {
      'id': m.id,
      'idMal': m.idMal,
      'title': m.title,
      'romajiTitle': m.romajiTitle,
      'poster': m.poster,
      'largePoster': m.largePoster,
      'status': m.status,
      'rating': m.rating,
      'format': m.format,
      'totalEpisodes': m.totalEpisodes,
      'mediaType': m.mediaType.index,
      'serviceType': m.serviceType.index,
    };
  }

  Media? _mediaFromCacheJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    if (id.isEmpty) return null;
    return Media(
      id: id,
      idMal: json['idMal']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      romajiTitle: json['romajiTitle']?.toString() ?? '',
      poster: json['poster']?.toString() ?? '',
      largePoster: json['largePoster']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      rating: json['rating']?.toString() ?? '',
      format: json['format']?.toString() ?? '',
      totalEpisodes: json['totalEpisodes']?.toString() ?? '',
      mediaType: ItemType.values[json['mediaType'] as int? ?? 0],
      serviceType: ServicesType.values[json['serviceType'] as int? ?? 0],
    );
  }

  Future<void> _detectAnimeSequels() async {
    try {
      final handler = Get.find<ServiceHandler>();
      final serviceType = handler.serviceType.value;

      if (serviceType == ServicesType.extensions ||
          !handler.isLoggedIn.value) {
        return;
      }

      final fingerprint = _buildFingerprint(handler.animeList);

      if (_tryLoadFromCache('anime', missingAnimeSequels, fingerprint)) {
        return;
      }

      final completedAnime = handler.animeList
          .where((m) => m.watchingStatus == 'COMPLETED')
          .toList();

      if (completedAnime.isEmpty) return;

      final Set<String> userAnimeIds = _collectUserIds(handler.animeList);

      if (serviceType == ServicesType.anilist) {
        await _detectAnilistAnimeSequels(completedAnime, userAnimeIds);
      } else if (serviceType == ServicesType.mal) {
        await _detectMalAnimeSequels(completedAnime, userAnimeIds);
      }

      _saveToCache('anime', missingAnimeSequels.toList(), fingerprint);
    } catch (e) {
      Logger.i('Error in anime sequel detection: $e');
    }
  }

  Future<void> _detectMangaSequels() async {
    try {
      final handler = Get.find<ServiceHandler>();
      final serviceType = handler.serviceType.value;

      if (serviceType == ServicesType.extensions ||
          !handler.isLoggedIn.value) {
        return;
      }

      final fingerprint = _buildFingerprint(handler.mangaList);

      if (_tryLoadFromCache('manga', missingMangaSequels, fingerprint)) {
        return;
      }

      final completedManga = handler.mangaList
          .where((m) => m.watchingStatus == 'COMPLETED')
          .toList();

      if (completedManga.isEmpty) return;

      final Set<String> userMangaIds = _collectUserIds(handler.mangaList);

      if (serviceType == ServicesType.anilist) {
        await _detectAnilistMangaSequels(completedManga, userMangaIds);
      } else if (serviceType == ServicesType.mal) {
        await _detectMalMangaSequels(completedManga, userMangaIds);
      }

      _saveToCache('manga', missingMangaSequels.toList(), fingerprint);
    } catch (e) {
      Logger.i('Error in manga sequel detection: $e');
    }
  }

  Set<String> _collectUserIds(RxList<TrackedMedia> list) {
    final ids = <String>{};
    for (final m in list) {
      if (m.id != null) ids.add(m.id!);
      if (m.idMal != null) ids.add(m.idMal!);
    }
    return ids;
  }

  void _addIfNew(RxList<Media> target, Media media) {
    if (target.any((m) => m.id == media.id)) return;
    target.add(media);
  }

  static const int _anilistBatchSize = 50;

  static const _relevantRelationTypes = {
    'SEQUEL',
    'PREQUEL',
    'SPIN_OFF',
    'SIDE_STORY',
    'ALTERNATIVE',
    'ALTERNATIVE_SETTING',
    'SUMMARY',
    'FULL',
    'PARENT',
  };

  Future<void> _detectAnilistAnimeSequels(
    List<TrackedMedia> completed,
    Set<String> userIds,
  ) async {
    final token = AuthKeys.authToken.get<String?>();
    if (token == null) return;

    final ids = completed
        .map((m) => int.tryParse(m.id ?? ''))
        .whereType<int>()
        .toList();

    final batches = _chunkList(ids, _anilistBatchSize);
    final seenIds = <int>{};

    for (final batch in batches) {
      try {
        final results = await _fetchAnilistRelations(
          ids: batch,
          token: token,
          mediaType: 'ANIME',
        );

        for (final item in results) {
          if (seenIds.contains(item.idParsed)) continue;
          if (userIds.contains(item.id) || userIds.contains(item.idMal)) {
            continue;
          }
          seenIds.add(item.idParsed);
          final media = _relationToMedia(item, ItemType.anime);
          if (media != null) {
            _addIfNew(missingAnimeSequels, media);
          }
        }
      } catch (e) {
        Logger.i('AniList anime sequel batch error: $e');
      }
    }
  }

  Future<void> _detectAnilistMangaSequels(
    List<TrackedMedia> completed,
    Set<String> userIds,
  ) async {
    final token = AuthKeys.authToken.get<String?>();
    if (token == null) return;

    final ids = completed
        .map((m) => int.tryParse(m.id ?? ''))
        .whereType<int>()
        .toList();

    final batches = _chunkList(ids, _anilistBatchSize);
    final seenIds = <int>{};

    for (final batch in batches) {
      try {
        final results = await _fetchAnilistRelations(
          ids: batch,
          token: token,
          mediaType: 'MANGA',
        );

        for (final item in results) {
          if (seenIds.contains(item.idParsed)) continue;
          if (userIds.contains(item.id) || userIds.contains(item.idMal)) {
            continue;
          }
          seenIds.add(item.idParsed);
          final media = _relationToMedia(item, ItemType.manga);
          if (media != null) {
            _addIfNew(missingMangaSequels, media);
          }
        }
      } catch (e) {
        Logger.i('AniList manga sequel batch error: $e');
      }
    }
  }

  Future<List<_RawRelation>> _fetchAnilistRelations({
    required List<int> ids,
    required String token,
    required String mediaType,
  }) async {
    const query = r'''
    query ($ids: [Int], $type: MediaType) {
      Page(page: 1, perPage: 50) {
        media(id_in: $ids, type: $type) {
          relations {
            edges {
              relationType
              node {
                id
                idMal
                title {
                  userPreferred
                  romaji
                  english
                }
                coverImage { large }
                type
                status
                averageScore
                format
                episodes
                chapters
              }
            }
          }
        }
      }
    }
    ''';

    final response = await http.post(
      Uri.parse('https://graphql.anilist.co'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({
        'query': query,
        'variables': {'ids': ids, 'type': mediaType},
      }),
    );

    if (response.statusCode != 200) {
      Logger.i('AniList relations query failed: ${response.statusCode}');
      return [];
    }

    final data = json.decode(response.body);
    final mediaList =
        (data['data']?['Page']?['media'] as List<dynamic>?) ?? [];

    final results = <_RawRelation>[];
    for (final media in mediaList) {
      final edges =
          (media['relations']?['edges'] as List<dynamic>?) ?? [];
      for (final edge in edges) {
        final relType = edge['relationType'] as String?;
        if (relType == null || !_relevantRelationTypes.contains(relType)) {
          continue;
        }
        final node = edge['node'];
        if (node == null) continue;

        final nodeType = node['type'] as String?;
        if (nodeType != mediaType) continue;

        results.add(_RawRelation(
          id: node['id']?.toString() ?? '',
          idMal: node['idMal']?.toString() ?? '',
          title: node['title']?['userPreferred'] ??
              node['title']?['english'] ??
              node['title']?['romaji'] ??
              '',
          romajiTitle: node['title']?['romaji'] ?? '',
          poster: node['coverImage']?['large'] ?? '',
          status: node['status'] ?? '',
          averageScore: node['averageScore'] ?? '',
          format: node['format'] ?? '',
          totalEpisodes:
              (node['episodes'] ?? node['chapters'])?.toString() ?? '',
          relationType: relType,
        ));
      }
    }
    return results;
  }

  Media? _relationToMedia(_RawRelation r, ItemType type) {
    if (r.id.isEmpty || r.poster.isEmpty) return null;
    final score = r.averageScore is int
        ? (r.averageScore / 10).toStringAsFixed(1)
        : r.averageScore.toString();
    return Media(
      id: r.id,
      idMal: r.idMal,
      title: r.title,
      romajiTitle: r.romajiTitle,
      poster: r.poster,
      largePoster: r.poster,
      status: r.status,
      rating: score,
      format: r.format,
      totalEpisodes: r.totalEpisodes,
      mediaType: type,
      serviceType: ServicesType.anilist,
    );
  }

  Future<void> _detectMalAnimeSequels(
    List<TrackedMedia> completed,
    Set<String> userIds,
  ) async {
    final malApi = Get.find<MalApi>();
    final seenIds = <String>{};

    for (int i = 0; i < completed.length; i++) {
      final item = completed[i];
      final malId = item.id;
      if (malId == null || malId.isEmpty) continue;

      try {
        final related = await malApi.request(
          'https://api.myanimelist.net/v2/anime/$malId?fields=related_anime',
        );

        if (related == null) continue;
        final relatedList =
            (related['related_anime'] as List<dynamic>?) ?? [];

        for (final rel in relatedList) {
          final node = rel['node'] as Map<String, dynamic>?;
          final relType =
              (rel['relation_type'] as String?)?.toLowerCase();
          if (node == null || relType == null) continue;
          if (!_isMalRelevantRelation(relType)) continue;

          final relId = node['id']?.toString() ?? '';
          if (relId.isEmpty || seenIds.contains(relId)) continue;
          if (userIds.contains(relId)) continue;

          seenIds.add(relId);
          final media = _malNodeToAnimeMedia(node);
          if (media != null) {
            _addIfNew(missingAnimeSequels, media);
          }
        }
      } catch (e) {
        Logger.i('MAL anime sequel error for $malId: $e');
      }

      if (i < completed.length - 1) {
        await Future.delayed(const Duration(milliseconds: 350));
      }
    }
  }

  Future<void> _detectMalMangaSequels(
    List<TrackedMedia> completed,
    Set<String> userIds,
  ) async {
    final malApi = Get.find<MalApi>();
    final seenIds = <String>{};

    for (int i = 0; i < completed.length; i++) {
      final item = completed[i];
      final malId = item.id;
      if (malId == null || malId.isEmpty) continue;

      try {
        final related = await malApi.request(
          'https://api.myanimelist.net/v2/manga/$malId?fields=related_manga',
        );

        if (related == null) continue;
        final relatedList =
            (related['related_manga'] as List<dynamic>?) ?? [];

        for (final rel in relatedList) {
          final node = rel['node'] as Map<String, dynamic>?;
          final relType =
              (rel['relation_type'] as String?)?.toLowerCase();
          if (node == null || relType == null) continue;
          if (!_isMalRelevantRelation(relType)) continue;

          final relId = node['id']?.toString() ?? '';
          if (relId.isEmpty || seenIds.contains(relId)) continue;
          if (userIds.contains(relId)) continue;

          seenIds.add(relId);
          final media = _malNodeToMangaMedia(node);
          if (media != null) {
            _addIfNew(missingMangaSequels, media);
          }
        }
      } catch (e) {
        Logger.i('MAL manga sequel error for $malId: $e');
      }

      if (i < completed.length - 1) {
        await Future.delayed(const Duration(milliseconds: 350));
      }
    }
  }

  static const _malRelevantRelations = {
    'sequel',
    'prequel',
    'spin_off',
    'side_story',
    'alternative_version',
    'alternative_setting',
    'summary',
    'full_story',
    'parent_story',
  };

  bool _isMalRelevantRelation(String type) {
    return _malRelevantRelations.contains(type);
  }

  Media? _malNodeToAnimeMedia(Map<String, dynamic> node) {
    final id = node['id']?.toString() ?? '';
    final title = node['title']?.toString() ?? '';
    final pic = node['main_picture'] as Map<String, dynamic>?;
    final poster = pic?['large'] ?? pic?['medium'] ?? '';
    if (id.isEmpty || poster.isEmpty) return null;

    return Media(
      id: id,
      idMal: id,
      title: title,
      poster: poster,
      largePoster: pic?['large'] ?? poster,
      mediaType: ItemType.anime,
      serviceType: ServicesType.mal,
    );
  }

  Media? _malNodeToMangaMedia(Map<String, dynamic> node) {
    final id = node['id']?.toString() ?? '';
    final title = node['title']?.toString() ?? '';
    final pic = node['main_picture'] as Map<String, dynamic>?;
    final poster = pic?['large'] ?? pic?['medium'] ?? '';
    if (id.isEmpty || poster.isEmpty) return null;

    return Media(
      id: id,
      idMal: id,
      title: title,
      poster: poster,
      largePoster: pic?['large'] ?? poster,
      mediaType: ItemType.manga,
      serviceType: ServicesType.mal,
    );
  }

  List<List<T>> _chunkList<T>(List<T> list, int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += size) {
      chunks.add(list.sublist(
        i,
        (i + size > list.length) ? list.length : i + size,
      ));
    }
    return chunks;
  }
}

class _RawRelation {
  final String id;
  final String idMal;
  final String title;
  final String romajiTitle;
  final String poster;
  final String status;
  final dynamic averageScore;
  final String format;
  final String totalEpisodes;
  final String relationType;

  int get idParsed => int.tryParse(id) ?? 0;

  _RawRelation({
    required this.id,
    required this.idMal,
    required this.title,
    required this.romajiTitle,
    required this.poster,
    required this.status,
    required this.averageScore,
    required this.format,
    required this.totalEpisodes,
    required this.relationType,
  });
}
