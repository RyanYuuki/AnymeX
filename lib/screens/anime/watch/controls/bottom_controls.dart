import 'dart:io';
import 'package:anymex/screens/anime/watch/controls/widgets/bottom_sheet.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/control_button.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/progress_slider.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class BottomControls extends StatelessWidget {
  const BottomControls({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PlayerController>();
    final isDesktop = !Platform.isAndroid && !Platform.isIOS;

    return Obx(() => IgnorePointer(
          ignoring: !controller.showControls.value,
          child: AnimatedSlide(
            offset: controller.showControls.value
                ? Offset.zero
                : const Offset(0, 1),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              opacity: controller.showControls.value ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  top: false,
                  left: false,
                  right: false,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 32 : 20,
                      vertical: isDesktop ? 24 : 8,
                    ),
                    child: _buildLayout(context),
                  ),
                ),
              ),
            ),
          ),
        ));
  }

  Widget _buildLayout(BuildContext context) {
    final controller = Get.find<PlayerController>();
    final theme = context.theme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 20, 5),
          child: Align(
            alignment: Alignment.centerRight,
            child: Material(
              borderRadius: BorderRadius.circular(16),
              color: Colors.transparent,
              child: InkWell(
                onTap: () =>
                    controller.megaSeek(controller.playerSettings.skipDuration),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer
                        .withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.outline,
                      width: 0.5,
                    ),
                  ),
                  child: AnymexText(
                    text: '+${controller.playerSettings.skipDuration}',
                    variant: TextVariant.semiBold,
                  ),
                ),
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
          child: const ProgressSlider(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                        width: 0.5,
                      ),
                    ),
                    child: Obx(() => Text(
                          controller.formattedCurrentPosition,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        )),
                  ),
                  if (!controller.isOffline.value) ...[
                    const SizedBox(width: 16),
                    ControlButton(
                      icon: Symbols.playlist_play_rounded,
                      onPressed: () {
                        controller.isEpisodePaneOpened.value =
                            !controller.isEpisodePaneOpened.value;
                      },
                      tooltip: 'Playlist',
                    ),
                  ]
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.15),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ControlButton(
                          icon: Symbols.tune_rounded,
                          onPressed: () =>
                              controller.openColorProfileBottomSheet(context),
                          tooltip: 'Shaders & Color Profiles',
                          compact: true,
                        ),
                        if (!controller.isOffline.value) ...[
                          ControlButton(
                            icon: Symbols.subtitles_rounded,
                            onPressed: () =>
                                PlayerBottomSheets.showSubtitleTracks(
                              context,
                              controller,
                            ),
                            tooltip: 'Subtitles',
                            compact: true,
                          ),
                          ControlButton(
                            icon: Symbols.cloud_rounded,
                            onPressed: () {
                              PlayerBottomSheets.showVideoServers(
                                  context, controller);
                            },
                            tooltip: 'Server',
                            compact: true,
                          ),
                          ControlButton(
                            icon: Symbols.high_quality_rounded,
                            onPressed: () =>
                                PlayerBottomSheets.showVideoQuality(
                                    context, controller),
                            tooltip: 'Quality',
                            compact: true,
                          ),
                        ] else ...[
                          ControlButton(
                            icon: Symbols.subtitles_rounded,
                            onPressed: () => PlayerBottomSheets.showOfflineSubs(
                              context,
                              controller,
                            ),
                            tooltip: 'Subtitles',
                            compact: true,
                          ),
                        ],
                        ControlButton(
                          icon: Symbols.speed_rounded,
                          onPressed: () => PlayerBottomSheets.showPlaybackSpeed(
                              context, controller),
                          tooltip: 'Speed',
                          compact: true,
                        ),
                        ControlButton(
                          icon: Symbols.music_note_rounded,
                          onPressed: () => PlayerBottomSheets.showAudioTracks(
                              context, controller),
                          tooltip: 'Audio Track',
                          compact: true,
                        ),
                        if (Platform.isAndroid || Platform.isIOS)
                          ControlButton(
                            icon: Icons.screen_rotation_rounded,
                            onPressed: () => controller.toggleOrientation(),
                            tooltip: 'Toggle Orientation',
                            compact: true,
                          ),
                        ControlButton(
                          icon: Symbols.fit_screen,
                          onPressed: () => controller.toggleVideoFit(),
                          tooltip: 'Aspect Ratio',
                          compact: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                        width: 0.5,
                      ),
                    ),
                    child: Obx(() => Text(
                          controller.formattedEpisodeDuration,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        )),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
