import 'dart:convert';
import 'package:anymex/controllers/network/network_manager.dart';
import 'package:anymex/core/metadata/models/episode_metadata.dart';
import 'package:anymex/core/metadata/providers/episode_metadata_provider.dart';

class SimklMetadataProvider implements EpisodeMetadataProvider {
  static const String clientId =
      '8619718cebfec7ce9a405b856bbd4a7508ec29168072402dfd8ca3a65c56df3f';

  @override
  String get id => 'simkl';

  @override
  String get name => 'Simkl';

  @override
  String get description =>
      'Episode metadata, descriptions, air dates, and thumbnails via Simkl API';

  @override
  bool supports(MetadataTargetIds ids) {
    return ids.simklId != null || ids.malId != null || ids.anilistId != null;
  }

  @override
  Future<Map<String, EpisodeMetadataItem>> fetchEpisodes(
      MetadataTargetIds ids) async {
    String? simklId = ids.simklId;

    if (simklId == null && (ids.malId != null || ids.anilistId != null)) {
      simklId = await _lookupSimklId(ids);
      if (simklId != null) {
        ids.simklId = simklId;
      }
    }

    if (simklId == null) return const {};

    try {
      final url =
          'https://api.simkl.com/anime/episodes/$simklId?extended=full&client_id=$clientId';
      final response = await NetworkManager.instance.compatibleClient
          .get(Uri.parse(url), headers: {'Accept': 'application/json'}).timeout(
              const Duration(seconds: 15));

      if (response.statusCode != 200 || response.body.isEmpty) {
        return const {};
      }

      final dynamic data = jsonDecode(response.body);
      if (data is! List) return const {};

      final result = <String, EpisodeMetadataItem>{};
      for (final ep in data) {
        if (ep is! Map || ep['episode'] == null) continue;
        if (ep['type'] != null && ep['type'] != 'episode') continue;

        final rawNumber = ep['episode'];
        final episodeNum =
            double.tryParse('$rawNumber')?.toString() ?? '$rawNumber';
        final normalizedNumber = episodeNum.endsWith('.0')
            ? episodeNum.substring(0, episodeNum.length - 2)
            : episodeNum;

        final image = _cleanString(ep['img']);
        final thumbnail = image != null
            ? 'https://wsrv.nl/?url=https://simkl.in/episodes/${image}_c.webp'
            : null;

        final airDate = _cleanString(ep['date']) ?? _cleanString(ep['aired']);

        result[normalizedNumber] = EpisodeMetadataItem(
          number: normalizedNumber,
          title: _cleanString(ep['title']),
          description: _cleanString(ep['description']),
          thumbnail: thumbnail,
          airDate: airDate,
          runtimeMinutes: (ep['runtime'] as num?)?.toInt(),
        );
      }

      return result;
    } catch (_) {
      return const {};
    }
  }

  Future<String?> _lookupSimklId(MetadataTargetIds ids) async {
    try {
      final param =
          ids.malId != null ? 'mal=${ids.malId}' : 'anilist=${ids.anilistId}';
      final url = 'https://api.simkl.com/search/id?$param&client_id=$clientId';
      final response = await NetworkManager.instance.compatibleClient
          .get(Uri.parse(url), headers: {'Accept': 'application/json'}).timeout(
              const Duration(seconds: 10));

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final dynamic data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty && data[0] is Map) {
          final idsMap = data[0]['ids'];
          if (idsMap is Map) {
            final foundId = idsMap['simkl']?.toString();
            return (foundId != null && foundId.isNotEmpty) ? foundId : null;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  String? _cleanString(dynamic value) {
    final s = value?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }
}
