import 'dart:ui';
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/watch_settings_pane.dart';
import 'package:anymex/screens/anime/widgets/episode/episode_style_registry.dart';
import 'package:anymex/utils/string_extensions.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EpisodeSidePane extends StatefulWidget {
  final Widget child;
  final Duration animationDuration;
  final Curve animationCurve;
  final Color? backgroundColor;
  final Color? shadowColor;
  final bool isVisible;
  final VoidCallback? onOverlayTap;

  const EpisodeSidePane({
    super.key,
    required this.child,
    required this.isVisible,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeOutCubic,
    this.backgroundColor,
    this.shadowColor,
    this.onOverlayTap,
  });

  @override
  State<EpisodeSidePane> createState() => _EpisodeSidePaneState();
}

class _EpisodeSidePaneState extends State<EpisodeSidePane>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _overlayAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.animationCurve,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _overlayAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    if (widget.isVisible) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(EpisodeSidePane oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Visibility(
          visible: _controller.value > 0 || widget.isVisible,
          child: Stack(
            children: [
              GestureDetector(
                onTap: widget.onOverlayTap,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black.opaque(_overlayAnimation.value),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      width: context.width *
                          getResponsiveSize(context,
                              mobileSize: 0.6, desktopSize: 0.4),
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: widget.backgroundColor ??
                            context.theme.colorScheme.surfaceContainer.withOpacity(0.75),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          bottomLeft: Radius.circular(24),
                        ),
                        border: Border(
                          left: BorderSide(
                            color: context.theme.colorScheme.onSurface.withOpacity(0.08),
                            width: 1.0,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                widget.shadowColor ?? Colors.black.opaque(0.3),
                            blurRadius: 20,
                            offset: const Offset(-4, 0),
                          ),
                          BoxShadow(
                            color:
                                context.theme.colorScheme.primary.opaque(0.1),
                            blurRadius: 30,
                            offset: const Offset(-8, 0),
                          ),
                        ],
                      ),
                       child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          bottomLeft: Radius.circular(24),
                        ),
                        child: _controller.value > 0.95
                            ? BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 8.0 * ((_controller.value - 0.95) / 0.05),
                                  sigmaY: 8.0 * ((_controller.value - 0.95) / 0.05),
                                ),
                                child: widget.child,
                              )
                            : widget.child,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class EpisodesPane extends StatelessWidget {
  final PlayerController controller;

  const EpisodesPane({
    super.key,
    required this.controller,
  });

  void _closePane() {
    controller.isEpisodePaneOpened.value = false;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => EpisodeSidePane(
          isVisible: controller.isEpisodePaneOpened.value,
          onOverlayTap: _closePane,
          child: WatchSettingsPane(
            title: 'Episodes',
            onClose: _closePane,
            actions: [
              IconButton(
                onPressed: () {
                  final styles = EpisodeStyleRegistry.styles;
                  final currentId = EpisodeStyleRegistry.currentStyleId.value;
                  final currentIndex = styles.indexWhere((s) => s.id == currentId);
                  final nextIndex = (currentIndex + 1) % styles.length;
                  EpisodeStyleRegistry.setStyle(styles[nextIndex].id);
                },
                style: IconButton.styleFrom(
                  backgroundColor: context.theme.colorScheme.surfaceContainerHigh,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Obx(() {
                  final currentId = EpisodeStyleRegistry.currentStyleId.value;
                  final icon = currentId == 'minimal'
                      ? Icons.list_rounded
                      : currentId == 'compact'
                          ? Icons.grid_view_rounded
                          : Icons.view_stream_rounded;
                  return Icon(icon, color: context.theme.colorScheme.onSurface);
                }),
              ),
            ],
            child: controller.episodeList.isEmpty
                ? const SizedBox.shrink()
                : Obx(() {
                    final currentStyle = EpisodeStyleRegistry.activeStyle;
                    final episodes = controller.episodeList;
                    final initialIndex = (() {
                      if (controller.isOffline.value) {
                        final idx = episodes.indexWhere(
                            (e) => e.link == controller.selectedVideo.value?.url);
                        return idx >= 0 ? idx : 0;
                      }
                      final numIdx =
                          controller.currentEpisode.value.number.toInt() - 1;
                      return numIdx.clamp(0, episodes.length - 1);
                    })();

                    final double itemHeight = currentStyle.id == 'minimal'
                        ? 75.0
                        : currentStyle.id == 'compact'
                            ? 110.0
                            : 120.0;
                    
                    final double initialOffset = (initialIndex * itemHeight).clamp(0.0, double.infinity);
                    final scrollController = ScrollController(initialScrollOffset: initialOffset);

                    if (currentStyle.isGrid) {
                      return GridView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: getResponsiveCrossAxisCount(
                            context,
                            baseColumns: 1,
                            maxColumns: 2,
                            mobileItemWidth: 200,
                            tabletItemWidth: 200,
                            desktopItemWidth: 200,
                          ),
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          mainAxisExtent: currentStyle.id == 'minimal' ? 65 : 100,
                        ),
                        itemCount: episodes.length,
                        itemBuilder: (context, index) {
                          final episode = episodes[index];
                          final isSelected = controller.isOffline.value
                              ? episode.link ==
                                  controller.selectedVideo.value?.url
                              : episode.number == controller.currentEpisode.value.number;
                          final offlineEpisodes = controller.offlineStorage
                              .getAnimeById(controller.anilistData.id)
                              ?.episodes;
                          final isWatched = (offlineEpisodes ?? []).any((e) => e.number == episode.number);
                          
                          double progress = 0.0;
                          if (offlineEpisodes != null) {
                            final matching = offlineEpisodes.firstWhereOrNull((e) => e.number == episode.number);
                            if (matching != null && matching.durationInMilliseconds != null && matching.durationInMilliseconds! > 0) {
                              progress = (matching.timeStampInMilliseconds ?? 0) / matching.durationInMilliseconds!;
                            }
                          }

                          return currentStyle.builder(
                            context,
                            episode,
                            isSelected,
                            isWatched,
                            progress,
                            controller.anilistData,
                            () => controller.changeEpisode(episode),
                            null,
                          );
                        },
                      );
                    } else {
                      return ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: episodes.length,
                        itemBuilder: (context, index) {
                          final episode = episodes[index];
                          final isSelected = controller.isOffline.value
                              ? episode.link ==
                                  controller.selectedVideo.value?.url
                              : episode.number == controller.currentEpisode.value.number;
                          final offlineEpisodes = controller.offlineStorage
                              .getAnimeById(controller.anilistData.id)
                              ?.episodes;
                          final isWatched = (offlineEpisodes ?? []).any((e) => e.number == episode.number);
                          
                          double progress = 0.0;
                          if (offlineEpisodes != null) {
                            final matching = offlineEpisodes.firstWhereOrNull((e) => e.number == episode.number);
                            if (matching != null && matching.durationInMilliseconds != null && matching.durationInMilliseconds! > 0) {
                              progress = (matching.timeStampInMilliseconds ?? 0) / matching.durationInMilliseconds!;
                            }
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: currentStyle.builder(
                              context,
                              episode,
                              isSelected,
                              isWatched,
                              progress,
                              controller.anilistData,
                              () => controller.changeEpisode(episode),
                              null,
                            ),
                          );
                        },
                      );
                    }
                  }),
          ),
        ));
  }
}
