import 'dart:async';
import 'dart:typed_data';

import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'base_player.dart';

class BetterPlayerImpl extends BasePlayer {
  late BetterPlayerController _controller;
  BetterPlayerDataSource? _currentDataSource;
  final PlayerConfiguration config;

  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();
  final _bufferController = StreamController<Duration>.broadcast();
  final _playingController = StreamController<bool>.broadcast();
  final _bufferingController = StreamController<bool>.broadcast();
  final _tracksController = StreamController<PlayerTracks>.broadcast();
  final _rateController = StreamController<double>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  final _subtitleController = StreamController<List<String>>.broadcast();
  final _heightController = StreamController<int?>.broadcast();
  final _completedController = StreamController<bool>.broadcast();

  PlayerState _state = PlayerState();
  Timer? _positionTimer;
  Timer? _bufferTimer;
  bool _isDisposed = false;

  BetterPlayerImpl({
    PlayerConfiguration? configuration,
  }) : config = configuration ??
            PlayerConfiguration(playerType: PlayerType.betterPlayer);

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
  Stream<PlayerTracks> get tracksStream => _tracksController.stream;

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
  PlayerState get state => _state;

  @override
  Future<void> initialize() async {
    WakelockPlus.enable();
    final betterPlayerConfiguration = BetterPlayerConfiguration(
      autoPlay: true,
      autoDetectFullscreenDeviceOrientation: true,
      controlsConfiguration: const BetterPlayerControlsConfiguration(
        showControls: false,
      ),
      eventListener: _handlePlayerEvent,
    );

    _controller = BetterPlayerController(betterPlayerConfiguration);
    _setupPeriodicUpdates();
  }

  void _handlePlayerEvent(BetterPlayerEvent event) {
    if (_isDisposed) return;

    switch (event.betterPlayerEventType) {
      case BetterPlayerEventType.initialized:
        _onInitialized();
        break;
      case BetterPlayerEventType.play:
        _state = _state.copyWith(isPlaying: true);
        _playingController.add(true);
        break;
      case BetterPlayerEventType.pause:
        _state = _state.copyWith(isPlaying: false);
        _playingController.add(false);
        break;
      case BetterPlayerEventType.finished:
        _completedController.add(true);
        break;
      case BetterPlayerEventType.bufferingStart:
        _state = _state.copyWith(isBuffering: true);
        _bufferingController.add(true);
        break;
      case BetterPlayerEventType.bufferingEnd:
        if (_controller.isVideoInitialized() == true) {
          _state = _state.copyWith(isBuffering: false);
          _bufferingController.add(false);
        }
        break;
      case BetterPlayerEventType.exception:
        _errorController.add(event.parameters?.toString() ?? 'Unknown error');
        break;
      case BetterPlayerEventType.setupDataSource:
        _onDataSourceSetup();
        break;
      default:
        break;
    }
  }

  void _onInitialized() {
    _state = _state.copyWith(isBuffering: false);
    _bufferingController.add(false);

    final videoPlayerController = _controller.videoPlayerController;
    if (videoPlayerController != null) {
      final duration = videoPlayerController.value.duration ?? Duration.zero;
      _state = _state.copyWith(duration: duration);
      _durationController.add(duration);

      final size = videoPlayerController.value.size;
      if (size != null && size.height > 0) {
        final height = size.height.toInt();
        _state = _state.copyWith(videoHeight: height);
        _heightController.add(height);
      }

      _extractTracks();
    }
  }

  void _onDataSourceSetup() {
    _extractTracks();
  }

  void _extractTracks() {
    final tracks = PlayerTracks(
      audio: _extractAudioTracks(),
      subtitle: _extractSubtitleTracks(),
      video: _extractVideoTracks(),
    );
    _tracksController.add(tracks);
  }

  List<AudioTrack> _extractAudioTracks() {
    final audioTracks = <AudioTrack>[];

    audioTracks.add(AudioTrack.auto());

    return audioTracks;
  }

  List<SubtitleTrack> _extractSubtitleTracks() {
    final subtitleTracks = <SubtitleTrack>[SubtitleTrack.no()];

    if (_currentDataSource?.subtitles != null) {
      for (var i = 0; i < _currentDataSource!.subtitles!.length; i++) {
        final sub = _currentDataSource!.subtitles![i];
        subtitleTracks.add(SubtitleTrack(
          id: 'subtitle_$i',
          title: sub.name,
          language: sub.name,
          url: sub.urls?.first ?? "",
        ));
      }
    }

    return subtitleTracks;
  }

  List<VideoTrack> _extractVideoTracks() {
    final videoTracks = <VideoTrack>[];

    videoTracks.add(VideoTrack.auto());

    if (_currentDataSource?.resolutions != null) {
      _currentDataSource!.resolutions!.forEach((quality, url) {
        videoTracks.add(VideoTrack(
          id: quality,
          title: quality,
        ));
      });
    }

    return videoTracks;
  }

