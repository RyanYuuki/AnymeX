import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/screens/anime/watch/controls/themes/setup/player_control_theme.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/bottom_sheet.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/control_button.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/progress_slider.dart';
import 'package:anymex/screens/settings/sub_settings/settings_player.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class Ios26PlayerControlTheme extends PlayerControlTheme {
  Ios26PlayerControlTheme();

  @override
  String get id => 'ios26';

  @override
  String get name => 'iOS 26 Glass';

  @override
  Widget buildTopControls(BuildContext context, PlayerController controller) {
    final isDesktop = !_isMobilePlatform;

    return Obx(() {
      if (controller.isLocked.value) {
        if (!controller.showControls.value) return const SizedBox.shrink();
        return Align(
          alignment: Alignment.centerRight,
          child: _IosUnlockButton(
            onUnlock: () => controller.isLocked.value = false,
          ),
        );
      }

      return IgnorePointer(
        ignoring: !controller.showControls.value,
        child: AnimatedSlide(
          offset:
              controller.showControls.value ? Offset.zero : const Offset(0, -1),
          duration: const Duration(milliseconds: 360),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: controller.showControls.value ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 280),
            child: SafeArea(
              bottom: false,
              left: false,
              right: false,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 28 : 14,
                  vertical: isDesktop ? 16 : 8,
                ),
                child: _buildTopSection(context, controller, isDesktop),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildTopSection(
      BuildContext context, PlayerController controller, bool isDesktop) {
    final theme = Theme.of(context);

    return _GlassPanel(
      radius: 24,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 16 : 12,
        vertical: isDesktop ? 12 : 10,
      ),
      child: Row(
        children: [
          _IosGlassIconButton(
            icon: CupertinoIcons.back,
            tooltip: 'Back',
            onPressed: () => Get.back(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  controller.currentEpisode.value.title ??
                      controller.itemName ??
                      'Unknown Title',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _GlassTag(
                      text: controller.currentEpisode.value.number == 'Offline'
                          ? 'Offline'
                          : 'Episode ${controller.currentEpisode.value.number}',
                    ),
                    if (((controller.anilistData.title == '?'
                                ? controller.folderName
                                : controller.anilistData.title) ??
                            '')
                        .isNotEmpty)
                      _GlassTag(
                        text: (controller.anilistData.title == '?'
                                ? controller.folderName
                                : controller.anilistData.title) ??
                            '',
                      ),
                    Obx(() {
                      final qualityText =
                          _qualityLabel(controller.videoHeight.value);
                      if (qualityText.isEmpty) return const SizedBox.shrink();
                      return _GlassTag(text: qualityText);
                    }),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _IosGlassIconButton(
            icon: CupertinoIcons.lock_fill,
            tooltip: 'Lock Controls',
            onPressed: () => controller.isLocked.value = true,
          ),
          const SizedBox(width: 8),
          _IosGlassIconButton(
            icon: CupertinoIcons.fullscreen,
            tooltip: 'Fullscreen',
            onPressed: controller.toggleFullScreen,
          ),
          const SizedBox(width: 8),
          _IosGlassIconButton(
            icon: CupertinoIcons.settings_solid,
            tooltip: 'Settings',
            onPressed: () {
              showModalBottomSheet(
                context: Get.context!,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (sheetContext) => Container(
                  height: MediaQuery.of(sheetContext).size.height,
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: const SettingsPlayer(isModal: true),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget buildCenterControls(BuildContext context, PlayerController controller) {
    final isDesktop = !_isMobilePlatform;

    return Obx(() {
      if (controller.isLocked.value) return const SizedBox.shrink();

      return IgnorePointer(
        ignoring: !controller.showControls.value,
        child: Align(
          alignment: Alignment.center,
          child: AnimatedOpacity(
            opacity: controller.showControls.value ? 1 : 0,
            duration: const Duration(milliseconds: 220),
            child: AnimatedScale(
              scale: controller.showControls.value ? 1 : 0.88,
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutBack,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _IosGlassIconButton(
                    icon: CupertinoIcons.backward_end_fill,
                    tooltip: 'Previous Episode',
                    enabled: controller.canGoBackward.value,
                    onPressed: () => controller.navigator(false),
                  ),
                  const SizedBox(width: 12),
                  _IosGlassIconButton(
                    icon: isDesktop
                        ? CupertinoIcons.gobackward_30
                        : CupertinoIcons.gobackward_15,
                    tooltip: isDesktop ? 'Replay 30s' : 'Replay',
                    onPressed: () {
                      final currentPos = controller.currentPosition.value;
                      final seekBy = Duration(
                          seconds: isDesktop
                              ? 30
                              : controller.playerSettings.seekDuration);
                      final newPos = currentPos - seekBy;
                      controller.seekTo(
                        newPos.isNegative ? Duration.zero : newPos,
                      );
                    },
                  ),
                  const SizedBox(width: 14),
                  Obx(() => _GlassPlayButton(
                        isPlaying: controller.isPlaying.value,
                        isBuffering: controller.isBuffering.value,
                        onTap: controller.togglePlayPause,
                      )),
                  const SizedBox(width: 14),
                  _IosGlassIconButton(
                    icon: isDesktop
                        ? CupertinoIcons.goforward_30
                        : CupertinoIcons.goforward_15,
                    tooltip: isDesktop ? 'Forward 30s' : 'Forward',
                    onPressed: () {
                      final currentPos = controller.currentPosition.value;
                      final duration = controller.episodeDuration.value;
                      final seekBy = Duration(
                          seconds: isDesktop
                              ? 30
                              : controller.playerSettings.seekDuration);
                      final newPos = currentPos + seekBy;
                      controller.seekTo(newPos > duration ? duration : newPos);
                    },
                  ),
                  const SizedBox(width: 12),
                  _IosGlassIconButton(
                    icon: CupertinoIcons.forward_end_fill,
                    tooltip: 'Next Episode',
                    enabled: controller.canGoForward.value,
                    onPressed: () => controller.navigator(true),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  @override
  Widget buildBottomControls(BuildContext context, PlayerController controller) {
    final isDesktop = !_isMobilePlatform;

    return Obx(() {
      if (controller.isLocked.value) {
        if (!controller.showControls.value) return const SizedBox.shrink();
        return SafeArea(
          top: false,
          left: false,
          right: false,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 28 : 14,
              vertical: isDesktop ? 18 : 8,
            ),
            child: const _GlassPanel(
              radius: 26,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: IgnorePointer(
                ignoring: true,
                child: Opacity(
                  opacity: 0.7,
                  child: ProgressSlider(style: SliderStyle.ios),
                ),
              ),
            ),
          ),
        );
      }

      return IgnorePointer(
        ignoring: !controller.showControls.value,
        child: AnimatedSlide(
          offset:
              controller.showControls.value ? Offset.zero : const Offset(0, 1),
          duration: const Duration(milliseconds: 360),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: controller.showControls.value ? 1 : 0,
            duration: const Duration(milliseconds: 240),
            child: SafeArea(
              top: false,
              left: false,
              right: false,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 28 : 14,
                  vertical: isDesktop ? 18 : 8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: _GlassActionChip(
                        icon: CupertinoIcons.forward_fill,
                        label: '+${controller.playerSettings.skipDuration}',
                        onTap: controller.isLocked.value
                            ? null
                            : () => controller
                                .megaSeek(controller.playerSettings.skipDuration),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildBottomSection(context, controller),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildBottomSection(
      BuildContext context, PlayerController controller) {

    final String jsonString =
        PlayerUiKeys.bottomControlsSettings.get<String>('{}');
    final Map<String, dynamic> decodedConfig = json.decode(jsonString);

    final List<String> leftButtonIds =
        List<String>.from(decodedConfig['leftButtonIds'] ?? []);
    final List<String> rightButtonIds =
        List<String>.from(decodedConfig['rightButtonIds'] ?? []);
    final Map<String, dynamic> buttonConfigs =
        Map<String, dynamic>.from(decodedConfig['buttonConfigs'] ?? {});

    bool isVisible(String id) =>
        (buttonConfigs[id]?['visible'] as bool?) ?? true;

    final Map<String, Widget> buttonWidgets = {
      'playlist': ControlButton(
        icon: Symbols.playlist_play_rounded,
        onPressed: () {
          controller.isEpisodePaneOpened.value =
              !controller.isEpisodePaneOpened.value;
        },
        tooltip: 'Playlist',
        compact: true,
      ),
      'shaders': ControlButton(
        icon: Symbols.tune_rounded,
        onPressed: () => controller.openColorProfileBottomSheet(context),
        tooltip: 'Shaders & Color Profiles',
        compact: true,
      ),
      'subtitles': !controller.isOffline.value
          ? ControlButton(
              icon: Symbols.subtitles_rounded,
              onPressed: () =>
                  PlayerBottomSheets.showSubtitleTracks(context, controller),
              tooltip: 'Subtitles',
              compact: true,
            )
          : ControlButton(
              icon: Symbols.subtitles_rounded,
              onPressed: () =>
                  PlayerBottomSheets.showOfflineSubs(context, controller),
              tooltip: 'Subtitles',
              compact: true,
            ),
      'server': ControlButton(
        icon: Symbols.cloud_rounded,
        onPressed: () =>
            PlayerBottomSheets.showVideoServers(context, controller),
        tooltip: 'Server',
        compact: true,
      ),
      'quality': ControlButton(
        icon: Symbols.high_quality_rounded,
        onPressed: () =>
            PlayerBottomSheets.showVideoQuality(context, controller),
        tooltip: 'Quality',
        compact: true,
      ),
      'speed': ControlButton(
        icon: Symbols.speed_rounded,
        onPressed: () =>
            PlayerBottomSheets.showPlaybackSpeed(context, controller),
        tooltip: 'Speed',
        compact: true,
      ),
      'audio_track': ControlButton(
        icon: Symbols.music_note_rounded,
        onPressed: () =>
            PlayerBottomSheets.showAudioTracks(context, controller),
        tooltip: 'Audio Track',
        compact: true,
      ),
      'orientation': ControlButton(
        icon: Icons.screen_rotation_rounded,
        onPressed: () => controller.toggleOrientation(),
        tooltip: 'Toggle Orientation',
        compact: true,
      ),
      'aspect_ratio': ControlButton(
        icon: Symbols.fit_screen,
        onPressed: () => controller.toggleVideoFit(),
        tooltip: 'Aspect Ratio',
        compact: true,
      ),
    };

    List<Widget> buildButtonList(List<String> ids) {
      final regularButtons = <Widget>[];
      final compactButtons = <Widget>[];

      for (final id in ids) {
        if (!isVisible(id)) continue;
        if (id == 'server' && controller.isOffline.value) continue;
        if (id == 'quality' && controller.isOffline.value) continue;
        if (id == 'orientation' && !(Platform.isAndroid || Platform.isIOS)) {
          continue;
        }

        final widget = buttonWidgets[id];
        if (widget == null) continue;

        if (widget is ControlButton && widget.compact) {
          compactButtons.add(widget);
        } else {
          regularButtons.add(widget);
        }
      }

      if (compactButtons.isNotEmpty) {
        regularButtons.add(
          _GlassPanel(
            radius: 18,
            blur: 20,
            tint: Colors.white.withValues(alpha: 0.09),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child:
                Row(mainAxisSize: MainAxisSize.min, children: compactButtons),
          ),
        );
      }

      return regularButtons;
    }

    final leftButtons = buildButtonList(leftButtonIds);
    final rightButtons = buildButtonList(rightButtonIds);

    return _GlassPanel(
      radius: 28,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: ProgressSlider(style: SliderStyle.ios),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _GlassTimeChip(
                child: Obx(
                  () => Text(
                    controller.formattedCurrentPosition,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
              if (leftButtons.isNotEmpty) const SizedBox(width: 10),
              ...leftButtons,
              const Spacer(),
              ...rightButtons,
              if (rightButtons.isNotEmpty) const SizedBox(width: 10),
              _GlassTimeChip(
                child: Obx(
                  () => Text(
                    controller.formattedEpisodeDuration,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;
  final Color tint;

  const _GlassPanel({
    required this.child,
    required this.padding,
    this.radius = 20,
    this.blur = 22,
    this.tint = const Color(0x1FFFFFFF),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.24),
              width: 0.9,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 20,
                spreadRadius: -2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _IosGlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool enabled;
  final String tooltip;

  const _IosGlassIconButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: _GlassPanel(
        radius: 16,
        blur: 18,
        tint: Colors.white.withValues(alpha: 0.08),
        padding: EdgeInsets.zero,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: enabled ? onPressed : null,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(
                icon,
                color: enabled
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.45),
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassTag extends StatelessWidget {
  final String text;
  const _GlassTag({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _GlassActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _GlassActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      radius: 16,
      padding: EdgeInsets.zero,
      tint: Colors.white.withValues(alpha: 0.10),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: onTap == null
                        ? Colors.white.withValues(alpha: 0.45)
                        : Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassTimeChip extends StatelessWidget {
  final Widget child;
  const _GlassTimeChip({required this.child});

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      radius: 14,
      blur: 18,
      tint: Colors.white.withValues(alpha: 0.08),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: child,
    );
  }
}

class _GlassPlayButton extends StatelessWidget {
  final bool isPlaying;
  final bool isBuffering;
  final VoidCallback onTap;

  const _GlassPlayButton({
    required this.isPlaying,
    required this.isBuffering,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      radius: 28,
      blur: 24,
      tint: Colors.white.withValues(alpha: 0.12),
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: SizedBox(
            width: 66,
            height: 66,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 120),
                child: isBuffering
                    ? const SizedBox(
                        width: 26,
                        height: 26,
                        child: ExpressiveLoadingIndicator(),
                      )
                    : Icon(
                        isPlaying
                            ? CupertinoIcons.pause_solid
                            : CupertinoIcons.play_fill,
                        key: ValueKey(isPlaying),
                        color: Colors.white,
                        size: 28,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IosUnlockButton extends StatefulWidget {
  final VoidCallback onUnlock;

  const _IosUnlockButton({required this.onUnlock});

  @override
  State<_IosUnlockButton> createState() => _IosUnlockButtonState();
}

class _IosUnlockButtonState extends State<_IosUnlockButton> {
  bool _confirm = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: _GlassPanel(
        radius: 18,
        blur: 18,
        padding: EdgeInsets.zero,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              if (_confirm) {
                widget.onUnlock();
                return;
              }
              setState(() => _confirm = true);
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) setState(() => _confirm = false);
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    CupertinoIcons.lock_open_fill,
                    color: Colors.white,
                    size: 18,
                  ),
                  if (_confirm) ...[
                    const SizedBox(width: 8),
                    const Text(
                      'Unlock?',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _qualityLabel(int? videoHeight) {
  if (videoHeight == null) return '';
  if (videoHeight >= 2160) return '2160p';
  if (videoHeight >= 1440) return '1440p';
  if (videoHeight >= 1080) return '1080p';
  if (videoHeight >= 720) return '720p';
  if (videoHeight >= 480) return '480p';
  if (videoHeight >= 360) return '360p';
  return '';
}

bool get _isMobilePlatform => Platform.isAndroid || Platform.isIOS;
