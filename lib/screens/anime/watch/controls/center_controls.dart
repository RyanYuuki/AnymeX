import 'dart:io';

import 'package:anymex/screens/anime/watch/controls/widgets/control_button.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';

class CenterControls extends StatelessWidget {
  const CenterControls({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PlayerController>();
    final isDesktop = !Platform.isAndroid && !Platform.isIOS;
    final theme = Theme.of(context);

    return Obx(() => IgnorePointer(
          ignoring: !controller.showControls.value,
          child: Align(
            alignment: Alignment.center,
            child: AnimatedScale(
              scale: controller.showControls.value ? 1.0 : 0.8,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutBack,
              child: AnimatedOpacity(
                opacity: controller.showControls.value ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                child: isDesktop
                    ? _buildDesktopLayout(theme)
                    : _buildMobileLayout(theme),
              ),
            ),
          ),
        ));
  }

  Widget _buildMobileLayout(ThemeData theme) {
    final controller = Get.find<PlayerController>();

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ControlButton(
          icon: Icons.skip_previous_rounded,
          onPressed: () => controller.navigator(false),
          tooltip: 'Previous Episode',
        ),
        const SizedBox(width: 32),
        Obx(() => GestureDetector(
              onTap: controller.togglePlayPause,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                width: 80,
                height: 80,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 100),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: child,
                    );
                  },
                  child: controller.isBuffering.value
                      ? const ExpressiveLoadingIndicator()
                      : Icon(
                          controller.isPlaying.value
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          key: ValueKey(controller.isPlaying.value),
                          size: 42,
                        ),
                ),
              ),
            )),
        const SizedBox(width: 32),
        ControlButton(
          icon: Icons.skip_next_rounded,
          onPressed: () => controller.navigator(true),
          tooltip: 'Next Episode',
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(ThemeData theme) {
    final controller = Get.find<PlayerController>();

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Opacity(
          opacity: controller.canGoBackward.value ? 1 : 0.5,
          child: ControlButton(
            icon: Icons.skip_previous_rounded,
            onPressed: () => controller.navigator(false),
            tooltip: 'Previous Episode',
          ),
        ),
        const SizedBox(width: 28),
        ControlButton(
          icon: Icons.replay_30_rounded,
          onPressed: () {
            final currentPos = controller.currentPosition.value;
            final newPos = currentPos - const Duration(seconds: 30);
            controller.seekTo(newPos.isNegative ? Duration.zero : newPos);
          },
          tooltip: 'Replay 30s',
        ),
        const SizedBox(width: 32),
        Obx(() => MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: controller.togglePlayPause,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  width: 92,
                  height: 92,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 100),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: child,
                      );
                    },
                    child: controller.isBuffering.value
                        ? const ExpressiveLoadingIndicator()
                        : Icon(
                            controller.isPlaying.value
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            key: ValueKey(controller.isPlaying.value),
                            size: 42,
                          ),
                  ),
                ),
              ),
            )),
        const SizedBox(width: 32),
        ControlButton(
          icon: Icons.forward_30_rounded,
          onPressed: () {
            final currentPos = controller.currentPosition.value;
            final duration = controller.episodeDuration.value;
            final newPos = currentPos + const Duration(seconds: 30);
            controller.seekTo(newPos > duration ? duration : newPos);
          },
          tooltip: 'Forward 30s',
        ),
        const SizedBox(width: 28),
        Opacity(
          opacity: controller.canGoForward.value ? 1 : 0.5,
          child: ControlButton(
            icon: Icons.skip_next_rounded,
            onPressed: () => controller.navigator(true),
            tooltip: 'Next Episode',
          ),
        ),
      ],
    );
  }
}
