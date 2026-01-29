import 'dart:ui';

import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Obx(() {
      final value = isVolumeIndicator
          ? controller.volume.value
          : controller.brightness.value;

      final indicatorVisible = isVolumeIndicator
          ? controller.volumeIndicator.value
          : controller.brightnessIndicator.value;

      return IgnorePointer(
        ignoring: true,
        child: AnimatedOpacity(
          opacity: indicatorVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: AnimatedScale(
            scale: indicatorVisible ? 1.0 : 0.9,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            value: 1.0,
                            strokeWidth: 8,
                            color: Colors.black.withOpacity(0.2),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0, end: value),
                            duration: const Duration(milliseconds: 150),
                            builder: (context, animValue, _) {
                              return CircularProgressIndicator(
                                value: animValue,
                                year2023: false,
                                strokeWidth: 8,
                                color: isVolumeIndicator
                                    ? colorScheme.primary.withOpacity(0.9)
                                    : colorScheme.tertiary.withOpacity(0.9),
                                strokeCap: StrokeCap.round,
                              );
                            },
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getIcon(value),
                              size: 32,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${(value * 100).round()}%',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
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
          ),
        ),
      );
    });
  }

  IconData _getIcon(double value) {
    if (isVolumeIndicator) {
      return switch (value) {
        == 0.0 => Icons.volume_off_rounded,
        < 0.3 => Icons.volume_mute_rounded,
        < 0.7 => Icons.volume_down_rounded,
        _ => Icons.volume_up_rounded,
      };
    } else {
      return switch (value) {
        < 0.33 => Icons.brightness_low_rounded,
        < 0.66 => Icons.brightness_medium_rounded,
        _ => Icons.brightness_high_rounded,
      };
    }
  }
}
