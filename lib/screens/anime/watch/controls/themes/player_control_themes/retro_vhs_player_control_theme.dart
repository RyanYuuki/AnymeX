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

// ─── VHS palette ─────────────────────────────────────────────────────────────
const _kAmber = Color(0xFFFFB300);
const _kAmberDim = Color(0xFFCC8A00);
const _kGreen = Color(0xFF39FF14);
const _kVhsDark = Color(0xF0100C05);
const _kVhsBar = Color(0xF5130F03);

class RetroVhsPlayerControlTheme extends PlayerControlTheme {
  RetroVhsPlayerControlTheme();

  @override
  String get id => 'retro_vhs';

  @override
  String get name => 'Retro VHS';

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
          child: _VhsUnlockButton(
              onUnlock: () => controller.isLocked.value = false),
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
              color: _kVhsBar,
              child: SafeArea(
                bottom: false,
                left: false,
                right: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 20 : 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      _VhsButton(
                        label: '◀',
                        onPressed: () => Get.back(),
                        tooltip: 'Back',
                      ),
                      const SizedBox(width: 12),
                      // VHS-style title with blinking REC dot
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                const _VhsRecDot(),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Obx(() => Text(
                                        (controller.currentEpisode.value
                                                    .title ??
                                                controller.itemName ??
                                                'UNKNOWN TITLE')
                                            .toUpperCase(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: _kAmber,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 2,
                                          fontFamily: 'monospace',
                                          shadows: [
                                            Shadow(
                                                color: _kAmber, blurRadius: 6)
                                          ],
                                        ),
                                      )),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Obx(() => Text(
                                  '${_qualityLabel(controller.videoHeight.value).isNotEmpty ? '[ ${_qualityLabel(controller.videoHeight.value)} ]  ' : ''}'
                                  '${controller.currentEpisode.value.number == 'Offline' ? 'OFFLINE' : 'EP.${controller.currentEpisode.value.number}'}',
                                  style: const TextStyle(
                                    color: _kAmberDim,
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                    letterSpacing: 1.5,
                                  ),
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _VhsButton(
                        label: '🔒',
                        onPressed: () => controller.isLocked.value = true,
                        tooltip: 'Lock',
                        useIcon: true,
                        iconData: Icons.lock_outline_rounded,
                      ),
                      const SizedBox(width: 6),
                      if (isDesktop) ...[
                        _VhsButton(
                          label: '⛶',
                          onPressed: controller.toggleFullScreen,
                          tooltip: 'Fullscreen',
                          useIcon: true,
                          iconData: Icons.fullscreen_rounded,
                        ),
                        const SizedBox(width: 6),
                      ],
                      _VhsButton(
                        label: '⚙',
                        onPressed: () => _openSettings(context),
                        tooltip: 'Settings',
                        useIcon: true,
                        iconData: Icons.settings_outlined,
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: _kVhsDark,
                border: Border.all(
                    color: _kAmber.withValues(alpha: 0.6), width: 1),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                      color: _kAmber.withValues(alpha: 0.15),
                      blurRadius: 24)
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _VhsButton(
                    label: '|◀◀',
                    onPressed: controller.canGoBackward.value
                        ? () => controller.navigator(false)
                        : null,
                    tooltip: 'Previous',
                    enabled: controller.canGoBackward.value,
                  ),
                  const SizedBox(width: 10),
                  _VhsButton(
                    label: isDesktop ? '◀◀' : '◀',
                    onPressed: () {
                      final p = controller.currentPosition.value;
                      final s = isDesktop
                          ? 30
                          : controller.playerSettings.seekDuration;
                      final n = p - Duration(seconds: s);
                      controller.seekTo(n.isNegative ? Duration.zero : n);
                    },
                    tooltip: isDesktop ? 'Replay 30s' : 'Replay',
                  ),
                  const SizedBox(width: 14),
                  // VHS-style play/pause — big square button
                  Obx(() => _VhsPlayButton(
                        isPlaying: controller.isPlaying.value,
                        isBuffering: controller.isBuffering.value,
                        onTap: controller.togglePlayPause,
                      )),
                  const SizedBox(width: 14),
                  _VhsButton(
                    label: isDesktop ? '▶▶' : '▶',
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
                  ),
                  const SizedBox(width: 10),
                  _VhsButton(
                    label: '▶▶|',
                    onPressed: controller.canGoForward.value
                        ? () => controller.navigator(true)
                        : null,
                    tooltip: 'Next',
                    enabled: controller.canGoForward.value,
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
        return Container(
          color: _kVhsBar,
          child: SafeArea(
            top: false,
            left: false,
            right: false,
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 20 : 12, vertical: 8),
              child: IgnorePointer(
                ignoring: true,
                child: Opacity(
                    opacity: 0.4,
                    child: const ProgressSlider(style: SliderStyle.ios)),
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
              color: _kVhsBar,
              child: SafeArea(
                top: false,
                left: false,
                right: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      isDesktop ? 20 : 12, 8,
                      isDesktop ? 20 : 12, isDesktop ? 14 : 10),
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
        // Amber top border line (VHS tape feel)
        Container(height: 1, color: _kAmber.withValues(alpha: 0.4)),
        const SizedBox(height: 8),
        // Slider
        const ProgressSlider(style: SliderStyle.ios),
        const SizedBox(height: 6),
        // Timecode row
        Row(
          children: [
            // Timecode display — monospaced
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(
                    color: _kGreen.withValues(alpha: 0.6), width: 0.8),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Obx(() => Text(
                    controller.formattedCurrentPosition,
                    style: const TextStyle(
                      color: _kGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                      letterSpacing: 1.5,
                      shadows: [Shadow(color: _kGreen, blurRadius: 4)],
                    ),
                  )),
            ),
            const SizedBox(width: 6),
            const Text('/',
                style: TextStyle(
                    color: _kAmberDim,
                    fontSize: 12,
                    fontFamily: 'monospace')),
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(
                    color: _kAmberDim.withValues(alpha: 0.4), width: 0.8),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Obx(() => Text(
                    controller.formattedEpisodeDuration,
                    style: const TextStyle(
                      color: _kAmberDim,
                      fontSize: 12,
                      fontFamily: 'monospace',
                      letterSpacing: 1.5,
                    ),
                  )),
            ),
            if (leftBtns.isNotEmpty) ...[
              const SizedBox(width: 10),
              ...leftBtns,
            ],
            const Spacer(),
            // Skip button — VHS style
            GestureDetector(
              onTap: () =>
                  controller.megaSeek(controller.playerSettings.skipDuration),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: _kAmber.withValues(alpha: 0.6), width: 0.8),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  '▶▶ +${controller.playerSettings.skipDuration}s',
                  style: const TextStyle(
                    color: _kAmber,
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    shadows: [Shadow(color: _kAmber, blurRadius: 4)],
                  ),
                ),
              ),
            ),
            if (rightBtns.isNotEmpty) ...[
              const SizedBox(width: 8),
              ...rightBtns,
            ],
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

class _VhsButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final String tooltip;
  final bool enabled;
  final bool useIcon;
  final IconData? iconData;
  const _VhsButton({
    required this.label,
    required this.onPressed,
    required this.tooltip,
    this.enabled = true,
    this.useIcon = false,
    this.iconData,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled ? _kAmber : _kAmber.withValues(alpha: 0.3);
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.6), width: 0.8),
            borderRadius: BorderRadius.circular(3),
          ),
          child: useIcon && iconData != null
              ? Icon(iconData!, color: color, size: 16)
              : Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    shadows: enabled
                        ? [Shadow(color: color, blurRadius: 4)]
                        : null,
                  ),
                ),
        ),
      ),
    );
  }
}

