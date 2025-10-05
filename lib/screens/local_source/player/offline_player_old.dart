// ignore_for_file: invalid_use_of_protected_member
import 'dart:async';
import 'package:anymex/screens/local_source/player/offline_player.dart';
import 'package:anymex/utils/logger.dart';
import 'dart:io';
import 'package:anymex/controllers/service_handler/service_handler.dart';

import 'package:anymex/constants/contants.dart';
import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/models/player/player_adaptor.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/screens/anime/widgets/media_indicator_old.dart';
import 'package:anymex/screens/anime/widgets/video_slider.dart';
import 'package:anymex/screens/settings/sub_settings/settings_player.dart';
import 'package:anymex/utils/color_profiler.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/language.dart';
import 'package:anymex/utils/shaders.dart';
import 'package:anymex/widgets/common/checkmark_tile.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/anymex_titlebar.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/custom_widgets/custom_button.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/custom_widgets/custom_textspan.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconsax/iconsax.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:outlined_text/outlined_text.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:super_sliver_list/super_sliver_list.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:window_manager/window_manager.dart';

class OfflineWatchPageOld extends StatefulWidget {
  final LocalEpisode episodePath;
  final List<LocalEpisode> episodesList;
  const OfflineWatchPageOld({
    super.key,
    required this.episodePath,
    required this.episodesList,
  });

  @override
  State<OfflineWatchPageOld> createState() => _OfflineWatchPageOldState();
}

class _OfflineWatchPageOldState extends State<OfflineWatchPageOld>
    with TickerProviderStateMixin {
  final offlineStorage = Get.find<OfflineStorageController>();

  late Player player;
  late VideoController playerController;
  final isPlaying = true.obs;
  final currentPosition = const Duration(milliseconds: 0).obs;
  final episodeDuration = const Duration(minutes: 24).obs;
  final formattedTime = "00:00".obs;
  final formattedDuration = "00:00".obs;
  final showControls = true.obs;
  final playbackSpeed = 1.0.obs;
  final isFullscreen = false.obs;
  final settings = Get.find<Settings>();
  final RxString resizeMode = "Cover".obs;
  late PlayerSettings playerSettings;
  late FocusNode _keyboardListenerFocusNode;

  final RxBool _volumeIndicator = false.obs;
  final RxBool _brightnessIndicator = false.obs;
  Timer? _volumeTimer;
  Timer? _brightnessTimer;
  var _volumeInterceptEventStream = false;
  final RxDouble _volumeValue = 0.0.obs;
  final RxDouble _brightnessValue = 0.0.obs;
  late AnimationController _leftAnimationController;
  late AnimationController _rightAnimationController;
  RxInt skipDuration = 10.obs;
  final isLocked = false.obs;

  final doubleTapLabel = 0.obs;
  Timer? doubleTapTimeout;
  final isLeftSide = false.obs;
  Timer? _hideControlsTimer;
  final pressed2x = false.obs;

  final audioTracks = <AudioTrack>[].obs;
  final subtitleTracks = <SubtitleTrack>[].obs;

  final selectedAudioTrack = Rxn<AudioTrack>();
  final selectedSubTrack = Rxn<SubtitleTrack>();

  RxList<String> subtitleText = [''].obs;

  // Service Related Handlers and Variables
  final sourceController = Get.find<SourceController>();
  final serviceHandler = Get.find<ServiceHandler>();
  final leftOriented = true.obs;
  final isMobile = Platform.isAndroid || Platform.isIOS;

  // Video Player Visual Profile
  final currentVisualProfile = 'natural'.obs;
  RxMap<String, int> customSettings = <String, int>{}.obs;

  void applySavedProfile() => ColorProfileManager()
      .applyColorProfile(currentVisualProfile.value, player);

  @override
  void initState() {
    super.initState();
    if (!settings.isTV.value) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      if (settings.defaultPortraitMode) {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      } else {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight
        ]);
      }
    }
    _leftAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _rightAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _initHiveVariables();
    _initPlayer(true);
    _attachListeners();
    applySavedProfile();
    if (isMobile) {
      _handleVolumeAndBrightness();
    }
    _keyboardListenerFocusNode = FocusNode(
      canRequestFocus: !settings.isTV.value,
      skipTraversal: settings.isTV.value,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_keyboardListenerFocusNode.hasFocus) {
        _keyboardListenerFocusNode.requestFocus();
      }
    });
  }

  Future<void> trackEpisode(Duration position, Duration duration) async {
    offlineStorage.storage
        .put('${widget.episodePath.path}-progress', position.inMilliseconds);
  }

  void _initPlayer(bool firstTime) async {
    int startTimeMilliseconds = offlineStorage.storage
        .get('${widget.episodePath.path}-progress', defaultValue: 0);
    if (firstTime) {
      player = Player();
      playerController = VideoController(player,
          configuration: const VideoControllerConfiguration(
              androidAttachSurfaceAfterVideoParameters: true));
    } else {
      currentPosition.value = Duration.zero;
      episodeDuration.value = Duration.zero;
    }
    player.open(Media('file:///${widget.episodePath.path}',
        start: Duration(milliseconds: startTimeMilliseconds)));
    player.setRate(prevRate.value);
    if (settings.preferences.get('shaders_enabled', defaultValue: false)) {
      final key = (PlayerShaders.getShaders()
          .indexWhere((e) => e == settings.selectedShader));
      setShaders(key, showMessage: false);
    }
  }

