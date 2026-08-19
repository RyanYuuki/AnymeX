import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/episodes_pane.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/watch_settings_pane.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tabbar.dart';
import 'package:anymex/screens/anime/watch/player/base_player.dart';

import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum _QualityTab { servers, inbuilt }

class SourcePopup extends StatelessWidget {
  final PlayerController controller;

  const SourcePopup({super.key, required this.controller});

  void _closePane() {
    controller.isSourcePaneOpened.value = false;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => EpisodeSidePane(
          isVisible: controller.isSourcePaneOpened.value,
          onOverlayTap: _closePane,
          child: _SourcePopupContent(
            controller: controller,
            onClose: _closePane,
          ),
        ));
  }
}

class _SourcePopupContent extends StatefulWidget {
  final PlayerController controller;
  final VoidCallback onClose;

  const _SourcePopupContent({
    required this.controller,
    required this.onClose,
  });

  @override
  State<_SourcePopupContent> createState() => _SourcePopupContentState();
}

class _SourcePopupContentState extends State<_SourcePopupContent> {
  _QualityTab _currentTab = _QualityTab.servers;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final cs = theme.colorScheme;

    return Obx(() {
      final qualities = widget.controller.embeddedQuality.value
          .where((e) => e.height != null && e.width != null)
          .toList();
      final hasInbuilt = qualities.isNotEmpty;

      if (_currentTab == _QualityTab.inbuilt && !hasInbuilt) {
        _currentTab = _QualityTab.servers;
      }

      return WatchSettingsPane(
        title: 'Quality Settings',
        onClose: widget.onClose,
        tabBar: _buildTabBar(cs, theme, hasInbuilt: hasInbuilt),
        child: switch (_currentTab) {
          _QualityTab.servers => _buildServersList(cs, theme),
          _QualityTab.inbuilt => _buildInbuiltList(cs, theme),
        },
      );
    });
  }

  Widget _buildTabBar(ColorScheme cs, ThemeData theme,
      {required bool hasInbuilt}) {
    final tabs = ['Servers', if (hasInbuilt) 'Inbuilt'];
    final icons = [Icons.dns_rounded, if (hasInbuilt) Icons.high_quality_rounded];
    final activeIndex = switch (_currentTab) {
      _QualityTab.servers => 0,
      _QualityTab.inbuilt => 1,
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
              0 => _QualityTab.servers,
              _ => _QualityTab.inbuilt,
            };
          });
        },
      ),
    );
  }

  Widget _buildServersList(ColorScheme cs, ThemeData theme) {
    return Obx(() {
      final servers = widget.controller.episodeTracks;
      final selectedServer = widget.controller.selectedVideo.value;

      if (servers.isEmpty) {
        return _buildEmpty(
            cs, theme, Icons.dns_rounded, 'No servers available');
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SingleChildScrollView(
          child: AnymeXTileBuilder(
            items: servers,
            selectedItem: selectedServer,
            getTitle: (server) => server.quality ?? 'Auto',
            getSubtitle: (server) => 'Server',
            getIcon: (server) => Icons.dns_rounded,
            onItemPressed: (server) {
              widget.controller.setServerTrack(server);
            },
          ),
        ),
      );
    });
  }

  Widget _buildInbuiltList(ColorScheme cs, ThemeData theme) {
    return Obx(() {
      final qualities = widget.controller.embeddedQuality.value
          .where((e) => e.height != null && e.width != null)
          .toList();
      final selected = widget.controller.selectedQualityTrack.value;

      if (qualities.isEmpty) {
        return _buildEmpty(
            cs, theme, Icons.high_quality_rounded, 'No quality tracks');
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SingleChildScrollView(
          child: AnymeXTileBuilder<VideoTrack>(
            items: qualities,
            selectedItem: selected,
            getTitle: (track) => '${track.height}p',
            getSubtitle: (track) => 'Embedded Quality',
            getIcon: (track) => Icons.high_quality_rounded,
            onItemPressed: (track) {
              widget.controller.setVideoTrack(track);
              widget.controller.selectedQualityTrack.value = track;
            },
          ),
        ),
      );
    });
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
