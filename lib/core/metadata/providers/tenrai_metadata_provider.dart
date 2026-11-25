import 'dart:convert';
import 'package:anymex/controllers/network/network_manager.dart';
import 'package:anymex/core/metadata/models/episode_metadata.dart';
import 'package:anymex/core/metadata/providers/episode_metadata_provider.dart';

class TenraiMetadataProvider implements EpisodeMetadataProvider {
  static const String _baseUrl = 'https://api.tenrai.org/v1';

  @override
  String get id => 'tenrai';

  @override
  String get name => 'Tenrai';

  @override
  String get description => 'MyAnimeList episode titles, air dates, scores, and filler/recap flags';

  @override
  bool supports(MetadataTargetIds ids) {
    return ids.malId != null;
  }

  @override
  Future<Map<String, EpisodeMetadataItem>> fetchEpisodes(MetadataTargetIds ids) async {
    final malId = ids.malId;
    if (malId == null) return const {};

    final result = <String, EpisodeMetadataItem>{};

    try {
      for (var page = 1; page <= 25; page++) {
        final url = '$_baseUrl/anime/$malId/episodes?page=$page';
        final response = await NetworkManager.instance.compatibleClient
            .get(Uri.parse(url), headers: {'Accept': 'application/json'})
            .timeout(const Duration(seconds: 12));

        if (response.statusCode != 200 || response.body.isEmpty) {
          break;
        }

        final dynamic body = jsonDecode(response.body);
        if (body is! Map<String, dynamic>) break;

        final rows = body['data'];
        if (rows is! List || rows.isEmpty) break;

        for (final row in rows) {
          if (row is! Map || row['mal_id'] == null) continue;

          final rawNumber = row['mal_id'];
          final episodeNum = double.tryParse('$rawNumber')?.toString() ?? '$rawNumber';
          final normalizedNumber = episodeNum.endsWith('.0')
              ? episodeNum.substring(0, episodeNum.length - 2)
              : episodeNum;

          final rawDuration = (row['duration'] as num?)?.toInt();
          final runtimeMinutes = rawDuration != null
              ? (rawDuration >= 180 ? rawDuration ~/ 60 : rawDuration)
              : null;
          final images = row['images'];
          final thumbnail = images is Map && images['jpg'] is Map
              ? _cleanString(images['jpg']['image_url'])
              : null;

          result[normalizedNumber] = EpisodeMetadataItem(
            number: normalizedNumber,
            title: _cleanString(row['title']),
            description: _cleanString(row['synopsis']),
            thumbnail: thumbnail,
            airDate: _cleanString(row['aired']),
            runtimeMinutes: runtimeMinutes,
            rating: (row['score'] as num?)?.toDouble(),
            isFiller: row['filler'] as bool?,
            isRecap: row['recap'] as bool?,
          );
        }

        final pagination = body['pagination'];
        if (pagination is! Map || pagination['has_next_page'] != true) {
          break;
        }
      }
      return result;
    } catch (_) {
      return result;
    }
  }

  String? _cleanString(dynamic value) {
    final s = value?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }
}
