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

// ─── Cyberpunk palette ────────────────────────────────────────────────────────
const _kCyan = Color(0xFF00FFFF);
const _kMagenta = Color(0xFFFF00FF);
const _kNeonYellow = Color(0xFFE8FF00);
const _kDarkBg = Color(0xCC000814);
const _kPanelBg = Color(0xB3000D1A);

class CyberpunkPlayerControlTheme extends PlayerControlTheme {
  CyberpunkPlayerControlTheme();

  @override
  String get id => 'cyberpunk';

  @override
  String get name => 'Cyberpunk';

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
          child: _CyberUnlockButton(
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
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: controller.showControls.value ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 240),
            child: SafeArea(
              bottom: false,
              left: false,
              right: false,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 24 : 12,
                  vertical: isDesktop ? 16 : 8,
                ),
                child: _CyberPanel(
                  child: Row(
                    children: [
                      _CyberIconButton(
                        icon: Icons.arrow_back_ios_rounded,
                        onPressed: () => Get.back(),
                        tooltip: 'Back',
                        accent: _kCyan,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Obx(() => Text(
                                  (controller.currentEpisode.value.title ??
                                          controller.itemName ??
                                          'UNKNOWN')
                                      .toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _kCyan,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.5,
                                    shadows: [
                                      Shadow(
                                          color: _kCyan,
                                          blurRadius: 8)
                                    ],
                                  ),
                                )),
                            const SizedBox(height: 4),
                            Obx(() => Row(
                                  children: [
                                    _CyberTag(
                                      text: controller.currentEpisode.value
                                                  .number ==
                                              'Offline'
                                          ? 'OFFLINE'
                                          : 'EP_${controller.currentEpisode.value.number}',
                                      color: _kMagenta,
                                    ),
                                    const SizedBox(width: 6),
                                    Obx(() {
                                      final q = _qualityLabel(
                                          controller.videoHeight.value);
                                      if (q.isEmpty)
                                        return const SizedBox.shrink();
                                      return _CyberTag(
                                          text: q, color: _kNeonYellow);
                                    }),
                                  ],
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _CyberIconButton(
                        icon: Icons.lock_outline_rounded,
                        onPressed: () => controller.isLocked.value = true,
                        tooltip: 'Lock',
                        accent: _kMagenta,
                      ),
                      const SizedBox(width: 6),
                      if (isDesktop) ...[
                        _CyberIconButton(
                          icon: Icons.fullscreen_rounded,
                          onPressed: controller.toggleFullScreen,
                          tooltip: 'Fullscreen',
                          accent: _kCyan,
                        ),
                        const SizedBox(width: 6),
                      ],
                      _CyberIconButton(
                        icon: Icons.settings_outlined,
                        onPressed: () => _openSettings(context),
                        tooltip: 'Settings',
                        accent: _kCyan,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
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
            duration: const Duration(milliseconds: 200),
            child: AnimatedScale(
              scale: controller.showControls.value ? 1.0 : 0.85,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CyberCenterButton(
                    icon: Icons.skip_previous_rounded,
                    enabled: controller.canGoBackward.value,
                    onPressed: () => controller.navigator(false),
                    tooltip: 'Prev',
                    accent: _kMagenta,
                    size: 30,
                  ),
                  const SizedBox(width: 16),
                  _CyberCenterButton(
                    icon: isDesktop
                        ? Icons.replay_30_rounded
                        : Icons.replay_10_rounded,
                    onPressed: () {
                      final p = controller.currentPosition.value;
                      final s = isDesktop
                          ? 30
                          : controller.playerSettings.seekDuration;
                      final n = p - Duration(seconds: s);
                      controller.seekTo(n.isNegative ? Duration.zero : n);
                    },
                    tooltip: isDesktop ? 'Replay 30s' : 'Replay',
                    accent: _kCyan,
                    size: 32,
                  ),
                  const SizedBox(width: 20),
                  // Main hexagonal play button
                  Obx(() => _CyberPlayButton(
                        isPlaying: controller.isPlaying.value,
                        isBuffering: controller.isBuffering.value,
                        onTap: controller.togglePlayPause,
                      )),
                  const SizedBox(width: 20),
                  _CyberCenterButton(
                    icon: isDesktop
                        ? Icons.forward_30_rounded
                        : Icons.forward_10_rounded,
                    onPressed: () {
                      final p = controller.currentPosition.value;
                      final d = controller.episodeDuration.value;
                      final s = isDesktop
                          ? 30
                          : controller.playerSettings.seekDuration;
                      final n = p + Duration(seconds: s);
                      controller.seekTo(n > d ? d : n);
                    },
                    tooltip: isDesktop ? 'Forward 30s' : 'Forward',
                    accent: _kCyan,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  _CyberCenterButton(
                    icon: Icons.skip_next_rounded,
                    enabled: controller.canGoForward.value,
                    onPressed: () => controller.navigator(true),
                    tooltip: 'Next',
                    accent: _kMagenta,
                    size: 30,
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
                horizontal: isDesktop ? 24 : 12, vertical: 10),
            child: IgnorePointer(
              ignoring: true,
              child: Opacity(
                  opacity: 0.4, child: const ProgressSlider(style: SliderStyle.ios)),
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
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: controller.showControls.value ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 240),
            child: SafeArea(
              top: false,
              left: false,
              right: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    isDesktop ? 24 : 12, 0, isDesktop ? 24 : 12,
                    isDesktop ? 18 : 10),
                child: _CyberPanel(
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
    final Map<String, dynamic> cfg = json.decode(jsonString);
    final leftIds = List<String>.from(cfg['leftButtonIds'] ?? []);
    final rightIds = List<String>.from(cfg['rightButtonIds'] ?? []);
    final btnCfg = Map<String, dynamic>.from(cfg['buttonConfigs'] ?? {});
    bool vis(String id) => (btnCfg[id]?['visible'] as bool?) ?? true;

    final widgets = _buildButtonWidgets(context, controller);
    List<Widget> buildList(List<String> ids) {
      final result = <Widget>[];
      for (final id in ids) {
        if (!vis(id)) continue;
        if (id == 'server' && controller.isOffline.value) continue;
        if (id == 'quality' && controller.isOffline.value) continue;
        if (id == 'orientation' &&
            !(Platform.isAndroid || Platform.isIOS)) continue;
        final w = widgets[id];
        if (w != null) result.add(w);
      }
      return result;
    }

    final leftBtns = buildList(leftIds);
    final rightBtns = buildList(rightIds);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Skip chip — neon yellow
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () =>
                controller.megaSeek(controller.playerSettings.skipDuration),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: _kNeonYellow.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: _kNeonYellow, width: 1),
                boxShadow: [
                  BoxShadow(
                      color: _kNeonYellow.withValues(alpha: 0.3),
                      blurRadius: 8)
                ],
              ),
              child: Text(
                '+${controller.playerSettings.skipDuration}s',
                style: const TextStyle(
                  color: _kNeonYellow,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  shadows: [Shadow(color: _kNeonYellow, blurRadius: 6)],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Slider — ios style, tinted cyan
        const ProgressSlider(style: SliderStyle.ios),
        const SizedBox(height: 6),
        // Bottom row
        Row(
          children: [
            Obx(() => Text(
                  controller.formattedCurrentPosition,
                  style: const TextStyle(
                    color: _kCyan,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    shadows: [Shadow(color: _kCyan, blurRadius: 6)],
                  ),
                )),
            const SizedBox(width: 4),
            Text(
              '/',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
            ),
            const SizedBox(width: 4),
            Obx(() => Text(
                  controller.formattedEpisodeDuration,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1,
                  ),
                )),
            if (leftBtns.isNotEmpty) ...[
              const SizedBox(width: 10),
              ...leftBtns,
            ],
            const Spacer(),
            ...rightBtns,
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
          compact: true),
      'shaders': ControlButton(
          icon: Symbols.tune_rounded,
          onPressed: () => controller.openColorProfileBottomSheet(context),
          tooltip: 'Shaders',
          compact: true),
      'subtitles': !controller.isOffline.value
          ? ControlButton(
              icon: Symbols.subtitles_rounded,
              onPressed: () =>
                  PlayerBottomSheets.showSubtitleTracks(context, controller),
              tooltip: 'Subtitles',
              compact: true)
          : ControlButton(
              icon: Symbols.subtitles_rounded,
              onPressed: () =>
                  PlayerBottomSheets.showOfflineSubs(context, controller),
              tooltip: 'Subtitles',
              compact: true),
      'server': ControlButton(
          icon: Symbols.cloud_rounded,
          onPressed: () =>
              PlayerBottomSheets.showVideoServers(context, controller),
          tooltip: 'Server',
          compact: true),
      'quality': ControlButton(
          icon: Symbols.high_quality_rounded,
          onPressed: () =>
              PlayerBottomSheets.showVideoQuality(context, controller),
          tooltip: 'Quality',
          compact: true),
      'speed': ControlButton(
          icon: Symbols.speed_rounded,
          onPressed: () =>
              PlayerBottomSheets.showPlaybackSpeed(context, controller),
          tooltip: 'Speed',
          compact: true),
      'audio_track': ControlButton(
          icon: Symbols.music_note_rounded,
          onPressed: () =>
              PlayerBottomSheets.showAudioTracks(context, controller),
          tooltip: 'Audio Track',
          compact: true),
      'orientation': ControlButton(
          icon: Icons.screen_rotation_rounded,
          onPressed: () => controller.toggleOrientation(),
          tooltip: 'Orientation',
          compact: true),
      'aspect_ratio': ControlButton(
          icon: Symbols.fit_screen,
          onPressed: () => controller.toggleVideoFit(),
          tooltip: 'Aspect Ratio',
          compact: true),
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
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(28))),
        child: const SettingsPlayer(isModal: true),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _CyberPanel extends StatelessWidget {
  final Widget child;
  const _CyberPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _kPanelBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _kCyan.withValues(alpha: 0.5), width: 1),
            boxShadow: [
              BoxShadow(
                  color: _kCyan.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: -2),
              BoxShadow(
                  color: _kMagenta.withValues(alpha: 0.08),
                  blurRadius: 30,
                  spreadRadius: -5),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _CyberTag extends StatelessWidget {
  final String text;
  final Color color;
  const _CyberTag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.7), width: 0.8),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.25), blurRadius: 6)
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          shadows: [Shadow(color: color, blurRadius: 4)],
        ),
      ),
    );
  }
}

class _CyberIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final Color accent;
  const _CyberIconButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onPressed,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              border:
                  Border.all(color: accent.withValues(alpha: 0.4), width: 0.8),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: accent, size: 18,
                shadows: [Shadow(color: accent, blurRadius: 8)]),
          ),
        ),
      ),
    );
  }
}

