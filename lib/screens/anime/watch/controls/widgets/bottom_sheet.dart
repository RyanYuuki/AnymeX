import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/screens/anime/watch/player/base_player.dart';
import 'package:anymex/screens/anime/widgets/episode/normal_episode.dart';
import 'package:anymex/utils/language.dart';
import 'package:anymex/utils/string_extensions.dart';
import 'package:anymex/utils/theme_extensions.dart';

import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
              child: GestureDetector(
                onTap: () {},
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
                      color: context.theme.colorScheme.outline
                          .opaque(0.2, iReallyMeanIt: true),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: context.theme.colorScheme.primary
                            .opaque(0.1, iReallyMeanIt: true),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                      BoxShadow(
                        color: Colors.black.opaque(0.3, iReallyMeanIt: true),
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
                          color: context.theme.colorScheme.outline
                              .opaque(0.3, iReallyMeanIt: true),
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
                                        .opaque(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    size: 20,
                                    color: context.theme.colorScheme.onSurface
                                        .opaque(0.7, iReallyMeanIt: true),
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
            )
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
            duration: const Duration(milliseconds: 300),
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
                        ? context.theme.colorScheme.primary
                            .opaque(0.12, iReallyMeanIt: true)
                        : (_isHovered
                            ? context.theme.colorScheme.primary
                                .opaque(0.08, iReallyMeanIt: true)
                            : Colors.transparent),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.isSelected
                          ? context.theme.colorScheme.primary
                              .opaque(0.3, iReallyMeanIt: true)
                          : (_isHovered
                              ? context.theme.colorScheme.primary
                                  .opaque(0.2, iReallyMeanIt: true)
                              : Colors.transparent),
                      width: widget.isSelected ? 1.0 : 0.5,
                    ),
                    boxShadow: widget.isSelected || _isHovered
                        ? [
                            BoxShadow(
                              color: context.theme.colorScheme.primary.opaque(
                                  widget.isSelected ? 0.2 : 0.1,
                                  iReallyMeanIt: true),
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
                                    .opaque(0.15, iReallyMeanIt: true)
                                : context.theme.colorScheme.surfaceVariant
                                    .opaque(0.3, iReallyMeanIt: true),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            widget.item.icon,
                            size: 20,
                            color: widget.isSelected
                                ? context.theme.colorScheme.primary
                                : context.theme.colorScheme.onSurface
                                    .opaque(0.7, iReallyMeanIt: true),
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
                                        .opaque(0.6, iReallyMeanIt: true),
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
                                .opaque(0.15, iReallyMeanIt: true),
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
    return Get.find<PlayerController>().showSheetWithPause(
      () => showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        isDismissible: isDismissible,
        backgroundColor: Colors.transparent,
        builder: (context) =>
            !isExpanded ? sheet : SizedBox(height: double.infinity, child: sheet),
      ),
    );
  }

  static Future<int?> showAudioTracks(
      BuildContext context, PlayerController controller) {
    final tracks = controller.embeddedAudioTracks.value;
    final filteredTracks =
        tracks.where((e) => e.title != null && e.language != null).toList();
    final currentIndex = filteredTracks
            .indexOf(controller.selectedAudioTrack.value ?? tracks.first) +
        1;

    return show<int>(
      context: context,
      title: 'Audio Tracks',
      showSearch: filteredTracks.length > 5,
      searchHint: 'Search audio tracks...',
      items: [
        const BottomSheetItem(
            title: 'Auto', subtitle: 'Audio Track', icon: Icons.audiotrack),
        ...tracks.where((e) => e.title != null).map((entry) {
          return BottomSheetItem(
            title: completeLanguageName(entry.language ?? '').toUpperCase(),
            subtitle: 'Audio Track',
            icon: Icons.audiotrack,
          );
        })
      ],
      selectedIndex: currentIndex < 0 ? 0 : currentIndex,
      onItemSelected: (index) {
        if (index == 0) {
          controller.setAudioTrack(AudioTrack.auto());
          controller.selectedAudioTrack.value = AudioTrack.auto();
        } else {
          final selectedTrack = filteredTracks[index - 1];
          controller.setAudioTrack(selectedTrack);
          controller.selectedAudioTrack.value = selectedTrack;
        }
        Get.back(result: index);
      },
    );
  }

  static Future<T?> showCustom<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    bool isExpanded = false,
    double expandedHeightFactor = 0.8,
  }) {
    final sheet = DynamicBottomSheet(
      title: title,
      customContent: content,
    );
    return Get.find<PlayerController>().showSheetWithPause(
      () => showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => isExpanded
            ? SizedBox(
                height: MediaQuery.of(context).size.height * expandedHeightFactor,
                child: sheet)
            : sheet,
      ),
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
          title: quality.quality ?? 'Auto',
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
    final qualities = controller.embeddedQuality.value
        .where((e) => e.height != null && e.width != null)
        .toList();
    final selectedQuality = controller.selectedQualityTrack.value;
    return show<String>(
      context: context,
      title: 'Video Quality',
      items: qualities.map((quality) {
        return BottomSheetItem(
          title: quality.height == 0
              ? 'Auto'
              : '${quality.width}x${quality.height}',
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

  static void showLoader() {
    Get.bottomSheet(
      PopScope(
        canPop: false,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            color: Get.theme.colorScheme.surface,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 32),
                ExpressiveLoadingIndicator(),
                SizedBox(height: 24),
                _LoaderContent(),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      isDismissible: false,
      enableDrag: false,
    );
  }

  static hideLoader() {
    if (Get.isBottomSheetOpen ?? false) {
      Get.back();
    }
  }
}

class _LoaderContent extends StatefulWidget {
  const _LoaderContent();

  @override
  State<_LoaderContent> createState() => _LoaderContentState();
}

class _LoaderContentState extends State<_LoaderContent> {
  bool _showWarning = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) setState(() => _showWarning = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: _showWarning
          ? Column(
              children: [
                Text(
                  'Taking longer than expected...',
                  style: Get.theme.textTheme.bodyMedium?.copyWith(
                    color: Get.theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Go Back'),
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }
}
