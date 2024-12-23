import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:math' show max;
import 'package:anymex/api/Mangayomi/Eval/dart/model/m_chapter.dart';
import 'package:anymex/api/Mangayomi/Eval/dart/model/video.dart' as v;
import 'package:anymex/api/Mangayomi/Model/Source.dart';
import 'package:anymex/api/Mangayomi/Search/getVideo.dart';
import 'package:anymex/components/android/videoPlayer/custom_controls.dart';
import 'package:anymex/auth/auth_provider.dart';
import 'package:anymex/models/server.dart';
import 'package:anymex/pages/Anime/widgets/indicator.dart';
import 'package:flutter/material.dart';
import 'package:better_player/better_player.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:media_kit/media_kit.dart' hide Track;
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:window_manager/window_manager.dart';

class WatchPage extends StatefulWidget {
  final v.Video? episodeSrc;
  final List<v.Video>? streams;
  final List<v.Track> tracks;
  final int animeId;
  final String animeTitle;
  final int currentEpisode;
  final dynamic episodeData;
  final Server activeServer;
  final String description;
  final String posterImage;
  final Source activeSource;

  const WatchPage({
    super.key,
    required this.episodeSrc,
    required this.tracks,
    required this.animeTitle,
    required this.currentEpisode,
    required this.activeServer,
    this.episodeData,
    required this.animeId,
    required this.description,
    required this.posterImage,
    required this.activeSource,
    required this.streams,
  });

  @override
  State<WatchPage> createState() => _WatchPageState();
}

class _WatchPageState extends State<WatchPage> with TickerProviderStateMixin {
  bool showControls = true;
  bool showSubs = true;
  List<BetterPlayerSubtitlesSource>? subtitles;
  int selectedQuality = 0;
  bool isLandScapeRight = false;
  bool isControlsLocked = false;
  v.Video? episodeSrc;
  List<v.Video>? streams;
  List<v.Track>? tracks;
  String? episodeTitle;
  int? currentEpisode;
  final List<BoxFit> resizeModes = [BoxFit.contain, BoxFit.fill, BoxFit.cover];
  final Map<String, BoxFit> resizeModesOptions = {
    'Cover': BoxFit.contain,
    'Zoom': BoxFit.fill,
    'Stretch': BoxFit.cover,
  };
  final Map<String, Color> colorOptions = {
    'Default': Colors.transparent,
    'White': Colors.white,
    'Black': Colors.black,
    'Red': Colors.red,
    'Green': Colors.green,
    'Blue': Colors.blue,
    'Yellow': Colors.yellow,
    'Cyan': Colors.cyan,
  };

  // Video Player
  late Player player;
  VideoController? videoPlayerController;
  final FocusNode _focusNode = FocusNode();
  // Video Player Settings
  late String resizeMode;
  late double playbackSpeed;
  late String subtitleColor;
  late String subtitleOutlineColor;
  late String subtitleBackgroundColor;
  late String subtitleFont;
  late double subtitleSize;
  late AnimationController _leftAnimationController;
  late AnimationController _rightAnimationController;
  int? skipDuration;

