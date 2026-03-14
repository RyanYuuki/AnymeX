import 'dart:convert';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/models_convertor/carousel/carousel_data.dart';
import 'package:anymex/utils/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class UnderratedEntry {
  final int anilistId;
  final int? malId;
  final String? title;
  final int? anilistUserId;
  final int? malUserId;
  final String? author;
  final String? reason;

  UnderratedEntry({
    required this.anilistId,
    this.malId,
    this.title,
    this.anilistUserId,
    this.malUserId,
    this.author,
    this.reason,
  });

  factory UnderratedEntry.fromJson(Map<String, dynamic> json) {
    return UnderratedEntry(
      anilistId: json['anilist_id'] ?? json['id'] ?? 0,
      malId: json['mal_id'],
      title: json['title'],
      anilistUserId: json['anilist_user_id'],
      malUserId: json['mal_user_id'],
      author: json['author'],
      reason: json['reason'],
    );
  }
}

class UnderratedService extends GetxController {
  static const String _animeJsonUrl =
      'https://raw.githubusercontent.com/Shebyyy/AnymeX-Preview/beta/underrated_anime.json';
  static const String _mangaJsonUrl =
      'https://raw.githubusercontent.com/Shebyyy/AnymeX-Preview/beta/underrated_manga.json';

  static const String _anilistApi = 'https://graphql.anilist.co';

  RxList<UnderratedMedia> underratedAnimes = <UnderratedMedia>[].obs;
  RxList<UnderratedMedia> underratedMangas = <UnderratedMedia>[].obs;

  RxBool isLoadingAnime = false.obs;
  RxBool isLoadingManga = false.obs;

  RxString animeError = ''.obs;
  RxString mangaError = ''.obs;

  static const Set<String> _filteredStatuses = {'COMPLETED', 'CURRENT', 'DROPPED'};

  List<UnderratedMedia> getFilteredAnimes() {
    try {
      final anilistAuth = Get.find<AnilistAuth>();
      final userList = anilistAuth.animeList;

      final filteredIds = userList
          .where((item) => _filteredStatuses.contains(item.watchingStatus?.toUpperCase()))
          .map((item) => item.id)
          .toSet();

      return underratedAnimes.where((item) => !filteredIds.contains(item.media.id)).toList();
    } catch (e) {
      return underratedAnimes.toList();
    }
  }

  List<UnderratedMedia> getFilteredMangas() {
    try {
      final anilistAuth = Get.find<AnilistAuth>();
      final userList = anilistAuth.mangaList;

      final filteredIds = userList
          .where((item) => _filteredStatuses.contains(item.watchingStatus?.toUpperCase()))
          .map((item) => item.id)
          .toSet();

      return underratedMangas.where((item) => !filteredIds.contains(item.media.id)).toList();
    } catch (e) {
      return underratedMangas.toList();
    }
  }

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

  Future<Media?> _fetchMediaFromMAL(int malId, bool isManga) async {
    try {
      final clientId = dotenv.env['MAL_CLIENT_ID'] ?? '';
      if (clientId.isEmpty) return null;

      final endpoint = isManga ? 'manga' : 'anime';
      final fields = "fields=mean,status,media_type,synopsis,genres,num_episodes,num_chapters,rank,popularity";

      final response = await http.get(
        Uri.parse('https://api.myanimelist.net/v2/$endpoint/$malId?$fields'),
        headers: {'X-MAL-CLIENT-ID': clientId},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Media.fromMAL(data);
      } else {
        Logger.i('Failed to fetch MAL media $malId: ${response.statusCode}');
      }
    } catch (e) {
      Logger.i('Error fetching MAL media $malId: $e');
    }
    return null;
  }

  Future<String?> _fetchAnilistUsername(int userId) async {
    const String query = '''
      query (\$id: Int) {
        User(id: \$id) {
          name
        }
      }
    ''';

    try {
      final response = await http.post(
        Uri.parse(_anilistApi),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'query': query,
          'variables': {'id': userId},
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']?['User']?['name'];
      }
    } catch (e) {
      Logger.i('Error fetching AniList username for $userId: $e');
    }
    return null;
  }

