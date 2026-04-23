import 'dart:convert';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/models/Anilist/anilist_profile.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/models_convertor/carousel/carousel_data.dart';
import 'package:anymex/screens/profile/user_profile_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher_string.dart';

void navigateToAuthorProfile(CommunityMedia item) {
  final serviceType = Get.find<ServiceHandler>().serviceType.value;
  if (serviceType == ServicesType.simkl) {
    if (item.simklUserId != null) {
      launchUrlString('https://simkl.com/${item.simklUserId}');
    }
  } else if (serviceType == ServicesType.anilist &&
      item.anilistUserId != null) {
    navigate(() => UserProfilePage(userId: item.anilistUserId!));
  } else if (item.malUsername != null && item.malUsername!.isNotEmpty) {
    launchUrlString('https://myanimelist.net/profile/${item.malUsername}');
  }
}

void navigateToReasonAuthorProfile(
    ReasonEntry reason, ServicesType serviceType) {
  if (reason.user == null) return;
  final user = reason.user!;
  if (serviceType == ServicesType.simkl && user.simklId != null) {
    launchUrlString('https://simkl.com/${user.simklId}');
  } else if (serviceType == ServicesType.anilist && user.anilistId != null) {
    navigate(() => UserProfilePage(userId: user.anilistId!));
  } else if (serviceType == ServicesType.mal && user.malId != null) {
    launchUrlString(
        'https://myanimelist.net/profile/${user.malUsername ?? ''}');
  } else {
    // Fallback: try any available service
    if (user.anilistId != null) {
      navigate(() => UserProfilePage(userId: user.anilistId!));
    } else if (user.simklId != null) {
      launchUrlString('https://simkl.com/${user.simklId}');
    } else if (user.malUsername != null && user.malUsername!.isNotEmpty) {
      launchUrlString('https://myanimelist.net/profile/${user.malUsername}');
    }
  }
}

class ReasonUserProfile {
  final int? anilistId;
  final String? anilistUsername;
  final String? anilistAvatar;
  final int? malId;
  final String? malUsername;
  final String? malAvatar;
  final int? simklId;
  final String? simklUsername;
  final String? simklAvatar;
  final bool isAdmin;

  ReasonUserProfile({
    this.anilistId,
    this.anilistUsername,
    this.anilistAvatar,
    this.malId,
    this.malUsername,
    this.malAvatar,
    this.simklId,
    this.simklUsername,
    this.simklAvatar,
    this.isAdmin = false,
  });

  factory ReasonUserProfile.fromJson(Map<String, dynamic> json) {
    final anilist = json['anilist'] as Map<String, dynamic>?;
    final mal = json['mal'] as Map<String, dynamic>?;
    final simkl = json['simkl'] as Map<String, dynamic>?;

    return ReasonUserProfile(
      anilistId: anilist?['id'] as int?,
      anilistUsername: anilist?['username']?.toString(),
      anilistAvatar: anilist?['avatar']?.toString(),
      malId: mal?['id'] as int?,
      malUsername: mal?['username']?.toString(),
      malAvatar: mal?['avatar']?.toString(),
      simklId: simkl?['id'] as int?,
      simklUsername: simkl?['username']?.toString(),
      simklAvatar: simkl?['avatar']?.toString(),
      isAdmin: json['isAdmin'] == true,
    );
  }

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

  int? userIdFor(ServicesType serviceType) {
    if (serviceType == ServicesType.anilist) return anilistId;
    if (serviceType == ServicesType.mal) return malId;
    if (serviceType == ServicesType.simkl) return simklId;
    return anilistId;
  }

  bool matchesUser(ReasonUserProfile? other) {
    if (other == null) return false;
    if (anilistId != null && anilistId! > 0 && anilistId == other.anilistId) return true;
    if (malId != null && malId! > 0 && malId == other.malId) return true;
    if (simklId != null && simklId! > 0 && simklId == other.simklId) return true;
    if (anilistUsername != null &&
        anilistUsername!.isNotEmpty &&
        anilistUsername == other.anilistUsername) return true;
    if (malUsername != null &&
        malUsername!.isNotEmpty &&
        malUsername == other.malUsername) return true;
    if (simklUsername != null &&
        simklUsername!.isNotEmpty &&
        simklUsername == other.simklUsername) return true;
    return false;
  }

  String? get displayName =>
      anilistUsername ?? malUsername ?? simklUsername;