class _CyberCenterButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final bool enabled;
  final VoidCallback? onPressed;
  final String tooltip;
  final Color accent;
  const _CyberCenterButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    required this.accent,
    required this.size,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(
                color: enabled
                    ? accent.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.1),
                width: 0.8),
            borderRadius: BorderRadius.circular(8),
            boxShadow: enabled
                ? [
                    BoxShadow(
                        color: accent.withValues(alpha: 0.2),
                        blurRadius: 12)
                  ]
                : null,
          ),
          child: Icon(
            icon,
            color: enabled ? accent : Colors.white.withValues(alpha: 0.25),
            size: size,
            shadows: enabled ? [Shadow(color: accent, blurRadius: 8)] : null,
          ),
        ),
      ),
    );
  }
}

class _CyberPlayButton extends StatelessWidget {
  final bool isPlaying;
  final bool isBuffering;
  final VoidCallback onTap;
  const _CyberPlayButton(
      {required this.isPlaying,
      required this.isBuffering,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _kCyan.withValues(alpha: 0.08),
          border: Border.all(color: _kCyan, width: 1.5),
          boxShadow: [
            BoxShadow(
                color: _kCyan.withValues(alpha: 0.5),
                blurRadius: 28,
                spreadRadius: 0),
            BoxShadow(
                color: _kMagenta.withValues(alpha: 0.2),
                blurRadius: 40,
                spreadRadius: -4),
          ],
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 120),
            child: isBuffering
                ? const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(_kCyan),
                    ),
                  )
                : Icon(
                    isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    key: ValueKey(isPlaying),
                    color: _kCyan,
                    size: 38,
                    shadows: const [Shadow(color: _kCyan, blurRadius: 16)],
                  ),
          ),
        ),
      ),
    );
  }
}

class _CyberUnlockButton extends StatefulWidget {
  final VoidCallback onUnlock;
  const _CyberUnlockButton({required this.onUnlock});

  @override
  State<_CyberUnlockButton> createState() => _CyberUnlockButtonState();
}

class _CyberUnlockButtonState extends State<_CyberUnlockButton> {
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: _kPanelBg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _kMagenta, width: 1),
            boxShadow: [
              BoxShadow(
                  color: _kMagenta.withValues(alpha: 0.4),
                  blurRadius: 16)
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_open_rounded,
                  color: _kMagenta,
                  size: 18,
                  shadows: [Shadow(color: _kMagenta, blurRadius: 8)]),
              if (_confirm) ...[
                const SizedBox(width: 8),
                const Text(
                  'UNLOCK?',
                  style: TextStyle(
                    color: _kMagenta,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    shadows: [Shadow(color: _kMagenta, blurRadius: 6)],
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
