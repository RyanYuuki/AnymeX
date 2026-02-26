import 'dart:convert';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/kitsu/kitsu_auth.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/models/Anilist/anilist_media_user.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class KitsuSync extends GetxController {
  static KitsuSync get instance => Get.find<KitsuSync>();
  final kitsuAuth = Get.find<KitsuAuth>();

  static const Map<String, String> _animeStatusMap = {
    'CURRENT': 'current',
    'COMPLETED': 'completed',
    'PAUSED': 'on_hold',
    'DROPPED': 'dropped',
    'PLANNING': 'planned',
    'REPEATING': 'current',
  };

  static const Map<String, String> _mangaStatusMap = {
    'CURRENT': 'current',
    'COMPLETED': 'completed',
    'PAUSED': 'on_hold',
    'DROPPED': 'dropped',
    'PLANNING': 'planned',
    'REPEATING': 'current',
  };
  
  Future<String?> getKitsuIdFromMalId(String malId, {bool isAnime = true}) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://kitsu.app/api/edge/mappings'
          '?filter[external_site]=${isAnime ? 'myanimelist/anime' : 'myanimelist/manga'}'
          '&filter[external_id]=$malId'
          '&include=item',
        ),
        headers: {'Accept': 'application/vnd.api+json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'].isNotEmpty && data['included'].isNotEmpty) {
          // Get the media ID from included
          final mediaItem = data['included'].firstWhere(
            (item) => item['type'] == (isAnime ? 'anime' : 'manga'),
            orElse: () => null,
          );
          return mediaItem?['id']?.toString();
        }
      }
    } catch (e) {
      Logger.i('Failed to get Kitsu ID from MAL ID: $e');
    }
    return null;
  }
  
  Future<void> syncToKitsu({
    required String listId,
    required bool isAnime,
    String? score,
    String? status,
    int? progress,
    String? malId,
  }) async {
    if (!kitsuAuth.isLoggedIn.value) {
      Logger.i('Kitsu not logged in, skipping sync');
      return;
    }
    
    String? effectiveMalId = malId;
    if (effectiveMalId == null) {
      final currentService = serviceHandler.serviceType.value;
      if (currentService == ServicesType.anilist) {
        effectiveMalId = await _getMalIdFromAnilist(listId);
      } else if (currentService == ServicesType.mal) {
        effectiveMalId = listId;
      } else if (currentService == ServicesType.simkl) {
        effectiveMalId = await _getMalIdFromSimkl(listId);
      }
    }

    if (effectiveMalId == null) {
      Logger.i('No MAL ID available for Kitsu sync');
      return;
    }
    
    final kitsuMediaId = await getKitsuIdFromMalId(effectiveMalId, isAnime: isAnime);
    if (kitsuMediaId == null) {
      Logger.i('No Kitsu mapping found for MAL ID: $effectiveMalId');
      return;
    }
    
    final existingEntry = await _findLibraryEntry(kitsuMediaId, isAnime);
    
    if (existingEntry != null) {
      await _updateLibraryEntry(existingEntry, kitsuMediaId, isAnime, score, status, progress);
    } else {
      await _createLibraryEntry(kitsuMediaId, isAnime, score, status, progress);
    }
  }

  Future<String?> _getMalIdFromAnilist(String anilistId) async {
    try {
      const query = '''
      query (\$id: Int) {
        Media(id: \$id) {
          idMal
        }
      }
      ''';

      final response = await http.post(
        Uri.parse('https://graphql.anilist.co'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'query': query,
          'variables': {'id': int.parse(anilistId)},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['Media']['idMal']?.toString();
      }
    } catch (e) {
      Logger.i('Failed to get MAL ID from AniList: $e');
    }
    return null;
  }

  Future<String?> _getMalIdFromSimkl(String simklId) async {
    try {
      final cleanId = simklId.split('*').first;
      final response = await http.get(
        Uri.parse('https://api.simkl.com/anime/$cleanId?client_id=${dotenv.env['SIMKL_CLIENT_ID']}&extended=full'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['ids']['mal']?.toString();
      }
    } catch (e) {
      Logger.i('Failed to get MAL ID from Simkl: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> _findLibraryEntry(String mediaId, bool isAnime) async {
    final token = AuthKeys.kitsuAuthToken.get<String?>();
    if (token == null) return null;

    try {
      final userResponse = await http.get(
        Uri.parse('https://kitsu.app/api/edge/users?filter[self]=true'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/vnd.api+json',
        },
      );

      if (userResponse.statusCode != 200) return null;
      final userData = jsonDecode(userResponse.body);
      final userId = userData['data'][0]['id'];
      final entryResponse = await http.get(
        Uri.parse(
          'https://kitsu.app/api/edge/library-entries'
          '?filter[user_id]=$userId'
          '&filter[${isAnime ? 'anime' : 'manga'}_id]=$mediaId',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/vnd.api+json',
        },
      );

      if (entryResponse.statusCode == 200) {
        final data = jsonDecode(entryResponse.body);
        if (data['data'].isNotEmpty) {
          return data['data'][0];
        }
      }
    } catch (e) {
      Logger.i('Error finding library entry: $e');
    }
    return null;
  }

  Future<void> _createLibraryEntry(
    String mediaId,
    bool isAnime,
    String? score,
    String? status,
    int? progress,
  ) async {
    final token = AuthKeys.kitsuAuthToken.get<String?>();
    if (token == null) return;

    try {
      final userResponse = await http.get(
        Uri.parse('https://kitsu.app/api/edge/users?filter[self]=true'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/vnd.api+json',
        },
      );

      if (userResponse.statusCode != 200) return;
      final userData = jsonDecode(userResponse.body);
      final userId = userData['data'][0]['id'];
      final Map<String, dynamic> attributes = {};
      
      if (status != null && status.isNotEmpty) {
        final kitsuStatus = isAnime 
            ? _animeStatusMap[status.toUpperCase()]
            : _mangaStatusMap[status.toUpperCase()];
        if (kitsuStatus != null) {
          attributes['status'] = kitsuStatus;
        }
      }

      if (progress != null && progress > 0) {
        attributes['progress'] = progress;
      }

      if (score != null && score.isNotEmpty) {
        final doubleScore = double.tryParse(score) ?? 0.0;
        if (doubleScore > 0) {
          attributes['ratingTwenty'] = (doubleScore * 2).round();
        }
      }
      
      final body = {
        'data': {
          'type': 'libraryEntries',
          'attributes': attributes,
          'relationships': {
            'user': {
              'data': {'id': userId, 'type': 'users'}
            },
            'media': {
              'data': {'id': mediaId, 'type': isAnime ? 'anime' : 'manga'}
            }
          }
        }
      };

      final response = await http.post(
        Uri.parse('https://kitsu.app/api/edge/library-entries'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/vnd.api+json',
          'Accept': 'application/vnd.api+json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        Logger.i('Successfully created Kitsu entry');
      } else {
        Logger.i('Failed to create Kitsu entry: ${response.body}');
      }
    } catch (e) {
      Logger.i('Error creating library entry: $e');
    }
  }

  Future<void> _updateLibraryEntry(
    Map<String, dynamic> existingEntry,
    String mediaId,
    bool isAnime,
    String? score,
    String? status,
    int? progress,
  ) async {
    final token = AuthKeys.kitsuAuthToken.get<String?>();
    if (token == null) return;

    try {
      final entryId = existingEntry['id'];
      final Map<String, dynamic> attributes = {};
      
      if (status != null && status.isNotEmpty) {
        final kitsuStatus = isAnime 
            ? _animeStatusMap[status.toUpperCase()]
            : _mangaStatusMap[status.toUpperCase()];
        if (kitsuStatus != null) {
          attributes['status'] = kitsuStatus;
        }
      }

      if (progress != null && progress > 0) {
        attributes['progress'] = progress;
      }

      if (score != null && score.isNotEmpty) {
        final doubleScore = double.tryParse(score) ?? 0.0;
        if (doubleScore > 0) {
          attributes['ratingTwenty'] = (doubleScore * 2).round();
        }
      }
      
      final body = {
        'data': {
          'type': 'libraryEntries',
          'id': entryId,
          'attributes': attributes,
        }
      };

      final response = await http.patch(
        Uri.parse('https://kitsu.app/api/edge/library-entries/$entryId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/vnd.api+json',
          'Accept': 'application/vnd.api+json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        Logger.i('Successfully updated Kitsu entry');
      } else {
        Logger.i('Failed to update Kitsu entry: ${response.body}');
      }
    } catch (e) {
      Logger.i('Error updating library entry: $e');
    }
  }
  
  Future<void> batchSyncToKitsu() async {
    if (!kitsuAuth.isLoggedIn.value) return;

    final service = serviceHandler.onlineService;
    
    for (final anime in service.animeList) {
      await syncToKitsu(
        listId: anime.id ?? '',
        isAnime: true,
        score: anime.score?.toString(),
        status: anime.watchingStatus,
        progress: int.tryParse(anime.episodeCount ?? '0'),
        malId: anime.malId?.toString(),
      );
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    for (final manga in service.mangaList) {
      await syncToKitsu(
        listId: manga.id ?? '',
        isAnime: false,
        score: manga.score?.toString(),
        status: manga.watchingStatus,
        progress: int.tryParse(manga.chapterCount ?? '0'),
        malId: manga.malId?.toString(),
      );
      await Future.delayed(const Duration(milliseconds: 500));
    }

    snackBar('Kitsu sync completed!');
  }
}
