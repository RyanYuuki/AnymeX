import 'dart:ui';

import 'package:anymex/screens/anime/watch/controls/themes/setup/media_indicator_theme.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:flutter/material.dart';

class ElegantMediaIndicatorTheme extends MediaIndicatorTheme {
  @override
  String get id => 'elegant';

  @override
  String get name => 'Elegant';

  @override
  Widget buildIndicator(BuildContext context, MediaIndicatorThemeData data) {
    final colors = Theme.of(context).colorScheme;
    final accentColor = data.isVolumeIndicator
        ? colors.primary
        : colors.tertiary;
    const transitionDuration = Duration(milliseconds: 280);
    const valueAnimationDuration = Duration(milliseconds: 200);

    return AnimatedOpacity(
      opacity: data.isVisible ? 1.0 : 0.0,
      duration: transitionDuration,
      curve: Curves.easeInOutCubic,
      child: Align(
        alignment: data.isVolumeIndicator
            ? Alignment.centerLeft
            : Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: data.value),
            duration: valueAnimationDuration,
            curve: Curves.easeOutCubic,
            builder: (context, animValue, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    width: 52,
                    height: 240,
                    decoration: BoxDecoration(
                      color: Colors.white.opaque(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.opaque(0.12),
                        width: 0.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          data.icon,
                          color: Colors.white.opaque(0.9),
                          size: 20,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 140,
                          width: 4,
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              Container(
                                width: 4,
                                height: 140,
                                decoration: BoxDecoration(
                                  color: Colors.white.opaque(0.1),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 100),
                                height: 140 * animValue,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      accentColor,
                                      accentColor.opaque(0.5),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accentColor.opaque(0.6),
                                      blurRadius: 8,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${(animValue * 100).round()}',
                          style: TextStyle(
                            color: Colors.white.opaque(0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w300,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
