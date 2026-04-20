
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/episodes_pane.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_symbols_icons/symbols.dart';

enum _SourceTab { servers, subtitles }

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
  _SourceTab _currentTab = _SourceTab.servers;
  final RxBool _showAllStreams = false.obs;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final cs = theme.colorScheme;

    return Column(
      children: [
        _buildHeader(cs, theme),
        _buildTabBar(cs, theme),
        Expanded(
          child: _currentTab == _SourceTab.servers
              ? _buildServersList(cs, theme)
              : _buildSubtitlesList(cs, theme),
        ),
      ],
    );
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
            child: Icon(Symbols.cloud_rounded, color: cs.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Source',
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          _buildTab(
            label: 'Servers',
            icon: Symbols.dns_rounded,
            isSelected: _currentTab == _SourceTab.servers,
            onTap: () => setState(() => _currentTab = _SourceTab.servers),
            cs: cs,
            theme: theme,
          ),
          const SizedBox(width: 4),
          _buildTab(
            label: 'Subtitles',
            icon: Symbols.subtitles_rounded,
            isSelected: _currentTab == _SourceTab.subtitles,
            onTap: () => setState(() => _currentTab = _SourceTab.subtitles),
            cs: cs,
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme cs,
    required ThemeData theme,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
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
                size: 18,
                color: isSelected ? cs.onPrimary : cs.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? cs.onPrimary : cs.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServersList(ColorScheme cs, ThemeData theme) {
    return Obx(() {
      final servers = widget.controller.episodeTracks;
      final selectedServer = widget.controller.selectedVideo.value;

      if (servers.isEmpty) {
        return _buildEmpty(cs, theme, Symbols.dns_rounded, 'No servers available');
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: servers.length,
        itemBuilder: (context, index) {
          final server = servers[index];
          final isSelected = selectedServer != null && servers.indexOf(selectedServer) == index;

          return _buildListItem(
            cs: cs,
            theme: theme,
            title: server.quality ?? 'Auto',
            subtitle: 'Server',
            icon: Symbols.dns_rounded,
            isSelected: isSelected,
            onTap: () {
              widget.controller.setServerTrack(server);
            },
          );
        },
      );
    });
  }

  Widget _buildSubtitlesList(ColorScheme cs, ThemeData theme) {
    return Column(
      children: [
        _buildAllStreamsToggle(cs),
        Expanded(
          child: Obx(() {
            final allMode = _showAllStreams.value;
            final tracks = allMode
                ? widget.controller.getAllStreamSubtitleOptions()
                : widget.controller.getCurrentStreamSubtitleOptions();
            final selectedFile = widget.controller.selectedExternalSub.value.file;
            final selectedTrackIndex = tracks.indexWhere((t) => t.file == selectedFile);

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: tracks.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  final isNoneSelected = selectedFile == null || selectedFile.isEmpty;
                  return _buildListItem(
                    cs: cs,
                    theme: theme,
                    title: 'None',
                    subtitle: 'No subtitles',
                    icon: Icons.subtitles_off,
                    isSelected: isNoneSelected,
                    onTap: () => widget.controller.setExternalSub(null),
                  );
                }

                final track = tracks[index - 1];
                final isSelected = selectedTrackIndex == index - 1;

                return _buildListItem(
                  cs: cs,
                  theme: theme,
                  title: track.label ?? 'No Title',
                  subtitle: allMode ? 'All Streams' : 'Current Stream',
                  icon: Icons.subtitles,
                  isSelected: isSelected,
                  onTap: () => widget.controller.setExternalSub(track),
                );
              },
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
