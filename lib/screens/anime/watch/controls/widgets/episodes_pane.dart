import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/screens/anime/widgets/episode/normal_episode.dart';
import 'package:anymex/utils/string_extensions.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

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
                  color: Colors.black.withOpacity(_overlayAnimation.value),
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
                            context.theme.colorScheme.surface,
                        boxShadow: [
                          BoxShadow(
                            color: widget.shadowColor ??
                                Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(-4, 0),
                          ),
                          BoxShadow(
                            color: context.theme.colorScheme.primary
                                .withOpacity(0.1),
                            blurRadius: 30,
                            offset: const Offset(-8, 0),
                          ),
                        ],
                      ),
                      child: widget.child,
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
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      context.theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  border: Border(
                    bottom: BorderSide(
                      color: context.theme.colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Episodes',
                        style: context.theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _closePane,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: context.theme.colorScheme.surfaceVariant
                              .withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.close,
                          size: 20,
                          color: context.theme.colorScheme.onSurface
                              .withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ScrollablePositionedList.separated(
                    initialScrollIndex:
                        controller.currentEpisode.value.number.toInt() - 1,
                    separatorBuilder: (context, i) => const SizedBox(height: 8),
                    itemCount: controller.episodeList.length,
                    itemBuilder: (context, index) {
                      final episode = controller.episodeList[index];
                      final isSelected =
                          episode == controller.currentEpisode.value;
                      final offlineEpisode = controller.offlineStorage
                          .getAnimeById(controller.anilistData.id)
                          ?.episodes;

                      return BetterEpisode(
                        episode: episode,
                        isSelected: isSelected,
                        onTap: () => controller.changeEpisode(episode),
                        layoutType: EpisodeLayoutType.detailed,
                        offlineEpisodes: offlineEpisode,
                        fallbackImageUrl: controller.anilistData.cover ??
                            controller.anilistData.poster,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ));
  }
}
