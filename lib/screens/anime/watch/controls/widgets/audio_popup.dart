import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/episodes_pane.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/watch_settings_pane.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tabbar.dart';
import 'package:anymex/screens/anime/watch/player/base_player.dart';
import 'package:anymex/utils/language.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';

enum _AudioTab { source, inbuilt }

class AudioPopup extends StatelessWidget {
  final PlayerController controller;

  const AudioPopup({super.key, required this.controller});

  void _closePane() {
    controller.isAudioPaneOpened.value = false;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => EpisodeSidePane(
          isVisible: controller.isAudioPaneOpened.value,
          onOverlayTap: _closePane,
          child: _AudioPopupContent(
            controller: controller,
            onClose: _closePane,
          ),
        ));
  }
}

class _AudioPopupContent extends StatefulWidget {
  final PlayerController controller;
  final VoidCallback onClose;

  const _AudioPopupContent({
    required this.controller,
    required this.onClose,
  });

  @override
  State<_AudioPopupContent> createState() => _AudioPopupContentState();
}

class _AudioPopupContentState extends State<_AudioPopupContent> {
  _AudioTab _currentTab = _AudioTab.source;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final cs = theme.colorScheme;

    return Obx(() {
      final externalAudios =
          widget.controller.selectedVideo.value?.audios ?? [];

      final seenIds = <String>{};
      final embeddedAudios = widget.controller.embeddedAudioTracks.value
          .where((t) => seenIds.add(t.id))
          .toList();

      final realTracks =
          embeddedAudios.where((t) => t.id != 'no' && t.id != 'auto').toList();

      final hasSource = externalAudios.isNotEmpty;
      final hasInbuilt = realTracks.isNotEmpty;

      if (_currentTab == _AudioTab.source && !hasSource && hasInbuilt) {
        _currentTab = _AudioTab.inbuilt;
      } else if (_currentTab == _AudioTab.inbuilt && !hasInbuilt && hasSource) {
        _currentTab = _AudioTab.source;
      }

      return WatchSettingsPane(
        title: 'Audio Settings',
        onClose: widget.onClose,
        tabBar: _buildTabBar(cs, theme,
            hasSource: hasSource, hasInbuilt: hasInbuilt),
        child: switch (_currentTab) {
          _AudioTab.source => _buildSourceAudio(cs, theme, externalAudios),
          _AudioTab.inbuilt => _buildInbuiltAudio(cs, theme, embeddedAudios),
        },
      );
    });
  }

  Widget _buildTabBar(ColorScheme cs, ThemeData theme,
      {required bool hasSource, required bool hasInbuilt}) {
    final tabs = [if (hasSource) 'Source', if (hasInbuilt) 'Inbuilt'];
    final icons = [
      if (hasSource) Icons.cloud_rounded,
      if (hasInbuilt) Icons.high_quality_rounded
    ];

    if (tabs.isEmpty) return const SizedBox.shrink();

    final activeIndex = switch (_currentTab) {
      _AudioTab.source => tabs.indexOf('Source'),
      _AudioTab.inbuilt => tabs.indexOf('Inbuilt'),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: AnymeXTabBar(
        selectTabs: tabs,
        selectedIndex: activeIndex.clamp(0, tabs.length - 1),
        icons: icons,
        onTabSelected: (index) {
          setState(() {
            final selectedTabName = tabs[index];
            _currentTab = selectedTabName == 'Source'
                ? _AudioTab.source
                : _AudioTab.inbuilt;
          });
        },
      ),
    );
  }

  Widget _buildSourceAudio(
      ColorScheme cs, ThemeData theme, List<dynamic> externalAudios) {
    if (externalAudios.isEmpty) {
      return _buildEmpty(
          cs, theme, Icons.cloud_off_rounded, 'No source audio tracks');
    }

    final selectedFile = widget.controller.selectedExternalAudio.value?.file;
    final items = [null, ...externalAudios];
    final selectedItem = (selectedFile == null || selectedFile.isEmpty)
        ? null
        : externalAudios.firstWhereOrNull((a) => a.file == selectedFile);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        child: AnymeXTileBuilder(
          items: items,
          selectedItem: selectedItem,
          getTitle: (track) =>
              track == null ? 'Default' : (track.label ?? 'Track'),
          getSubtitle: (track) =>
              track == null ? 'Default Source Audio' : 'External Audio Stream',
          getIcon: (track) => Icons.audiotrack_rounded,
          onItemPressed: (track) => widget.controller.setExternalAudio(track),
        ),
      ),
    );
  }

  Widget _buildInbuiltAudio(
      ColorScheme cs, ThemeData theme, List<AudioTrack> embeddedTracks) {
    final seenIds = <String>{};
    final audioTrackItems =
        embeddedTracks.where((t) => seenIds.add(t.id)).toList();

    final realTracks =
        audioTrackItems.where((t) => t.id != 'no' && t.id != 'auto').toList();
    if (realTracks.isEmpty) {
      return _buildEmpty(
          cs, theme, Icons.music_off_rounded, 'No inbuilt audio tracks');
    }

    final selected = widget.controller.selectedAudioTrack.value;
    final selectedLayout = widget.controller.selectedAudioChannelLayout.value;

    final layouts = [
      ('mono', 'Mono', '1 Channel'),
      ('stereo', 'Stereo', '2 Channels'),
      ('5.1', '5.1 Surround', '6 Channels'),
      ('7.1', '7.1 Surround', '8 Channels'),
    ];

    AudioTrack? selectedAudioTrackItem = selected;
    if (selected == null ||
        selected.id == 'auto' ||
        (!audioTrackItems.any((t) => t.id == selected.id) &&
            selected.id != 'no')) {
      selectedAudioTrackItem =
          audioTrackItems.firstWhereOrNull((t) => t.id == 'auto');
    } else if (selected.id == 'no') {
      selectedAudioTrackItem =
          audioTrackItems.firstWhereOrNull((t) => t.id == 'no');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnymeXTileBuilder<AudioTrack>(
              items: audioTrackItems,
              selectedItem: selectedAudioTrackItem,
              getTitle: (t) {
                if (t.id == 'no') return 'None';
                if (t.id == 'auto') return 'Auto';
                if (t.language != null && t.title != null) {
                  return '${completeSubtitleLanguageName(t.language!)} ${(t.title?.isNotEmpty ?? false) ? '- ${t.title}' : ''}';
                } else if (t.language != null) {
                  return completeSubtitleLanguageName(t.language!);
                } else if (t.title != null) {
                  return t.title!;
                }
                return 'Audio Track';
              },
              getSubtitle: (t) {
                if (t.id == 'no') return 'Mute Audio';
                if (t.id == 'auto') return 'Default Audio';
                return 'Audio Track';
              },
              getIcon: (t) => t.id == 'no'
                  ? Icons.music_off_rounded
                  : Icons.music_note_rounded,
              onItemPressed: (t) {
                widget.controller.setAudioTrack(t);
                widget.controller.selectedAudioTrack.value = t;
              },
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 10, left: 4),
              child: AnymeXText(
                'AUDIO CHANNELS / LAYOUT',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: cs.primary,
                ),
              ),
            ),
            AnymeXTileBuilder<(String, String, String)>(
              items: layouts,
              selectedItem:
                  layouts.firstWhereOrNull((l) => l.$1 == selectedLayout),
              getTitle: (l) => l.$2,
              getSubtitle: (l) => l.$3,
              getIcon: (l) => Icons.speaker_group_rounded,
              onItemPressed: (l) {
                widget.controller.setAudioChannelLayout(l.$1);
              },
            ),
          ],
        ),
      ),
    );
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
