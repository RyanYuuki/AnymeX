import 'package:anymex/database/isar_models/episode.dart';
import 'package:anymex/screens/anime/widgets/episode/normal_episode.dart';
import 'package:flutter/material.dart';

Widget buildCompactEpisodeStyle(
  BuildContext context,
  Episode episode,
  bool isSelected,
  bool isWatched,
  double progress,
  String? mediaTitle,
  List<Episode>? offlineEpisodes,
  VoidCallback? onTap,
  VoidCallback? onLongPress,
) {
  return Opacity(
    opacity: isWatched ? 0.5 : 1.0,
    child: BetterEpisode(
      episode: episode,
      isSelected: isSelected,
      layoutType: EpisodeLayoutType.compact,
      mediaTitle: mediaTitle,
      offlineEpisodes: offlineEpisodes,
      onTap: onTap,
      onLongPress: onLongPress,
    ),
  );
}
