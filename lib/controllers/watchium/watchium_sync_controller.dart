import 'dart:async';

import 'package:anymex/controllers/watchium/watchium_models.dart';
import 'package:anymex/controllers/watchium/watchium_service.dart';
import 'package:anymex/database/isar_models/video.dart';
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/utils/logger.dart';
import 'package:get/get.dart';

class WatchiumSyncController extends GetxController {
  final PlayerController playerController;

  WatchiumSyncController({required this.playerController});

  late final WatchiumService _watchium;
  Timer? _heartbeatTimer;
  bool _applyingSync = false;
  Worker? _playbackWorker;
  Worker? _episodeWorker;
  Worker? _seekWorker;
  Worker? _roomStateWorker;
  Worker? _isHostWorker;

  String _lastSyncedEpisodeNumber = '';
  double _lastHostPositionSec = 0.0;
  bool _listenersSetupForHost = false;

  @override
  void onInit() {
    super.onInit();
    _watchium = Get.find<WatchiumService>();
    _setupListeners();
  }

  void _setupListeners() {
    // Watch for host role changes — the role may arrive AFTER this controller
    // is created (party:state event is async), so we must react to it.
    _isHostWorker = ever(_watchium.isHost, (isHost) {
      if (isHost && !_listenersSetupForHost) {
        Logger.i('WatchiumSync: Role changed to HOST, setting up host listeners', 'WATCHIUM_SYNC');
        _teardownRoleListeners();
        _setupHostListeners();
        _listenersSetupForHost = true;
      } else if (!isHost && _listenersSetupForHost) {
        Logger.i('WatchiumSync: Role changed to MEMBER, switching to joiner listeners', 'WATCHIUM_SYNC');
        _teardownRoleListeners();
        _setupJoinerListeners();
        _listenersSetupForHost = false;
      }
    });

    // Initial setup based on current role
    if (_watchium.isHost.value) {
      _setupHostListeners();
      _listenersSetupForHost = true;
    } else {
      _setupJoinerListeners();
      _listenersSetupForHost = false;
    }
  }

  // ---- Host Logic ----

