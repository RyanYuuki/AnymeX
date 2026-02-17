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
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

// ─── YouTube palette ──────────────────────────────────────────────────────────
const _kYtRed = Color(0xFFFF0000);
const _kYtRedDark = Color(0xFFCC0000);
const _kYtDark = Color(0xFF0F0F0F);
const _kYtBarBg = Color(0xCC0F0F0F); // ~80% opaque near-black

class YouTubePlayerControlTheme extends PlayerControlTheme {
  YouTubePlayerControlTheme();

  @override
  String get id => 'youtube';

  @override
  String get name => 'YouTube';

  bool get _isMobile => Platform.isAndroid || Platform.isIOS;

  // ── TOP ───────────────────────────────────────────────────────────────────

  @override
  Widget buildTopControls(BuildContext context, PlayerController controller) {
    final isDesktop = !_isMobile;

    return Obx(() {
      if (controller.isLocked.value) {
        if (!controller.showControls.value) return const SizedBox.shrink();
        return Align(
          alignment: Alignment.centerRight,
          child: _YtUnlockButton(
            onUnlock: () => controller.isLocked.value = false,
          ),
        );
      }

      return IgnorePointer(
        ignoring: !controller.showControls.value,
        child: AnimatedSlide(
          offset: controller.showControls.value
              ? Offset.zero
              : const Offset(0, -1),
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: controller.showControls.value ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.75),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                left: false,
                right: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 24 : 12,
                    vertical: isDesktop ? 14 : 8,
                  ),
                  child: _buildTopRow(context, controller, isDesktop),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildTopRow(
      BuildContext context, PlayerController controller, bool isDesktop) {
    return Row(
      children: [
        _YtIconButton(
          icon: Icons.arrow_back_rounded,
          onPressed: () => Get.back(),
          tooltip: 'Back',
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Obx(() => Text(
                controller.currentEpisode.value.title ??
                    controller.itemName ??
                    'Unknown Title',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              )),
        ),
        const SizedBox(width: 8),
        // Quality chip
        Obx(() {
          final q = _qualityLabel(controller.videoHeight.value);
          if (q.isEmpty) return const SizedBox.shrink();
          return _YtQualityBadge(text: q);
        }),
        const SizedBox(width: 6),
        _YtIconButton(
          icon: Icons.lock_outline_rounded,
          onPressed: () => controller.isLocked.value = true,
          tooltip: 'Lock Controls',
        ),
        if (isDesktop) ...[
          const SizedBox(width: 4),
          _YtIconButton(
            icon: Icons.fullscreen_rounded,
            onPressed: controller.toggleFullScreen,
            tooltip: 'Fullscreen',
          ),
        ],
        const SizedBox(width: 4),
        _YtIconButton(
          icon: Icons.more_vert_rounded,
          onPressed: () => _openSettings(context),
          tooltip: 'Settings',
        ),
      ],
    );
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
            duration: const Duration(milliseconds: 180),
            child: AnimatedScale(
              scale: controller.showControls.value ? 1.0 : 0.88,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _YtCenterButton(
                    icon: Icons.skip_previous_rounded,
                    size: 30,
                    enabled: controller.canGoBackward.value,
                    onPressed: () => controller.navigator(false),
                    tooltip: 'Previous Episode',
                  ),
                  const SizedBox(width: 14),
                  if (isDesktop)
                    _YtCenterButton(
                      icon: Icons.replay_30_rounded,
                      size: 32,
                      onPressed: () {
                        final p = controller.currentPosition.value;
                        final n = p - const Duration(seconds: 30);
                        controller.seekTo(n.isNegative ? Duration.zero : n);
                      },
                      tooltip: 'Replay 30s',
                    )
                  else
                    _YtCenterButton(
                      icon: Icons.replay_10_rounded,
                      size: 32,
                      onPressed: () {
                        final p = controller.currentPosition.value;
                        final seekBy = Duration(
                            seconds: controller.playerSettings.seekDuration);
                        final n = p - seekBy;
                        controller.seekTo(n.isNegative ? Duration.zero : n);
                      },
                      tooltip: 'Replay',
                    ),
                  const SizedBox(width: 16),
                  // Play/Pause — YouTube style: no background, just icon
                  Obx(() => _YtPlayButton(
                        isPlaying: controller.isPlaying.value,
                        isBuffering: controller.isBuffering.value,
                        onTap: controller.togglePlayPause,
                      )),
                  const SizedBox(width: 16),
                  if (isDesktop)
                    _YtCenterButton(
                      icon: Icons.forward_30_rounded,
                      size: 32,
                      onPressed: () {
                        final p = controller.currentPosition.value;
                        final d = controller.episodeDuration.value;
                        final n = p + const Duration(seconds: 30);
                        controller.seekTo(n > d ? d : n);
                      },
                      tooltip: 'Forward 30s',
                    )
                  else
                    _YtCenterButton(
                      icon: Icons.forward_10_rounded,
                      size: 32,
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
                  const SizedBox(width: 14),
                  _YtCenterButton(
                    icon: Icons.skip_next_rounded,
                    size: 30,
                    enabled: controller.canGoForward.value,
                    onPressed: () => controller.navigator(true),
                    tooltip: 'Next Episode',
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
                horizontal: isDesktop ? 20 : 12, vertical: 8),
            child: IgnorePointer(
              ignoring: true,
              child: Opacity(
                opacity: 0.5,
                child: const ProgressSlider(style: SliderStyle.capsule),
              ),
            ),
          ),
        );
      }

      return IgnorePointer(
        ignoring: !controller.showControls.value,
        child: AnimatedSlide(
          offset: controller.showControls.value
              ? Offset.zero
              : const Offset(0, 1),
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: controller.showControls.value ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.85),
                  ],
                ),
              ),
              child: SafeArea(
                top: false,
                left: false,
                right: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isDesktop ? 20 : 12,
                    0,
                    isDesktop ? 20 : 12,
                    isDesktop ? 16 : 8,
                  ),
                  child: _buildBottomSection(context, controller, isDesktop),
                ),
              ),
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
        // YouTube-style scrubber with red progress
        const ProgressSlider(style: SliderStyle.capsule),
        const SizedBox(height: 2),
        // Bottom row
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Play/Pause inline (YouTube puts this at left of bottom bar too)
            Obx(() => _YtSmallPlayButton(
                  isPlaying: controller.isPlaying.value,
                  isBuffering: controller.isBuffering.value,
                  onTap: controller.togglePlayPause,
                )),
            const SizedBox(width: 8),
            // Skip next
            Obx(() => Opacity(
                  opacity: controller.canGoForward.value ? 1.0 : 0.5,
                  child: _YtIconButton(
                    icon: Icons.skip_next_rounded,
                    onPressed: controller.canGoForward.value
                        ? () => controller.navigator(true)
                        : null,
                    tooltip: 'Next Episode',
                  ),
                )),
            const SizedBox(width: 8),
            // Skip chip
            _YtSkipChip(controller: controller),
            const SizedBox(width: 10),
            // Time
            Obx(() => Text(
                  '${controller.formattedCurrentPosition}  /  ${controller.formattedEpisodeDuration}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                )),
            if (leftButtons.isNotEmpty) ...[
              const SizedBox(width: 8),
              ...leftButtons,
            ],
            const Spacer(),
            ...rightButtons,
            if (rightButtons.isNotEmpty) const SizedBox(width: 4),
            // Episode / series info chip
            Obx(() {
              final ep = controller.currentEpisode.value.number == 'Offline'
                  ? 'Offline'
                  : 'Ep ${controller.currentEpisode.value.number}';
              return _YtTextChip(text: ep);
            }),
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

class _YtIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  const _YtIconButton(
      {required this.icon, required this.onPressed, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

class _YtCenterButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final bool enabled;
  final VoidCallback? onPressed;
  final String tooltip;
  const _YtCenterButton({
    required this.icon,
    required this.size,
    required this.onPressed,
    required this.tooltip,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onPressed : null,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(
              icon,
              color: enabled
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.35),
              size: size,
            ),
          ),
        ),
      ),
    );
  }
}

