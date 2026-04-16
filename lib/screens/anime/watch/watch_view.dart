import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/database/isar_models/episode.dart';
import 'package:anymex/database/isar_models/video.dart' as model;
import 'package:anymex/models/Media/media.dart' as anymex;
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/screens/anime/watch/controls/themes/setup/themed_controls.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/double_tap_seek.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/episodes_pane.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/overlay.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/buffering_overlay.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/subtitle_text.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/tracks_popup.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/source_popup.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/sync_subs_popup.dart';
import 'package:anymex/screens/anime/widgets/media_indicator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WatchScreen extends StatefulWidget {
  final model.Video episodeSrc;
  final Episode currentEpisode;
  final List<Episode> episodeList;
  final anymex.Media anilistData;
  final List<model.Video> episodeTracks;
  final bool shouldTrack;
  const WatchScreen({
    super.key,
    required this.episodeSrc,
    required this.currentEpisode,
    required this.episodeList,
    required this.anilistData,
    required this.episodeTracks,
    this.shouldTrack = true,
  });

  @override
  State<WatchScreen> createState() => _WatchScreenState();
}

class _WatchScreenState extends State<WatchScreen> {
  late PlayerController controller;

  @override
  initState() {
    super.initState();
    controller = Get.put(PlayerController(
        widget.episodeSrc,
        widget.currentEpisode,
        widget.episodeList,
        widget.anilistData,
        widget.episodeTracks,
        shouldTrack: widget.shouldTrack));
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
          controller.playerReloadVersion.value;
          return controller.videoWidget;
        }),
        PlayerOverlay(controller: controller),
        BufferingOverlay(controller: controller),
        Obx(() {
          controller.playerReloadVersion.value;
          if (PlayerKeys.useLibass.get<bool>(false)) {
            return const SizedBox.shrink();
          }
          return SubtitleText(controller: controller);
        }),
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
          child: SourcePopup(controller: controller),
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
          child: SyncSubsPopup(controller: controller),
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
