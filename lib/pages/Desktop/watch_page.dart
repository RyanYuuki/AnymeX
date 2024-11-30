import 'package:flutter/material.dart';

class DesktopWatchPage extends StatefulWidget {
  final dynamic episodeSrc;
  final int animeId;
  final String sourceAnimeId;
  final ThemeData provider;
  final dynamic tracks;
  final String animeTitle;
  final String episodeTitle;
  final int currentEpisode;
  final dynamic episodeData;
  final String activeServer;
  final bool isDub;
  final String description;
  final String posterImage;

  const DesktopWatchPage({
    super.key,
    required this.episodeSrc,
    required this.tracks,
    required this.provider,
    required this.animeTitle,
    required this.currentEpisode,
    required this.episodeTitle,
    required this.activeServer,
    required this.isDub,
    this.episodeData,
    required this.animeId,
    required this.sourceAnimeId,
    required this.description,
    required this.posterImage,
  });

  @override
  State<DesktopWatchPage> createState() => _DesktopWatchPageState();
}

class _DesktopWatchPageState extends State<DesktopWatchPage> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
