import 'dart:async';

import 'package:anymex/controllers/watchium/watchium_models.dart';
import 'package:anymex/controllers/watchium/watchium_service.dart';
import 'package:anymex/database/isar_models/video.dart';
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:get/get.dart';

const _syncDriftThreshold = 5.0;

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
  Worker? _followModeWorker;

  String _lastSyncedEpisodeNumber = '';
  double _lastHostPositionSec = 0.0;
  bool _listenersSetupForHost = false;

  final RxBool isOutOfSync = false.obs;

  @override
  void onInit() {
    super.onInit();
    _watchium = Get.find<WatchiumService>();
    _setupListeners();
  }

  void _setupListeners() {
    _isHostWorker = ever(_watchium.isHost, (isHost) {
      if (isHost && !_listenersSetupForHost) {
        Logger.i(
            'WatchiumSync: Role changed to HOST, setting up host listeners',
            'WATCHIUM_SYNC');
        _teardownRoleListeners();
        _setupHostListeners();
        _listenersSetupForHost = true;
      } else if (!isHost && _listenersSetupForHost) {
        Logger.i(
            'WatchiumSync: Role changed to MEMBER, switching to joiner listeners',
            'WATCHIUM_SYNC');
        _teardownRoleListeners();
        _setupJoinerListeners();
        _listenersSetupForHost = false;
      }
    });

    if (_watchium.isHost.value) {
      _setupHostListeners();
      _listenersSetupForHost = true;
    } else {
      _setupJoinerListeners();
      _listenersSetupForHost = false;
    }
  }

  void _setupHostListeners() {
    Logger.i('WatchiumSync: Setting up HOST listeners', 'WATCHIUM_SYNC');

    _heartbeatTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      final pos = playerController.currentPosition.value.inSeconds;
      final playing = playerController.isPlaying.value;
      _watchium.sendHeartbeat(pos.toDouble(), playing);
    });

    _playbackWorker = ever(playerController.isPlaying, (playing) {
      if (_applyingSync) return;
      if (playing) {
        _watchium.sendPlay();
      } else {
        _watchium.sendPause();
      }
    });

    _seekWorker = ever(playerController.currentPosition, (pos) {
      if (_applyingSync) return;
      final newSec = pos.inSeconds.toDouble();
      final diff = (newSec - _lastHostPositionSec).abs();
      if (diff > 2 && _lastHostPositionSec > 0) {
        Logger.d(
            'WatchiumSync: Seek detected (${_lastHostPositionSec.toStringAsFixed(1)}s → ${newSec.toStringAsFixed(1)}s)',
            'WATCHIUM_SYNC');
        _watchium.sendSeek(newSec);
      }
      _lastHostPositionSec = newSec;
    });

    _episodeWorker = ever(playerController.currentEpisode, (episode) {
      if (_applyingSync) return;
      Logger.i('WatchiumSync: Episode changed to ${episode.number}',
          'WATCHIUM_SYNC');
      _sendContentForCurrentEpisode();
    });
  }

  void _sendContentForCurrentEpisode() {
    final content = _buildContentFromPlayer(playerController);
    _watchium.setContent(content);
  }

  void _setupJoinerListeners() {
    Logger.i('WatchiumSync: Setting up JOINER listeners', 'WATCHIUM_SYNC');

    _roomStateWorker = ever(_watchium.roomState, (state) {
      if (state == null) return;

      final playback = state.playback;
      if (playback == null) return;

      final content = state.content;
      if (content != null) {
        final epKey = '${content.animeId}-${content.episodeNumber}';
        if (epKey != _lastSyncedEpisodeNumber) {
          _lastSyncedEpisodeNumber = epKey;
          Logger.i(
              'WatchiumSync: Host changed content to ep ${content.episodeNumber}',
              'WATCHIUM_SYNC');
          _onHostEpisodeChange(content);
        }
      }

      if (_watchium.followHost.value) {
        _applyHostSync(playback);
      } else {
        _checkSyncStatus(playback);
      }
    });

    _followModeWorker = ever(_watchium.followHost, (isFollowing) {
      if (isFollowing) {
        final state = _watchium.roomState.value;
        if (state != null) {
          final content = state.content;
          if (content != null) {
            _lastSyncedEpisodeNumber = '';
            _onHostEpisodeChange(content);
          }
          final playback = state.playback;
          if (playback != null) {
            _applyHostSync(playback);
          }
        }
      } else {
        isOutOfSync.value = false;
      }
    });
  }

  void _onHostEpisodeChange(WatchiumAnimeContent content) {
    if (content.availableServers.isEmpty) return;

    if (_watchium.followHost.value) {
      _applyHostEpisodeChange(content);
    } else {
      _showHostEpisodeSnackbar(content);
    }
  }

  void _applyHostEpisodeChange(WatchiumAnimeContent content) {
    _applyingSync = true;
    try {
      final videos = content.availableServers.map((s) => s.toVideo()).toList();
      playerController.episodeTracks.value = videos;

      final previousTrack = playerController.selectedVideo.value;
      final matched = _findBestMatchingTrack(videos, previousTrack);

      if (matched != null) {
        Logger.i(
            'WatchiumSync: Auto-switching to ep ${content.episodeNumber}, server: ${matched.quality ?? matched.originalUrl}',
            'WATCHIUM_SYNC');
        playerController.setServerTrack(matched);
      } else {
        Logger.i(
            'WatchiumSync: No servers for ep ${content.episodeNumber}, opening source selector',
            'WATCHIUM_SYNC');
        playerController.isSourcePaneOpened.value = true;
      }
    } finally {
      Future.microtask(() => _applyingSync = false);
    }
  }

  Video? _findBestMatchingTrack(List<Video> tracks, Video? previous) {
    if (previous == null || tracks.isEmpty) {
      return tracks.isNotEmpty ? tracks.first : null;
    }

    final exactMatch = tracks.where(
        (t) => t.url == previous.url || t.originalUrl == previous.originalUrl);
    if (exactMatch.isNotEmpty) return exactMatch.first;

    if (previous.quality != null) {
      final qualityMatch = tracks.where((t) => t.quality == previous.quality);
      if (qualityMatch.isNotEmpty) return qualityMatch.first;
    }

    return tracks.first;
  }

  void _showHostEpisodeSnackbar(WatchiumAnimeContent content) {
    final title =
        content.animeTitle.isNotEmpty ? content.animeTitle : 'the anime';
    snackBar('Host switched to Episode ${content.episodeNumber} of $title');
    isOutOfSync.value = true;
  }

  void _checkSyncStatus(WatchiumPlayback playback) {
    if (_applyingSync) return;
    final hostPos = playback.positionSec;
    final localPos = playerController.currentPosition.value.inSeconds;
    final diff = (hostPos - localPos).abs();
    final wasOutOfSync = isOutOfSync.value;
    isOutOfSync.value = diff > _syncDriftThreshold;
    if (isOutOfSync.value && !wasOutOfSync) {
      Logger.d('WatchiumSync: Out of sync (diff=${diff.toStringAsFixed(1)}s)',
          'WATCHIUM_SYNC');
    }
  }

  void _applyHostSync(WatchiumPlayback playback) {
    if (_applyingSync) return;
    final hostPos = playback.positionSec;
    final localPos = playerController.currentPosition.value.inSeconds;
    final diff = (hostPos - localPos).abs();

    if (diff > 1.5) {
      _applyingSync = true;
      try {
        Logger.d(
            'WatchiumSync: Auto-sync to host (${localPos}s → ${hostPos.toStringAsFixed(1)}s)',
            'WATCHIUM_SYNC');
        playerController
            .seekTo(Duration(milliseconds: (hostPos * 1000).round()));
      } finally {
        Future.microtask(() => _applyingSync = false);
      }
    }

    if (playback.isPlaying && !playerController.isPlaying.value) {
      playerController.play();
    } else if (!playback.isPlaying && playerController.isPlaying.value) {
      playerController.pause();
    }

    isOutOfSync.value = false;
  }

  void syncToHost() {
    final state = _watchium.roomState.value;
    if (state == null) {
      Logger.w('syncToHost: no room state', 'WATCHIUM_SYNC');
      return;
    }
    final playback = state.playback;
    if (playback == null) {
      Logger.w('syncToHost: no playback data', 'WATCHIUM_SYNC');
      return;
    }
    _applyingSync = true;
    try {
      final content = state.content;
      if (content != null) {
        final epKey = '${content.animeId}-${content.episodeNumber}';
        if (epKey != _lastSyncedEpisodeNumber) {
          _lastSyncedEpisodeNumber = epKey;
          _applyHostEpisodeChange(content);

          return;
        }
      }

      final hostPos = playback.positionSec;
      Logger.i(
          'WatchiumSync: Manual sync to host at ${hostPos.toStringAsFixed(1)}s',
          'WATCHIUM_SYNC');
      playerController.seekTo(Duration(seconds: hostPos.round()));
      if (playback.isPlaying && !playerController.isPlaying.value) {
        playerController.play();
      } else if (!playback.isPlaying && playerController.isPlaying.value) {
        playerController.pause();
      }
      isOutOfSync.value = false;
    } finally {
      Future.microtask(() => _applyingSync = false);
    }
  }

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
    _followModeWorker?.dispose();
    _followModeWorker = null;
  }

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
      animePosterImage: pc.anilistData.largePoster,
      episodeNumber: int.tryParse(pc.currentEpisode.value.number) ?? 1,
      totalEpisodes: int.tryParse(pc.anilistData.totalEpisodes),
      anilistId: int.tryParse(pc.anilistData.uniqueId),
      malId: int.tryParse(pc.anilistData.idMal),
      availableServers: servers,
    );
  }

  String _detectVideoType(String? url) {
    if (url == null) return 'other';
    if (url.contains('.m3u8')) return 'hls';
    if (url.contains('.mpd')) return 'dash';
    if (url.endsWith('.mp4') || url.endsWith('.mkv')) return 'mp4';
    return 'hls';
  }

  @override
  void onClose() {
    isOutOfSync.close();
    _isHostWorker?.dispose();
    _teardownRoleListeners();
    Logger.d('WatchiumSync: onClose', 'WATCHIUM_SYNC');
    super.onClose();
  }
}
