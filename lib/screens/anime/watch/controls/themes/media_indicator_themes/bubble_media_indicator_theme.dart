import 'dart:ui';

import 'package:anymex/screens/anime/watch/controls/themes/setup/media_indicator_theme.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:flutter/material.dart';

class BubbleMediaIndicatorTheme extends MediaIndicatorTheme {
  @override
  String get id => 'bubble';

  @override
  String get name => 'Bubble';

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
      curve: Curves.elasticOut,
      child: Align(
        alignment: data.isVolumeIndicator
            ? Alignment.centerLeft
            : Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: data.value),
            duration: valueAnimationDuration,
            curve: Curves.easeOutBack,
            builder: (context, animValue, _) {
              return Container(
                width: 90,
                height: 180,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildBubble(
                      size: 40,
                      filled: animValue >= 0.75,
                      accentColor: accentColor,
                      icon: Icons.more_vert,
                    ),
                    _buildBubble(
                      size: 32,
                      filled: animValue >= 0.5 && animValue < 0.75,
                      accentColor: accentColor,
                      icon: Icons.more_horiz,
                    ),
                    _buildBubble(
                      size: 24,
                      filled: animValue >= 0.25 && animValue < 0.5,
                      accentColor: accentColor,
                      icon: null,
                    ),
                    _buildBubble(
                      size: 20,
                      filled: animValue < 0.25,
                      accentColor: accentColor,
                      icon: null,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBubble({
    required double size,
    required bool filled,
    required Color accentColor,
    IconData? icon,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? accentColor : Colors.white.withOpacity(0.2),
        border: Border.all(
          color: filled ? accentColor : Colors.white.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: filled
            ? [
                BoxShadow(
                  color: accentColor,
                  blurRadius: 12,
                  spreadRadius: -2,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                ),
              ],
      ),
      child: icon != null
          ? Icon(
              icon,
              color: Colors.white,
              size: size * 0.4,
            )
          : null,
    );
  }
}
