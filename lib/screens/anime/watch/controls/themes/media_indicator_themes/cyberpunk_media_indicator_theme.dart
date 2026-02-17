import 'dart:ui';

import 'package:anymex/screens/anime/watch/controls/themes/setup/media_indicator_theme.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:flutter/material.dart';

class CyberpunkMediaIndicatorTheme extends MediaIndicatorTheme {
  @override
  String get id => 'cyberpunk';

  @override
  String get name => 'Cyberpunk';

  @override
  Widget buildIndicator(BuildContext context, MediaIndicatorThemeData data) {
    final colors = Theme.of(context).colorScheme;
    final accentColor = data.isVolumeIndicator
        ? colors.primary
        : colors.tertiary;
    const transitionDuration = Duration(milliseconds: 200);
    const valueAnimationDuration = Duration(milliseconds: 100);

    return AnimatedOpacity(
      opacity: data.isVisible ? 1.0 : 0.0,
      duration: transitionDuration,
      curve: Curves.easeInOut,
      child: Align(
        alignment: data.isVolumeIndicator
            ? Alignment.centerLeft
            : Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: data.value),
            duration: valueAnimationDuration,
            curve: Curves.easeOut,
            builder: (context, animValue, _) {
              return Container(
                width: 72,
                height: 220,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accentColor.opaque(0.8),
                      accentColor.withOpacity(0.3),
                    ],
                  ),
                  border: Border.all(
                    color: accentColor,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor,
                      blurRadius: 20,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 8,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            border: Border.all(
                              color: accentColor.opaque(0.5),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'CYBER',
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            data.icon,
                            color: Colors.white,
                            size: 32,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                blurRadius: 4,
                                offset: const Offset(2, 2),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          for (int i = 0; i < 8; i++)
                            Container(
                              height: 12,
                              margin: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: i < (animValue * 8).round()
                                    ? accentColor
                                    : Colors.white.opaque(0.15),
                                border: Border.all(
                                  color: Colors.black26,
                                  width: 1,
                                ),
                              ),
                            ),
                        ],
                    ],
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
