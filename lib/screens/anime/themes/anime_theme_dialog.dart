import 'dart:ui';

import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/models/Media/media.dart' as m;
import 'package:anymex/models/animethemes/anime_theme.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class AnimeThemePlayerDialog extends StatefulWidget {
  final List<AnimeTheme> themes;
  final int initialIndex;
  final m.Media animeDetails;

  const AnimeThemePlayerDialog({
    super.key,
    required this.themes,
    required this.initialIndex,
    required this.animeDetails,
  });

  static Future<void> show(
    BuildContext context, {
    required List<AnimeTheme> themes,
    required int initialIndex,
    required m.Media animeDetails,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => AnimeThemePlayerDialog(
        themes: themes,
        initialIndex: initialIndex,
        animeDetails: animeDetails,
      ),
    );
  }

  @override
  State<AnimeThemePlayerDialog> createState() => _AnimeThemePlayerDialogState();
}

class _AnimeThemePlayerDialogState extends State<AnimeThemePlayerDialog> {
  late final Player _player;
  late final VideoController _controller;

  late int _currentIndex;
  bool _isPlaying = false;
  bool _isBuffering = false;
  bool _hasStarted = false;
  bool _isError = false;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  bool _isSeeking = false;
  double _seekValue = 0.0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.themes.length - 1);
    _player = Player();
    _controller = VideoController(_player);
    _setupListeners();
    _playTheme(_currentIndex);
  }

  void _setupListeners() {
    _player.stream.playing.listen((playing) {
      if (mounted) setState(() => _isPlaying = playing);
    });

    _player.stream.position.listen((position) {
      if (mounted && !_isSeeking) {
        setState(() => _position = position);
      }
    });

    _player.stream.duration.listen((duration) {
      if (mounted) setState(() => _duration = duration);
    });

    _player.stream.buffering.listen((buffering) {
      if (mounted) setState(() => _isBuffering = buffering);
    });

    _player.stream.completed.listen((completed) {
      if (completed && mounted && _currentIndex < widget.themes.length - 1) {
        _playTheme(_currentIndex + 1);
      }
    });

    _player.stream.error.listen((_) {
      if (mounted) {
        setState(() {
          _isError = true;
          _isBuffering = false;
        });
      }
    });
  }

  Future<void> _playTheme(int index) async {
    if (index < 0 || index >= widget.themes.length) return;
    final theme = widget.themes[index];
    final url = theme.videoUrl ?? theme.audioUrl;
    if (url == null || url.isEmpty) {
      if (mounted) {
        setState(() {
          _currentIndex = index;
          _isError = true;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _currentIndex = index;
        _isError = false;
        _hasStarted = false;
        _isBuffering = true;
        _position = Duration.zero;
        _duration = Duration.zero;
      });
    }

    try {
      await _player.open(Media(url), play: true);
      if (mounted) {
        setState(() => _hasStarted = true);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isError = true;
          _isBuffering = false;
        });
      }
    }
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  void _seekBy(int seconds) {
    final target = _position + Duration(seconds: seconds);
    final clamped = target < Duration.zero
        ? Duration.zero
        : (target > _duration ? _duration : target);
    _player.seek(clamped);
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final currentTheme = widget.themes[_currentIndex];
    final isOP = currentTheme.type.toUpperCase().startsWith('OP');
    final badgeColor = isOP ? colors.primary : colors.secondary;
    final badgeText =
        '${currentTheme.type}${currentTheme.sequence != null ? ' ${currentTheme.sequence}' : ''}';

    final totalMs = _duration.inMilliseconds.toDouble();
    final currentMs = _position.inMilliseconds.toDouble();
    final sliderVal = _isSeeking
        ? _seekValue
        : (totalMs > 0 ? currentMs.clamp(0.0, totalMs) : 0.0);
    final sliderMax = totalMs > 0 ? totalMs : 1.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: getResponsiveValue(
          context,
          mobileValue: double.infinity,
          desktopValue: 500.0,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceContainer.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(24.multiplyRadius()),
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.multiplyRadius()),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: badgeColor.withValues(alpha: 0.35),
                          ),
                        ),
                        child: AnymeXText(
                          badgeText,
                          size: 11,
                          variant: TextVariant.bold,
                          color: badgeColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AnymeXText(
                          widget.animeDetails.title,
                          size: 12.5,
                          variant: TextVariant.semiBold,
                          color: colors.onSurfaceVariant,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.close_rounded, size: 20),
                        color: colors.onSurfaceVariant,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16.multiplyRadius()),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        color: Colors.black,
                        child: Stack(
                          fit: StackFit.expand,
                          alignment: Alignment.center,
                          children: [
                            Video(
                              controller: _controller,
                              fit: BoxFit.contain,
                              controls: null,
                            ),
                            if (_isBuffering || !_hasStarted)
                              Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: colors.primary,
                                ),
                              ),
                            if (_isError)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: AnymeXText(
                                    'Unable to load theme video',
                                    color: colors.error,
                                    size: 13,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnymeXText(
                          currentTheme.title,
                          size: 15,
                          variant: TextVariant.bold,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (currentTheme.artist.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          AnymeXText(
                            currentTheme.artist,
                            size: 12.5,
                            color: colors.onSurfaceVariant,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 3.0,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 12.0),
                      activeTrackColor: colors.primary,
                      inactiveTrackColor:
                          colors.onSurface.withValues(alpha: 0.12),
                      thumbColor: colors.primary,
                      overlayColor: colors.primary.withValues(alpha: 0.2),
                      trackShape: const RectangularSliderTrackShape(),
                    ),
                    child: Slider(
                      value: sliderVal,
                      min: 0.0,
                      max: sliderMax,
                      onChanged: (val) {
                        setState(() {
                          _isSeeking = true;
                          _seekValue = val;
                        });
                      },
                      onChangeEnd: (val) {
                        _player.seek(Duration(milliseconds: val.toInt()));
                        setState(() => _isSeeking = false);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AnymeXText(
                          _formatDuration(_isSeeking
                              ? Duration(milliseconds: _seekValue.toInt())
                              : _position),
                          size: 11,
                          color: colors.onSurfaceVariant,
                        ),
                        AnymeXText(
                          _formatDuration(_duration),
                          size: 11,
                          color: colors.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.themes.length > 1) ...[
                        IconButton(
                          icon:
                              const Icon(Icons.skip_previous_rounded, size: 26),
                          color: _currentIndex > 0
                              ? colors.onSurface
                              : colors.onSurface.withValues(alpha: 0.3),
                          onPressed: _currentIndex > 0
                              ? () => _playTheme(_currentIndex - 1)
                              : null,
                        ),
                        const SizedBox(width: 8),
                      ],
                      IconButton(
                        icon: const Icon(Icons.replay_10_rounded, size: 28),
                        color: colors.onSurface,
                        onPressed: () => _seekBy(-10),
                      ),
                      const SizedBox(width: 14),
                      GestureDetector(
                        onTap: _togglePlayPause,
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: colors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: colors.primary.withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: colors.onPrimary,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      IconButton(
                        icon: const Icon(Icons.forward_10_rounded, size: 28),
                        color: colors.onSurface,
                        onPressed: () => _seekBy(10),
                      ),
                      if (widget.themes.length > 1) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.skip_next_rounded, size: 26),
                          color: _currentIndex < widget.themes.length - 1
                              ? colors.onSurface
                              : colors.onSurface.withValues(alpha: 0.3),
                          onPressed: _currentIndex < widget.themes.length - 1
                              ? () => _playTheme(_currentIndex + 1)
                              : null,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