  void _setupPeriodicUpdates() {
    _positionTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (_isDisposed) return;

      final videoController = _controller.videoPlayerController;
      if (videoController != null && videoController.value.initialized) {
        final position = videoController.value.position;
        _state = _state.copyWith(position: position);
        _positionController.add(position);
      }
    });

    _bufferTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isDisposed) return;

      final videoController = _controller.videoPlayerController;
      if (videoController != null && videoController.value.initialized) {
        final buffered = videoController.value.buffered;
        if (buffered.isNotEmpty) {
          final bufferEnd = buffered.last.end;
          _state = _state.copyWith(buffer: bufferEnd);
          _bufferController.add(bufferEnd);
        }
      }
    });
  }

  @override
  Future<void> open(
    String url, {
    Map<String, String>? headers,
    Duration? startPosition,
  }) async {
    _state = _state.copyWith(isBuffering: true);
    _bufferingController.add(true);

    _currentDataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      url,
      headers: headers,
      videoFormat: url.contains('.mp4')
          ? BetterPlayerVideoFormat.other
          : BetterPlayerVideoFormat.hls,
      bufferingConfiguration: BetterPlayerBufferingConfiguration(
        minBufferMs: config.bufferSize ~/ 1000,
        maxBufferMs: config.bufferSize ~/ 500,
      ),
    );

    await _controller.setupDataSource(_currentDataSource!);

    if (startPosition != null && startPosition > Duration.zero) {
      await _controller.seekTo(startPosition);
    }
  }

  @override
  Future<void> seek(Duration position) async {
    await _controller.seekTo(position);
  }

  @override
  Future<void> play() async {
    await _controller.play();
  }

  @override
  Future<void> pause() async {
    await _controller.pause();
  }

  @override
  Future<void> playOrPause() async {
    if (_state.isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  @override
  Future<void> setRate(double rate) async {
    await _controller.setSpeed(rate);
    _state = _state.copyWith(rate: rate);
    _rateController.add(rate);
  }

  @override
  Future<void> setVolume(double volume) async {
    await _controller.setVolume(volume);
    _state = _state.copyWith(volume: volume);
  }

  @override
  Future<void> setVideoTrack(VideoTrack track) async {
    if (_currentDataSource?.resolutions != null &&
        _currentDataSource!.resolutions!.containsKey(track.id)) {
      final currentPosition = _state.position;
      final newUrl = _currentDataSource!.resolutions![track.id];

      if (newUrl != null) {
        await open(newUrl, startPosition: currentPosition);
      }
    }
  }

  @override
  Future<void> setAudioTrack(AudioTrack track) async {
    if (track.id == 'no') {
      await _controller.setVolume(0);
      return;
    }

    snackBar("Not implemented yet");
  }

  @override
  Future<void> setSubtitleTrack(SubtitleTrack track) async {
    if (track.id == 'no') {
      await _controller.setupSubtitleSource(
        BetterPlayerSubtitlesSource(
          type: BetterPlayerSubtitlesSourceType.none,
        ),
      );
      return;
    }

    if (track.url != null) {
      await _controller.setupDataSource(
        _currentDataSource!.copyWith(
          subtitles: [
            ..._currentDataSource?.subtitles ?? [],
            BetterPlayerSubtitlesSource(
              type: BetterPlayerSubtitlesSourceType.network,
              urls: [track.url!],
              name: track.title,
            ),
          ],
        ),
      );
    } else {
      final index = int.tryParse(track.id.replaceAll('subtitle_', ''));
      if (index != null && _currentDataSource?.subtitles != null) {
        if (index < _currentDataSource!.subtitles!.length) {
          _controller.setupSubtitleSource(
            _currentDataSource!.subtitles![index],
          );
        }
      }
    }
  }

  @override
  Future<Uint8List?> screenshot({
    bool includeSubtitles = true,
    String format = 'image/png',
  }) async {
    return null;
  }

  @override
  Future<void> setHardwareDecoding(String mode) async {}

  @override
  Widget getVideoWidget({
    BoxFit? fit,
    double? width,
    double? height,
  }) {
    _controller.setOverriddenFit(fit ?? BoxFit.contain);
    return BetterPlayer(
      controller: _controller,
    );
  }

  @override
  Future<void> dispose() async {
    WakelockPlus.disable();
    _isDisposed = true;

    _positionTimer?.cancel();
    _bufferTimer?.cancel();

    await _positionController.close();
    await _durationController.close();
    await _bufferController.close();
    await _playingController.close();
    await _bufferingController.close();
    await _tracksController.close();
    await _rateController.close();
    await _errorController.close();
    await _subtitleController.close();
    await _heightController.close();
    await _completedController.close();

    _controller.dispose();
  }

  BetterPlayerController get nativeController => _controller;

  @override
  Future<void> toggleVideoFit(BoxFit fit) async {
    _controller.setOverriddenFit(fit);
  }
}

extension BetterPlayerDataSourceExtension on BetterPlayerDataSource {
  BetterPlayerDataSource copyWith({
    PlayerConfiguration? config,
    List<BetterPlayerSubtitlesSource>? subtitles,
    List<BetterPlayerAsmsAudioTrack>? audiosTracks,
  }) {
    final finalConfig = config ?? PlayerConfiguration();
    return BetterPlayerDataSource(
      type,
      url,
      subtitles: subtitles ?? this.subtitles,
      headers: headers,
      // : audiosTracks ?? this.audiosTracks,
      resolutions: resolutions,
      bufferingConfiguration: BetterPlayerBufferingConfiguration(
        minBufferMs: finalConfig.bufferSize ~/ 1000,
        maxBufferMs: finalConfig.bufferSize ~/ 500,
      ),
    );
  }
}
