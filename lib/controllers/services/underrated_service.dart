import 'dart:convert';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/models_convertor/carousel/carousel_data.dart';
import 'package:anymex/utils/logger.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

/// Model for underrated entry with extra metadata
class UnderratedEntry {
  final int anilistId;
  final String? title;
  final String? recommendedBy;
  final String? reason;

  UnderratedEntry({
    required this.anilistId,
    this.title,
    this.recommendedBy,
    this.reason,
  });

  factory UnderratedEntry.fromJson(Map<String, dynamic> json) {
    return UnderratedEntry(
      anilistId: json['anilist_id'] ?? json['id'] ?? 0,
      title: json['title'],
      recommendedBy: json['recommended_by'],
      reason: json['reason'],
    );
  }
}

/// Service to fetch underrated anime/manga from a GitHub JSON file
class UnderratedService extends GetxController {
  // GitHub raw URLs for the JSON files
  static const String _animeJsonUrl =
      'https://raw.githubusercontent.com/Shebyyy/AnymeX-Preview/beta/underrated_anime.json';
  static const String _mangaJsonUrl =
      'https://raw.githubusercontent.com/Shebyyy/AnymeX-Preview/beta/underrated_manga.json';

  // AniList GraphQL endpoint
  static const String _anilistApi = 'https://graphql.anilist.co';

  // Observable lists for underrated content with extra metadata
  RxList<UnderratedMedia> underratedAnimes = <UnderratedMedia>[].obs;
  RxList<UnderratedMedia> underratedMangas = <UnderratedMedia>[].obs;

  // Loading states
  RxBool isLoadingAnime = false.obs;
  RxBool isLoadingManga = false.obs;

  // Error states
  RxString animeError = ''.obs;
  RxString mangaError = ''.obs;

  /// Fetch media details from AniList by ID
  Future<Media?> _fetchMediaFromAnilist(int anilistId, bool isManga) async {
    final String mediaType = isManga ? 'MANGA' : 'ANIME';
    final String query = '''
      query (\$id: Int, \$type: MediaType) {
        Media(id: \$id, type: \$type) {
          id
          idMal
          title {
            romaji
            english
            native
          }
          description(asHtml: false)
          coverImage {
            large
            extraLarge
            color
          }
          bannerImage
          episodes
          chapters
          status
          averageScore
          popularity
          genres
          format
          season
          seasonYear
          studios(isMain: true) {
            nodes {
              name
            }
          }
          nextAiringEpisode {
            airingAt
            timeUntilAiring
            episode
          }
        }
      }
    ''';

    try {
      final response = await http.post(
        Uri.parse(_anilistApi),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'query': query,
          'variables': {
            'id': anilistId,
            'type': mediaType,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final mediaData = data['data']?['Media'];
        if (mediaData != null) {
          return Media.fromUnderratedAnilist(mediaData, isManga);
        }
      } else {
        Logger.i('Failed to fetch media $anilistId: ${response.statusCode}');
      }
    } catch (e) {
      Logger.i('Error fetching media $anilistId: $e');
    }
    return null;
  }

  /// Fetch underrated anime from GitHub JSON
  Future<void> fetchUnderratedAnime() async {
    if (underratedAnimes.isNotEmpty) return; // Already fetched

    isLoadingAnime.value = true;
    animeError.value = '';

    try {
      final response = await http.get(Uri.parse(_animeJsonUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final entries = data.map((e) => UnderratedEntry.fromJson(e)).toList();
        
        // Fetch media details for each entry
        final results = await Future.wait(
          entries.map((entry) async {
            final media = await _fetchMediaFromAnilist(entry.anilistId, false);
            if (media != null) {
              return UnderratedMedia(
                media: media,
                recommendedBy: entry.recommendedBy,
                reason: entry.reason,
                fallbackTitle: entry.title,
              );
            }
            return null;
          }),
        );

        underratedAnimes.value = results.whereType<UnderratedMedia>().toList();
        Logger.i('Fetched ${underratedAnimes.length} underrated anime');
      } else {
        animeError.value = 'Failed to load: ${response.statusCode}';
        Logger.i('Failed to fetch underrated anime: ${response.statusCode}');
      }
    } catch (e) {
      animeError.value = 'Error: $e';
      Logger.i('Error fetching underrated anime: $e');
    } finally {
      isLoadingAnime.value = false;
    }
  }

  /// Fetch underrated manga from GitHub JSON
  Future<void> fetchUnderratedManga() async {
    if (underratedMangas.isNotEmpty) return; // Already fetched

    isLoadingManga.value = true;
    mangaError.value = '';

    try {
      final response = await http.get(Uri.parse(_mangaJsonUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final entries = data.map((e) => UnderratedEntry.fromJson(e)).toList();
        
        // Fetch media details for each entry
        final results = await Future.wait(
          entries.map((entry) async {
            final media = await _fetchMediaFromAnilist(entry.anilistId, true);
            if (media != null) {
              return UnderratedMedia(
                media: media,
                recommendedBy: entry.recommendedBy,
                reason: entry.reason,
                fallbackTitle: entry.title,
              );
            }
            return null;
          }),
        );

        underratedMangas.value = results.whereType<UnderratedMedia>().toList();
        Logger.i('Fetched ${underratedMangas.length} underrated manga');
      } else {
        mangaError.value = 'Failed to load: ${response.statusCode}';
        Logger.i('Failed to fetch underrated manga: ${response.statusCode}');
      }
    } catch (e) {
      mangaError.value = 'Error: $e';
      Logger.i('Error fetching underrated manga: $e');
    } finally {
      isLoadingManga.value = false;
    }
  }

  /// Fetch both anime and manga
  Future<void> fetchAll() async {
    await Future.wait([
      fetchUnderratedAnime(),
      fetchUnderratedManga(),
    ]);
  }

  /// Refresh all data (force reload)
  Future<void> refresh() async {
    underratedAnimes.clear();
    underratedMangas.clear();
    await fetchAll();
  }
}

/// Wrapper class for media with underrated metadata
class UnderratedMedia {
  final Media media;
  final String? recommendedBy;
  final String? reason;
  final String? fallbackTitle;

  UnderratedMedia({
    required this.media,
    this.recommendedBy,
    this.reason,
    this.fallbackTitle,
  });

  /// Get display title (use fallback if media title is empty)
  String get displayTitle => media.title.isNotEmpty ? media.title : (fallbackTitle ?? 'Unknown');

  /// Get display description (use reason if available)
  String get displayDescription => reason ?? media.description;

  /// Convert to CarouselData for display in carousel
  CarouselData toCarouselData({bool isManga = false}) {
    return CarouselData(
      id: media.id.toString(),
      title: displayTitle,
      poster: media.poster,
      extraData: media.rating.toString(),
      servicesType: ServicesType.anilist,
      releasing: media.status == "RELEASING",
      recommendedBy: recommendedBy,
      reason: reason,
    );
  }
}
