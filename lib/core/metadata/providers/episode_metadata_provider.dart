import 'package:anymex/core/metadata/models/episode_metadata.dart';

abstract class EpisodeMetadataProvider {
  String get id;
  String get name;
  String get description;

  bool supports(MetadataTargetIds ids);

  Future<Map<String, EpisodeMetadataItem>> fetchEpisodes(MetadataTargetIds ids);
}
