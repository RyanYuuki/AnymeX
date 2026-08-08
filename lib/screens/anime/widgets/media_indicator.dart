import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/screens/anime/watch/controls/themes/setup/media_indicator_theme.dart';
import 'package:anymex/screens/anime/watch/controls/themes/setup/media_indicator_theme_registry.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MediaIndicatorBuilder extends StatelessWidget {
  final PlayerController controller;
  final bool isVolumeIndicator;

  const MediaIndicatorBuilder({
    super.key,
    required this.isVolumeIndicator,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<Settings>();

    return Obx(() {
      final value = isVolumeIndicator
          ? controller.volume.value
          : controller.brightness.value;
      final isVisible = isVolumeIndicator
          ? controller.volumeIndicator.value
          : controller.brightnessIndicator.value;
      final theme = MediaIndicatorThemeRegistry.resolve(
        settings.mediaIndicatorThemeRx.value,
      );
      final data = MediaIndicatorThemeData(
        controller: controller,
        isVisible: isVisible,
        isVolumeIndicator: isVolumeIndicator,
        value: value,
      );

      return IgnorePointer(
        ignoring: true,
        child: theme.buildIndicator(context, data),
      );
    });
  }
}
