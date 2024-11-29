import 'dart:async';
import 'dart:developer';
import 'dart:math' show max;
import 'package:anymex/auth/auth_provider.dart';
import 'package:anymex/components/android/videoPlayer/custom_controls.dart';
import 'package:anymex/hiveData/appData/database.dart';
import 'package:anymex/utils/sources/anime/extensions/aniwatch_api/api.dart';
import 'package:anymex/utils/sources/unified_handler.dart';
import 'package:flutter/material.dart';
import 'package:better_player/better_player.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class WatchPage extends StatefulWidget {
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

  const WatchPage({
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
  State<WatchPage> createState() => _WatchPageState();
}

class _WatchPageState extends State<WatchPage> with TickerProviderStateMixin {
  BetterPlayerController? _betterPlayerController;
  bool showControls = true;
  bool showSubs = true;
  List<BetterPlayerSubtitlesSource>? subtitles;
  int selectedQuality = 0;
  bool isLandScapeRight = false;
  bool isControlsLocked = false;
  List<dynamic>? episodeSrc;
  dynamic tracks;
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

    if (widget.isDub) {
      fetchSubtitles(
          widget.episodeData[widget.currentEpisode - 1]['episodeId']);
    }

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

  @override
  void dispose() {
    _betterPlayerController?.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _leftAnimationController.dispose();
    _rightAnimationController.dispose();
    _doubleTapTimeout?.cancel();
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
    episodeSrc = widget.episodeSrc['sources'];
    tracks = widget.tracks;
    episodeTitle = widget.episodeTitle;
    currentEpisode = widget.currentEpisode;
    skipDuration = Hive.box('app-data').get('skipDuration', defaultValue: 10);
  }

  void initializePlayer() {
    filterSubtitles(tracks);
    BetterPlayerConfiguration betterPlayerConfiguration =
        BetterPlayerConfiguration(
      fit: resizeModesOptions[resizeMode]!,
      controlsConfiguration:
          const BetterPlayerControlsConfiguration(showControls: false),
      autoPlay: true,
      expandToFill: true,
      looping: false,
      subtitlesConfiguration: BetterPlayerSubtitlesConfiguration(
        fontSize: subtitleSize,
        fontColor: colorOptions[subtitleColor]!,
        outlineColor: colorOptions[subtitleOutlineColor]!,
        fontFamily: subtitleFont == "Default" ? "Poppins" : subtitleFont,
        backgroundColor: colorOptions[subtitleBackgroundColor]!,
      ),
    );

    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _betterPlayerController!.setupDataSource(_createDataSource());

    _betterPlayerController!.addEventsListener((event) {
      if (event.betterPlayerEventType == BetterPlayerEventType.initialized) {
        _betterPlayerController!.setSpeed(playbackSpeed);
      }
    });
  }

  BetterPlayerDataSource _createDataSource() {
    return BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      episodeSrc![0]['url']!,
      subtitles: subtitles,
      videoFormat: BetterPlayerVideoFormat.hls,
    );
  }

  void filterSubtitles(List<dynamic>? source) {
    if (source != null) {
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
    } else {
      subtitles = null;
    }
  }

  Future<void> fetchSrcHelper(String episodeId) async {
    setState(() {
      episodeSrc == null;
      _betterPlayerController!.pause();
      _betterPlayerController!
          .setupDataSource(BetterPlayerDataSource.network(''));
    });
    try {
      final response =
          await Provider.of<UnifiedSourcesHandler>(context, listen: false)
              .getAnimeInstance()
              .fetchEpisodesSrcs(
                episodeId,
                lang: widget.activeServer,
                category: widget.isDub ? 'dub' : 'sub',
              );

      if (response != null && mounted) {
        setState(() {
          tracks = response['tracks'];
          episodeSrc = response['sources'];
        });
        final isOOB = currentEpisode! == widget.episodeData.length;
        if (widget.sourceAnimeId != 'rescue') {
          Provider.of<AppData>(context).addWatchedAnime(
              anilistAnimeId: widget.animeId.toString(),
              animeId: widget.sourceAnimeId,
              animeTitle: widget.animeTitle,
              currentEpisode:
                  (isOOB ? currentEpisode : currentEpisode! + 1).toString(),
              animePosterImageUrl: widget.posterImage,
              episodeList: widget.episodeData,
              currentSource:
                  Provider.of<UnifiedSourcesHandler>(context, listen: false)
                      .getAnimeInstance()
                      .selectedSource,
              animeDescription: widget.description);
        }

        if (Provider.of<UnifiedSourcesHandler>(context, listen: false)
                .getAnimeInstance()
                .selectedSource !=
            "GogoAnime") {
          filterSubtitles(tracks);
          if (widget.isDub) await fetchSubtitles(episodeId);
        }
        _betterPlayerController?.setupDataSource(_createDataSource());
      }
    } catch (e) {
      log('Error fetching episode sources: $e');
    }
  }

  Future<void> fetchSubtitles(String episodeId) async {
    try {
      final response = await HiAnimeApi().fetchStreamingLinksAniwatch(
        episodeId,
        widget.activeServer,
        'sub',
      );

      if (response != null && mounted) {
        setState(() {
          tracks = response['tracks'];
        });

        filterSubtitles(tracks);
        _betterPlayerController?.setupDataSource(_createDataSource());
      }
    } catch (e) {
      log('Error fetching subtitles: $e');
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
        // IconButton(
        //   onPressed: () {
        //     _betterPlayerController!
        //         .enablePictureInPicture(GlobalKey(debugLabel: 'AnymeX'));
        //   },
        //   icon: const Icon(
        //     Icons.picture_in_picture_alt_rounded,
        //     color: Colors.white,
        //   ),
        // ),
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

  void changeResizeMode(int index) {
    setState(() {
      _betterPlayerController?.setOverriddenFit(resizeModes[index]);
    });
  }

  Row bottomControls() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () {
                if (Provider.of<UnifiedSourcesHandler>(context, listen: false)
                        .getAnimeInstance()
                        .selectedSource ==
                    "AnimePahe") {
                  multiQualityDialog();
                } else {
                  qualityDialog();
                }
              },
              icon: const Icon(
                Icons.high_quality_rounded,
                color: Colors.white,
              ),
            ),
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
            IconButton(
              onPressed: () {
                index++;
                if (index > 2) {
                  index = 0;
                  changeResizeMode(index);
                } else {
                  changeResizeMode(index);
                }
              },
              icon: const Icon(
                Icons.fullscreen_rounded,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void showPlaybackSpeedDialog(BuildContext context) {
    BetterPlayerController? playerController = _betterPlayerController;
    double currentSpeed =
        playerController?.videoPlayerController?.value.speed ?? 1.0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Playback Speed'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSpeedOption(
                    context, playerController!, 0.5, currentSpeed),
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

  Widget _buildSpeedOption(
      BuildContext context,
      BetterPlayerController playerController,
      double speed,
      double currentSpeed) {
    return RadioListTile<double>(
      value: speed,
      groupValue: currentSpeed,
      onChanged: (value) {
        if (value != null) {
          playerController.setSpeed(value);
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
        final episodeIndex = widget.episodeData
            .indexWhere((episode) => episode['number'] == currentEpisode);
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
                    final episode = widget.episodeData[index];
                    final isSelected = episode['number'] == currentEpisode;
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
                            episodeTitle = episode['title'];
                            currentEpisode = episode['number'];
                          });
                          Navigator.pop(context);
                          await fetchSrcHelper(episode['episodeId']);
                        },
                        child: Text(
                          'Episode ${episode['number']}: ${episode['title']}',
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

  qualityDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
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
                itemCount:
                    _betterPlayerController?.betterPlayerAsmsTracks.length ?? 0,
                itemBuilder: (context, index) {
                  final BetterPlayerAsmsTrack? track =
                      _betterPlayerController?.betterPlayerAsmsTracks[index];

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
                        _betterPlayerController?.setTrack(track!);
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        track?.height == 0 ? 'Auto' : '${track?.height}P',
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

  multiQualityDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
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
                itemCount: widget.episodeSrc['multiSrc'].length ?? 0,
                itemBuilder: (context, index) {
                  final String quality =
                      widget.episodeSrc['multiSrc'][index]['quality'];
                  final String link =
                      widget.episodeSrc['multiSrc'][index]['url'];

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
                        _betterPlayerController?.setupDataSource(
                            BetterPlayerDataSource.network(link));
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        quality,
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
  BetterPlayerSubtitlesSource? nullSub;

  subtitleDialog() {
    log(widget.tracks.toString());
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
                  itemCount: _betterPlayerController
                          ?.betterPlayerSubtitlesSourceList.length ??
                      0,
                  itemBuilder: (context, index) {
                    final BetterPlayerSubtitlesSource? track =
                        _betterPlayerController
                            ?.betterPlayerSubtitlesSourceList[index];

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
                            _betterPlayerController
                                ?.setupSubtitleSource(track!);
                          });
                          Navigator.pop(context);
                        },
                        child: Text(
                          (track?.name == 'Default subtitles'
                              ? 'None'
                              : track?.name)!,
                          style: TextStyle(
                              fontSize: 16,
                              color: selectedSub == index
                                  ? Colors.black
                                  : Colors.white),
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
    final currentPosition =
        _betterPlayerController!.videoPlayerController?.value.position;
    if (currentPosition == null) return;

    setState(() {
      isControlsLocked = true;
      _doubleTapLabel = isLeft ? '-${skipDuration}s' : '+${skipDuration}s';
    });

    if (isLeft) {
      _betterPlayerController!.seekTo(
          Duration(seconds: max(0, currentPosition.inSeconds - skipDuration!)));
      _leftAnimationController.forward(from: 0);
    } else {
      _betterPlayerController!
          .seekTo(Duration(seconds: currentPosition.inSeconds + skipDuration!));
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
    var episode = widget.episodeData[currentEpisode! - 1];
    setState(() {
      episodeTitle = episode['title'];
      currentEpisode = episode['number'];
    });
    await fetchSrcHelper(episode['episodeId']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTapDown: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // Video Player
            BetterPlayer(controller: _betterPlayerController!),
            Positioned.fill(child: overlay()),
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: showControls ? 1 : 0,
                duration: const Duration(milliseconds: 300),
                child: IgnorePointer(
                  ignoring: !showControls,
                  child: Controls(
                    controller: _betterPlayerController!,
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
          ],
        ),
      ),
    );
  }
}
