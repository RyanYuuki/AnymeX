import 'dart:async';
import 'dart:typed_data';

import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/player_core_visual_settings.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'base_player.dart' as base;

class MediaKitPlayer extends base.BasePlayer {
  late Player _player;
  late VideoController _videoController;
  final base.PlayerConfiguration config;

  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();
  final _bufferController = StreamController<Duration>.broadcast();
  final _playingController = StreamController<bool>.broadcast();
  final _bufferingController = StreamController<bool>.broadcast();
  final _tracksController = StreamController<base.PlayerTracks>.broadcast();
  final _rateController = StreamController<double>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  final _subtitleController = StreamController<List<String>>.broadcast();
  final _heightController = StreamController<int?>.broadcast();
  final _completedController = StreamController<bool>.broadcast();

  base.PlayerState _state = base.PlayerState();
  final List<StreamSubscription> _subscriptions = [];
  bool _isDisposed = false;

  MediaKitPlayer({base.PlayerConfiguration? configuration})
      : config = configuration ??
            base.PlayerConfiguration(playerType: base.PlayerType.mediaKit);

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Stream<Duration> get durationStream => _durationController.stream;

  @override
  Stream<Duration> get bufferStream => _bufferController.stream;

  @override
  Stream<bool> get playingStream => _playingController.stream;

  @override
  Stream<bool> get bufferingStream => _bufferingController.stream;

  @override
  Stream<base.PlayerTracks> get tracksStream => _tracksController.stream;

  @override
  Stream<double> get rateStream => _rateController.stream;

  @override
  Stream<String> get errorStream => _errorController.stream;

  @override
  Stream<List<String>> get subtitleStream => _subtitleController.stream;

  @override
  Stream<int?> get heightStream => _heightController.stream;

  @override
  Stream<bool> get completedStream => _completedController.stream;

  @override
  base.PlayerState get state => _state;

  @override
  Future<void> initialize() async {
    _player = Player(
      configuration: PlayerConfiguration(
        bufferSize: config.bufferSize,
        libass: config.useLibass,
      ),
    );

    _videoController = VideoController(
      _player,
      configuration: VideoControllerConfiguration(
        hwdec: config.hwdec,
        androidAttachSurfaceAfterVideoParameters: true,
      ),
    );

    _setupListeners();
    await PlayerCoreVisualSettings.applyMpvCoreSettings(_player);
    await PlayerCoreVisualSettings.applyMpvVisualSettings(_player);
  }

  void _setupListeners() {
    _subscriptions.add(_player.stream.position.listen((position) {
      _state = _state.copyWith(position: position);
      _positionController.add(position);
    }));

    _subscriptions.add(_player.stream.duration.listen((duration) {
      _state = _state.copyWith(duration: duration);
      _durationController.add(duration);
    }));

    _subscriptions.add(_player.stream.buffer.listen((buffer) {
      _state = _state.copyWith(buffer: buffer);
      _bufferController.add(buffer);
    }));

    _subscriptions.add(_player.stream.playing.listen((playing) {
      _state = _state.copyWith(isPlaying: playing);
      _playingController.add(playing);
    }));

    _subscriptions.add(_player.stream.buffering.listen((buffering) {
      _state = _state.copyWith(isBuffering: buffering);
      _bufferingController.add(buffering);
    }));

    _subscriptions.add(_player.stream.tracks.listen((tracks) {
      final playerTracks = base.PlayerTracks(
        audio: tracks.audio
            .map((t) => base.AudioTrack(
                  id: t.id,
                  title: t.title,
                  language: t.language,
                ))
            .toList(),
        subtitle: tracks.subtitle
            .where((e) => e.title != null && e.language != null)
            .map((t) {
          return base.SubtitleTrack(
            id: t.id,
            title: t.title,
            language: t.language,
          );
        }).toList(),
        video: tracks.video
            .map((t) => base.VideoTrack(
                  id: t.id,
                  title: t.id,
                  width: t.w,
                  height: t.h,
                  bitrate: t.bitrate?.toInt(),
                ))
            .toList(),
      );
      _tracksController.add(playerTracks);
    }));

    _subscriptions.add(_player.stream.rate.listen((rate) {
      _state = _state.copyWith(rate: rate);
      _rateController.add(rate);
    }));

    _subscriptions.add(_player.stream.error.listen((error) {
      Logger.e('Player error: $error');
      _errorController.add(error);
    }));

    _subscriptions.add(_player.stream.subtitle.listen((subtitles) {
      _subtitleController.add(subtitles);
    }));

    _subscriptions.add(_player.stream.height.listen((height) {
      _state = _state.copyWith(videoHeight: height);
      _heightController.add(height);
    }));

    _subscriptions.add(_player.stream.completed.listen((completed) {
      _completedController.add(completed);
    }));
  }

