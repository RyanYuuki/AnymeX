import 'dart:typed_data';

import 'package:flutter/material.dart';

abstract class BasePlayer {
  Stream<Duration> get positionStream;

  Stream<Duration> get durationStream;

  Stream<Duration> get bufferStream;

  Stream<bool> get playingStream;

  Stream<bool> get bufferingStream;

  Stream<PlayerTracks> get tracksStream;

  Stream<double> get rateStream;

  Stream<String> get errorStream;

  Stream<List<String>> get subtitleStream;

  Stream<int?> get heightStream;

  Stream<bool> get completedStream;

  PlayerState get state;

  Future<void> initialize();

  Future<void> open(
    String url, {
    Map<String, String>? headers,
    Duration? startPosition,
  });

  Future<void> seek(Duration position);

  Future<void> play();

  Future<void> pause();

  Future<void> playOrPause();

  Future<void> setRate(double rate);

  Future<void> setVolume(double volume);

  Future<void> setVideoTrack(VideoTrack track);

  Future<void> setAudioTrack(AudioTrack track);

  Future<void> setSubtitleTrack(SubtitleTrack track);

  Future<void> toggleVideoFit(BoxFit fit);

  Future<Uint8List?> screenshot({
    bool includeSubtitles = true,
    String format = 'image/png',
  });

  Future<void> dispose();

  Widget getVideoWidget({
    BoxFit? fit,
    double? width,
    double? height,
  });

  Future<void> setHardwareDecoding(String mode);
}

class PlayerState {
  final Duration position;
  final Duration duration;
  final Duration buffer;
  final bool isPlaying;
  final bool isBuffering;
  final double volume;
  final double rate;
  final int? videoHeight;

  PlayerState({
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.buffer = Duration.zero,
    this.isPlaying = false,
    this.isBuffering = true,
    this.volume = 1.0,
    this.rate = 1.0,
    this.videoHeight,
  });

  PlayerState copyWith({
    Duration? position,
    Duration? duration,
    Duration? buffer,
    bool? isPlaying,
    bool? isBuffering,
    double? volume,
    double? rate,
    int? videoHeight,
  }) {
    return PlayerState(
      position: position ?? this.position,
      duration: duration ?? this.duration,
      buffer: buffer ?? this.buffer,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      volume: volume ?? this.volume,
      rate: rate ?? this.rate,
      videoHeight: videoHeight ?? this.videoHeight,
    );
  }
}

class PlayerTracks {
  final List<AudioTrack> audio;
  final List<SubtitleTrack> subtitle;
  final List<VideoTrack> video;

  PlayerTracks({
    this.audio = const [],
    this.subtitle = const [],
    this.video = const [],
  });
}

class AudioTrack {
  final String id;
  final String? title;
  final String? language;
  final String? url;

  AudioTrack({
    required this.id,
    this.title,
    this.language,
    this.url,
  });

  factory AudioTrack.uri(String uri, {String? title, String? language}) {
    return AudioTrack(
      id: uri,
      title: title,
      language: language,
      url: uri,
    );
  }

  factory AudioTrack.no() {
    return AudioTrack(id: 'no', title: 'No Audio');
  }

  factory AudioTrack.auto() {
    return AudioTrack(id: 'auto', title: 'Auto');
  }
}

class SubtitleTrack {
  final String id;
  final String? title;
  final String? language;
  final String? url;

  SubtitleTrack({
    required this.id,
    this.title,
    this.language,
    this.url,
  });

  factory SubtitleTrack.uri(String uri, {String? title, String? language}) {
    return SubtitleTrack(
      id: uri,
      title: title,
      language: language,
      url: uri,
    );
  }

  factory SubtitleTrack.no() {
    return SubtitleTrack(id: 'no', title: 'No Subtitle');
  }

  factory SubtitleTrack.auto() {
    return SubtitleTrack(id: 'auto', title: 'Auto');
  }
}

class VideoTrack {
  final String id;
  final String? title;
  final int? width;
  final int? height;
  final int? bitrate;

  VideoTrack({
    required this.id,
    this.title,
    this.width,
    this.height,
    this.bitrate,
  });

  factory VideoTrack.no() {
    return VideoTrack(id: 'no', title: 'No Video');
  }

  factory VideoTrack.auto() {
    return VideoTrack(id: 'auto', title: 'Auto');
  }
}

enum PlayerType {
  mediaKit,
  betterPlayer,
}

class PlayerConfiguration {
  final int bufferSize;
  final bool useLibass;
  final String hwdec;
  final PlayerType playerType;
  final bool enableCache;
  final Duration? seekAccuracy;

  PlayerConfiguration({
    this.bufferSize = 1024 * 1024 * 32,
    this.useLibass = false,
    this.hwdec = 'no',
    this.playerType = PlayerType.mediaKit,
    this.enableCache = true,
    this.seekAccuracy,
  });
}
