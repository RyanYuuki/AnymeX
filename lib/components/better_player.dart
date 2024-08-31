import 'package:flutter/material.dart';
import 'package:better_player/better_player.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class VideoPlayerAlt extends StatefulWidget {
  final String videoUrl;
  final ThemeData provider;
  final dynamic tracks;
  const VideoPlayerAlt(
      {super.key, required this.videoUrl, required this.tracks, required this.provider});

  @override
  State<VideoPlayerAlt> createState() => _VideoPlayerAltState();
}

class _VideoPlayerAltState extends State<VideoPlayerAlt>
    with AutomaticKeepAliveClientMixin {
  List<BetterPlayerSubtitlesSource>? subtitles;
  BetterPlayerController? _betterPlayerController;

  @override
  void initState() {
    super.initState();
    initializePlayer();
  }

  @override
  void didUpdateWidget(covariant VideoPlayerAlt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.videoUrl != oldWidget.videoUrl) {
      _betterPlayerController?.dispose();
      initializePlayer();
    }
  }

  void initializePlayer() {
    filterSubtitles(widget.tracks);
    BetterPlayerConfiguration betterPlayerConfiguration =
        BetterPlayerConfiguration(
      autoDetectFullscreenAspectRatio: true,
      autoDetectFullscreenDeviceOrientation: true,
      deviceOrientationsOnFullScreen: const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight
      ],
      fit: BoxFit.contain,
      aspectRatio: 16 / 9,
      controlsConfiguration: BetterPlayerControlsConfiguration(
        playerTheme: BetterPlayerTheme.cupertino,
        playIcon: Iconsax.play,
        skipBackIcon: Iconsax.backward_10_seconds,
        skipForwardIcon: Iconsax.forward_10_seconds,
        pauseIcon: Iconsax.pause,
        controlBarColor: widget.provider.colorScheme.surfaceContainerHighest,
        progressBarHandleColor: widget.provider.colorScheme.onPrimaryFixed,
        progressBarPlayedColor: widget.provider.colorScheme.onPrimaryFixedVariant,
      ),
      autoPlay: true,
      looping: false,
      subtitlesConfiguration: const BetterPlayerSubtitlesConfiguration(
        fontSize: 20,
        fontFamily: 'Poppins-Bold',
        outlineEnabled: true,
        outlineSize: 3,
        outlineColor: Colors.black,
      ),
    );

    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _betterPlayerController!.setupDataSource(BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      widget.videoUrl,
      subtitles: subtitles,
    ));

    WakelockPlus.enable();
  }

  void filterSubtitles(List<dynamic> source) {
    setState(() {
      subtitles = source
          .where((data) => data['kind'] == 'captions')
          .map<BetterPlayerSubtitlesSource>(
            (caption) => BetterPlayerSubtitlesSource(
              selectedByDefault: caption['label'] == 'English',
              type: BetterPlayerSubtitlesSourceType.network,
              name: caption['label'],
              urls: [caption['file']],
            ),
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); 
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: BetterPlayer(controller: _betterPlayerController!),
    );
  }

  @override
  void dispose() {
    _betterPlayerController?.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}
