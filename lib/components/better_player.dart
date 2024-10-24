import 'dart:developer';

import 'package:aurora/components/test_player.dart';
import 'package:aurora/database/api.dart';
import 'package:flutter/material.dart';
import 'package:better_player/better_player.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';

class VideoPlayerAlt extends StatefulWidget {
  final String episodeSrc;
  final ThemeData provider;
  final dynamic tracks;
  final String animeTitle;
  final String episodeTitle;
  final int currentEpisode;
  final dynamic episodeData;
  final String activeServer;
  final bool isDub;

  const VideoPlayerAlt({
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
  });

  @override
  State<VideoPlayerAlt> createState() => _VideoPlayerAltState();
}

class _VideoPlayerAltState extends State<VideoPlayerAlt>
    with AutomaticKeepAliveClientMixin {
  BetterPlayerController? _betterPlayerController;
  bool showControls = true;
  bool showSubs = true;
  List<BetterPlayerSubtitlesSource>? subtitles;
  int selectedQuality = 0;
  bool isLandScapeRight = false;
  bool isControlsLocked = false;
  String? episodeSrc;
  dynamic tracks;
  String? episodeTitle;
  int? currentEpisode;
  List<BoxFit> resizeModes = [
    BoxFit.contain,
    BoxFit.fill,
    BoxFit.cover,
  ];
  int index = 0;

  @override
  void initState() {
    super.initState();
    _initVars();
    initializePlayer();
  }

  void _initVars() {
    setState(() {
      episodeSrc = widget.episodeSrc;
      tracks = widget.tracks;
      episodeTitle = widget.episodeTitle;
      currentEpisode = widget.currentEpisode;
    });
  }

  void initializePlayer() {
    filterSubtitles(tracks);

    BetterPlayerConfiguration betterPlayerConfiguration =
        const BetterPlayerConfiguration(
      fit: BoxFit.contain,
      aspectRatio: 16 / 9,
      controlsConfiguration: BetterPlayerControlsConfiguration(
        showControls: false,
      ),
      autoPlay: false,
      expandToFill: true,
      looping: false,
    );

    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _betterPlayerController!.setupDataSource(BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      episodeSrc!,
      subtitles: subtitles,
      videoFormat: BetterPlayerVideoFormat.hls,
    ));
  }

  void filterSubtitles(List<dynamic>? source) {
    if (source != null) {
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
    } else {
      subtitles = null;
    }
  }

  Future<void> fetchSrcHelper(String episodeId) async {
    episodeSrc = null;
    try {
      final response = await fetchStreamingLinksAniwatch(
          episodeId, widget.activeServer, widget.isDub ? 'dub' : 'sub');
      if (response != null) {
        final episodeSrcs = response;
        setState(() {
          tracks = episodeSrcs['tracks'];
          episodeSrc = episodeSrcs['sources'][0]['url'];
        });

        filterSubtitles(tracks);

        _betterPlayerController?.setupDataSource(BetterPlayerDataSource(
          BetterPlayerDataSourceType.network,
          episodeSrc!,
          subtitles: subtitles,
          videoFormat: BetterPlayerVideoFormat.hls,
        ));
      }
    } catch (e) {
      log('Error fetching episode sources: $e');
    }
  }

  Flexible topControls() {
    return Flexible(
      flex: 1,
      child: Row(
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
      ),
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
                qualityDialog();
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

  void episodesDialog() {
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
                  itemCount: widget.episodeData.length,
                  itemBuilder: (context, index) {
                    final episode = widget.episodeData[index];
                    final isSelected = episode['number'] == currentEpisode;
                    return Container(
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Select Video Quality",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
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

  int selectedSub = 0;
  BetterPlayerSubtitlesSource? nullSub;

  subtitleDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GestureDetector(
      onTap: () {
        setState(() {
          showControls = !showControls;
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        });
      },
      child: Stack(
        children: [
          BetterPlayer(controller: _betterPlayerController!),
          Positioned.fill(child: overlay()),
          if (showControls) ...[
            Controls(
                controller: _betterPlayerController!,
                bottomControls: bottomControls(),
                topControls: topControls(),
                hideControlsOnTimeout: () {},
                isControlsLocked: () {
                  return isControlsLocked;
                },
                isControlsVisible: showControls),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _betterPlayerController?.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}
