import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BufferingOverlay extends StatelessWidget {
  final PlayerController controller;

  const BufferingOverlay({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final visible = controller.isBuffering.value &&
          (!controller.showControls.value || controller.isLocked.value);

      if (!visible) {
        return const SizedBox.shrink();
      }
      return const IgnorePointer(
        ignoring: true,
        child: Center(
          child: SizedBox(
            width: 32,
            height: 32,
            child: ExpressiveLoadingIndicator(),
          ),
        ),
      );
    });
  }
}
