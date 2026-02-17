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

// ─── Prime Video accent color ────────────────────────────────────────────────
const _kPrimeBlue = Color(0xFF00A8E1);
const _kPrimeDark = Color(0xFF0F171E);
const _kPrimeBar = Color(0xE6111C25); // ~90% opaque dark navy

class PrimeVideoPlayerControlTheme extends PlayerControlTheme {
  PrimeVideoPlayerControlTheme();

  @override
  String get id => 'prime_video';

  @override
  String get name => 'Prime Video';

  // ── helpers ────────────────────────────────────────────────────────────────

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
          child: _PrimeUnlockButton(
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
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: controller.showControls.value ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 220),
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_kPrimeDark, Colors.transparent],
                  stops: [0.0, 1.0],
                ),
              ),
              child: SafeArea(
                bottom: false,
                left: false,
                right: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 28 : 16,
                    vertical: isDesktop ? 18 : 10,
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
        // Back button
        _PrimeIconButton(
          icon: Icons.arrow_back_ios_rounded,
          onPressed: () => Get.back(),
          tooltip: 'Back',
        ),
        const SizedBox(width: 14),
        // Title / episode info
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                    ),
                  )),
              const SizedBox(height: 4),
              Obx(() => Row(
                    children: [
                      _PrimePill(
                        text: controller.currentEpisode.value.number ==
                                'Offline'
                            ? 'Offline'
                            : 'Ep ${controller.currentEpisode.value.number}',
                        color: _kPrimeBlue,
                      ),
                      const SizedBox(width: 6),
                      if (((controller.anilistData.title == '?'
                                  ? controller.folderName
                                  : controller.anilistData.title) ??
                              '')
                          .isNotEmpty)
                        Flexible(
                          child: _PrimePill(
                            text: (controller.anilistData.title == '?'
                                    ? controller.folderName
                                    : controller.anilistData.title) ??
                                '',
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                      const SizedBox(width: 6),
                      Obx(() {
                        final q = _qualityLabel(controller.videoHeight.value);
                        if (q.isEmpty) return const SizedBox.shrink();
                        return _PrimePill(
                            text: q,
                            color: _kPrimeBlue.withValues(alpha: 0.25));
                      }),
                    ],
                  )),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Right action buttons
        _PrimeIconButton(
          icon: Icons.lock_outline_rounded,
          onPressed: () => controller.isLocked.value = true,
          tooltip: 'Lock Controls',
        ),
        const SizedBox(width: 6),
        if (isDesktop) ...[
          _PrimeIconButton(
            icon: Icons.fullscreen_rounded,
            onPressed: controller.toggleFullScreen,
            tooltip: 'Fullscreen',
          ),
          const SizedBox(width: 6),
        ],
        _PrimeIconButton(
          icon: Icons.settings_outlined,
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
            duration: const Duration(milliseconds: 200),
            child: AnimatedScale(
              scale: controller.showControls.value ? 1.0 : 0.90,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutBack,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PrimeCenterButton(
                    icon: Icons.skip_previous_rounded,
                    size: 32,
                    enabled: controller.canGoBackward.value,
                    onPressed: () => controller.navigator(false),
                    tooltip: 'Previous Episode',
                  ),
                  const SizedBox(width: 20),
                  if (isDesktop)
                    _PrimeCenterButton(
                      icon: Icons.replay_30_rounded,
                      size: 34,
                      onPressed: () {
                        final p = controller.currentPosition.value;
                        final n = p - const Duration(seconds: 30);
                        controller
                            .seekTo(n.isNegative ? Duration.zero : n);
                      },
                      tooltip: 'Replay 30s',
                    )
                  else
                    _PrimeCenterButton(
                      icon: Icons.replay_10_rounded,
                      size: 34,
                      onPressed: () {
                        final p = controller.currentPosition.value;
                        final seekBy = Duration(
                            seconds:
                                controller.playerSettings.seekDuration);
                        final n = p - seekBy;
                        controller
                            .seekTo(n.isNegative ? Duration.zero : n);
                      },
                      tooltip: 'Replay',
                    ),
                  const SizedBox(width: 18),
                  // Main play/pause
                  Obx(() => _PrimePlayButton(
                        isPlaying: controller.isPlaying.value,
                        isBuffering: controller.isBuffering.value,
                        onTap: controller.togglePlayPause,
                      )),
                  const SizedBox(width: 18),
                  if (isDesktop)
                    _PrimeCenterButton(
                      icon: Icons.forward_30_rounded,
                      size: 34,
                      onPressed: () {
                        final p = controller.currentPosition.value;
                        final d = controller.episodeDuration.value;
                        final n = p + const Duration(seconds: 30);
                        controller.seekTo(n > d ? d : n);
                      },
                      tooltip: 'Forward 30s',
                    )
                  else
                    _PrimeCenterButton(
                      icon: Icons.forward_10_rounded,
                      size: 34,
                      onPressed: () {
                        final p = controller.currentPosition.value;
                        final d = controller.episodeDuration.value;
                        final seekBy = Duration(
                            seconds:
                                controller.playerSettings.seekDuration);
                        final n = p + seekBy;
                        controller.seekTo(n > d ? d : n);
                      },
                      tooltip: 'Forward',
                    ),
                  const SizedBox(width: 20),
                  _PrimeCenterButton(
                    icon: Icons.skip_next_rounded,
                    size: 32,
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
              horizontal: isDesktop ? 28 : 16,
              vertical: isDesktop ? 18 : 10,
            ),
            child: IgnorePointer(
              ignoring: true,
              child: Opacity(
                opacity: 0.5,
                child: const ProgressSlider(),
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
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: controller.showControls.value ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 220),
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, _kPrimeDark],
                  stops: [0.0, 1.0],
                ),
              ),
              child: SafeArea(
                top: false,
                left: false,
                right: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isDesktop ? 28 : 16,
                    0,
                    isDesktop ? 28 : 16,
                    isDesktop ? 20 : 10,
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
    final Map<String, dynamic> decodedConfig = json.decode(jsonString);

    final List<String> leftButtonIds =
        List<String>.from(decodedConfig['leftButtonIds'] ?? []);
    final List<String> rightButtonIds =
        List<String>.from(decodedConfig['rightButtonIds'] ?? []);
    final Map<String, dynamic> buttonConfigs =
        Map<String, dynamic>.from(decodedConfig['buttonConfigs'] ?? {});

    bool isVisible(String id) =>
        (buttonConfigs[id]?['visible'] as bool?) ?? true;

    final Map<String, Widget> buttonWidgets = _buildButtonWidgets(context, controller);

    List<Widget> buildList(List<String> ids) {
      final compact = <Widget>[];
      for (final id in ids) {
        if (!isVisible(id)) continue;
        if (id == 'server' && controller.isOffline.value) continue;
        if (id == 'quality' && controller.isOffline.value) continue;
        if (id == 'orientation' &&
            !(Platform.isAndroid || Platform.isIOS)) continue;
        final w = buttonWidgets[id];
        if (w != null) compact.add(w);
      }
      if (compact.isEmpty) return [];
      return [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: _kPrimeBar,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 0.5,
            ),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: compact),
        ),
      ];
    }

    final leftButtons = buildList(leftButtonIds);
    final rightButtons = buildList(rightButtonIds);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Skip intro chip
        Align(
          alignment: Alignment.centerRight,
          child: _PrimeSkipChip(controller: controller),
        ),
        const SizedBox(height: 6),
        // Slider
        const ProgressSlider(),
        const SizedBox(height: 4),
        // Time row + buttons
        Row(
          children: [
            Obx(() => Text(
                  controller.formattedCurrentPosition,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                )),
            const SizedBox(width: 6),
            const Text('/',
                style: TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                    fontWeight: FontWeight.w400)),
            const SizedBox(width: 6),
            Obx(() => Text(
                  controller.formattedEpisodeDuration,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
                )),
            if (leftButtons.isNotEmpty) ...[
              const SizedBox(width: 12),
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

class _PrimePill extends StatelessWidget {
  final String text;
  final Color color;
  const _PrimePill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _PrimeIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  const _PrimeIconButton(
      {required this.icon, required this.onPressed, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
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

class _PrimeCenterButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final bool enabled;
  final VoidCallback? onPressed;
  final String tooltip;
  const _PrimeCenterButton({
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

class _PrimePlayButton extends StatelessWidget {
  final bool isPlaying;
  final bool isBuffering;
  final VoidCallback onTap;
  const _PrimePlayButton(
      {required this.isPlaying,
      required this.isBuffering,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isPlaying ? 'Pause' : 'Play',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _kPrimeBlue,
            boxShadow: [
              BoxShadow(
                color: _kPrimeBlue.withValues(alpha: 0.45),
                blurRadius: 24,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 120),
              child: isBuffering
                  ? const SizedBox(
                      width: 26,
                      height: 26,
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
                      size: 34,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimeSkipChip extends StatelessWidget {
  final PlayerController controller;
  const _PrimeSkipChip({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () =>
            controller.megaSeek(controller.playerSettings.skipDuration),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: _kPrimeBar,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _kPrimeBlue.withValues(alpha: 0.6),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.forward_rounded,
                  color: _kPrimeBlue, size: 15),
              const SizedBox(width: 5),
              Text(
                '+${controller.playerSettings.skipDuration}s',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimeUnlockButton extends StatefulWidget {
  final VoidCallback onUnlock;
  const _PrimeUnlockButton({required this.onUnlock});

  @override
  State<_PrimeUnlockButton> createState() => _PrimeUnlockButtonState();
}

class _PrimeUnlockButtonState extends State<_PrimeUnlockButton> {
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
            color: _kPrimeBar,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _kPrimeBlue.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_open_rounded,
                  color: _kPrimeBlue, size: 18),
              if (_confirm) ...[
                const SizedBox(width: 8),
                const Text(
                  'Unlock?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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