  void _setupHostListeners() {
    Logger.i('WatchiumSync: Setting up HOST listeners', 'WATCHIUM_SYNC');

    // Start heartbeat timer (every 3 seconds)
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      final pos = playerController.currentPosition.value.inSeconds;
      final playing = playerController.isPlaying.value;
      _watchium.sendHeartbeat(pos.toDouble(), playing);
    });

    // Watch for play/pause changes from user
    _playbackWorker = ever(playerController.isPlaying, (playing) {
      if (_applyingSync) return;
      if (playing) {
        _watchium.sendPlay();
      } else {
        _watchium.sendPause();
      }
    });

    // Watch for user-initiated seeks (position jump > 2s in a single Rx tick)
    _seekWorker = ever(playerController.currentPosition, (pos) {
      if (_applyingSync) return;
      final newSec = pos.inSeconds.toDouble();
      final diff = (newSec - _lastHostPositionSec).abs();
      if (diff > 2 && _lastHostPositionSec > 0) {
        Logger.d('WatchiumSync: Seek detected (${_lastHostPositionSec.toStringAsFixed(1)}s → ${newSec.toStringAsFixed(1)}s)', 'WATCHIUM_SYNC');
        _watchium.sendSeek(newSec);
      }
      _lastHostPositionSec = newSec;
    });

    // Watch for episode changes
    _episodeWorker = ever(playerController.currentEpisode, (episode) {
      if (_applyingSync) return;
      Logger.i('WatchiumSync: Episode changed to ${episode.number}', 'WATCHIUM_SYNC');
      _sendContentForCurrentEpisode();
    });
  }

  void _sendContentForCurrentEpisode() {
    final content = _buildContentFromPlayer(playerController);
    _watchium.setContent(content);
  }

  // ---- Joiner Logic ----

  void _setupJoinerListeners() {
    Logger.i('WatchiumSync: Setting up JOINER listeners', 'WATCHIUM_SYNC');

    // Watch roomState for playback sync
    _roomStateWorker = ever(_watchium.roomState, (state) {
      if (state == null) return;
      if (!state.onlyHostControls) return;

      final playback = state.playback;
      if (playback == null) return;

      _applyPlaybackSync(playback);

      // Detect content (episode) change from host
      final content = state.content;
      if (content != null) {
        final epKey = '${content.animeId}-${content.episodeNumber}';
        if (epKey != _lastSyncedEpisodeNumber) {
          _lastSyncedEpisodeNumber = epKey;
          Logger.i('WatchiumSync: Host changed content to ep ${content.episodeNumber}', 'WATCHIUM_SYNC');
          _updateJoinerTracks(content);
        }
      }
    });
  }

  void _applyPlaybackSync(WatchiumPlayback playback) {
    _applyingSync = true;
    try {
      final hostPlaying = playback.isPlaying;
      final localPlaying = playerController.isPlaying.value;

      if (hostPlaying && !localPlaying) {
        Logger.d('WatchiumSync: Host played — resuming', 'WATCHIUM_SYNC');
        playerController.play();
      } else if (!hostPlaying && localPlaying) {
        Logger.d('WatchiumSync: Host paused — pausing', 'WATCHIUM_SYNC');
        playerController.pause();
      }

      // Position sync: seek if off by more than 3 seconds
      final hostPos = playback.positionSec;
      final localPos = playerController.currentPosition.value.inSeconds;
      final diff = (hostPos - localPos).abs();
      if (diff > 3) {
        Logger.d('WatchiumSync: Seeking from ${localPos}s to ${hostPos}s (diff=${diff.toStringAsFixed(1)}s)', 'WATCHIUM_SYNC');
        playerController.seekTo(Duration(seconds: hostPos.round()));
      }
    } finally {
      // Use a microtask to reset the flag after the current event loop tick
      // so the player state changes triggered above don't cause re-emission
      Future.microtask(() => _applyingSync = false);
    }
  }

  void _updateJoinerTracks(WatchiumAnimeContent content) {
    if (content.availableServers.isEmpty) return;

    // Convert WatchiumAnimeServers to Video models and update the player's
    // episodeTracks so the joiner can pick from them.
    final videos = content.availableServers.map((s) => s.toVideo()).toList();
    playerController.episodeTracks.value = videos;

    Logger.i('WatchiumSync: Updated joiner tracks with ${videos.length} servers', 'WATCHIUM_SYNC');
  }

  // ---- Teardown ----

  void _teardownRoleListeners() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _playbackWorker?.dispose();
    _playbackWorker = null;
    _episodeWorker?.dispose();
    _episodeWorker = null;
    _seekWorker?.dispose();
    _seekWorker = null;
    _roomStateWorker?.dispose();
    _roomStateWorker = null;
  }

  // ---- Helpers ----

  WatchiumAnimeContent _buildContentFromPlayer(PlayerController pc) {
    final servers = pc.episodeTracks.asMap().entries.map((entry) {
      final video = entry.value;
      return WatchiumAnimeServer(
        serverId: entry.key.toString(),
        serverName: video.quality ?? 'Server ${entry.key + 1}',
        quality: video.quality,
        type: _detectVideoType(video.url),
        url: video.url,
        originalUrl: video.originalUrl,
        headers: video.headers,
        subtitles: video.subtitles
            ?.where((t) => t.file != null && t.label != null)
            .map((t) => WatchiumTrack(file: t.file!, label: t.label!))
            .toList(),
        audios: video.audios
            ?.where((t) => t.file != null && t.label != null)
            .map((t) => WatchiumTrack(file: t.file!, label: t.label!))
            .toList(),
      );
    }).toList();

    return WatchiumAnimeContent(
      animeId: pc.anilistData.id,
      animeTitle: pc.anilistData.title,
      animeCoverImage: pc.anilistData.cover,
      episodeNumber: int.tryParse(pc.currentEpisode.value.number) ?? 1,
      totalEpisodes: int.tryParse(pc.anilistData.totalEpisodes),
      availableServers: servers,
    );
  }

  String _detectVideoType(String? url) {
    if (url == null) return 'other';
    if (url.contains('.m3u8')) return 'hls';
    if (url.contains('.mpd')) return 'dash';
    if (url.endsWith('.mp4') || url.endsWith('.mkv')) return 'mp4';
    return 'hls'; // default for streaming
  }

  @override
  void onClose() {
    _isHostWorker?.dispose();
    _teardownRoleListeners();
    Logger.d('WatchiumSync: onClose', 'WATCHIUM_SYNC');
    super.onClose();
  }
}