  int index = 0;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _initPlayerSettings();
    _leftAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _rightAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _initVars();
    initializePlayer();
    _handleVolumeAndBrightness();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);

    Provider.of<AniListProvider>(context, listen: false).updateAnimeProgress(
      animeId: widget.animeId,
      episodeProgress: widget.currentEpisode,
      status: 'CURRENT',
    );
  }

  void _handleKeyPress(KeyEvent event) {
    if (event is KeyDownEvent) {
      final screenWidth = MediaQuery.of(context).size.width;

      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        setState(() {
          _doubleTapPosition = Offset(screenWidth * 0.25, 0);
          _isLeftSide = true;
        });
        _handleDoubleTap(true);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        setState(() {
          _doubleTapPosition = Offset(screenWidth * 0.75, 0);
          _isLeftSide = false;
        });
        _handleDoubleTap(false);
      } else if (event.logicalKey == LogicalKeyboardKey.space) {
        player.playOrPause();
      }
    }
  }

  @override
  void dispose() {
    player.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _leftAnimationController.dispose();
    _rightAnimationController.dispose();
    _doubleTapTimeout?.cancel();
    windowManager.setFullScreen(false);
    _focusNode.dispose();
    super.dispose();
  }

  void _initPlayerSettings() {
    var box = Hive.box('app-data');
    resizeMode = box.get('resizeMode', defaultValue: 'Cover');
    playbackSpeed = box.get('playbackSpeed', defaultValue: 1.0);
    subtitleColor = box.get('subtitleColor', defaultValue: 'White');
    subtitleBackgroundColor =
        box.get('subtitleBackgroundColor', defaultValue: 'Default');
    subtitleOutlineColor =
        box.get('subtitleOutlineColor', defaultValue: 'Black');
    subtitleFont = box.get('subtitleFont', defaultValue: 'Poppins');
    subtitleSize = box.get('subtitleSize', defaultValue: 16.0);
  }

  void _initVars() {
    episodeSrc = widget.episodeSrc;
    tracks = widget.tracks;
    episodeTitle = widget.animeTitle;
    currentEpisode = widget.currentEpisode;
    streams = widget.streams;
    skipDuration = Hive.box('app-data').get('skipDuration', defaultValue: 10);
  }

  void initializePlayer() {
    player = Player();
    videoPlayerController = VideoController(player);
    player.open(Media(episodeSrc!.url));
    player.play();
  }

  Future<void> fetchSrcHelper(String episodeId) async {
    setState(() {
      episodeSrc == null;
      player.open(Media(''));
    });
    try {
      final response =
          await getVideo(url: episodeId, source: widget.activeSource);

      if (mounted) {
        setState(() {
          tracks = response[0].subtitles;
          episodeSrc = response.first;
          streams = response;
        });
        // final isOOB = currentEpisode! == widget.episodeData.length;
        // if (widget.sourceAnimeId != 'rescue') {
        //   Provider.of<AppData>(context, listen: false).addWatchedAnime(
        //       anilistAnimeId: widget.animeId.toString(),
        //       animeId: widget.sourceAnimeId,
        //       animeTitle: widget.animeTitle,
        //       currentEpisode:
        //           (isOOB ? currentEpisode : currentEpisode! + 1).toString(),
        //       animePosterImageUrl: widget.posterImage,
        //       episodeList: widget.episodeData,
        //       currentSource: "",
        //       animeDescription: widget.description);
        // }
        player.open(Media(episodeSrc!.url));
      }
    } catch (e) {
      log('Error fetching episode sources: $e');
    }
  }

  Row topControls() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Padding(
            padding: EdgeInsets.only(top: 5.0),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                alignment: Alignment.topLeft,
                child: Text(
                  "Episode $currentEpisode: $episodeTitle",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                alignment: Alignment.topLeft,
                child: Text(
                  widget.animeTitle,
                  style: const TextStyle(
                    color: Color.fromARGB(255, 190, 190, 190),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    overflow: TextOverflow.ellipsis,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            episodesDialog();
          },
          icon: const Icon(
            Icons.video_collection,
            color: Colors.white,
          ),
        ),
        IconButton(
          onPressed: () {
            setState(() {
              isControlsLocked = !isControlsLocked;
            });
          },
          icon: Icon(
            isControlsLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  bool isFullScreen = false;
  Row bottomControls() {
    final isMobile = Platform.isAndroid || Platform.isIOS;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () {
                qualityDialog();
              },
              icon: const Icon(
                Icons.high_quality_rounded,
                color: Colors.white,
              ),
            ),
            if (widget.tracks != null)
              IconButton(
                onPressed: () {
                  subtitleDialog();
                },
                icon: const Icon(
                  Iconsax.subtitle5,
                  color: Colors.white,
                ),
              ),
          ],
        ),
        Row(
          children: [
            if (isMobile)
              IconButton(
                onPressed: () {
                  setState(() {
                    isLandScapeRight = !isLandScapeRight;
                    if (isLandScapeRight) {
                      SystemChrome.setPreferredOrientations(
                          [DeviceOrientation.landscapeRight]);
                    } else {
                      SystemChrome.setPreferredOrientations(
                          [DeviceOrientation.landscapeLeft]);
                    }
                  });
                },
                icon: const Icon(
                  Icons.screen_rotation_rounded,
                  color: Colors.white,
                ),
              ),
            IconButton(
              onPressed: () {
                showPlaybackSpeedDialog(context);
              },
              icon: const Icon(
                Icons.speed_rounded,
                color: Colors.white,
              ),
            ),
            if (isMobile)
              IconButton(
                onPressed: () {
                  changeResizeMode();
                },
                icon: const Icon(
                  Icons.fullscreen_rounded,
                  color: Colors.white,
                ),
              ),
            if (!Platform.isAndroid && !Platform.isIOS)
              IconButton(
                icon: Icon(isFullScreen
                    ? Icons.fullscreen_exit_rounded
                    : Icons.fullscreen),
                onPressed: () {
                  setState(() {
                    isFullScreen = !isFullScreen;
                    windowManager.setFullScreen(isFullScreen);
                  });
                },
              )
          ],
        ),
      ],
    );
  }

  void changeResizeMode() {
    setState(() {
      switch (resizeMode) {
        case 'Cover':
          resizeMode = 'Zoom';
          break;
        case 'Zoom':
          resizeMode = 'Stretch';
          break;
        case 'Stretch':
          resizeMode = 'Cover';
          break;
      }
    });
  }

  void showPlaybackSpeedDialog(BuildContext context) async {
    Player? playerController = player;
    double currentSpeed = player.state.rate ?? 1.0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Playback Speed'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSpeedOption(context, playerController, 0.5, currentSpeed),
                _buildSpeedOption(
                    context, playerController, 0.75, currentSpeed),
                _buildSpeedOption(context, playerController, 1.0, currentSpeed),
                _buildSpeedOption(
                    context, playerController, 1.25, currentSpeed),
                _buildSpeedOption(context, playerController, 1.5, currentSpeed),
                _buildSpeedOption(context, playerController, 2.0, currentSpeed),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSpeedOption(BuildContext context, Player playerController,
      double speed, double currentSpeed) {
    return RadioListTile<double>(
      value: speed,
      groupValue: currentSpeed,
      onChanged: (value) {
        if (value != null) {
          player.setRate(value);
          Navigator.of(context).pop();
        }
      },
      title: Text('${speed}x'),
    );
  }

  void episodesDialog() {
    ScrollController scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (currentEpisode != null &&
          currentEpisode! > 0 &&
          widget.episodeData.isNotEmpty) {
        final episodeIndex = widget.episodeData.indexWhere((MChapter episode) =>
            int.parse(episode.name!.split("Episode ").last) == currentEpisode);
        if (episodeIndex != -1) {
          double positionToScroll = (episodeIndex) * 77.0;
          scrollController.jumpTo(positionToScroll);
        }
      }
    });
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Episodes",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: widget.episodeData.length,
                  itemBuilder: (context, index) {
                    MChapter episode = widget.episodeData[index];
                    final isSelected =
                        int.parse(episode.name!.split("Episode ").last) ==
                            currentEpisode;
                    return Container(
                      height: 65,
                      margin: const EdgeInsets.only(bottom: 12.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                          minimumSize: const Size(double.infinity, 0),
                        ),
                        onPressed: () async {
                          setState(() {
                            episodeTitle = episode.name!;
                            currentEpisode =
                                int.parse(episode.name!.split("Episode ").last);
                          });
                          Navigator.pop(context);
                          await fetchSrcHelper(episode.url!);
                        },
                        child: Text(
                          episode.name!,
                          style: TextStyle(
                            fontSize: 16,
                            color: isSelected ? Colors.black : Colors.white,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Duration? lastDuration;
  Duration? end;

  qualityDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        player.stream.position.listen((dur) {
          lastDuration = dur;
        });
        player.stream.duration.listen((dur) {
          end = dur;
        });
        return Container(
          width: 400,
          height: 300,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: ListView(
            children: [
              const Center(
                child: Text(
                  "Select Video Quality",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: streams?.length,
                itemBuilder: (context, index) {
                  final v.Video track = streams![index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: selectedQuality == index
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                        minimumSize: const Size(double.infinity, 0),
                      ),
                      onPressed: () {
                        selectedQuality = index;
                        player.stream.position.listen((dur) {
                          lastDuration = dur;
                        });
                        player.stream.duration.listen((dur) {
                          end = dur;
                        });
                        player.open(
                            Media(track.url, start: lastDuration, end: end));
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        track.quality,
                        style: TextStyle(
                            fontSize: 16,
                            color: selectedQuality == index
                                ? Colors.black
                                : Colors.white),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  int selectedSub = 0;

  int? returnSubsLength() {
    return tracks?.length ?? 0;
  }

  subtitleDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          width: 400,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Subtitles",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 220,
                child: ListView.builder(
                  itemCount: returnSubsLength()! + 1,
                  itemBuilder: (context, index) {
                    if (index == returnSubsLength()) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: selectedSub == index
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                            minimumSize: const Size(double.infinity, 0),
                          ),
                          onPressed: () {
                            setState(() {
                              selectedSub = index;
                              player.setSubtitleTrack(SubtitleTrack.no());
                            });
                            Navigator.pop(context);
                          },
                          child: Text(
                            'None',
                            style: TextStyle(
                              fontSize: 16,
                              color: selectedSub == index
                                  ? Colors.black
                                  : Colors.white,
                            ),
                          ),
                        ),
                      );
                    }

                    final track = tracks![index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: selectedSub == index
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                          minimumSize: const Size(double.infinity, 0),
                        ),
                        onPressed: () {
                          setState(() {
                            selectedSub = index;
                            player.setSubtitleTrack(
                                SubtitleTrack.uri(track.file!));
                          });
                          Navigator.pop(context);
                        },
                        child: Text(
                          track.label!,
                          style: TextStyle(
                            fontSize: 16,
                            color: selectedSub == index
                                ? Colors.black
                                : Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  AnimatedOpacity overlay() {
    return AnimatedOpacity(
      opacity: !showControls ? 0.0 : 0.7,
      duration: const Duration(milliseconds: 300),
      child: Container(
        color: Colors.black,
        alignment: Alignment.center,
      ),
    );
  }

  Map<String, bool> getEpisodeMap() {
    final episodeMap = {'prev': false, 'next': false};

    if (currentEpisode != null && currentEpisode! > 1) {
      if (widget.episodeData[currentEpisode! - 2] != null) {
        episodeMap['prev'] = true;
      }
    }

    if (currentEpisode != null && currentEpisode! < widget.episodeData.length) {
      if (widget.episodeData[currentEpisode!] != null) {
        episodeMap['next'] = true;
      }
    }

    return episodeMap;
  }

  Future<void> navEpisodes(String direction) async {
    if (direction == 'prev') {
      currentEpisode = currentEpisode! - 1;
    } else {
      currentEpisode = currentEpisode! + 1;
    }
    MChapter episode = widget.episodeData[currentEpisode! - 1];
    setState(() {
      episodeTitle = episode.name;
      currentEpisode = int.parse(episode.name!.split("Episode ").last);
    });
    await fetchSrcHelper(episode.url!);
  }

  var _volumeInterceptEventStream = false;
  double _volumeValue = 0.0;
  double _brightnessValue = 0.0;

  void _handleVolumeAndBrightness() {
    Future.microtask(() async {
      try {
        VolumeController().showSystemUI = false;
        _volumeValue = await VolumeController().getVolume();
        VolumeController().listener((value) {
          if (mounted && !_volumeInterceptEventStream) {
            _volumeValue = value;
          }
        });
      } catch (_) {}
    });
    Future.microtask(() async {
      try {
        _brightnessValue = await ScreenBrightness().current;
        ScreenBrightness().onCurrentBrightnessChanged.listen((value) {
          if (mounted) {
            _brightnessValue = value;
          }
        });
      } catch (_) {}
    });
  }

  bool _volumeIndicator = false;
  bool _brightnessIndicator = false;
  Timer? _volumeTimer;
  Timer? _brightnessTimer;

  Future<void> setVolume(double value) async {
    try {
      VolumeController().setVolume(value);
    } catch (_) {}
    setState(() {
      _volumeValue = value;
      _volumeIndicator = true;
      _volumeInterceptEventStream = true;
      _volumeTimer?.cancel();
      _volumeTimer = Timer(const Duration(milliseconds: 200), () {
        if (mounted) {
          _volumeIndicator = false;
          _volumeInterceptEventStream = false;
        }
      });
    });
  }

  Future<void> setBrightness(double value) async {
    try {
      await ScreenBrightness().setScreenBrightness(value);
    } catch (_) {}
    setState(() {
      _brightnessIndicator = true;
      _brightnessTimer?.cancel();
      _brightnessTimer = Timer(const Duration(milliseconds: 200), () {
        if (mounted) {
          _brightnessIndicator = false;
        }
      });
    });
  }

  String _doubleTapLabel = '';
  Timer? _doubleTapTimeout;

  Offset? _doubleTapPosition;
  DateTime? _lastTapTime;
  bool _isLeftSide = false;

  void _handleTap(TapDownDetails details) {
    final now = DateTime.now();
    final screenWidth = MediaQuery.of(context).size.width;
    final tapPosition = details.globalPosition;
    final isLeft = tapPosition.dx < screenWidth / 2;

    if (_lastTapTime != null &&
        now.difference(_lastTapTime!) < const Duration(milliseconds: 300)) {
      _handleDoubleTap(isLeft);
      _doubleTapPosition = tapPosition;
      _isLeftSide = isLeft;
    } else {
      setState(() {
        showControls = !showControls;
      });
    }

    _lastTapTime = now;
  }

  void _handleDoubleTap(bool isLeft) {
    Duration? currentPosition;
    player.stream.position.listen((dur) {
      currentPosition = dur;
    });

    if (currentPosition == null) return;

    setState(() {
      isControlsLocked = true;
      _doubleTapLabel = isLeft ? '-${skipDuration}s' : '+${skipDuration}s';
    });

    if (isLeft) {
      player.seek(Duration(
          seconds: max(0, currentPosition!.inSeconds - skipDuration!)));
      _leftAnimationController.forward(from: 0);
    } else {
      player
          .seek(Duration(seconds: currentPosition!.inSeconds + skipDuration!));
      _rightAnimationController.forward(from: 0);
    }

    _resetControlsAfterDelay();
  }

  void _resetControlsAfterDelay() {
    _doubleTapTimeout?.cancel();
    _doubleTapTimeout = Timer(const Duration(milliseconds: 1000), () {
      setState(() {
        isControlsLocked = false;
        _doubleTapLabel = '';
      });
    });
  }

  Widget _buildRippleEffect() {
    if (_doubleTapPosition == null || _doubleTapLabel.isEmpty) {
      return const SizedBox();
    }

    return AnimatedPositioned(
      left: _isLeftSide ? 0 : MediaQuery.of(context).size.width / 1.5,
      width: MediaQuery.of(context).size.width / 3,
      top: 0,
      bottom: 0,
      duration: const Duration(milliseconds: 1000),
      child: AnimatedBuilder(
        animation:
            _isLeftSide ? _leftAnimationController : _rightAnimationController,
        builder: (context, child) {
          final scale = Tween<double>(begin: 1.5, end: 1).animate(
            CurvedAnimation(
              parent: _isLeftSide
                  ? _leftAnimationController
                  : _rightAnimationController,
              curve: Curves.bounceInOut,
            ),
          );

          return Opacity(
            opacity: 1.0 -
                (_isLeftSide
                    ? _leftAnimationController.value
                    : _rightAnimationController.value),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(_isLeftSide ? 0 : 100),
                  topRight: Radius.circular(_isLeftSide ? 100 : 0),
                  bottomLeft: Radius.circular(_isLeftSide ? 0 : 100),
                  bottomRight: Radius.circular(_isLeftSide ? 100 : 0),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: scale,
                    child: Icon(
                      _isLeftSide ? Iconsax.backward : Iconsax.forward,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _doubleTapLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTapDown: _handleTap,
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: (e) async {
          final delta = e.delta.dy;
          final Offset position = e.localPosition;

          if (position.dx <= MediaQuery.of(context).size.width / 2) {
            final brightness = _brightnessValue - delta / 500;
            final result = brightness.clamp(0.0, 1.0);
            setBrightness(result);
          } else {
            final volume = _volumeValue - delta / 500;
            final result = volume.clamp(0.0, 1.0);
            setVolume(result);
          }
        },
        child: KeyboardListener(
          focusNode: _focusNode,
          onKeyEvent: _handleKeyPress,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Video Player
              Video(
                fit: resizeModesOptions[resizeMode] ?? BoxFit.contain,
                controller: videoPlayerController!,
                subtitleViewConfiguration: SubtitleViewConfiguration(
                    style: TextStyle(
                        fontSize: subtitleSize,
                        fontFamily: subtitleFont,
                        backgroundColor: colorOptions[subtitleBackgroundColor],
                        inherit: false,
                        color: colorOptions[subtitleColor])),
                pauseUponEnteringBackgroundMode: false,
                controls: null,
              ),
              Positioned.fill(child: overlay()),
              Positioned.fill(
                child: AnimatedOpacity(
                  opacity: showControls ? 1 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: IgnorePointer(
                    ignoring: !showControls,
                    child: VideoControls(
                      controller: player,
                      bottomControls: bottomControls(),
                      topControls: topControls(),
                      hideControlsOnTimeout: () {},
                      isControlsLocked: () => isControlsLocked,
                      isControlsVisible: showControls,
                      episodeMap: getEpisodeMap(),
                      episodeNav: (direction) => navEpisodes(direction),
                    ),
                  ),
                ),
              ),
              _buildRippleEffect(),
              AnimatedOpacity(
                curve: Curves.easeInOut,
                opacity: _brightnessIndicator ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: MediaIndicatorBuilder(
                  value: _brightnessValue,
                  isVolumeIndicator: false,
                ),
              ),
              AnimatedOpacity(
                curve: Curves.easeInOut,
                opacity: _volumeIndicator ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: MediaIndicatorBuilder(
                  value: _volumeValue,
                  isVolumeIndicator: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
