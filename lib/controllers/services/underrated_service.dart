import 'dart:convert';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/models_convertor/carousel/carousel_data.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class SimklUnderratedEntry {
  final int? simklId;
  final String? title;
  final String? poster;
  final String? score;
  final String? reason;
  final String? simklUsername;
  final String? simklAvatar;

  final bool isNsfw;

  SimklUnderratedEntry({
    this.simklId,
    this.title,
    this.poster,
    this.score,
    this.reason,
    this.simklUsername,
    this.simklAvatar,
    this.isNsfw = false,
  });

  factory SimklUnderratedEntry.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final simklUser = user?['simkl'] as Map<String, dynamic>?;

    return SimklUnderratedEntry(
      simklId: json['simkl_id'] as int?,
      title: json['title']?.toString(),
      poster: json['poster']?.toString(),
      score: json['score']?.toString(),
      reason: json['reason']?.toString(),
      simklUsername: simklUser?['username']?.toString(),
      simklAvatar: simklUser?['avatar']?.toString(),
      isNsfw: json['nsfw'] == true,
    );
  }
}

class UnderratedEntry {
  final int? anilistId;
  final int? malId;
  final String? title;
  final String? poster;
  final String? score;
  final int? anilistUserId;
  final int? malUserId;
  final String? anilistUsername;
  final String? malUsername;
  final String? anilistAvatar;
  final String? malAvatar;
  final String? reason;
  final bool isNsfw;

  UnderratedEntry({
    this.anilistId,
    this.malId,
    this.title,
    this.poster,
    this.score,
    this.anilistUserId,
    this.malUserId,
    this.anilistUsername,
    this.malUsername,
    this.anilistAvatar,
    this.malAvatar,
    this.reason,
    this.isNsfw = false,
  });

  factory UnderratedEntry.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final anilistUser = user?['anilist'] as Map<String, dynamic>?;
    final malUser = user?['mal'] as Map<String, dynamic>?;

    return UnderratedEntry(
      anilistId: json['anilist_id'] ?? json['id'],
      malId: json['mal_id'],
      title: json['title']?.toString(),
      poster: json['poster']?.toString(),
      score: _normalizeScore(json['score'] ?? json['averageScore']),
      anilistUserId: anilistUser?['id'] as int?,
      malUserId: malUser?['id'] as int?,
      anilistUsername: anilistUser?['username']?.toString(),
      malUsername: malUser?['username']?.toString(),
      anilistAvatar: anilistUser?['avatar']?.toString(),
      malAvatar: malUser?['avatar']?.toString(),
      reason: json['reason']?.toString(),
      isNsfw: json['nsfw'] == true,
    );
  }

  static String? _normalizeScore(dynamic rawScore) {
    final numericScore = switch (rawScore) {
      num value => value.toDouble(),
      String value => double.tryParse(value),
      _ => null,
    };

    if (numericScore == null) return null;

    final normalized = numericScore > 10 ? numericScore / 10 : numericScore;
    return normalized.toStringAsFixed(1);
  }
}

class UnderratedService extends GetxController {
  static const String _animeJsonUrl =
      'https://raw.githubusercontent.com/Shebyyy/AnymeX-Preview/beta/underrated_anime.json';
  static const String _mangaJsonUrl =
      'https://raw.githubusercontent.com/Shebyyy/AnymeX-Preview/beta/underrated_manga.json';
  static const String _showsJsonUrl =
      'https://raw.githubusercontent.com/Shebyyy/AnymeX-Preview/beta/underrated_shows.json';
  static const String _moviesJsonUrl =
      'https://raw.githubusercontent.com/Shebyyy/AnymeX-Preview/beta/underrated_movies.json';

  RxList<UnderratedMedia> underratedAnimes = <UnderratedMedia>[].obs;
  RxList<UnderratedMedia> underratedMangas = <UnderratedMedia>[].obs;
  RxList<UnderratedMedia> underratedShows = <UnderratedMedia>[].obs;
  RxList<UnderratedMedia> underratedMovies = <UnderratedMedia>[].obs;

  RxBool isLoadingAnime = false.obs;
  RxBool isLoadingManga = false.obs;
  RxBool isLoadingShows = false.obs;
  RxBool isLoadingMovies = false.obs;

  RxString animeError = ''.obs;
  RxString mangaError = ''.obs;
  RxString showsError = ''.obs;
  RxString moviesError = ''.obs;

  static const Set<String> _filteredStatuses = {
    'COMPLETED',
    'CURRENT',
    'DROPPED'
  };

  ServicesType? _cachedServiceType;

