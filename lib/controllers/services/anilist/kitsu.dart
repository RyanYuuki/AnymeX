import 'dart:convert';
import 'package:anymex/utils/logger.dart';

import 'package:anymex/models/Offline/Hive/episode.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

class Kitsu {
  static Future<List<Episode>> fetchKitsuEpisodes(
      String id, List<Episode> episodes) async {
    final query = '''
    query {
      lookupMapping(externalId: $id, externalSite: ANILIST_ANIME) {
        __typename
        ... on Anime {
          id
          episodes(first: 2000) {
            nodes {
              number
              titles {
                canonicalLocale
              }
              description
              thumbnail {
                original {
                  url
                }
              }
            }
          }
        }
      }
    }
    ''';

    final result = (await fetchFromKitsu(query));
    if (result == null) {
      Logger.i("Yeah so it didnt really go well, not found on kitsu as well");
      return episodes;
    }
    final kitsuEpisodes = result['data']['episodes']['nodes'];
    for (int i = 0; i <= kitsuEpisodes.length; i++) {
      final episode = episodes[i];
      episode.title =
          kitsuEpisodes[i]?['titles']?['canonicalLocale'] ?? episode.title;
      episode.thumbnail = kitsuEpisodes[i]?['thumbnail']['original']['url'] ??
          episode.thumbnail;
      episode.desc = kitsuEpisodes[i]?['description'] ?? episode.desc;
    }
    return episodes;
  }

  static Future<dynamic> fetchFromKitsu(String query) async {
    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
    };

    try {
      final response = await post(
        Uri.parse('https://kitsu.io/api/graphql'),
        headers: headers,
        body: jsonEncode({"query": query}),
      );
      final json = await jsonDecode(response.body);
      return json;
    } catch (e) {
      debugPrint("Error fetching Kitsu data: $e");
      return null;
    }
  }
}
