import 'dart:convert';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/models_convertor/carousel/carousel_data.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

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

  RxList<UnderratedMedia> underratedAnimes = <UnderratedMedia>[].obs;
  RxList<UnderratedMedia> underratedMangas = <UnderratedMedia>[].obs;

  RxBool isLoadingAnime = false.obs;
  RxBool isLoadingManga = false.obs;

  RxString animeError = ''.obs;
  RxString mangaError = ''.obs;

  static const Set<String> _filteredStatuses = {
    'COMPLETED',
    'CURRENT',
    'DROPPED'
  };

  ServicesType? _cachedServiceType;

  List<UnderratedMedia> getFilteredAnimes() {
    if (underratedAnimes.isEmpty) return [];
    try {
      final serviceHandler = Get.find<ServiceHandler>();
      final onlineService = serviceHandler.onlineService;
      final userList = onlineService.animeList;

      if (userList.isEmpty) return underratedAnimes.reversed.toList();

      final filteredIds = userList
          .where((item) =>
              _filteredStatuses.contains(item.watchingStatus?.toUpperCase()))
          .map((item) => item.id)
          .toSet();

      return underratedAnimes
          .where((item) => !filteredIds.contains(item.media.id))
          .toList()
          .reversed
          .toList();
    } catch (e) {
      return underratedAnimes.reversed.toList();
    }
  }

  List<UnderratedMedia> getFilteredMangas() {
    if (underratedMangas.isEmpty) return [];
    try {
      final serviceHandler = Get.find<ServiceHandler>();
      final onlineService = serviceHandler.onlineService;
      final userList = onlineService.mangaList;

      if (userList.isEmpty) return underratedMangas.reversed.toList();

      final filteredIds = userList
          .where((item) =>
              _filteredStatuses.contains(item.watchingStatus?.toUpperCase()))
          .map((item) => item.id)
          .toSet();

      return underratedMangas
          .where((item) => !filteredIds.contains(item.media.id))
          .toList()
          .reversed
          .toList();
    } catch (e) {
      return underratedMangas.reversed.toList();
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

  Future<void> fetchAll() async {
    try {
      await Future.wait([
        fetchUnderratedAnime(),
        fetchUnderratedManga(),
      ]);
    } catch (e) {
      Logger.i('Error in underrated fetchAll: $e');
    }
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
  final String? anilistUsername;
  final String? malUsername;
  final String? anilistAvatar;
  final String? malAvatar;
  final String? reason;
  final String? fallbackTitle;

  UnderratedMedia({
    required this.media,
    this.anilistUserId,
    this.malUserId,
    this.anilistUsername,
    this.malUsername,
    this.anilistAvatar,
    this.malAvatar,
    this.reason,
    this.fallbackTitle,
  });

  String get displayTitle =>
      media.title.isNotEmpty ? media.title : (fallbackTitle ?? 'Unknown');

  String get displayDescription => reason ?? media.description;

  String? get author => usernameFor(media.serviceType);

  String? usernameFor(ServicesType serviceType) {
    if (serviceType == ServicesType.mal) {
      return malUsername ?? anilistUsername;
    }
    return anilistUsername ?? malUsername;
  }

  String? avatarFor(ServicesType serviceType) {
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
