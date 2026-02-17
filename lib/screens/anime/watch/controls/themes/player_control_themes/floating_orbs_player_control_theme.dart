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

class FloatingOrbsPlayerControlTheme extends PlayerControlTheme {
  FloatingOrbsPlayerControlTheme();

  @override
  String get id => 'floating_orbs';

  @override
  String get name => 'Floating Orbs';

  bool get _isMobile => Platform.isAndroid || Platform.isIOS;

  // ── TOP ── title floats top-left, actions float top-right as individual orbs

  @override
  Widget buildTopControls(BuildContext context, PlayerController controller) {
    final isDesktop = !_isMobile;

    return Obx(() {
      if (controller.isLocked.value) {
        if (!controller.showControls.value) return const SizedBox.shrink();
        return Align(
          alignment: Alignment.centerRight,
          child: _OrbUnlockButton(
              onUnlock: () => controller.isLocked.value = false),
        );
      }

      return IgnorePointer(
        ignoring: !controller.showControls.value,
        child: AnimatedOpacity(
          opacity: controller.showControls.value ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 220),
          child: SafeArea(
            bottom: false,
            left: false,
            right: false,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 20 : 12,
                vertical: isDesktop ? 14 : 8,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back orb
                  _Orb(
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded,
                          color: Colors.white, size: 18),
                      onPressed: () => Get.back(),
                      tooltip: 'Back',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                          minWidth: 36, minHeight: 36),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Title pill — wider capsule
                  Expanded(
                    child: _OrbPill(
                      child: Obx(() => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                controller.currentEpisode.value.title ??
                                    controller.itemName ??
                                    'Unknown',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                _subtitle(controller),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          )),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Right action orbs — each separate
                  Obx(() {
                    final q = _qualityLabel(controller.videoHeight.value);
                    if (q.isEmpty) return const SizedBox.shrink();
                    return Row(children: [
                      _OrbLabel(text: q),
                      const SizedBox(width: 6),
                    ]);
                  }),
                  _Orb(
                    child: IconButton(
                      icon: const Icon(Icons.lock_outline_rounded,
                          color: Colors.white, size: 18),
                      onPressed: () => controller.isLocked.value = true,
                      tooltip: 'Lock',
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (isDesktop) ...[
                    _Orb(
                      child: IconButton(
                        icon: const Icon(Icons.fullscreen_rounded,
                            color: Colors.white, size: 18),
                        onPressed: controller.toggleFullScreen,
                        tooltip: 'Fullscreen',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                            minWidth: 36, minHeight: 36),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  _Orb(
                    child: IconButton(
                      icon: const Icon(Icons.settings_outlined,
                          color: Colors.white, size: 18),
                      onPressed: () => _openSettings(context),
                      tooltip: 'Settings',
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  String _subtitle(PlayerController c) {
    final ep = c.currentEpisode.value.number == 'Offline'
        ? 'Offline'
        : 'Episode ${c.currentEpisode.value.number}';
    final title =
        (c.anilistData.title == '?' ? c.folderName : c.anilistData.title) ??
            '';
    return title.isNotEmpty ? '$title · $ep' : ep;
  }

  // ── CENTER ─── each control its own orb, arranged in a horizontal row

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
              scale: controller.showControls.value ? 1.0 : 0.88,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Orb(
                    size: 48,
                    opacity: controller.canGoBackward.value ? 1.0 : 0.4,
                    child: IconButton(
                      icon: const Icon(Icons.skip_previous_rounded,
                          color: Colors.white, size: 22),
                      onPressed: controller.canGoBackward.value
                          ? () => controller.navigator(false)
                          : null,
                      tooltip: 'Previous',
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 48, minHeight: 48),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _Orb(
                    size: 52,
                    child: IconButton(
                      icon: Icon(
                          isDesktop
                              ? Icons.replay_30_rounded
                              : Icons.replay_10_rounded,
                          color: Colors.white,
                          size: 24),
                      onPressed: () {
                        final p = controller.currentPosition.value;
                        final s = isDesktop
                            ? 30
                            : controller.playerSettings.seekDuration;
                        final n = p - Duration(seconds: s);
                        controller.seekTo(n.isNegative ? Duration.zero : n);
                      },
                      tooltip: isDesktop ? 'Replay 30s' : 'Replay',
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 52, minHeight: 52),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Play/pause — larger orb
                  Obx(() => _Orb(
                        size: 76,
                        isPrimary: true,
                        child: GestureDetector(
                          onTap: controller.togglePlayPause,
                          child: SizedBox(
                            width: 76,
                            height: 76,
                            child: Center(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 120),
                                child: controller.isBuffering.value
                                    ? const SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: ExpressiveLoadingIndicator())
                                    : Icon(
                                        controller.isPlaying.value
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                        key: ValueKey(
                                            controller.isPlaying.value),
                                        color: Colors.white,
                                        size: 38),
                              ),
                            ),
                          ),
                        ),
                      )),
                  const SizedBox(width: 12),
                  _Orb(
                    size: 52,
                    child: IconButton(
                      icon: Icon(
                          isDesktop
                              ? Icons.forward_30_rounded
                              : Icons.forward_10_rounded,
                          color: Colors.white,
                          size: 24),
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
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 52, minHeight: 52),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _Orb(
                    size: 48,
                    opacity: controller.canGoForward.value ? 1.0 : 0.4,
                    child: IconButton(
                      icon: const Icon(Icons.skip_next_rounded,
                          color: Colors.white, size: 22),
                      onPressed: controller.canGoForward.value
                          ? () => controller.navigator(true)
                          : null,
                      tooltip: 'Next',
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 48, minHeight: 48),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  // ── BOTTOM ─── progress as a floating pill, time + actions as separate orbs

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
                horizontal: isDesktop ? 20 : 12, vertical: 10),
            child: IgnorePointer(
              ignoring: true,
              child: _OrbPill(
                child: Opacity(
                  opacity: 0.4,
                  child: const ProgressSlider(style: SliderStyle.ios),
                ),
              ),
            ),
          ),
        );
      }

      return IgnorePointer(
        ignoring: !controller.showControls.value,
        child: AnimatedOpacity(
          opacity: controller.showControls.value ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 220),
          child: SafeArea(
            top: false,
            left: false,
            right: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isDesktop ? 20 : 12,
                0,
                isDesktop ? 20 : 12,
                isDesktop ? 16 : 10,
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Skip + right buttons row
        Row(
          children: [
            const Spacer(),
            // Skip orb
            GestureDetector(
              onTap: () =>
                  controller.megaSeek(controller.playerSettings.skipDuration),
              child: _OrbLabel(
                  text: '+${controller.playerSettings.skipDuration}s'),
            ),
            if (rightBtns.isNotEmpty) ...[
              const SizedBox(width: 8),
              ...rightBtns,
            ],
          ],
        ),
        const SizedBox(height: 8),
        // Slider as a floating pill
        _OrbPill(
          child: const ProgressSlider(style: SliderStyle.capsule),
        ),
        const SizedBox(height: 8),
        // Time + left buttons row
        Row(
          children: [
            // Time orb
            _OrbPill(
              child: Obx(() => Text(
                    '${controller.formattedCurrentPosition}  ·  ${controller.formattedEpisodeDuration}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  )),
            ),
            if (leftBtns.isNotEmpty) ...[
              const SizedBox(width: 8),
              ...leftBtns,
            ],
            const Spacer(),
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

/// Square/circle frosted orb
class _Orb extends StatelessWidget {
  final Widget child;
  final double size;
  final bool isPrimary;
  final double opacity;
  const _Orb({
    required this.child,
    this.size = 40,
    this.isPrimary = false,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Opacity(
      opacity: opacity,
      child: ClipOval(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isPrimary
                  ? colors.primary.withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.12),
              border: Border.all(
                color: isPrimary
                    ? colors.primary.withValues(alpha: 0.7)
                    : Colors.white.withValues(alpha: 0.22),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: isPrimary
                      ? colors.primary.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.2),
                  blurRadius: 16,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Wide pill / capsule for text or sliders
class _OrbPill extends StatelessWidget {
  final Widget child;
  const _OrbPill({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.20),
              width: 0.8,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Small text label orb
class _OrbLabel extends StatelessWidget {
  final String text;
  const _OrbLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 0.8,
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}

class _OrbUnlockButton extends StatefulWidget {
  final VoidCallback onUnlock;
  const _OrbUnlockButton({required this.onUnlock});

  @override
  State<_OrbUnlockButton> createState() => _OrbUnlockButtonState();
}

class _OrbUnlockButtonState extends State<_OrbUnlockButton> {
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
        child: _OrbPill(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_open_rounded,
                  color: Colors.white, size: 16),
              if (_confirm) ...[
                const SizedBox(width: 6),
                const Text('Unlock?',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
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
