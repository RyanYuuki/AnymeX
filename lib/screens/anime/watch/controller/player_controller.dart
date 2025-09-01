import 'dart:async';
import 'dart:io';

import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/service_handler/params.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/models/Media/media.dart' as anymex;
import 'package:anymex/models/Offline/Hive/episode.dart';
import 'package:anymex/models/Offline/Hive/video.dart' as model;
import 'package:anymex/models/player/player_adaptor.dart';
import 'package:anymex/screens/anime/watch/controller/player_utils.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/bottom_sheet.dart';
import 'package:anymex/screens/anime/watch/subtitles/model/online_subtitle.dart';
import 'package:anymex/utils/aniskip.dart' as aniskip;
import 'package:anymex/utils/color_profiler.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/shaders.dart';
import 'package:anymex/utils/string_extensions.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:dartotsu_extension_bridge/ExtensionManager.dart';
import 'package:dartotsu_extension_bridge/Models/DEpisode.dart' as d;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:rxdart/rxdart.dart' show ThrottleExtensions;
import 'package:screen_brightness/screen_brightness.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:window_manager/window_manager.dart';

extension PlayerControllerExtensions on PlayerController {
  bool get hasNextEpisode =>
      episodeList.indexOf(currentEpisode.value) < episodeList.length - 1;
  bool get hasPreviousEpisode => episodeList.indexOf(currentEpisode.value) > 0;

  Episode? get nextEpisode {
    final index = episodeList.indexOf(currentEpisode.value);
    return index < episodeList.length - 1 ? episodeList[index + 1] : null;
  }

  Episode? get previousEpisode {
    final index = episodeList.indexOf(currentEpisode.value);
    return index > 0 ? episodeList[index - 1] : null;
  }

  int get currentEpisodeIndex => episodeList.indexOf(currentEpisode.value);
}

class PlayerController extends GetxController with WidgetsBindingObserver {
  Rx<Episode> currentEpisode = Rx<Episode>(Episode(number: '1'));
  final List<Episode> episodeList;
  final anymex.Media anilistData;
  RxList<model.Video> episodeTracks = RxList();

  PlayerController(model.Video video, Episode episode, this.episodeList,
      this.anilistData, List<model.Video> episodes) {
    selectedVideo.value = video;
    currentEpisode.value = episode;
    episodeTracks.value = episodes;
  }

  late Player player;
  late VideoController playerController;

  Episode? get savedEpisode => offlineStorage.getWatchedEpisode(
      anilistData.id, currentEpisode.value.number);

  final offlineStorage = Get.find<OfflineStorageController>();

  PlayerSettings get playerSettings => settings.playerSettings.value;

  final Rx<Duration> currentPosition = Rx<Duration>(Duration.zero);
  String get formattedCurrentPosition =>
      PlayerUtils.formatDuration(currentPosition.value);

  final Rx<Duration> episodeDuration = Rx<Duration>(Duration.zero);
  String get formattedEpisodeDuration =>
      PlayerUtils.formatDuration(episodeDuration.value);

  final Rx<Duration> bufferred = Rx<Duration>(Duration.zero);
  final RxDouble playbackSpeed = 1.0.obs;
  final RxBool isBuffering = false.obs;
  final RxBool isPlaying = false.obs;
  final RxBool showControls = true.obs;
  final RxBool isSeeking = false.obs;
  final RxBool isFullScreen = false.obs;
  final RxInt skipDuration = 85.obs;
  final RxInt seekDuration = 10.obs;
  final RxList<String> subtitleText = RxList([]);
  Timer? _seekDebounce;

  Timer? _autoHideTimer;
  static const Duration _autoHideDuration = Duration(seconds: 7);

  final RxBool isMouseHovering = false.obs;

  final Rx<List<AudioTrack>> embeddedAudioTracks = Rx([]);
  final Rx<List<SubtitleTrack>> embeddedSubs = Rx([]);
  final Rx<List<VideoTrack>> embeddedQuality = Rx([]);

  final Rx<AudioTrack?> selectedAudioTrack = Rx(null);
  final Rx<SubtitleTrack?> selectedSubsTrack = Rx(null);
  final Rx<VideoTrack?> selectedQualityTrack = Rx(null);

