import 'dart:convert';
import 'package:anymex/controllers/network/network_manager.dart';
import 'package:anymex/controllers/services/anilist/anilist_cache.dart';
import 'package:anymex/controllers/services/anilist/anilist_error_handler.dart';
import 'package:anymex/controllers/services/anilist/anilist_queries.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/models/Media/character.dart';
import 'package:anymex/models/Media/staff.dart';
import 'package:anymex/utils/logger.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class AnilistApi {
  NetworkManager get _net => Get.find<NetworkManager>();
  http.Client get _client => _net.compatibleClient;

  static const String _url = 'https://graphql.anilist.co';

  Future<Map<String, dynamic>?> postQuery(
    String query, {
    Map<String, dynamic>? variables,
    String? token,
    int maxRetries = 2,
  }) async {
    final tokenn = token ?? AuthKeys.authToken.get<String?>();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (tokenn != null && tokenn.isNotEmpty) 'Authorization': 'Bearer $tokenn',
    };

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final response = await _client.post(
          Uri.parse(_url),
          headers: headers,
          body: json.encode({
            'query': query,
            if (variables != null) 'variables': variables,
          }),
        );

        if (response.statusCode == 200) {
          final decoded = json.decode(response.body) as Map<String, dynamic>?;
          if (decoded != null && decoded['errors'] != null) {
            AnilistErrorHandler.handleResponse(response);
          }
          return decoded;
        }

        if (response.statusCode == 429 && attempt < maxRetries) {
          final retryAfter = response.headers['retry-after'];
          final waitSeconds = retryAfter != null
              ? (int.tryParse(retryAfter) ?? (2 << attempt))
              : (2 << attempt);
          await Future.delayed(Duration(seconds: waitSeconds));
          continue;
        }

        AnilistErrorHandler.handleResponse(response);
        Logger.i('AniList GraphQL Error: ${response.statusCode} - ${response.body}');
        return null;
      } catch (e) {
        if (attempt >= maxRetries) {
          AnilistErrorHandler.handleError(e);
          Logger.i('Error posting AniList query: $e');
          return null;
        }
        await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
      }
    }
    return null;
  }

  Future<Character?> getCharacterDetails(String id) async {
    final cached = await AnilistCache.instance.get('character_$id');
    if (cached != null) {
      return Character.fromJson(cached);
    }

    final variables = {'id': int.tryParse(id)};
    final data = await postQuery(characterDetailsQuery, variables: variables);
    if (data != null && data['data'] != null && data['data']['Character'] != null) {
      final charJson = data['data']['Character'] as Map<String, dynamic>;
      AnilistCache.instance.put(
        'character_$id',
        charJson,
        ttl: const Duration(days: 7),
        persist: true,
      );
      return Character.fromJson(charJson);
    }
    return null;
  }

  Future<Staff?> getStaffDetails(String id) async {
    final cached = await AnilistCache.instance.get('staff_$id');
    if (cached != null) {
      return Staff.fromDetailJson(cached);
    }

    int charPage = 1;
    int staffPage = 1;
    bool charHasNext = true;
    bool staffHasNext = true;
    List<dynamic> allCharacterEdges = [];
    List<dynamic> allStaffEdges = [];
    Map<String, dynamic>? initialData;
    int loopCount = 0;

    try {
      while (staffHasNext && loopCount < 3) {
        final variables = {
          'id': int.tryParse(id),
          'characterPage': charPage,
          'staffPage': staffPage,
        };

        final data = await postQuery(staffDetailsQuery, variables: variables);
        if (data != null && data['data'] != null && data['data']['Staff'] != null) {
          final staffData = data['data']['Staff'];

          if (loopCount == 0) {
            initialData = staffData;
          }

          if (charHasNext) {
            final charData = staffData['characters'];
            if (charData != null) {
              final edges = charData['edges'] as List?;
              if (edges != null) allCharacterEdges.addAll(edges);
              final pageInfo = charData['pageInfo'];
              charHasNext = pageInfo?['hasNextPage'] ?? false;
              if (charHasNext) charPage++;
            } else {
              charHasNext = false;
            }
          }

          if (staffHasNext) {
            final stfMedia = staffData['staffMedia'];
            if (stfMedia != null) {
              final edges = stfMedia['edges'] as List?;
              if (edges != null) allStaffEdges.addAll(edges);
              final pageInfo = stfMedia['pageInfo'];
              staffHasNext = pageInfo?['hasNextPage'] ?? false;
              if (staffHasNext) staffPage++;
            } else {
              staffHasNext = false;
            }
          }
        } else {
          break;
        }
        loopCount++;
      }

      if (initialData != null) {
        final finalData = Map<String, dynamic>.from(initialData);
        if (finalData['characters'] == null) finalData['characters'] = {};
        finalData['characters']['edges'] = allCharacterEdges;
        if (finalData['staffMedia'] == null) finalData['staffMedia'] = {};
        finalData['staffMedia']['edges'] = allStaffEdges;
        AnilistCache.instance.put(
          'staff_$id',
          finalData,
          ttl: const Duration(days: 7),
          persist: true,
        );
        return Staff.fromDetailJson(finalData);
      }
    } catch (e) {
      Logger.i('Error fetching staff details: $e');
    }
    return null;
  }
}
