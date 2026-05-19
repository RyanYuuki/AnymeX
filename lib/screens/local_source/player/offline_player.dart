import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/database/isar_models/episode.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/screens/anime/watch/controls/themes/setup/themed_controls.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/double_tap_seek.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/episodes_pane.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/overlay.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/source_popup.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/subtitle_text.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/sync_subs_popup.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/tracks_popup.dart';
import 'package:anymex/screens/anime/widgets/media_indicator.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:anymex/screens/downloads/model/download_models.dart';
import 'package:anymex/database/isar_models/track.dart' as hive;

class LocalEpisode {
  final String folderName;
  final String name;
  final String path;

  LocalEpisode({
    required this.folderName,
    required this.name,
    required this.path,
  });
}

class OfflineWatchPage extends StatefulWidget {
  final LocalEpisode episode;
  final List<LocalEpisode> episodeList;
  const OfflineWatchPage({
    super.key,
    required this.episode,
    required this.episodeList,
  });

  @override
  State<OfflineWatchPage> createState() => _OfflineWatchPageState();
}

class _OfflineWatchPageState extends State<OfflineWatchPage> {
  late PlayerController controller;

  @override
  initState() {
    super.initState();
    final episodes = widget.episodeList
        .asMap()
        .entries
        .map((e) => Episode(
              number: (e.key + 1).toString(),
              title: e.value.name,
              link: e.value.path,
            ))
        .toList();

    final currentIndex = widget.episodeList
        .indexWhere((e) => e.path == widget.episode.path);
    final currentEpisodeNumber =
        currentIndex >= 0 ? (currentIndex + 1).toString() : '1';

    List<hive.Track>? offlineSubtitles;
    try {
      final parentDir = File(widget.episode.path).parent;
      final metaFile = File(p.join(parentDir.path, 'metadata.json'));
      if (metaFile.existsSync()) {
        final raw = jsonDecode(metaFile.readAsStringSync()) as Map<String, dynamic>;
        final meta = DownloadedMediaMeta.fromJson(raw);
        final epMeta = meta.episodes.firstWhereOrNull((e) => 
            e.filePath == widget.episode.path || 
            e.fileName == p.basename(widget.episode.path));
        offlineSubtitles = epMeta?.subtitles;
      }
    } catch (e) {
      debugPrint('Failed to read metadata for subtitles: $e');
    }

    controller = Get.put(PlayerController.offline(
        folderName: widget.episode.folderName,
        itemName: widget.episode.name,
        videoPath: widget.episode.path,
        subtitles: offlineSubtitles,
        episode: Episode(
          number: currentEpisodeNumber,
          title: widget.episode.name,
          link: widget.episode.path,
        ),
        episodeList: episodes,
        anilistData: Media(serviceType: ServicesType.simkl)));
  }

  @override
  void dispose() {
    Get.delete<PlayerController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
      children: [
        Obx(() {
          return controller.videoWidget;
        }),
        PlayerOverlay(controller: controller),
        if (!PlayerKeys.useLibass.get<bool>(false))
          SubtitleText(controller: controller),
        DoubleTapSeekWidget(
          controller: controller,
        ),
        const Align(
          alignment: Alignment.center,
          child: ThemedCenterControls(),
        ),
        const Align(
          alignment: Alignment.topCenter,
          child: ThemedTopControls(),
        ),
        const Align(
          alignment: Alignment.bottomCenter,
          child: ThemedBottomControls(),
        ),
        MediaIndicatorBuilder(
          isVolumeIndicator: false,
          controller: controller,
        ),
        MediaIndicatorBuilder(
          isVolumeIndicator: true,
          controller: controller,
        ),
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          left: 0,
          child: TracksPopup(controller: controller),
        ),
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          left: 0,
          child: EpisodesPane(controller: controller),
        ),
      ],
    ));
  }
}
