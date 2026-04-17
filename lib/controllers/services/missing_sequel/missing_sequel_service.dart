import 'dart:convert';

import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class MissingSequelService extends GetxController {
  static const String baseUrl = 'http://anymex.duckdns.org:3002';
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

  DateTime? _lastFetchCheckAnime;
  DateTime? _lastFetchCheckManga;
  DateTime? _lastFetchUpcomingAnime;
  DateTime? _lastFetchUpcomingManga;
  DateTime? _lastFetchCatchUpAnime;
  DateTime? _lastFetchCatchUpManga;

  String? _cachedPlatform;

  static const Duration _cacheDuration = Duration(hours: 24);

  Map<String, dynamic>? _cachedCheckAnime;
  Map<String, dynamic>? _cachedCheckManga;
  Map<String, dynamic>? _cachedUpcomingAnime;
  Map<String, dynamic>? _cachedUpcomingManga;
  Map<String, dynamic>? _cachedCatchUpAnime;
  Map<String, dynamic>? _cachedCatchUpManga;

  void clearAllCache() {
    _cachedCheckAnime = null;
    _cachedCheckManga = null;
    _cachedUpcomingAnime = null;
    _cachedUpcomingManga = null;
    _cachedCatchUpAnime = null;
    _cachedCatchUpManga = null;
    _lastFetchCheckAnime = null;
    _lastFetchCheckManga = null;
    _lastFetchUpcomingAnime = null;
    _lastFetchUpcomingManga = null;
    _lastFetchCatchUpAnime = null;
    _lastFetchCatchUpManga = null;
    _cachedPlatform = null;
    missingSequelsAnime.clear();
    missingSequelsManga.clear();
    upcomingSequelsAnime.clear();
    upcomingSequelsManga.clear();
    catchUpAnime.clear();
    catchUpManga.clear();
  }

  bool _isCacheValid() {
    final platform = _getPlatform();
    if (platform == null || _cachedPlatform == null) return false;
    return platform == _cachedPlatform;
  }

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
    } else if (serviceType == ServicesType.mal) {
      return serviceHandler.profileData.value.name ?? '';
    }
    return null;
  }

  Future<Map<String, dynamic>?> _apiCall(String endpoint, Map<String, dynamic> body) async {
    final platform = _getPlatform();
    final token = _getToken();
    if (platform == null || token == null) return null;

    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'X-API-Key': apiKey,
      },
      body: jsonEncode({
        ...body,
        'platform': platform,
        'token': token,
        'compact': true,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      Logger.i('MissingSequel API error: ${response.statusCode} ${response.body}');
      return null;
    }
  }

  Media _parseCompactMedia(dynamic json) {
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

    String extractCover(dynamic cover) {
      if (cover == null) return '';
      if (cover is String) return cover;
      if (cover is Map) {
        return (cover['extra_large'] ?? cover['extraLarge'] ?? cover['large'] ?? cover['medium'] ?? '').toString();
      }
      return cover.toString();
    }

    final coverUrl = extractCover(json['cover_image']);

    return Media(
      id: json['id']?.toString() ?? '0',
      idMal: json['id_mal']?.toString() ?? '0',
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
      serviceType: _getPlatform() == 'mal' ? ServicesType.mal : ServicesType.anilist,
      seasonYear: json['start_date']?['year'],
    );
  }

  Future<void> fetchMissingSequels({bool isAnime = true}) async {
    final now = DateTime.now();

    if (!_isCacheValid()) {
      clearAllCache();
    }

    final lastFetch = isAnime ? _lastFetchCheckAnime : _lastFetchCheckManga;

    if (lastFetch != null && now.difference(lastFetch) < _cacheDuration) {
      final cached = isAnime ? _cachedCheckAnime : _cachedCheckManga;
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
        _cachedPlatform = _getPlatform();
        if (isAnime) {
          _cachedCheckAnime = data;
          _lastFetchCheckAnime = now;
        } else {
          _cachedCheckManga = data;
          _lastFetchCheckManga = now;
        }
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

    final mediaList = missing.map((item) {
      final missingMedia = item['missing'];
      return _parseCompactMedia(missingMedia);
    }).where((m) => m.id != '0').toList();

    if (isAnime) {
      missingSequelsAnime.value = mediaList;
    } else {
      missingSequelsManga.value = mediaList;
    }
  }

  Future<void> fetchUpcoming({bool isAnime = true}) async {
    final now = DateTime.now();

    if (!_isCacheValid()) {
      clearAllCache();
    }

    final lastFetch = isAnime ? _lastFetchUpcomingAnime : _lastFetchUpcomingManga;

    if (lastFetch != null && now.difference(lastFetch) < _cacheDuration) {
      final cached = isAnime ? _cachedUpcomingAnime : _cachedUpcomingManga;
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
        _cachedPlatform = _getPlatform();
        if (isAnime) {
          _cachedUpcomingAnime = data;
          _lastFetchUpcomingAnime = now;
        } else {
          _cachedUpcomingManga = data;
          _lastFetchUpcomingManga = now;
        }
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
    final list = upcoming.map((item) => _parseCompactMedia(item))
        .where((m) => m.id != '0').toList();

    if (isAnime) {
      upcomingSequelsAnime.value = list;
    } else {
      upcomingSequelsManga.value = list;
    }
  }

  Future<void> fetchCatchUp({bool isAnime = true}) async {
    final now = DateTime.now();

    if (!_isCacheValid()) {
      clearAllCache();
    }

    final lastFetch = isAnime ? _lastFetchCatchUpAnime : _lastFetchCatchUpManga;

    if (lastFetch != null && now.difference(lastFetch) < _cacheDuration) {
      final cached = isAnime ? _cachedCatchUpAnime : _cachedCatchUpManga;
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
        _cachedPlatform = _getPlatform();
        if (isAnime) {
          _cachedCatchUpAnime = data;
          _lastFetchCatchUpAnime = now;
        } else {
          _cachedCatchUpManga = data;
          _lastFetchCatchUpManga = now;
        }
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
    final list = items.map((item) => _parseCompactMedia(item))
        .where((m) => m.id != '0').toList();

    if (isAnime) {
      catchUpAnime.value = list;
    } else {
      catchUpManga.value = list;
    }
  }

  void refreshSection(String section, {bool isAnime = true}) {
    switch (section) {
      case 'check':
        if (isAnime) {
          _cachedCheckAnime = null;
          _lastFetchCheckAnime = null;
          _isLoadingCheckAnime = false;
        } else {
          _cachedCheckManga = null;
          _lastFetchCheckManga = null;
          _isLoadingCheckManga = false;
        }
        fetchMissingSequels(isAnime: isAnime);
      case 'upcoming':
        if (isAnime) {
          _cachedUpcomingAnime = null;
          _lastFetchUpcomingAnime = null;
          _isLoadingUpcomingAnime = false;
        } else {
          _cachedUpcomingManga = null;
          _lastFetchUpcomingManga = null;
          _isLoadingUpcomingManga = false;
        }
        fetchUpcoming(isAnime: isAnime);
      case 'catchup':
        if (isAnime) {
          _cachedCatchUpAnime = null;
          _lastFetchCatchUpAnime = null;
          _isLoadingCatchUpAnime = false;
        } else {
          _cachedCatchUpManga = null;
          _lastFetchCatchUpManga = null;
          _isLoadingCatchUpManga = false;
        }
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
