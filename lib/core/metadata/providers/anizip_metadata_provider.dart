import 'dart:convert';
import 'package:anymex/controllers/network/network_manager.dart';
import 'package:anymex/core/metadata/models/episode_metadata.dart';
import 'package:anymex/core/metadata/providers/episode_metadata_provider.dart';

class AniZipMetadataProvider implements EpisodeMetadataProvider {
  @override
  String get id => 'anizip';

  @override
  String get name => 'ani.zip';

  @override
  String get description => 'Rich episode titles, overviews, thumbnails, and mappings from ani.zip';

  @override
  bool supports(MetadataTargetIds ids) {
    return ids.anilistId != null || ids.malId != null;
  }

  @override
  Future<Map<String, EpisodeMetadataItem>> fetchEpisodes(MetadataTargetIds ids) async {
    final queryParam = ids.anilistId != null
        ? 'anilist_id=${ids.anilistId}'
        : 'mal_id=${ids.malId}';
    final url = 'https://api.ani.zip/mappings?$queryParam';

    try {
      final response = await NetworkManager.instance.compatibleClient
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200 || response.body.isEmpty) {
        return const {};
      }

      final dynamic data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) return const {};

      if (data['mappings'] is Map) {
        final mappings = data['mappings'] as Map;
        ids.kitsuId ??= mappings['kitsu_id']?.toString();
        ids.simklId ??= mappings['simkl_id']?.toString();
        ids.malId ??= mappings['mal_id']?.toString();
        ids.anilistId ??= mappings['anilist_id']?.toString();
      }

      final episodes = data['episodes'];
      if (episodes is! Map) return const {};

      final result = <String, EpisodeMetadataItem>{};
      for (final entry in episodes.entries) {
        final ep = entry.value;
        if (ep is! Map) continue;

        final rawNumber = ep['episode'] ?? entry.key;
        final episodeNum = double.tryParse('$rawNumber')?.toString() ?? '$rawNumber';
        final normalizedNumber = episodeNum.endsWith('.0')
            ? episodeNum.substring(0, episodeNum.length - 2)
            : episodeNum;

        final titles = ep['title'];
        String? title;
        if (titles is Map) {
          title = _cleanString(titles['en']) ??
              _cleanString(titles['x-jat']) ??
              _cleanString(titles['ja']);
        } else if (titles is String) {
          title = _cleanString(titles);
        }

        final description = _cleanString(ep['summary']) ?? _cleanString(ep['overview']);
        final thumbnail = _cleanString(ep['image']);
        final airDate = _cleanString(ep['airDateUtc']) ?? _cleanString(ep['airdate'] ?? ep['airDate']);
        final runtime = (ep['runtime'] as num?)?.toInt() ?? (ep['length'] as num?)?.toInt();
        final rating = double.tryParse('${ep['rating'] ?? ''}');

        result[normalizedNumber] = EpisodeMetadataItem(
          number: normalizedNumber,
          title: title,
          description: description,
          thumbnail: thumbnail,
          airDate: airDate,
          runtimeMinutes: runtime,
          rating: rating,
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
