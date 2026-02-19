import 'dart:convert';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:anymex/database/data_keys/keys.dart';

class RecommendationCache {
  static final Map<String, List<Media>> _cache = {};
  static final Map<String, int> _pageCache = {};
  
  static List<Media>? get(String key, int page) {
    final cacheKey = '$key:$page';
    return _cache[cacheKey];
  }
  
  static void set(String key, int page, List<Media> items) {
    final cacheKey = '$key:$page';
    _cache[cacheKey] = items;
    _pageCache[key] = page;
  }
  
  static int getCurrentPage(String key) {
    return _pageCache[key] ?? 1;
  }
  
  static void clear() {
    _cache.clear();
    _pageCache.clear();
  }
}

class AnimeSproutOptions {
  final bool extraSeasons;
  final bool movies;
  final bool specials;
  final bool music;

  const AnimeSproutOptions({
    this.extraSeasons = true,
    this.movies = true,
    this.specials = true,
    this.music = false,
  });

  Map<String, String> toQueryParams({String? source}) {
    return {
      if (source != null) 'source': source,
      if (extraSeasons) 'exs': 'true',
      if (specials) 'specials': 'true',
      if (movies) 'movies': 'true',
      if (music) 'music': 'true',
    };
  }
}

Future<List<Media>> getAiRecommendations(
  bool isManga,
  int page, {
  bool isAdult = false,
  String? username,
  AnimeSproutOptions options = const AnimeSproutOptions(),
  bool refresh = false,
}) async {
  final service = Get.find<ServiceHandler>();
  final isAL = service.serviceType.value == ServicesType.anilist;
  final userName =
      username?.trim() ?? service.onlineService.profileData.value.name ?? '';

  if (userName.isEmpty) {
    snackBar('Please log in to get recommendations');
    return [];
  }

  final cacheKey = '${isManga ? 'manga' : 'anime'}:$userName:${isAL ? 'al' : 'mal'}:${isAdult ? 'adult' : 'sfw'}';
  
  if (!refresh) {
    final cached = RecommendationCache.get(cacheKey, page);
    if (cached != null) {
      return cached;
    }
  }

  final Set<String> trackedIds = _buildTrackedIdSet(service, isAL);

  List<Media> results = [];

  if (isManga) {
    results = await _fetchNativeRecommendations(
      isManga: true,
      isAL: isAL,
      page: page,
      isAdult: isAdult,
    );
  } else {
    final futures = await Future.wait([
      _fetchAnimeSproutRecommendations(
        userName: userName,
        isAL: isAL,
        options: options,
        trackedIds: trackedIds,
        isAdult: isAdult,
      ),
      _fetchNativeRecommendations(
        isManga: false,
        isAL: isAL,
        page: page,
        isAdult: isAdult,
      ),
    ], eagerError: false);

    final sproutRecs = futures[0];
    final nativeRecs = futures[1];

    final seenIds = <String>{};
    
    for (final m in sproutRecs) {
      if (m.id != null && seenIds.add(m.id!)) {
        results.add(m);
      }
    }
    
    for (final m in nativeRecs) {
      if (m.id != null && seenIds.add(m.id!)) {
        results.add(m);
      }
    }
  }

  results = results
      .where((m) => m.id != null && !trackedIds.contains(m.id!))
      .toList();

  final seen = <String>{};
  results = results.where((m) => m.id != null && seen.add(m.id!)).toList();

  if (results.isEmpty && page == 1) {
    snackBar('No recommendations found');
  }

  RecommendationCache.set(cacheKey, page, results);

  return results;
}

Set<String> _buildTrackedIdSet(ServiceHandler service, bool isAL) {
  final ids = <String>{};
  try {
    if (isAL) {
      for (final m in service.anilistService.animeList) {
        if (m.id != null) ids.add(m.id!);
      }
      for (final m in service.anilistService.mangaList) {
        if (m.id != null) ids.add(m.id!);
      }
    } else {
      for (final m in service.malService.animeList) {
        if (m.id != null) ids.add(m.id!);
      }
      for (final m in service.malService.mangaList) {
        if (m.id != null) ids.add(m.id!);
      }
    }
  } catch (e) {
    Logger.i('Error building tracked IDs: $e');
  }
  return ids;
}

