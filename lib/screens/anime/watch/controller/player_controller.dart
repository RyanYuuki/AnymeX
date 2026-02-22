import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:anymex/controllers/discord/discord_rpc.dart';
import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/service_handler/params.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/database/isar_models/episode.dart';
import 'package:anymex/database/isar_models/video.dart' as model;
import 'package:anymex/models/Media/media.dart' as anymex;
import 'package:anymex/models/player/player_adaptor.dart';
import 'package:anymex/screens/anime/watch/controller/player_utils.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/bottom_sheet.dart';
import 'package:anymex/screens/anime/watch/player/base_player.dart';
import 'package:anymex/screens/anime/watch/player/better_player.dart';
import 'package:anymex/screens/anime/watch/player/media_kit_player.dart';
import 'package:anymex/screens/anime/watch/subtitles/model/online_subtitle.dart';
import 'package:anymex/utils/aniskip.dart' as aniskip;
import 'package:anymex/utils/color_profiler.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/string_extensions.dart';
import 'package:anymex/utils/subtitle_pre_translator.dart';
import 'package:anymex/utils/subtitle_translator.dart';
import 'package:anymex/widgets/custom_widgets/anymex_titlebar.dart';
import 'package:anymex/widgets/non_widgets/anymex_toast.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:dartotsu_extension_bridge/ExtensionManager.dart';
import 'package:dartotsu_extension_bridge/Models/DEpisode.dart' as d;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:rxdart/rxdart.dart' show ThrottleExtensions;
import 'package:screen_brightness/screen_brightness.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:volume_controller/volume_controller.dart';

import '../../../../database/isar_models/track.dart' as model;

extension PlayerControllerExtensions on PlayerController {
  bool get hasNextEpisode {
    final index =
        episodeList.indexWhere((e) => e.number == currentEpisode.value.number);
    return index != -1 && index < episodeList.length - 1;
  }

  bool get hasPreviousEpisode {
    final index =
        episodeList.indexWhere((e) => e.number == currentEpisode.value.number);
    return index > 0;
  }

  Episode? get nextEpisode {
    final index =
        episodeList.indexWhere((e) => e.number == currentEpisode.value.number);
    if (index == -1 || index >= episodeList.length - 1) return null;
    return episodeList[index + 1];
  }

  Episode? get previousEpisode {
    final index =
        episodeList.indexWhere((e) => e.number == currentEpisode.value.number);
    if (index <= 0) return null;
    return episodeList[index - 1];
  }

  int get currentEpisodeIndex =>
      episodeList.indexWhere((e) => e.number == currentEpisode.value.number);
}

class PlayerController extends GetxController with WidgetsBindingObserver {
  static final _htmlRx = RegExp(r'<[^>]*>');
  static final _assRx = RegExp(r'\{[^}]*\}');
  static final _newlineRx = RegExp(r'\\[nN]');

  Rx<Episode> currentEpisode = Rx<Episode>(Episode(number: '1'));
  final List<Episode> episodeList;
  final anymex.Media anilistData;
  RxList<model.Video> episodeTracks = RxList();
  final isOffline = false.obs;

  final String? folderName;
  final String? itemName;
  final String? offlineVideoPath;
  final bool shouldTrack;

  PlayerController(model.Video video, Episode episode, this.episodeList,
      this.anilistData, List<model.Video> episodes,
      {bool offline = false,
      this.folderName,
      this.itemName,
      this.offlineVideoPath,
      this.shouldTrack = false}) {
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
      url: videoPath,
      quality: 'Offline',
      originalUrl: videoPath,
      headerKeys: [],
      headerValues: [],
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

  late BasePlayer _basePlayer;

  Widget get videoWidget => _basePlayer.getVideoWidget(fit: videoFit.value);

  Episode? get savedEpisode => offlineStorage.getWatchedEpisode(
      anilistData.id, currentEpisode.value.number.toString());

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
  final RxString translatedSubtitle = ''.obs;
  final RxBool isPreTranslating = false.obs;
  final RxString preTranslateProgress = ''.obs;
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

  void applySavedProfile() {
    if (_basePlayer is MediaKitPlayer) {
      ColorProfileManager().applyColorProfile(currentVisualProfile.value,
          (_basePlayer as MediaKitPlayer).nativePlayer);
    } else {
      snackBar('Color profiles only available with Old player');
    }
  }

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
    if (PlayerKeys.useLibass.get(false)) {
      snackBar(
          "if subtitle is not showing up then disable libass in settings and restart",
          duration: 3000);
    }
  }