  UnderratedMedia? _processSimklEntry(
    SimklUnderratedEntry entry,
    bool isMovie,
  ) {
    if (entry.simklId == null || entry.simklId == 0) return null;

    final idSuffix = isMovie ? 'MOVIE' : 'SERIES';
    final media = Media(
      id: '${entry.simklId}*$idSuffix',
      title: entry.title ?? 'Unknown Title',
      romajiTitle: entry.title ?? 'Unknown Title',
      poster: entry.poster ?? '',
      largePoster: entry.poster ?? '',
      rating: entry.score ?? '?',
      mediaType: isMovie ? ItemType.anime : ItemType.manga,
      type: isMovie ? 'MOVIE' : 'SERIES',
      serviceType: ServicesType.simkl,
    );

    return UnderratedMedia(
      media: media,
      simklUsername: entry.simklUsername,
      simklAvatar: entry.simklAvatar,
      reason: entry.reason,
      fallbackTitle: entry.title,
      isNsfw: entry.isNsfw,
    );
  }

  RxBool communityEnabled =
      RxBool(General.showCommunityRecommendations.get<bool>(true));
  RxBool hideNsfw =
      RxBool(General.hideNsfwRecommendations.get<bool>(true));

  bool get _communityEnabled => communityEnabled.value;
  bool get _hideNsfw => hideNsfw.value;

  List<UnderratedMedia> getFilteredShows() {
    if (!_communityEnabled || underratedShows.isEmpty) return [];
    try {
      final serviceHandler = Get.find<ServiceHandler>();
      final simkl = serviceHandler.onlineService;
      final userList = simkl.mangaList;

      final filteredIds = userList
          .where((item) =>
              _filteredStatuses.contains(item.watchingStatus?.toUpperCase()))
          .map((item) => item.id)
          .toSet();

      return underratedShows
          .where((item) => !filteredIds.contains(item.media.id))
          .where((item) => !_hideNsfw || !(item.isNsfw))
          .toList()
          .reversed
          .toList();
    } catch (e) {
      return underratedShows
          .where((item) => !_hideNsfw || !(item.isNsfw))
          .toList()
          .reversed
          .toList();
    }
  }

  List<UnderratedMedia> getFilteredMovies() {
    if (!_communityEnabled || underratedMovies.isEmpty) return [];
    try {
      final serviceHandler = Get.find<ServiceHandler>();
      final simkl = serviceHandler.onlineService;
      final userList = simkl.animeList;

      final filteredIds = userList
          .where((item) =>
              _filteredStatuses.contains(item.watchingStatus?.toUpperCase()))
          .map((item) => item.id)
          .toSet();

      return underratedMovies
          .where((item) => !filteredIds.contains(item.media.id))
          .where((item) => !_hideNsfw || !(item.isNsfw))
          .toList()
          .reversed
          .toList();
    } catch (e) {
      return underratedMovies
          .where((item) => !_hideNsfw || !(item.isNsfw))
          .toList()
          .reversed
          .toList();
    }
  }

  List<UnderratedMedia> getFilteredAnimes() {
    if (!_communityEnabled || underratedAnimes.isEmpty) return [];
    try {
      final serviceHandler = Get.find<ServiceHandler>();
      final onlineService = serviceHandler.onlineService;
      final userList = onlineService.animeList;

      final filteredIds = userList
          .where((item) =>
              _filteredStatuses.contains(item.watchingStatus?.toUpperCase()))
          .map((item) => item.id)
          .toSet();

      return underratedAnimes
          .where((item) => !filteredIds.contains(item.media.id))
          .where((item) => !_hideNsfw || !(item.isNsfw))
          .toList()
          .reversed
          .toList();
    } catch (e) {
      return underratedAnimes
          .where((item) => !_hideNsfw || !(item.isNsfw))
          .toList()
          .reversed
          .toList();
    }
  }

  List<UnderratedMedia> getFilteredMangas() {
    if (!_communityEnabled || underratedMangas.isEmpty) return [];
    try {
      final serviceHandler = Get.find<ServiceHandler>();
      final onlineService = serviceHandler.onlineService;
      final userList = onlineService.mangaList;

      final filteredIds = userList
          .where((item) =>
              _filteredStatuses.contains(item.watchingStatus?.toUpperCase()))
          .map((item) => item.id)
          .toSet();

      return underratedMangas
          .where((item) => !filteredIds.contains(item.media.id))
          .where((item) => !_hideNsfw || !(item.isNsfw))
          .toList()
          .reversed
          .toList();
    } catch (e) {
      return underratedMangas
          .where((item) => !_hideNsfw || !(item.isNsfw))
          .toList()
          .reversed
          .toList();
    }
  }

