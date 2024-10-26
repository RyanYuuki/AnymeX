import 'package:flutter/material.dart';
import 'package:better_player/better_player.dart';
import 'package:better_player/src/video_player/video_player.dart';
import 'package:better_player/src/controls/better_player_material_progress_bar.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class Controls extends StatefulWidget {
  final BetterPlayerController controller;
  final Widget bottomControls;
  final Widget topControls;
  final void Function() hideControlsOnTimeout;
  final bool Function() isControlsLocked;
  final bool isControlsVisible;

  const Controls({
    super.key,
    required this.controller,
    required this.bottomControls,
    required this.topControls,
    required this.hideControlsOnTimeout,
    required this.isControlsLocked,
    required this.isControlsVisible,
  });

  @override
  State<Controls> createState() => _ControlsState();
}

class _ControlsState extends State<Controls> {
  late VideoPlayerController _controller;

  IconData? playPause;
  String currentTime = "0:00";
  String maxTime = "0:00";
  int? skipDuration;
  bool alreadySkipped = false;
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
      skipDuration = 10;
      megaSkipDuration = 85;
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
    return Positioned.fill(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            widget.topControls,
            Expanded(
              child: widget.isControlsLocked()
                  ? lockedCenterControls()
                  : centerControls(context),
            ),
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
                    if (megaSkipDuration != null &&
                        !widget.isControlsLocked() &&
                        !alreadySkipped)
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
                          trackShape: EdgeToEdgeTrackShape(),
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
      ),
    );
  }

  ElevatedButton megaSkipButton() {
    return ElevatedButton(
      onPressed: () {
        fastForward(megaSkipDuration!);
        alreadySkipped = true;
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

  Container lockedCenterControls() {
    return Container(
      alignment: Alignment.center,
      child: Row(
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
    );
  }

  Row centerControls(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        buildControlButton(
          icon: Icons.fast_rewind_rounded,
          onTap: () {
            fastForward(skipDuration != null ? -skipDuration! : -10);
          },
        ),
        Container(
          child: !buffering
              ? buildControlButton(
                  icon: playPause ?? Icons.play_arrow_rounded,
                  size: 45,
                  onTap: () {
                    if (_controller.value.isPlaying) {
                      playPause = Icons.play_arrow_rounded;
                      _controller.pause();
                    } else {
                      playPause = Icons.pause_rounded;
                      _controller.play();
                    }
                    setState(() {});
                  },
                )
              : Container(
                  width: 65,
                  height: 65,
                  margin: const EdgeInsets.only(left: 5, right: 5),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
        ),
        buildControlButton(
          icon: Icons.fast_forward_rounded,
          onTap: () {
            fastForward(skipDuration ?? 10);
          },
        ),
      ],
    );
  }

  Widget buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    double size = 40,
  }) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        height: 65,
        width: 65,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Icon(
            icon,
            color: Colors.white,
            size: size,
          ),
        ),
      ),
    );
  }
}

class EdgeToEdgeTrackShape extends RoundedRectSliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 2.0;
    final double trackWidth = parentBox.size.width;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    return Rect.fromLTWH(offset.dx, trackTop, trackWidth, trackHeight);
  }
}