  static void initializePlayerControlsIfNeeded(Settings settings) {
    final String jsonString =
        PlayerUiKeys.bottomControlsSettings.get<String>('{}');
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
      PlayerUiKeys.bottomControlsSettings.set(json.encode(defaultConfig));
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
      if (!kDebugMode) {
        _trackLocally();
      }
    }
  }

  void _initDatabaseVars() {
    videoFit.value = BoxFit.values.firstWhere(
        (e) => e.name == settings.resizeMode,
        orElse: () => BoxFit.contain);
    seekDuration.value = settings.seekDuration;
    skipDuration.value = settings.skipDuration;
    playbackSpeed.value = settings.speed;
    currentVisualProfile.value =
        PlayerUiKeys.currentVisualProfile.get<String>('natural');
    customSettings.value = (PlayerUiKeys.currentVisualSettings
            .get<Map<String, dynamic>>({}) as Map)
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
        _basePlayer.seek(duration);
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
        _basePlayer.seek(duration);
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

  bool _shouldUseMediaKit() {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return true;
    }

    return PlayerKeys.useMediaKit.get<bool>(false);
  }

  void _initializePlayer() {
    final useMediaKit = _shouldUseMediaKit();

    final config = PlayerConfiguration(
      bufferSize: 1024 * 1024 * 32,
      useLibass: PlayerKeys.useLibass.get<bool>(false),
      hwdec: 'no',
      playerType: useMediaKit ? PlayerType.mediaKit : PlayerType.betterPlayer,
    );

    if (useMediaKit) {
      _basePlayer = MediaKitPlayer(
        configuration: config,
      );
    } else {
      _basePlayer = BetterPlayerImpl(configuration: config);
    }

    _basePlayer.initialize().then((_) {
      if (isOffline.value && offlineVideoPath != null) {
        final stamp =
            DynamicKeys.offlineVideoProgress.get<int?>(offlineVideoPath, null);
        _basePlayer.open(
          offlineVideoPath!,
          startPosition: Duration(milliseconds: stamp ?? 0),
        );
      } else {
        _basePlayer.open(
          selectedVideo.value!.url ?? "",
          headers: selectedVideo.value!.headers,
          startPosition: Duration(
              milliseconds: savedEpisode?.timeStampInMilliseconds ?? 0),
        );
      }

      _performInitialTracking();
      applySavedProfile();
    });
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
    bool? lastAutoTranslate;
    String? lastTranslateTo;

    _subscriptions.add(settingsController.playerSettings.listen((settings) {
      final bool autoTranslate = settings.autoTranslate;
      final String? translateTo = (settings as dynamic).translateTo;

      final bool autoWasEnabled = lastAutoTranslate == true;
      final bool autoNowEnabled = autoTranslate == true;

      final bool autoTurnedOn = (!autoWasEnabled && autoNowEnabled);
      final bool autoTurnedOff = (autoWasEnabled && !autoNowEnabled);
      final bool translateToChangedWhileEnabled = autoNowEnabled &&
          lastTranslateTo != null &&
          lastTranslateTo != translateTo;

      if (autoTurnedOn || translateToChangedWhileEnabled) {
        triggerPreTranslation();
      } else if (autoTurnedOff) {
        translatedSubtitle.value = '';
      }

      lastAutoTranslate = autoTranslate;
      lastTranslateTo = translateTo;
    }));

    _subscriptions.add(_basePlayer.positionStream
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

    _subscriptions.add(_basePlayer.durationStream.listen((dur) {
      episodeDuration.value = dur;
      currentEpisode.value.durationInMilliseconds = dur.inMilliseconds;
      _updateRpc();
    }));

    _subscriptions.add(_basePlayer.bufferStream
        .throttleTime(const Duration(seconds: 1))
        .listen((buf) {
      bufferred.value = buf;
    }));

    _subscriptions.add(_basePlayer.playingStream.listen((e) {
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

    _subscriptions.add(_basePlayer.bufferingStream.listen((e) {
      isBuffering.value = e;
    }));

    _subscriptions.add(_basePlayer.tracksStream.listen((e) {
      embeddedAudioTracks.value = e.audio;
      embeddedSubs.value = e.subtitle;
      embeddedQuality.value = e.video;
    }));

    _subscriptions.add(_basePlayer.rateStream.listen((e) {
      playbackSpeed.value = e;
    }));

    _subscriptions.add(_basePlayer.errorStream.listen((e) {
      Logger.i(e);
      if (e.toString().contains('Failed to open')) {
        snackBar('Failed, Dont Bother..');
      }
    }));

    int subtitleTranslateRequestId = 0;

    _subscriptions.add(_basePlayer.subtitleStream.listen((e) async {
      final sanitizedLines = e
          .map((line) => line
              .replaceAll(_htmlRx, '')
              .replaceAll(_assRx, '')
              .replaceAll(_newlineRx, '\n')
              .trim())
          .where((line) => line.isNotEmpty)
          .toList();

      subtitleText.value = sanitizedLines;
      final int currentRequestId = ++subtitleTranslateRequestId;

      final cleanedText = sanitizedLines.join('\n');

      if (!playerSettings.autoTranslate) {
        translatedSubtitle.value = '';
        return;
      }

      if (cleanedText.isEmpty && playerSettings.autoTranslate) {
        translatedSubtitle.value = "";
        return;
      }

      if (playerSettings.autoTranslate && cleanedText.isNotEmpty) {
        final lookupKey = cleanedText
            .replaceAll(_htmlRx, '')
            .replaceAll(_assRx, '')
            .replaceAll(_newlineRx, '\n')
            .trim();

        final cached = SubtitlePreTranslator.lookup(lookupKey);
        if (cached != null) {
          translatedSubtitle.value = cached
              .replaceAll(_htmlRx, '')
              .replaceAll(_assRx, '')
              .replaceAll(_newlineRx, '\n')
              .trim();
          return;
        }

        try {
          final translated = await SubtitleTranslator.translate(
            cleanedText,
            playerSettings.translateTo,
          );

          final sanitizedTranslated = translated
              .replaceAll(_htmlRx, '')
              .replaceAll(_assRx, '')
              .replaceAll(_newlineRx, '\n')
              .trim();

          if (currentRequestId == subtitleTranslateRequestId &&
              sanitizedTranslated.isNotEmpty) {
            translatedSubtitle.value = sanitizedTranslated;
            SubtitlePreTranslator.manualAdd(lookupKey, sanitizedTranslated);
          }
        } catch (_) {}
      }
    }));

    _subscriptions.add(_basePlayer.heightStream.listen((height) {
      videoHeight.value = height;
    }));

    _subscriptions.add(_basePlayer.completedStream.listen((e) {
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
    brightnessIndicator.value = false;
    volumeIndicator.value = false;
    toggleControls();
    if (showControls.value) {
      _resetAutoHideTimer();
    }
  }

  Future<void> fetchEpisode(Episode episode, {Duration? savedPosition}) async {
    if (isOffline.value) return;

    try {
      PlayerBottomSheets.showLoader();

      final data = await sourceController.activeSource.value!.methods
          .getVideoList(d.DEpisode(
              episodeNumber: episode.number.toString(), url: episode.link));

      if (data.isEmpty) {
        PlayerBottomSheets.hideLoader();
        snackBar('No servers found for this episode.');
        isEpisodePaneOpened.value = true;
        return;
      }

      resetListeners();
      _basePlayer.open('');
      setExternalSub(null);
      currentEpisode.value = episode;
      _hasTrackedInitialLocal = false;
      _hasTrackedInitialOnline = false;

      episodeTracks.value = data.map((e) => model.Video.fromVideo(e)).toList();

      final previousTrack = selectedVideo.value;
      final matched = _findBestMatchingTrack(episodeTracks, previousTrack);

      selectedVideo.value = matched;
      _extractSubtitles();

      final episodeTimestamp = savedEpisode?.timeStampInMilliseconds;
      final startPosition = episodeTimestamp != null && episodeTimestamp > 0
          ? Duration(milliseconds: episodeTimestamp)
          : (savedPosition ?? Duration.zero);

      await _switchMedia(matched.url ?? "", matched.headers,
          startPosition: startPosition);
    } catch (e) {
      snackBar('Failed to load episode. Check your connection.');
    } finally {
      PlayerBottomSheets.hideLoader();
      updateNavigatorState();
    }
  }

  model.Video _findBestMatchingTrack(
    List<model.Video> tracks,
    model.Video? previousTrack,
  ) {
    if (tracks.isEmpty) {
      throw Exception('No tracks available');
    }

    if (previousTrack == null) {
      return tracks.first;
    }

    final scoredTracks = <Map<String, dynamic>>[];

    for (final track in tracks) {
      int score = 0;
      final quality = track.quality!.toLowerCase();
      final prevQuality = previousTrack.quality!.toLowerCase();
      final isDub = prevQuality.contains('dub');

      if ((isDub && quality.contains('dub')) ||
          (!isDub && !quality.contains('dub'))) {
        score += 4;
      }

      final prevQualityRegex = RegExp(r'\d{3,4}p');
      final prevQualityMatch = prevQualityRegex.firstMatch(prevQuality);
      if (prevQualityMatch != null &&
          quality.contains(prevQualityMatch.group(0)!)) {
        score += 2;
      }

      final prevServer = prevQuality.split(' ').first;
      if (quality.startsWith(prevServer)) {
        score += 1;
      }

      scoredTracks.add({'track': track, 'score': score});
    }

    scoredTracks
        .sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    return scoredTracks.first['track'];
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
    if (_basePlayer is MediaKitPlayer) {
      await _basePlayer.open("");
    }
    await _basePlayer.open(url, headers: headers, startPosition: startPosition);
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
    await _basePlayer.dispose();
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

  void _seekTo(Duration pos) async => await _basePlayer.seek(pos);

  void play() {
    _basePlayer.play();
    onUserInteraction();
  }

  void pause() {
    _basePlayer.pause();
    onUserInteraction();
  }

  void setRate(double rate) {
    playbackSpeed.value = rate;
    _basePlayer.setRate(rate);
  }

  void megaSeek(int seconds) {
    seekTo(currentPosition.value + Duration(seconds: seconds));
  }

  void setVideoTrack(VideoTrack track) {
    _basePlayer.setVideoTrack(track);
  }

  void setAudioTrack(AudioTrack track) {
    _basePlayer.setAudioTrack(track);
  }

  void setSubtitleTrack(SubtitleTrack track) {
    _basePlayer.setSubtitleTrack(track);
  }

  void toggleControls({bool? val}) {
    showControls.value = val ?? !showControls.value;
    if (showControls.value) {
      _resetAutoHideTimer();
    }
  }

  void togglePlayPause() {
    _basePlayer.playOrPause();
    onUserInteraction();
  }

  void toggleMute() {
    final currentVolume = _basePlayer.state.volume;
    _basePlayer.setVolume(currentVolume == 0 ? 1 : 0);
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
      _basePlayer.setVolume(value);
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

      selectedSubsTrack.value = null;
      _basePlayer.setSubtitleTrack(SubtitleTrack.no());

      subtitleText.value = [];
      translatedSubtitle.value = '';

      SubtitlePreTranslator.clearCache();
      return;
    }

    if (track.file?.isEmpty ?? true) {
      snackBar('Corrupted Subtitle!');
      return;
    }

    selectedExternalSub.value = track;
    final subtitleTrack = SubtitleTrack.uri(track.file!, title: track.label);

    selectedSubsTrack.value = subtitleTrack;
    _basePlayer.setSubtitleTrack(subtitleTrack);

    if (playerSettings.autoTranslate && track.file != null) {
      startPreTranslation(track.file!);
    }
  }

  void triggerPreTranslation() {
    final subtitleUrl = selectedExternalSub.value.file;
    if (subtitleUrl != null &&
        subtitleUrl.isNotEmpty &&
        playerSettings.autoTranslate) {
      startPreTranslation(subtitleUrl);
    }
  }

  void startPreTranslation(String subtitleUrl) async {
    if (isPreTranslating.value) {
      return;
    }

    isPreTranslating.value = true;
    preTranslateProgress.value = 'Starting translation...';
    snackBar('Pre-translating subtitles...');

    try {
      final success = await SubtitlePreTranslator.preTranslateFromUrl(
        subtitleUrl,
        playerSettings.translateTo,
      );

      if (success) {
        snackBar(
            'Subtitles translated! (${SubtitlePreTranslator.totalEntries} entries)');
      } else {
        snackBar('Pre-translation failed, using real-time fallback');
      }
    } catch (e) {
      Logger.e('[PlayerController] Pre-translation error: $e');
      snackBar('Pre-translation error, using real-time fallback');
    }

    isPreTranslating.value = false;
    preTranslateProgress.value = '';
  }

  void setServerTrack(model.Video track) async {
    if (track.url?.isEmpty ?? true) {
      snackBar('Corrupted Quality!');
      return;
    }

    selectedVideo.value = track;
    _extractSubtitles();
    await _switchMedia(track.url.toString(), track.headers,
        startPosition: _basePlayer.state.position);
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
          snackBar(
              'Skipped $skippedCount filler episode${skippedCount > 1 ? 's' : ''}');
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
    _basePlayer.pause();
    _trackLocally();
    if (!isOffline.value) {
      _trackOnline(_shouldMarkAsCompleted);
    }
    isEpisodePaneOpened.value = false;
    fetchEpisode(episode, savedPosition: currentPosition.value);
    onUserInteraction();
  }

  void resetListeners() {
    currentPosition.value = Duration.zero;
    episodeDuration.value = Duration.zero;
    bufferred.value = Duration.zero;
  }

  void openColorProfileBottomSheet(BuildContext context) {
    if (_basePlayer is MediaKitPlayer) {
      ColorProfileBottomSheet.showColorProfileSheet(
          context, this, (_basePlayer as MediaKitPlayer).nativePlayer);
    } else {
      snackBar('Color profiles only available with MediaKit player');
    }
  }

  void toggleVideoFit() {
    videoFit.value =
        BoxFit.values[(videoFit.value.index + 1) % BoxFit.values.length];
    _basePlayer.toggleVideoFit(videoFit.value);
    AnymexToast.show(
        message: videoFit.value.name.capitalizeFirst ?? '',
        duration: const Duration(milliseconds: 700));
  }

  Future<void> _trackLocally() async {
    if (isOffline.value) {
      DynamicKeys.offlineVideoProgress
          .set(offlineVideoPath, currentPosition.value.inMilliseconds);
      return;
    }

    try {
      final episode = currentEpisode.value;
      final currentTimestamp = episode.timeStampInMilliseconds;
      final totalDuration = episodeDuration.value.inMilliseconds;

      if (currentTimestamp == null) return;
      if (episodeDuration.value.inMinutes < 1) return;

      Uint8List? screenshot;
      String? thumbnailBase64;

      if (settings.enableScreenshot) {
        screenshot = await _basePlayer.screenshot(
          includeSubtitles: true,
          format: 'image/png',
        );

        thumbnailBase64 = screenshot != null ? base64Encode(screenshot) : null;
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

      await offlineStorage.addOrUpdateAnime(
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

  Future<void> _trackOnline(bool hasCrossedLimit) async {
    if (!shouldTrack) return;
    if (isOffline.value) {
      Logger.i('Offline mode: skipping online tracking');
      return;
    }

    if (currentEpisode.value.number.toString() ==
        anilistData.serviceType.onlineService.currentMedia.value.episodeCount) {
      return;
    }

    try {
      final service = anilistData.serviceType.onlineService;
      final currEpisodeNum = (currentEpisode.value.number ?? "1").toInt();

      final int newProgress =
          hasCrossedLimit ? currEpisodeNum : currEpisodeNum - 1;

      final int previousProgress =
          int.tryParse(service.currentMedia.value.episodeCount ?? '0') ?? 0;

      if (newProgress <= previousProgress) {
        return;
      }

      await service.updateListEntry(UpdateListEntryParams(
          listId: anilistData.id,
          progress: newProgress,
          isAnime: true,
          status: hasCrossedLimit &&
                  anilistData.status == 'COMPLETED' &&
                  !hasNextEpisode
              ? 'COMPLETED'
              : 'CURRENT',
          syncIds: [anilistData.idMal]));

      service.setCurrentMedia(anilistData.id.toString());
      Logger.i(
          'Online tracking completed for episode ${currentEpisode.value.number}, progress updated to: $newProgress');
    } catch (e) {
      Logger.i('Failed to track online: $e');
    }
  }
}
