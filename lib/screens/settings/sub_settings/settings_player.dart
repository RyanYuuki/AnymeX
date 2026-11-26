import 'package:anymex/l10n/l10n_extension.dart';
import 'dart:io' show Platform;
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/screens/anime/watch/controls/themes/setup/media_indicator_theme_registry.dart';
import 'package:anymex/screens/anime/watch/controls/themes/setup/player_control_theme_registry.dart';
import 'package:anymex/screens/settings/sub_settings/player/settings_player_controls.dart';
import 'package:anymex/screens/settings/sub_settings/player/settings_player_engine.dart';
import 'package:anymex/screens/settings/sub_settings/player/settings_player_shaders.dart';
import 'package:anymex/screens/settings/sub_settings/player/settings_player_subtitles.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/subtitle_translator.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_titlebar.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/non_widgets/reusable_checkmark.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

class SettingsPlayer extends StatefulWidget {
  final bool isModal;
  const SettingsPlayer({super.key, this.isModal = false});

  @override
  State<SettingsPlayer> createState() => _SettingsPlayerState();
}

class _SettingsPlayerState extends State<SettingsPlayer> {
  final settings = Get.find<Settings>();
  bool _shouldApplyResizeModeOnClose = false;
  late bool _useExternalPlayer;

  @override
  void initState() {
    super.initState();
    _useExternalPlayer = PlayerKeys.useExternalPlayer.get<bool>(false);
  }

  @override
  void dispose() {
    final shouldApplyResizeOnClose =
        widget.isModal && _shouldApplyResizeModeOnClose;
    super.dispose();
    if (!shouldApplyResizeOnClose) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!Get.isRegistered<PlayerController>()) return;
      final controller = Get.find<PlayerController>();
      if (controller.isClosed) return;
      controller.applyConfiguredResizeMode();
    });
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
        _shouldApplyResizeModeOnClose = true;
        setState(() {});
      },
      leadingIcon: Icons.aspect_ratio_rounded,
    );
  }

  void _openSubPage(Widget page) {
    if (widget.isModal) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => page),
      );
    } else {
      navigate(() => page);
    }
  }

  Widget _buildModalHeader(BuildContext context) {
    final theme = context.theme;
    final cs = theme.colorScheme;
    final isDesktop = !Platform.isAndroid && !Platform.isIOS;
    final titleBarHeight =
        (Platform.isWindows && !AnymeXTitleBar.isFullScreen.value) ? 40.0 : 0.0;
    final topPadding = MediaQuery.paddingOf(context).top +
        titleBarHeight +
        (isDesktop ? 16.0 : 10.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: EdgeInsets.only(top: topPadding, bottom: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: cs.outline.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: AnymeXText(
                  context.l10n.playerSettings,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontFamily: 'Linotte',
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: cs.onSurface,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                  backgroundColor: cs.surfaceContainerHigh,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(Icons.close_rounded, color: cs.onSurface),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnymeXScaffold(
      showHeader: !widget.isModal,
      headerTitle: context.l10n.playerSettings,
      body: Builder(
        builder: (ctx) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16.0,
            widget.isModal ? 0.0 : AnymeXHeaderScope.of(ctx),
            16.0,
            30.0,
          ),
          child: Obx(() {
            final controlTheme = PlayerControlThemeRegistry.resolve(
              settings.playerControlTheme,
            ).name;
            final indicatorTheme = MediaIndicatorThemeRegistry.resolve(
              settings.mediaIndicatorTheme,
            ).name;
            final subLang = SubtitleTranslator.languages[
                    settings.preferredSubtitleLanguage] ??
                'None';
            final subFont = settings.playerSettings.value.subtitleFont;
            final shadersOn = PlayerUiKeys.shadersEnabled.get<bool>(false);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.isModal) _buildModalHeader(context),
                AnymeXSectionBuilder(
                  title: context.l10n.quickDefaults,
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
                      subtitle: settings.resizeMode.capitalizeFirst ??
                          settings.resizeMode,
                      onTap: _showResizeModeDialog,
                    ),
                    AnymeXTile.toggle(
                      icon: Icons.launch_rounded,
                      title: context.l10n.useExternalPlayer,
                      subtitle:
                          context.l10n.openVideoStreamsInAnExternal,
                      value: _useExternalPlayer,
                      onChanged: (val) {
                        setState(() {
                          _useExternalPlayer = val;
                        });
                        PlayerKeys.useExternalPlayer.set<bool>(val);
                      },
                    ),
                  ],
                ),
                AnymeXSectionBuilder(
                  title: context.l10n.customize,
                  children: [
                    AnymeXTile(
                      icon: HugeIcons.strokeRoundedPlaySquare,
                      title: context.l10n.controlsGestures,
                      subtitle:
                          context.l10n.bottomBarSeek(controlTheme, indicatorTheme),
                      onTap: () =>
                          _openSubPage(const SettingsPlayerControls()),
                    ),
                    AnymeXTile(
                      icon: Icons.subtitles_rounded,
                      title: context.l10n.subtitlesTranslation,
                      subtitle: context.l10n.stylingLibass(subLang.toString(), subFont.toString()),
                      onTap: () =>
                          _openSubPage(const SettingsPlayerSubtitles()),
                    ),
                    AnymeXTile(
                      icon: Icons.auto_awesome_rounded,
                      title: context.l10n.anime4kShaders,
                      subtitle: shadersOn
                          ? 'Enabled (${settings.selectedProfile})'
                          : 'Upscaling shaders & keybindings',
                      onTap: () => _openSubPage(const SettingsPlayerShaders()),
                    ),
                    AnymeXTile(
                      icon: Icons.memory_rounded,
                      title: context.l10n.engineAdvanced,
                      subtitle:
                          context.l10n.decoderRendererMpvConf(settings.hardwareDecoder.toUpperCase()),
                      onTap: () => _openSubPage(const SettingsPlayerEngine()),
                    ),
                  ],
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
