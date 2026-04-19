import 'dart:convert';

import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class MissingSequelService extends GetxController {
  static const String baseUrl = 'http://217.60.25.118:3002';
  static const String apiKey = 'xK9mP2vL7nQ4wR8';

  RxList<Media> missingSequelsAnime = <Media>[].obs;
  RxList<Media> missingSequelsManga = <Media>[].obs;
  RxList<Media> upcomingSequelsAnime = <Media>[].obs;
  RxList<Media> upcomingSequelsManga = <Media>[].obs;
  RxList<Media> catchUpAnime = <Media>[].obs;
  RxList<Media> catchUpManga = <Media>[].obs;

  bool _isLoadingCheckAnime = false;
  bool _isLoadingCheckManga = false;
  bool _isLoadingUpcomingAnime = false;
  bool _isLoadingUpcomingManga = false;
  bool _isLoadingCatchUpAnime = false;
  bool _isLoadingCatchUpManga = false;

  bool get isLoadingCheckAnime => _isLoadingCheckAnime;
  bool get isLoadingCheckManga => _isLoadingCheckManga;
  bool get isLoadingUpcomingAnime => _isLoadingUpcomingAnime;
  bool get isLoadingUpcomingManga => _isLoadingUpcomingManga;
  bool get isLoadingCatchUpAnime => _isLoadingCatchUpAnime;
  bool get isLoadingCatchUpManga => _isLoadingCatchUpManga;

  DateTime? _alLastFetchCheckAnime;
  DateTime? _alLastFetchCheckManga;
  DateTime? _alLastFetchUpcomingAnime;
  DateTime? _alLastFetchUpcomingManga;
  DateTime? _alLastFetchCatchUpAnime;
  DateTime? _alLastFetchCatchUpManga;

  Map<String, dynamic>? _alCachedCheckAnime;
  Map<String, dynamic>? _alCachedCheckManga;
  Map<String, dynamic>? _alCachedUpcomingAnime;
  Map<String, dynamic>? _alCachedUpcomingManga;
  Map<String, dynamic>? _alCachedCatchUpAnime;
  Map<String, dynamic>? _alCachedCatchUpManga;

  DateTime? _malLastFetchCheckAnime;
  DateTime? _malLastFetchCheckManga;
  DateTime? _malLastFetchUpcomingAnime;
  DateTime? _malLastFetchUpcomingManga;
  DateTime? _malLastFetchCatchUpAnime;
  DateTime? _malLastFetchCatchUpManga;

  Map<String, dynamic>? _malCachedCheckAnime;
  Map<String, dynamic>? _malCachedCheckManga;
  Map<String, dynamic>? _malCachedUpcomingAnime;
  Map<String, dynamic>? _malCachedUpcomingManga;
  Map<String, dynamic>? _malCachedCatchUpAnime;
  Map<String, dynamic>? _malCachedCatchUpManga;

  static const Duration _cacheDuration = Duration(hours: 24);

  String? _getPlatform() {
    final serviceType = serviceHandler.serviceType.value;
    switch (serviceType) {
      case ServicesType.anilist:
        return 'anilist';
      case ServicesType.mal:
        return 'mal';
      default:
        return null;
    }
  }

  String? _getToken() {
    final serviceType = serviceHandler.serviceType.value;
    if (serviceType == ServicesType.anilist) {
      return AuthKeys.authToken.get<String?>();
    } else if (serviceType == ServicesType.mal) {
      return AuthKeys.malAuthToken.get<String?>();
    }
    return null;
  }

  dynamic _getUserId() {
    final serviceType = serviceHandler.serviceType.value;
    if (serviceType == ServicesType.anilist) {
      return int.tryParse(serviceHandler.profileData.value.id ?? '') ?? 0;
    }
    // MAL: don't send user_id, backend resolves username from token
    return null;
  }

  void clearAllCache() {
    _alCachedCheckAnime = null;
    _alCachedCheckManga = null;
    _alCachedUpcomingAnime = null;
    _alCachedUpcomingManga = null;
    _alCachedCatchUpAnime = null;
    _alCachedCatchUpManga = null;
    _alLastFetchCheckAnime = null;
    _alLastFetchCheckManga = null;
    _alLastFetchUpcomingAnime = null;
    _alLastFetchUpcomingManga = null;
    _alLastFetchCatchUpAnime = null;
    _alLastFetchCatchUpManga = null;

    _malCachedCheckAnime = null;
    _malCachedCheckManga = null;
    _malCachedUpcomingAnime = null;
    _malCachedUpcomingManga = null;
    _malCachedCatchUpAnime = null;
    _malCachedCatchUpManga = null;
    _malLastFetchCheckAnime = null;
    _malLastFetchCheckManga = null;
    _malLastFetchUpcomingAnime = null;
    _malLastFetchUpcomingManga = null;
    _malLastFetchCatchUpAnime = null;
    _malLastFetchCatchUpManga = null;

    missingSequelsAnime.clear();
    missingSequelsManga.clear();
    upcomingSequelsAnime.clear();
    upcomingSequelsManga.clear();
    catchUpAnime.clear();
    catchUpManga.clear();
  }

  Future<Map<String, dynamic>?> _apiCall(String endpoint, Map<String, dynamic> body) async {
    final platform = _getPlatform();
    final token = _getToken();
    if (platform == null || token == null) return null;

    final Map<String, dynamic> requestBody = {
      'platform': platform,
      'token': token,
      'compact': true,
    };
    body.forEach((key, value) {
      if (value != null) {
        requestBody[key] = value;
      }
    });

    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'X-API-Key': apiKey,
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      Logger.i('MissingSequel API error: ${response.statusCode} ${response.body}');
      return null;
    }
  }

  Media _parseAniListCompactMedia(dynamic json) {
    if (json == null) return Media(serviceType: ServicesType.anilist);

    final title = json['title'];
    String titleStr = '';
    String romajiStr = '';

    if (title is String) {
      titleStr = title;
      romajiStr = title;
    } else if (title is Map) {
      titleStr = title['english'] ?? title['preferred'] ?? title['romaji'] ?? '';
      romajiStr = title['romaji'] ?? title['preferred'] ?? '';
    }

    final type = json['type']?.toString().toUpperCase() ?? 'ANIME';
    final isManga = type == 'MANGA';

    String episodes = json['episodes']?.toString() ?? '?';
    String chapters = json['chapters']?.toString() ?? '?';

    if (isManga && chapters != '?') {
      episodes = '?';
    }

    final coverUrl = _extractCover(json['cover_image']);

    return Media(
      id: json['id']?.toString() ?? '0',
      title: titleStr,
      romajiTitle: romajiStr,
      poster: coverUrl,
      cover: coverUrl,
      totalEpisodes: episodes,
      totalChapters: chapters,
      status: (json['status'] ?? '').toString().replaceAll('_', ' '),
      rating: json['average_score'] != null
          ? (json['average_score'] / 10).toStringAsFixed(1)
          : '?',
      type: type,
      format: json['format']?.toString() ?? '',
      mediaType: isManga ? ItemType.manga : ItemType.anime,
      serviceType: ServicesType.anilist,
      seasonYear: json['start_date']?['year'],
    );
  }

  Media _parseMalCompactMedia(dynamic json) {
    if (json == null) return Media(serviceType: ServicesType.mal);

    final title = json['title'];
    String titleStr = '';
    String romajiStr = '';

    if (title is String) {
      titleStr = title;
      romajiStr = title;
    } else if (title is Map) {
      titleStr = title['english'] ?? title['preferred'] ?? title['romaji'] ?? '';
      romajiStr = title['preferred'] ?? title['english'] ?? '';
    }

    final type = json['type']?.toString().toUpperCase() ?? 'ANIME';
    final isManga = type == 'MANGA';

    String episodes = json['episodes']?.toString() ?? '?';
    String chapters = json['chapters']?.toString() ?? '?';

    if (isManga && chapters != '?') {
      episodes = '?';
    }

    final coverUrl = _extractCover(json['cover_image']);

    return Media(
      id: json['id']?.toString() ?? '0',
      title: titleStr,
      romajiTitle: romajiStr,
      poster: coverUrl,
      cover: coverUrl,
      totalEpisodes: episodes,
      totalChapters: chapters,
      status: (json['status'] ?? '').toString().replaceAll('_', ' '),
      rating: json['average_score'] != null
          ? (json['average_score'] / 10).toStringAsFixed(1)
          : '?',
      type: type,
      format: json['format']?.toString() ?? '',
      mediaType: isManga ? ItemType.manga : ItemType.anime,
      serviceType: ServicesType.mal,
      seasonYear: json['start_date']?['year'],
    );
  }

  String _extractCover(dynamic cover) {
    if (cover == null) return '';
    if (cover is String) return cover;
    if (cover is Map) {
      return (cover['extra_large'] ?? cover['extraLarge'] ?? cover['large'] ?? cover['medium'] ?? '').toString();
    }
    return cover.toString();
  }

  bool _isMal() => _getPlatform() == 'mal';

  DateTime? _getLastFetchCheck(bool isAnime) =>
      _isMal() ? (isAnime ? _malLastFetchCheckAnime : _malLastFetchCheckManga) : (isAnime ? _alLastFetchCheckAnime : _alLastFetchCheckManga);

  void _setLastFetchCheck(bool isAnime, DateTime time) {
    if (_isMal()) {
      if (isAnime) _malLastFetchCheckAnime = time;
      else _malLastFetchCheckManga = time;
    } else {
      if (isAnime) _alLastFetchCheckAnime = time;
      else _alLastFetchCheckManga = time;
    }
  }

  Map<String, dynamic>? _getCachedCheck(bool isAnime) =>
      _isMal() ? (isAnime ? _malCachedCheckAnime : _malCachedCheckManga) : (isAnime ? _alCachedCheckAnime : _alCachedCheckManga);

  void _setCachedCheck(bool isAnime, Map<String, dynamic>? data) {
    if (_isMal()) {
      if (isAnime) _malCachedCheckAnime = data;
      else _malCachedCheckManga = data;
    } else {
      if (isAnime) _alCachedCheckAnime = data;
      else _alCachedCheckManga = data;
    }
  }

  DateTime? _getLastFetchUpcoming(bool isAnime) =>
      _isMal() ? (isAnime ? _malLastFetchUpcomingAnime : _malLastFetchUpcomingManga) : (isAnime ? _alLastFetchUpcomingAnime : _alLastFetchUpcomingManga);

  void _setLastFetchUpcoming(bool isAnime, DateTime time) {
    if (_isMal()) {
      if (isAnime) _malLastFetchUpcomingAnime = time;
      else _malLastFetchUpcomingManga = time;
    } else {
      if (isAnime) _alLastFetchUpcomingAnime = time;
      else _alLastFetchUpcomingManga = time;
    }
  }

  Map<String, dynamic>? _getCachedUpcoming(bool isAnime) =>
      _isMal() ? (isAnime ? _malCachedUpcomingAnime : _malCachedUpcomingManga) : (isAnime ? _alCachedUpcomingAnime : _alCachedUpcomingManga);

  void _setCachedUpcoming(bool isAnime, Map<String, dynamic>? data) {
    if (_isMal()) {
      if (isAnime) _malCachedUpcomingAnime = data;
      else _malCachedUpcomingManga = data;
    } else {
      if (isAnime) _alCachedUpcomingAnime = data;
      else _alCachedUpcomingManga = data;
    }
  }

  DateTime? _getLastFetchCatchUp(bool isAnime) =>
      _isMal() ? (isAnime ? _malLastFetchCatchUpAnime : _malLastFetchCatchUpManga) : (isAnime ? _alLastFetchCatchUpAnime : _alLastFetchCatchUpManga);

  void _setLastFetchCatchUp(bool isAnime, DateTime time) {
    if (_isMal()) {
      if (isAnime) _malLastFetchCatchUpAnime = time;
      else _malLastFetchCatchUpManga = time;
    } else {
      if (isAnime) _alLastFetchCatchUpAnime = time;
      else _alLastFetchCatchUpManga = time;
    }
  }

  Map<String, dynamic>? _getCachedCatchUp(bool isAnime) =>
      _isMal() ? (isAnime ? _malCachedCatchUpAnime : _malCachedCatchUpManga) : (isAnime ? _alCachedCatchUpAnime : _alCachedCatchUpManga);

  void _setCachedCatchUp(bool isAnime, Map<String, dynamic>? data) {
    if (_isMal()) {
      if (isAnime) _malCachedCatchUpAnime = data;
      else _malCachedCatchUpManga = data;
    } else {
      if (isAnime) _alCachedCatchUpAnime = data;
      else _alCachedCatchUpManga = data;
    }
  }

  Future<void> fetchMissingSequels({bool isAnime = true}) async {
    final now = DateTime.now();
    final lastFetch = _getLastFetchCheck(isAnime);

    if (lastFetch != null && now.difference(lastFetch) < _cacheDuration) {
      final cached = _getCachedCheck(isAnime);
      if (cached != null) {
        _processCheckResponse(cached, isAnime);
        return;
      }
    }

    if (isAnime ? _isLoadingCheckAnime : _isLoadingCheckManga) return;
    if (isAnime) {
      _isLoadingCheckAnime = true;
    } else {
      _isLoadingCheckManga = true;
    }

    try {
      final body = {
        'user_id': _getUserId(),
        'media_type': isAnime ? 'ANIME' : 'MANGA',
        'include_upcoming': false,
      };

      final data = await _apiCall('/api/check', body);
      if (data != null) {
        _setLastFetchCheck(isAnime, now);
        _setCachedCheck(isAnime, data);
        _processCheckResponse(data, isAnime);
      }
    } catch (e) {
      Logger.i('Error fetching missing sequels: $e');
    } finally {
      if (isAnime) {
        _isLoadingCheckAnime = false;
      } else {
        _isLoadingCheckManga = false;
      }
    }
  }

  void _processCheckResponse(Map<String, dynamic> data, bool isAnime) {
    final missing = data['missing'] as List<dynamic>? ?? [];
    final isMal = _isMal();

    final mediaList = missing.map((item) {
      final missingMedia = item['missing'];
      return isMal
          ? _parseMalCompactMedia(missingMedia)
          : _parseAniListCompactMedia(missingMedia);
    }).where((m) => m.id != '0').toList();

    if (isAnime) {
      missingSequelsAnime.value = mediaList;
    } else {
      missingSequelsManga.value = mediaList;
    }
  }

  Future<void> fetchUpcoming({bool isAnime = true}) async {
    final now = DateTime.now();
    final lastFetch = _getLastFetchUpcoming(isAnime);

    if (lastFetch != null && now.difference(lastFetch) < _cacheDuration) {
      final cached = _getCachedUpcoming(isAnime);
      if (cached != null) {
        _processUpcomingResponse(cached, isAnime);
        return;
      }
    }

    if (isAnime ? _isLoadingUpcomingAnime : _isLoadingUpcomingManga) return;
    if (isAnime) {
      _isLoadingUpcomingAnime = true;
    } else {
      _isLoadingUpcomingManga = true;
    }

    try {
      final body = {
        'user_id': _getUserId(),
        'media_type': isAnime ? 'ANIME' : 'MANGA',
      };

      final data = await _apiCall('/api/upcoming', body);
      if (data != null) {
        _setLastFetchUpcoming(isAnime, now);
        _setCachedUpcoming(isAnime, data);
        _processUpcomingResponse(data, isAnime);
      }
    } catch (e) {
      Logger.i('Error fetching upcoming: $e');
    } finally {
      if (isAnime) {
        _isLoadingUpcomingAnime = false;
      } else {
        _isLoadingUpcomingManga = false;
      }
    }
  }

  void _processUpcomingResponse(Map<String, dynamic> data, bool isAnime) {
    final upcoming = data['upcoming'] as List<dynamic>? ?? [];
    final isMal = _isMal();

    final list = upcoming.map((item) {
      return isMal
          ? _parseMalCompactMedia(item)
          : _parseAniListCompactMedia(item);
    }).where((m) => m.id != '0').toList();

    if (isAnime) {
      upcomingSequelsAnime.value = list;
    } else {
      upcomingSequelsManga.value = list;
    }
  }

  Future<void> fetchCatchUp({bool isAnime = true}) async {
    final now = DateTime.now();
    final lastFetch = _getLastFetchCatchUp(isAnime);

    if (lastFetch != null && now.difference(lastFetch) < _cacheDuration) {
      final cached = _getCachedCatchUp(isAnime);
      if (cached != null) {
        _processCatchUpResponse(cached, isAnime);
        return;
      }
    }

    if (isAnime ? _isLoadingCatchUpAnime : _isLoadingCatchUpManga) return;
    if (isAnime) {
      _isLoadingCatchUpAnime = true;
    } else {
      _isLoadingCatchUpManga = true;
    }

    try {
      final body = {
        'user_id': _getUserId(),
        'media_type': isAnime ? 'ANIME' : 'MANGA',
      };

      final data = await _apiCall('/api/status-check', body);
      if (data != null) {
        _setLastFetchCatchUp(isAnime, now);
        _setCachedCatchUp(isAnime, data);
        _processCatchUpResponse(data, isAnime);
      }
    } catch (e) {
      Logger.i('Error fetching catch up: $e');
    } finally {
      if (isAnime) {
        _isLoadingCatchUpAnime = false;
      } else {
        _isLoadingCatchUpManga = false;
      }
    }
  }

  void _processCatchUpResponse(Map<String, dynamic> data, bool isAnime) {
    final items = data['finished_not_completed'] as List<dynamic>? ?? [];
    final isMal = _isMal();

    final list = items.map((item) {
      return isMal
          ? _parseMalCompactMedia(item)
          : _parseAniListCompactMedia(item);
    }).where((m) => m.id != '0').toList();

    if (isAnime) {
      catchUpAnime.value = list;
    } else {
      catchUpManga.value = list;
    }
  }

  void refreshSection(String section, {bool isAnime = true}) {
    switch (section) {
      case 'check':
        _setCachedCheck(isAnime, null);
        _setLastFetchCheck(isAnime, DateTime.fromMillisecondsSinceEpoch(0));
        if (isAnime) _isLoadingCheckAnime = false;
        else _isLoadingCheckManga = false;
        fetchMissingSequels(isAnime: isAnime);
      case 'upcoming':
        _setCachedUpcoming(isAnime, null);
        _setLastFetchUpcoming(isAnime, DateTime.fromMillisecondsSinceEpoch(0));
        if (isAnime) _isLoadingUpcomingAnime = false;
        else _isLoadingUpcomingManga = false;
        fetchUpcoming(isAnime: isAnime);
      case 'catchup':
        _setCachedCatchUp(isAnime, null);
        _setLastFetchCatchUp(isAnime, DateTime.fromMillisecondsSinceEpoch(0));
        if (isAnime) _isLoadingCatchUpAnime = false;
        else _isLoadingCatchUpManga = false;
        fetchCatchUp(isAnime: isAnime);
    }
  }

  Future<void> fetchAll() async {
    final platform = _getPlatform();
    final token = _getToken();
    if (platform == null || token == null) return;

    await Future.wait([
      fetchMissingSequels(isAnime: true),
      fetchMissingSequels(isAnime: false),
      fetchUpcoming(isAnime: true),
      fetchUpcoming(isAnime: false),
      fetchCatchUp(isAnime: true),
      fetchCatchUp(isAnime: false),
    ]);
  }

  void onListChanged({bool? isAnime}) {
    clearAllCache();
    fetchAll();
  }
}
