import 'dart:convert';
import 'dart:io';

import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/screens/anime/watch/controls/themes/setup/player_control_theme.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/bottom_sheet.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/control_button.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/progress_slider.dart';
import 'package:anymex/screens/settings/sub_settings/settings_player.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class MinimalPlayerControlTheme extends PlayerControlTheme {
  MinimalPlayerControlTheme();

  @override
  String get id => 'minimal';

  @override
  String get name => 'Minimal';

  bool get _isMobile => Platform.isAndroid || Platform.isIOS;

  // Subtle text shadow so icons/text stay readable on any video
  static const _shadow = [
    Shadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 1)),
  ];
  static const _iconShadow = [
    BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 1)),
  ];

  // ── TOP ───────────────────────────────────────────────────────────────────

  @override
  Widget buildTopControls(BuildContext context, PlayerController controller) {
    final isDesktop = !_isMobile;

    return Obx(() {
      if (controller.isLocked.value) {
        if (!controller.showControls.value) return const SizedBox.shrink();
        return Align(
          alignment: Alignment.centerRight,
          child: _MinimalUnlockButton(
            onUnlock: () => controller.isLocked.value = false,
          ),
        );
      }

      return IgnorePointer(
        ignoring: !controller.showControls.value,
        child: AnimatedOpacity(
          opacity: controller.showControls.value ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 180),
          child: SafeArea(
            bottom: false,
            left: false,
            right: false,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 24 : 16,
                vertical: isDesktop ? 16 : 10,
              ),
              child: Row(
                children: [
                  _MinimalIconButton(
                    icon: Icons.arrow_back_ios_rounded,
                    onPressed: () => Get.back(),
                    tooltip: 'Back',
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Obx(() => Text(
                              controller.currentEpisode.value.title ??
                                  controller.itemName ??
                                  'Unknown Title',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isDesktop ? 15 : 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.1,
                                shadows: _shadow,
                              ),
                            )),
                        const SizedBox(height: 2),
                        Obx(() => Text(
                              _episodeSubtitle(controller),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                shadows: _shadow,
                              ),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Quality badge (text only, no background)
                  Obx(() {
                    final q = _qualityLabel(controller.videoHeight.value);
                    if (q.isEmpty) return const SizedBox.shrink();
                    return Text(
                      q,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.70),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        shadows: _shadow,
                      ),
                    );
                  }),
                  const SizedBox(width: 8),
                  _MinimalIconButton(
                    icon: Icons.lock_outline_rounded,
                    onPressed: () => controller.isLocked.value = true,
                    tooltip: 'Lock Controls',
                  ),
                  if (isDesktop) ...[
                    const SizedBox(width: 4),
                    _MinimalIconButton(
                      icon: Icons.fullscreen_rounded,
                      onPressed: controller.toggleFullScreen,
                      tooltip: 'Fullscreen',
                    ),
                  ],
                  const SizedBox(width: 4),
                  _MinimalIconButton(
                    icon: Icons.more_vert_rounded,
                    onPressed: () => _openSettings(context),
                    tooltip: 'Settings',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  String _episodeSubtitle(PlayerController c) {
    final epNum = c.currentEpisode.value.number == 'Offline'
        ? 'Offline'
        : 'Episode ${c.currentEpisode.value.number}';
    final title = (c.anilistData.title == '?'
            ? c.folderName
            : c.anilistData.title) ??
        '';
    return title.isNotEmpty ? '$title  ·  $epNum' : epNum;
  }

  // ── CENTER ─────────────────────────────────────────────────────────────────

  @override
  Widget buildCenterControls(
      BuildContext context, PlayerController controller) {
    final isDesktop = !_isMobile;

    return Obx(() {
      if (controller.isLocked.value) return const SizedBox.shrink();

      return IgnorePointer(
        ignoring: !controller.showControls.value,
        child: Align(
          alignment: Alignment.center,
          child: AnimatedOpacity(
            opacity: controller.showControls.value ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 160),
            child: AnimatedScale(
              scale: controller.showControls.value ? 1.0 : 0.92,
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _MinimalCenterIcon(
                    icon: Icons.skip_previous_rounded,
                    size: 28,
                    enabled: controller.canGoBackward.value,
                    onPressed: () => controller.navigator(false),
                    tooltip: 'Previous',
                  ),
                  const SizedBox(width: 16),
                  if (isDesktop)
                    _MinimalCenterIcon(
                      icon: Icons.replay_30_rounded,
                      size: 30,
                      onPressed: () {
                        final p = controller.currentPosition.value;
                        final n = p - const Duration(seconds: 30);
                        controller.seekTo(n.isNegative ? Duration.zero : n);
                      },
                      tooltip: 'Replay 30s',
                    )
                  else
                    _MinimalCenterIcon(
                      icon: Icons.replay_10_rounded,
                      size: 30,
                      onPressed: () {
                        final p = controller.currentPosition.value;
                        final seekBy = Duration(
                            seconds: controller.playerSettings.seekDuration);
                        final n = p - seekBy;
                        controller.seekTo(n.isNegative ? Duration.zero : n);
                      },
                      tooltip: 'Replay',
                    ),
                  const SizedBox(width: 20),
                  // Play/Pause — slightly larger, still no background
                  Obx(() => Tooltip(
                        message: controller.isPlaying.value ? 'Pause' : 'Play',
                        child: GestureDetector(
                          onTap: controller.togglePlayPause,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 110),
                            child: controller.isBuffering.value
                                ? const SizedBox(
                                    width: 52,
                                    height: 52,
                                    child: ExpressiveLoadingIndicator(),
                                  )
                                : Icon(
                                    controller.isPlaying.value
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    key: ValueKey(controller.isPlaying.value),
                                    color: Colors.white,
                                    size: 56,
                                    shadows: _shadow
                                        .map((s) => Shadow(
                                              color: s.color,
                                              blurRadius: s.blurRadius * 1.5,
                                              offset: s.offset,
                                            ))
                                        .toList(),
                                  ),
                          ),
                        ),
                      )),
                  const SizedBox(width: 20),
                  if (isDesktop)
                    _MinimalCenterIcon(
                      icon: Icons.forward_30_rounded,
                      size: 30,
                      onPressed: () {
                        final p = controller.currentPosition.value;
                        final d = controller.episodeDuration.value;
                        final n = p + const Duration(seconds: 30);
                        controller.seekTo(n > d ? d : n);
                      },
                      tooltip: 'Forward 30s',
                    )
                  else
                    _MinimalCenterIcon(
                      icon: Icons.forward_10_rounded,
                      size: 30,
                      onPressed: () {
                        final p = controller.currentPosition.value;
                        final d = controller.episodeDuration.value;
                        final seekBy = Duration(
                            seconds: controller.playerSettings.seekDuration);
                        final n = p + seekBy;
                        controller.seekTo(n > d ? d : n);
                      },
                      tooltip: 'Forward',
                    ),
                  const SizedBox(width: 16),
                  _MinimalCenterIcon(
                    icon: Icons.skip_next_rounded,
                    size: 28,
                    enabled: controller.canGoForward.value,
                    onPressed: () => controller.navigator(true),
                    tooltip: 'Next',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  // ── BOTTOM ─────────────────────────────────────────────────────────────────

  @override
  Widget buildBottomControls(
      BuildContext context, PlayerController controller) {
    final isDesktop = !_isMobile;

    return Obx(() {
      if (controller.isLocked.value) {
        if (!controller.showControls.value) return const SizedBox.shrink();
        return SafeArea(
          top: false,
          left: false,
          right: false,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 24 : 16,
              vertical: isDesktop ? 16 : 10,
            ),
            child: IgnorePointer(
              ignoring: true,
              child: Opacity(opacity: 0.4, child: const ProgressSlider()),
            ),
          ),
        );
      }

      return IgnorePointer(
        ignoring: !controller.showControls.value,
        child: AnimatedOpacity(
          opacity: controller.showControls.value ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 180),
          child: SafeArea(
            top: false,
            left: false,
            right: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isDesktop ? 24 : 16,
                0,
                isDesktop ? 24 : 16,
                isDesktop ? 18 : 10,
              ),
              child: _buildBottomSection(context, controller, isDesktop),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildBottomSection(BuildContext context,
      PlayerController controller, bool isDesktop) {
    final String jsonString =
        PlayerUiKeys.bottomControlsSettings.get<String>('{}');
    final Map<String, dynamic> config = json.decode(jsonString);
    final List<String> leftIds =
        List<String>.from(config['leftButtonIds'] ?? []);
    final List<String> rightIds =
        List<String>.from(config['rightButtonIds'] ?? []);
    final Map<String, dynamic> btnCfg =
        Map<String, dynamic>.from(config['buttonConfigs'] ?? {});

    bool visible(String id) => (btnCfg[id]?['visible'] as bool?) ?? true;

    final widgets = _buildButtonWidgets(context, controller);

    List<Widget> buildList(List<String> ids) {
      final result = <Widget>[];
      for (final id in ids) {
        if (!visible(id)) continue;
        if (id == 'server' && controller.isOffline.value) continue;
        if (id == 'quality' && controller.isOffline.value) continue;
        if (id == 'orientation' &&
            !(Platform.isAndroid || Platform.isIOS)) continue;
        final w = widgets[id];
        if (w != null) result.add(w);
      }
      return result;
    }

    final leftButtons = buildList(leftIds);
    final rightButtons = buildList(rightIds);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Skip chip - text only
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () =>
                controller.megaSeek(controller.playerSettings.skipDuration),
            child: Text(
              '+${controller.playerSettings.skipDuration}s  ▶▶',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                shadows: _shadow,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Slider
        const ProgressSlider(),
        const SizedBox(height: 2),
        // Time + buttons row
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Obx(() => Text(
                  controller.formattedCurrentPosition,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    shadows: _shadow,
                  ),
                )),
            Text(
              '  /  ',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 12,
                shadows: _shadow,
              ),
            ),
            Obx(() => Text(
                  controller.formattedEpisodeDuration,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                    shadows: _shadow,
                  ),
                )),
            if (leftButtons.isNotEmpty) ...[
              const SizedBox(width: 10),
              ...leftButtons,
            ],
            const Spacer(),
            ...rightButtons,
          ],
        ),
      ],
    );
  }

  Map<String, Widget> _buildButtonWidgets(
      BuildContext context, PlayerController controller) {
    return {
      'playlist': ControlButton(
        icon: Symbols.playlist_play_rounded,
        onPressed: () => controller.isEpisodePaneOpened.value =
            !controller.isEpisodePaneOpened.value,
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
  }

  void _openSettings(BuildContext context) {
    showModalBottomSheet(
      context: Get.context!,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height,
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: const SettingsPlayer(isModal: true),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _MinimalIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  const _MinimalIconButton(
      {required this.icon, required this.onPressed, required this.tooltip});

  static const _shadow = [
    Shadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 1)),
  ];

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(
            icon,
            color: Colors.white,
            size: 22,
            shadows: _shadow,
          ),
        ),
      ),
    );
  }
}

class _MinimalCenterIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final bool enabled;
  final VoidCallback? onPressed;
  final String tooltip;
  const _MinimalCenterIcon({
    required this.icon,
    required this.size,
    required this.onPressed,
    required this.tooltip,
    this.enabled = true,
  });

  static const _shadow = [
    Shadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 1)),
  ];

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            color: enabled
                ? Colors.white
                : Colors.white.withValues(alpha: 0.30),
            size: size,
            shadows: _shadow,
          ),
        ),
      ),
    );
  }
}

class _MinimalUnlockButton extends StatefulWidget {
  final VoidCallback onUnlock;
  const _MinimalUnlockButton({required this.onUnlock});

  @override
  State<_MinimalUnlockButton> createState() => _MinimalUnlockButtonState();
}

class _MinimalUnlockButtonState extends State<_MinimalUnlockButton> {
  bool _confirm = false;

  static const _shadow = [
    Shadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 1)),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: GestureDetector(
        onTap: () {
          if (_confirm) {
            widget.onUnlock();
          } else {
            setState(() => _confirm = true);
            Future.delayed(const Duration(seconds: 2),
                () { if (mounted) setState(() => _confirm = false); });
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_open_rounded,
                color: Colors.white, size: 20, shadows: _shadow),
            if (_confirm) ...[
              const SizedBox(width: 6),
              Text(
                'Unlock?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  shadows: _shadow,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _qualityLabel(int? h) {
  if (h == null) return '';
  if (h >= 2160) return '4K';
  if (h >= 1440) return '1440p';
  if (h >= 1080) return '1080p';
  if (h >= 720) return '720p';
  if (h >= 480) return '480p';
  if (h >= 360) return '360p';
  return '';
}
