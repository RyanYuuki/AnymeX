import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:anymex/controllers/discord/discord_rpc.dart';
import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/service_handler/params.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/database/data_keys/player.dart';
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
import 'package:anymex/utils/string_extensions.dart';
import 'package:anymex/widgets/custom_widgets/anymex_titlebar.dart';
import 'package:anymex/widgets/non_widgets/anymex_toast.dart';
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
import 'package:sensors_plus/sensors_plus.dart';
import 'package:volume_controller/volume_controller.dart';

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
  final isOffline = false.obs;

  final String? folderName;
  final String? itemName;
  final String? offlineVideoPath;

  PlayerController(model.Video video, Episode episode, this.episodeList,
      this.anilistData, List<model.Video> episodes,
      {bool offline = false,
      this.folderName,
      this.itemName,
      this.offlineVideoPath}) {
    selectedVideo.value = video;
    currentEpisode.value = episode;
    episodeTracks.value = episodes;
    isOffline.value = offline;
  }

  factory PlayerController.offline({
    required String folderName,
    required String itemName,
    required String videoPath,
    required Episode episode,
    required List<Episode> episodeList,
    required anymex.Media anilistData,
  }) {
    final offlineVideo = model.Video(
      videoPath,
      'Offline',
      videoPath,
      headers: {},
    );

    return PlayerController(
      offlineVideo,
      episode,
      episodeList,
      anilistData,
      [offlineVideo],
      offline: true,
      folderName: folderName,
      itemName: itemName,
      offlineVideoPath: videoPath,
    );
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

  final RxBool canGoForward = false.obs;
  final RxBool canGoBackward = false.obs;

  final RxDouble volume = 0.0.obs;
  final RxDouble brightness = 0.0.obs;

  final brightnessIndicator = false.obs;
  final RxBool volumeIndicator = false.obs;

  final currentVisualProfile = 'natural'.obs;
  RxMap<String, int> customSettings = <String, int>{}.obs;

  bool _hasTrackedInitialOnline = false;
  bool _hasTrackedInitialLocal = false;

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
  bool isLeftLandscaped = true;

  final Rx<BoxFit> videoFit = Rx<BoxFit>(BoxFit.contain);

  final RxBool isLocked = false.obs;
  final Rx<int?> videoHeight = Rx<int?>(null);

  final _subscriptions = <StreamSubscription>[];

  @override
  void onInit() {
    super.onInit();
    initializePlayerControlsIfNeeded(settings);
    WidgetsBinding.instance.addObserver(this);
    _initDatabaseVars();
    _initOrientations();
    _initializePlayer();
    _updateRpc();
    if (!isOffline.value) {
      _initializeAniSkip();
    }
    _initializeListeners();
    if (!isOffline.value) {
      _extractSubtitles();
    }
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

  static void initializePlayerControlsIfNeeded(Settings settings) {
    final String jsonString =
        settings.preferences.get('bottomControlsSettings', defaultValue: '{}');
    final Map<String, dynamic> decodedConfig = json.decode(jsonString);

    if (decodedConfig.isEmpty) {
      final Map<String, dynamic> defaultConfig = {
        'leftButtonIds': ['playlist'],
        'rightButtonIds': [
          'shaders',
          'subtitles',
          'server',
          'quality',
          'speed',
          'audio_track',
          'orientation',
          'aspect_ratio'
        ],
        'hiddenButtonIds': [],
        'buttonConfigs': {
          'playlist': {'visible': true},
          'shaders': {'visible': true},
          'subtitles': {'visible': true},
          'server': {'visible': true},
          'quality': {'visible': true},
          'speed': {'visible': true},
          'audio_track': {'visible': true},
          'orientation': {'visible': true},
          'aspect_ratio': {'visible': true},
        },
      };
      settings.preferences
          .put('bottomControlsSettings', json.encode(defaultConfig));
    }
  }

  Future<void> _updateRpc() async {
    if (isOffline.value) {
      await DiscordRPCController.instance.updateBrowsingPresence(
        activity: 'Watching Offline Video',
        details: itemName ?? 'Offline Media',
      );
      return;
    }
    await DiscordRPCController.instance.updateAnimePresence(
      anime: anilistData,
      episode: currentEpisode.value,
      totalEpisodes: episodeList.length.toString(),
    );
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

  Future<void> _initOrientations() async {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    ever(isFullScreen,
        (isFullScreen) => AnymexTitleBar.setFullScreen(isFullScreen));

    final orientation = await _getClosestLandscapeOrientation();

    SystemChrome.setPreferredOrientations([orientation]);
  }

  Future<DeviceOrientation> _getClosestLandscapeOrientation() async {
    try {
      final event = await accelerometerEvents.first
          .timeout(const Duration(milliseconds: 100));

      const double threshold = 0.3;

      if (event.x > threshold) {
        return DeviceOrientation.landscapeLeft;
      } else if (event.x < -threshold) {
        return DeviceOrientation.landscapeRight;
      }

      if (event.y.abs() < 0.5) {
        final view = WidgetsBinding.instance.platformDispatcher.views.first;
        return view.physicalSize.width > view.physicalSize.height
            ? DeviceOrientation.landscapeLeft
            : DeviceOrientation.landscapeLeft;
      }
    } catch (_) {}

    return DeviceOrientation.landscapeLeft;
  }

  void toggleOrientation() {
    if (isLeftLandscaped) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeRight]);
      isLeftLandscaped = false;
    } else {
      SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft]);
      isLeftLandscaped = true;
    }
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

  void _initializeSwipeStuffs() async {
    try {
      VolumeController.instance.showSystemUI = false;
      volume.value = await VolumeController.instance.getVolume();
    } catch (_) {}

    try {
      brightness.value = await ScreenBrightness.instance.application;
      _subscriptions
          .add(ScreenBrightness.instance.onCurrentBrightnessChanged.listen(
        (value) {
          brightness.value = value;
        },
      ));
    } catch (_) {}
  }

  void _initializePlayer() {
    player = Player(
        configuration: PlayerConfiguration(
            bufferSize: 1024 * 1024 * 32,
            libass: PlayerKeys.useLibass.get(false)));
    playerController = VideoController(player,
        configuration: VideoControllerConfiguration(
            hwdec: 'no',
            androidAttachSurfaceAfterVideoParameters:
                Platform.isAndroid ? true : null));

    if (isOffline.value && offlineVideoPath != null) {
      final stamp = settingsController.preferences
          .get(offlineVideoPath, defaultValue: null);
      player.open(
          Media(offlineVideoPath!, start: Duration(milliseconds: stamp ?? 0)));
    } else {
      player.open(Media(selectedVideo.value!.url,
          httpHeaders: selectedVideo.value!.headers,
          start: Duration(
              milliseconds: savedEpisode?.timeStampInMilliseconds ?? 0)));
    }

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

      if (!_hasTrackedInitialOnline && !isOffline.value) {
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
    _subscriptions.add(player.stream.position
        .throttleTime(const Duration(seconds: 1))
        .listen((pos) {
      if (isSeeking.value) return;
      currentPosition.value = pos;
      currentEpisode.value.timeStampInMilliseconds = pos.inMilliseconds;
      currentEpisode.value.durationInMilliseconds =
          episodeDuration.value.inMilliseconds;

      if (_shouldMarkAsCompleted && !isOffline.value) {
        _trackOnline(true);
      }

      if (isPlaying.value && skipTimes != null && !isOffline.value) {
        _handleAutoSkip();
      }
    }));

    _subscriptions.add(player.stream.duration.listen((dur) {
      episodeDuration.value = dur;
      currentEpisode.value.durationInMilliseconds = dur.inMilliseconds;
      _updateRpc();
    }));

    _subscriptions.add(player.stream.buffer
        .throttleTime(const Duration(seconds: 1))
        .listen((buf) {
      bufferred.value = buf;
    }));

    _subscriptions.add(player.stream.playing.listen((e) {
      isPlaying.value = e;
      if (e) {
        _resetAutoHideTimer();
      }
      if (isOffline.value) return;
      if (!e) {
        DiscordRPCController.instance.updateAnimePresencePaused(
            anime: anilistData,
            episode: currentEpisode.value,
            totalEpisodes: episodeList.length.toString());
      } else {
        _updateRpc();
      }
    }));

    _subscriptions.add(player.stream.buffering.listen((e) {
      isBuffering.value = e;
    }));

    _subscriptions.add(player.stream.tracks.listen((e) {
      embeddedAudioTracks.value = e.audio;
      embeddedSubs.value = e.subtitle;
      embeddedQuality.value = e.video;
    }));

    _subscriptions.add(player.stream.rate.listen((e) {
      playbackSpeed.value = e;
    }));

    _subscriptions.add(player.stream.error.listen((e) {
      Logger.i(e);
      if (e.toString().contains('Failed to open')) {
        snackBar('Failed, Dont Bother..');
      }
    }));

    _subscriptions.add(player.stream.subtitle.listen((e) {
      subtitleText.value = e;
    }));

    _subscriptions.add(player.stream.height.listen((height) {
      videoHeight.value = height;
    }));

    _subscriptions.add(player.stream.completed.listen((e) {
      if (e && !isOffline.value) {
        hasNextEpisode ? navigator(true) : Get.back();
      }
    }));
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
    if (isOffline.value) {
      Logger.i('Offline mode: skipping episode fetch');
      return;
    }

    try {
      PlayerBottomSheets.showLoader();
      final data = await sourceController.activeSource.value!.methods
          .getVideoList(
              d.DEpisode(episodeNumber: episode.number, url: episode.link));
      episodeTracks.value = data.map((e) => model.Video.fromVideo(e)).toList();

      final previousTrack = selectedVideo.value;
      selectedVideo.value =
          _findBestMatchingTrack(episodeTracks, previousTrack);
      _extractSubtitles();
      await _switchMedia(
          selectedVideo.value!.url, selectedVideo.value?.headers);
      PlayerBottomSheets.hideLoader();
    } catch (e) {
      Logger.i(e.toString());
    } finally {
      updateNavigatorState();
    }
  }

  model.Video _findBestMatchingTrack(
      List<model.Video> tracks, model.Video? previousTrack) {
    if (previousTrack == null) {
      return tracks.first;
    }

    final scoredTracks = <Map<String, dynamic>>[];
    for (final track in tracks) {
      int score = 0;
      final quality = track.quality.toLowerCase();
      final prevQuality = previousTrack.quality.toLowerCase();
      final isDub = prevQuality.contains('dub');

      if ((isDub && quality.contains('dub')) ||
          (!isDub && !quality.contains('dub'))) {
        score += 4;
      }

      final prevQualityRegex = RegExp(r'\d{3,4}p');
      final prevQualityMatch = prevQualityRegex.firstMatch(prevQuality);
      if (prevQualityMatch != null) {
        if (quality.contains(prevQualityMatch.group(0)!)) {
          score += 2;
        }
      }

      final prevServer = prevQuality.split(' ').first;
      if (quality.startsWith(prevServer)) {
        score += 1;
      }

      scoredTracks.add({'track': track, 'score': score});
    }

    scoredTracks
        .sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    if (scoredTracks.isNotEmpty && scoredTracks.first['score'] > 0) {
      return scoredTracks.first['track'] as model.Video;
    } else {
      return tracks.first;
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

  @override
  Future<void> dispose() async {
    super.dispose();
    try {
      await _trackLocally();
      if (!isOffline.value) {
        final durationMs = episodeDuration.value.inMilliseconds;
        final hasCrossedLimit = durationMs > 0
            ? (currentPosition.value.inMilliseconds / durationMs >=
                settings.markAsCompleted)
            : false;
        await _trackOnline(hasCrossedLimit);
      }
    } catch (e) {
      Logger.e('Error saving during dispose: $e');
    }

    _revertOrientations();
    WidgetsBinding.instance.removeObserver(this);
    if (!isOffline.value) {
      DiscordRPCController.instance.updateMediaPresence(media: anilistData);
    }
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    player.dispose();
    _seekDebounce?.cancel();
    _brightnessTimer?.cancel();
    _volumeTimer?.cancel();
    _controlsTimer?.cancel();
    _autoHideTimer?.cancel();
    ScreenBrightness.instance.resetApplicationScreenBrightness();
  }

  Future<void> delete() async {
    await dispose();
  }

  void _revertOrientations() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (!Platform.isAndroid && !Platform.isIOS) {
      AnymexTitleBar.setFullScreen(false);
    }
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

  void onVerticalDragUpdate(BuildContext context, DragUpdateDetails e) {
    if (!settings.enableSwipeControls) return;

    final size = MediaQuery.of(context).size;
    final position = e.localPosition;
    if (position.dy < size.height * 0.2 || position.dy > size.height * 0.8) {
      return;
    }

    const sensitivity = 200.0;

    final delta = e.delta.dy;
    if (position.dx <= size.width / 2) {
      final bright = brightness.value - delta / sensitivity;
      setBrightness(bright.clamp(0.0, 1.0), isDragging: true);
    } else {
      final vol = (volume.value - delta / sensitivity).toPrecision(2);
      if (volume.value != vol) {
        volume.value = vol.clamp(0.0, 1.0);
        volumeIndicator.value = true;
        Future.microtask(
            () => VolumeController.instance.setVolume(volume.value));
      }
    }
  }

  void onVerticalDragEnd(BuildContext context, DragEndDetails details) {
    if (settings.enableSwipeControls) {
      _controlsTimer?.cancel();
      _hideVolumeIndicatorAfterDelay();
      _hideBrightnessIndicatorAfterDelay();

      if (_wasControlsVisible && !showControls.value) {
        toggleControls(val: true);
      }

      _resetAutoHideTimer();
    }
  }

  Future<void> setVolume(double value, {bool isDragging = false}) async {
    try {
      VolumeController.instance.setVolume(value);
    } catch (_) {}
    volume.value = value;
    volumeIndicator.value = true;
    _volumeTimer?.cancel();

    if (!isDragging) {
      _hideVolumeIndicatorAfterDelay();
    }
  }

  Future<void> setBrightness(double value, {bool isDragging = false}) async {
    brightness.value = value;
    brightnessIndicator.value = true;

    try {
      await ScreenBrightness.instance.setApplicationScreenBrightness(value);
    } catch (_) {}

    _brightnessTimer?.cancel();

    if (!isDragging) {
      _hideBrightnessIndicatorAfterDelay();
    }
    refresh();
  }

  void _hideVolumeIndicatorAfterDelay() {
    _volumeTimer?.cancel();
    _volumeTimer = Timer(const Duration(milliseconds: 500), () {
      volumeIndicator.value = false;
    });
  }

  void _hideBrightnessIndicatorAfterDelay() {
    _brightnessTimer?.cancel();
    _brightnessTimer = Timer(const Duration(milliseconds: 500), () {
      brightnessIndicator.value = false;
    });
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
    _extractSubtitles();
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
    
      if (playerSettings.autoSkipFiller) {
        final targetEpisode = _getNextNonFillerEpisode();
        if (targetEpisode != null) {
          changeEpisode(targetEpisode);
        } else if (hasNextEpisode) {
          changeEpisode(nextEpisode!);
        }
      } else {
        changeEpisode(nextEpisode!);
      }
    } else if (hasPreviousEpisode) {
      changeEpisode(previousEpisode!);
    }
    onUserInteraction();
  }

  
  Episode? _getNextNonFillerEpisode() {
    final currentIndex = currentEpisodeIndex;
    int skippedCount = 0;
    
    for (int i = currentIndex + 1; i < episodeList.length; i++) {
      final episode = episodeList[i];
      if (episode.filler != true) {
        if (skippedCount > 0) {
          snackBar('Skipped $skippedCount filler episode${skippedCount > 1 ? 's' : ''}');
        }
        return episode;
      }
      skippedCount++;
    }
    
   
    return nextEpisode;
  }

  void updateNavigatorState() {
    canGoForward.value = hasNextEpisode;
    canGoBackward.value = hasPreviousEpisode;
  }

  void changeEpisode(Episode episode) {
    _trackLocally();

    if (!isOffline.value) {
      _trackOnline(_shouldMarkAsCompleted);
    }

    isEpisodePaneOpened.value = false;
    resetListeners();
    player.open(Media(''));
    setExternalSub(null);
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
    AnymexToast.show(
        message: videoFit.value.name.capitalizeFirst ?? '',
        duration: const Duration(milliseconds: 700));
  }

  Future<void> _trackLocally() async {
    if (isOffline.value) {
      settingsController.preferences
          .put(offlineVideoPath, currentPosition.value.inMilliseconds);
      return;
    }

    try {
      final episode = currentEpisode.value;
      final currentTimestamp = episode.timeStampInMilliseconds;
      final totalDuration = episodeDuration.value.inMilliseconds;

      if (currentTimestamp == null) return;
      if (episodeDuration.value.inMinutes < 1) return;

      final Uint8List? screenshot = await player.screenshot(
        includeLibassSubtitles: true,
        format: 'image/png',
      );

      final String? thumbnailBase64 =
          screenshot != null ? base64Encode(screenshot) : null;

      if (screenshot == null) {
        Logger.w('Screenshot failed — thumbnail will not be saved');
      }

      final episodeToSave = Episode(
        number: episode.number,
        title: episode.title,
        link: episode.link,
        timeStampInMilliseconds:
            (currentTimestamp > 0 && currentTimestamp < totalDuration)
                ? currentTimestamp
                : 0,
        thumbnail: thumbnailBase64 ?? episode.thumbnail,
        currentTrack: selectedVideo.value,
        videoTracks: episodeTracks,
        durationInMilliseconds: episode.durationInMilliseconds,
        lastWatchedTime: DateTime.now().millisecondsSinceEpoch,
        source: episode.source,
        desc: episode.desc,
      );

      offlineStorage.addOrUpdateAnime(
        anilistData,
        episodeList,
        episodeToSave,
      );

      offlineStorage.addOrUpdateWatchedEpisode(
        anilistData.id,
        episodeToSave,
      );
      Logger.i(
        'Saved episode ${episodeToSave.number} | '
        'timestamp=${episodeToSave.timeStampInMilliseconds} | '
        'thumbnailLength=${episodeToSave.thumbnail?.length}',
      );
    } catch (e, st) {
      Logger.e('Failed to track locally $e', stackTrace: st);
    }
  }

  // Future<void> _trackLocally() async {
  //   if (isOffline.value) {
  //     settingsController.preferences
  //         .put(offlineVideoPath, currentPosition.value.inMilliseconds);
  //     return;
  //   }
  //   try {
  //     final currentTimestamp = currentEpisode.value.timeStampInMilliseconds;
  //     final totalDuration = episodeDuration.value.inMilliseconds;
  //     final thumbnail = await player.screenshot(
  //         includeLibassSubtitles: true, format: 'image/png');

  //     if (currentTimestamp == null) return;
  //     if (episodeDuration.value.inMinutes < 1) return;

  //     if (currentTimestamp > 0 && currentTimestamp < totalDuration) {
  //       if (thumbnail != null) {
  //         currentEpisode.value.thumbnail = base64Encode(thumbnail);
  //         print('Thumbnail saved for episode ${currentEpisode.value.number}');
  //         print(
  //             'Thumbnail  ${currentEpisode.value.thumbnail!.substring(0, 20)}...');
  //       }
  //       offlineStorage.addOrUpdateAnime(
  //           anilistData, episodeList, currentEpisode.value);
  //       offlineStorage.addOrUpdateWatchedEpisode(
  //           anilistData.id, currentEpisode.value);
  //       currentEpisode.value.currentTrack = selectedVideo.value;
  //       currentEpisode.value.videoTracks = episodeTracks;

  //       Logger.i(
  //           'Local tracking completed for episode ${currentEpisode.value.number} with timestamp: ${currentTimestamp}ms, duration: ${totalDuration}ms');
  //     } else {
  //       final episodeToSave = currentEpisode.value;
  //       episodeToSave.timeStampInMilliseconds = 0;

  //       if (thumbnail != null) {
  //         episodeToSave.thumbnail = base64Encode(thumbnail);
  //         print('Thumbnail saved for episode ${currentEpisode.value.number}');

  //         print(
  //             'Thumbnail  ${currentEpisode.value.thumbnail!.substring(0, 20)}...');
  //       }

  //       offlineStorage.addOrUpdateAnime(
  //           anilistData, episodeList, episodeToSave);
  //       offlineStorage.addOrUpdateWatchedEpisode(anilistData.id, episodeToSave);
  //       episodeToSave.currentTrack = selectedVideo.value;
  //       episodeToSave.videoTracks = episodeTracks;

  //       Logger.i(
  //           'Local tracking completed for episode ${currentEpisode.value.number} with timestamp: ${currentTimestamp}ms, duration: ${totalDuration}ms');
  //     }
  //   } catch (e) {
  //     Logger.i('Failed to track locally: $e');
  //   }
  // }

  Future<void> _trackOnline(bool hasCrossedLimit) async {
    if (isOffline.value) {
      Logger.i('Offline mode: skipping online tracking');
      return;
    }

    if (currentEpisode.value.number.toString() ==
        anilistData.serviceType.onlineService.currentMedia.value.episodeCount) {
      return;
    }
    try {
      final currEpisodeNum = currentEpisode.value.number.toInt();
      final service = anilistData.serviceType.onlineService;
      await service.updateListEntry(UpdateListEntryParams(
          listId: anilistData.id,
          progress: hasCrossedLimit ? currEpisodeNum : currEpisodeNum - 1,
          isAnime: true,
          status: hasCrossedLimit &&
                  anilistData.status == 'COMPLETED' &&
                  !hasNextEpisode
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
