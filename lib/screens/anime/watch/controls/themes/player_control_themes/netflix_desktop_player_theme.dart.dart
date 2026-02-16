// netflix_player_control_theme_desktop.dart

import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/screens/anime/watch/controls/themes/player_control_themes/netflix_shared.dart';
import 'package:anymex/screens/anime/watch/controls/themes/setup/player_control_theme.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/bottom_sheet.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/progress_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class NetflixDesktopPlayerControlTheme extends PlayerControlTheme {
  @override
  String get id => 'netflix_desktop';

  @override
  String get name => 'Netflix (Desktop)';

  @override
  Widget buildTopControls(BuildContext context, PlayerController controller) {
    return Obx(() {
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
    // Desktop uses the bottom bar for play/pause — no center controls needed
    return const SizedBox.shrink();
  }

  @override
  Widget buildBottomControls(
      BuildContext context, PlayerController controller) {
    return Obx(() {
      return IgnorePointer(
        ignoring: !controller.showControls.value,
        child: AnimatedOpacity(
          opacity: controller.showControls.value ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: VerticalScrim(
            fromTop: false,
            height: 140,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: ProgressSlider(style: SliderStyle.ios),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Row(
                      children: [
                        Obx(() => NFDesktopButton(
                              icon: controller.isPlaying.value
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 38,
                              onTap: controller.togglePlayPause,
                            )),
                        const SizedBox(width: 16),
                        NFDesktopButton(
                          icon: Icons.replay_10_rounded,
                          size: 32,
                          onTap: () {
                            final np = controller.currentPosition.value -
                                const Duration(seconds: 10);
                            controller
                                .seekTo(np.isNegative ? Duration.zero : np);
                          },
                        ),
                        const SizedBox(width: 12),
                        NFDesktopButton(
                          icon: Icons.forward_10_rounded,
                          size: 32,
                          onTap: () {
                            final pos = controller.currentPosition.value;
                            final dur = controller.episodeDuration.value;
                            final np = pos + const Duration(seconds: 10);
                            controller.seekTo(np > dur ? dur : np);
                          },
                        ),
                        const SizedBox(width: 24),
                        Obx(() => Text(
                              '${controller.formattedCurrentPosition} / ${controller.formattedEpisodeDuration}',
                              style: const TextStyle(
                                color: NFColors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            )),
                        const Spacer(),
                        Obx(() => NFDesktopButton(
                              icon: Icons.skip_next_rounded,
                              enabled: controller.canGoForward.value,
                              size: 34,
                              onTap: () => controller.navigator(true),
                            )),
                        const SizedBox(width: 20),
                        NFDesktopButton(
                          icon: Symbols.subtitles_rounded,
                          size: 30,
                          onTap: () => controller.isOffline.value
                              ? PlayerBottomSheets.showOfflineSubs(
                                  context, controller)
                              : PlayerBottomSheets.showSubtitleTracks(
                                  context, controller),
                        ),
                        const SizedBox(width: 20),
                        NFDesktopButton(
                          icon: Symbols.playlist_play_rounded,
                          size: 34,
                          onTap: () => controller.isEpisodePaneOpened.value =
                              !controller.isEpisodePaneOpened.value,
                        ),
                        const SizedBox(width: 20),
                        NFDesktopButton(
                          icon: Icons.fullscreen_rounded,
                          size: 36,
                          onTap: controller.toggleFullScreen,
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
