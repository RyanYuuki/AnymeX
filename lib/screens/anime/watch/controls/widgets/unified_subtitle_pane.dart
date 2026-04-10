import 'package:anymex/database/isar_models/track.dart' as model;
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/screens/anime/watch/player/base_player.dart';
import 'package:anymex/screens/anime/watch/player/better_player.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/custom_widgets/anymex_segmented_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_symbols_icons/symbols.dart';

enum SubtitlePaneView {
  selection,
  delay,
}

class SubtitleSidePane extends StatefulWidget {
  final Widget child;
  final Duration animationDuration;
  final Curve animationCurve;
  final Color? backgroundColor;
  final Color? shadowColor;
  final bool isVisible;
  final VoidCallback? onOverlayTap;

  const SubtitleSidePane({
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
  State<SubtitleSidePane> createState() => _SubtitleSidePaneState();
}

class _SubtitleSidePaneState extends State<SubtitleSidePane>
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
  void didUpdateWidget(SubtitleSidePane oldWidget) {
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
                      width: context.width * 0.4 > 350 ? 350 : context.width * 0.7,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: widget.backgroundColor ??
                            context.theme.colorScheme.surface.withOpacity(0.95),
                        boxShadow: [
                          BoxShadow(
                            color: widget.shadowColor ?? Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(-4, 0),
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

class UnifiedSubtitlePane extends StatefulWidget {
  final PlayerController controller;

  const UnifiedSubtitlePane({
    super.key,
    required this.controller,
  });

  @override
  State<UnifiedSubtitlePane> createState() => _UnifiedSubtitlePaneState();
}

class _UnifiedSubtitlePaneState extends State<UnifiedSubtitlePane> {
  SubtitlePaneView _currentView = SubtitlePaneView.selection;
  final RxBool _showAllStreams = false.obs;

  void _closePane() {
    widget.controller.isSubtitleUnifiedPaneOpened.value = false;
    setState(() {
      _currentView = SubtitlePaneView.selection;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => SubtitleSidePane(
          isVisible: widget.controller.isSubtitleUnifiedPaneOpened.value,
          onOverlayTap: _closePane,
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: _buildContent(context),
              ),
            ],
          ),
        ));
  }

  Widget _buildHeader(BuildContext context) {
    final isDelayView = _currentView == SubtitlePaneView.delay;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: context.theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          if (isDelayView)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  _currentView = SubtitlePaneView.selection;
                });
              },
            ),
          Expanded(
            child: Text(
              isDelayView ? 'Subtitle Delay' : 'Subtitles',
              style: context.theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (!isDelayView)
            IconButton(
              icon: const Icon(Symbols.timer_rounded),
              onPressed: () {
                setState(() {
                  _currentView = SubtitlePaneView.delay;
                });
              },
              tooltip: 'Subtitle Delay',
            ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _closePane,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (_currentView) {
      case SubtitlePaneView.selection:
        return _buildSelectionView(context);
      case SubtitlePaneView.delay:
        return _buildDelayView(context);
    }
  }

  Widget _buildSelectionView(BuildContext context) {
    return widget.controller.isOffline.value
        ? _buildEmbeddedList()
        : Column(
            children: [
              const SizedBox(height: 16),
              _buildAllStreamsToggle(),
              const SizedBox(height: 10),
              Expanded(
                child: Obx(() => _buildOnlineSubtitleList()),
              ),
            ],
          );
  }

  Widget _buildAllStreamsToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: context.theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(14),
        ),
        child: SwitchListTile(
          value: _showAllStreams.value,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          title: const Text('Show all streams'),
          onChanged: (val) {
            _showAllStreams.value = val;
            widget.controller.showAllStreamSubtitles.value = val;
          },
        ),
      ),
    );
  }

  Widget _buildOnlineSubtitleList() {
    final allMode = _showAllStreams.value;
    final tracks = allMode
        ? widget.controller.getAllStreamSubtitleOptions()
        : widget.controller.getCurrentStreamSubtitleOptions();
    final selectedFile = widget.controller.selectedExternalSub.value.file;
    final selectedTrackIndex = tracks.indexWhere((t) => t.file == selectedFile);

    final items = [
      _SubtitleItemData(
        title: 'Search Online',
        subtitle: 'Find subtitles online',
        icon: Icons.cloud_download,
      ),
      _SubtitleItemData(
        title: 'None',
        subtitle: 'No subtitles',
        icon: Icons.subtitles_off,
      ),
      ...tracks.map((e) => _SubtitleItemData(
            title: e.label ?? 'No Title',
            subtitle: allMode ? 'All Streams' : 'Current Stream',
            icon: Icons.subtitles,
            value: e,
          )),
    ];

    return ListView.builder(
      itemCount: items.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        final isSearchOnline = index == 0;
        final isNone = index == 1;
        final isSelected = (selectedFile == null || selectedFile.isEmpty)
            ? isNone
            : (selectedTrackIndex + 2) == index;

        return _SubtitleListItem(
          item: item,
          isSelected: isSelected,
          onTap: () {
            if (isSearchOnline) {
              widget.controller.isSubtitlePaneOpened.value = true;
              _closePane();
            } else if (isNone) {
              widget.controller.setExternalSub(null);
            } else {
              widget.controller.setExternalSub(item.value as model.Track);
            }
          },
        );
      },
    );
  }

  Widget _buildEmbeddedList() {
    final tracks = widget.controller.embeddedSubs.value;
    final selectedTrack = widget.controller.selectedSubsTrack.value;
    final currentIndex =
        selectedTrack == null ? 0 : tracks.indexOf(selectedTrack) + 1;

    final items = [
      _SubtitleItemData(
          title: 'None', subtitle: 'No subtitles', icon: Icons.subtitles_off),
      ...tracks.map((entry) => _SubtitleItemData(
            title: (entry.title ?? entry.language ?? entry.url ?? entry.id)
                .toUpperCase(),
            subtitle: 'Embedded Subtitle',
            icon: Icons.closed_caption_rounded,
            value: entry,
          ))
    ];

    return ListView.builder(
      itemCount: items.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = currentIndex == index;

        return _SubtitleListItem(
          item: item,
          isSelected: isSelected,
          onTap: () {
            if (index == 0) {
              widget.controller.setSubtitleTrack(SubtitleTrack.no());
            } else {
              widget.controller.setSubtitleTrack(item.value as SubtitleTrack);
            }
          },
        );
      },
    );
  }

  Widget _buildDelayView(BuildContext context) {
    if (widget.controller.basePlayer is BetterPlayerImpl) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, size: 48, color: context.theme.colorScheme.error),
            const SizedBox(height: 16),
            const Text(
              'Not supported, use Libmpv',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Obx(() {
              final delay = widget.controller.subtitleDelay.value;
              final seconds = delay.inMilliseconds / 1000.0;
              return Column(
                children: [
                  Text(
                    '${seconds.toStringAsFixed(1)}s',
                    style: context.theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    seconds == 0 ? 'In sync' : (seconds > 0 ? 'Delayed' : 'Preceded'),
                    style: context.theme.textTheme.bodyMedium,
                  ),
                ],
              );
            }),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDelayButton(
                  icon: Icons.remove_rounded,
                  onPressed: () => _adjustDelay(-500),
                  onLongPress: () => _adjustDelay(-1000),
                  label: '-0.5s',
                ),
                const SizedBox(width: 40),
                _buildDelayButton(
                  icon: Icons.add_rounded,
                  onPressed: () => _adjustDelay(500),
                  onLongPress: () => _adjustDelay(1000),
                  label: '+0.5s',
                ),
              ],
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDelayButton(
                  icon: Icons.fast_rewind_rounded,
                  onPressed: () => _adjustDelay(-100),
                  label: '-0.1s',
                  small: true,
                ),
                const SizedBox(width: 20),
                _buildDelayButton(
                  icon: Icons.fast_forward_rounded,
                  onPressed: () => _adjustDelay(100),
                  label: '+0.1s',
                  small: true,
                ),
              ],
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => widget.controller.setSubtitleDelay(Duration.zero),
                icon: const Icon(Icons.sync_rounded),
                label: const Text('Reset Sync'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDelayButton({
    required IconData icon,
    required VoidCallback onPressed,
    VoidCallback? onLongPress,
    required String label,
    bool small = false,
  }) {
    final size = small ? 50.0 : 70.0;
    return Column(
      children: [
        Material(
          color: context.theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(size / 2),
          child: InkWell(
            onTap: onPressed,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(size / 2),
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(icon, size: small ? 24 : 32),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: context.theme.textTheme.labelMedium),
      ],
    );
  }

  void _adjustDelay(int ms) {
    final current = widget.controller.subtitleDelay.value.inMilliseconds;
    widget.controller.setSubtitleDelay(Duration(milliseconds: current + ms));
  }
}

class _SubtitleItemData {
  final String title;
  final String? subtitle;
  final IconData icon;
  final dynamic value;

  _SubtitleItemData({
    required this.title,
    this.subtitle,
    required this.icon,
    this.value,
  });
}

class _SubtitleListItem extends StatelessWidget {
  final _SubtitleItemData item;
  final bool isSelected;
  final VoidCallback onTap;

  const _SubtitleListItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: isSelected
            ? context.theme.colorScheme.primary.withOpacity(0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected
                    ? context.theme.colorScheme.primary.withOpacity(0.3)
                    : Colors.transparent,
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? context.theme.colorScheme.primary.withOpacity(0.15)
                        : context.theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    item.icon,
                    size: 20,
                    color: isSelected
                        ? context.theme.colorScheme.primary
                        : context.theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.title,
                        style: context.theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? context.theme.colorScheme.primary
                              : context.theme.colorScheme.onSurface,
                        ),
                      ),
                      if (item.subtitle != null)
                        Text(
                          item.subtitle!,
                          style: context.theme.textTheme.bodySmall?.copyWith(
                            color: context.theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    size: 20,
                    color: context.theme.colorScheme.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
