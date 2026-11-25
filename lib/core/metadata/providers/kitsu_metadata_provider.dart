import 'dart:convert';
import 'package:anymex/controllers/network/network_manager.dart';
import 'package:anymex/core/metadata/models/episode_metadata.dart';
import 'package:anymex/core/metadata/providers/episode_metadata_provider.dart';

class KitsuMetadataProvider implements EpisodeMetadataProvider {
  @override
  String get id => 'kitsu';

  @override
  String get name => 'Kitsu';

  @override
  String get description => 'Canonical titles, descriptions, and high-res thumbnails via Kitsu GraphQL';

  @override
  bool supports(MetadataTargetIds ids) {
    return ids.anilistId != null || ids.malId != null || ids.kitsuId != null;
  }

  @override
  Future<Map<String, EpisodeMetadataItem>> fetchEpisodes(MetadataTargetIds ids) async {
    final query = ids.kitsuId != null
        ? '''
query {
  findAnimeById(id: ${ids.kitsuId}) {
    episodes(first: 2000) {
      nodes {
        number
        titles { localized }
        description
        thumbnail { original { url } }
        length
      }
    }
  }
}
'''
        : '''
query {
  lookupMapping(externalId: ${ids.anilistId ?? ids.malId}, externalSite: ${ids.anilistId != null ? 'ANILIST_ANIME' : 'MYANIMELIST_ANIME'}) {
    __typename
    ... on Anime {
      id
      episodes(first: 2000) {
        nodes {
          number
          titles { canonical }
          description
          thumbnail { original { url } }
          length
        }
      }
    }
  }
}
''';

    try {
      final response = await NetworkManager.instance.compatibleClient.post(
        Uri.parse('https://kitsu.io/api/graphql'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'query': query}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200 || response.body.isEmpty) {
        return const {};
      }

      final dynamic data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) return const {};

      final graphData = data['data'];
      if (graphData is! Map) return const {};

      List? nodes;
      if (graphData['findAnimeById'] is Map) {
        nodes = graphData['findAnimeById']['episodes']?['nodes'];
      } else if (graphData['lookupMapping'] is Map) {
        final mapping = graphData['lookupMapping'];
        ids.kitsuId ??= mapping['id']?.toString();
        nodes = mapping['episodes']?['nodes'];
      }

      if (nodes == null || nodes.isEmpty) return const {};

      final result = <String, EpisodeMetadataItem>{};
      for (final node in nodes) {
        if (node is! Map || node['number'] == null) continue;

        final rawNumber = node['number'];
        final episodeNum = double.tryParse('$rawNumber')?.toString() ?? '$rawNumber';
        final normalizedNumber = episodeNum.endsWith('.0')
            ? episodeNum.substring(0, episodeNum.length - 2)
            : episodeNum;

        final localized = node['titles']?['localized'];
        String? title;
        if (localized is Map) {
          title = _cleanString(localized['en']) ??
              _cleanString(localized['en_jp']) ??
              _cleanString(localized['en_us']) ??
              localized.values
                  .map(_cleanString)
                  .firstWhere((e) => e != null, orElse: () => null);
        }
        final descObj = node['description'];
        final description = descObj is Map
            ? _cleanString(descObj['en'])
            : _cleanString(descObj);
        final thumbnail = _cleanString(node['thumbnail']?['original']?['url']);
        final rawLength = (node['length'] as num?)?.toInt();
        final runtime = rawLength != null
            ? (rawLength >= 180 ? rawLength ~/ 60 : rawLength)
            : null;

        result[normalizedNumber] = EpisodeMetadataItem(
          number: normalizedNumber,
          title: title,
          description: description,
          thumbnail: thumbnail,
          runtimeMinutes: runtime,
        );
      }

      return result;
    } catch (_) {
      return const {};
    }
  }

  String? _cleanString(dynamic value) {
    final s = value?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }
}
