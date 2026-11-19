import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/episodes_pane.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/watch_settings_pane.dart';
import 'package:anymex/screens/settings/sub_settings/player/settings_player_controls.dart';
import 'package:anymex/screens/settings/sub_settings/player/settings_player_engine.dart';
import 'package:anymex/screens/settings/sub_settings/player/settings_player_shaders.dart';
import 'package:anymex/screens/settings/sub_settings/player/settings_player_subtitles.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/non_widgets/reusable_checkmark.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_expansion_tile.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

class PlayerSettingsPane extends StatefulWidget {
  final PlayerController controller;

  const PlayerSettingsPane({
    super.key,
    required this.controller,
  });

  @override
  State<PlayerSettingsPane> createState() => _PlayerSettingsPaneState();
}

class _PlayerSettingsPaneState extends State<PlayerSettingsPane> {
  final settings = Get.find<Settings>();
  late bool _useExternalPlayer;

  @override
  void initState() {
    super.initState();
    _useExternalPlayer = PlayerKeys.useExternalPlayer.get<bool>(false);
  }

  void _closePane() {
    widget.controller.isSettingsPaneOpened.value = false;
  }

  void _showDefaultOrientationDialog() {
    const orientations = {
      'landscape': 'Auto (Landscape)',
      'auto_full': 'Auto (Full)',
      'landscape_left': 'Landscape Left',
      'landscape_right': 'Landscape Right',
      'portrait': 'Portrait',
    };
    showSelectionDialog<String>(
      title: 'Default Orientation',
      items: orientations.keys.toList(),
      selectedItem: settings.defaultOrientation.obs,
      getTitle: (value) => orientations[value] ?? 'Auto (Landscape)',
      onItemSelected: (value) {
        settings.defaultOrientation = value;
        setState(() {});
      },
      leadingIcon: Icons.screen_rotation_rounded,
    );
  }

  void _showPlaybackSpeedDialog() {
    final speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
    showSelectionDialog<double>(
      title: 'Playback Speed',
      items: speeds,
      selectedItem: settings.speed.obs,
      getTitle: (s) => '${s}x',
      onItemSelected: (s) {
        settings.speed = s;
        if (!widget.controller.isClosed) {
          widget.controller.setRate(s);
        }
        setState(() {});
      },
      leadingIcon: Icons.speed_rounded,
    );
  }

  void _showResizeModeDialog() {
    const modes = ['contain', 'cover', 'fill', 'fitWidth', 'fitHeight'];
    showSelectionDialog<String>(
      title: 'Resize Mode',
      items: modes,
      selectedItem: settings.resizeMode.obs,
      getTitle: (m) => m.capitalizeFirst ?? m,
      onItemSelected: (m) {
        settings.resizeMode = m;
        if (!widget.controller.isClosed) {
          widget.controller.applyConfiguredResizeMode();
        }
        setState(() {});
      },
      leadingIcon: Icons.aspect_ratio_rounded,
    );
  }

  Widget _buildQuickDefaults() {
    return Column(
      children: [
        AnymeXTile(
          icon: Icons.screen_rotation_rounded,
          onTap: _showDefaultOrientationDialog,
          title: 'Default Orientation',
          subtitle: const {
                'landscape': 'Auto (Landscape)',
                'auto_full': 'Auto (Full)',
                'landscape_left': 'Landscape Left',
                'landscape_right': 'Landscape Right',
                'portrait': 'Portrait',
              }[settings.defaultOrientation] ??
              'Auto (Landscape)',
        ),
        AnymeXTile(
          icon: Icons.speed_rounded,
          onTap: _showPlaybackSpeedDialog,
          title: 'Playback Speed',
          subtitle: '${settings.speed.toStringAsFixed(2)}x',
        ),
        AnymeXTile(
          icon: Icons.aspect_ratio_rounded,
          title: 'Resize Mode',
          subtitle: settings.resizeMode.capitalizeFirst ?? settings.resizeMode,
          onTap: _showResizeModeDialog,
        ),
        AnymeXTile.toggle(
          icon: Icons.launch_rounded,
          title: 'Use External Player',
          subtitle: 'Open video streams in an external player by default',
          value: _useExternalPlayer,
          onChanged: (val) {
            setState(() {
              _useExternalPlayer = val;
            });
            PlayerKeys.useExternalPlayer.set<bool>(val);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => EpisodeSidePane(
          isVisible: widget.controller.isSettingsPaneOpened.value,
          onOverlayTap: _closePane,
          child: WatchSettingsPane(
            title: 'Player Settings',
            onClose: _closePane,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnymeXExpansionTile(
                    title: 'Quick Defaults',
                    subtitle: 'Orientation, speed, resize mode & external player',
                    icon: Icons.tune_rounded,
                    initialExpanded: true,
                    useContentContainer: false,
                    content: _buildQuickDefaults(),
                  ),
                  const SizedBox(height: 12),
                  const AnymeXExpansionTile(
                    title: 'Controls & Gestures',
                    subtitle:
                        'Theme, indicators, gestures, auto-skip & button layout',
                    icon: HugeIcons.strokeRoundedPlaySquare,
                    initialExpanded: false,
                    useContentContainer: false,
                    content: Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: SettingsPlayerControls(isEmbedded: true),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const AnymeXExpansionTile(
                    title: 'Subtitles & Translation',
                    subtitle: 'Languages, fonts, styling, libass & translation',
                    icon: Icons.subtitles_rounded,
                    initialExpanded: false,
                    useContentContainer: false,
                    content: Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: SettingsPlayerSubtitles(isEmbedded: true),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const AnymeXExpansionTile(
                    title: 'Anime4K & Shaders',
                    subtitle: 'Upscaling shaders, presets & profiles',
                    icon: Icons.auto_awesome_rounded,
                    initialExpanded: false,
                    useContentContainer: false,
                    content: Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: SettingsPlayerShaders(isEmbedded: true),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const AnymeXExpansionTile(
                    title: 'Engine & Advanced',
                    subtitle:
                        'Hardware decoder, video renderer, audio & mpv config',
                    icon: Icons.memory_rounded,
                    initialExpanded: false,
                    useContentContainer: false,
                    content: Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: SettingsPlayerEngine(isEmbedded: true),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}
