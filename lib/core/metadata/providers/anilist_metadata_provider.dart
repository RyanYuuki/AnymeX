import 'dart:convert';
import 'package:anymex/controllers/network/network_manager.dart';
import 'package:anymex/core/metadata/models/episode_metadata.dart';
import 'package:anymex/core/metadata/providers/episode_metadata_provider.dart';

class AniListMetadataProvider implements EpisodeMetadataProvider {
  static final RegExp _titleRegex = RegExp(
    r'^\s*(?:Episode|Ep\.?)\s*(\d+(?:\.\d+)?)\s*[-–:]?\s*(.*)$',
    caseSensitive: false,
  );

  @override
  String get id => 'anilist';

  @override
  String get name => 'AniList';

  @override
  String get description => 'Streaming episode titles, thumbnails, and airing schedules directly from AniList';

  @override
  bool supports(MetadataTargetIds ids) {
    return ids.anilistId != null;
  }

  @override
  Future<Map<String, EpisodeMetadataItem>> fetchEpisodes(MetadataTargetIds ids) async {
    final anilistId = int.tryParse(ids.anilistId ?? '');
    if (anilistId == null) return const {};

    const query = '''
query (\$id: Int) {
  Media(id: \$id, type: ANIME) {
    streamingEpisodes {
      title
      thumbnail
    }
    airingSchedule(perPage: 150) {
      nodes {
        episode
        airingAt
      }
    }
  }
}
''';

    try {
      final response = await NetworkManager.instance.compatibleClient.post(
        Uri.parse('https://graphql.anilist.co'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'query': query,
          'variables': {'id': anilistId},
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200 || response.body.isEmpty) {
        return const {};
      }

      final dynamic data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) return const {};

      final media = data['data']?['Media'];
      if (media is! Map) return const {};

      final result = <String, EpisodeMetadataItem>{};

      final streamingEpisodes = media['streamingEpisodes'];
      if (streamingEpisodes is List) {
        for (final ep in streamingEpisodes) {
          if (ep is! Map) continue;
          final rawTitle = ep['title']?.toString() ?? '';
          final match = _titleRegex.firstMatch(rawTitle);
          if (match == null) continue;

          final epNumStr = match.group(1);
          if (epNumStr == null) continue;

          final episodeNum = double.tryParse(epNumStr)?.toString() ?? epNumStr;
          final normalizedNumber = episodeNum.endsWith('.0')
              ? episodeNum.substring(0, episodeNum.length - 2)
              : episodeNum;

          final epTitle = _cleanString(match.group(2));
          final epThumb = _cleanString(ep['thumbnail']);

          result[normalizedNumber] = EpisodeMetadataItem(
            number: normalizedNumber,
            title: epTitle,
            thumbnail: epThumb,
          );
        }
      }

      final airingNodes = media['airingSchedule']?['nodes'];
      if (airingNodes is List) {
        for (final node in airingNodes) {
          if (node is! Map || node['episode'] == null) continue;
          final rawNum = node['episode'];
          final episodeNum = double.tryParse('$rawNum')?.toString() ?? '$rawNum';
          final normalizedNumber = episodeNum.endsWith('.0')
              ? episodeNum.substring(0, episodeNum.length - 2)
              : episodeNum;

          final airingAt = (node['airingAt'] as num?)?.toInt();
          String? airDate;
          if (airingAt != null) {
            airDate = DateTime.fromMillisecondsSinceEpoch(airingAt * 1000, isUtc: true).toIso8601String();
          }

          if (result.containsKey(normalizedNumber)) {
            final existing = result[normalizedNumber]!;
            result[normalizedNumber] = EpisodeMetadataItem(
              number: existing.number,
              title: existing.title,
              description: existing.description,
              thumbnail: existing.thumbnail,
              airDate: airDate ?? existing.airDate,
              runtimeMinutes: existing.runtimeMinutes,
              rating: existing.rating,
              isFiller: existing.isFiller,
              isRecap: existing.isRecap,
            );
          } else if (airDate != null) {
            result[normalizedNumber] = EpisodeMetadataItem(
              number: normalizedNumber,
              airDate: airDate,
            );
          }
        }
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
