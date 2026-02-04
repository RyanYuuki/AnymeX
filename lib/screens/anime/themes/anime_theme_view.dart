import 'dart:ui';

import 'package:anymex/models/animethemes/anime_theme.dart';
import 'package:anymex/utils/anime_themes_api.dart';
import 'package:flutter/material.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../models/Media/media.dart' as m;

class AnimeThemePlayerPage extends StatefulWidget {
  final m.Media animeDetails;

  const AnimeThemePlayerPage({
    super.key,
    required this.animeDetails,
  });

  @override
  State<AnimeThemePlayerPage> createState() => _AnimeThemePlayerPageState();
}

class _AnimeThemePlayerPageState extends State<AnimeThemePlayerPage> {
  late final Player player;
  late final VideoController controller;

  String animeTitle = '';
  List<AnimeTheme> themes = [];
  bool isLoading = true;
  String? error;
  int currentThemeIndex = -1;

  bool isPlaying = false;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;
  bool isBuffering = false;

  bool isSeeking = false;
  double seekValue = 0.0;

  @override
  void initState() {
    super.initState();
    player = Player();
    controller = VideoController(player);
    _initializePlayer();
    _loadAnimeData();
  }

  void _initializePlayer() {
    player.stream.playing.listen((playing) {
      if (mounted) setState(() => isPlaying = playing);
    });

    player.stream.position.listen((position) {
      if (mounted && !isSeeking) setState(() => currentPosition = position);
    });

    player.stream.duration.listen((duration) {
      if (mounted) setState(() => totalDuration = duration);
    });

    player.stream.buffering.listen((buffering) {
      if (mounted) setState(() => isBuffering = buffering);
    });

    player.stream.completed.listen((completed) {
      if (completed && currentThemeIndex < themes.length - 1) {
        _playTheme(currentThemeIndex + 1);
      }
    });
  }

  Future<void> _loadAnimeData() async {
    try {
      final data =
          await AnimeThemesAPI.getAnimeData(widget.animeDetails.id.toString());
      if (mounted) {
        setState(() {
          animeTitle = data['title'] ?? widget.animeDetails.title;
          themes = data['themes'] ?? [];
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          isLoading = false;
        });
      }
    }
  }

  Future<void> _playTheme(int index) async {
    if (index < 0 || index >= themes.length) return;

    final theme = themes[index];
    final url = theme.audioUrl ?? theme.videoUrl;

    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No playable media available')),
      );
      return;
    }

    try {
      await player.open(Media(url), play: true);
      setState(() => currentThemeIndex = index);
    } catch (e) {
      debugPrint('Error playing: $e');
    }
  }

  void _togglePlayPause() {
    isPlaying ? player.pause() : player.play();
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    final surfaceColor = colorScheme.surface;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  widget.animeDetails.poster,
                  fit: BoxFit.cover,
                ),
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    color: colorScheme.surface.opaque(0.5),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.opaque(0.2),
                        surfaceColor.opaque(0.8),
                        surfaceColor,
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Column(
                            children: [
                              Hero(
                                tag: 'anime_poster_${widget.animeDetails.id}',
                                child: Container(
                                  height: 220,
                                  width: 150,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.opaque(0.4),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(
                                      widget.animeDetails.poster,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24),
                                child: Column(
                                  children: [
                                    Text(
                                      widget.animeDetails.title,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(
                                              color: Colors.black45,
                                              blurRadius: 10)
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      widget.animeDetails.studios?.join(', ') ??
                                          'Unknown Studio',
                                      style: TextStyle(
                                        color: Colors.white.opaque(0.7),
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Container(
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(32)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.opaque(0.1),
                              offset: const Offset(0, -5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                margin:
                                    const EdgeInsets.only(top: 12, bottom: 8),
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: colorScheme.onSurfaceVariant
                                      .opaque(0.3),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            _buildControlsHeader(context),
                          ],
                        ),
                      ),
                    ),
                    if (isLoading)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Container(
                          color: surfaceColor,
                          child:
                              const Center(child: CircularProgressIndicator()),
                        ),
                      )
                    else if (themes.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Container(
                          color: surfaceColor,
                          child: const Center(child: Text("No themes found")),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return Container(
                              color: surfaceColor,
                              child: _buildThemeTile(index, context),
                            );
                          },
                          childCount: themes.length,
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: Container(
                        height: 120,
                        color: surfaceColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (currentThemeIndex != -1)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomPlayer(context),
            ),
        ],
      ),
    );
  }

  Widget _buildControlsHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Tracks (${themes.length})",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          FilledButton.icon(
            onPressed: themes.isNotEmpty ? () => _playTheme(0) : null,
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text("Play All"),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeTile(int index, BuildContext context) {
    final theme = themes[index];
    final isCurrent = index == currentThemeIndex;
    final colorScheme = context.colors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _playTheme(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 25,
                child: isCurrent && isPlaying
                    ? Icon(Icons.graphic_eq,
                        color: colorScheme.primary, size: 20)
                    : Text(
                        (index + 1).toString().padLeft(2, '0'),
                        style: TextStyle(
                          color: isCurrent
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                          fontWeight:
                              isCurrent ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      theme.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: isCurrent
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            theme.type +
                                (theme.sequence != null
                                    ? ' ${theme.sequence}'
                                    : ''),
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            theme.artist.isNotEmpty
                                ? theme.artist
                                : 'Unknown Artist',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isCurrent)
                Icon(Icons.volume_up_rounded,
                    color: colorScheme.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPlayer(BuildContext context) {
    final colorScheme = context.colors;
    final currentTheme = themes[currentThemeIndex];

    final double maxDuration = totalDuration.inMilliseconds.toDouble();
    final double currentVal = isSeeking
        ? seekValue
        : currentPosition.inMilliseconds.toDouble().clamp(0.0, maxDuration);

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer.opaque(0.95),
            border: Border(
              top: BorderSide(
                  color: colorScheme.outlineVariant.opaque(0.3)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.opaque(0.2),
                blurRadius: 15,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 2.0,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 0.0),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 14.0),
                  activeTrackColor: colorScheme.primary,
                  inactiveTrackColor: colorScheme.onSurface.opaque(0.1),
                  thumbColor: colorScheme.primary,
                  year2023: false,
                  overlayColor: colorScheme.primary.opaque(0.2),
                  trackShape: const RectangularSliderTrackShape(),
                ),
                child: Slider(
                  value: currentVal,
                  min: 0.0,
                  max: maxDuration > 0 ? maxDuration : 1.0,
                  onChanged: (value) {
                    setState(() {
                      isSeeking = true;
                      seekValue = value;
                    });
                  },
                  onChangeEnd: (value) {
                    player.seek(Duration(milliseconds: value.toInt()));
                    setState(() {
                      isSeeking = false;
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        widget.animeDetails.poster,
                        width: 42,
                        height: 42,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentTheme.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            currentTheme.artist.isNotEmpty
                                ? currentTheme.artist
                                : 'Unknown',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        final newPos =
                            currentPosition - const Duration(seconds: 10);
                        player.seek(
                            newPos < Duration.zero ? Duration.zero : newPos);
                      },
                      icon: const Icon(Icons.replay_10_rounded),
                      iconSize: 22,
                    ),
                    Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: _togglePlayPause,
                        icon: isBuffering
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.onPrimary,
                                ),
                              )
                            : Icon(
                                isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: colorScheme.onPrimary,
                              ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        final newPos =
                            currentPosition + const Duration(seconds: 10);
                        player.seek(
                            newPos > totalDuration ? totalDuration : newPos);
                      },
                      icon: const Icon(Icons.forward_10_rounded),
                      iconSize: 22,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
