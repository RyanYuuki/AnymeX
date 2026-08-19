import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/episodes_pane.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/watch_settings_pane.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tabbar.dart';
import 'package:anymex/screens/anime/watch/player/base_player.dart';
import 'package:anymex/utils/language.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum _SubtitleTab { source, embedded, online }

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
  _SubtitleTab _currentTab = _SubtitleTab.source;
  final RxBool _showAllStreams = false.obs;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final cs = theme.colorScheme;

    return WatchSettingsPane(
      title: 'Subtitle Settings',
      onClose: widget.onClose,
      tabBar: _buildTabBar(cs, theme),
      child: switch (_currentTab) {
        _SubtitleTab.source => _buildSourceSubtitles(cs, theme),
        _SubtitleTab.embedded => _buildEmbeddedSubtitles(cs, theme),
        _SubtitleTab.online => _buildOnlineSubtitles(cs, theme),
      },
    );
  }

  Widget _buildTabBar(ColorScheme cs, ThemeData theme) {
    final tabs = ['Source', 'Embedded', 'Online'];
    final icons = [
      Icons.cloud_rounded,
      Icons.closed_caption_rounded,
      Icons.language_rounded,
    ];

    final activeIndex = switch (_currentTab) {
      _SubtitleTab.source => 0,
      _SubtitleTab.embedded => 1,
      _SubtitleTab.online => 2,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: AnymeXTabBar(
        selectTabs: tabs,
        selectedIndex: activeIndex,
        icons: icons,
        onTabSelected: (index) {
          setState(() {
            _currentTab = switch (index) {
              0 => _SubtitleTab.source,
              1 => _SubtitleTab.embedded,
              _ => _SubtitleTab.online,
            };
          });
        },
      ),
    );
  }

  Widget _buildSourceSubtitles(ColorScheme cs, ThemeData theme) {
    return Column(
      children: [
        _buildAllStreamsToggle(cs),
        Expanded(
          child: Obx(() {
            final allMode = _showAllStreams.value;
            final tracks = allMode
                ? widget.controller.getAllStreamSubtitleOptions()
                : widget.controller.getCurrentStreamSubtitleOptions();
            final selectedFile =
                widget.controller.selectedExternalSub.value.file;

            final items = [null, ...tracks];
            final selectedItem = (selectedFile == null || selectedFile.isEmpty)
                ? null
                : tracks.firstWhereOrNull((t) => t.file == selectedFile);

            if (tracks.isEmpty) {
              return _buildEmpty(
                  cs, theme, Icons.subtitles_rounded, 'No external subtitles');
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                child: AnymeXTileBuilder(
                  items: items,
                  selectedItem: selectedItem,
                  getTitle: (track) => track == null ? 'None' : (track.label ?? 'No Title'),
                  getSubtitle: (track) => track == null ? 'No subtitles' : (allMode ? 'All Streams' : 'Current Stream'),
                  getIcon: (track) => track == null ? Icons.subtitles_off : Icons.subtitles,
                  onItemPressed: (track) => widget.controller.setExternalSub(track),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildAllStreamsToggle(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Obx(() => Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withOpacity(0.3),
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
          )),
    );
  }

  Widget _buildEmbeddedSubtitles(ColorScheme cs, ThemeData theme) {
    return Obx(() {
      final tracks = widget.controller.embeddedSubs.value;
      final selectedTrack = widget.controller.selectedSubsTrack.value;

      final subtitleTrackItems = [SubtitleTrack.no(), ...tracks];
      final selectedItem = selectedTrack ?? subtitleTrackItems.first;

      if (tracks.isEmpty) {
        return _buildEmpty(
            cs, theme, Icons.closed_caption_rounded, 'No embedded subtitles');
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SingleChildScrollView(
          child: AnymeXTileBuilder<SubtitleTrack>(
            items: subtitleTrackItems,
            selectedItem: selectedItem,
            getTitle: (t) => t.id == 'no' ? 'None' : (completeSubtitleLanguageName(t.language ?? '')).toUpperCase(),
            getSubtitle: (t) => t.id == 'no' ? 'No subtitles' : 'Embedded Subtitle',
            getIcon: (t) => t.id == 'no' ? Icons.subtitles_off : Icons.closed_caption_rounded,
            onItemPressed: (t) => widget.controller.setSubtitleTrack(t),
          ),
        ),
      );
    });
  }

  Widget _buildOnlineSubtitles(ColorScheme cs, ThemeData theme) {
    return _buildEmpty(
        cs, theme, Icons.language_rounded, 'Online subtitle search coming soon');
  }

  Widget _buildEmpty(
      ColorScheme cs, ThemeData theme, IconData icon, String message) {
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
