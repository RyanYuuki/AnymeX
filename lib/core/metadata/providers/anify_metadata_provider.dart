import 'dart:convert';
import 'package:anymex/controllers/network/network_manager.dart';
import 'package:anymex/core/metadata/models/episode_metadata.dart';
import 'package:anymex/core/metadata/providers/episode_metadata_provider.dart';

class AnifyMetadataProvider implements EpisodeMetadataProvider {
  @override
  String get id => 'anify';

  @override
  String get name => 'Anify';

  @override
  String get description => 'Legacy Anify episode titles, descriptions, and thumbnails';

  @override
  bool supports(MetadataTargetIds ids) {
    return ids.anilistId != null;
  }

  @override
  Future<Map<String, EpisodeMetadataItem>> fetchEpisodes(MetadataTargetIds ids) async {
    final anilistId = ids.anilistId;
    if (anilistId == null) return const {};

    try {
      final url = 'https://api.anify.eltik.cc/info/$anilistId?fields=[episodes]';
      final response = await NetworkManager.instance.compatibleClient
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200 || response.body.isEmpty) {
        return const {};
      }

      final dynamic data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) return const {};

      final episodesData = data['episodes'];
      if (episodesData is! Map || episodesData['data'] is! List) return const {};

      final result = <String, EpisodeMetadataItem>{};
      final episodeList = episodesData['data'] as List;

      for (final ep in episodeList) {
        if (ep is! Map) continue;
        final rawNumber = ep['number'];
        if (rawNumber == null) continue;

        final episodeNum = double.tryParse('$rawNumber')?.toString() ?? '$rawNumber';
        final normalizedNumber = episodeNum.endsWith('.0')
            ? episodeNum.substring(0, episodeNum.length - 2)
            : episodeNum;

        result[normalizedNumber] = EpisodeMetadataItem(
          number: normalizedNumber,
          title: _cleanString(ep['title']),
          description: _cleanString(ep['description']),
          thumbnail: _cleanString(ep['image']),
          rating: (ep['rating'] as num?)?.toDouble(),
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