  final Rx<model.Track> selectedExternalSub = Rx(model.Track());
  final Rx<model.Track> selectedExternalAudio = Rx(model.Track());
  final Rxn<model.Video> selectedVideo = Rxn();

  final Rx<List<model.Track>> externalSubs = Rx([]);

  final Rx<bool> isSubtitlePaneOpened = false.obs;
  final Rx<bool> isEpisodePaneOpened = false.obs;

  final OfflineStorageController offlineStorageController =
      Get.find<OfflineStorageController>();

  final RxBool canGoForward = false.obs;
  final RxBool canGoBackward = false.obs;

  final RxDouble volume = 1.0.obs;
  final RxDouble brightness = 1.0.obs;

  final brightnessIndicator = false.obs;
  final RxBool volumeIndicator = false.obs;

  final currentVisualProfile = 'natural'.obs;
  RxMap<String, int> customSettings = <String, int>{}.obs;

  bool _hasTrackedInitialOnline = false;
  bool _hasTrackedInitialLocal = false;

  // AniSkip
  aniskip.EpisodeSkipTimes? skipTimes;
  final isOPSkippedOnce = false.obs;
  final isEDSkippedOnce = false.obs;

  void applySavedProfile() => ColorProfileManager()
      .applyColorProfile(currentVisualProfile.value, player);

  final settings = Get.find<Settings>();
  Timer? _volumeTimer;
  Timer? _brightnessTimer;
  Timer? _controlsTimer;
  bool _wasControlsVisible = false;

  final Rx<BoxFit> videoFit = Rx<BoxFit>(BoxFit.contain);