// Continuous Tracking
  int lastProcessedMinute = 0;
  bool isSwitchingEpisode = false;
  StreamSubscription<Duration>? _positionSubscription;
  bool _isSeeking = false;
  int lastProcessedSecond = -1;
  Duration _lastPosition = Duration.zero;
  DateTime _lastUIUpdate = DateTime.now();

  void _attachListeners() {
    _positionSubscription = player.stream.position.listen((e) {
      if (_isSeeking) return;

      if (_lastPosition.inSeconds != e.inSeconds) {
        _lastPosition = e;

        if (e.inSeconds % 30 == 0 && isPlaying.value && !isSwitchingEpisode) {
          trackEpisode(e, episodeDuration.value);
        }
      }

      final now = DateTime.now();
      if (mounted && now.difference(_lastUIUpdate).inMilliseconds >= 1000) {
        _lastUIUpdate = now;
        currentPosition.value = e;
        formattedTime.value = formatDuration(e);
        Logger.i('UI Updated with accurate stream position: ${e.inSeconds}s');
      }
    });

    player.stream.playing.listen((e) {
      isPlaying.value = e;

      if (e) {
        Future.delayed(const Duration(seconds: 2), () {
          isSwitchingEpisode = false;
        });
      }
    });

    player.stream.duration.listen((e) {
      episodeDuration.value = e;
      formattedDuration.value = formatDuration(e);
    });

    player.stream.tracks.listen((e) {
      if (e.audio.isEmpty) {
        audioTracks.value = e.audio
            .where((e) {
              final title = (e.language != null
                      ? completeSubtitleLanguageName(e.language!)
                      : (e.title ?? e.id))
                  .toLowerCase();
              return title != 'no' && title != 'auto' && title != 'none';
            })
            .toSet()
            .toList();
      }

      subtitleTracks.value = e.subtitle
          .where((e) {
            final title = (e.language != null
                    ? completeSubtitleLanguageName(e.language!)
                    : (e.title ?? e.id))
                .toLowerCase();
            return title != 'no' && title != 'auto' && title != 'none';
          })
          .toSet()
          .toList();

      if (audioTracks.isNotEmpty) {
        selectedAudioTrack.value = audioTracks.first;
      }

      if (subtitleTracks.isNotEmpty) {
        selectedSubTrack.value = subtitleTracks.first;
      }

      Logger.i("Audio tracks: ${e.audio.length}");
      Logger.i("Subtitle tracks: ${e.subtitle.length}");
    });

    player.stream.rate.listen((e) {
      playbackSpeed.value = e;
    });

    player.stream.subtitle.listen((e) {
      subtitleText.value = e;
    });
  }

  void startSeeking() {
    _isSeeking = true;
  }

  void endSeeking(Duration position) {
    currentPosition.value = position;
    formattedTime.value = formatDuration(position);
    _isSeeking = false;
  }

  void _initHiveVariables() {
    playerSettings = settings.playerSettings.value;
    resizeMode.value = settings.resizeMode;
    skipDuration.value = settings.seekDuration;
    prevRate.value = playerSettings.speed;
    currentVisualProfile.value = settings.preferences
        .get('currentVisualProfile', defaultValue: 'natural');
    customSettings.value = (settings.preferences
            .get('currentVisualSettings', defaultValue: {}) as Map)
        .cast<String, int>();
  }

  final Map<int, String> _durationCache = <int, String>{};

  String formatDuration(Duration duration) {
    final key = duration.inSeconds;
    if (_durationCache.containsKey(key)) {
      return _durationCache[key]!;
    }

    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    final result =
        duration.inHours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';

    if (_durationCache.length > 100) {
      _durationCache.clear();
    }

    _durationCache[key] = result;
    return result;
  }

  String extractQuality(String quality) {
    final extractedQuality =
        quality.split(" ").firstWhere((e) => e.contains("p"));
    return extractedQuality;
  }

  Future<void> setVolume(double value) async {
    try {
      VolumeController.instance.setVolume(value);
    } catch (_) {}
    _volumeValue.value = value;
    _volumeIndicator.value = true;
    _volumeInterceptEventStream = true;
    _volumeTimer?.cancel();
    _volumeTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted) {
        _volumeIndicator.value = false;
        _volumeInterceptEventStream = false;
      }
    });
  }

  Future<void> setBrightness(double value) async {
    try {
      await ScreenBrightness().setScreenBrightness(value);
    } catch (_) {}
    setState(() {
      _brightnessIndicator.value = true;
      _brightnessTimer?.cancel();
      _brightnessTimer = Timer(const Duration(milliseconds: 200), () {
        if (mounted) {
          _brightnessIndicator.value = false;
        }
      });
    });
  }

  void _handleVolumeAndBrightness() {
    Future.microtask(() async {
      try {
        VolumeController.instance.showSystemUI = false;
        _volumeValue.value = await VolumeController.instance.getVolume();
        VolumeController.instance.addListener((value) {
          if (mounted && !_volumeInterceptEventStream) {
            _volumeValue.value = value;
          }
        });
      } catch (_) {}
    });
    Future.microtask(() async {
      try {
        _brightnessValue.value = await ScreenBrightness.instance.current;
        ScreenBrightness.instance.onCurrentBrightnessChanged.listen((value) {
          if (mounted) {
            _brightnessValue.value = value;
          }
        });
      } catch (_) {}
    });
  }

  void _handleDoubleTap(TapDownDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tapPosition = details.globalPosition;
    final isLeft = tapPosition.dx < screenWidth / 2;
    _skipSegments(isLeft);
  }

  void _skipSegments(bool isLeft) {
    player.pause();
    if (isLeftSide.value != isLeft) {
      doubleTapLabel.value = 0;
      skipDuration.value = 0;
    }

    isLeftSide.value = isLeft;
    doubleTapLabel.value += settings.seekDuration;
    skipDuration.value += settings.seekDuration;

    final currentSeconds = currentPosition.value.inSeconds;
    final maxSeconds = episodeDuration.value.inSeconds;

    final newSeekPosition = isLeft
        ? (currentSeconds - skipDuration.value).clamp(0, maxSeconds)
        : (currentSeconds + skipDuration.value).clamp(0, maxSeconds);

    // Batch UI updates
    formattedTime.value = formatDuration(Duration(seconds: newSeekPosition));
    player.seek(Duration(seconds: newSeekPosition));

    // Optimize animations
    if (isLeft) {
      _leftAnimationController.forward(from: 0);
    } else {
      _rightAnimationController.forward(from: 0);
    }

    // Reset after delay
    doubleTapTimeout?.cancel();
    doubleTapTimeout = Timer(const Duration(milliseconds: 800), () {
      _leftAnimationController.reset();
      _rightAnimationController.reset();
      doubleTapLabel.value = 0;
      skipDuration.value = 0;
      player.play();
    });
  }

  void _megaSkip(bool invert) {
    if (invert) {
      final duration = Duration(
          seconds: currentPosition.value.inSeconds - settings.skipDuration);
      if (duration.inMilliseconds < 0) {
        currentPosition.value = const Duration(milliseconds: 0);
        player.seek(const Duration(seconds: 0));
      } else {
        currentPosition.value = duration;
        player.seek(duration);
      }
    } else {
      final duration = Duration(
          seconds: currentPosition.value.inSeconds + settings.skipDuration);
      currentPosition.value = duration;
      player.seek(duration);
    }
  }

  void toggleControls({bool? val}) {
    showControls.value = val ?? !showControls.value;

    if (showControls.value && isPlaying.value) {
      _startHideControlsTimer();
    }
  }

  void _startHideControlsTimer() {
    if (!isPlaying.value) {
      _hideControlsTimer?.cancel();
      return;
    }
    _hideControlsTimer?.cancel();

    _hideControlsTimer = Timer(const Duration(seconds: 5), () {
      if (isPlaying.value) {
        showControls.value = false;
      }
    });
  }

  @override
  void dispose() {
    _volumeTimer?.cancel();
    _brightnessTimer?.cancel();
    _hideControlsTimer?.cancel();
    doubleTapTimeout?.cancel();
    _positionSubscription?.cancel();

    trackEpisode(currentPosition.value, episodeDuration.value);

    player.dispose();
    _leftAnimationController.dispose();
    _rightAnimationController.dispose();

    if (isMobile && !settings.isTV.value) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
      ScreenBrightness().resetScreenBrightness();
    } else {
      AnymexTitleBar.setFullScreen(false);
    }
    _keyboardListenerFocusNode.dispose();
    super.dispose();
  }

  void setShaders(int key, {bool showMessage = true}) async {
    if (key == -1) {
      PlayerShaders.setShaders(player, '');
      if (showMessage) {
        snackBar("Cleared Shaders");
      }
      return;
    }
    final shaders = PlayerShaders.getShaders();
    PlayerShaders.setShaders(player, shaders[key]);
    if (showMessage) {
      snackBar('Applied ${shaders[key]}');
    }
  }

  Future<void> handlePlayerKeyEvent(
    KeyEvent e,
  ) async {
    if (e is! KeyDownEvent || settings.isTV.value) return;

    final key = e.logicalKey;

    if (key == LogicalKeyboardKey.space) {
      player.playOrPause();
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      _skipSegments(true);
    } else if (key == LogicalKeyboardKey.arrowRight) {
      _skipSegments(false);
    } else if (key == LogicalKeyboardKey.period || e.character == '>') {
      _megaSkip(false);
    } else if (key == LogicalKeyboardKey.comma || e.character == '<') {
      _megaSkip(true);
    }

    if (settings.preferences.get('shaders_enabled', defaultValue: false)) {
      final keyLabel = key.keyLabel;
      final allowedKeys = ["1", "2", "3", "4", "5", "6", "0"];
      Logger.i(keyLabel);
      if (allowedKeys.contains(keyLabel)) {
        setShaders(int.parse(keyLabel) - 1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _keyboardListenerFocusNode,
      autofocus: !settings.isTV.value,
      onKeyEvent: handlePlayerKeyEvent,
      child: Scaffold(
        body: Stack(
          alignment: Alignment.center,
          children: [
            _buildPlayer(context),
            _buildOverlay(context),
            _buildSubtitle(),
            _buildControls(),
            _buildRippleEffect(),
            _build2xThingy(),
            if (isMobile && settings.enableSwipeControls) ...[
              _buildBrightnessSlider(),
              _buildVolumeSlider(),
            ],
          ],
        ),
      ),
    );
  }

  Obx _buildSubtitle() {
    return Obx(() => AnimatedPositioned(
          right: 0,
          left: 0,
          top: 0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          bottom: showControls.value ? 100 : (30 + settings.bottomMargin),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedOpacity(
              opacity: subtitleText[0].isEmpty ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: subtitleText[0].isEmpty
                      ? Colors.transparent
                      : colorOptions[settings.subtitleBackgroundColor],
                  borderRadius: BorderRadius.circular(12.multiplyRadius()),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  switchInCurve: Curves.easeIn,
                  switchOutCurve: Curves.easeOut,
                  child: OutlinedText(
                    text: Text(
                      [
                        for (final line in subtitleText)
                          if (line.trim().isNotEmpty) line.trim(),
                      ].join('\n'),
                      key: ValueKey(subtitleText.join()),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: fontColorOptions[settings.subtitleColor],
                        fontSize: settings.subtitleSize.toDouble(),
                        fontFamily: "Poppins-Bold",
                      ),
                    ),
                    strokes: [
                      OutlinedTextStroke(
                          color:
                              fontColorOptions[settings.subtitleOutlineColor]!,
                          width: settings.subtitleOutlineWidth.toDouble())
                    ],
                  ),
                ),
              ),
            ),
          ),
        ));
  }

  Obx _build2xThingy() {
    return Obx(() {
      if (pressed2x.value) {
        return Positioned(
            top: 30,
            child: Container(
              width: 80,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AnymexText(
                    text: "${(prevRate.value * 2).toInt()}x",
                    variant: TextVariant.semiBold,
                  ),
                  const SizedBox(width: 5),
                  const Icon(Icons.fast_forward)
                ],
              ),
            ));
      } else {
        return const SizedBox.shrink();
      }
    });
  }

  Obx _buildPlayer(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Obx(() => Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: size.width,
              child: Video(
                controller: playerController,
                controls: null,
                fit: resizeModes[resizeMode.value]!,
                subtitleViewConfiguration: const SubtitleViewConfiguration(
                  visible: false,
                ),
              ),
            ),
          ],
        ));
  }

  final prevRate = 1.0.obs;

  Obx _buildOverlay(BuildContext context) {
    return Obx(
      () => AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          left: 0,
          top: 0,
          bottom: 0,
          right: 0,
          child: KeyboardListener(
            focusNode: FocusNode(
                skipTraversal: showControls.value,
                canRequestFocus: !showControls.value,
                descendantsAreFocusable: false,
                descendantsAreTraversable: false),
            autofocus: !showControls.value,
            onKeyEvent: (e) {
              if (settings.isTV.value) {
                if (!showControls.value) {
                  if (e.logicalKey == LogicalKeyboardKey.select ||
                      e.logicalKey == LogicalKeyboardKey.arrowLeft ||
                      e.logicalKey == LogicalKeyboardKey.arrowRight ||
                      e.logicalKey == LogicalKeyboardKey.arrowUp ||
                      e.logicalKey == LogicalKeyboardKey.arrowDown) {
                    toggleControls(val: true);
                  }
                }
              }
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onLongPressStart: (e) {
                pressed2x.value = true;
                player.setRate(prevRate.value * 2);
              },
              onLongPressEnd: (e) {
                pressed2x.value = false;
                player.setRate(prevRate.value);
              },
              onTap: toggleControls,
              onDoubleTapDown: (e) => _handleDoubleTap(e),
              onVerticalDragUpdate: (e) async {
                if (isMobile && settings.enableSwipeControls) {
                  final screenHeight = MediaQuery.of(context).size.height;
                  final topBoundary = screenHeight * 0.2;
                  final bottomBoundary = screenHeight * 0.8;

                  final position = e.localPosition;
                  if (position.dy >= topBoundary &&
                      position.dy <= bottomBoundary) {
                    final delta = e.delta.dy;

                    if (position.dx <= MediaQuery.of(context).size.width / 2) {
                      final brightness = _brightnessValue - delta / 500;
                      final result = brightness.clamp(0.0, 1.0);
                      setBrightness(result.toDouble());
                    } else {
                      final volume = _volumeValue - delta / 500;
                      final result = volume.clamp(0.0, 1.0);
                      setVolume(result.toDouble());
                    }
                  }
                }
              },
              child: AnimatedOpacity(
                curve: Curves.easeInOut,
                duration: const Duration(milliseconds: 300),
                opacity: showControls.value ? 1 : 0,
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
            ),
          )),
    );
  }

  Obx _buildVolumeSlider() {
    return Obx(() => AnimatedOpacity(
          curve: Curves.easeInOut,
          opacity: _volumeIndicator.value ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: MediaIndicatorBuilder(
            value: _volumeValue.value,
            isVolumeIndicator: true,
          ),
        ));
  }

  Obx _buildBrightnessSlider() {
    return Obx(() => AnimatedOpacity(
          curve: Curves.easeInOut,
          opacity: _brightnessIndicator.value ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: MediaIndicatorBuilder(
            value: _brightnessValue.value,
            isVolumeIndicator: false,
          ),
        ));
  }

  Widget _buildRippleEffect() {
    return Obx(() {
      if (doubleTapLabel.value == 0) {
        return const SizedBox();
      }
      return AnimatedPositioned(
        left: isLeftSide.value ? 0 : MediaQuery.of(context).size.width / 1.5,
        width: MediaQuery.of(context).size.width / 2.5,
        top: 0,
        bottom: 0,
        duration: const Duration(milliseconds: 1000),
        child: AnimatedBuilder(
          animation: isLeftSide.value
              ? _leftAnimationController
              : _rightAnimationController,
          builder: (context, child) {
            final scale = Tween<double>(begin: 1.5, end: 1).animate(
              CurvedAnimation(
                parent: isLeftSide.value
                    ? _leftAnimationController
                    : _rightAnimationController,
                curve: Curves.easeInOut,
              ),
            );

            return GestureDetector(
              onDoubleTapDown: (t) => _handleDoubleTap(t),
              child: Opacity(
                opacity: 1.0 -
                    (isLeftSide.value
                        ? _leftAnimationController.value
                        : _rightAnimationController.value),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isLeftSide.value ? 0 : 100),
                      topRight: Radius.circular(isLeftSide.value ? 100 : 0),
                      bottomLeft: Radius.circular(isLeftSide.value ? 0 : 100),
                      bottomRight: Radius.circular(isLeftSide.value ? 100 : 0),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ScaleTransition(
                        scale: scale,
                        child: Icon(
                          isLeftSide.value
                              ? Icons.fast_rewind_rounded
                              : Icons.fast_forward_rounded,
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
                        child: Text(
                          "${doubleTapLabel.value}s",
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
              ),
            );
          },
        ),
      );
    });
  }

  void playerSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      clipBehavior: Clip.antiAlias,
      isScrollControlled: true,
      builder: (context) {
        return Wrap(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: const SettingsPlayer(isModal: true),
              ),
            ),
          ],
        );
      },
    );
  }

  // Helper Methods
  Color _getFgColor() {
    return settings.playerStyle == 0
        ? Colors.white
        : Theme.of(context).colorScheme.primary;
  }

  Widget _buildControls() {
    return Obx(() {
      final themeFgColor = _getFgColor().obs;
      final width = MediaQuery.of(context).size.width;

      return AnimatedPositioned(
        duration: const Duration(milliseconds: 300),
        left: 0,
        top: 0,
        bottom: 0,
        right: 0,
        child: IgnorePointer(
          ignoring: !showControls.value,
          child: AnimatedOpacity(
            curve: Curves.easeInOut,
            opacity: showControls.value ? 1 : 0,
            duration: const Duration(milliseconds: 300),
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      // curve: Curves.,
                      transform: Matrix4.identity()
                        ..translate(0.0, showControls.value ? 0.0 : -100.0),
                      padding: const EdgeInsets.symmetric(
                          vertical: 15.0, horizontal: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isLocked.value) ...[
                            BlurWrapper(
                              child: IconButton(
                                  onPressed: () {
                                    Get.back();
                                  },
                                  icon: const Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      color: Colors.white)),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: getResponsiveSize(context,
                                  mobileSize: width * 0.3,
                                  desktopSize: (width * 0.6)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AnymexText(
                                    text: widget.episodePath.name,
                                    variant: TextVariant.semiBold,
                                    maxLines: 3,
                                    color: themeFgColor.value,
                                  ),
                                  5.height(),
                                  AnymexText(
                                    text: widget.episodePath.folderName,
                                    variant: TextVariant.semiBold,
                                    maxLines: 3,
                                    color: themeFgColor.value,
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const Spacer(),
                          BlurWrapper(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                _buildIcon(
                                    onTap: () {
                                      showPlaybackSpeedDialog(context);
                                    },
                                    icon: HugeIcons.strokeRoundedClock01),
                                _buildIcon(
                                    onTap: () {
                                      isLocked.value = !isLocked.value;
                                    },
                                    icon: isLocked.value
                                        ? Icons.lock
                                        : Icons.lock_open),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      transform: Matrix4.identity()
                        ..translate(0.0, showControls.value ? 0.0 : 100.0),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              AnymexTextSpans(
                                maxLines: 1,
                                spans: [
                                  AnymexTextSpan(
                                      text: '${formattedTime.value} ',
                                      variant: TextVariant.semiBold,
                                      color:
                                          themeFgColor.value.withOpacity(0.8)),
                                  AnymexTextSpan(
                                    variant: TextVariant.semiBold,
                                    text: ' /  ${formattedDuration.value}',
                                  ),
                                ],
                              ),
                              if (!isLocked.value) _buildSkipButton(false),
                            ],
                          ),
                          IgnorePointer(
                            ignoring: isLocked.value,
                            child: SizedBox(
                              height: 27,
                              child: VideoSliderTheme(
                                  color: themeFgColor.value,
                                  inactiveTrackColor:
                                      _getBgColor().withOpacity(0.1),
                                  child: Slider(
                                    focusNode: FocusNode(
                                        canRequestFocus: false,
                                        skipTraversal: true),
                                    min: 0,
                                    value: currentPosition.value.inMilliseconds
                                        .toDouble(),
                                    max: (currentPosition.value.inMilliseconds >
                                                episodeDuration
                                                    .value.inMilliseconds
                                            ? currentPosition
                                                .value.inMilliseconds
                                            : episodeDuration
                                                .value.inMilliseconds)
                                        .toDouble(),
                                    onChangeStart: (_) {
                                      startSeeking();
                                    },
                                    onChangeEnd: (val) async {
                                      if (episodeDuration.value.inMilliseconds
                                              .toDouble() !=
                                          0.0) {
                                        final newPosition =
                                            Duration(milliseconds: val.toInt());
                                        player.seek(newPosition);
                                        endSeeking(newPosition);
                                      }
                                    },
                                    onChanged: (val) {
                                      if (episodeDuration.value.inMilliseconds
                                              .toDouble() !=
                                          0.0) {
                                        currentPosition.value =
                                            Duration(milliseconds: val.toInt());
                                        formattedTime.value = formatDuration(
                                            currentPosition.value);
                                      }
                                    },
                                  )),
                            ),
                          ),
                          const SizedBox(height: 5),
                          if (!isLocked.value)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                BlurWrapper(
                                  child: Row(
                                    children: [
                                      _buildIcon(
                                          onTap: () {
                                            playerSettingsSheet(context);
                                          },
                                          icon: HugeIcons
                                              .strokeRoundedSettings01),
                                      _buildIcon(
                                          onTap: () {
                                            showSubtitleSelector();
                                          },
                                          icon:
                                              HugeIcons.strokeRoundedSubtitle),
                                      _buildIcon(
                                          onTap: () {
                                            showAudioSelector();
                                          },
                                          icon: Iconsax.music),
                                    ],
                                  ),
                                ),
                                BlurWrapper(
                                  child: Row(
                                    children: [
                                      if (Platform.isAndroid ||
                                          Platform.isIOS) ...[
                                        _buildIcon(
                                            onTap: () async {
                                              SystemChrome
                                                  .setPreferredOrientations([
                                                DeviceOrientation.portraitUp,
                                              ]);
                                            },
                                            icon: Icons.phone_android),
                                        _buildIcon(
                                            onTap: () async {
                                              leftOriented.value =
                                                  !leftOriented.value;
                                              if (!leftOriented.value) {
                                                SystemChrome
                                                    .setPreferredOrientations([
                                                  DeviceOrientation
                                                      .landscapeLeft,
                                                ]);
                                              } else {
                                                SystemChrome
                                                    .setPreferredOrientations([
                                                  DeviceOrientation
                                                      .landscapeRight,
                                                ]);
                                              }
                                            },
                                            icon: Icons.screen_rotation),
                                      ],
                                      _buildIcon(
                                          onTap: () =>
                                              showColorProfileSheet(context),
                                          icon: Icons.hdr_on_rounded),
                                      _buildIcon(
                                          onTap: () {
                                            final newIndex =
                                                (resizeModeList.indexOf(
                                                            resizeMode.value) +
                                                        1) %
                                                    resizeModeList.length;
                                            resizeMode.value =
                                                resizeModeList[newIndex];
                                          },
                                          icon: Icons.aspect_ratio_rounded),
                                      if (!Platform.isAndroid &&
                                          !Platform.isIOS)
                                        _buildIcon(
                                            onTap: () async {
                                              isFullscreen.value =
                                                  !isFullscreen.value;
                                              await AnymexTitleBar
                                                  .setFullScreen(
                                                      isFullscreen.value);
                                            },
                                            icon: !isFullscreen.value
                                                ? Icons.fullscreen
                                                : Icons
                                                    .fullscreen_exit_rounded),
                                    ],
                                  ),
                                ),
                              ],
                            )
                        ],
                      ),
                    )
                  ],
                ),
                if (!isLocked.value) ...[_buildPlaybackButtons()],
                if (settings.isTV.value)
                  Positioned(
                      right: 10,
                      top: MediaQuery.of(context).size.height * 0.48,
                      child: _buildIcon(icon: Icons.arrow_back_ios))
              ],
            ),
          ),
        ),
      );
    });
  }

  _buildSkipButton(bool invert) {
    return BlurWrapper(
      borderRadius: BorderRadius.circular(20.multiplyRoundness()),
      child: AnymeXButton(
        height: 50,
        width: 120,
        variant: ButtonVariant.simple,
        borderRadius: BorderRadius.circular(20.multiplyRoundness()),
        backgroundColor: Colors.transparent,
        onTap: () {
          if (invert) {
            final duration = Duration(
                seconds:
                    currentPosition.value.inSeconds - settings.skipDuration);
            if (duration.inMilliseconds < 0) {
              currentPosition.value = const Duration(milliseconds: 0);
              player.seek(const Duration(seconds: 0));
            } else {
              currentPosition.value = duration;
              player.seek(duration);
            }
          } else {
            final duration = Duration(
                seconds:
                    currentPosition.value.inSeconds + settings.skipDuration);
            currentPosition.value = duration;
            player.seek(duration);
          }
        },
        child: invert
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.fast_rewind_rounded,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 5),
                  AnymexText(
                    text: "-${settings.skipDuration}s",
                    variant: TextVariant.semiBold,
                    color: Colors.white,
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnymexText(
                    text: "+${settings.skipDuration}s",
                    variant: TextVariant.semiBold,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 5),
                  const Icon(
                    Icons.fast_forward_rounded,
                    color: Colors.white,
                  )
                ],
              ),
      ),
    );
  }

  void showPlaybackSpeedDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: getResponsiveValue(context,
                mobileValue: null, desktopValue: 500.0),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Playback Speed',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: SuperListView.builder(
                    shrinkWrap: true,
                    itemCount: cursedSpeed.length,
                    itemBuilder: (context, index) {
                      final e = cursedSpeed[index];

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3.0),
                        child: _buildSpeedOption(
                            context, player, e, playbackSpeed.value),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpeedOption(BuildContext context, Player playerController,
      double speed, double currentSpeed) {
    return ListTileWithCheckMark(
      active: speed == currentSpeed,
      leading: const Icon(Icons.speed),
      onTap: () {
        prevRate.value = speed;
        player.setRate(speed);
        Navigator.of(context).pop();
      },
      title: '${speed.toStringAsFixed(2)}x',
      color: Theme.of(context).colorScheme.primary,
    );
  }

  // Helper Methods
  Color _getPlayFgColor() {
    return settings.playerStyle == 0
        ? Colors.white
        : Theme.of(context).colorScheme.onPrimary;
  }

  Color _getBgColor() {
    return settings.playerStyle == 0
        ? Colors.transparent
        : Theme.of(context).colorScheme.primary;
  }

  Widget _buildPlaybackButtons() {
    final themeFgColor = _getPlayFgColor().obs;
    final themeBgColor = _getBgColor().obs;

    return Positioned.fill(
      child: AnimatedContainer(
        transform: Matrix4.identity()
          ..translate(0.0, showControls.value ? 0.0 : 50.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: Alignment.center,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            _buildPlaybackButton(
                icon: Icons.skip_previous_rounded,
                color: Colors.white,
                onTap: () async {
                  //TODO: Add Local Episode Navigator
                }),
            Obx(
              () => buildPlayButton(
                isPlaying: isPlaying,
                color: themeBgColor.value,
                iconColor: themeFgColor.value,
              ),
            ),
            _buildPlaybackButton(
              icon: Icons.skip_next_rounded,
              color: Colors.white,
              onTap: () async {
                //TODO: Add Local Episode Navigator
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPlayButton({
    required RxBool isPlaying,
    Color? color,
    Color? iconColor,
  }) {
    final isMobile = Platform.isAndroid || Platform.isIOS;
    final padding = getResponsiveSize(
      context,
      mobileSize: 10,
      desktopSize: 20,
      isStrict: true,
    );
    final radius = getResponsiveSize(
      context,
      mobileSize: 20.multiplyRadius(),
      desktopSize: 40.multiplyRadius(),
      isStrict: true,
    );

    return Obx(() {
      return Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 50),
        child: BlurWrapper(
          borderRadius: BorderRadius.circular(radius),
          child: AnymexOnTap(
            onTap: () {
              player.playOrPause();
            },
            bgColor: Colors.transparent,
            focusedBorderColor: Colors.transparent,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              ),
              child: IconButton(
                key: ValueKey(isPlaying.value),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(radius),
                  ),
                  padding: EdgeInsets.all(padding),
                ),
                onPressed: () {
                  player.playOrPause();
                },
                icon: Icon(
                  isPlaying.value
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: iconColor ?? color,
                  size: getResponsiveSize(
                    context,
                    mobileSize: 40,
                    desktopSize: 80,
                    isStrict: true,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildPlaybackButton({
    required Function() onTap,
    IconData? icon,
    Color? color,
    Color? iconColor,
  }) {
    final isPlay =
        icon == Icons.play_arrow_rounded || icon == Icons.pause_rounded;
    final isMobile = Platform.isAndroid || Platform.isIOS;
    final padding = getResponsiveSize(context,
        mobileSize: isPlay ? 10 : 5,
        desktopSize: isPlay ? 20 : 10,
        isStrict: true);
    final radius = getResponsiveSize(context,
        mobileSize: 20.multiplyRadius(),
        desktopSize: 40.multiplyRadius(),
        isStrict: true);

    return Container(
      decoration: BoxDecoration(
        color: isPlay
            ? color
            : settings.playerStyle == 0
                ? Colors.transparent
                : Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: isPlay ? [glowingShadow(context)] : [],
      ),
      clipBehavior: Clip.antiAlias,
      margin:
          EdgeInsets.symmetric(horizontal: isPlay ? (isMobile ? 20 : 50) : 0),
      child: BlurWrapper(
        borderRadius: BorderRadius.circular(radius),
        child: AnymexOnTap(
          onTap: onTap,
          bgColor: Colors.transparent,
          focusedBorderColor: Colors.transparent,
          child: IconButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius),
              ),
              padding: EdgeInsets.all(padding),
            ),
            onPressed: onTap,
            icon: Icon(
              icon,
              color: iconColor ?? color,
              size: getResponsiveSize(context,
                  mobileSize: 40, desktopSize: 80, isStrict: true),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon({VoidCallback? onTap, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 3),
      child: AnymexOnTap(
        onTap: () {
          onTap?.call();
        },
        child: IconButton(
            onPressed: onTap,
            icon: Icon(
              icon,
              color: Colors.white,
            )),
      ),
    );
  }

  void showAudioSelector() {
    showModalBottomSheet(
        context: context,
        backgroundColor: Theme.of(context).colorScheme.surface,
        isScrollControlled: true,
        builder: (context) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const Center(
                  child: AnymexText(
                    text: "Choose Audio",
                    size: 18,
                    variant: TextVariant.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // "None" option
                    AnymexOnTap(
                      onTap: () {
                        Get.back();
                        player.setAudioTrack(AudioTrack.no());
                      },
                      child: audioTile(AudioTrack.no()),
                    ),
                    ...audioTracks.map((audio) {
                      return AnymexOnTap(
                        onTap: () {
                          selectedAudioTrack.value = audio;
                          Get.back();
                          player.setAudioTrack(audio);
                        },
                        child: audioTile(audio),
                      );
                    }),
                  ],
                ),
              ],
            ),
          );
        });
  }

  Widget audioTile(AudioTrack track) {
    return Obx(() {
      final isSelected = selectedAudioTrack.value == track;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(vertical: 2.5, horizontal: 10),
          title: AnymexText(
            text: track.title ??
                completeSubtitleLanguageName(track.language ?? 'None')
                    .toUpperCase(),
            variant: TextVariant.bold,
            size: 16,
            color: isSelected
                ? Colors.black
                : Theme.of(context).colorScheme.primary,
          ),
          tileColor: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          trailing: Icon(Iconsax.subtitle5,
              color: isSelected
                  ? Colors.black
                  : Theme.of(context).colorScheme.primary),
        ),
      );
    });
  }

  void showSubtitleSelector() {
    showModalBottomSheet(
        context: context,
        backgroundColor: Theme.of(context).colorScheme.surface,
        isScrollControlled: true,
        builder: (context) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const Center(
                  child: AnymexText(
                    text: "Choose Subtitle",
                    size: 18,
                    variant: TextVariant.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // "None" option
                    AnymexOnTap(
                      onTap: () {
                        Get.back();
                        player.setSubtitleTrack(SubtitleTrack.no());
                      },
                      child: subtitleTile(
                          const SubtitleTrack('NULL', 'NONE', 'NONE')),
                    ),
                    ...subtitleTracks.map((subtitle) {
                      return AnymexOnTap(
                        onTap: () {
                          selectedSubTrack.value = subtitle;
                          Get.back();
                          player.setSubtitleTrack(subtitle);
                        },
                        child: subtitleTile(subtitle),
                      );
                    }),
                    AnymexOnTap(
                      onTap: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: extensions,
                        );

                        if (result?.files.single.path != null) {
                          final file = result!.files.single;
                          final filePath = file.path!;
                          final subtitle =
                              SubtitleTrack(filePath, file.name, file.name);
                          subtitleTracks.add(subtitle);
                          selectedSubTrack.value = subtitle;
                          player.setSubtitleTrack(subtitle);
                          Get.back();
                        } else {
                          snackBar('No subtitle file selected.',
                              duration: 2000);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5.0),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 2.5, horizontal: 10),
                          title: AnymexText(
                            text: 'Add Subtitle',
                            variant: TextVariant.bold,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          tileColor:
                              Theme.of(context).colorScheme.surfaceContainer,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          trailing: Icon(Iconsax.subtitle5,
                              color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        });
  }

  Widget subtitleTile(SubtitleTrack track) {
    return Obx(() {
      final isSelected = selectedSubTrack.value == track;
      final title = track.language != null
          ? completeSubtitleLanguageName(track.language!)
          : track.title;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(vertical: 2.5, horizontal: 10),
          title: AnymexText(
            text: title?.toUpperCase() ?? track.id,
            variant: TextVariant.bold,
            size: 16,
            color: isSelected
                ? Colors.black
                : Theme.of(context).colorScheme.primary,
          ),
          tileColor: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          trailing: Icon(Iconsax.subtitle5,
              color: isSelected
                  ? Colors.black
                  : Theme.of(context).colorScheme.primary),
        ),
      );
    });
  }

  void showColorProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ColorProfileBottomSheet(
        activeSettings: customSettings.value,
        currentProfile: currentVisualProfile.value,
        player: player,
        onProfileSelected: (profile) {
          currentVisualProfile.value = profile;
          settings.preferences.put('currentVisualProfile', profile);
        },
        onCustomSettingsChanged: (sett) {
          customSettings.value = sett;
          settings.preferences.put('currentVisualSettings', sett);
        },
      ),
    );
  }
}