  UnderratedMedia? _processEntry(
    UnderratedEntry entry,
    bool isManga,
    ServicesType serviceType,
  ) {
    final primaryId =
        serviceType == ServicesType.mal ? entry.malId : entry.anilistId;
    if (primaryId == null || primaryId == 0) {
      return null;
    }

    final media = Media(
      id: primaryId.toString(),
      idMal: (entry.malId ?? 0).toString(),
      title: entry.title ?? 'Unknown Title',
      romajiTitle: entry.title ?? 'Unknown Title',
      poster: entry.poster ?? '',
      largePoster: entry.poster ?? '',
      rating: entry.score ?? '?',
      mediaType: isManga ? ItemType.manga : ItemType.anime,
      type: isManga ? 'MANGA' : 'ANIME',
      serviceType: serviceType,
    );

    return UnderratedMedia(
      media: media,
      anilistUserId: entry.anilistUserId,
      malUserId: entry.malUserId,
      anilistUsername: entry.anilistUsername,
      malUsername: entry.malUsername,
      anilistAvatar: entry.anilistAvatar,
      malAvatar: entry.malAvatar,
      reason: entry.reason,
      fallbackTitle: entry.title,
      isNsfw: entry.isNsfw,
    );
  }

  Future<void> fetchUnderratedAnime() async {
    final serviceType = Get.find<ServiceHandler>().serviceType.value;

    if (underratedAnimes.isNotEmpty && _cachedServiceType == serviceType)
      return;

    if (_cachedServiceType != serviceType) {
      underratedAnimes.clear();
      underratedMangas.clear();
    }

    isLoadingAnime.value = true;
    animeError.value = '';

    try {
      final response = await http.get(Uri.parse(_animeJsonUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final entries = data.map((e) => UnderratedEntry.fromJson(e)).toList();

        underratedAnimes.value = entries
            .map((entry) => _processEntry(entry, false, serviceType))
            .whereType<UnderratedMedia>()
            .toList();
        _cachedServiceType = serviceType;
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
    final serviceType = Get.find<ServiceHandler>().serviceType.value;

    if (underratedMangas.isNotEmpty && _cachedServiceType == serviceType)
      return;

    isLoadingManga.value = true;
    mangaError.value = '';

    try {
      final response = await http.get(Uri.parse(_mangaJsonUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final entries = data.map((e) => UnderratedEntry.fromJson(e)).toList();

        underratedMangas.value = entries
            .map((entry) => _processEntry(entry, true, serviceType))
            .whereType<UnderratedMedia>()
            .toList();
        _cachedServiceType = serviceType;
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

  Future<void> fetchUnderratedShows() async {
    if (underratedShows.isNotEmpty) return;

    isLoadingShows.value = true;
    showsError.value = '';

    try {
      final response = await http.get(Uri.parse(_showsJsonUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final entries =
            data.map((e) => SimklUnderratedEntry.fromJson(e)).toList();

        underratedShows.value = entries
            .map((entry) => _processSimklEntry(entry, false))
            .whereType<UnderratedMedia>()
            .toList();
        Logger.i('Fetched ${underratedShows.length} underrated shows');
      } else {
        showsError.value = 'Failed to load: ${response.statusCode}';
        Logger.i('Failed to fetch underrated shows: ${response.statusCode}');
      }
    } catch (e) {
      showsError.value = 'Error: $e';
      Logger.i('Error fetching underrated shows: $e');
    } finally {
      isLoadingShows.value = false;
    }
  }

  Future<void> fetchUnderratedMovies() async {
    if (underratedMovies.isNotEmpty) return;

    isLoadingMovies.value = true;
    moviesError.value = '';

    try {
      final response = await http.get(Uri.parse(_moviesJsonUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final entries =
            data.map((e) => SimklUnderratedEntry.fromJson(e)).toList();

        underratedMovies.value = entries
            .map((entry) => _processSimklEntry(entry, true))
            .whereType<UnderratedMedia>()
            .toList();
        Logger.i('Fetched ${underratedMovies.length} underrated movies');
      } else {
        moviesError.value = 'Failed to load: ${response.statusCode}';
        Logger.i('Failed to fetch underrated movies: ${response.statusCode}');
      }
    } catch (e) {
      moviesError.value = 'Error: $e';
      Logger.i('Error fetching underrated movies: $e');
    } finally {
      isLoadingMovies.value = false;
    }
  }

  Future<void> fetchAll() async {
    try {
      await Future.wait([
        fetchUnderratedAnime(),
        fetchUnderratedManga(),
        fetchUnderratedShows(),
        fetchUnderratedMovies(),
      ]);
    } catch (e) {
      Logger.i('Error in underrated fetchAll: $e');
    }
  }

  Future<void> refresh() async {
    underratedAnimes.clear();
    underratedMangas.clear();
    underratedShows.clear();
    underratedMovies.clear();
    await fetchAll();
  }

  static String? get _botBaseUrl => dotenv.env['BOT_BASE_URL'];
  static String? get _botSecret => dotenv.env['BOT_API_SECRET'];

  static bool get votingEnabled =>
      _botBaseUrl != null &&
      _botBaseUrl!.isNotEmpty &&
      _botSecret != null &&
      _botSecret!.isNotEmpty;

  static Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_botSecret',
      };

  static Future<VoteResult?> fetchVotes(
      String mediaType, String mediaId) async {
    if (!votingEnabled) return null;
    try {
      final url =
          Uri.parse('$_botBaseUrl/api/votes/$mediaType/$mediaId');
      final resp = await http.get(url, headers: _authHeaders);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return VoteResult.fromJson(data);
      }
    } catch (e) {
      Logger.i('fetchVotes error: $e');
    }
    return null;
  }

  static Future<VoteResult?> castVote({
    required String mediaType,
    required String mediaId,
    required String direction,
    int? anilistUserId,
    int? malUserId,
    int? simklUserId,
    String displayName = 'User',
  }) async {
    if (!votingEnabled) return null;
    try {
      final url =
          Uri.parse('$_botBaseUrl/api/vote/$mediaType/$mediaId');
      final body = <String, dynamic>{
        'direction': direction,
        'display_name': displayName,
      };
      if (anilistUserId != null) {
        body['anilist_user_id'] = anilistUserId;
        body['id_type'] = 'anilist';
      } else if (malUserId != null) {
        body['mal_user_id'] = malUserId;
        body['id_type'] = 'mal';
      } else if (simklUserId != null) {
        body['simkl_user_id'] = simklUserId;
        body['id_type'] = 'simkl';
      } else {
        return null;
      }
      final resp = await http.post(url,
          headers: _authHeaders, body: jsonEncode(body));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return VoteResult(
          upvotes: data['upvotes'] ?? 0,
          downvotes: data['downvotes'] ?? 0,
          net: data['net'] ?? 0,
        );
      }
      Logger.i('castVote ${resp.statusCode}: ${resp.body}');
    } catch (e) {
      Logger.i('castVote error: $e');
    }
    return null;
  }
}

class UnderratedMedia {
  final Media media;
  final int? anilistUserId;
  final int? malUserId;
  final String? anilistUsername;
  final String? malUsername;
  final String? anilistAvatar;
  final String? malAvatar;
  final String? simklUsername;
  final String? simklAvatar;
  final String? reason;
  final String? fallbackTitle;
  final bool isNsfw;

  UnderratedMedia({
    required this.media,
    this.anilistUserId,
    this.malUserId,
    this.anilistUsername,
    this.malUsername,
    this.anilistAvatar,
    this.malAvatar,
    this.simklUsername,
    this.simklAvatar,
    this.reason,
    this.fallbackTitle,
    this.isNsfw = false,
  });

  String get displayTitle =>
      media.title.isNotEmpty ? media.title : (fallbackTitle ?? 'Unknown');

  String get displayDescription => reason ?? media.description;

  String? get author => usernameFor(media.serviceType);

  String? usernameFor(ServicesType serviceType) {
    if (serviceType == ServicesType.simkl) {
      return simklUsername ?? anilistUsername ?? malUsername;
    }
    if (serviceType == ServicesType.mal) {
      return malUsername ?? anilistUsername;
    }
    return anilistUsername ?? malUsername;
  }

  String? avatarFor(ServicesType serviceType) {
    if (serviceType == ServicesType.simkl) {
      return simklAvatar ?? anilistAvatar ?? malAvatar;
    }
    if (serviceType == ServicesType.mal) {
      return malAvatar ?? anilistAvatar;
    }
    return anilistAvatar ?? malAvatar;
  }

  CarouselData toCarouselData({bool isManga = false}) {
    return CarouselData(
      id: media.id.toString(),
      title: displayTitle,
      poster: media.poster,
      extraData: media.rating.toString(),
      servicesType: media.serviceType,
      releasing: media.status == "RELEASING",
      author: usernameFor(media.serviceType),
      reason: reason,
    );
  }
}

class VoteResult {
  final int upvotes;
  final int downvotes;
  final int net;
  final String? userVote;

  VoteResult({
    required this.upvotes,
    required this.downvotes,
    required this.net,
    this.userVote,
  });

  factory VoteResult.fromJson(Map<String, dynamic> json) {
    return VoteResult(
      upvotes: json['total_upvotes'] ?? 0,
      downvotes: json['total_downvotes'] ?? 0,
      net: json['net'] ?? 0,
    );
  }
}
