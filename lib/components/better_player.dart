import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';

class VideoPlayerAlt extends StatefulWidget {
  final String videoUrl;
  final dynamic tracks;
  const VideoPlayerAlt(
      {super.key, required this.videoUrl, required this.tracks});

  @override
  State<VideoPlayerAlt> createState() => _VideoPlayerAltState();
}

class _VideoPlayerAltState extends State<VideoPlayerAlt>
    with AutomaticKeepAliveClientMixin {
  List<BetterPlayerSubtitlesSource>? subtitles;
  late BetterPlayerController _betterPlayerController;
  final BetterPlayerTheme _playerTheme = BetterPlayerTheme.cupertino;

  @override
  void initState() {
    super.initState();

    filterSubtitles(widget.tracks);

    BetterPlayerConfiguration betterPlayerConfiguration =
        BetterPlayerConfiguration(
      aspectRatio: 16 / 9,
      controlsConfiguration: BetterPlayerControlsConfiguration(
        playerTheme: _playerTheme,
      ),
    );

    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _betterPlayerController.setupDataSource(BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      useAsmsSubtitles: true,
      widget.videoUrl,
      subtitles: subtitles,
    ));
  }

  void filterSubtitles(List<dynamic> source) {
    setState(() {
      subtitles = source
          .where((data) => data['kind'] == 'captions')
          .map<BetterPlayerSubtitlesSource>((caption) => BetterPlayerSubtitlesSource(
                type: BetterPlayerSubtitlesSourceType.network,
                name: caption['label'],
                urls: [caption['file']],
              ))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: BetterPlayer(controller: _betterPlayerController),
    );
  }

  @override
  void dispose() {
    _betterPlayerController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}
