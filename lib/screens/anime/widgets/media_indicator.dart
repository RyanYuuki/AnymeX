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
      final indicator = isVolumeIndicator
          ? controller.volumeIndicator
          : controller.brightnessIndicator;

      return AnimatedPositioned(
        duration: const Duration(milliseconds: 500),
        curve: Curves.elasticOut,
        left: isVolumeIndicator ? 24 : null,
        right: isVolumeIndicator ? null : 24,
        top: 0,
        bottom: 0,
        child: IgnorePointer(
          ignoring: true,
          child: Center(
            child: AnimatedScale(
              scale: indicator.value ? 1.0 : 0.8,
              duration: const Duration(milliseconds: 400),
              curve: Curves.elasticOut,
              child: AnimatedOpacity(
                opacity: indicator.value ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        colorScheme.surface.withOpacity(0.95),
                        colorScheme.surface.withOpacity(0.85),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.1),
                        blurRadius: 8,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  colorScheme.primary.withOpacity(0.2),
                                  colorScheme.primary.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: colorScheme.primary.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              _getIcon(value),
                              color: colorScheme.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 160,
                            width: 8,
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                Container(
                                  width: 8,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    color: colorScheme.outline.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOutCubic,
                                  width: 8,
                                  height: 160 * value,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        colorScheme.primary,
                                        colorScheme.primary.withOpacity(0.8),
                                        colorScheme.primary.withOpacity(0.6),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: colorScheme.primary
                                            .withOpacity(0.4),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                                if (value > 0)
                                  AnimatedPositioned(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeOutCubic,
                                    bottom: (160 * value) - 6,
                                    child: Container(
                                      width: 16,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary,
                                        borderRadius: BorderRadius.circular(6),
                                        boxShadow: [
                                          BoxShadow(
                                            color: colorScheme.primary
                                                .withOpacity(0.6),
                                            blurRadius: 12,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  colorScheme.primaryContainer.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.primary.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '${(value * 100).round()}%',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
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