  String? get displayAvatar =>
      anilistAvatar ?? malAvatar ?? simklAvatar;
}

class ReasonEntry {
  final String? author;
  final String text;
  final String? addedAt;
  final String? editedAt;
  final ReasonUserProfile? user;

  ReasonEntry({
    this.author,
    required this.text,
    this.addedAt,
    this.editedAt,
    this.user,
  });

  factory ReasonEntry.fromJson(Map<String, dynamic> json) {
    final userMap = json['user'] as Map<String, dynamic>?;
    return ReasonEntry(
      author: json['author']?.toString(),
      text: json['text']?.toString() ?? json['reason']?.toString() ?? '',
      addedAt: json['added_at']?.toString(),
      editedAt: json['edited_at']?.toString(),
      user: userMap != null ? ReasonUserProfile.fromJson(userMap) : null,
    );
  }

  String? usernameFor(ServicesType serviceType) {
    return user?.usernameFor(serviceType) ?? author;
  }

  String? avatarFor(ServicesType serviceType) {
    return user?.avatarFor(serviceType);
  }

  int? userIdFor(ServicesType serviceType) {
    return user?.userIdFor(serviceType);
  }

  String get displayText {
    if (text.length > 150) return '${text.substring(0, 147)}...';
    return text;
  }
}

class SimklCommunityEntry {
  final int? simklId;
  final String? title;
  final String? poster;
  final String? score;
  final String? reason;
  final int? simklUserId;
  final String? simklUsername;
  final String? simklAvatar;
  final bool isNsfw;
  final List<ReasonEntry> reasons;
  final Map<String, dynamic> rawJson;

  SimklCommunityEntry({
    this.simklId,
    this.title,
    this.poster,
    this.score,
    this.reason,
    this.simklUserId,
    this.simklUsername,
    this.simklAvatar,
    this.isNsfw = false,
    this.reasons = const [],
    required this.rawJson,
  });

  factory SimklCommunityEntry.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final simklUser = user?['simkl'] as Map<String, dynamic>?;
    var reasonsList = json['reasons'] as List<dynamic>?;

    // Migrate old format (no reasons[]) into new format in-memory
    if (reasonsList == null || reasonsList.isEmpty) {
      final text = json['reason']?.toString() ?? '';
      if (text.isNotEmpty || user != null) {
        reasonsList = [
          {
            'user': user ?? {},
            'author': json['author']?.toString(),
            'text': text,
            'added_at': null
          },
        ];
      }
    }

    final reasons = reasonsList
            ?.map((e) => ReasonEntry.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return SimklCommunityEntry(
      simklId: json['simkl_id'] as int?,
      title: json['title']?.toString(),
      poster: json['poster']?.toString(),
      score: json['score']?.toString(),
      reason: json['reason']?.toString(),
      simklUserId: simklUser?['id'] as int?,
      simklUsername: simklUser?['username']?.toString(),
      simklAvatar: simklUser?['avatar']?.toString(),
      isNsfw: json['nsfw'] == true,
      reasons: reasons,
      rawJson: json,
    );
  }
}

class CommunityEntry {
  final int? anilistId;
  final int? malId;
  final String? title;
  final String? poster;
  final String? score;
  final int? anilistUserId;
  final int? malUserId;
  final int? simklUserId;
  final String? anilistUsername;
  final String? malUsername;
  final String? simklUsername;
  final String? anilistAvatar;
  final String? malAvatar;
  final String? simklAvatar;
  final String? reason;
  final bool isNsfw;
  final List<ReasonEntry> reasons;
  final Map<String, dynamic> rawJson;

  CommunityEntry({
    this.anilistId,
    this.malId,
    this.title,
    this.poster,
    this.score,
    this.anilistUserId,
    this.malUserId,
    this.simklUserId,
    this.anilistUsername,
    this.malUsername,
    this.simklUsername,
    this.anilistAvatar,
    this.malAvatar,
    this.simklAvatar,
    this.reason,
    this.isNsfw = false,
    this.reasons = const [],
    required this.rawJson,
  });

  factory CommunityEntry.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final anilistUser = user?['anilist'] as Map<String, dynamic>?;
    final malUser = user?['mal'] as Map<String, dynamic>?;
    final simklUser = user?['simkl'] as Map<String, dynamic>?;
    var reasonsList = json['reasons'] as List<dynamic>?;

