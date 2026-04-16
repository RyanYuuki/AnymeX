import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/episodes_pane.dart';
import 'package:anymex/screens/anime/watch/player/base_player.dart';
import 'package:anymex/utils/language.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_symbols_icons/symbols.dart';

enum _TracksTab { video, audio, subtitles }

class TracksPopup extends StatelessWidget {
  final PlayerController controller;

  const TracksPopup({super.key, required this.controller});

  void _closePane() {
    controller.isTracksPaneOpened.value = false;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => EpisodeSidePane(
          isVisible: controller.isTracksPaneOpened.value,
          onOverlayTap: _closePane,
          child: _TracksPopupContent(
            controller: controller,
            onClose: _closePane,
          ),
        ));
  }
}

class _TracksPopupContent extends StatefulWidget {
  final PlayerController controller;
  final VoidCallback onClose;

  const _TracksPopupContent({
    required this.controller,
    required this.onClose,
  });

  @override
  State<_TracksPopupContent> createState() => _TracksPopupContentState();
}

class _TracksPopupContentState extends State<_TracksPopupContent> {
  _TracksTab _currentTab = _TracksTab.subtitles;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final cs = theme.colorScheme;

    return Column(
      children: [
        _buildHeader(cs, theme),
        _buildTabBar(cs, theme),
        Expanded(
          child: _buildContent(cs, theme),
        ),
      ],
    );
  }

  Widget _buildContent(ColorScheme cs, ThemeData theme) {
    switch (_currentTab) {
      case _TracksTab.video:
        return _buildVideoTracks(cs, theme);
      case _TracksTab.audio:
        return _buildAudioTracks(cs, theme);
      case _TracksTab.subtitles:
        return _buildSubtitleTracks(cs, theme);
    }
  }

  Widget _buildHeader(ColorScheme cs, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16 + 40, 16, 16),

      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(color: cs.outline.withOpacity(0.15)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Symbols.tune_rounded, color: cs.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tracks',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: widget.onClose,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.close, size: 20, color: cs.onSurface.withOpacity(0.7)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ColorScheme cs, ThemeData theme) {
    return Obx(() {
      final hasQuality = widget.controller.embeddedQuality.value
              .where((e) => e.height != null && e.width != null)
              .length >
          1;
      final hasAudio = widget.controller.embeddedAudioTracks.value
              .where((e) => e.title != null && e.language != null)
              .length >
          1;

      final tabs = <_TracksTab>[];
      tabs.add(_TracksTab.subtitles);
      if (hasQuality) tabs.add(_TracksTab.video);
      if (hasAudio) tabs.add(_TracksTab.audio);

      if (!tabs.contains(_currentTab)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _currentTab = tabs.first);
        });
      }

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outline.withOpacity(0.1)),
        ),
        child: Row(
          children: tabs.map((tab) {
            final isSelected = _currentTab == tab;
            final label = switch (tab) {
              _TracksTab.video => 'Quality',
              _TracksTab.audio => 'Audio',
              _TracksTab.subtitles => 'Subtitles',
            };
            final icon = switch (tab) {
              _TracksTab.video => Symbols.high_quality_rounded,
              _TracksTab.audio => Symbols.music_note_rounded,
              _TracksTab.subtitles => Symbols.subtitles_rounded,
            };

            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _currentTab = tab),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? cs.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: cs.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 16,
                        color: isSelected ? cs.onPrimary : cs.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected ? cs.onPrimary : cs.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    });
  }

  Widget _buildVideoTracks(ColorScheme cs, ThemeData theme) {
    return Obx(() {
      final qualities = widget.controller.embeddedQuality.value
          .where((e) => e.height != null && e.width != null)
          .toList();
      final selected = widget.controller.selectedQualityTrack.value;

      if (qualities.isEmpty) {
        return _buildEmpty(cs, theme, Symbols.high_quality_rounded, 'No quality tracks');
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: qualities.length,
        itemBuilder: (context, index) {
          final q = qualities[index];
          final isSelected = selected != null && qualities.indexOf(selected) == index;
          return _buildListItem(
            cs: cs,
            theme: theme,
            title: q.height == 0 ? 'Auto' : '${q.width}x${q.height}',
            subtitle: 'Quality',
            icon: Symbols.high_quality_rounded,
            isSelected: isSelected,
            onTap: () => widget.controller.setVideoTrack(q),
          );
        },
      );
    });
  }

  Widget _buildAudioTracks(ColorScheme cs, ThemeData theme) {
    return Obx(() {
      final tracks = widget.controller.embeddedAudioTracks.value
          .where((e) => e.title != null && e.language != null)
          .toList();
      final selected = widget.controller.selectedAudioTrack.value;

      if (tracks.isEmpty) {
        return _buildEmpty(cs, theme, Symbols.music_note_rounded, 'No audio tracks');
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: tracks.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = selected == null ||
                selected.id == 'auto' ||
                !tracks.contains(selected);
            return _buildListItem(
              cs: cs,
              theme: theme,
              title: 'Auto',
              subtitle: 'Audio Track',
              icon: Symbols.music_note_rounded,
              isSelected: isSelected,
              onTap: () {
                widget.controller.setAudioTrack(AudioTrack.auto());
                widget.controller.selectedAudioTrack.value = AudioTrack.auto();
              },
            );
          }

          final track = tracks[index - 1];
          final isSelected = selected != null && tracks.indexOf(selected) == index - 1;
          return _buildListItem(
            cs: cs,
            theme: theme,
            title: completeLanguageName(track.language ?? '') +
                (track.title != null ? ' - ${track.title}' : ''),
            subtitle: 'Audio Track',
            icon: Symbols.music_note_rounded,
            isSelected: isSelected,
            onTap: () {
              widget.controller.setAudioTrack(track);
              widget.controller.selectedAudioTrack.value = track;
            },
          );
        },
      );
    });
  }

  Widget _buildSubtitleTracks(ColorScheme cs, ThemeData theme) {
    return Obx(() {
      final tracks = widget.controller.embeddedSubs.value;
      final selectedTrack = widget.controller.selectedSubsTrack.value;
      final currentIndex =
          selectedTrack == null ? 0 : tracks.indexOf(selectedTrack) + 1;

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: tracks.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildListItem(
              cs: cs,
              theme: theme,
              title: 'None',
              subtitle: 'No subtitles',
              icon: Icons.subtitles_off,
              isSelected: currentIndex == 0,
              onTap: () => widget.controller.setSubtitleTrack(SubtitleTrack.no()),
            );
          }

          final track = tracks[index - 1];
          final isSelected = currentIndex == index;
          return _buildListItem(
            cs: cs,
            theme: theme,
            title: (track.title ?? track.language ?? track.url ?? track.id)
                .toUpperCase(),
            subtitle: 'Embedded Subtitle',
            icon: Icons.closed_caption_rounded,
            isSelected: isSelected,
            onTap: () => widget.controller.setSubtitleTrack(track),
          );
        },
      );
    });
  }

  Widget _buildListItem({
    required ColorScheme cs,
    required ThemeData theme,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: isSelected ? cs.primary.withOpacity(0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? cs.primary.withOpacity(0.3) : Colors.transparent,
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
                        ? cs.primary.withOpacity(0.15)
                        : cs.surfaceContainerHighest.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isSelected ? cs.primary : cs.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? cs.primary : cs.onSurface,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.check, size: 16, color: cs.primary),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(ColorScheme cs, ThemeData theme, IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: cs.onSurface.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: cs.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}
