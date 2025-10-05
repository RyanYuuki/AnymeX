import 'package:anymex/models/Offline/Hive/video.dart';
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/screens/anime/watch/subtitles/subtitle_view.dart';
import 'package:anymex/screens/anime/widgets/episode/normal_episode.dart';
import 'package:dartotsu_extension_bridge/Mangayomi/string_extensions.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart' hide Track;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class DynamicBottomSheet extends StatefulWidget {
  final String title;
  final List<BottomSheetItem> items;
  final int? selectedIndex;
  final Function(int)? onItemSelected;
  final Widget? customContent;

  const DynamicBottomSheet({
    super.key,
    required this.title,
    this.items = const [],
    this.selectedIndex,
    this.onItemSelected,
    this.customContent,
  });

  @override
  State<DynamicBottomSheet> createState() => _DynamicBottomSheetState();
}

class _DynamicBottomSheetState extends State<DynamicBottomSheet>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  List<BottomSheetItem> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _slideController.forward();
    Future.delayed(const Duration(milliseconds: 100), () {
      _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items
            .where((item) =>
                item.title.toLowerCase().contains(query.toLowerCase()) ||
                (item.subtitle?.toLowerCase().contains(query.toLowerCase()) ??
                    false))
            .toList();
      }
    });
  }

  void _closeBottomSheet() async {
    await _fadeController.reverse();
    await _slideController.reverse();
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: _closeBottomSheet,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SlideTransition(
              position: _slideAnimation,
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                decoration: BoxDecoration(
                  color: context.theme.colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  border: Border.all(
                    color: context.theme.colorScheme.outline.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: context.theme.colorScheme.primary.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color:
                            context.theme.colorScheme.outline.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.title,
                                style: context.theme.textTheme.titleLarge
                                    ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: context.theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: _closeBottomSheet,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: context
                                      .theme.colorScheme.surfaceVariant
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
                    ),
                    Flexible(
                      child: widget.customContent ?? _buildItemsList(),
                    ),
                    SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filteredItems.length,
        itemBuilder: (context, index) {
          final item = _filteredItems[index];
          final isSelected = widget.selectedIndex == widget.items.indexOf(item);

          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 300 + (index * 50)),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: _BottomSheetListItem(
              item: item,
              isSelected: isSelected,
              onTap: () {
                if (widget.onItemSelected != null) {
                  widget.onItemSelected!(widget.items.indexOf(item));
                }
                _closeBottomSheet();
              },
            ),
          );
        },
      ),
    );
  }
}

class _BottomSheetListItem extends StatefulWidget {
  final BottomSheetItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _BottomSheetListItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_BottomSheetListItem> createState() => _BottomSheetListItemState();
}

