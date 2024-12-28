// ignore_for_file: unused_field

import 'dart:async';
import 'package:anymex/components/platform_builder.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';
import 'package:media_kit/media_kit.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class VideoControls extends StatefulWidget {
  final Player controller;
  final Widget bottomControls;
  final Widget topControls;
  final void Function() hideControlsOnTimeout;
  final bool Function() isControlsLocked;
  final void Function(String) episodeNav;
  final bool isControlsVisible;
  final Map<String, bool> episodeMap;

  const VideoControls({
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
  State<VideoControls> createState() => _ControlsState();
}

class _ControlsState extends State<VideoControls> {
  late Player _controller;

  IconData? playPause;
  String currentTime = "0:00";
  String maxTime = "0:00";
  int? megaSkipDuration;
  bool buffering = true;
  bool wakelockEnabled = false;

  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    wakelockEnabled = true;
    _controller = widget.controller;
    widget.hideControlsOnTimeout();
    playerEventListener();
    assignSettings();
  }

  StreamSubscription? positionSubscription;
  StreamSubscription? durationSubscription;
  StreamSubscription? bufferingSubscription;
  StreamSubscription? playingSubscription;

  void playerEventListener() {
    positionSubscription = _controller.stream.position.listen((e) {
      if (mounted) {
        setState(() {
          currentTime = getFormattedTime(e.inSeconds) ?? '00:00';
        });
      }
    });

    durationSubscription = _controller.stream.duration.listen((e) {
      if (mounted) {
        setState(() {
          maxTime = getFormattedTime(e.inSeconds) ?? '00:00';
        });
      }
    });

    bufferingSubscription =
        _controller.stream.buffering.listen((bufferingStatus) {
      if (mounted) {
        setState(() {
          buffering = bufferingStatus;
        });
      }
    });

    playingSubscription = _controller.stream.playing.listen((playingStatus) {
      if (mounted) {
        setState(() {
          playPause = playingStatus ? Iconsax.pause5 : Iconsax.play5;
          isPlaying = playingStatus;
        });
      }
    });
  }

  @override
  void dispose() {
    positionSubscription?.cancel();
    durationSubscription?.cancel();
    bufferingSubscription?.cancel();
    playingSubscription?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  bool? isPlaying;

  Future<void> assignSettings() async {
    setState(() {
      megaSkipDuration =
          Hive.box('app-data').get('megaSkipDuration', defaultValue: 85);
    });
  }

  String? getFormattedTime(int timeInSeconds) {
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
    if ((_controller.state.position.inSeconds + seekDuration) <= 0) {
      _controller.seek(const Duration(seconds: 0));
    } else {
      if ((_controller.state.position.inSeconds + seekDuration) >=
          _controller.state.duration.inSeconds) {
        _controller.seek(Duration(
            milliseconds: _controller.state.duration.inMilliseconds - 500));
      } else {
        _controller.seek(Duration(
            seconds: _controller.state.position.inSeconds + seekDuration));
      }
    }
  }

  int timeStringToSeconds(String time) {
    List<String> parts = time.split(':');
    if (parts.length == 2) {
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    } else if (parts.length == 3) {
      return int.parse(parts[0]) * 3600 +
          int.parse(parts[1]) * 60 +
          int.parse(parts[2]);
    }
    return 0;
  }

  String _formatSecondsToTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int secs = seconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    double currentProgress = timeStringToSeconds(currentTime).toDouble();
    double totalDuration = timeStringToSeconds(maxTime).toDouble();
    return Padding(
      padding: MediaQuery.of(context).orientation == Orientation.portrait
          ? const EdgeInsets.symmetric(vertical: 5.0, horizontal: 5.0)
          : const EdgeInsets.symmetric(vertical: 15.0, horizontal: 40.0),
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
                      const SizedBox(
                        width: 4,
                      ),
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
                      child: Slider(
                        min: 0.0,
                        max: totalDuration > 0 ? totalDuration : 1.0,
                        value: currentProgress.clamp(0.0, totalDuration),
                        onChanged: (double val) {
                          widget.controller.pause();
                          setState(() {
                            buffering = true;
                            currentTime = _formatSecondsToTime(val.toInt());
                          });
                          _controller.seek(Duration(seconds: val.toInt()));
                          _controller.stream.buffering.listen((err) {
                            buffering = err;
                          });
                          widget.controller.play();
                        },
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
            child: PlatformBuilder(
              strictMode: true,
              androidBuilder: buildControlButton(
                icon: Iconsax.previous5,
                onTap: () {
                  final map = widget.episodeMap;
                  if (map['prev'] ?? false) {
                    widget.episodeNav('prev');
                  }
                },
              ),
              desktopBuilder: Row(
                children: [
                  buildControlButton(
                    icon: Iconsax.previous5,
                    size: 50,
                    onTap: () {
                      final map = widget.episodeMap;
                      if (map['prev'] ?? false) {
                        widget.episodeNav('prev');
                      }
                    },
                  ),
                  const SizedBox(width: 30),
                ],
              ),
            ),
          ),
          const SizedBox(width: 50),
          buffering
              ? Center(
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                )
              : PlatformBuilder(
                  strictMode: true,
                  androidBuilder: buildControlButton(
                    icon: playPause ?? Iconsax.pause5,
                    onTap: () {
                      setState(() {
                        if (isPlaying ?? false) {
                          playPause = Iconsax.play5;
                          _controller.pause();
                        } else {
                          playPause = Iconsax.pause5;
                          _controller.play();
                        }
                      });
                    },
                  ),
                  desktopBuilder: buildControlButton(
                    size: 60,
                    icon: playPause ?? Iconsax.pause5,
                    onTap: () {
                      setState(() {
                        if (isPlaying ?? false) {
                          playPause = IconlyBold.play;
                          _controller.pause();
                        } else {
                          playPause = Iconsax.pause5;
                          _controller.play();
                        }
                      });
                    },
                  ),
                ),
          const SizedBox(width: 50),
          Opacity(
            opacity: widget.episodeMap['next'] ?? true ? 1 : 0,
            child: PlatformBuilder(
              strictMode: true,
              androidBuilder: buildControlButton(
                icon: Iconsax.next5,
                onTap: () {
                  final map = widget.episodeMap;
                  if (map['next'] ?? true) {
                    widget.episodeNav('right');
                  }
                },
              ),
              desktopBuilder: Row(
                children: [
                  const SizedBox(width: 30),
                  buildControlButton(
                    icon: Iconsax.next5,
                    size: 50,
                    onTap: () {
                      final map = widget.episodeMap;
                      if (map['next'] ?? true) {
                        widget.episodeNav('right');
                      }
                    },
                  ),
                ],
              ),
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
