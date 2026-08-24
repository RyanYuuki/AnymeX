import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/episodes_pane.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/watch_settings_pane.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';

class SyncSubsPopup extends StatelessWidget {
  final PlayerController controller;

  const SyncSubsPopup({super.key, required this.controller});

  void _closePane() {
    controller.isSyncSubsPaneOpened.value = false;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => EpisodeSidePane(
          isVisible: controller.isSyncSubsPaneOpened.value,
          onOverlayTap: _closePane,
          child: controller.isSyncSubsPaneOpened.value
              ? _SyncSubsContent(
                  controller: controller,
                  onClose: _closePane,
                )
              : const SizedBox.shrink(),
        ));
  }
}

class _SyncSubsContent extends StatefulWidget {
  final PlayerController controller;
  final VoidCallback onClose;

  const _SyncSubsContent({
    required this.controller,
    required this.onClose,
  });

  @override
  State<_SyncSubsContent> createState() => _SyncSubsContentState();
}

class _SyncSubsContentState extends State<_SyncSubsContent> {
  final ItemScrollController _scrollController = ItemScrollController();
  int _lastHighlightedIndex = -1;
  bool _userScrolling = false;

  void _adjustDelay(int ms) {
    final current = widget.controller.subtitleDelay.value.inMilliseconds;
    widget.controller.setSubtitleDelay(Duration(milliseconds: current + ms));
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) return '$h:$m:$s';
    return '$m:$s';
  }

  void _scrollToActive(int index) {
    if (!_userScrolling && _scrollController.isAttached) {
      _scrollController.jumpTo(
        index: index,
        alignment: 0.3,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final cs = theme.colorScheme;

    return WatchSettingsPane(
      title: 'Sync Subtitles',
      onClose: widget.onClose,
      child: Column(
        children: [
          _buildDelayControls(cs, theme),
          Expanded(child: _buildCueViewer(cs, theme)),
        ],
      ),
    );
  }

  Widget _buildDelayControls(ColorScheme cs, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: cs.outline.withOpacity(0.1)),
        ),
      ),
      child: Column(
        children: [
          Obx(() {
            final delay = widget.controller.subtitleDelay.value;
            final seconds = delay.inMilliseconds / 1000.0;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnymeXText(
                  '${seconds.toStringAsFixed(1)}s',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: seconds == 0
                        ? cs.primary.withOpacity(0.1)
                        : cs.tertiary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: AnymeXText(
                    seconds == 0
                        ? 'In sync'
                        : (seconds > 0 ? 'Delayed' : 'Earlier'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: seconds == 0 ? cs.primary : cs.tertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDelayChip(cs, theme, '-0.5s', () => _adjustDelay(-500)),
              const SizedBox(width: 8),
              _buildDelayChip(cs, theme, '-0.1s', () => _adjustDelay(-100)),
              const SizedBox(width: 8),
              _buildResetChip(cs, theme),
              const SizedBox(width: 8),
              _buildDelayChip(cs, theme, '+0.1s', () => _adjustDelay(100)),
              const SizedBox(width: 8),
              _buildDelayChip(cs, theme, '+0.5s', () => _adjustDelay(500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDelayChip(
      ColorScheme cs, ThemeData theme, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withOpacity(0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.outline.withOpacity(0.15)),
        ),
        child: AnymeXText(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildResetChip(ColorScheme cs, ThemeData theme) {
    return GestureDetector(
      onTap: () => widget.controller.setSubtitleDelay(Duration.zero),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: cs.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.primary.withOpacity(0.2)),
        ),
        child: Icon(Icons.sync_rounded, size: 18, color: cs.primary),
      ),
    );
  }

  Widget _buildCueViewer(ColorScheme cs, ThemeData theme) {
    return Obx(() {
      final cues = widget.controller.parsedSubtitleCues;

      if (cues.isEmpty) {
        return _buildEmptyCues(cs, theme);
      }

      final currentPos = widget.controller.currentPosition.value;
      final delay = widget.controller.subtitleDelay.value;
      final adjustedPos = currentPos - delay;

      int activeIndex = -1;
      for (int i = 0; i < cues.length; i++) {
        if (adjustedPos >= cues[i].start && adjustedPos <= cues[i].end) {
          activeIndex = i;
          break;
        }
      }

      if (activeIndex == -1) {
        for (int i = 0; i < cues.length; i++) {
          if (adjustedPos < cues[i].start) {
            activeIndex = i > 0 ? i - 1 : 0;
            break;
          }
        }
        if (activeIndex == -1 && cues.isNotEmpty) {
          activeIndex = cues.length - 1;
        }
      }

      if (activeIndex != _lastHighlightedIndex && activeIndex >= 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToActive(activeIndex);
          _lastHighlightedIndex = activeIndex;
        });
      }

      return NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollStartNotification) {
            _userScrolling = true;
          } else if (notification is ScrollEndNotification) {
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) _userScrolling = false;
            });
          }
          return false;
        },
        child: ScrollablePositionedList.builder(
          itemScrollController: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: cues.length,
          itemBuilder: (context, index) {
            final cue = cues[index];
            final isActive = index == activeIndex;
            final isPast = adjustedPos > cue.end;

            double progress = 0.0;
            if (isActive) {
              final cueDuration =
                  cue.end.inMilliseconds - cue.start.inMilliseconds;
              if (cueDuration > 0) {
                progress =
                    ((adjustedPos.inMilliseconds - cue.start.inMilliseconds) /
                            cueDuration)
                        .clamp(0.0, 1.0);
              }
            }

            return GestureDetector(
              onTap: () {
                final currentPos = widget.controller.currentPosition.value;
                final newDelay =
                    currentPos - cue.start - const Duration(milliseconds: 150);
                widget.controller.setSubtitleDelay(newDelay);
                _userScrolling = false;
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isActive
                      ? cs.primary.withOpacity(0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive
                        ? cs.primary.withOpacity(0.3)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isActive
                                ? cs.primary.withOpacity(0.15)
                                : cs.surfaceContainerHighest.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: AnymeXText(
                            _formatDuration(cue.start),
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontFamily: 'monospace',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? cs.primary
                                  : cs.onSurface
                                      .withOpacity(isPast ? 0.35 : 0.5),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AnymeXText(
                            cue.text,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isActive
                                  ? cs.primary
                                  : cs.onSurface
                                      .withOpacity(isPast ? 0.4 : 0.85),
                              fontWeight:
                                  isActive ? FontWeight.w600 : FontWeight.w400,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (isActive) ...[
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () {},
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 6,
                            thumbShape: SliderComponentShape.noThumb,
                            overlayShape: SliderComponentShape.noOverlay,
                            activeTrackColor: cs.primary,
                            inactiveTrackColor: cs.primary.withOpacity(0.2),
                            trackShape: const RoundedRectSliderTrackShape(),
                          ),
                          child: Slider(
                            value: progress,
                            min: 0.0,
                            max: 1.0,
                            onChanged: (val) {
                              final currentPos =
                                  widget.controller.currentPosition.value;
                              final cueDuration = cue.end.inMilliseconds -
                                  cue.start.inMilliseconds;
                              // Clamp away from edges so adjustedPos stays inside the cue
                              // and doesn't trigger a jump to the previous/next cue.
                              final safeVal = val.clamp(0.02, 0.98);
                              final newDelay = currentPos -
                                  cue.start -
                                  Duration(
                                      milliseconds:
                                          (cueDuration * safeVal).toInt());
                              widget.controller.setSubtitleDelay(newDelay);
                            },
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildEmptyCues(ColorScheme cs, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.subtitles_off_rounded,
              size: 48, color: cs.onSurface.withOpacity(0.3)),
          const SizedBox(height: 16),
          AnymeXText(
            'No subtitle cues loaded',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: cs.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: AnymeXText(
              'Cues are only available for external subtitles. Use the delay controls above to sync embedded tracks.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withOpacity(0.35),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
