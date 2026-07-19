import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:anymex/utils/torrent/torrent_url_detector.dart';
import 'package:anymex/utils/torrent/torrent_stream_resolver.dart';

import 'package:anymex/controllers/discord/discord_rpc.dart';
import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/service_handler/params.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/controllers/sync/gist_sync_controller.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/database/isar_models/episode.dart';
import 'package:anymex/database/isar_models/video.dart' as model;
import 'package:anymex/models/Media/media.dart' as anymex;
import 'package:anymex/models/player/player_adaptor.dart';
import 'package:anymex/screens/anime/watch/controller/player_utils.dart';
import 'package:anymex/utils/external_player.dart';
import 'package:anymex/utils/pip_controller.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/bottom_sheet.dart';
import 'package:anymex/screens/anime/watch/player/base_player.dart';
import 'package:anymex/screens/anime/watch/player/media_kit_player.dart';
import 'package:flutter_media_session/flutter_media_session.dart';
import 'package:flutter_media_session/flutter_media_session_platform_interface.dart';

import 'package:anymex/utils/aniskip.dart' as aniskip;
import 'package:anymex/utils/language.dart';
import 'package:anymex/utils/color_profiler.dart';
import 'package:anymex/utils/sub_parser.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/player_core_visual_settings.dart';
import 'package:anymex/utils/shaders.dart';
import 'package:anymex/utils/string_extensions.dart';
import 'package:anymex/utils/subtitle_pre_translator.dart';
import 'package:anymex/utils/subtitle_translator.dart';
import 'package:anymex/widgets/custom_widgets/anymex_titlebar.dart';
import 'package:anymex/widgets/non_widgets/anymex_toast.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex_extension_runtime_bridge/ExtensionManager.dart';
import 'package:anymex_extension_runtime_bridge/Models/DEpisode.dart' as d;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:rxdart/rxdart.dart' show ThrottleExtensions, WhereTypeExtension;
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
  final _mediaSession = FlutterMediaSession();
  bool _isMediaSessionActive = false;
  DateTime? _lastMediaSessionPositionUpdate;
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
    List<model.Track>? subtitles,
  }) {
    final offlineVideo = model.Video(
      url: videoPath,
      quality: 'Offline',
      originalUrl: videoPath,
      headerKeys: [],
      headerValues: [],
      subtitles: subtitles,
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

  BasePlayer get basePlayer => _basePlayer;

  late BasePlayer _basePlayer;
  final RxBool _isPlayerInitialized = false.obs;
  final RxBool isPipMode = false.obs;

  Widget get videoWidget {
    if (_isReloadingPlayer.value || !_isPlayerInitialized.value) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return _basePlayer.getVideoWidget(fit: videoFit.value);
  }

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
  double _sessionSpeed = 1.0;
  final RxBool isBuffering = false.obs;
  final RxBool isPlaying = false.obs;
  final RxBool showControls = true.obs;
  final RxBool isSeeking = false.obs;

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
  final RxString selectedAudioChannelLayout = 'auto'.obs;
  final Rx<SubtitleTrack?> selectedSubsTrack = Rx(null);
  final Rx<VideoTrack?> selectedQualityTrack = Rx(null);
  final Rx<model.Track> selectedExternalSub = Rx(model.Track());
  final Rx<model.Track> selectedExternalAudio = Rx(model.Track());
  final Rxn<model.Video> selectedVideo = Rxn();
  final Rx<List<model.Track>> externalSubs = Rx([]);
  final RxBool showAllStreamSubtitles = false.obs;
  final Rx<bool> isSourcePaneOpened = false.obs;
  final Rx<bool> isTracksPaneOpened = false.obs;
  final Rx<bool> isSyncSubsPaneOpened = false.obs;
  final RxList<SubtitleCue> parsedSubtitleCues = <SubtitleCue>[].obs;
  final Rx<bool> isEpisodePaneOpened = false.obs;
  final Rx<bool> isSpeedPaneOpened = false.obs;
  final RxBool canGoForward = false.obs;
  final RxBool canGoBackward = false.obs;
  final RxDouble volume = 0.0.obs;
  final RxDouble brightness = 0.0.obs;
  final brightnessIndicator = false.obs;
  final RxBool volumeIndicator = false.obs;
  final currentVisualProfile = 'natural'.obs;
  final RxString activeShaderName = 'Default'.obs;
  final RxBool showShaderOsd = false.obs;
  Timer? _shaderOsdTimer;
  final Rx<Duration> subtitleDelay = Duration.zero.obs;
  RxMap<String, int> customSettings = <String, int>{}.obs;
  bool _hasTrackedInitialOnline = false;
  bool _hasTrackedInitialLocal = false;
  bool _hasAutoSelectedPreferredSub = false;
  aniskip.EpisodeSkipTimes? skipTimes;
  final isOPSkippedOnce = false.obs;
  final isEDSkippedOnce = false.obs;
  final isRecapSkippedOnce = false.obs;
  final Rx<aniskip.SkipIntervals?> currentSkipInterval =
      Rx<aniskip.SkipIntervals?>(null);

  static const int autoSkipCountdownSeconds = 5;
  final RxInt autoSkipCountdownRemaining = 0.obs;
  Timer? _autoSkipCountdownTimer;
  bool _autoSkipCancelledForCurrentSegment = false;

  Worker? _subSyncWorker;

  bool get isAutoSkipCountdownActive => autoSkipCountdownRemaining.value > 0;

  bool get _isAutoSkipEnabledForCurrentSegment {
    final interval = currentSkipInterval.value;
    if (interval == null || skipTimes == null) return false;
    if (identical(skipTimes!.op, interval)) {
      if (!playerSettings.autoSkipOP) return false;
      if (playerSettings.autoSkipOnce && isOPSkippedOnce.value) return false;
      return true;
    }
    if (identical(skipTimes!.ed, interval)) {
      if (!playerSettings.autoSkipED) return false;
      if (playerSettings.autoSkipOnce && isEDSkippedOnce.value) return false;
      return true;
    }
    if (identical(skipTimes!.recap, interval)) {
      if (!playerSettings.autoSkipRecap) return false;
      if (playerSettings.autoSkipOnce && isRecapSkippedOnce.value) return false;
      return true;
    }
    return false;
  }

  void _cancelAutoSkipTimer() {
    _autoSkipCountdownTimer?.cancel();
    _autoSkipCountdownTimer = null;
    autoSkipCountdownRemaining.value = 0;
  }

  void cancelAutoSkipCountdown() {
    _cancelAutoSkipTimer();
    _autoSkipCancelledForCurrentSegment = true;
  }

  void applySavedProfile() {
    if (_basePlayer is MediaKitPlayer) {
      final nativePlayer = (_basePlayer as MediaKitPlayer).nativePlayer;
      ColorProfileManager()
          .applyColorProfile(currentVisualProfile.value, nativePlayer);
      applySavedShader(nativePlayer);
    }
  }

  Future<void> applySavedShader(dynamic nativePlayer) async {
    final shadersEnabled = PlayerUiKeys.shadersEnabled.get<bool>(false);
    if (!shadersEnabled) return;

    final shadersDownloaded = await PlayerShaders.areShadersDownloaded();
    if (!shadersDownloaded) return;

    final savedShader = PlayerUiKeys.selectedShader.get<String>('');
    if (savedShader.isEmpty || savedShader == 'Default') return;
    try {
      await PlayerShaders.setShaders(nativePlayer, savedShader);
      activeShaderName.value = savedShader;
      Logger.i('Auto-applied saved shader: $savedShader');
    } catch (e) {
      Logger.e('Failed to auto-apply shader: $e');
    }
  }

  Future<void> applyShader(String shaderName) async {
    final cleanShaderName = shaderName == "Default" ? "" : shaderName;
    settingsController.selectedShader = cleanShaderName;
    PlayerUiKeys.selectedShader.set(cleanShaderName);

    if (_basePlayer is MediaKitPlayer) {
      final nativePlayer = (_basePlayer as MediaKitPlayer).nativePlayer;
      try {
        await PlayerShaders.setShaders(nativePlayer, shaderName);
      } catch (e) {
        Logger.e('Failed to apply shader: $e');
      }
    }

    activeShaderName.value = shaderName;
    showShaderOsd.value = true;
    _shaderOsdTimer?.cancel();
    _shaderOsdTimer = Timer(const Duration(seconds: 2), () {
      showShaderOsd.value = false;
    });
  }

  void setAudioChannelLayout(String layout) {
    selectedAudioChannelLayout.value = layout;
    PlayerKeys.audioChannelLayout.set(layout);
    _basePlayer.setAudioChannelLayout(layout);
  }

  void applyShaderByIndex(int index) {
    final shaders = PlayerShaders.getShaders();
    if (index >= 0 && index < shaders.length) {
      applyShader(shaders[index]);
    }
  }

  void clearShaders() {
    applyShader("Default");
  }

  final settings = Get.find<Settings>();
  Timer? _volumeTimer;
  Timer? _brightnessTimer;
  Timer? _controlsTimer;
  bool _wasControlsVisible = false;
  bool isLeftLandscaped = true;
  final Rx<DeviceOrientation> currentOrientation =
      DeviceOrientation.landscapeLeft.obs;
  final Rx<DeviceOrientation> physicalOrientation =
      DeviceOrientation.portraitUp.obs;
  StreamSubscription? _accelerometerSub;

  final Rx<BoxFit> videoFit = Rx<BoxFit>(BoxFit.contain);
  final RxBool isLocked = false.obs;
  final Rx<int?> videoHeight = Rx<int?>(null);
  final _subscriptions = <StreamSubscription>[];
  final _playerSubscriptions = <StreamSubscription>[];
  final RxInt playerReloadVersion = 0.obs;
  bool _persistentListenersInitialized = false;
  final RxBool _isReloadingPlayer = false.obs;
  bool _activeUseLibass = false;

  @override
  void onInit() {
    super.onInit();
    PlayerController.initializePlayerControlsIfNeeded(settings);
    WidgetsBinding.instance.addObserver(this);
    _initDatabaseVars();
    _initOrientations();
    selectedAudioChannelLayout.value = PlayerKeys.audioChannelLayout.get<String>('auto');
    _activeUseLibass = PlayerKeys.useLibass.get<bool>(false);
    _initializePlayer();
    _updateRpc();
    if (!isOffline.value) {
      _initializeAniSkip();
    }
    _initializePersistentListeners();
    _initMediaSession();
    if (!isOffline.value) {
      _extractSubtitles();
    }
    _initializeSwipeStuffs();
    _initializeControlsAutoHide();
    updateNavigatorState();
    if (isOffline.value) {
      _loadLocalSubtitles();
    }
    ever(selectedVideo, (_) {
      final audios = selectedVideo.value?.audios ?? [];
      embeddedAudioTracks.value = audios
          .map((e) => AudioTrack.uri(e.file ?? '', title: e.label))
          .toList();
    });
    if (PlayerKeys.useLibass.get(false)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        snackBar(
            "if subtitle is not showing up then disable libass in settings and restart",
            duration: 3000);
      });
    }
    PipController.setAutoEnter(enabled: true);
    PipController.onPlay = () => play();
    PipController.onPause = () => pause();
    PipController.onForward = () => megaSeek(30);
    PipController.onBackward = () => megaSeek(-30);
    PipController.onPipModeChanged = (active) => isPipMode.value = active;
    PipController.initialize();
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
          'source',
          'tracks',
          'sync_subs',
          'speed',
          'orientation',
          'aspect_ratio',
          'external_player'
        ],
        'hiddenButtonIds': [],
        'buttonConfigs': {
          'playlist': {'visible': true},
          'shaders': {'visible': true},
          'source': {'visible': true},
          'tracks': {'visible': true},
          'sync_subs': {'visible': true},
          'speed': {'visible': true},
          'orientation': {'visible': true},
          'aspect_ratio': {'visible': true},
          'external_player': {'visible': true},
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

  Future<void> _initMediaSession() async {
    try {
      await _mediaSession.activate();
      _isMediaSessionActive = true;
      _mediaSession.setActionHandler(
        onPlay: () {
          play();
        },
        onPause: () {
          pause();
        },
        onSkipToNext: () {
          if (hasNextEpisode) {
            changeEpisode(nextEpisode!);
          }
        },
        onSkipToPrevious: () {
          if (hasPreviousEpisode) {
            changeEpisode(previousEpisode!);
          }
        },
        onSeekTo: (pos) {
          seekTo(pos);
        },
      );
      await _updateMediaSessionMetadata();
    } catch (e) {
      Logger.e('Failed to initialize media session: $e');
    }
  }

  Future<void> _deactivateMediaSession() async {
    if (!_isMediaSessionActive) return;
    _isMediaSessionActive = false;
    try {
      await _mediaSession.deactivate();
    } catch (e) {
      Logger.e('Failed to deactivate media session: $e');
    }
  }

  Future<void> _updateMediaSessionMetadata() async {
    if (!_isMediaSessionActive) return;
    try {
      final epTitle = currentEpisode.value.title ?? '';
      final epNum = currentEpisode.value.number;
      final showName = itemName ?? anilistData.title;
      final title = epTitle.isNotEmpty ? 'Ep $epNum: $epTitle' : 'Episode $epNum';
      final artworkUrl = isOffline.value ? 'https://raw.githubusercontent.com/RyanYuuki/AnymeX/refs/heads/main/assets/images/logo.png' : (anilistData.cover ?? anilistData.poster);

      await FlutterMediaSessionPlatform.instance.updateMetadata(
        MediaMetadata(
          title: title,
          artist: showName,
          album: showName,
          artworkUri: artworkUrl,
          duration: episodeDuration.value,
        ),
      );
    } catch (e) {
      Logger.e('Failed to update media session metadata: $e');
    }
  }

  Future<void> _updateMediaSessionState(bool playing, {Duration? position}) async {
    if (!_isMediaSessionActive) return;
    try {
      await FlutterMediaSessionPlatform.instance.updatePlaybackState(
        PlaybackState(
          status: playing ? PlaybackStatus.playing : PlaybackStatus.paused,
          position: position ?? currentPosition.value,
        ),
      );
    } catch (e) {
      Logger.e('Failed to update media session state: $e');
    }
  }

  @override
  void onClose() {
    _deactivateMediaSession();
    PipController.setAutoEnter(enabled: false);
    _accelerometerSub?.cancel();
    delete();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      isPipMode.value = false;
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      isPipMode.value = true;
      if (!kDebugMode) {
        _trackLocally();
      }
    }

    if (state == AppLifecycleState.detached) {
      _deactivateMediaSession();
    }
  }

  void _initDatabaseVars() {
    videoFit.value = BoxFit.values.firstWhere(
        (e) => e.name == settings.resizeMode,
        orElse: () => BoxFit.contain);
    seekDuration.value = settings.seekDuration;
    skipDuration.value = settings.skipDuration;
    playbackSpeed.value = settings.speed;
    _sessionSpeed = settings.speed;
    final savedProfile =
        PlayerUiKeys.currentVisualProfile.get<String>('natural').toLowerCase();
    currentVisualProfile.value =
        ColorProfileManager.profiles.containsKey(savedProfile)
            ? savedProfile
            : 'natural';
    customSettings.value = _loadVisualSettings();
  }

  Map<String, int> _loadVisualSettings() {
    try {
      final raw =
          PlayerUiKeys.currentVisualSettings.get<Map<String, dynamic>>({});

      final out = <String, int>{};
      for (final entry in raw.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        if (value is int) {
          out[key] = value;
          continue;
        }
        if (value is num) {
          out[key] = value.round();
          continue;
        }
        if (value is String) {
          final parsed = int.tryParse(value);
          if (parsed != null) out[key] = parsed;
        }
      }
      return out;
    } catch (e, stack) {
      Logger.e('Failed to load visual settings: $e');
      Logger.e('STACK: $stack');
      return <String, int>{};
    }
  }

  Future<void> _initOrientations() async {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initPhysicalOrientationListener();

    if (Platform.isAndroid || Platform.isIOS) {
      if (playerSettings.defaultPortraitMode) {
        _applyOrientation(DeviceOrientation.portraitUp);
      } else {
        final orientation = await _getClosestLandscapeOrientation();
        _applyOrientation(orientation);
      }
    }
  }

  void _initPhysicalOrientationListener() {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      _accelerometerSub = accelerometerEvents.listen((event) {
        final x = event.x;
        final y = event.y;
        if (x.abs() > y.abs()) {
          if (x > 5.0) {
            physicalOrientation.value = DeviceOrientation.landscapeLeft;
          } else if (x < -5.0) {
            physicalOrientation.value = DeviceOrientation.landscapeRight;
          }
        } else {
          if (y > 5.0) {
            physicalOrientation.value = DeviceOrientation.portraitUp;
          } else if (y < -5.0) {
            physicalOrientation.value = DeviceOrientation.portraitDown;
          }
        }
      });
    } catch (_) {}
  }

  Future<DeviceOrientation> _getClosestLandscapeOrientation() async {
    try {
      final samples = await accelerometerEvents
          .take(4)
          .timeout(
            const Duration(milliseconds: 250),
            onTimeout: (sink) => sink.close(),
          )
          .toList();

      if (samples.isNotEmpty) {
        final averageX =
            samples.map((event) => event.x).reduce((a, b) => a + b) /
                samples.length;

        const double slightLeanThreshold = 0.05;
        if (averageX >= slightLeanThreshold) {
          return DeviceOrientation.landscapeLeft;
        }
        if (averageX <= -slightLeanThreshold) {
          return DeviceOrientation.landscapeRight;
        }
      }
    } catch (_) {}

    return DeviceOrientation.landscapeLeft;
  }

  void _applyOrientation(DeviceOrientation orientation) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([orientation]);
    currentOrientation.value = orientation;
    isLeftLandscaped = orientation != DeviceOrientation.landscapeRight;
  }

  Duration overlayAnimationDuration(int milliseconds) {
    return playerSettings.playerMenuAnimation
        ? Duration(milliseconds: milliseconds)
        : Duration.zero;
  }

  void toggleOrientation() {
    if (currentOrientation.value != physicalOrientation.value) {
      _applyOrientation(physicalOrientation.value);
      return;
    }
    DeviceOrientation next;
    if (currentOrientation.value == DeviceOrientation.landscapeLeft) {
      next = DeviceOrientation.portraitUp;
    } else if (currentOrientation.value == DeviceOrientation.portraitUp) {
      next = DeviceOrientation.landscapeRight;
    } else {
      next = DeviceOrientation.landscapeLeft;
    }
    _applyOrientation(next);
  }

  void _performSegmentSkip(aniskip.SkipIntervals interval) {
    final duration = Duration(seconds: interval.end);
    currentPosition.value = duration;
    _basePlayer.seek(duration);
    if (identical(skipTimes?.op, interval)) {
      isOPSkippedOnce.value = true;
      snackBar('Skipped Opening', duration: 2000);
    } else if (identical(skipTimes?.ed, interval)) {
      isEDSkippedOnce.value = true;
      snackBar('Skipped Ending', duration: 2000);
    } else if (identical(skipTimes?.recap, interval)) {
      isRecapSkippedOnce.value = true;
      snackBar('Skipped Recap', duration: 2000);
    }
  }

  void _handleAutoSkip() {
    final interval = currentSkipInterval.value;
    if (interval == null ||
        !_isAutoSkipEnabledForCurrentSegment ||
        _autoSkipCancelledForCurrentSegment) {
      _cancelAutoSkipTimer();
      return;
    }
    if (_autoSkipCountdownTimer != null) return;
    autoSkipCountdownRemaining.value = autoSkipCountdownSeconds;
    _autoSkipCountdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (currentSkipInterval.value != interval) {
        _cancelAutoSkipTimer();
        return;
      }
      final next = autoSkipCountdownRemaining.value - 1;
      autoSkipCountdownRemaining.value = next;
      if (next <= 0) {
        t.cancel();
        _autoSkipCountdownTimer = null;
        autoSkipCountdownRemaining.value = 0;
        _performSegmentSkip(interval);
      }
    });
  }

  void _updateSkipUiState() {
    if (skipTimes == null) return;

    final currentSec = currentPosition.value.inSeconds;
    aniskip.SkipIntervals? foundInterval;

    if (skipTimes!.op != null &&
        currentSec >= skipTimes!.op!.start &&
        currentSec < skipTimes!.op!.end) {
      foundInterval = skipTimes!.op;
    } else if (skipTimes!.ed != null &&
        currentSec >= skipTimes!.ed!.start &&
        currentSec < skipTimes!.ed!.end) {
      foundInterval = skipTimes!.ed;
    } else if (skipTimes!.recap != null &&
        currentSec >= skipTimes!.recap!.start &&
        currentSec < skipTimes!.recap!.end) {
      foundInterval = skipTimes!.recap;
    }

    if (currentSkipInterval.value != foundInterval) {
      _cancelAutoSkipTimer();
      _autoSkipCancelledForCurrentSegment = false;
      currentSkipInterval.value = foundInterval;
    }
  }

  String get skipButtonLabel {
    if (isAutoSkipCountdownActive) return 'Cancel skip';
    final interval = currentSkipInterval.value;
    if (interval == null || skipTimes == null) {
      return '+${playerSettings.skipDuration}';
    }
    if (identical(skipTimes!.op, interval)) return 'Skip intro';
    if (identical(skipTimes!.ed, interval)) return 'Skip outro';
    if (identical(skipTimes!.recap, interval)) return 'Skip recap';
    return '+${playerSettings.skipDuration}';
  }

  void performSkipAction() {
    if (isAutoSkipCountdownActive) {
      cancelAutoSkipCountdown();
      return;
    }
    final interval = currentSkipInterval.value;
    if (interval != null) {
      seekTo(Duration(seconds: interval.end));
    } else {
      megaSeek(playerSettings.skipDuration);
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

  Future<void> _initializePlayer({
    Duration? startPositionOverride,
    bool? resumePlaybackOverride,
    SubtitleTrack? subtitleToRestore,
  }) async {
    final useMediaKit = _shouldUseMediaKit();
    final mpvCore = PlayerCoreVisualSettings.getMpvCoreSettings();
    final betterCore = PlayerCoreVisualSettings.getBetterPlayerCoreSettings();
    final decoderHwdec = _resolveDecoderHwdec();
    final bufferSizeMb = (useMediaKit
            ? (mpvCore['demuxerMaxBytesMb'] as num? ?? 64)
            : (betterCore['bufferSizeMb'] as num? ?? 32))
        .toInt();

    final config = PlayerConfiguration(
      bufferSize: bufferSizeMb * 1024 * 1024,
      useLibass: PlayerKeys.useLibass.get<bool>(false),
      hwdec: decoderHwdec,
      videoOutput: settings.videoOutput,
      audioOutput: settings.audioOutput,
      playerType: useMediaKit ? PlayerType.mediaKit : PlayerType.betterPlayer,
      autoPlay: (betterCore['autoPlay'] as bool?) ?? true,
      useBuffering: (betterCore['useBuffering'] as bool?) ?? true,
    );
    _activeUseLibass = config.useLibass;

    _basePlayer = MediaKitPlayer(
      configuration: config,
    );

    await _basePlayer.initialize();
    _isPlayerInitialized.value = true;
    _bindPlayerStreams();
    playerReloadVersion.value++;
    refresh();

    if (PlayerKeys.useExternalPlayer.get<bool>(false)) {
      await launchExternalPlayer();
      return;
    }

    if (isOffline.value && offlineVideoPath != null) {
      final stamp =
          DynamicKeys.offlineVideoProgress.get<int?>(offlineVideoPath, null);
      await _basePlayer.open(
        offlineVideoPath!,
        startPosition:
            startPositionOverride ?? Duration(milliseconds: stamp ?? 0),
      );
      await _basePlayer.setRate(_sessionSpeed);
      snackBar('If you see black screen, use external player for watching');
    } else {
      await _openWithCloudFallback(
          startPositionOverride: startPositionOverride);
    }

    if (subtitleToRestore != null) {
      await _applySubtitleTrack(
        subtitleToRestore,
        allowReload: false,
      );
    }

    if (resumePlaybackOverride == false) {
      await _basePlayer.pause();
    } else if (resumePlaybackOverride == true) {
      await _basePlayer.play();
    }

    _performInitialTracking();
    applySavedProfile();
  }

  String _resolveDecoderHwdec() {
    switch (settings.hardwareDecoder) {
      case 'sw':
        return 'no';
      case 'hw+':
        if (Platform.isAndroid) return 'mediacodec-copy';
        if (Platform.isWindows) return 'd3d11va-copy';
        if (Platform.isLinux) return 'vaapi-copy';
        if (Platform.isIOS || Platform.isMacOS) return 'videotoolbox';
        return 'auto-copy';
      case 'hw':
      default:
        if (Platform.isAndroid) return 'mediacodec';
        if (Platform.isIOS || Platform.isMacOS) return 'videotoolbox';
        if (Platform.isWindows) return 'd3d11va';
        if (Platform.isLinux) return 'vaapi';
        return 'auto';
    }
  }

  Future<void> _openWithCloudFallback({Duration? startPositionOverride}) async {
    final localStamp = savedEpisode?.timeStampInMilliseconds ?? 0;
    var url = selectedVideo.value?.url ?? '';
    final headers = selectedVideo.value?.headers;
    final episodeNum = currentEpisode.value.number;

    Duration startPosition =
        startPositionOverride ?? Duration(milliseconds: localStamp);

    try {
      final shouldCheckCloud = startPositionOverride == null;
      final ctrl = shouldCheckCloud && Get.isRegistered<GistSyncController>()
          ? Get.find<GistSyncController>()
          : null;
      if (ctrl != null && ctrl.isConnected.value && ctrl.syncEnabled.value) {
        final cloudMs = await ctrl
            .fetchNewerEpisodeTimestamp(
              mediaId: anilistData.id,
              malId: anilistData.idMal,
              episodeNumber: episodeNum,
              localTimestampMs: localStamp,
            )
            .timeout(const Duration(seconds: 4), onTimeout: () => null);

        if (cloudMs != null && cloudMs > localStamp) {
          startPosition = Duration(milliseconds: cloudMs);
        }
      }
    } catch (_) {}

    if (isTorrentUrl(url)) {
      try {
        Logger.i('Torrent URL detected from extension, resolving stream...');
        final resolved = await TorrentStreamResolver.resolve(url, episode: episodeNum);
        url = resolved.streamUrl;
        Logger.i('Torrent stream resolved: $url');
      } catch (e) {
        Logger.e('Failed to resolve torrent stream: $e');
        snackBar('Failed to start torrent stream: $e');
        return;
      }
    }

    await _basePlayer.open(url, headers: headers, startPosition: startPosition);
    await _basePlayer.setRate(_sessionSpeed);
  }

  void _initializeAniSkip() {
    isOPSkippedOnce.value = false;
    isEDSkippedOnce.value = false;
    isRecapSkippedOnce.value = false;
    currentSkipInterval.value = null;
    _cancelAutoSkipTimer();
    _autoSkipCancelledForCurrentSegment = false;

    final episodeLengthSec =
        (currentEpisode.value.durationInMilliseconds ?? 0) ~/ 1000;

    final skipQuery = aniskip.SkipSearchQuery(
      idMAL: anilistData.idMal,
      episodeNumber: currentEpisode.value.number,
      episodeLength: episodeLengthSec,
    );
    aniskip.AniSkipApi().getSkipTimes(skipQuery).then((skipTimeResult) {
      skipTimes = skipTimeResult;
    }).onError((error, stackTrace) {
      debugPrint('An error occurred: $error');
      debugPrint('Stack trace: $stackTrace');
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

  void _initializePersistentListeners() {
    if (_persistentListenersInitialized) return;
    _persistentListenersInitialized = true;

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

    _subSyncWorker = ever(selectedExternalSub, (track) {
      if (track.file != null && track.file!.isNotEmpty) {
        final url = _resolveSubtitleUrl(track.file!);
        loadSubtitleCuesFromUrl(url);
      } else {
        parsedSubtitleCues.clear();
      }
    });
  }

  void _bindPlayerStreams() {
    for (final subscription in _playerSubscriptions) {
      subscription.cancel();
    }
    _playerSubscriptions.clear();

    _playerSubscriptions.add(_basePlayer.positionStream
        .throttleTime(const Duration(seconds: 1))
        .listen((pos) {
      if (_isReloadingPlayer.value) return;
      if (isSeeking.value) return;
      currentPosition.value = pos;
      currentEpisode.value.timeStampInMilliseconds = pos.inMilliseconds;
      currentEpisode.value.durationInMilliseconds =
          episodeDuration.value.inMilliseconds;

      if (_shouldMarkAsCompleted && !isOffline.value) {
        _trackOnline(true);
      }

      if (isPlaying.value && skipTimes != null && !isOffline.value) {
        _updateSkipUiState();
        _handleAutoSkip();
      }
      final now = DateTime.now();
      if (_lastMediaSessionPositionUpdate == null ||
          now.difference(_lastMediaSessionPositionUpdate!) >=
              const Duration(seconds: 3)) {
        _lastMediaSessionPositionUpdate = now;
        _updateMediaSessionState(isPlaying.value, position: pos);
      }
    }));

    _playerSubscriptions.add(_basePlayer.durationStream.listen((dur) {
      if (_isReloadingPlayer.value) return;
      episodeDuration.value = dur;
      currentEpisode.value.durationInMilliseconds = dur.inMilliseconds;
      _updateRpc();
      _updateMediaSessionMetadata();
      _updateMediaSessionState(isPlaying.value);
    }));

    _playerSubscriptions.add(_basePlayer.bufferStream
        .throttleTime(const Duration(seconds: 1))
        .listen((buf) {
      if (_isReloadingPlayer.value) return;
      bufferred.value = buf;
    }));

    _playerSubscriptions.add(_basePlayer.playingStream.listen((e) {
      if (_isReloadingPlayer.value) return;
      isPlaying.value = e;
      PipController.updatePlaybackState(e);
      _updateMediaSessionState(e);
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

    _playerSubscriptions.add(_basePlayer.bufferingStream.listen((e) {
      if (_isReloadingPlayer.value) return;
      isBuffering.value = e;
    }));

    _playerSubscriptions.add(_basePlayer.tracksStream.listen((e) {
      if (_isReloadingPlayer.value) return;
      embeddedAudioTracks.value = [];
      for (var i in e.audio) {
        embeddedAudioTracks.value.add(i);
      }
      final subs = e.subtitle
          .where((track) => !_isExternalSubtitleTrack(track))
          .toList();

      if (isOffline.value) {
        if (embeddedSubs.value.isEmpty) {
          final offlineTracks = externalSubs.value
              .map((s) => SubtitleTrack.uri(s.file ?? '',
                  title: s.label, language: s.label))
              .toList();
          subs.addAll(offlineTracks);
          embeddedSubs.value = subs;
        }
      } else {
        embeddedSubs.value = subs;
      }
      embeddedQuality.value = e.video;
      _tryAutoSelectPreferredSubtitle();
    }));

    _playerSubscriptions.add(_basePlayer.rateStream.listen((e) {
      if (_isReloadingPlayer.value) return;
      playbackSpeed.value = e;
    }));

    _playerSubscriptions.add(_basePlayer.errorStream.listen((e) {
      if (_isReloadingPlayer.value) return;
      Logger.i('${e} => ${selectedVideo.value?.headers}');
      final errorStr = e.toString();
      if (errorStr.contains('Failed to open') &&
          !errorStr.contains('.glsl') &&
          !errorStr.contains('Cannot open file')) {
        snackBar('Failed to open stream. Please try other server');
      }
    }));

    int subtitleTranslateRequestId = 0;

    _playerSubscriptions.add(_basePlayer.subtitleStream.listen((e) async {
      if (_isReloadingPlayer.value) return;
      subtitleText.value = e;
      if (!playerSettings.autoTranslate) {
        if (translatedSubtitle.value.isNotEmpty) {
          translatedSubtitle.value = '';
        }
        return;
      }

      final sanitizedLines = e
          .map((line) => line
              .replaceAll(_htmlRx, '')
              .replaceAll(_assRx, '')
              .replaceAll(_newlineRx, '\n')
              .trim())
          .where((line) => line.isNotEmpty)
          .toList();
      final int currentRequestId = ++subtitleTranslateRequestId;

      final cleanedText = sanitizedLines.join('\n');

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

    _playerSubscriptions.add(_basePlayer.heightStream.listen((height) {
      if (_isReloadingPlayer.value) return;
      videoHeight.value = height;
    }));

    _playerSubscriptions.add(_basePlayer.completedStream.listen((e) {
      if (_isReloadingPlayer.value) return;
      if (e && !isOffline.value) {
        hasNextEpisode ? navigator(true) : Get.back();
      }
    }));
  }

  void _loadLocalSubtitles() async {
    if (offlineVideoPath == null) return;

    if (selectedVideo.value?.subtitles != null &&
        selectedVideo.value!.subtitles!.isNotEmpty) {
      final validSubs = selectedVideo.value!.subtitles!
          .where((s) => s.file != null && !s.file!.startsWith('http'))
          .toList();

      if (validSubs.isNotEmpty) {
        for (var sub in validSubs) {
          if (!sub.file!.startsWith('file://')) {
            sub.file = Uri.file(sub.file!).toString();
          }
        }
        externalSubs.value = validSubs;

        final subtitleTracks = validSubs
            .map((s) => SubtitleTrack.uri(s.file ?? '',
                title: s.label, language: s.label))
            .toList();

        embeddedSubs.update((val) {
          val?.addAll(subtitleTracks);
        });
        return;
      }
    }

    try {
      final videoFile = File(offlineVideoPath!);
      final parentDir = videoFile.parent;
      final dirs = await parentDir.list().whereType<Directory>().toList();
      final expectedSubsDirName = 'Episode_${currentEpisode.value.number}_subs';
      final subsDir = dirs
          .firstWhereOrNull((d) => p.basename(d.path) == expectedSubsDirName);

      if (subsDir != null && await subsDir.exists()) {
        final files = await subsDir.list().toList();
        final subFiles = files.whereType<File>().where((f) {
          final ext = p.extension(f.path).toLowerCase();
          return ext == '.vtt' ||
              ext == '.srt' ||
              ext == '.ass' ||
              ext == '.ssa';
        }).toList();

        final tracks = subFiles.map((f) {
          final label = p.basenameWithoutExtension(f.path);
          return model.Track(
            file: Uri.file(f.path).toString(),
            label: label,
          );
        }).toList();

        externalSubs.update((val) {
          val?.addAll(tracks);
        });

        final subtitleTracks = tracks
            .map((s) => SubtitleTrack.uri(s.file ?? '',
                title: s.label, language: s.label))
            .toList();

        embeddedSubs.update((val) {
          val?.addAll(subtitleTracks);
        });
      }
    } catch (e) {
      debugPrint('Error loading local subtitles: $e');
    }
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
            !isSourcePaneOpened.value &&
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

  void toggleControls({bool? val}) {
    showControls.value = val ?? !showControls.value;
    if (showControls.value) {
      _resetAutoHideTimer();
    } else {
      _cancelAutoHideTimer();
    }
  }

  void setSubtitleDelay(Duration delay) {
    subtitleDelay.value = delay;
    _basePlayer.setSubtitleDelay(delay);
  }

  Future<void> fetchEpisode(Episode episode, {Duration? savedPosition}) async {
    if (isOffline.value) {
      // Support local file switching for offline episode list
      final videoPath = episode.link;
      if (videoPath == null || videoPath.isEmpty) return;
      _basePlayer.pause();
      DynamicKeys.offlineVideoProgress
          .set(offlineVideoPath, currentPosition.value.inMilliseconds);
      resetListeners();
      isEpisodePaneOpened.value = false;
      currentEpisode.value = episode;
      final stamp = DynamicKeys.offlineVideoProgress.get<int?>(videoPath, null);
      await _basePlayer.open(
        videoPath,
        startPosition: Duration(milliseconds: stamp ?? 0),
      );
      await _basePlayer.setRate(_sessionSpeed);
      // Update the selected video and offline path tracking
      selectedVideo.value = model.Video(
        url: videoPath,
        quality: 'Offline',
        originalUrl: videoPath,
        headerKeys: [],
        headerValues: [],
      );
      applySavedProfile();
      return;
    }

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
      await _basePlayer.stop();
      setExternalSub(null);
      currentEpisode.value = episode;
      _hasTrackedInitialLocal = false;
      _hasTrackedInitialOnline = false;
      _hasAutoSelectedPreferredSub = false;
      selectedSubsTrack.value = null;

      episodeTracks.value = data.map((e) => model.Video.fromVideo(e)).toList();

      final previousTrack = selectedVideo.value;
      final matched = _findBestMatchingTrack(episodeTracks, previousTrack);

      selectedVideo.value = matched;
      _extractSubtitles();

      _initializeAniSkip();

      final savedEpisodeData = savedEpisode;
      Duration startPosition = Duration.zero;

      if (savedEpisodeData != null) {
        final savedTimestamp = savedEpisodeData.timeStampInMilliseconds ?? 0;
        final episodeTotalDuration =
            savedEpisodeData.durationInMilliseconds ?? 0;

        final bool wasCompleted = episodeTotalDuration > 0 &&
            (savedTimestamp / episodeTotalDuration) * 100 >=
                settingsController.markAsCompleted;

        if (!wasCompleted && savedTimestamp > 0) {
          startPosition = Duration(milliseconds: savedTimestamp);
        }
      }

      await _switchMedia(matched.url ?? "", matched.headers,
          startPosition: startPosition);
    } catch (e) {
      snackBar('Failed to load episode. Check your connection.');
    } finally {
      PlayerBottomSheets.hideLoader();
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
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

  String _stripServerSuffix(String label) {
    final suffixIndex = label.lastIndexOf(' [');
    if (suffixIndex == -1 || !label.endsWith(']')) return label.trim();
    return label.substring(0, suffixIndex).trim();
  }

  List<model.Track> _processSubtitles(
    List<model.Video> tracks, {
    required bool includeServerSuffix,
  }) {
    final allSubtitles = <model.Track>[];

    for (var track in tracks) {
      if (track.subtitles?.isEmpty ?? true) continue;

      final processedSubs = track.subtitles!.map((sub) {
        final serverName = track.quality ?? 'Unknown';
        final baseLabel = (sub.label ?? 'Unknown').trim();
        final label = includeServerSuffix
            ? '$baseLabel [$serverName]'
            : _stripServerSuffix(baseLabel);
        return model.Track(
          file: sub.file,
          label: label,
        );
      }).toList();

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

  List<model.Track> getCurrentStreamSubtitleOptions() {
    final currentUrl = selectedVideo.value?.url;
    final tracks = currentUrl == null
        ? <model.Video>[]
        : episodeTracks.where((v) => v.url == currentUrl).toList();
    return _processSubtitles(
      tracks.isNotEmpty
          ? tracks
          : [if (selectedVideo.value != null) selectedVideo.value!],
      includeServerSuffix: false,
    );
  }

  List<model.Track> getAllStreamSubtitleOptions() {
    return _processSubtitles(
      episodeTracks,
      includeServerSuffix: true,
    );
  }

  int _subtitleComparator(model.Track a, model.Track b) {
    if (a.label == null || b.label == null) return -1;
    if (a.label == "English" && b.label != "English") return -1;
    if (b.label == "English" && a.label != "English") return 1;
    return a.label!.compareTo(b.label!);
  }

  bool _matchesPreferredLanguage(String? label, String preferredLangCode) {
    if (label == null || label.isEmpty || preferredLangCode == 'none')
      return false;
    final normLabel = label.toLowerCase();
    final normCode = preferredLangCode.toLowerCase();
    final fullName =
        SubtitleTranslator.languages[preferredLangCode]?.toLowerCase();
    final extName = extensionLanguageNameByCode[normCode]?.toLowerCase();
    return normLabel.contains(normCode) ||
        (fullName != null && normLabel.contains(fullName)) ||
        (extName != null && normLabel.contains(extName));
  }

  void _tryAutoSelectPreferredSubtitle() {
    if (_hasAutoSelectedPreferredSub) return;

    if (selectedSubsTrack.value != null) {
      _hasAutoSelectedPreferredSub = true;
      Future.delayed(const Duration(milliseconds: 500), () {
        _applySubtitleTrack(selectedSubsTrack.value!, allowReload: false);
      });
      return;
    }

    final preferredLang = playerSettings.preferredSubtitleLanguage;
    if (preferredLang == 'none' || embeddedSubs.value.isEmpty) return;

    final match = embeddedSubs.value.firstWhereOrNull((track) =>
        _matchesPreferredLanguage(
            '${track.language ?? ''} ${track.title ?? ''}', preferredLang));

    if (match != null) {
      _hasAutoSelectedPreferredSub = true;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (selectedSubsTrack.value == null) setSubtitleTrack(match);
      });
    }
  }

  void _extractSubtitles() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      externalSubs.value = getAllStreamSubtitleOptions();

      final currentStreamSubs = getCurrentStreamSubtitleOptions();
      if (currentStreamSubs.isEmpty) {
        setExternalSub(null);
        return;
      }

      if (selectedExternalSub.value.file != null &&
          currentStreamSubs
              .any((e) => e.file == selectedExternalSub.value.file)) {
        final match = currentStreamSubs.firstWhere(
          (e) => e.file == selectedExternalSub.value.file,
          orElse: () => currentStreamSubs.first,
        );
        selectedExternalSub.value = match;
        return;
      }

      final preferredLang = playerSettings.preferredSubtitleLanguage;
      final match = preferredLang != 'none'
          ? currentStreamSubs.firstWhereOrNull(
              (e) => _matchesPreferredLanguage(e.label, preferredLang))
          : currentStreamSubs.firstWhereOrNull(
              (e) => e.label?.toLowerCase().contains('eng') ?? false);
      setExternalSub(match ?? currentStreamSubs.first);
    });
  }

  Future<void> _switchMedia(String url, Map<String, String>? headers,
      {Duration? startPosition}) async {
    if (PlayerKeys.useExternalPlayer.get<bool>(false)) {
      await launchExternalPlayer();
      return;
    }

    if (_basePlayer is MediaKitPlayer) {
      await _basePlayer.open("");
    }

    if (isTorrentUrl(url)) {
      try {
        Logger.i('Torrent URL detected (switch), resolving stream...');
        final episodeNum = currentEpisode.value.number;
        final resolved = await TorrentStreamResolver.resolve(url, episode: episodeNum.toString());
        url = resolved.streamUrl;
        Logger.i('Torrent stream resolved: $url');
      } catch (e) {
        Logger.e('Failed to resolve torrent stream: $e');
        snackBar('Failed to start torrent stream: $e');
        return;
      }
    }

    await _basePlayer.open(url, headers: headers, startPosition: startPosition);
    await _basePlayer.setRate(_sessionSpeed);
  }

  Future<void> delete() async {
    for (final subscription in _playerSubscriptions) {
      subscription.cancel();
    }
    _playerSubscriptions.clear();

    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();

    await _deactivateMediaSession();
    await _basePlayer.pause();
    _subSyncWorker?.dispose();
    _seekDebounce?.cancel();
    _brightnessTimer?.cancel();
    _volumeTimer?.cancel();
    _controlsTimer?.cancel();
    _autoHideTimer?.cancel();
    _autoSkipCountdownTimer?.cancel();

    try {
      _trackLocally(syncToCloud: false);
      if (!isOffline.value) {
        final durationMs = episodeDuration.value.inMilliseconds;
        final hasCrossedLimit = durationMs > 0
            ? (currentPosition.value.inMilliseconds / durationMs >=
                settings.markAsCompleted)
            : false;
        _trackOnline(hasCrossedLimit);
        _syncCloudProgressOnExit();
      }
    } catch (e) {
      Logger.e('Error saving during dispose: $e');
    }

    _revertOrientations();
    WidgetsBinding.instance.removeObserver(this);
    if (!isOffline.value) {
      DiscordRPCController.instance.updateMediaPresence(media: anilistData);
    }

    await _basePlayer.dispose();

    TorrentStreamResolver.stopActiveStream();

    ScreenBrightness.instance.resetApplicationScreenBrightness();
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

  Future<T?> showSheetWithPause<T>(Future<T?> Function() openSheet) async {
    final wasPlaying = isPlaying.value;
    if (wasPlaying) _basePlayer.pause();
    try {
      return await openSheet();
    } finally {
      if (wasPlaying) _basePlayer.play();
    }
  }

  void setRate(double rate, {bool updateSession = true}) {
    if (updateSession) {
      _sessionSpeed = rate;
    }
    playbackSpeed.value = rate;
    _basePlayer.setRate(rate);
  }

  void megaSeek(int seconds) {
    seekTo(currentPosition.value + Duration(seconds: seconds));
  }

  void setVideoTrack(VideoTrack track) {
    _basePlayer.setVideoTrack(track);
    selectedQualityTrack.value = track;
  }

  void setAudioTrack(AudioTrack track) {
    _basePlayer.setAudioTrack(track);
  }

  void setSubtitleTrack(SubtitleTrack track) {
    selectedSubsTrack.value = track.id == 'no' ? null : track;

    if (track.id != 'no' &&
        track.id != 'auto' &&
        _isExternalSubtitleTrack(track)) {
      final match = externalSubs.value.firstWhere(
        (sub) {
          final isUrlMatch = sub.file == track.url;
          final trackTitle = track.title?.trim().toLowerCase() ?? '';
          final label = sub.label?.trim().toLowerCase() ?? '';
          final isLabelMatch =
              label.contains(trackTitle) || trackTitle.contains(label);
          return isUrlMatch || isLabelMatch;
        },
        orElse: () => externalSubs.value.first,
      );
      selectedExternalSub.value = match;
    } else {
      selectedExternalSub.value = model.Track();
    }

    _applySubtitleTrack(track);
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
    AnymexTitleBar.toggleFullScreen();
    onUserInteraction();
  }

  void onVerticalDragStart(BuildContext context, DragStartDetails details) {
    if (isLocked.value) return;
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
    if (isLocked.value) return;
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
        final newVol = vol.clamp(0.0, 2.0);
        setVolume(newVol, isDragging: true);
      }
    }
  }

  void onVerticalDragEnd(BuildContext context, DragEndDetails details) {
    if (isLocked.value) return;
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
      if (Platform.isAndroid || Platform.isIOS) {
        if (value <= 1.0) {
          VolumeController.instance.setVolume(value);
          _basePlayer.setVolume(1.0);
        } else {
          VolumeController.instance.setVolume(1.0);
          _basePlayer.setVolume(value);
        }
      } else {
        _basePlayer.setVolume(value);
      }
    } catch (_) {}
    volume.value = value;
    volumeIndicator.value = true;
    _volumeTimer?.cancel();

    brightnessIndicator.value = false;
    _brightnessTimer?.cancel();

    if (!isDragging) {
      _hideVolumeIndicatorAfterDelay();
    }
  }

  Future<void> setBrightness(double value, {bool isDragging = false}) async {
    brightness.value = value;
    brightnessIndicator.value = true;
    _brightnessTimer?.cancel();

    volumeIndicator.value = false;
    _volumeTimer?.cancel();

    unawaited(
      ScreenBrightness.instance
          .setApplicationScreenBrightness(value)
          .catchError((e) {
        Logger.e("Error setting brightness: $e");
      }),
    );

    if (!isDragging) {
      _hideBrightnessIndicatorAfterDelay();
    }
    refresh();
  }

  void _hideVolumeIndicatorAfterDelay() {
    _volumeTimer?.cancel();
    _volumeTimer = Timer(const Duration(milliseconds: 1500), () {
      volumeIndicator.value = false;
    });
  }

  void _hideBrightnessIndicatorAfterDelay() {
    _brightnessTimer?.cancel();
    _brightnessTimer = Timer(const Duration(milliseconds: 1500), () {
      brightnessIndicator.value = false;
    });
  }

  void setExternalSub(model.Track? track) {
    if (track == null) {
      selectedExternalSub.value = model.Track();

      selectedSubsTrack.value = null;
      _applySubtitleTrack(SubtitleTrack.no(), allowReload: false);

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
    final subtitleUrl = _resolveSubtitleUrl(track.file!);
    final subtitleTrack = SubtitleTrack.uri(
      subtitleUrl,
      title: track.label,
    );

    selectedSubsTrack.value = subtitleTrack;
    _applySubtitleTrack(subtitleTrack);

    if (playerSettings.autoTranslate && track.file != null) {
      startPreTranslation(subtitleUrl);
    }
  }

  String _resolveSubtitleUrl(String subtitlePath) {
    final raw = subtitlePath.trim();
    final uri = Uri.tryParse(raw);
    if (uri != null && uri.hasScheme) {
      return raw;
    }

    final baseUrl = selectedVideo.value?.url?.trim();
    if (baseUrl == null || baseUrl.isEmpty) {
      return raw;
    }

    final baseUri = Uri.tryParse(baseUrl);
    if (baseUri == null) {
      return raw;
    }

    try {
      return baseUri.resolve(raw).toString();
    } catch (_) {
      return raw;
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

  Future<void> loadSubtitleCuesFromUrl(String url) async {
    try {
      parsedSubtitleCues.clear();
      final uri = Uri.tryParse(url);
      if (uri == null) return;

      String content;
      if (uri.scheme == 'http' || uri.scheme == 'https') {
        final client = HttpClient();
        final request = await client.getUrl(uri);
        final response = await request.close();
        content = await response.transform(utf8.decoder).join();
        client.close();
      } else {
        print('[SUBS] Attempting to load local subtitle from path: $url');
        final file =
            File(url.replaceFirst('file://', '').replaceAll('%20', ' '));
        print('[SUBS] file exists? ${await file.exists()}');
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          content = utf8.decode(bytes, allowMalformed: true);
        } else {
          return;
        }
      }

      final cues = await SubParser.parseSubtitles(content);
      parsedSubtitleCues.assignAll(cues);
    } catch (e) {
      Logger.e('Failed to load subtitle cues: $e');
    }
  }

  Future<void> onLibassPreferenceChanged(bool enabled) async {
    if (_activeUseLibass == enabled) return;
    await reloadActivePlayer();
  }

  Future<void> reloadActivePlayer({SubtitleTrack? subtitleOverride}) async {
    if (_isReloadingPlayer.value) return;
    _isReloadingPlayer.value = true;
    playerReloadVersion.value++;
    refresh();

    await Future.delayed(const Duration(milliseconds: 50));

    final preservedPosition = currentPosition.value;
    final preservedSubtitle = subtitleOverride ?? selectedSubsTrack.value;
    final resumePlayback = isPlaying.value;

    try {
      for (final subscription in _playerSubscriptions) {
        await subscription.cancel();
      }
      _playerSubscriptions.clear();
      await _basePlayer.dispose();
      await _initializePlayer(
        startPositionOverride: preservedPosition,
        resumePlaybackOverride: resumePlayback,
        subtitleToRestore: preservedSubtitle,
      );
      await _waitForPlayerToBeReady(_basePlayer, preservedPosition);
    } catch (e) {
      Logger.e('Error reloading active player: $e');
    } finally {
      _isReloadingPlayer.value = false;
      currentPosition.value = _basePlayer.state.position;
      episodeDuration.value = _basePlayer.state.duration;
      bufferred.value = _basePlayer.state.buffer;
      isPlaying.value = _basePlayer.state.isPlaying || resumePlayback;
      isBuffering.value = _basePlayer.state.isBuffering;

      playerReloadVersion.value++;
      refresh();
    }
  }

  Future<void> _waitForPlayerToBeReady(
      BasePlayer player, Duration targetPosition) async {
    final completer = Completer<void>();
    StreamSubscription? durationSub;
    StreamSubscription? positionSub;
    Timer? timeoutTimer;

    void cleanup() {
      durationSub?.cancel();
      positionSub?.cancel();
      timeoutTimer?.cancel();
    }

    bool durationReady = false;
    bool positionReady = false;

    void checkReady() {
      if (durationReady && positionReady) {
        if (!completer.isCompleted) {
          cleanup();
          completer.complete();
        }
      }
    }

    timeoutTimer = Timer(const Duration(seconds: 8), () {
      if (!completer.isCompleted) {
        cleanup();
        completer.complete();
      }
    });

    durationSub = player.durationStream.listen((dur) {
      if (dur > Duration.zero) {
        durationReady = true;
        checkReady();
      }
    });

    if (targetPosition == Duration.zero) {
      positionReady = true;
    } else {
      positionSub = player.positionStream.listen((pos) {
        if (pos.inMilliseconds >= targetPosition.inMilliseconds - 2000) {
          positionReady = true;
          checkReady();
        }
      });
    }

    if (player.state.duration > Duration.zero) {
      durationReady = true;
    }
    if (targetPosition == Duration.zero ||
        player.state.position.inMilliseconds >=
            targetPosition.inMilliseconds - 2000) {
      positionReady = true;
    }
    checkReady();

    await completer.future;
  }

  Future<void> _applySubtitleTrack(
    SubtitleTrack track, {
    bool allowReload = true,
  }) async {
    if (allowReload && _shouldReloadForSubtitle(track)) {
      await reloadActivePlayer(subtitleOverride: track);
      return;
    }

    await _basePlayer.setSubtitleTrack(track);
  }

  bool _shouldReloadForSubtitle(SubtitleTrack track) {
    if (track.id == 'no') return false;
    return _isAssSubtitleTrack(track);
  }

  bool _isAssSubtitleTrack(SubtitleTrack track) {
    final candidates = [
      track.url ?? '',
      track.title ?? '',
      selectedExternalSub.value.file ?? '',
      selectedExternalSub.value.label ?? '',
    ];

    for (final candidate in candidates) {
      final normalized = candidate.toLowerCase();
      if (normalized.contains('.ass') || normalized.endsWith(' ass')) {
        return true;
      }
    }

    return false;
  }

  bool _isExternalSubtitleTrack(SubtitleTrack track) {
    final trackUrl = track.url?.isNotEmpty == true ? track.url! : track.id;
    if (trackUrl.isEmpty) return false;

    final isUrlMatch = externalSubs.value.any((sub) => sub.file == trackUrl);
    if (isUrlMatch) return true;

    final trackTitle = track.title?.trim().toLowerCase() ?? '';
    final isLabelMatch = externalSubs.value.any((sub) {
      final label = sub.label?.trim().toLowerCase() ?? '';
      return label.contains(trackTitle) || trackTitle.contains(label);
    });

    return isLabelMatch;
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
    _trackLocally();
    if (!isOffline.value) {
      _trackOnline(_shouldMarkAsCompleted);
    }
    _basePlayer.pause();
    unawaited(_basePlayer.stop());
    isEpisodePaneOpened.value = false;
    resetListeners();
    fetchEpisode(episode);
    _updateMediaSessionMetadata();
    onUserInteraction();
  }

  void resetListeners() {
    currentPosition.value = Duration.zero;
    episodeDuration.value = Duration.zero;
    bufferred.value = Duration.zero;
  }

  void openColorProfileBottomSheet(BuildContext context) {
    if (_basePlayer is MediaKitPlayer) {
      showSheetWithPause(() async {
        await ColorProfileBottomSheet.showColorProfileSheet(
            context, this, (_basePlayer as MediaKitPlayer).nativePlayer);
      });
    } else {
      snackBar('Color profiles only available with MediaKit player');
    }
  }

  void toggleVideoFit() {
    videoFit.value =
        BoxFit.values[(videoFit.value.index + 1) % BoxFit.values.length];
    _basePlayer.toggleVideoFit(videoFit.value);
    _showVideoFitToast(videoFit.value);
  }

  void applyConfiguredResizeMode({bool showToast = false}) {
    final configuredFit = BoxFit.values.firstWhere(
      (e) => e.name == settings.resizeMode,
      orElse: () => BoxFit.contain,
    );
    if (videoFit.value == configuredFit) return;

    videoFit.value = configuredFit;
    _basePlayer.toggleVideoFit(videoFit.value);
    if (showToast) {
      _showVideoFitToast(videoFit.value);
    }
  }

  void resetVideoFit() {
    if (videoFit.value != BoxFit.contain) {
      videoFit.value = BoxFit.contain;
      _basePlayer.toggleVideoFit(videoFit.value);
    }
    _showVideoFitToast(videoFit.value);
  }

  Future<void> enterPip() async {
    isPipMode.value = true;
    await Future.delayed(const Duration(milliseconds: 100));
    await PipController.enter();
  }

  Future<void> launchExternalPlayer() async {
    final url = selectedVideo.value?.url;
    if (url == null || url.isEmpty) {
      AnymexToast.show(
        message: 'No stream URL available',
        duration: const Duration(seconds: 2),
      );
      return;
    }

    pause();

    final headers = selectedVideo.value?.headers;
    AnymexToast.show(
      message: 'Opening in external player...',
      duration: const Duration(seconds: 2),
    );

    final success = await ExternalPlayer.launch(url, headers: headers);
    if (!success) {
      AnymexToast.show(
        message: 'Failed to launch external player',
        duration: const Duration(seconds: 2),
      );
    }
  }

  void _showVideoFitToast(BoxFit fit) {
    AnymexToast.show(
        message: fit.name.capitalizeFirst ?? '',
        duration: const Duration(milliseconds: 700));
  }

  Future<void> _trackLocally({bool syncToCloud = true}) async {
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
      String? thumbnailPath;

      if (settings.enableScreenshot) {
        screenshot = await _basePlayer.screenshot(
          includeSubtitles: true,
          format: 'image/png',
        );

        if (screenshot != null) {
          try {
            final appSupportDir = await getApplicationSupportDirectory();
            final snapshotsDir = Directory('${appSupportDir.path}/snapshots');
            if (!await snapshotsDir.exists()) {
              await snapshotsDir.create(recursive: true);
            }
            final cleanTitle = anilistData.title.replaceAll(RegExp(r'[^\w\s\-]'), '').replaceAll(RegExp(r'\s+'), '_');
            final cleanEpNumber = episode.number.replaceAll(RegExp(r'[^\w\s\-]'), '').replaceAll(RegExp(r'\s+'), '_');
            final file = File('${snapshotsDir.path}/${cleanTitle}_$cleanEpNumber.png');
            await file.writeAsBytes(screenshot);
            thumbnailPath = file.path;
          } catch (_) {
            thumbnailPath = base64Encode(screenshot);
          }
        }
      }

      final episodeToSave = Episode(
        number: episode.number,
        title: episode.title,
        link: episode.link,
        timeStampInMilliseconds: currentTimestamp.clamp(0, totalDuration),
        thumbnail: thumbnailPath ?? episode.thumbnail,
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
        syncToCloud: syncToCloud,
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
      final currEpisodeNum = currentEpisode.value.number.toInt();

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

  void _syncCloudProgressOnExit() async {
    final syncCtrl = Get.isRegistered<GistSyncController>()
        ? Get.find<GistSyncController>()
        : null;
    if (syncCtrl == null) {
      return;
    }

    final shouldRemove = syncCtrl.autoDeleteCompletedOnExit.value &&
        _shouldMarkAsCompleted &&
        !hasNextEpisode;

    syncCtrl.syncEpisodeProgressOnExit(
      mediaId: anilistData.id,
      malId: anilistData.idMal,
      episode: currentEpisode.value,
      isCompleted: shouldRemove,
    );
  }
}

class SubtitleCue {
  final Duration start;
  final Duration end;
  final String text;

  SubtitleCue({required this.start, required this.end, required this.text});
}