class _VhsPlayButton extends StatelessWidget {
  final bool isPlaying;
  final bool isBuffering;
  final VoidCallback onTap;
  const _VhsPlayButton(
      {required this.isPlaying,
      required this.isBuffering,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 58,
        decoration: BoxDecoration(
          color: _kAmber.withValues(alpha: 0.08),
          border: Border.all(color: _kAmber, width: 1.2),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
                color: _kAmber.withValues(alpha: 0.35), blurRadius: 16)
          ],
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 120),
            child: isBuffering
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation<Color>(_kAmber),
                    ),
                  )
                : Text(
                    isPlaying ? '⏸' : '▶',
                    key: ValueKey(isPlaying),
                    style: const TextStyle(
                      color: _kAmber,
                      fontSize: 26,
                      shadows: [Shadow(color: _kAmber, blurRadius: 10)],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Blinking REC dot
class _VhsRecDot extends StatefulWidget {
  const _VhsRecDot();

  @override
  State<_VhsRecDot> createState() => _VhsRecDotState();
}

class _VhsRecDotState extends State<_VhsRecDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.2, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: const Text(
        '● REC',
        style: TextStyle(
          color: Colors.red,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          fontFamily: 'monospace',
          letterSpacing: 1,
          shadows: [Shadow(color: Colors.red, blurRadius: 6)],
        ),
      ),
    );
  }
}

class _VhsUnlockButton extends StatefulWidget {
  final VoidCallback onUnlock;
  const _VhsUnlockButton({required this.onUnlock});

  @override
  State<_VhsUnlockButton> createState() => _VhsUnlockButtonState();
}

class _VhsUnlockButtonState extends State<_VhsUnlockButton> {
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: _kVhsDark,
            border: Border.all(color: _kAmber, width: 1),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔓',
                  style: TextStyle(
                      color: _kAmber,
                      fontSize: 14,
                      shadows: [Shadow(color: _kAmber, blurRadius: 4)])),
              if (_confirm) ...[
                const SizedBox(width: 8),
                const Text(
                  'UNLOCK?',
                  style: TextStyle(
                    color: _kAmber,
                    fontSize: 10,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    shadows: [Shadow(color: _kAmber, blurRadius: 4)],
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