class _YtPlayButton extends StatelessWidget {
  final bool isPlaying;
  final bool isBuffering;
  final VoidCallback onTap;
  const _YtPlayButton(
      {required this.isPlaying,
      required this.isBuffering,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isPlaying ? 'Pause' : 'Play',
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 68,
          height: 68,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 110),
              child: isBuffering
                  ? const SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(
                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      key: ValueKey(isPlaying),
                      color: Colors.white,
                      size: 52,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// Smaller inline play/pause for the bottom bar
class _YtSmallPlayButton extends StatelessWidget {
  final bool isPlaying;
  final bool isBuffering;
  final VoidCallback onTap;
  const _YtSmallPlayButton(
      {required this.isPlaying,
      required this.isBuffering,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isPlaying ? 'Pause' : 'Play',
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 110),
              child: isBuffering
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(
                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      key: ValueKey(isPlaying),
                      color: Colors.white,
                      size: 28,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _YtQualityBadge extends StatelessWidget {
  final String text;
  const _YtQualityBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _kYtRed,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _YtSkipChip extends StatelessWidget {
  final PlayerController controller;
  const _YtSkipChip({required this.controller});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          controller.megaSeek(controller.playerSettings.skipDuration),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 0.8,
          ),
        ),
        child: Text(
          '+${controller.playerSettings.skipDuration}s',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

class _YtTextChip extends StatelessWidget {
  final String text;
  const _YtTextChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _YtUnlockButton extends StatefulWidget {
  final VoidCallback onUnlock;
  const _YtUnlockButton({required this.onUnlock});

  @override
  State<_YtUnlockButton> createState() => _YtUnlockButtonState();
}

class _YtUnlockButtonState extends State<_YtUnlockButton> {
  bool _confirm = false;

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
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _kYtBarBg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_open_rounded,
                  color: Colors.white, size: 18),
              if (_confirm) ...[
                const SizedBox(width: 8),
                const Text(
                  'Unlock?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
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
