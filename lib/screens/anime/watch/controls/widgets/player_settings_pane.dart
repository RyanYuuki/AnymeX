import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/episodes_pane.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/watch_settings_pane.dart';
import 'package:anymex/screens/settings/sub_settings/player/settings_player_controls.dart';
import 'package:anymex/screens/settings/sub_settings/player/settings_player_engine.dart';
import 'package:anymex/screens/settings/sub_settings/player/settings_player_shaders.dart';
import 'package:anymex/screens/settings/sub_settings/player/settings_player_subtitles.dart';
import 'package:anymex/widgets/non_widgets/reusable_checkmark.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_expansion_tile.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:anymex/l10n/l10n_extension.dart';

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
      title: context.l10n.defaultOrientation,
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
      title: context.l10n.playbackSpeed,
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
      title: context.l10n.resizeMode,
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
          title: context.l10n.defaultOrientation,
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
          title: context.l10n.playbackSpeed,
          subtitle: context.l10n.x((settings.speed.toStringAsFixed(2)).toString()),
        ),
        AnymeXTile(
          icon: Icons.aspect_ratio_rounded,
          title: context.l10n.resizeMode,
          subtitle: settings.resizeMode.capitalizeFirst ?? settings.resizeMode,
          onTap: _showResizeModeDialog,
        ),
        AnymeXTile.toggle(
          icon: Icons.launch_rounded,
          title: context.l10n.useExternalPlayer,
          subtitle: context.l10n.openVideoStreamsInAnExternal,
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
            title: context.l10n.playerSettings,
            onClose: _closePane,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnymeXExpansionTile(
                    title: context.l10n.quickDefaults,
                    subtitle: context.l10n.orientationSpeedResizeModeExternalPlayer,
                    icon: Icons.tune_rounded,
                    initialExpanded: true,
                    useContentContainer: false,
                    content: _buildQuickDefaults(),
                  ),
                  const SizedBox(height: 12),
                  AnymeXExpansionTile(
                    title: context.l10n.controlsGestures,
                    subtitle:
                        context.l10n.themeIndicatorsGesturesAutoSkip,
                    icon: HugeIcons.strokeRoundedPlaySquare,
                    initialExpanded: false,
                    useContentContainer: false,
                    content: const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: SettingsPlayerControls(isEmbedded: true),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnymeXExpansionTile(
                    title: context.l10n.subtitlesTranslation,
                    subtitle: context.l10n.languagesFontsStylingLibassTranslation,
                    icon: Icons.subtitles_rounded,
                    initialExpanded: false,
                    useContentContainer: false,
                    content: const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: SettingsPlayerSubtitles(isEmbedded: true),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnymeXExpansionTile(
                    title: context.l10n.anime4kShaders,
                    subtitle: context.l10n.upscalingShadersPresetsProfiles,
                    icon: Icons.auto_awesome_rounded,
                    initialExpanded: false,
                    useContentContainer: false,
                    content: const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: SettingsPlayerShaders(isEmbedded: true),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnymeXExpansionTile(
                    title: context.l10n.engineAdvanced,
                    subtitle:
                        context.l10n.hardwareDecoderVideoRendererAudio,
                    icon: Icons.memory_rounded,
                    initialExpanded: false,
                    useContentContainer: false,
                    content: const Padding(
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
