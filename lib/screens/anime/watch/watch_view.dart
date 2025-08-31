import 'package:anymex/models/Media/media.dart' as anymex;
import 'package:anymex/models/Offline/Hive/episode.dart';
import 'package:anymex/models/Offline/Hive/video.dart' as model;
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/screens/anime/watch/controls/bottom_controls.dart';
import 'package:anymex/screens/anime/watch/controls/center_controls.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/double_tap_seek.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/overlay.dart';
import 'package:anymex/screens/anime/watch/controls/top_controls.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/episodes_pane.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/subtitle_text.dart';
import 'package:anymex/screens/anime/watch/subtitles/subtitle_view.dart';
import 'package:anymex/screens/anime/widgets/media_indicator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_kit_video/media_kit_video.dart';

class WatchScreen extends StatefulWidget {
  final model.Video episodeSrc;
  final Episode currentEpisode;
  final List<Episode> episodeList;
  final anymex.Media anilistData;
  final List<model.Video> episodeTracks;
  const WatchScreen(
      {super.key,
      required this.episodeSrc,
      required this.currentEpisode,
      required this.episodeList,
      required this.anilistData,
      required this.episodeTracks});

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
        widget.episodeTracks));
  }

  @override
  void dispose() {
    controller.delete();
    Get.delete<PlayerController>(force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: MouseRegion(
      onHover: (e) => controller.toggleControls(val: true),
      child: GestureDetector(
        onTap: () => controller.toggleControls(),
        onVerticalDragStart: (details) =>
            controller.onVerticalDragStart(context, details),
        onVerticalDragEnd: (details) =>
            controller.onVerticalDragEnd(context, details),
        onVerticalDragUpdate: (e) =>
            controller.onVerticalDragUpdate(context, e),
        child: Stack(
          children: [
            Obx(() {
              return Video(
                  controller: controller.playerController,
                  fit: controller.videoFit.value,
                  filterQuality: FilterQuality.none,
                  subtitleViewConfiguration:
                      const SubtitleViewConfiguration(visible: false),
                  controls: (state) => const SizedBox.shrink());
            }),
            PlayerOverlay(controller: controller),
            DoubleTapSeekWidget(
              controller: controller,
            ),
            const Align(
              alignment: Alignment.topCenter,
              child: TopControls(),
            ),
            const Align(
              alignment: Alignment.bottomCenter,
              child: BottomControls(),
            ),
            const Align(
              alignment: Alignment.center,
              child: CenterControls(),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              left: 0,
              child: SubtitleSearchBottomSheet(controller: controller),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              left: 0,
              child: EpisodesPane(controller: controller),
            ),
            MediaIndicatorBuilder(
              isVolumeIndicator: false,
              controller: controller,
            ),
            MediaIndicatorBuilder(
              isVolumeIndicator: true,
              controller: controller,
            ),
            SubtitleText(controller: controller),
          ],
        ),
      ),
    ));
  }
}
