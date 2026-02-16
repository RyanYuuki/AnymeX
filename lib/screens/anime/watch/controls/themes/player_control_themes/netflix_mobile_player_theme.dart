// netflix_playerNFColorsontrol_theme_mobile.dart

import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/screens/anime/watch/controls/themes/player_control_themes/netflix_shared.dart';
import 'package:anymex/screens/anime/watch/controls/themes/setup/player_control_theme.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/bottom_sheet.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/progress_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class NetflixMobilePlayerControlTheme extends PlayerControlTheme {
  @override
  String get id => 'netflix_mobile';

  @override
  String get name => 'Netflix (Mobile)';

  @override
  Widget buildTopControls(BuildContext context, PlayerController controller) {
    return Obx(() {
      if (controller.isLocked.value) {
        if (!controller.showControls.value) return const SizedBox.shrink();
        return Align(
          alignment: Alignment.topRight,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 16, right: 16),
              child: NFUnlockButton(
                onUnlock: () => controller.isLocked.value = false,
              ),
            ),
          ),
        );
      }

      return IgnorePointer(
        ignoring: !controller.showControls.value,
        child: AnimatedOpacity(
          opacity: controller.showControls.value ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: VerticalScrim(
            fromTop: true,
            height: 120,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 16, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NFRawButton(
                      onTap: () => Get.back(),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: NFColors.white, size: 28),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: Obx(() => Text(
                              buildNFTitle(controller),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: NFColors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(color: Colors.black87, blurRadius: 4)
                                ],
                              ),
                            )),
                      ),
                    ),
                    const SizedBox(width: 4),
                    NFRawButton(
                      onTap: () => showNFMoreSheet(context, controller),
                      child: const Icon(Icons.more_vert_rounded,
                          color: NFColors.white, size: 28),
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
        child: AnimatedOpacity(
          opacity: controller.showControls.value ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                NFSeekButton(
                  icon: Icons.replay_10_rounded,
                  onTap: () {
                    final np = controller.currentPosition.value -
                        Duration(
                            seconds: controller.playerSettings.seekDuration);
                    controller.seekTo(np.isNegative ? Duration.zero : np);
                  },
                ),
                const SizedBox(width: 64),
                Obx(() => NFCenterPlayPause(
                      isPlaying: controller.isPlaying.value,
                      isBuffering: controller.isBuffering.value,
                      onTap: controller.togglePlayPause,
                    )),
                const SizedBox(width: 64),
                NFSeekButton(
                  icon: Icons.forward_10_rounded,
                  onTap: () {
                    final pos = controller.currentPosition.value;
                    final dur = controller.episodeDuration.value;
                    final np = pos +
                        Duration(
                            seconds: controller.playerSettings.seekDuration);
                    controller.seekTo(np > dur ? dur : np);
                  },
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  @override
  Widget buildBottomControls(
      BuildContext context, PlayerController controller) {
    return Obx(() {
      if (controller.isLocked.value) {
        if (!controller.showControls.value) return const SizedBox.shrink();
        return const VerticalScrim(
          fromTop: false,
          height: 100,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.3,
                  child: ProgressSlider(style: SliderStyle.ios),
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
          duration: const Duration(milliseconds: 200),
          child: VerticalScrim(
            fromTop: false,
            height: 180,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              Obx(() => Text(
                                    controller.formattedCurrentPosition,
                                    style: const TextStyle(
                                      color: NFColors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      shadows: [
                                        Shadow(
                                            color: Colors.black87,
                                            blurRadius: 2)
                                      ],
                                    ),
                                  )),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: ProgressSlider(style: SliderStyle.ios),
                              ),
                              const SizedBox(width: 12),
                              Obx(() {
                                final remaining =
                                    controller.episodeDuration.value -
                                        controller.currentPosition.value;
                                String twoDigits(int n) =>
                                    n.toString().padLeft(2, "0");
                                final mm = twoDigits(
                                    remaining.inMinutes.remainder(60));
                                final ss = twoDigits(
                                    remaining.inSeconds.remainder(60));
                                final formatted = remaining.inHours > 0
                                    ? "${twoDigits(remaining.inHours)}:$mm:$ss"
                                    : "$mm:$ss";
                                return Text(
                                  remaining.inSeconds > 0
                                      ? "-$formatted"
                                      : "00:00",
                                  style: const TextStyle(
                                    color: NFColors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    shadows: [
                                      Shadow(
                                          color: Colors.black87, blurRadius: 2)
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              NFLabeledButton(
                                icon: Symbols.playlist_play_rounded,
                                label: 'Episodes',
                                onTap: () =>
                                    controller.isEpisodePaneOpened.value =
                                        !controller.isEpisodePaneOpened.value,
                              ),
                              NFLabeledButton(
                                icon: Symbols.subtitles_rounded,
                                label: 'Audio & Subtitles',
                                onTap: () => controller.isOffline.value
                                    ? PlayerBottomSheets.showOfflineSubs(
                                        context, controller)
                                    : PlayerBottomSheets.showSubtitleTracks(
                                        context, controller),
                              ),
                              Obx(() => NFLabeledButton(
                                    icon: Icons.skip_next_rounded,
                                    label: 'Next Ep.',
                                    enabled: controller.canGoForward.value,
                                    onTap: () => controller.navigator(true),
                                  )),
                            ],
                          ),
                        ),
                      ],
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
}