  Future<String?> _fetchMALUsername(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.myanimelist.net/v2/users/$userId'),
        headers: {'X-MAL-CLIENT-ID': dotenv.env['MAL_CLIENT_ID'] ?? ''},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['name'];
      }
    } catch (e) {
      Logger.i('Error fetching MAL username for $userId: $e');
    }
    return null;
  }

  Future<UnderratedMedia?> _processEntry(
    UnderratedEntry entry,
    bool isManga,
    ServicesType serviceType,
  ) async {
    Media? media;
    String? fetchedAuthor;

    final malId = entry.malId;
    final anilistId = entry.anilistId;
    final malUserId = entry.malUserId;
    final anilistUserId = entry.anilistUserId;

    if (serviceType == ServicesType.mal && malId != null) {
      media = await _fetchMediaFromMAL(malId, isManga);
      if (malUserId != null) {
        fetchedAuthor = await _fetchMALUsername(malUserId);
      }
    } else if (anilistId != null) {
      media = await _fetchMediaFromAnilist(anilistId, isManga);
      if (anilistUserId != null) {
        fetchedAuthor = await _fetchAnilistUsername(anilistUserId);
      }
    }

    if (media != null) {
      return UnderratedMedia(
        media: media,
        anilistUserId: entry.anilistUserId,
        malUserId: entry.malUserId,
        author: fetchedAuthor ?? entry.author,
        reason: entry.reason,
        fallbackTitle: entry.title,
      );
    }
    return null;
  }

  Future<void> fetchUnderratedAnime() async {
    if (underratedAnimes.isNotEmpty) return;

    isLoadingAnime.value = true;
    animeError.value = '';

    try {
      final response = await http.get(Uri.parse(_animeJsonUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final entries = data.map((e) => UnderratedEntry.fromJson(e)).toList();

        final serviceType = Get.find<ServiceHandler>().serviceType.value;

        final results = await Future.wait(
          entries.map((entry) => _processEntry(entry, false, serviceType)),
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

  Future<void> fetchUnderratedManga() async {
    if (underratedMangas.isNotEmpty) return;

    isLoadingManga.value = true;
    mangaError.value = '';

    try {
      final response = await http.get(Uri.parse(_mangaJsonUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final entries = data.map((e) => UnderratedEntry.fromJson(e)).toList();

        final serviceType = Get.find<ServiceHandler>().serviceType.value;

        final results = await Future.wait(
          entries.map((entry) => _processEntry(entry, true, serviceType)),
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

  Future<void> fetchAll() async {
    await Future.wait([
      fetchUnderratedAnime(),
      fetchUnderratedManga(),
    ]);
  }

  Future<void> refresh() async {
    underratedAnimes.clear();
    underratedMangas.clear();
    await fetchAll();
  }
}

class UnderratedMedia {
  final Media media;
  final int? anilistUserId;
  final int? malUserId;
  final String? author;
  final String? reason;
  final String? fallbackTitle;

  UnderratedMedia({
    required this.media,
    this.anilistUserId,
    this.malUserId,
    this.author,
    this.reason,
    this.fallbackTitle,
  });

  String get displayTitle => media.title.isNotEmpty ? media.title : (fallbackTitle ?? 'Unknown');

  String get displayDescription => reason ?? media.description;

  CarouselData toCarouselData({bool isManga = false}) {
    return CarouselData(
      id: media.id.toString(),
      title: displayTitle,
      poster: media.poster,
      extraData: media.rating.toString(),
      servicesType: ServicesType.anilist,
      releasing: media.status == "RELEASING",
      anilistUserId: anilistUserId,
      malUserId: malUserId,
      author: author,
      reason: reason,
    );
  }
}
