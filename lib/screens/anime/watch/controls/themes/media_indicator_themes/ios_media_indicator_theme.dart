import 'dart:ui';

import 'package:anymex/screens/anime/watch/controls/themes/setup/media_indicator_theme.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:flutter/material.dart';

class IosMediaIndicatorTheme extends MediaIndicatorTheme {
  @override
  String get id => 'ios';

  @override
  String get name => 'iOS 26';

  @override
  Widget buildIndicator(BuildContext context, MediaIndicatorThemeData data) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = colors.primary.opaque(0.9);
    final tertiaryColor = colors.tertiary.opaque(0.9);
    const transitionDuration = Duration(milliseconds: 200);
    const valueAnimationDuration = Duration(milliseconds: 150);
    const hiddenScale = 0.9;

    return AnimatedOpacity(
      opacity: data.isVisible ? 1.0 : 0.0,
      duration: transitionDuration,
      curve: Curves.easeInOut,
      child: AnimatedScale(
        scale: data.isVisible ? 1.0 : hiddenScale,
        duration: transitionDuration,
        curve: Curves.easeOutCubic,
        child: Align(
          alignment: Alignment.center,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: colors.surface.opaque(0.2),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Colors.white.opaque(0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.opaque(0.1),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const SizedBox(
                      width: 88,
                      height: 88,
                      child: CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 8,
                        color: Color.fromRGBO(0, 0, 0, 0.2),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    SizedBox(
                      width: 88,
                      height: 88,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(end: data.value),
                        duration: valueAnimationDuration,
                        curve: Curves.easeOut,
                        builder: (context, animValue, _) {
                          final firstValue = animValue.clamp(0.0, 1.0);
                          final secondValue = (animValue - 1.0).clamp(0.0, 1.0);

                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox.expand(
                                child: CircularProgressIndicator(
                                  value: firstValue,
                                  year2023: false,
                                  strokeWidth: 8,
                                  color: data.isVolumeIndicator
                                      ? primaryColor
                                      : tertiaryColor,
                                  strokeCap: StrokeCap.round,
                                ),
                              ),
                              if (data.isVolumeIndicator && secondValue > 0)
                                SizedBox.expand(
                                  child: CircularProgressIndicator(
                                    value: secondValue,
                                    year2023: false,
                                    strokeWidth: 8,
                                    color: tertiaryColor,
                                    strokeCap: StrokeCap.round,
                                    backgroundColor: Colors.transparent,
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          data.icon,
                          size: 32,
                          color: Colors.white.opaque(0.9),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${data.percent.round()}%',
                          style: textTheme.labelMedium?.copyWith(
                            color: Colors.white.opaque(0.9),
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
    );
  }
}
