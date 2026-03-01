import 'package:anymex/database/isar_models/track.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/screens/anime/watch/player/base_player.dart';
import 'package:anymex/screens/anime/widgets/episode/normal_episode.dart';
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
  static EpisodeLayoutType _resolveEpisodeLayoutType() {
    return switch (settingsController.episodeListLayout) {
      1 => EpisodeLayoutType.compact,
      2 => EpisodeLayoutType.blocks,
      _ => EpisodeLayoutType.detailed,
    };
  }

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
            title: (entry.title ?? entry.language ?? entry.url ?? "")
                .toUpperCase(),
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
            title: (entry.language ?? entry.title ?? entry.url.toString())
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
              title: e?.label ?? 'No Title',
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
    final qualities = controller.embeddedQuality.value;
    final selectedQuality = controller.selectedQualityTrack.value;
    return show<String>(
      context: context,
      title: 'Video Quality',
      items: qualities
          .where((e) => e.height != null && e.width != null)
          .map((quality) {
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

  static Future<double?> showPlaybackSpeed(
      BuildContext context, PlayerController controller) {
    return showCustom(
        context: context,
        title: 'Playback Speed',
        content: PlaybackSpeedSheet(controller: controller));
  }

  static Future<double?> showPlaylist(
      BuildContext context, PlayerController controller) {
    final episodes = controller.episodeList;
    final selectedEpisode = controller.currentEpisode;
    final layoutType = _resolveEpisodeLayoutType();
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
            layoutType: layoutType,
            showTitleInBlockLayout: layoutType == EpisodeLayoutType.blocks,
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
                  onPressed: () => Get.back(), // closes bottom sheet only
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Go Back'),
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }
}

class PlaybackSpeedSheet extends StatefulWidget {
  final PlayerController controller;

  const PlaybackSpeedSheet({super.key, required this.controller});

  @override
  State<PlaybackSpeedSheet> createState() => _PlaybackSpeedSheetState();
}

class _PlaybackSpeedSheetState extends State<PlaybackSpeedSheet> {
  static const List<double> _defaultSpeeds = [
    0.25,
    0.5,
    0.75,
    1.0,
    1.25,
    1.5,
    1.75,
    2.0
  ];

  late List<double> _speedChips;
  late double _currentSpeed;

  @override
  void initState() {
    super.initState();
    _currentSpeed = widget.controller.playbackSpeed.value;

    _speedChips = List<double>.from(_defaultSpeeds);

    _currentSpeed = _currentSpeed.clamp(_speedChips.first, _speedChips.last);
  }

  double get _min => _speedChips.first;
  double get _max => _speedChips.last;

  void _setSpeed(double v) {
    setState(() => _currentSpeed = v);
    widget.controller.setRate(v);
  }

  void _removeChip(double speed) {
    if (_speedChips.length <= 1) return;
    setState(() {
      _speedChips.remove(speed);

      _currentSpeed = _currentSpeed.clamp(_min, _max);
    });
    widget.controller.setRate(_currentSpeed);
  }

  void _addChip() async {
    double? newSpeed = await _showAddSpeedDialog();
    if (newSpeed == null) return;
    if (_speedChips.contains(newSpeed)) return;
    setState(() {
      _speedChips.add(newSpeed);
      _speedChips.sort();
    });
  }

  Future<double?> _showAddSpeedDialog() async {
    double value = 2.5;
    return showDialog<double>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSt) {
          return AlertDialog(
            title: const Text('Add Speed'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${value.toStringAsFixed(2)}x',
                    style: ctx.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Slider(
                  min: 0.05,
                  max: 20.0,
                  divisions: 399,
                  year2023: false,
                  value: value,
                  onChanged: (v) => setSt(() => value = v),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx, value),
                  child: const Text('Add')),
            ],
          );
        });
      },
    );
  }

  void _restoreChips() {
    setState(() {
      _speedChips = List<double>.from(_defaultSpeeds);
      _currentSpeed = _currentSpeed.clamp(_min, _max);
    });
    widget.controller.setRate(_currentSpeed);
  }

  void _restoreSpeed() {
    _setSpeed(1.0);
  }

  String _fmt(double v) {
    if (v == 1.0) return '1×';

    final s = v.toStringAsFixed(2);
    return '${s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')}×';
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;
    final sliderVal = _currentSpeed.clamp(_min, _max);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current Speed',
                      style: tt.labelSmall?.copyWith(
                          color: cs.onSurface.opaque(0.5, iReallyMeanIt: true),
                          letterSpacing: 0.8)),
                  const SizedBox(height: 2),
                  Text(
                    _fmt(_currentSpeed),
                    style: tt.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                      height: 1,
                    ),
                  ),
                ],
              ),
              _ActionChip(
                label: 'Reset to 1×',
                icon: Icons.replay_rounded,
                onTap: _restoreSpeed,
                color: cs.secondary,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(_fmt(_min),
                  style: tt.labelSmall?.copyWith(
                      color: cs.onSurface.opaque(0.45, iReallyMeanIt: true))),
              Expanded(
                child: Slider(
                  min: _min,
                  max: _max,
                  value: sliderVal,
                  year2023: false,
                  onChanged: (v) {
                    final snapped = (v * 20).round() / 20;
                    _setSpeed(snapped);
                  },
                ),
              ),
              Text(_fmt(_max),
                  style: tt.labelSmall?.copyWith(
                      color: cs.onSurface.opaque(0.45, iReallyMeanIt: true))),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text('Speed Presets',
                    style: tt.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.opaque(0.7, iReallyMeanIt: true))),
              ),
              _ActionChip(
                label: 'Restore',
                icon: Icons.settings_backup_restore_rounded,
                onTap: _restoreChips,
                color: cs.tertiary,
              ),
              const SizedBox(width: 8),
              _ActionChip(
                label: 'Add',
                icon: Icons.add_rounded,
                onTap: _addChip,
                color: cs.primary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _speedChips.map((speed) {
              final isActive = (speed - _currentSpeed).abs() < 0.001;
              final isLast = _speedChips.length == 1;
              return _SpeedChip(
                label: _fmt(speed),
                isActive: isActive,
                canDelete: !isLast,
                onTap: () => _setSpeed(speed),
                onDelete: () => _removeChip(speed),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                _setSpeed(widget.controller.settings.speed);
              },
              icon: const Icon(Icons.star_outline_rounded, size: 18),
              label: const Text('Make Default Speed'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                side: BorderSide(
                    color: cs.outline.opaque(0.3, iReallyMeanIt: true)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeedChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool canDelete;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SpeedChip({
    required this.label,
    required this.isActive,
    required this.canDelete,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.only(
            left: 12, right: canDelete ? 4 : 12, top: 6, bottom: 6),
        decoration: BoxDecoration(
          color: isActive
              ? cs.primary
              : cs.surfaceVariant.opaque(0.5, iReallyMeanIt: true),
          borderRadius: BorderRadius.circular(20),
          border: isActive
              ? null
              : Border.all(color: cs.outline.opaque(0.2, iReallyMeanIt: true)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: context.theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isActive ? cs.onPrimary : cs.onSurface,
              ),
            ),
            if (canDelete) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onDelete,
                child: Icon(Icons.close_rounded,
                    size: 14,
                    color: isActive
                        ? cs.onPrimary.opaque(0.7, iReallyMeanIt: true)
                        : cs.onSurface.opaque(0.5, iReallyMeanIt: true)),
              ),
              const SizedBox(width: 4),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.opaque(0.1, iReallyMeanIt: true),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.opaque(0.2, iReallyMeanIt: true)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: context.theme.textTheme.labelSmall
                    ?.copyWith(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