    // Migrate old format (no reasons[]) into new format in-memory
    if (reasonsList == null || reasonsList.isEmpty) {
      final text = json['reason']?.toString() ?? '';
      if (text.isNotEmpty || user != null) {
        reasonsList = [
          {
            'user': user ?? {},
            'author': json['author']?.toString(),
            'text': text,
            'added_at': null
          },
        ];
      }
    }

    final reasons = reasonsList
            ?.map((e) => ReasonEntry.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return CommunityEntry(
      anilistId: json['anilist_id'] ?? json['id'],
      malId: json['mal_id'],
      title: json['title']?.toString(),
      poster: json['poster']?.toString(),
      score: _normalizeScore(json['score'] ?? json['averageScore']),
      anilistUserId: anilistUser?['id'] as int?,
      malUserId: malUser?['id'] as int?,
      simklUserId: simklUser?['id'] as int?,
      anilistUsername: anilistUser?['username']?.toString(),
      malUsername: malUser?['username']?.toString(),
      simklUsername: simklUser?['username']?.toString(),
      anilistAvatar: anilistUser?['avatar']?.toString(),
      malAvatar: malUser?['avatar']?.toString(),
      simklAvatar: simklUser?['avatar']?.toString(),
      reason: json['reason']?.toString(),
      isNsfw: json['nsfw'] == true,
      reasons: reasons,
      rawJson: json,
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

class CommunityService extends GetxController {
  static const String _animeJsonUrl =
      'https://raw.githubusercontent.com/Shebyyy/AnymeX-Preview/beta/community_anime.json';
  static const String _mangaJsonUrl =
      'https://raw.githubusercontent.com/Shebyyy/AnymeX-Preview/beta/community_manga.json';
  static const String _showsJsonUrl =
      'https://raw.githubusercontent.com/Shebyyy/AnymeX-Preview/beta/community_shows.json';
  static const String _moviesJsonUrl =
      'https://raw.githubusercontent.com/Shebyyy/AnymeX-Preview/beta/community_movies.json';

  RxList<CommunityMedia> communityAnimes = <CommunityMedia>[].obs;
  RxList<CommunityMedia> communityMangas = <CommunityMedia>[].obs;
  RxList<CommunityMedia> communityShows = <CommunityMedia>[].obs;
  RxList<CommunityMedia> communityMovies = <CommunityMedia>[].obs;

  RxBool isLoadingAnime = false.obs;
  RxBool isLoadingManga = false.obs;
  RxBool isLoadingShows = false.obs;
  RxBool isLoadingMovies = false.obs;

  RxString animeError = ''.obs;
  RxString mangaError = ''.obs;
  RxString showsError = ''.obs;
  RxString moviesError = ''.obs;

  ServicesType? _cachedServiceType;

  RxBool filterByListEnabled =
      RxBool(General.filterByListEnabled.get<bool>(true));
  RxBool filterCompleted = RxBool(General.filterCompleted.get<bool>(true));
  RxBool filterWatching = RxBool(General.filterWatching.get<bool>(true));
  RxBool filterDropped = RxBool(General.filterDropped.get<bool>(true));
  RxBool filterPlanning = RxBool(General.filterPlanning.get<bool>(false));
  RxBool filterPaused = RxBool(General.filterPaused.get<bool>(false));
  RxBool filterRepeating = RxBool(General.filterRepeating.get<bool>(false));

  Set<String> get _activeFilteredStatuses {
    if (!filterByListEnabled.value) return {};
    return {
      if (filterCompleted.value) 'COMPLETED',
      if (filterWatching.value) 'CURRENT',
      if (filterDropped.value) 'DROPPED',
      if (filterPlanning.value) 'PLANNING',
      if (filterPaused.value) 'PAUSED',
      if (filterRepeating.value) 'REPEATING',
    };
  }

  CommunityMedia? _processSimklCommunityEntry(
    SimklCommunityEntry entry,
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

    return CommunityMedia(
      media: media,
      simklUserId: entry.simklUserId,
      simklUsername: entry.simklUsername,
      simklAvatar: entry.simklAvatar,
      reason: entry.reason,
      fallbackTitle: entry.title,
      isNsfw: entry.isNsfw,
      reasons: entry.reasons,
      rawJson: entry.rawJson,
    );
  }

  RxBool communityEnabled =
      RxBool(General.showCommunityRecommendations.get<bool>(true));
  RxBool hideNsfw = RxBool(General.hideNsfwRecommendations.get<bool>(true));

  bool get _communityEnabled => communityEnabled.value;
  bool get _hideNsfw => hideNsfw.value;

  List<CommunityMedia> getFilteredCommunityShows() {
    if (!_communityEnabled || communityShows.isEmpty) return [];
    try {
      final serviceHandler = Get.find<ServiceHandler>();
      final simkl = serviceHandler.onlineService;
      final userList = simkl.mangaList;

      final filteredIds = userList
          .where((item) => _activeFilteredStatuses
              .contains(item.watchingStatus?.toUpperCase()))
          .map((item) => item.id)
          .toSet();

      return communityShows
          .where((item) => !filteredIds.contains(item.media.id))
          .where((item) => !_hideNsfw || !(item.isNsfw))
          .toList()
          .reversed
          .toList();
    } catch (e) {
      return communityShows
          .where((item) => !_hideNsfw || !(item.isNsfw))
          .toList()
          .reversed
          .toList();
    }
  }

  List<CommunityMedia> getFilteredCommunityMovies() {
    if (!_communityEnabled || communityMovies.isEmpty) return [];
    try {
      final serviceHandler = Get.find<ServiceHandler>();
      final simkl = serviceHandler.onlineService;
      final userList = simkl.animeList;

      final filteredIds = userList
          .where((item) => _activeFilteredStatuses
              .contains(item.watchingStatus?.toUpperCase()))
          .map((item) => item.id)
          .toSet();

      return communityMovies
          .where((item) => !filteredIds.contains(item.media.id))
          .where((item) => !_hideNsfw || !(item.isNsfw))
          .toList()
          .reversed
          .toList();
    } catch (e) {
      return communityMovies
          .where((item) => !_hideNsfw || !(item.isNsfw))
          .toList()
          .reversed
          .toList();
    }
  }

  List<CommunityMedia> getFilteredCommunityAnimes() {
    if (!_communityEnabled || communityAnimes.isEmpty) return [];
    try {
      final serviceHandler = Get.find<ServiceHandler>();
      final onlineService = serviceHandler.onlineService;
      final userList = onlineService.animeList;

      final filteredIds = userList
          .where((item) => _activeFilteredStatuses
              .contains(item.watchingStatus?.toUpperCase()))
          .map((item) => item.id)
          .toSet();

      return communityAnimes
          .where((item) => !filteredIds.contains(item.media.id))
          .where((item) => !_hideNsfw || !(item.isNsfw))
          .toList()
          .reversed
          .toList();
    } catch (e) {
      return communityAnimes
          .where((item) => !_hideNsfw || !(item.isNsfw))
          .toList()
          .reversed
          .toList();
    }
  }

  List<CommunityMedia> getFilteredCommunityMangas() {
    if (!_communityEnabled || communityMangas.isEmpty) return [];
    try {
      final serviceHandler = Get.find<ServiceHandler>();
      final onlineService = serviceHandler.onlineService;
      final userList = onlineService.mangaList;

      final filteredIds = userList
          .where((item) => _activeFilteredStatuses
              .contains(item.watchingStatus?.toUpperCase()))
          .map((item) => item.id)
          .toSet();

      return communityMangas
          .where((item) => !filteredIds.contains(item.media.id))
          .where((item) => !_hideNsfw || !(item.isNsfw))
          .toList()
          .reversed
          .toList();
    } catch (e) {
      return communityMangas
          .where((item) => !_hideNsfw || !(item.isNsfw))
          .toList()
          .reversed
          .toList();
    }
  }

  CommunityMedia? _processEntry(
    CommunityEntry entry,
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

    return CommunityMedia(
      media: media,
      anilistUserId: entry.anilistUserId,
      malUserId: entry.malUserId,
      simklUserId: entry.simklUserId,
      anilistUsername: entry.anilistUsername,
      malUsername: entry.malUsername,
      simklUsername: entry.simklUsername,
      anilistAvatar: entry.anilistAvatar,
      malAvatar: entry.malAvatar,
      simklAvatar: entry.simklAvatar,
      reason: entry.reason,
      fallbackTitle: entry.title,
      isNsfw: entry.isNsfw,
      reasons: entry.reasons,
      rawJson: entry.rawJson,
    );
  }

  Future<void> fetchCommunityAnime() async {
    final serviceType = Get.find<ServiceHandler>().serviceType.value;

    if (communityAnimes.isNotEmpty && _cachedServiceType == serviceType) return;

    if (_cachedServiceType != serviceType) {
      communityAnimes.clear();
      communityMangas.clear();
    }

    isLoadingAnime.value = true;
    animeError.value = '';

    try {
      final response = await http.get(Uri.parse(_animeJsonUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final entries = data.map((e) => CommunityEntry.fromJson(e)).toList();

        communityAnimes.value = entries
            .map((entry) => _processEntry(entry, false, serviceType))
            .whereType<CommunityMedia>()
            .toList();
        _cachedServiceType = serviceType;
        Logger.i('Fetched ${communityAnimes.length} community anime');
      } else {
        animeError.value = 'Failed to load: ${response.statusCode}';
        Logger.i('Failed to fetch community anime: ${response.statusCode}');
      }
    } catch (e) {
      animeError.value = 'Error: $e';
      Logger.i('Error fetching community anime: $e');
    } finally {
      isLoadingAnime.value = false;
    }
  }

  Future<void> fetchCommunityManga() async {
    final serviceType = Get.find<ServiceHandler>().serviceType.value;

    if (communityMangas.isNotEmpty && _cachedServiceType == serviceType) return;

    isLoadingManga.value = true;
    mangaError.value = '';

    try {
      final response = await http.get(Uri.parse(_mangaJsonUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final entries = data.map((e) => CommunityEntry.fromJson(e)).toList();

        communityMangas.value = entries
            .map((entry) => _processEntry(entry, true, serviceType))
            .whereType<CommunityMedia>()
            .toList();
        _cachedServiceType = serviceType;
        Logger.i('Fetched ${communityMangas.length} community manga');
      } else {
        mangaError.value = 'Failed to load: ${response.statusCode}';
        Logger.i('Failed to fetch community manga: ${response.statusCode}');
      }
    } catch (e) {
      mangaError.value = 'Error: $e';
      Logger.i('Error fetching community manga: $e');
    } finally {
      isLoadingManga.value = false;
    }
  }

  Future<void> fetchCommunityShows() async {
    if (communityShows.isNotEmpty) return;

    isLoadingShows.value = true;
    showsError.value = '';

    try {
      final response = await http.get(Uri.parse(_showsJsonUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final entries =
            data.map((e) => SimklCommunityEntry.fromJson(e)).toList();

        communityShows.value = entries
            .map((entry) => _processSimklCommunityEntry(entry, false))
            .whereType<CommunityMedia>()
            .toList();
        Logger.i('Fetched ${communityShows.length} community shows');
      } else {
        showsError.value = 'Failed to load: ${response.statusCode}';
        Logger.i('Failed to fetch community shows: ${response.statusCode}');
      }
    } catch (e) {
      showsError.value = 'Error: $e';
      Logger.i('Error fetching community shows: $e');
    } finally {
      isLoadingShows.value = false;
    }
  }

  Future<void> fetchCommunityMovies() async {
    if (communityMovies.isNotEmpty) return;

    isLoadingMovies.value = true;
    moviesError.value = '';

    try {
      final response = await http.get(Uri.parse(_moviesJsonUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final entries =
            data.map((e) => SimklCommunityEntry.fromJson(e)).toList();

        communityMovies.value = entries
            .map((entry) => _processSimklCommunityEntry(entry, true))
            .whereType<CommunityMedia>()
            .toList();
        Logger.i('Fetched ${communityMovies.length} community movies');
      } else {
        moviesError.value = 'Failed to load: ${response.statusCode}';
        Logger.i('Failed to fetch community movies: ${response.statusCode}');
      }
    } catch (e) {
      moviesError.value = 'Error: $e';
      Logger.i('Error fetching community movies: $e');
    } finally {
      isLoadingMovies.value = false;
    }
  }

  Future<void> fetchAll() async {
    try {
      await Future.wait([
        fetchCommunityAnime(),
        fetchCommunityManga(),
        fetchCommunityShows(),
        fetchCommunityMovies(),
      ]);
    } catch (e) {
      Logger.i('Error in community fetchAll: $e');
    }
  }

  Future<void> refresh() async {
    communityAnimes.clear();
    communityMangas.clear();
    communityShows.clear();
    communityMovies.clear();
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

  static Future<bool> checkIsAdmin({
    required ServicesType serviceType,
    required Profile profile,
  }) async {
    if (!votingEnabled) return false;
    try {
      final body =
          _buildUserIdentityBody(serviceType: serviceType, profile: profile);
      final url = Uri.parse('$_botBaseUrl/api/is_admin');
      final resp =
          await http.post(url, headers: _authHeaders, body: jsonEncode(body));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return data['is_admin'] == true;
      }
    } catch (e) {
      Logger.i('checkIsAdmin error: $e');
    }
    return false;
  }

  static Future<VoteResult?> fetchVotes(String mediaType, String mediaId,
      {int? anilistUserId, int? malUserId, int? simklUserId}) async {
    if (!votingEnabled) return null;
    try {
      final queryParams = <String, String>{};
      if (anilistUserId != null) {
        queryParams['anilist_user_id'] = anilistUserId.toString();
      } else if (malUserId != null) {
        queryParams['mal_user_id'] = malUserId.toString();
      } else if (simklUserId != null) {
        queryParams['simkl_user_id'] = simklUserId.toString();
      }
      final url = Uri.parse('$_botBaseUrl/api/votes/$mediaType/$mediaId')
          .replace(queryParameters: queryParams);
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
      final url = Uri.parse('$_botBaseUrl/api/vote/$mediaType/$mediaId');
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
      final resp =
          await http.post(url, headers: _authHeaders, body: jsonEncode(body));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final action = data['action'] as String?;
        String? resolvedUserVote;
        if (action != null) {
          if (action == 'added_up' || action == 'switched_to_up') {
            resolvedUserVote = 'up';
          } else if (action == 'added_down' || action == 'switched_to_down') {
            resolvedUserVote = 'down';
          } else if (action == 'removed_up' || action == 'removed_down') {
            resolvedUserVote = null;
          }
        }
        return VoteResult(
          upvotes: data['upvotes'] ?? 0,
          downvotes: data['downvotes'] ?? 0,
          net: data['net'] ?? 0,
          userVote: resolvedUserVote,
        );
      }
      Logger.i('castVote ${resp.statusCode}: ${resp.body}');
    } catch (e) {
      Logger.i('castVote error: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> checkIfExists({
    required String mediaType,
    required String id,
    required String idType,
  }) async {
    if (!votingEnabled) return null;
    try {
      final url = Uri.parse('$_botBaseUrl/api/check/$mediaType/$id')
          .replace(queryParameters: {'id_type': idType});
      final resp = await http.get(url, headers: _authHeaders);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        if (data['exists'] == true) {
          return data['entry'] as Map<String, dynamic>?;
        }
        return null;
      }
    } catch (e) {
      Logger.i('CommunityService.checkIfExists error: $e');
    }
    return null;
  }

  static Future<String?> submitRecommendation({
    required Media media,
    required String reason,
    required ServicesType serviceType,
    required Profile profile,
  }) async {
    if (!votingEnabled) return 'Bot URL not configured';
    try {
      final body = _buildSubmitBody(
        media: media,
        reason: reason,
        serviceType: serviceType,
        profile: profile,
      );

      String endpoint;
      if (media.type == 'MANGA') {
        endpoint = '/api/add_manga';
      } else if (media.type == 'MOVIE') {
        endpoint = '/api/add_movie';
      } else if (media.type == 'SERIES') {
        endpoint = '/api/add_show';
      } else {
        endpoint = '/api/add_anime';
      }

      final url = Uri.parse('$_botBaseUrl$endpoint');
      final resp =
          await http.post(url, headers: _authHeaders, body: jsonEncode(body));

      if (resp.statusCode == 201) return null; // new entry created
      if (resp.statusCode == 200)
        return null; // reason appended to existing entry
      if (resp.statusCode == 409) {
        return 'You already have a reason on this entry. Use edit instead.';
      }
      final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
      return decoded['error']?.toString() ??
          'Unknown error (${resp.statusCode})';
    } catch (e) {
      Logger.i('CommunityService.submitRecommendation error: $e');
      return 'Network error: $e';
    }
  }

  static Map<String, dynamic> _buildSubmitBody({
    required Media media,
    required String reason,
    required ServicesType serviceType,
    required Profile profile,
  }) {
    final body = <String, dynamic>{'reason': reason};

    final idInt = int.tryParse(media.id);
    final malInt = int.tryParse(media.idMal ?? '');

    if (serviceType == ServicesType.simkl) {
      final rawId = media.id.split('*').first;
      body['simkl_id'] = int.tryParse(rawId);
    } else if (serviceType == ServicesType.mal) {
      body['mal_id'] = idInt;
      if (malInt != null) body['anilist_id'] = null;
    } else {
      body['anilist_id'] = idInt;
      if (malInt != null && malInt != 0) body['mal_id'] = malInt;
    }

    final userId = int.tryParse(profile.id ?? '');
    final username = profile.userName ?? profile.name ?? '';
    final avatar = profile.avatar;

    if (serviceType == ServicesType.anilist) {
      if (userId != null) body['anilist_user_id'] = userId;
      if (username.isNotEmpty) body['anilist_username'] = username;
      if (avatar != null) body['anilist_avatar'] = avatar;
    } else if (serviceType == ServicesType.mal) {
      if (userId != null) body['mal_user_id'] = userId;
      if (username.isNotEmpty) body['mal_username'] = username;
      if (avatar != null) body['mal_avatar'] = avatar;
    } else if (serviceType == ServicesType.simkl) {
      if (userId != null) body['simkl_user_id'] = userId;
      if (username.isNotEmpty) body['simkl_username'] = username;
      if (avatar != null) body['simkl_avatar'] = avatar;
    }

    body['author'] = username.isNotEmpty ? username : 'Unknown';
    return body;
  }

  static Future<String?> editReason({
    required String mediaType,
    required String mediaId,
    required String newReason,
    required ServicesType serviceType,
    required Profile profile,
    bool isAdmin = false,
  }) async {
    if (!votingEnabled) return 'Bot URL not configured';
    try {
      final body = _buildUserIdentityBody(
          serviceType: serviceType, profile: profile, isAdmin: isAdmin);
      body['reason'] = newReason;
      final url = Uri.parse('$_botBaseUrl/api/edit_reason/$mediaType/$mediaId');
      final resp =
          await http.patch(url, headers: _authHeaders, body: jsonEncode(body));
      if (resp.statusCode == 200) return null;
      final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
      return decoded['error']?.toString() ??
          'Unknown error (${resp.statusCode})';
    } catch (e) {
      Logger.i('CommunityService.editReason error: $e');
      return 'Network error: $e';
    }
  }

  static Future<String?> deleteReason({
    required String mediaType,
    required String mediaId,
    required ServicesType serviceType,
    required Profile profile,
    bool isAdmin = false,
  }) async {
    if (!votingEnabled) return 'Bot URL not configured';
    try {
      final body = _buildUserIdentityBody(
          serviceType: serviceType, profile: profile, isAdmin: isAdmin);
      final url =
          Uri.parse('$_botBaseUrl/api/delete_reason/$mediaType/$mediaId');
      final resp =
          await http.delete(url, headers: _authHeaders, body: jsonEncode(body));
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
        if (decoded['pending'] == true) {
          return null; // pending admin review
        }
        return null; // deleted successfully
      }
      final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
      return decoded['error']?.toString() ??
          'Unknown error (${resp.statusCode})';
    } catch (e) {
      Logger.i('CommunityService.deleteReason error: $e');
      return 'Network error: $e';
    }
  }

  static Future<(String? error, bool pending)> deleteReasonWithStatus({
    required String mediaType,
    required String mediaId,
    required ServicesType serviceType,
    required Profile profile,
    bool isAdmin = false,
  }) async {
    if (!votingEnabled) return ('Bot URL not configured', false);
    try {
      final body = _buildUserIdentityBody(
          serviceType: serviceType, profile: profile, isAdmin: isAdmin);
      final url =
          Uri.parse('$_botBaseUrl/api/delete_reason/$mediaType/$mediaId');
      final resp =
          await http.delete(url, headers: _authHeaders, body: jsonEncode(body));
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
        final pending = decoded['pending'] == true;
        return (null, pending);
      }
      final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
      return (
        decoded['error']?.toString() ?? 'Unknown error (${resp.statusCode})',
        false
      );
    } catch (e) {
      Logger.i('CommunityService.deleteReasonWithStatus error: $e');
      return ('Network error: $e', false);
    }
  }

  static Future<String?> deleteEntry({
    required String mediaType,
    required String mediaId,
    required ServicesType serviceType,
    required Profile profile,
    bool isAdmin = false,
  }) async {
    if (!votingEnabled) return 'Bot URL not configured';
    try {
      final body = _buildUserIdentityBody(
          serviceType: serviceType, profile: profile, isAdmin: isAdmin);
      final url = Uri.parse('$_botBaseUrl/api/delete/$mediaType/$mediaId');
      final resp =
          await http.delete(url, headers: _authHeaders, body: jsonEncode(body));
      if (resp.statusCode == 200 || resp.statusCode == 202) return null;
      final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
      return decoded['error']?.toString() ??
          'Unknown error (${resp.statusCode})';
    } catch (e) {
      Logger.i('CommunityService.deleteEntry error: $e');
      return 'Network error: $e';
    }
  }

  static Future<(String? error, bool pending)> deleteEntryWithStatus({
    required String mediaType,
    required String mediaId,
    required ServicesType serviceType,
    required Profile profile,
    bool isAdmin = false,
  }) async {
    if (!votingEnabled) return ('Bot URL not configured', false);
    try {
      final body = _buildUserIdentityBody(
          serviceType: serviceType, profile: profile, isAdmin: isAdmin);
      final url = Uri.parse('$_botBaseUrl/api/delete/$mediaType/$mediaId');
      final resp =
          await http.delete(url, headers: _authHeaders, body: jsonEncode(body));
      if (resp.statusCode == 200) return (null, false);
      if (resp.statusCode == 202) return (null, true);
      final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
      return (
        decoded['error']?.toString() ?? 'Unknown error (${resp.statusCode})',
        false
      );
    } catch (e) {
      Logger.i('CommunityService.deleteEntryWithStatus error: $e');
      return ('Network error: $e', false);
    }
  }

  static Map<String, dynamic> _buildUserIdentityBody({
    required ServicesType serviceType,
    required Profile profile,
    bool isAdmin = false,
  }) {
    final body = <String, dynamic>{};
    final userId = int.tryParse(profile.id ?? '');
    final username = profile.userName ?? profile.name ?? '';
    if (serviceType == ServicesType.anilist) {
      if (userId != null) body['anilist_user_id'] = userId;
      if (username.isNotEmpty) body['anilist_username'] = username;
    } else if (serviceType == ServicesType.mal) {
      if (userId != null) body['mal_user_id'] = userId;
      if (username.isNotEmpty) body['mal_username'] = username;
    } else if (serviceType == ServicesType.simkl) {
      if (userId != null) body['simkl_user_id'] = userId;
      if (username.isNotEmpty) body['simkl_username'] = username;
    }
    if (isAdmin) body['admin'] = true;
    return body;
  }
}

class CommunityMedia {
  final Media media;
  final int? anilistUserId;
  final int? malUserId;
  final int? simklUserId;
  final String? anilistUsername;
  final String? malUsername;
  final String? simklUsername;
  final String? anilistAvatar;
  final String? malAvatar;
  final String? simklAvatar;
  final String? reason;
  final String? fallbackTitle;
  final bool isNsfw;
  final List<ReasonEntry> reasons;

  final Map<String, dynamic>? rawJson;

  CommunityMedia({
    required this.media,
    this.anilistUserId,
    this.malUserId,
    this.simklUserId,
    this.anilistUsername,
    this.malUsername,
    this.simklUsername,
    this.anilistAvatar,
    this.malAvatar,
    this.simklAvatar,
    this.reason,
    this.fallbackTitle,
    this.isNsfw = false,
    this.reasons = const [],
    this.rawJson,
  });

  String get displayTitle =>
      media.title.isNotEmpty ? media.title : (fallbackTitle ?? 'Unknown');

  String get displayDescription => reason ?? media.description;

  String? get author => usernameFor(media.serviceType);

  int get reasonCount => reasons.length;

  bool get hasMultipleReasons => reasons.length > 1;

  ReasonEntry? get firstReason => reasons.isNotEmpty ? reasons.first : null;

  bool get isFirstReasonAdmin =>
      reasons.isNotEmpty && reasons.first.user?.isAdmin == true;

  bool hasRecommendationFrom(ReasonUserProfile? user) {
    if (user == null) return false;
    return reasons.any((r) => r.user?.matchesUser(user) == true);
  }

  ReasonEntry? recommendationFrom(ReasonUserProfile? user) {
    if (user == null) return null;
    try {
      return reasons.firstWhere((r) => r.user?.matchesUser(user) == true);
    } catch (_) {
      return null;
    }
  }

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
      userVote: json['user_vote'] as String?,
    );
  }
}