  @override
  Future<void> open(
    String url, {
    Map<String, String>? headers,
    Duration? startPosition,
  }) async {
    print('Opening video: $url with headers: $headers');
    await _player.open(
      Media(url, httpHeaders: headers, start: startPosition),
    );
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> play() async {
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> playOrPause() async {
    await _player.playOrPause();
  }

  @override
  Future<void> setRate(double rate) async {
    await _player.setRate(rate);
  }

  @override
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume * 100);
    _state = _state.copyWith(volume: volume);
  }

  @override
  Future<void> setVideoTrack(base.VideoTrack track) async {
    print(
        'trying video track: ${track.id} - ${track.title} (${track.width}x${track.height})');
    final mediaKitTrack = _player.state.tracks.video.firstWhere(
      (t) => t.id == track.id,
      orElse: () => _player.state.tracks.video.first,
    );
    print(
        'Setting video track: ${mediaKitTrack.id} - ${mediaKitTrack.title} (${mediaKitTrack.w}x${mediaKitTrack.h})');

    await _player.setVideoTrack(mediaKitTrack);
  }

  @override
  Future<void> setAudioTrack(base.AudioTrack track) async {
    if (track.id == 'no') {
      await _player.setAudioTrack(AudioTrack.no());
      return;
    }

    if (track.url != null) {
      await _player
          .setAudioTrack(AudioTrack.uri(track.url!, title: track.title));
      return;
    }

    final mediaKitTrack = _player.state.tracks.audio.firstWhere(
      (t) => t.id == track.id,
      orElse: () => _player.state.tracks.audio.first,
    );
    await _player.setAudioTrack(mediaKitTrack);
  }

  @override
  Future<void> setSubtitleTrack(base.SubtitleTrack track) async {
    if (track.id == 'no') {
      await _player.setSubtitleTrack(SubtitleTrack.no());
      return;
    }

    if (track.url != null) {
      await _player.setSubtitleTrack(
        SubtitleTrack.uri(
          track.url!,
          title: track.title,
          language: track.language,
        ),
      );
      return;
    }

    final mediaKitTrack = _player.state.tracks.subtitle.firstWhere(
      (t) => t.id == track.id,
      orElse: () => _player.state.tracks.subtitle.first,
    );
    await _player.setSubtitleTrack(mediaKitTrack);
  }

  @override
  Future<void> setSubtitleDelay(Duration delay) async {
    final seconds = delay.inMicroseconds / 1000000.0;
    (_player.platform as dynamic).setProperty('sub-delay', seconds.toString());
  }

  @override
  Future<Uint8List?> screenshot({
    bool includeSubtitles = true,
    String format = 'image/png',
  }) async {
    try {
      return await _player.screenshot(
        includeLibassSubtitles: includeSubtitles,
        format: format,
      );
    } catch (e) {
      debugPrint('Screenshot failed: $e');
      return null;
    }
  }

  @override
  Future<void> setHardwareDecoding(String mode) async {
    debugPrint('Hardware decoding change requires player reinitialization');
  }

  @override
  Widget getVideoWidget({
    BoxFit? fit,
    double? width,
    double? height,
  }) {
    if (_isDisposed) return const SizedBox.shrink();

    return Video(
      filterQuality: FilterQuality.medium,
      controls: null,
      controller: _videoController,
      fit: fit ?? BoxFit.contain,
      resumeUponEnteringForegroundMode: true,
      subtitleViewConfiguration:
          SubtitleViewConfiguration(visible: config.useLibass),
    );
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;

    for (final s in _subscriptions) {
      s.cancel();
    }
    _subscriptions.clear();

    try {
      await _player.stop();
    } catch (_) {}

    _isDisposed = true;

    await Future.delayed(const Duration(milliseconds: 300));

    try {
      await _player.dispose();
    } catch (e) {
      Logger.e('Error during _player.dispose(): $e');
    }

    await Future.wait([
      _positionController.close(),
      _durationController.close(),
      _bufferController.close(),
      _playingController.close(),
      _bufferingController.close(),
      _tracksController.close(),
      _rateController.close(),
      _errorController.close(),
      _subtitleController.close(),
      _heightController.close(),
      _completedController.close(),
    ]);
  }

  Player get nativePlayer => _player;

  VideoController get nativeVideoController => _videoController;

  @override
  Future<void> toggleVideoFit(BoxFit fit) {
    return Future.value();
  }
}
