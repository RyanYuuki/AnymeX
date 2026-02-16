import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:flutter/material.dart';

class MediaIndicatorThemeData {
  final PlayerController controller;
  final bool isVisible;
  final bool isVolumeIndicator;
  final double value;

  const MediaIndicatorThemeData({
    required this.controller,
    required this.isVisible,
    required this.isVolumeIndicator,
    required this.value,
  });

  double get percent => (value * 100).clamp(0, 100);

  IconData get icon {
    if (isVolumeIndicator) {
      return switch (value) {
        == 0.0 => Icons.volume_off_rounded,
        < 0.3 => Icons.volume_mute_rounded,
        < 0.7 => Icons.volume_down_rounded,
        _ => Icons.volume_up_rounded,
      };
    }

    return switch (value) {
      < 0.33 => Icons.brightness_low_rounded,
      < 0.66 => Icons.brightness_medium_rounded,
      _ => Icons.brightness_high_rounded,
    };
  }
}

abstract class MediaIndicatorTheme {
  String get id;
  String get name;
  Widget buildIndicator(BuildContext context, MediaIndicatorThemeData data);
}
