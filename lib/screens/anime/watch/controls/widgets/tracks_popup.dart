import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/database/isar_models/track.dart' as model;
import 'package:anymex/screens/anime/watch/controls/widgets/episodes_pane.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/watch_settings_pane.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tabbar.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/screens/anime/watch/player/base_player.dart';
import 'package:anymex/utils/language.dart';
import 'package:anymex/utils/theme_extensions.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';

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
    return Obx(() {
      final allMode = _showAllStreams.value;
      final tracks = allMode
          ? widget.controller.getAllStreamSubtitleOptions()
          : widget.controller.getCurrentStreamSubtitleOptions();
      final selectedFile = widget.controller.selectedExternalSub.value.file;
      final localSubs = widget.controller.localSubtitles;

      final List<model.Track?> items = [null];
      for (final local in localSubs) {
        if (!tracks.any((t) => t.file == local.file)) {
          items.add(local);
        }
      }
      items.addAll(tracks);

      final totalCount = 2 + items.length;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          margin: EdgeInsets.zero,
          decoration: BoxDecoration(
            color: context.colors.surfaceContainer
                .opaque(0.45, iReallyMeanIt: true),
            borderRadius: BorderRadius.circular(18.0),
            border: Border.all(
              color: context.colors.onSurface.opaque(0.08, iReallyMeanIt: true),
              width: 0.8,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18.0),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: totalCount,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                thickness: 0.6,
                indent: index == 0 ? 16 : 66.0,
                endIndent: 16,
                color:
                    context.colors.onSurface.opaque(0.08, iReallyMeanIt: true),
              ),
              itemBuilder: (context, index) {
                BorderRadius radius;
                if (totalCount == 1) {
                  radius = BorderRadius.circular(18.0);
                } else if (index == 0) {
                  radius =
                      const BorderRadius.vertical(top: Radius.circular(18.0));
                } else if (index == totalCount - 1) {
                  radius = const BorderRadius.vertical(
                      bottom: Radius.circular(18.0));
                } else {
                  radius = BorderRadius.zero;
                }

                if (index == 0) {
                  return AnymeXTile.toggle(
                    value: allMode,
                    icon: Icons.layers_rounded,
                    title: 'Show all streams',
                    onChanged: (val) {
                      _showAllStreams.value = val;
                      widget.controller.showAllStreamSubtitles.value = val;
                    },
                    borderRadius: radius,
                  );
                }

                if (index == 1) {
                  return AnymeXTile(
                    title: 'Import Local Subtitle',
                    subtitle:
                        'Choose a subtitle file from your device (.srt, .vtt, .ass, .ssa)',
                    icon: Icons.file_open_rounded,
                    onTap: () {
                      widget.controller.pickLocalSubtitle();
                      widget.onClose();
                    },
                    borderRadius: radius,
                  );
                }

                final item = items[index - 2];
                final checked = (selectedFile == null || selectedFile.isEmpty)
                    ? item == null
                    : item?.file == selectedFile;

                final isLocal =
                    item != null && !tracks.any((t) => t.file == item.file);

                return AnymeXTile.radio(
                  title: item == null ? 'None' : (item.label ?? 'No Title'),
                  subtitle: item == null
                      ? 'No subtitles'
                      : (isLocal
                          ? 'Local Subtitle File'
                          : (allMode ? 'All Streams' : 'Current Stream')),
                  icon: item == null ? Icons.subtitles_off : Icons.subtitles,
                  selected: checked,
                  onTap: () => widget.controller.setExternalSub(item),
                  borderRadius: radius,
                );
              },
            ),
          ),
        ),
      );
    });
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
        child: AnymeXTileBuilder<SubtitleTrack>(
          items: subtitleTrackItems,
          selectedItem: selectedItem,
          getTitle: (t) => t.id == 'no'
              ? 'None'
              : (completeSubtitleLanguageName(t.language ?? '')).toUpperCase(),
          getSubtitle: (t) =>
              t.id == 'no' ? 'No subtitles' : 'Embedded Subtitle',
          getIcon: (t) =>
              t.id == 'no' ? Icons.subtitles_off : Icons.closed_caption_rounded,
          onItemPressed: (t) => widget.controller.setSubtitleTrack(t),
          lazy: true,
        ),
      );
    });
  }

  Widget _buildOnlineSubtitles(ColorScheme cs, ThemeData theme) {
    return _buildEmpty(cs, theme, Icons.language_rounded,
        'Online subtitle search coming soon');
  }

  Widget _buildEmpty(
      ColorScheme cs, ThemeData theme, IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: cs.onSurface.withOpacity(0.3)),
          const SizedBox(height: 16),
          AnymeXText(
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
