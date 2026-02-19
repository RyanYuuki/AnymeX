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

  final cacheKey =
      '${isManga ? 'manga' : 'anime'}:$userName:${isAL ? 'al' : 'mal'}:${isAdult ? 'adult' : 'sfw'}';

  if (!refresh) {
    final cached = RecommendationCache.get(cacheKey, page);
    if (cached != null) {
      return cached;
    }
  }

  final trackedIds = _buildTrackedIdSet(service, isAL);

  List<Media> results = [];

  final List<Future<List<Media>>> futures = [];

  if (!isManga) {
    futures.add(_fetchAnimeSproutRecommendations(
      userName: userName,
      isAL: isAL,
      options: options,
      trackedIds: trackedIds,
      isAdult: isAdult,
    ));
  }

  futures.add(_fetchNativeRecommendations(
    isManga: isManga,
    isAL: isAL,
    page: page,
    isAdult: isAdult,
  ));

  final resultsList = await Future.wait(futures, eagerError: false);

  final Map<String, Media> uniqueMap = {};

  for (final recList in resultsList) {
    for (final media in recList) {
      if (media.id != null && !trackedIds.contains(media.id)) {
        bool isDuplicate = false;
        for (final existingId in uniqueMap.keys) {
          if (existingId == media.id) {
            isDuplicate = true;
            break;
          }
          if (isAL && media.idMal.isNotEmpty) {
            final existingMedia = uniqueMap[existingId];
            if (existingMedia?.idMal == media.idMal) {
              isDuplicate = true;
              break;
            }
          }
        }

        if (!isDuplicate) {
          uniqueMap[media.id!] = media;
        }
      }
    }
  }

  results = uniqueMap.values.toList();

  // Enhanced adult content filter
  if (!isAdult) {
    results = results.where((media) {
      // Check genres for adult content
      final hasAdultGenres = media.genres.any((g) {
        final genre = g.toUpperCase();
        return genre.contains('HENTAI') || 
               genre.contains('EROTICA') || 
               genre.contains('ADULT') || 
               genre.contains('18+') ||
               genre.contains('ECCHI') ||
               genre.contains('MATURE');
      });
      
      final isMediaAdult = media.isAdult == true;
      
      // Check title for adult indicators
      final titleHasAdult = media.title.toLowerCase().contains('hentai') ||
                           media.title.toLowerCase().contains('erotica') ||
                           media.title.toLowerCase().contains('nsfw');
      
      return !hasAdultGenres && !isMediaAdult && !titleHasAdult;
    }).toList();
  }

  const int pageSize = 30;
  final startIndex = (page - 1) * pageSize;
  if (startIndex < results.length) {
    final endIndex = (startIndex + pageSize).clamp(0, results.length);
    results = results.sublist(startIndex, endIndex);
  } else {
    results = [];
  }

  if (results.isEmpty && page == 1) {
    snackBar('No recommendations found');
  }

  RecommendationCache.set(cacheKey, page, results);
  return results;
}