class _BottomSheetListItemState extends State<_BottomSheetListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: MouseRegion(
        onEnter: (_) {
          setState(() => _isHovered = true);
          _hoverController.forward();
        },
        onExit: (_) {
          setState(() => _isHovered = false);
          _hoverController.reverse();
        },
        child: GestureDetector(
          onTapDown: (_) => _hoverController.forward(),
          onTapUp: (_) => _hoverController.reverse(),
          onTapCancel: () => _hoverController.reverse(),
          onTap: widget.onTap,
          child: AnimatedBuilder(
            animation: _hoverController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: widget.isSelected
                        ? context.theme.colorScheme.primary.withOpacity(0.12)
                        : (_isHovered
                            ? context.theme.colorScheme.primary
                                .withOpacity(0.08)
                            : Colors.transparent),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.isSelected
                          ? context.theme.colorScheme.primary.withOpacity(0.3)
                          : (_isHovered
                              ? context.theme.colorScheme.primary
                                  .withOpacity(0.2)
                              : Colors.transparent),
                      width: widget.isSelected ? 1.0 : 0.5,
                    ),
                    boxShadow: widget.isSelected || _isHovered
                        ? [
                            BoxShadow(
                              color:
                                  context.theme.colorScheme.primary.withOpacity(
                                widget.isSelected ? 0.2 : 0.1,
                              ),
                              blurRadius: widget.isSelected ? 12 : 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      if (widget.item.icon != null)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: widget.isSelected
                                ? context.theme.colorScheme.primary
                                    .withOpacity(0.15)
                                : context.theme.colorScheme.surfaceVariant
                                    .withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            widget.item.icon,
                            size: 20,
                            color: widget.isSelected
                                ? context.theme.colorScheme.primary
                                : context.theme.colorScheme.onSurface
                                    .withOpacity(0.7),
                          ),
                        ),
                      if (widget.item.icon != null) const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.item.title,
                              style:
                                  context.theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: widget.isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: widget.isSelected
                                    ? context.theme.colorScheme.primary
                                    : context.theme.colorScheme.onSurface,
                              ),
                            ),
                            if (widget.item.subtitle != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  widget.item.subtitle!,
                                  style: context.theme.textTheme.bodySmall
                                      ?.copyWith(
                                    color: context.theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (widget.item.trailing != null)
                        widget.item.trailing!
                      else if (widget.isSelected)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: context.theme.colorScheme.primary
                                .withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.check,
                            size: 16,
                            color: context.theme.colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class BottomSheetItem {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final dynamic value;

  const BottomSheetItem({
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.value,
  });
}

class PlayerBottomSheets {
  static Future<T?> show<T>(
      {required BuildContext context,
      required String title,
      List<BottomSheetItem> items = const [],
      int? selectedIndex,
      Function(int)? onItemSelected,
      Widget? customContent,
      bool showSearch = false,
      String? searchHint,
      bool isDismissible = true,
      bool isExpanded = false}) {
    final sheet = DynamicBottomSheet(
      title: title,
      items: items,
      selectedIndex: selectedIndex,
      onItemSelected: onItemSelected,
      customContent: customContent,
    );
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          !isExpanded ? sheet : SizedBox(height: double.infinity, child: sheet),
    );
  }

  static Future<int?> showAudioTracks(
      BuildContext context, PlayerController controller) {
    final tracks = controller.embeddedAudioTracks.value;
    final currentIndex =
        tracks.indexOf(controller.selectedAudioTrack.value ?? tracks.first);
    return show<int>(
      context: context,
      title: 'Audio Tracks',
      showSearch: tracks.length > 5,
      searchHint: 'Search audio tracks...',
      items: [
        const BottomSheetItem(
            title: 'Auto', subtitle: 'Audio Track', icon: Icons.audiotrack),
        ...tracks
            .where((e) => e.title != null && e.language != null)
            .map((entry) {
          return BottomSheetItem(
            title: (entry.language ?? entry.title ?? entry.uri.toString())
                .toUpperCase(),
            subtitle: 'Audio Track',
            icon: Icons.audiotrack,
          );
        })
      ],
      selectedIndex: currentIndex < 0 ? 0 : currentIndex,
      onItemSelected: (index) => Get.back(result: index),
    );
  }

  static Future<int?> showOfflineSubs(
      BuildContext context, PlayerController controller) {
    final tracks = controller.embeddedSubs.value;
    final currentIndex =
        tracks.indexOf(controller.selectedSubsTrack.value ?? tracks.first);
    return show<int>(
      context: context,
      title: 'Subtitle Tracks',
      showSearch: tracks.length > 5,
      searchHint: 'Search subtitle tracks...',
      items: [
        const BottomSheetItem(
            title: 'None', subtitle: 'Subtitle Track', icon: Icons.audiotrack),
        ...tracks
            .where((e) => e.title != null && e.language != null)
            .map((entry) {
          return BottomSheetItem(
            title: (entry.language ?? entry.title ?? entry.uri.toString())
                .toUpperCase(),
            subtitle: 'Subtitle Track',
            icon: Icons.closed_caption_rounded,
          );
        })
      ],
      selectedIndex: currentIndex < 0 ? 0 : currentIndex,
      onItemSelected: (index) {
        if (index == 0) {
          controller.setSubtitleTrack(SubtitleTrack.no());
        } else {
          final selectedTrack = tracks[index];
          controller.selectedSubsTrack.value = selectedTrack;
          controller.setSubtitleTrack(selectedTrack);
        }
        Get.back(result: index);
      },
    );
  }

  static Future<int?> showSubtitleTracks(
    BuildContext context,
    PlayerController controller,
  ) {
    final tracks = controller.externalSubs.value;
    final selectedTrack = tracks.indexOf(controller.selectedExternalSub.value);

    return show<int>(
      context: context,
      title: 'Subtitles',
      items: [
        const BottomSheetItem(
          title: 'Search Online',
          subtitle: 'Find subtitles online',
          icon: Icons.cloud_download,
        ),
        const BottomSheetItem(
          title: 'None',
          subtitle: 'No subtitles',
          icon: Icons.subtitles_off,
        ),
        ...tracks.map((e) => BottomSheetItem(
              title: e.label ?? 'No Title',
              subtitle: 'Local Subtitle Track',
              icon: Icons.subtitles,
            )),
      ],
      selectedIndex: controller.selectedExternalSub.value == Track()
          ? 1
          : selectedTrack + 2,
      onItemSelected: (index) {
        if (index == 0) {
          Future.delayed(const Duration(milliseconds: 1000), () {
            controller.isSubtitlePaneOpened.value = true;
          });
          return;
        } else if (index == 1) {
          controller.setExternalSub(null);
        } else {
          final selectedTrack = tracks[index - 2];
          controller.setExternalSub(selectedTrack);
        }
      },
    );
  }

  static Future<String?> showVideoServers(
      BuildContext context, PlayerController controller) {
    final qualities = controller.episodeTracks;
    final selectedQuality = controller.selectedVideo.value;
    return show<String>(
      context: context,
      title: 'Video Servers',
      items: qualities.map((quality) {
        return BottomSheetItem(
          title: quality.quality,
          subtitle: 'Server',
          icon: Icons.high_quality,
        );
      }).toList(),
      selectedIndex:
          selectedQuality != null ? qualities.indexOf(selectedQuality) : 0,
      onItemSelected: (index) {
        final selectedQuality = qualities[index];
        controller.setServerTrack(selectedQuality);
      },
    );
  }

  static Future<String?> showVideoQuality(
      BuildContext context, PlayerController controller) {
    final qualities = controller.embeddedQuality.value;
    final selectedQuality = controller.selectedQualityTrack.value;
    return show<String>(
      context: context,
      title: 'Video Quality',
      items: qualities.where((e) => e.h != null && e.w != null).map((quality) {
        return BottomSheetItem(
          title: quality.h == 0 ? 'Auto' : '${quality.w}x${quality.h}',
          subtitle: 'Quality Setting',
          icon: Icons.high_quality,
        );
      }).toList(),
      selectedIndex:
          selectedQuality != null ? qualities.indexOf(selectedQuality) : 0,
      onItemSelected: (index) {
        final selectedQuality = qualities[index];
        controller.setVideoTrack(selectedQuality);
      },
    );
  }

  static Future<double?> showPlaybackSpeed(
      BuildContext context, PlayerController controller) {
    final speeds = [
      0.25,
      0.5,
      0.75,
      1.0,
      1.25,
      1.5,
      1.75,
      2.0,
      for (var i = 2.5; i < 20; i += 0.5) i
    ];
    final selectedSpeed = controller.playbackSpeed.value;

    return show<double>(
      context: context,
      title: 'Playback Speed',
      items: speeds.map((speed) {
        return BottomSheetItem(
          title: speed == 1.0 ? 'Normal' : '${speed}x',
          subtitle: 'Playback Speed',
          icon: speed < 1.0
              ? Icons.slow_motion_video
              : speed > 1.0
                  ? Icons.fast_forward
                  : Icons.play_arrow,
        );
      }).toList(),
      selectedIndex: speeds.indexOf(selectedSpeed),
      onItemSelected: (index) {
        final selectedSpeed = speeds[index];
        controller.setRate(selectedSpeed);
      },
    );
  }

  static Future<double?> showPlaylist(
      BuildContext context, PlayerController controller) {
    final episodes = controller.episodeList;
    final selectedEpisode = controller.currentEpisode;
    final offlineEpisode = controller.offlineStorage
        .getAnimeById(controller.anilistData.id)
        ?.episodes;

    return showCustom<double>(
      context: context,
      title: 'Episodes',
      isExpanded: true,
      content: ScrollablePositionedList.separated(
        initialScrollIndex: selectedEpisode.value.number.toInt() - 1,
        separatorBuilder: (context, i) => const SizedBox(height: 8),
        itemCount: episodes.length,
        itemBuilder: (context, index) {
          final episode = episodes[index];
          final isSelected = episode == selectedEpisode.value;

          return BetterEpisode(
            episode: episode,
            isSelected: isSelected,
            onTap: () => controller.changeEpisode(episode),
            layoutType: EpisodeLayoutType.compact,
            offlineEpisodes: offlineEpisode,
            fallbackImageUrl:
                controller.anilistData.cover ?? controller.anilistData.poster,
          );
        },
      ),
    );
  }

  static Future<T?> showCustom<T>(
      {required BuildContext context,
      required String title,
      required Widget content,
      bool isExpanded = false}) {
    return show<T>(
      context: context,
      title: title,
      isExpanded: isExpanded,
      customContent: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: content,
      ),
    );
  }

  static showLoader() {
    Get.bottomSheet(
      ClipRRect(
        borderRadius: BorderRadius.circular((20)),
        child: Container(
          color: Get.theme.colorScheme.surface,
          child: const Center(
            child: ExpressiveLoadingIndicator(),
          ),
        ),
      ),
    );
  }

  static hideLoader() => Get.back();
}
