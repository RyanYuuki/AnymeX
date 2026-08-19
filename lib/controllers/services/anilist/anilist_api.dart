import 'dart:convert';
import 'package:anymex/controllers/network/network_manager.dart';
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
  }) async {
    final tokenn = token ?? AuthKeys.authToken.get<String?>();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (tokenn != null && tokenn.isNotEmpty) 'Authorization': 'Bearer $tokenn',
    };

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
        return json.decode(response.body) as Map<String, dynamic>?;
      } else {
        Logger.i('AniList GraphQL Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      Logger.i('Error posting AniList query: $e');
    }
    return null;
  }

  Future<Character?> getCharacterDetails(String id) async {
    final variables = {'id': int.tryParse(id)};
    final data = await postQuery(characterDetailsQuery, variables: variables);
    if (data != null && data['data'] != null && data['data']['Character'] != null) {
      return Character.fromJson(data['data']['Character']);
    }
    return null;
  }

  Future<Staff?> getStaffDetails(String id) async {
    int charPage = 1;
    int staffPage = 1;
    bool charHasNext = true;
    bool staffHasNext = true;
    List<dynamic> allCharacterEdges = [];
    List<dynamic> allStaffEdges = [];
    Map<String, dynamic>? initialData;
    int loopCount = 0;

    try {
      while (staffHasNext && loopCount < 20) {
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
        return Staff.fromDetailJson(finalData);
      }
    } catch (e) {
      Logger.i('Error fetching staff details: $e');
    }
    return null;
  }
}
