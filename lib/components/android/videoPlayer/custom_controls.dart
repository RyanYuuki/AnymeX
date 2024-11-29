import 'package:flutter/material.dart';
import 'package:better_player/better_player.dart';
import 'package:better_player/src/video_player/video_player.dart';
import 'package:better_player/src/controls/better_player_material_progress_bar.dart';
import 'package:hive/hive.dart';
import 'package:iconsax/iconsax.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class Controls extends StatefulWidget {
  final BetterPlayerController controller;
  final Widget bottomControls;
  final Widget topControls;
  final void Function() hideControlsOnTimeout;
  final bool Function() isControlsLocked;
  final void Function(String) episodeNav;
  final bool isControlsVisible;
  final Map<String, bool> episodeMap;

  const Controls({
    super.key,
    required this.controller,
    required this.bottomControls,
    required this.topControls,
    required this.hideControlsOnTimeout,
    required this.isControlsLocked,
    required this.isControlsVisible,
    required this.episodeMap,
    required this.episodeNav,
  });

  @override
  State<Controls> createState() => _ControlsState();
}

class _ControlsState extends State<Controls> {
  late VideoPlayerController _controller;

  IconData? playPause;
  String currentTime = "0:00";
  String maxTime = "0:00";
  int? megaSkipDuration;
  bool buffering = false;
  bool wakelockEnabled = false;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    wakelockEnabled = true;
    _controller = widget.controller.videoPlayerController!;
    widget.hideControlsOnTimeout();
    _controller.addListener(playerEventListener);
    assignSettings();
  }

  void playerEventListener() {
    if (widget.isControlsVisible) {
      widget.hideControlsOnTimeout();
    }

    if (mounted) {
      setState(() {
        int duration = _controller.value.duration?.inSeconds ?? 0;
        int val = _controller.value.position.inSeconds;
        playPause = _controller.value.isPlaying
            ? Icons.pause_rounded
            : Icons.play_arrow_rounded;
        currentTime = getFormattedTime(val);
        maxTime = getFormattedTime(duration);
        buffering = _controller.value.isBuffering;
      });
    }

    if (_controller.value.isPlaying && !wakelockEnabled) {
      WakelockPlus.enable();
      wakelockEnabled = true;
    } else if (!_controller.value.isPlaying && wakelockEnabled) {
      WakelockPlus.disable();
      wakelockEnabled = false;
    }
  }

  Future<void> assignSettings() async {
    setState(() {
      megaSkipDuration =
          Hive.box('app-data').get('megaSkipDuration', defaultValue: 85);
    });
  }

  String getFormattedTime(int timeInSeconds) {
    String formatTime(int val) {
      return val.toString().padLeft(2, '0');
    }

    int hours = timeInSeconds ~/ 3600;
    int minutes = (timeInSeconds % 3600) ~/ 60;
    int seconds = timeInSeconds % 60;

    String formattedHours = hours == 0 ? '' : formatTime(hours);
    String formattedMins = formatTime(minutes);
    String formattedSeconds = formatTime(seconds);

    return "${formattedHours.isNotEmpty ? "$formattedHours:" : ''}$formattedMins:$formattedSeconds";
  }

  void fastForward(int seekDuration) {
    if ((_controller.value.position.inSeconds + seekDuration) <= 0) {
      _controller.seekTo(const Duration(seconds: 0));
    } else {
      if ((_controller.value.position.inSeconds + seekDuration) >=
          _controller.value.duration!.inSeconds) {
        _controller.seekTo(Duration(
            milliseconds: _controller.value.duration!.inMilliseconds - 500));
      } else {
        _controller.seekTo(Duration(
            seconds: _controller.value.position.inSeconds + seekDuration));
      }
    }
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 40),
      child: Stack(
        children: [
          widget.topControls,
          widget.isControlsLocked()
              ? lockedCenterControls()
              : centerControls(context),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        currentTime,
                      ),
                      const Text(
                        " / ",
                      ),
                      Text(
                        maxTime,
                      ),
                    ],
                  ),
                  if (megaSkipDuration != null && !widget.isControlsLocked())
                    megaSkipButton(),
                ],
              ),
              Container(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  height: 20,
                  child: IgnorePointer(
                    ignoring: widget.isControlsLocked(),
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 1.3,
                        thumbColor: Theme.of(context).colorScheme.primary,
                        activeTrackColor: Theme.of(context).colorScheme.primary,
                        inactiveTrackColor:
                            const Color.fromARGB(255, 121, 121, 121),
                        secondaryActiveTrackColor:
                            const Color.fromARGB(255, 167, 167, 167),
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: SliderComponentShape.noThumb,
                      ),
                      child: BetterPlayerMaterialVideoProgressBar(
                        _controller,
                        widget.controller,
                        onDragStart: () {
                          widget.controller.pause();
                        },
                        onDragEnd: () {
                          widget.controller.play();
                        },
                        colors: BetterPlayerProgressColors(
                          playedColor: Theme.of(context).colorScheme.primary,
                          handleColor: widget.isControlsLocked()
                              ? Colors.transparent
                              : Theme.of(context).colorScheme.primary,
                          bufferedColor:
                              const Color.fromARGB(255, 167, 167, 167),
                          backgroundColor:
                              const Color.fromARGB(255, 94, 94, 94),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              widget.bottomControls
            ],
          ),
        ],
      ),
    );
  }

  ElevatedButton megaSkipButton() {
    return ElevatedButton(
      onPressed: () {
        fastForward(megaSkipDuration ?? 85);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
      ),
      child: SizedBox(
        height: 50,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: Text(
                "+$megaSkipDuration",
                style: const TextStyle(
                  fontSize: 17,
                ),
              ),
            ),
            const Icon(
              Icons.fast_forward_rounded,
              color: Colors.white,
            )
          ],
        ),
      ),
    );
  }

  Positioned lockedCenterControls() {
    return Positioned(
      child: Center(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (buffering)
              SizedBox(
                width: 40,
                height: 40,
                child: Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Positioned centerControls(BuildContext context) {
    return Positioned.fill(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Opacity(
            opacity: widget.episodeMap['prev'] ?? false ? 1 : 0,
            child: buildControlButton(
              icon: Iconsax.previous5,
              size: 35,
              onTap: () {
                final map = widget.episodeMap;
                if (map['prev'] ?? false) {
                  widget.episodeNav('prev');
                }
              },
            ),
          ),
          const SizedBox(width: 50),
          buffering || !_controller.value.initialized
              ? Center(
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                )
              : buildControlButton(
                  icon: playPause ?? Iconsax.play5,
                  onTap: () {
                    if (_controller.value.isPlaying) {
                      playPause = Iconsax.play5;
                      _controller.pause();
                    } else {
                      playPause = Iconsax.pause5;
                      _controller.play();
                    }
                    setState(() {});
                  },
                ),
          const SizedBox(width: 50),
          Opacity(
            opacity: widget.episodeMap['next'] ?? true ? 1 : 0,
            child: buildControlButton(
              icon: Iconsax.next5,
              size: 35,
              onTap: () {
                final map = widget.episodeMap;
                if (map['next'] ?? true) {
                  widget.episodeNav('right');
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    double size = 45,
    Color color = Colors.white,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Icon(
        icon,
        color: color,
        size: size,
      ),
    );
  }
}