  @override
  void onInit() {
    super.onInit();

    WidgetsBinding.instance.addObserver(this);

    _initDatabaseVars();
    _initOrientations();
    _initializePlayer();
    _initializeAniSkip();
    _initializeListeners();
    _extractSubtitles();
    _initializeSwipeStuffs();
    _initializeControlsAutoHide();
    updateNavigatorState();
    ever(selectedVideo, (_) {
      final audios = selectedVideo.value?.audios ?? [];
      embeddedAudioTracks.value = audios
          .map((e) => AudioTrack.uri(e.file ?? '', title: e.label))
          .toList();
    });
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      _trackLocally();
    }
  }

  void _initDatabaseVars() {
    videoFit.value = BoxFit.values.firstWhere(
        (e) => e.name == settings.resizeMode,
        orElse: () => BoxFit.contain);
    seekDuration.value = settings.seekDuration;
    skipDuration.value = settings.skipDuration;
    playbackSpeed.value = settings.speed;
    currentVisualProfile.value = settings.preferences
        .get('currentVisualProfile', defaultValue: 'natural');
    customSettings.value = (settings.preferences
            .get('currentVisualSettings', defaultValue: {}) as Map)
        .cast<String, int>();
  }

  void _initOrientations() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    ever(isFullScreen,
        (isFullScreen) => windowManager.setFullScreen(isFullScreen));
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  }

  void _handleAutoSkip() {
    if (skipTimes?.op != null && playerSettings.autoSkipOP) {
      if (playerSettings.autoSkipOnce && isOPSkippedOnce.value) {
        return;
      }
      if (currentPosition.value.inSeconds > skipTimes!.op!.start &&
          currentPosition.value.inSeconds < skipTimes!.op!.end) {
        final skipNeeded = skipTimes!.op!.end - currentPosition.value.inSeconds;
        final duration =
            Duration(seconds: currentPosition.value.inSeconds + skipNeeded);
        currentPosition.value = duration;
        player.seek(duration);
        isOPSkippedOnce.value = true;
      }
    }
    if (skipTimes?.ed != null && playerSettings.autoSkipED) {
      if (playerSettings.autoSkipOnce && isEDSkippedOnce.value) {
        return;
      }
      if (currentPosition.value.inSeconds > skipTimes!.ed!.start &&
          currentPosition.value.inSeconds < skipTimes!.ed!.end) {
        final skipNeeded = skipTimes!.ed!.end - currentPosition.value.inSeconds;
        final duration =
            Duration(seconds: currentPosition.value.inSeconds + skipNeeded);
        currentPosition.value = duration;
        player.seek(duration);
        isEDSkippedOnce.value = true;
      }
    }
  }

  void _initializeSwipeStuffs() {
    Future.microtask(() async {
      try {
        VolumeController.instance.showSystemUI = false;
        volume.value = await VolumeController.instance.getVolume();
        VolumeController.instance.addListener((value) {
          volume.value = value;
        });
      } catch (_) {}
    });
    Future.microtask(() async {
      try {
        brightness.value = await ScreenBrightness.instance.current;
        ScreenBrightness.instance.onCurrentBrightnessChanged.listen((value) {
          brightness.value = value;
        });
      } catch (_) {}
    });
  }

  void _initializePlayer() {
    player = Player(
        configuration: PlayerConfiguration(
            bufferSize: 1024 * 1024 * 64,
            config: true,
            configDir: settings.mpvPath.value));
    playerController = VideoController(player,
        configuration: VideoControllerConfiguration(
            hwdec: 'auto',
            enableHardwareAcceleration: Platform.isMacOS ? false : true,
            vo: Platform.isAndroid ? "gpu" : "libmpv",
            androidAttachSurfaceAfterVideoParameters: true));
    player.open(Media(selectedVideo.value!.url,
        httpHeaders: selectedVideo.value!.headers,
        start: Duration(
            milliseconds: savedEpisode?.timeStampInMilliseconds ?? 0)));

    _performInitialTracking();
    applySavedProfile();
  }

  void _initializeAniSkip() {
    isOPSkippedOnce.value = false;
    isEDSkippedOnce.value = false;
    final skipQuery = aniskip.SkipSearchQuery(
        idMAL: anilistData.idMal, episodeNumber: currentEpisode.value.number);
    aniskip.AniSkipApi().getSkipTimes(skipQuery).then((skipTimeResult) {
      skipTimes = skipTimeResult;
    }).onError((error, stackTrace) {
      debugPrint("An error occurred: $error");
      debugPrint("Stack trace: $stackTrace");
    });
  }

  void _performInitialTracking() {
    Future.microtask(() async {
      if (!_hasTrackedInitialLocal) {
        await _trackLocally();
        _hasTrackedInitialLocal = true;
      }

      if (!_hasTrackedInitialOnline) {
        await _trackOnline(false);
        _hasTrackedInitialOnline = true;
      }
    });
  }

  double get _currentProgressPercentage {
    if (episodeDuration.value.inMilliseconds == 0) return 0.0;
    return (currentPosition.value.inMilliseconds /
            episodeDuration.value.inMilliseconds) *
        100;
  }

  bool get _shouldMarkAsCompleted {
    return _currentProgressPercentage >= settings.markAsCompleted;
  }

  void _initializeListeners() {
    player.stream.position
        .throttleTime(const Duration(seconds: 1))
        .listen((pos) {
      if (isSeeking.value) return;
      currentPosition.value = pos;
      currentEpisode.value.timeStampInMilliseconds = pos.inMilliseconds;
      currentEpisode.value.durationInMilliseconds =
          episodeDuration.value.inMilliseconds;

      if (_shouldMarkAsCompleted) {
        _trackOnline(true);
      }

      if (isPlaying.value && skipTimes != null) {
        _handleAutoSkip();
      }
    });

    player.stream.duration.listen((dur) {
      episodeDuration.value = dur;
      currentEpisode.value.durationInMilliseconds = dur.inMilliseconds;
    });

    player.stream.buffer.throttleTime(const Duration(seconds: 1)).listen((buf) {
      bufferred.value = buf;
    });

    player.stream.playing.listen((e) {
      isPlaying.value = e;
      if (e) {
        _resetAutoHideTimer();
      }
    });

    player.stream.buffering.listen((e) {
      isBuffering.value = e;
    });

    player.stream.tracks.listen((e) {
      embeddedAudioTracks.value = e.audio;
      embeddedSubs.value = e.subtitle;
      embeddedQuality.value = e.video;
    });

    player.stream.rate.listen((e) {
      playbackSpeed.value = e;
    });

    player.stream.error.listen((e) {
      Logger.i(e);
      if (e.toString().contains('Failed to open')) {
        snackBar('Failed, Dont Bother..');
      }
    });

    player.stream.subtitle.listen((e) {
      subtitleText.value = e;
    });

    player.stream.completed.listen((e) {
      if (e) {
        hasNextEpisode ? navigator(true) : Get.back();
      }
    });
  }

  void _initializeControlsAutoHide() {
    ever(showControls, (visible) {
      if (visible) {
        _resetAutoHideTimer();
      } else {
        _cancelAutoHideTimer();
      }
    });

    ever(isMouseHovering, (hovering) {
      if (hovering) {
        _showControlsOnHover();
      } else {
        _resetAutoHideTimer();
      }
    });

    _resetAutoHideTimer();
  }

  void _resetAutoHideTimer() {
    if (!isPlaying.value) return;
    _cancelAutoHideTimer();

    if (showControls.value && !isMouseHovering.value) {
      _autoHideTimer = Timer(_autoHideDuration, () {
        if (!isMouseHovering.value &&
            !isSubtitlePaneOpened.value &&
            !isEpisodePaneOpened.value) {
          showControls.value = false;
        }
      });
    }
  }

  void _cancelAutoHideTimer() {
    _autoHideTimer?.cancel();
    _autoHideTimer = null;
  }

  void _showControlsOnHover() {
    if (!showControls.value) {
      showControls.value = true;
    }
    _cancelAutoHideTimer();
  }

  void onMouseEnter() {
    isMouseHovering.value = true;
  }

  void onMouseExit() {
    isMouseHovering.value = false;
  }

  void onUserInteraction() {
    if (!showControls.value) {
      showControls.value = true;
    }
    _resetAutoHideTimer();
  }

  void onVideoTap() {
    toggleControls();
    if (showControls.value) {
      _resetAutoHideTimer();
    }
  }

  Future<void> fetchEpisode(Episode episode) async {
    try {
      PlayerBottomSheets.showLoader();
      final data = await sourceController.activeSource.value!.methods
          .getVideoList(
              d.DEpisode(episodeNumber: episode.number, url: episode.link));
      episodeTracks.value = data.map((e) => model.Video.fromVideo(e)).toList();
      selectedVideo.value = episodeTracks.first;
      await _switchMedia(
          selectedVideo.value!.url, selectedVideo.value?.headers);
      PlayerBottomSheets.hideLoader();
    } catch (e) {
      Logger.i(e.toString());
    } finally {
      updateNavigatorState();
    }
  }

  List<model.Track> _processSubtitles(List<model.Video> tracks) {
    final allSubtitles = <model.Track>[];

    for (var track in tracks) {
      if (track.subtitles?.isEmpty ?? true) continue;

      final processedSubs = track.subtitles!
          .map((sub) =>
              sub..label = "${sub.label ?? 'Unknown'} (${track.quality})")
          .toList();

      allSubtitles.addAll(processedSubs);
    }

    allSubtitles.sort(_subtitleComparator);

    final seen = <String>{};
    return allSubtitles.where((sub) {
      if (seen.contains(sub.file)) return false;
      seen.add(sub.file ?? '');
      return true;
    }).toList();
  }

  int _subtitleComparator(model.Track a, model.Track b) {
    if (a.label == null || b.label == null) return -1;
    if (a.label == "English" && b.label != "English") return -1;
    if (b.label == "English" && a.label != "English") return 1;
    return a.label!.compareTo(b.label!);
  }

  void _extractSubtitles() {
    Future.microtask(() {
      externalSubs.value = _processSubtitles(episodeTracks);

      if (externalSubs.value.isNotEmpty) {
        final englishSub = externalSubs.value.firstWhereOrNull(
          (e) => e.label?.toLowerCase().contains('eng') ?? false,
        );
        setExternalSub(englishSub);
      }
    });
  }

  Future<void> _switchMedia(String url, Map<String, String>? headers,
      {Duration? startPosition}) async {
    await player.open(Media(''));
    await player.open(Media(url, httpHeaders: headers, start: startPosition));
  }

  void delete() {
    Future.microtask(() async {
      _trackLocally();
      _trackOnline((currentPosition.value).inMilliseconds /
              episodeDuration.value.inMilliseconds >=
          settings.markAsCompleted);
    });

    WidgetsBinding.instance.removeObserver(this);

    player.dispose();
    _seekDebounce?.cancel();
    _brightnessTimer?.cancel();
    _volumeTimer?.cancel();
    _controlsTimer?.cancel();
    _autoHideTimer?.cancel();
    _revertOrientations();
  }

  void _revertOrientations() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    windowManager.setFullScreen(false);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight
    ]);
  }

  void seekTo(Duration pos) {
    currentPosition.value = pos;

    _seekDebounce?.cancel();
    _seekDebounce = Timer(const Duration(milliseconds: 100), () {
      _seekTo(pos);
    });
  }

  void _seekTo(Duration pos) async => await player.seek(pos);

  void play() {
    player.play();
    onUserInteraction();
  }

  void pause() {
    player.pause();
    onUserInteraction();
  }

  void setRate(double rate) {
    playbackSpeed.value = rate;
    player.setRate(rate);
  }

  void megaSeek(int seconds) {
    seekTo(currentPosition.value + Duration(seconds: seconds));
  }

  void setVideoTrack(VideoTrack track) {
    player.setVideoTrack(track);
  }

  void setAudioTrack(AudioTrack track) {
    player.setAudioTrack(track);
  }

  void setSubtitleTrack(SubtitleTrack track) {
    player.setSubtitleTrack(track);
  }

  void toggleControls({bool? val}) {
    showControls.value = val ?? !showControls.value;
    if (showControls.value) {
      _resetAutoHideTimer();
    }
  }

  void togglePlayPause() {
    player.playOrPause();
    onUserInteraction();
  }

  void toggleMute() {
    player.setVolume(player.state.volume == 0 ? 1 : 0);
    onUserInteraction();
  }

  void toggleFullScreen() {
    isFullScreen.value = !isFullScreen.value;
    onUserInteraction();
  }

  void onVerticalDragStart(BuildContext context, DragStartDetails details) {
    if (settings.enableSwipeControls) {
      _controlsTimer?.cancel();
      _cancelAutoHideTimer();

      _wasControlsVisible = showControls.value;

      if (showControls.value) {
        toggleControls(val: false);
      }
    }
  }

  void onVerticalDragUpdate(BuildContext context, DragUpdateDetails e) async {
    if (settings.enableSwipeControls) {
      final screenHeight = MediaQuery.of(context).size.height;
      final topBoundary = screenHeight * 0.2;
      final bottomBoundary = screenHeight * 0.8;

      final position = e.localPosition;
      if (position.dy >= topBoundary && position.dy <= bottomBoundary) {
        final delta = e.delta.dy;

        if (position.dx <= MediaQuery.of(context).size.width / 2) {
          final bright = brightness.value - delta / 500;
          setBrightness(bright.clamp(0.0, 1.0).toDouble());
        } else {
          final vol = volume.value - delta / 500;
          setVolume(vol.clamp(0.0, 1.0).toDouble());
        }
      }
    }
  }

  void onVerticalDragEnd(BuildContext context, DragEndDetails details) {
    if (settings.enableSwipeControls) {
      _controlsTimer?.cancel();

      if (_wasControlsVisible && !showControls.value) {
        toggleControls(val: true);
      }

      _resetAutoHideTimer();
    }
  }

  Future<void> setVolume(double value) async {
    try {
      VolumeController.instance.setVolume(value);
    } catch (_) {}
    volume.value = value;
    volumeIndicator.value = true;
    _volumeTimer?.cancel();
    _volumeTimer = Timer(const Duration(milliseconds: 200), () {
      volumeIndicator.value = false;
    });
  }

  Future<void> setBrightness(double value) async {
    try {
      await ScreenBrightness.instance.setScreenBrightness(value);
    } catch (_) {}
    brightnessIndicator.value = true;
    _brightnessTimer?.cancel();
    _brightnessTimer = Timer(const Duration(milliseconds: 200), () {
      brightnessIndicator.value = false;
    });
    refresh();
  }

  void setExternalSub(model.Track? track) {
    if (track == null) {
      selectedExternalSub.value = model.Track();
      setSubtitleTrack(SubtitleTrack.no());
      return;
    }
    if (track.file?.isEmpty ?? true) {
      snackBar('Corrupted Subtitle!');
      return;
    }
    selectedExternalSub.value = track;
    setSubtitleTrack(SubtitleTrack.uri(track.file!, title: track.label));
  }

  void setServerTrack(model.Video track) async {
    if (track.url.isEmpty) {
      snackBar('Corrupted Quality!');
      return;
    }

    selectedVideo.value = track;
    await _switchMedia(track.url, track.headers,
        startPosition: player.state.position);
  }

  void setExternalAudio(model.Track track) {
    if (track.file?.isEmpty ?? true) {
      snackBar('Corrupted Audio!');
      return;
    }
    selectedExternalAudio.value = track;
    setAudioTrack(AudioTrack.uri(track.file!));
  }

  void toggleSubtitlePane() {
    isSubtitlePaneOpened.value = !isSubtitlePaneOpened.value;
    if (isSubtitlePaneOpened.value) {
      _cancelAutoHideTimer();
    } else {
      _resetAutoHideTimer();
    }
  }

  void addOnlineSub(OnlineSubtitle sub) {
    externalSubs.value.insert(
        0,
        model.Track(
          label: '${sub.label} (Online)',
          file: sub.url,
        ));
  }

  void navigator(bool forward) {
    if (forward) {
      changeEpisode(nextEpisode!);
    } else if (hasNextEpisode) {
      changeEpisode(previousEpisode!);
    }
    onUserInteraction();
  }

  void updateNavigatorState() {
    canGoForward.value = hasNextEpisode;
    canGoBackward.value = hasPreviousEpisode;
  }

  void changeEpisode(Episode episode) {
    _trackLocally();

    _trackOnline(_shouldMarkAsCompleted);

    isEpisodePaneOpened.value = false;
    resetListeners();
    player.open(Media(''));
    currentEpisode.value = episode;

    _hasTrackedInitialLocal = false;
    _hasTrackedInitialOnline = false;

    fetchEpisode(episode);
    onUserInteraction();
  }

  void resetListeners() {
    currentPosition.value = Duration.zero;
    episodeDuration.value = Duration.zero;
    bufferred.value = Duration.zero;
  }

  void openColorProfileBottomSheet(BuildContext context) {
    ColorProfileBottomSheet.showColorProfileSheet(context, this, player);
  }

  void toggleVideoFit() {
    videoFit.value =
        BoxFit.values[(videoFit.value.index + 1) % BoxFit.values.length];
  }

  Future<void> _trackLocally() async {
    try {
      final currentTimestamp = currentEpisode.value.timeStampInMilliseconds;
      final totalDuration = episodeDuration.value.inMilliseconds;

      if (currentTimestamp == null) return;

      if (currentTimestamp > 0 && currentTimestamp < totalDuration) {
        offlineStorage.addOrUpdateAnime(
            anilistData, episodeList, currentEpisode.value);
        offlineStorage.addOrUpdateWatchedEpisode(
            anilistData.id, currentEpisode.value);
        currentEpisode.value.currentTrack = selectedVideo.value;
        currentEpisode.value.videoTracks = episodeTracks;

        Logger.i(
            'Local tracking completed for episode ${currentEpisode.value.number} with timestamp: ${currentTimestamp}ms, duration: ${totalDuration}ms');
      } else {
        final episodeToSave = currentEpisode.value;
        episodeToSave.timeStampInMilliseconds = 0;

        offlineStorage.addOrUpdateAnime(
            anilistData, episodeList, episodeToSave);
        offlineStorage.addOrUpdateWatchedEpisode(anilistData.id, episodeToSave);
        episodeToSave.currentTrack = selectedVideo.value;
        episodeToSave.videoTracks = episodeTracks;

        Logger.i(
            'Local tracking completed for episode ${currentEpisode.value.number} with timestamp: ${currentTimestamp}ms, duration: ${totalDuration}ms');
      }
    } catch (e) {
      Logger.i('Failed to track locally: $e');
    }
  }

  Future<void> _trackOnline(bool hasCrossedLimit) async {
    try {
      final currEpisodeNum = currentEpisode.value.number.toInt();
      final service = anilistData.serviceType.onlineService;
      await service.updateListEntry(UpdateListEntryParams(
          listId: anilistData.id,
          progress: hasCrossedLimit ? currEpisodeNum : currEpisodeNum - 1,
          isAnime: true,
          status: hasCrossedLimit &&
                  anilistData.status == 'COMPLETED' &&
                  hasNextEpisode
              ? 'COMPLETED'
              : 'CURRENT',
          syncIds: [anilistData.idMal]));
      service.setCurrentMedia(anilistData.id.toString());
      Logger.i(
          'Online tracking completed for episode ${currentEpisode.value.number}, progress: ${hasCrossedLimit ? currEpisodeNum : currEpisodeNum - 1}');
    } catch (e) {
      Logger.i('Failed to track online: $e');
    }
  }
}