Future<List<Media>> _fetchAnimeSproutRecommendations({
  required String userName,
  required bool isAL,
  required AnimeSproutOptions options,
  required Set<String> trackedIds,
  required bool isAdult,
}) async {
  try {
    final source = isAL ? 'anilist' : null;
    final params = options.toQueryParams(source: source);
    
    final uri = Uri.https(
      'anime.ameo.dev',
      '/user/$userName/recommendations',
      params,
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      Logger.i('AnimeSprout failed: ${response.statusCode}');
      return [];
    }

    final body = response.body;
    final jsonStart = body.indexOf('"initialRecommendations"');
    if (jsonStart == -1) return [];

    final scriptStart = body.lastIndexOf('<script', jsonStart);
    final scriptEnd = body.indexOf('</script>', jsonStart);
    if (scriptStart == -1 || scriptEnd == -1) return [];

    final scriptContent = body.substring(scriptStart, scriptEnd);
    final jsonTagStart = scriptContent.indexOf('{');
    if (jsonTagStart == -1) return [];

    final jsonStr = scriptContent.substring(jsonTagStart);
    final jsonData = jsonDecode(jsonStr) as Map<String, dynamic>;

    final initialRecs = jsonData['initialRecommendations'] as Map<String, dynamic>?;
    if (initialRecs == null || initialRecs['type'] != 'ok') return [];

    final recommendations = initialRecs['recommendations'] as List<dynamic>;
    final animeData = initialRecs['animeData'] as Map<String, dynamic>;

    final List<Media> results = [];
    final batchSize = 20;
    int processed = 0;

    for (final rec in recommendations) {
      if (processed >= 50) break;

      final malId = rec['id']?.toString();
      if (malId == null) continue;

      final data = animeData[malId] as Map<String, dynamic>?;
      if (data == null) continue;

      if (rec['planToWatch'] == true) continue;

      if (!isAdult) {
        final nsfw = data['nsfw'] == true || 
                     (data['genres'] as List?)?.any((g) => 
                       ['HENTAI', 'EROTICA'].contains(g['name']?.toUpperCase())) == true;
        if (nsfw) continue;
      }

      final title = (data['alternative_titles'] as Map?)?['en'] as String?;
      final titleFallback = data['title'] as String?;
      final picture = (data['main_picture'] as Map?)?['large'] as String?;
      final synopsis = data['synopsis'] as String?;
      final genres = (data['genres'] as List?)
          ?.map((g) => (g['name'] as String).toUpperCase())
          .toList();

      String? resolvedId;
      if (isAL) {
        resolvedId = await _getAnilistIdFromMal(malId);
        resolvedId ??= malId;
      } else {
        resolvedId = malId;
      }

      if (trackedIds.contains(resolvedId)) continue;

      results.add(Media(
        id: resolvedId,
        title: (title?.isNotEmpty == true ? title : titleFallback) ?? 'Unknown',
        poster: picture ?? '',
        description: synopsis ?? '',
        serviceType: isAL ? ServicesType.anilist : ServicesType.mal,
        genres: genres ?? [],
      ));
      
      processed++;
    }

    return results;
  } catch (e) {
    Logger.i('AnimeSprout fetch error: $e');
    return [];
  }
}

final Map<String, String> _malToAnilistCache = {};

Future<String?> _getAnilistIdFromMal(String malId) async {
  if (_malToAnilistCache.containsKey(malId)) {
    return _malToAnilistCache[malId];
  }

  try {
    final token = AuthKeys.authToken.get<String?>();
    final query = '''
    query(\$idMal: Int) {
      Media(idMal: \$idMal, type: ANIME) {
        id
      }
    }
    ''';

    final response = await http.post(
      Uri.parse('https://graphql.anilist.co'),
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'query': query,
        'variables': {'idMal': int.tryParse(malId)},
      }),
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final id = data['data']?['Media']?['id']?.toString();
      if (id != null) {
        _malToAnilistCache[malId] = id;
        return id;
      }
    }
  } catch (e) {
    Logger.i('MAL->AL conversion error for $malId: $e');
  }
  return null;
}