Future<void> loadNextPage({
  required bool isManga,
  required int currentPage,
  required bool showAdult,
  required bool hasMorePages,
  required List<Media> recommendations,
  required void Function(
          List<Media> updated, int newPage, bool morePages, bool isLoading)
      onUpdate,
}) async {
  if (!hasMorePages) return;

  onUpdate(recommendations, currentPage, hasMorePages, true);

  final nextPage = currentPage + 1;
  final moreRecs = await getAiRecommendations(
    isManga,
    nextPage,
    isAdult: showAdult,
    refresh: false,
  );

  if (moreRecs.isNotEmpty) {
    onUpdate(
      [...recommendations, ...moreRecs],
      nextPage,
      moreRecs.length >= 30,
      false,
    );
  } else {
    onUpdate(recommendations, currentPage, false, false);
  }
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

    final initialRecs =
        jsonData['initialRecommendations'] as Map<String, dynamic>?;
    if (initialRecs == null || initialRecs['type'] != 'ok') return [];

    final recommendations = initialRecs['recommendations'] as List<dynamic>;
    final animeData = initialRecs['animeData'] as Map<String, dynamic>;

    final List<Media> results = [];
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
                    ['HENTAI', 'EROTICA']
                        .contains(g['name']?.toUpperCase())) ==
                true;
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
      } else {
        resolvedId = malId;
      }

      if (trackedIds.contains(resolvedId)) continue;

      results.add(Media(
        id: resolvedId ?? '',
        idMal: malId,
        title:
            (title?.isNotEmpty == true ? title : titleFallback) ?? 'Unknown',
        romajiTitle: titleFallback ?? 'Unknown',
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

    // Fixed query - removed unused $type variable
    final query = '''
    query(\$page: Int) {
      Page(page: \$page, perPage: 50) {
        recommendations(sort: RATING_DESC) {
          mediaRecommendation {
            id
            idMal
            title {
              romaji
              english
              native
            }
            coverImage {
              large
              color
            }
            description
            genres
            type
            isAdult
            averageScore
            format
            status
            episodes
            chapters
            volumes
          }
        }
      }
    }
    ''';

    Logger.i('Fetching AniList recommendations for page $page');

    final response = await http.post(
      Uri.parse('https://graphql.anilist.co'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'query': query,
        'variables': {
          'page': page,
        },
      }),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 429) {
      Logger.i('Rate limited, waiting 3 seconds...');
      await Future.delayed(const Duration(seconds: 3));
      return _fetchAnilistRecommendations(
        isManga: isManga, 
        page: page, 
        isAdult: isAdult
      );
    }

    if (response.statusCode != 200) {
      Logger.i('AniList recommendations failed: ${response.statusCode}');
      return [];
    }

    final data = jsonDecode(response.body);
    final recs = data['data']?['Page']?['recommendations'] as List<dynamic>?;
    if (recs == null || recs.isEmpty) {
      Logger.i('No recommendations found');
      return [];
    }

    final results = <Media>[];
    final seenIds = <String>{};

    for (final rec in recs) {
      final media = rec['mediaRecommendation'] as Map<String, dynamic>?;
      if (media == null) continue;

      // Filter by type client-side
      final mediaType = media['type'] as String?;
      if (mediaType == null) continue;
      
      if (isManga && mediaType != 'MANGA') continue;
      if (!isManga && mediaType != 'ANIME') continue;

      // Adult content filter
      if (!isAdult && media['isAdult'] == true) continue;

      final id = media['id']?.toString();
      if (id == null || !seenIds.add(id)) continue;

      final titleMap = media['title'] as Map?;
      String title = 'Unknown';
      String romajiTitle = 'Unknown';
      if (titleMap != null) {
        title = titleMap['english'] ??
            titleMap['romaji'] ??
            titleMap['native'] ??
            'Unknown';
        romajiTitle = titleMap['romaji'] ?? title;
      }

      // Check for adult content in genres
      final genres = (media['genres'] as List?)
          ?.map((g) => g.toString().toUpperCase())
          .where((g) => g.isNotEmpty)
          .toList() ?? [];

      if (!isAdult) {
        final hasAdultGenres = genres.any((g) =>
            ['HENTAI', 'EROTICA', 'ADULT', '18+', 'ECCHI'].contains(g));
        if (hasAdultGenres) continue;
      }

      final coverImage = media['coverImage'] as Map?;
      final poster = coverImage?['large'] as String? ?? '';

      results.add(Media(
        id: id,
        idMal: media['idMal']?.toString() ?? '',
        title: title,
        romajiTitle: romajiTitle,
        poster: poster,
        description: media['description'] as String? ?? '',
        serviceType: ServicesType.anilist,
        genres: genres,
        rating: media['averageScore']?.toString() ?? '0',
        format: media['format']?.toString() ?? '',
        totalEpisodes: media['episodes']?.toString() ?? '0',
        totalChapters: media['chapters']?.toString() ?? '0',
        status: media['status']?.toString() ?? '',
        isAdult: media['isAdult'] as bool?,
      ));
    }

    Logger.i('Fetched ${results.length} AniList recommendations');
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

    final response =
        await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
    
    if (response.statusCode == 429) {
      Logger.i('Jikan rate limited, waiting...');
      await Future.delayed(const Duration(seconds: 2));
      return _fetchMalRecommendations(
        isManga: isManga, 
        page: page, 
        isAdult: isAdult
      );
    }

    if (response.statusCode != 200) {
      Logger.i('Jikan recommendations failed: ${response.statusCode}');
      return [];
    }

    final data = jsonDecode(response.body);
    final recs = data['data'] as List<dynamic>?;
    if (recs == null) return [];

    final results = <Media>[];
    final seen = <String>{};

    // Adult content keywords to filter
    final adultKeywords = [
      'Hentai', 'Erotica', 'Ecchi', 'Adult', '18+', 
      'Sex', 'Porn', 'NSFW', 'Mature'
    ];

    for (final rec in recs) {
      final entries = rec['entry'] as List<dynamic>?;
      if (entries == null) continue;

      for (final entry in entries) {
        final malId = entry['mal_id']?.toString();
        if (malId == null || !seen.add(malId)) continue;

        // Check multiple sources for adult content
        bool isAdultContent = false;

        // Check genres
        final genres = entry['genres'] as List? ?? [];
        isAdultContent = genres.any((g) {
          final genreName = g['name']?.toString() ?? '';
          return adultKeywords.any((keyword) => 
            genreName.toLowerCase().contains(keyword.toLowerCase()));
        });

        // Check demographics
        if (!isAdultContent) {
          final demographics = entry['demographics'] as List? ?? [];
          isAdultContent = demographics.any((d) {
            final demoName = d['name']?.toString() ?? '';
            return adultKeywords.any((keyword) => 
              demoName.toLowerCase().contains(keyword.toLowerCase()));
          });
        }

        // Check explicit/genre tags
        if (!isAdultContent) {
          final explicitGenres = entry['explicit_genres'] as List? ?? [];
          isAdultContent = explicitGenres.isNotEmpty;
        }

        // Check rating
        if (!isAdultContent) {
          final rating = entry['rating']?.toString() ?? '';
          isAdultContent = rating.toLowerCase().contains('rx') || 
                          rating.toLowerCase().contains('hentai');
        }

        // Filter if not adult mode and content is adult
        if (!isAdult && isAdultContent) {
          Logger.i('Filtered adult content: ${entry['title']}');
          continue;
        }

        final title = entry['title'] as String? ?? 'Unknown';
        final imageUrl =
            (entry['images'] as Map?)?['jpg']?['large_image_url'] as String?;
        final synopsis = entry['synopsis'] as String?;

        results.add(Media(
          id: malId,
          idMal: malId,
          title: title,
          romajiTitle: title,
          poster: imageUrl ?? '',
          description: synopsis ?? '',
          serviceType: ServicesType.mal,
          genres: genres.map((g) => g['name']?.toString() ?? '').toList(),
          isAdult: isAdultContent,
        ));
      }
    }

    Logger.i('Fetched ${results.length} MAL recommendations');
    return results;
  } catch (e) {
    Logger.i('Jikan recommendations error: $e');
    return [];
  }
}
