import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/screens/anime/watch/controls/themes/setup/player_control_theme.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/bottom_sheet.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/control_button.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/decoder_quick_button.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/progress_slider.dart';
import 'package:anymex/screens/settings/sub_settings/settings_player.dart';
import 'package:anymex/services/cast/widgets/cast_device_dialog.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';

class IosLegacyPlayerControlTheme extends PlayerControlTheme {
  IosLegacyPlayerControlTheme();

  @override
  String get id => 'ios_legacy';

  @override
  String get name => 'iOS Legacy';

  @override
  Widget buildTopControls(BuildContext context, PlayerController controller) {
    final isDesktop = !_isMobilePlatform;

    return Obx(() {
      if (controller.isLocked.value) {
        if (!controller.showControls.value) return const SizedBox.shrink();
        return Align(
          alignment: Alignment.centerRight,
          child: _IosLegacyUnlockButton(
            onUnlock: () => controller.isLocked.value = false,
          ),
        );
      }

      return IgnorePointer(
        ignoring: !controller.showControls.value,
        child: AnimatedSlide(
          offset:
              controller.showControls.value ? Offset.zero : const Offset(0, -1),
          duration: controller.overlayAnimationDuration(360),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: controller.showControls.value ? 1.0 : 0.0,
            duration: controller.overlayAnimationDuration(280),
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

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 16 : 12,
        vertical: isDesktop ? 12 : 10,
      ),
      child: Row(
        children: [
          _IosLegacyGlassIconButton(
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
                AnymeXText(
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
                    _IosLegacyGlassTag(
                      text: controller.currentEpisode.value.number == 'Offline'
                          ? 'Offline'
                          : 'Episode ${controller.currentEpisode.value.number}',
                    ),
                    if (((controller.anilistData.title == '?'
                                ? controller.folderName
                                : controller.anilistData.title) ??
                            '')
                        .isNotEmpty)
                      _IosLegacyGlassTag(
                        text: (controller.anilistData.title == '?'
                                ? controller.folderName
                                : controller.anilistData.title) ??
                            '',
                      ),
                    Obx(() {
                      final qualityText =
                          _qualityLabel(controller.videoHeight.value);
                      if (qualityText.isEmpty) return const SizedBox.shrink();
                      return _IosLegacyGlassTag(text: qualityText);
                    }),
                    DecoderQuickButton.glass(isMobile: !isDesktop),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _IosLegacyGlassIconButton(
            icon: CupertinoIcons.lock_fill,
            tooltip: 'Lock Controls',
            onPressed: () => controller.isLocked.value = true,
          ),
          const SizedBox(width: 8),
          _IosLegacyGlassIconButton(
            icon: CupertinoIcons.fullscreen,
            tooltip: 'Fullscreen',
            onPressed: controller.toggleFullScreen,
          ),
          const SizedBox(width: 8),
          _IosLegacyGlassIconButton(
            icon: CupertinoIcons.settings_solid,
            tooltip: 'Settings',
            onPressed: () {
              controller.showSheetWithPause(
                () => showModalBottomSheet(
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
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget buildCenterControls(
      BuildContext context, PlayerController controller) {
    final isDesktop = !_isMobilePlatform;

    return Obx(() {
      if (controller.isLocked.value) return const SizedBox.shrink();

      return IgnorePointer(
        ignoring: !controller.showControls.value,
        child: Align(
          alignment: Alignment.center,
          child: AnimatedOpacity(
            opacity: controller.showControls.value ? 1 : 0,
            duration: controller.overlayAnimationDuration(220),
            child: AnimatedScale(
              scale: controller.showControls.value ? 1 : 0.88,
              duration: controller.overlayAnimationDuration(320),
              curve: Curves.easeOutBack,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _IosLegacyGlassIconButton(
                    icon: CupertinoIcons.backward_end_fill,
                    tooltip: 'Previous Episode',
                    enabled: controller.canGoBackward.value,
                    onPressed: () => controller.navigator(false),
                  ),
                  const SizedBox(width: 12),
                  _IosLegacyGlassIconButton(
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
                  Obx(() => _IosLegacyGlassPlayButton(
                        isPlaying: controller.isPlaying.value,
                        isBuffering: controller.isBuffering.value,
                        onTap: controller.togglePlayPause,
                      )),
                  const SizedBox(width: 14),
                  _IosLegacyGlassIconButton(
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
                  _IosLegacyGlassIconButton(
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
  Widget buildBottomControls(
      BuildContext context, PlayerController controller) {
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
            child: const _IosLegacyGlassPanel(
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

      final showControls = controller.showControls.value;
      final inSkipSegment = controller.currentSkipInterval.value != null;
      final bottomBarVisible = showControls || inSkipSegment;
      final horizontal = isDesktop ? 28.0 : 14.0;
      final vertical = isDesktop ? 18.0 : 8.0;

      return GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        child: IgnorePointer(
          ignoring: !bottomBarVisible,
          child: AnimatedSlide(
            offset: bottomBarVisible ? Offset.zero : const Offset(0, 1),
            duration: controller.overlayAnimationDuration(360),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              opacity: bottomBarVisible ? 1 : 0,
              duration: controller.overlayAnimationDuration(240),
              child: showControls
                  ? SafeArea(
                      top: false,
                      left: false,
                      right: false,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontal,
                          vertical: vertical,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Align(
                              alignment: Alignment.centerRight,
                              child: Obx(() => _IosLegacyGlassActionChip(
                                    icon: controller.isAutoSkipCountdownActive
                                        ? CupertinoIcons.xmark
                                        : CupertinoIcons.forward_fill,
                                    label: controller.skipButtonLabel,
                                    onTap: controller.isLocked.value
                                        ? null
                                        : controller.performSkipAction,
                                    countdownProgress:
                                        controller.isAutoSkipCountdownActive
                                            ? controller
                                                    .autoSkipCountdownRemaining
                                                    .value /
                                                PlayerController
                                                    .autoSkipCountdownSeconds
                                            : null,
                                  )),
                            ),
                            const SizedBox(height: 8),
                            _buildBottomSection(context, controller),
                          ],
                        ),
                      ),
                    )
                  : Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          right: horizontal,
                          bottom: vertical,
                          child: Obx(() => _IosLegacyGlassActionChip(
                                icon: controller.isAutoSkipCountdownActive
                                    ? CupertinoIcons.xmark
                                    : CupertinoIcons.forward_fill,
                                label: controller.skipButtonLabel,
                                onTap: controller.isLocked.value
                                    ? null
                                    : controller.performSkipAction,
                                countdownProgress:
                                    controller.isAutoSkipCountdownActive
                                        ? controller.autoSkipCountdownRemaining
                                                .value /
                                            PlayerController
                                                .autoSkipCountdownSeconds
                                        : null,
                              )),
                        ),
                      ],
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
        icon: Icons.playlist_play_rounded,
        onPressed: () {
          controller.isEpisodePaneOpened.value =
              !controller.isEpisodePaneOpened.value;
        },
        tooltip: 'Playlist',
        compact: true,
      ),
      'shaders': ControlButton(
        icon: Icons.tune_rounded,
        onPressed: () => controller.openColorProfileBottomSheet(context),
        tooltip: 'Shaders & Color Profiles',
        compact: true,
      ),
      'source': ControlButton(
        icon: Icons.high_quality_rounded,
        onPressed: () => controller.isSourcePaneOpened.value =
            !controller.isSourcePaneOpened.value,
        tooltip: 'Quality',
        compact: true,
      ),
      'tracks': ControlButton(
        icon: Icons.subtitles_rounded,
        onPressed: () => controller.isTracksPaneOpened.value =
            !controller.isTracksPaneOpened.value,
        tooltip: 'Subtitles',
        compact: true,
      ),
      'sync_subs': ControlButton(
        icon: Icons.sync_rounded,
        onPressed: () => controller.isSyncSubsPaneOpened.value =
            !controller.isSyncSubsPaneOpened.value,
        tooltip: 'Sync Subs',
        compact: true,
      ),
      'server': ControlButton(
        icon: Icons.cloud_rounded,
        onPressed: () =>
            PlayerBottomSheets.showVideoServers(context, controller),
        tooltip: 'Server',
        compact: true,
      ),
      'quality': ControlButton(
        icon: Icons.high_quality_rounded,
        onPressed: () =>
            PlayerBottomSheets.showVideoQuality(context, controller),
        tooltip: 'Quality',
        compact: true,
      ),
      'audio': ControlButton(
        icon: Icons.volume_up_rounded,
        onPressed: () => controller.isAudioPaneOpened.value =
            !controller.isAudioPaneOpened.value,
        tooltip: 'Audio',
        compact: true,
      ),
      'orientation': ControlButton(
        icon: Icons.screen_rotation_rounded,
        onPressed: controller.toggleOrientation,
        tooltip: 'Orientation',
        compact: true,
      ),
      'cast': ControlButton(
        icon: Icons.cast_rounded,
        onPressed: () => CastDeviceDialog.show(context, controller),
        tooltip: 'Cast to Device',
        compact: true,
      ),
    };

    final leftWidgets = leftButtonIds
        .where(isVisible)
        .map((id) => buttonWidgets[id])
        .whereType<Widget>()
        .toList();

    final rightWidgets = rightButtonIds
        .where(isVisible)
        .map((id) => buttonWidgets[id])
        .whereType<Widget>()
        .toList();

    final isDesktop = !_isMobilePlatform;

    return _IosLegacyGlassPanel(
      radius: 28,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 18 : 14,
        vertical: isDesktop ? 14 : 10,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ProgressSlider(style: SliderStyle.ios),
          const SizedBox(height: 8),
          Row(
            children: [
              if (leftWidgets.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: leftWidgets,
                ),
              ],
              const Spacer(),
              if (rightWidgets.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: rightWidgets,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _qualityLabel(int? height) {
    if (height == null || height <= 0) return '';
    return '${height}p';
  }
}

class _IosLegacyGlassPanel extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;

  const _IosLegacyGlassPanel({
    required this.child,
    this.radius = 22,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: const Color(0x66101216),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withOpacity(0.16),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.24),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _IosLegacyGlassIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool enabled;

  const _IosLegacyGlassIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    const double size = 42;
    final effectiveEnabled = enabled && onPressed != null;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: effectiveEnabled ? onPressed : null,
          customBorder: const CircleBorder(),
          child: ClipOval(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: effectiveEnabled
                      ? const Color(0x551C2026)
                      : const Color(0x221C2026),
                  border: Border.all(
                    color: Colors.white.withOpacity(effectiveEnabled ? 0.18 : 0.08),
                    width: 1.0,
                  ),
                ),
                child: Icon(
                  icon,
                  size: size * 0.48,
                  color: Colors.white.withOpacity(effectiveEnabled ? 0.95 : 0.35),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IosLegacyGlassPlayButton extends StatelessWidget {
  final bool isPlaying;
  final bool isBuffering;
  final VoidCallback onTap;

  const _IosLegacyGlassPlayButton({
    required this.isPlaying,
    required this.isBuffering,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const double size = 68;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: ClipOval(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0x66181C22),
                border: Border.all(
                  color: Colors.white.withOpacity(0.24),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: isBuffering
                    ? const SizedBox(
                        width: 28,
                        height: 28,
                        child: ExpressiveLoadingIndicator(
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        isPlaying
                            ? CupertinoIcons.pause_fill
                            : CupertinoIcons.play_fill,
                        size: 34,
                        color: Colors.white,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IosLegacyGlassTag extends StatelessWidget {
  final String text;

  const _IosLegacyGlassTag({required this.text});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0x441A1E24),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.14),
              width: 0.9,
            ),
          ),
          child: AnymeXText(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _IosLegacyGlassActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final double? countdownProgress;

  const _IosLegacyGlassActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.countdownProgress,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0x551A1E24),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.18),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (countdownProgress != null) ...[
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        value: countdownProgress,
                        strokeWidth: 2,
                        color: Colors.white,
                        backgroundColor: Colors.white24,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ] else ...[
                    Icon(icon, size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                  ],
                  AnymeXText(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IosLegacyUnlockButton extends StatefulWidget {
  final VoidCallback onUnlock;

  const _IosLegacyUnlockButton({required this.onUnlock});

  @override
  State<_IosLegacyUnlockButton> createState() => _IosLegacyUnlockButtonState();
}

class _IosLegacyUnlockButtonState extends State<_IosLegacyUnlockButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        HapticFeedback.mediumImpact();
        widget.onUnlock();
        _controller.reset();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = !_isMobilePlatform;

    return Padding(
      padding: EdgeInsets.only(right: isDesktop ? 32 : 16),
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          if (_controller.status != AnimationStatus.completed) {
            _controller.reverse();
          }
        },
        onTapCancel: () => _controller.reverse(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0x66181C22),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: _controller.value,
                            strokeWidth: 2.5,
                            color: Colors.white,
                            backgroundColor: Colors.white24,
                          ),
                          const Icon(
                            CupertinoIcons.lock_fill,
                            size: 16,
                            color: Colors.white,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  const AnymeXText(
                    'Hold to Unlock',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

bool get _isMobilePlatform => Platform.isAndroid || Platform.isIOS;
