import 'dart:io';
import 'dart:ui' as ui;

import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/screens/anime/watch/controller/player_utils.dart';
import 'package:anymex/screens/anime/watch/controls/themes/setup/player_control_theme.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/bottom_sheet.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/decoder_quick_button.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/progress_slider.dart';
import 'package:anymex/screens/settings/sub_settings/settings_player.dart';
import 'package:anymex/services/cast/widgets/cast_device_dialog.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class Ios26PlayerControlTheme extends PlayerControlTheme {
  Ios26PlayerControlTheme();

  @override
  String get id => 'ios26';

  @override
  String get name => 'iOS 26';

  @override
  Widget buildTopControls(BuildContext context, PlayerController controller) {
    final isDesktop = !_isMobilePlatform;

    return Obx(() {
      if (controller.isLocked.value) {
        if (!controller.showControls.value) return const SizedBox.shrink();
        return Align(
          alignment: Alignment.centerRight,
          child: _Ios26UnlockButton(
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
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 28 : 16,
                  vertical: isDesktop ? 16 : 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _Ios26GlassCapsule(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _Ios26CapsuleIconButton(
                            icon: CupertinoIcons.back,
                            tooltip: 'Back',
                            onPressed: () => Get.back(),
                          ),
                          const SizedBox(width: 4),
                          _Ios26CapsuleIconButton(
                            icon: CupertinoIcons.lock_fill,
                            tooltip: 'Lock Controls',
                            onPressed: () => controller.isLocked.value = true,
                          ),
                          const SizedBox(width: 4),
                          _Ios26CapsuleIconButton(
                            icon: CupertinoIcons.gear_alt_fill,
                            tooltip: 'Player Settings',
                            onPressed: () {
                              controller.showSheetWithPause(
                                () => showModalBottomSheet(
                                  context: Get.context!,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (sheetContext) => Container(
                                    height:
                                        MediaQuery.of(sheetContext).size.height,
                                    clipBehavior: Clip.antiAlias,
                                    decoration: const BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(28)),
                                    ),
                                    child: const SettingsPlayer(isModal: true),
                                  ),
                                ),
                              );
                            },
                          ),
                          if (Platform.isAndroid || Platform.isIOS) ...[
                            const SizedBox(width: 4),
                            _Ios26CapsuleIconButton(
                              icon: CupertinoIcons.square_on_square,
                              tooltip: 'Picture in Picture',
                              onPressed: () => controller.enterPip(),
                            ),
                          ],
                          const SizedBox(width: 4),
                          _Ios26CapsuleIconButton(
                            icon: CupertinoIcons.arrow_up_right_square,
                            tooltip: 'External Player',
                            onPressed: () => controller.launchExternalPlayer(),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DecoderQuickButton.ios26(isMobile: !isDesktop),
                        const SizedBox(width: 8),
                        _Ios26GlassCapsule(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _Ios26CapsuleIconButton(
                                icon: CupertinoIcons.device_phone_portrait,
                                tooltip: 'Toggle Orientation',
                                onPressed: () => controller.toggleOrientation(),
                              ),
                              const SizedBox(width: 4),
                              _Ios26CapsuleIconButton(
                                icon: Icons.fit_screen,
                                tooltip: 'Aspect Ratio',
                                onPressed: () => controller.toggleVideoFit(),
                              ),
                              if (!_isMobilePlatform) ...[
                                const SizedBox(width: 4),
                                _Ios26CapsuleIconButton(
                                  icon: CupertinoIcons.fullscreen,
                                  tooltip: 'Fullscreen',
                                  onPressed: controller.toggleFullScreen,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  @override
  Widget buildCenterControls(
      BuildContext context, PlayerController controller) {
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _Ios26GlassCircleButton(
                    icon: Icons.skip_previous_rounded,
                    tooltip: 'Previous Episode',
                    size: 52,
                    onPressed: controller.canGoBackward.value
                        ? () => controller.navigator(false)
                        : null,
                  ),
                  const SizedBox(width: 20),
                  Obx(() => _Ios26GlassMainPlayButton(
                        isPlaying: controller.isPlaying.value,
                        isBuffering: controller.isBuffering.value,
                        onTap: controller.togglePlayPause,
                      )),
                  const SizedBox(width: 20),
                  _Ios26GlassCircleButton(
                    icon: Icons.skip_next_rounded,
                    tooltip: 'Next Episode',
                    size: 52,
                    onPressed: controller.canGoForward.value
                        ? () => controller.navigator(true)
                        : null,
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
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 28 : 16,
              vertical: isDesktop ? 18 : 10,
            ),
            child: const _Ios26GlassCapsule(
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
      final horizontal = isDesktop ? 28.0 : 16.0;
      final vertical = isDesktop ? 18.0 : 10.0;

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
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontal,
                          vertical: vertical,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 4, bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _getSubtitleText(controller),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.7),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                _getTitleText(controller),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 19,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: -0.2,
                                                  shadows: [
                                                    Shadow(
                                                      color: Colors.black45,
                                                      blurRadius: 8,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Obx(() {
                                              final pos = PlayerUtils.formatDuration(
                                                  controller.currentPosition.value);
                                              final dur = PlayerUtils.formatDuration(
                                                  controller.episodeDuration.value);
                                              return Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withOpacity(0.35),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                      color: Colors.white.withOpacity(0.15)),
                                                ),
                                                child: Text(
                                                  '$pos / $dur',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    letterSpacing: 0.2,
                                                  ),
                                                ),
                                              );
                                            }),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Obx(() {
                                    final showSkip = controller
                                                .currentSkipInterval.value !=
                                            null ||
                                        controller.isAutoSkipCountdownActive;
                                    if (!showSkip) {
                                      return const SizedBox.shrink();
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.only(left: 12),
                                      child: _Ios26GlassSkipChip(
                                        icon:
                                            controller.isAutoSkipCountdownActive
                                                ? CupertinoIcons.xmark
                                                : CupertinoIcons.forward_fill,
                                        label: controller.skipButtonLabel,
                                        onTap: controller.isLocked.value
                                            ? null
                                            : controller.performSkipAction,
                                        countdownProgress: controller
                                                .isAutoSkipCountdownActive
                                            ? controller
                                                    .autoSkipCountdownRemaining
                                                    .value /
                                                PlayerController
                                                    .autoSkipCountdownSeconds
                                            : null,
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                            const ProgressSlider(style: SliderStyle.ios),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _Ios26GlassPillButton(
                                      label: 'Episodes',
                                      onPressed: () {
                                        controller.isTracksPaneOpened.value = false;
                                        controller.isSpeedPaneOpened.value = false;
                                        controller.isSyncSubsPaneOpened.value = false;
                                        controller.isSourcePaneOpened.value = false;
                                        controller.isEpisodePaneOpened.value =
                                            !controller.isEpisodePaneOpened.value;
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    _Ios26GlassPillButton(
                                      label: 'Tracks',
                                      onPressed: () {
                                        controller.isEpisodePaneOpened.value = false;
                                        controller.isSpeedPaneOpened.value = false;
                                        controller.isSyncSubsPaneOpened.value = false;
                                        controller.isSourcePaneOpened.value = false;
                                        controller.isTracksPaneOpened.value =
                                            !controller.isTracksPaneOpened.value;
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    Obx(() => _Ios26GlassPillButton(
                                          label: controller.skipButtonLabel,
                                          onPressed: controller.performSkipAction,
                                        )),
                                    if (!controller.isOffline.value) ...[
                                      const SizedBox(width: 8),
                                      _Ios26GlassPillButton(
                                        label: 'Servers',
                                        onPressed: () {
                                          PlayerBottomSheets.showVideoServers(
                                              context, controller);
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      _Ios26GlassPillButton(
                                        label: 'Quality',
                                        onPressed: () {
                                          PlayerBottomSheets.showVideoQuality(
                                              context, controller);
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                                _Ios26GlassCapsule(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 5,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _Ios26CapsuleIconButton(
                                        icon: CupertinoIcons.timer,
                                        tooltip: 'Sync Subtitles',
                                        onPressed: () {
                                          controller.isEpisodePaneOpened.value = false;
                                          controller.isTracksPaneOpened.value = false;
                                          controller.isSpeedPaneOpened.value = false;
                                          controller.isSourcePaneOpened.value = false;
                                          controller.isSyncSubsPaneOpened.value =
                                              !controller.isSyncSubsPaneOpened.value;
                                        },
                                      ),
                                      const SizedBox(width: 4),
                                      _Ios26CapsuleIconButton(
                                        icon: CupertinoIcons.speaker_2_fill,
                                        tooltip: 'Audio Tracks',
                                        onPressed: () =>
                                            PlayerBottomSheets.showAudioTracks(
                                                context, controller),
                                      ),
                                      const SizedBox(width: 4),
                                      _Ios26CapsuleIconButton(
                                        icon: CupertinoIcons.speedometer,
                                        tooltip: 'Playback Speed',
                                        onPressed: () {
                                          controller.isEpisodePaneOpened.value = false;
                                          controller.isTracksPaneOpened.value = false;
                                          controller.isSpeedPaneOpened.value = false;
                                          controller.isSourcePaneOpened.value = false;
                                          controller.isSpeedPaneOpened.value =
                                              !controller.isSpeedPaneOpened.value;
                                        },
                                      ),
                                      const SizedBox(width: 4),
                                      _Ios26CapsuleIconButton(
                                        icon: CupertinoIcons.tv,
                                        tooltip: 'Cast to Device',
                                        onPressed: () =>
                                            CastDeviceDialog.show(context, controller),
                                      ),
                                      const SizedBox(width: 4),
                                      _Ios26CapsuleIconButton(
                                        icon:
                                            CupertinoIcons.slider_horizontal_3,
                                        tooltip: 'Shaders & Colors',
                                        onPressed: () => controller
                                            .openColorProfileBottomSheet(
                                                context),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
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
                          child: Obx(() => _Ios26GlassSkipChip(
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

  String _getSubtitleText(PlayerController controller) {
    final showTitle = controller.anilistData.title == '?'
        ? controller.folderName
        : controller.anilistData.title;
    if (showTitle != null && showTitle.isNotEmpty) {
      return showTitle;
    }
    final epNum = controller.currentEpisode.value.number;
    return epNum == 'Offline' ? 'Offline' : 'Episode $epNum';
  }

  String _getTitleText(PlayerController controller) {
    final epTitle = controller.currentEpisode.value.title;
    if (epTitle != null && epTitle.isNotEmpty) {
      return epTitle;
    }
    final itemName = controller.itemName;
    if (itemName != null && itemName.isNotEmpty) {
      return itemName;
    }
    return 'Episode ${controller.currentEpisode.value.number}';
  }
}

class _Ios26GlassCapsule extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;

  const _Ios26GlassCapsule({
    required this.child,
    this.radius = 30,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: const Color(0x66181818),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withOpacity(0.18),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 20,
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

class _Ios26CapsuleIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _Ios26CapsuleIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    const double size = 38;
    return ClipRRect(
      borderRadius: BorderRadius.circular(19),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(19),
          child: Tooltip(
            message: tooltip,
            child: Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 20,
                color: Colors.white.withOpacity(0.95),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Ios26GlassCircleButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;

  const _Ios26GlassCircleButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 52,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          customBorder: const CircleBorder(),
          child: ClipOval(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: enabled
                      ? const Color(0x66181818)
                      : const Color(0x22181818),
                  border: Border.all(
                    color: Colors.white.withOpacity(enabled ? 0.2 : 0.08),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: size * 0.5,
                  color: Colors.white.withOpacity(enabled ? 0.95 : 0.35),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Ios26GlassMainPlayButton extends StatelessWidget {
  final bool isPlaying;
  final bool isBuffering;
  final VoidCallback onTap;

  const _Ios26GlassMainPlayButton({
    required this.isPlaying,
    required this.isBuffering,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const double size = 74;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: ClipOval(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0x77181818),
                border: Border.all(
                  color: Colors.white.withOpacity(0.25),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 22,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: isBuffering
                    ? const SizedBox(
                        width: 30,
                        height: 30,
                        child: ExpressiveLoadingIndicator(
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        isPlaying
                            ? CupertinoIcons.pause_fill
                            : Icons.play_arrow_rounded,
                        size: 38,
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

class _Ios26GlassPillButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _Ios26GlassPillButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0x66181818),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.18),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Ios26GlassSkipChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final double? countdownProgress;

  const _Ios26GlassSkipChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.countdownProgress,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0x66181818),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
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
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
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

class _Ios26UnlockButton extends StatefulWidget {
  final VoidCallback onUnlock;

  const _Ios26UnlockButton({required this.onUnlock});

  @override
  State<_Ios26UnlockButton> createState() => _Ios26UnlockButtonState();
}

class _Ios26UnlockButtonState extends State<_Ios26UnlockButton>
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
            filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0x66181818),
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
                  const Text(
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