Future<List<Media>> _fetchNativeRecommendations({
  required bool isManga,
  required bool isAL,
  required int page,
  required bool isAdult,
}) async {
  if (isAL) {
    return _fetchAnilistRecommendations(
      isManga: isManga, 
      page: page,
      isAdult: isAdult,
    );
  } else {
    return _fetchMalRecommendations(
      isManga: isManga, 
      page: page,
      isAdult: isAdult,
    );
  }
}

Future<List<Media>> _fetchAnilistRecommendations({
  required bool isManga,
  required int page,
  required bool isAdult,
}) async {
  try {
    final token = AuthKeys.authToken.get<String?>();
    if (token == null) return [];

    final query = '''
    query(\$page: Int, \$type: MediaType, \$isAdult: Boolean) {
      Page(page: \$page, perPage: 30) {
        recommendations(sort: RATING_DESC, onList: true) {
          mediaRecommendation {
            id
            title { romaji english }
            coverImage { large }
            description
            genres
            type
            isAdult
            mediaListEntry { status }
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
      },
      body: jsonEncode({
        'query': query,
        'variables': {
          'page': page,
          'type': isManga ? 'MANGA' : 'ANIME',
          'isAdult': isAdult,
        },
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      Logger.i('AniList recommendations failed: ${response.statusCode}');
      return [];
    }

    final data = jsonDecode(response.body);
    final recs = data['data']?['Page']?['recommendations'] as List<dynamic>?;
    if (recs == null) return [];

    final results = <Media>[];
    for (final rec in recs) {
      final media = rec['mediaRecommendation'] as Map<String, dynamic>?;
      if (media == null) continue;

      if (media['mediaListEntry'] != null) continue;
      if (!isAdult && media['isAdult'] == true) continue;

      final id = media['id']?.toString();
      if (id == null) continue;

      final titleMap = media['title'] as Map?;
      final title = (titleMap?['english'] as String?)?.isNotEmpty == true
          ? titleMap!['english'] as String
          : titleMap?['romaji'] as String? ?? 'Unknown';

      results.add(Media(
        id: id,
        title: title,
        poster: (media['coverImage'] as Map?)?['large'] as String? ?? '',
        description: media['description'] as String? ?? '',
        serviceType: ServicesType.anilist,
        genres: ((media['genres'] as List?) ?? [])
            .map((g) => g.toString().toUpperCase())
            .toList(),
      ));
    }

    return results;
  } catch (e) {
    Logger.i('AniList recommendations error: $e');
    return [];
  }
}

Future<List<Media>> _fetchMalRecommendations({
  required bool isManga,
  required int page,
  required bool isAdult,
}) async {
  try {
    final type = isManga ? 'manga' : 'anime';
    final url = 'https://api.jikan.moe/v4/recommendations/$type?page=$page';

    final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      Logger.i('Jikan recommendations failed: ${response.statusCode}');
      return [];
    }

    final data = jsonDecode(response.body);
    final pagination = data['pagination'] as Map<String, dynamic>?;
    final recs = data['data'] as List<dynamic>?;
    if (recs == null) return [];

    final results = <Media>[];
    final seen = <String>{};

    for (final rec in recs) {
      final entries = rec['entry'] as List<dynamic>?;
      if (entries == null) continue;

      for (final entry in entries) {
        final malId = entry['mal_id']?.toString();
        if (malId == null || !seen.add(malId)) continue;

        if (!isAdult) {
          final genres = entry['genres'] as List? ?? [];
          final isNsfw = genres.any((g) => 
            ['Hentai', 'Erotica'].contains(g['name']));
          if (isNsfw) continue;
        }

        final title = entry['title'] as String? ?? 'Unknown';
        final imageUrl = (entry['images'] as Map?)?['jpg']?['large_image_url'] as String?;
        final synopsis = entry['synopsis'] as String?;

        results.add(Media(
          id: malId,
          title: title,
          poster: imageUrl ?? '',
          description: synopsis ?? '',
          serviceType: ServicesType.mal,
          genres: [],
        ));
      }
    }

    return results;
  } catch (e) {
    Logger.i('Jikan recommendations error: $e');
    return [];
  }
}
