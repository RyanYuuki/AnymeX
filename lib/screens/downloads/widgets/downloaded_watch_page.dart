import 'package:anymex/screens/downloads/controller/download_controller.dart';
import 'package:anymex/screens/downloads/model/download_models.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/database/isar_models/episode.dart';
import 'package:anymex/models/Media/media.dart' as anymex;
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/screens/anime/watch/controls/themes/setup/themed_controls.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/double_tap_seek.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/episodes_pane.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/overlay.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/subtitle_text.dart';
import 'package:anymex/screens/anime/widgets/media_indicator.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/source_popup.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/sync_subs_popup.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/tracks_popup.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DownloadedWatchPage extends StatefulWidget {
  final DownloadedEpisodeMeta episode;
  final List<DownloadedEpisodeMeta> allEpisodes;
  final DownloadedMediaMeta meta;
  final DownloadedMediaSummary summary;

  const DownloadedWatchPage({
    super.key,
    required this.episode,
    required this.allEpisodes,
    required this.meta,
    required this.summary,
  });

  @override
  State<DownloadedWatchPage> createState() => _DownloadedWatchPageState();
}

class _DownloadedWatchPageState extends State<DownloadedWatchPage> {
  late PlayerController _controller;
  late DownloadedEpisodeMeta _currentEpMeta;
  final downloadController = Get.find<DownloadController>();

  @override
  void initState() {
    super.initState();
    _currentEpMeta = widget.episode;
    _initPlayer(_currentEpMeta);
  }

  List<Episode> get _episodeList =>
      widget.allEpisodes.map((e) => e.episode).toList();

  void _initPlayer(DownloadedEpisodeMeta epMeta) {
    if (Get.isRegistered<PlayerController>()) {
      Get.delete<PlayerController>(force: true);
    }

    final savedTs = epMeta.episode.timeStampInMilliseconds ?? 0;

    _controller = Get.put(PlayerController.offline(
      folderName: widget.summary.extensionName,
      itemName: widget.summary.folderName,
      videoPath: epMeta.filePath,
      episode: epMeta.episode..timeStampInMilliseconds = savedTs,
      episodeList: _episodeList,
      anilistData: anymex.Media(serviceType: ServicesType.simkl),
    ));
  }

  Future<void> _saveProgress() async {
    final pos = _controller.currentPosition.value.inMilliseconds;
    final dur = _controller.episodeDuration.value.inMilliseconds;
    if (dur <= 0) return;

    await downloadController.updateEpisodeProgress(
      widget.summary.extensionName,
      widget.summary.folderName,
      _currentEpMeta.number,
      _currentEpMeta.sortMap,
      pos,
      dur,
    );
  }

  @override
  void deactivate() {
    _saveProgress();
    super.deactivate();
  }

  @override
  void dispose() {
    Get.delete<PlayerController>(force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Obx(() => _controller.videoWidget),
          PlayerOverlay(controller: _controller),
          if (!PlayerKeys.useLibass.get<bool>(false))
            SubtitleText(controller: _controller),
          DoubleTapSeekWidget(controller: _controller),
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
            controller: _controller,
          ),
          MediaIndicatorBuilder(
            isVolumeIndicator: true,
            controller: _controller,
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            left: 0,
            child: SourcePopup(controller: _controller),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            left: 0,
            child: TracksPopup(controller: _controller),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            left: 0,
            child: SyncSubsPopup(controller: _controller),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            left: 0,
            child: EpisodesPane(controller: _controller),
          ),
        ],
      ),
    );
  }
}
