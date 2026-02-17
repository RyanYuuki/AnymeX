import 'package:anymex/screens/anime/watch/controls/themes/setup/media_indicator_theme.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:flutter/material.dart';

class GamingMediaIndicatorTheme extends MediaIndicatorTheme {
  @override
  String get id => 'gaming';

  @override
  String get name => 'Gaming';

  @override
  Widget buildIndicator(BuildContext context, MediaIndicatorThemeData data) {
    final colors = Theme.of(context).colorScheme;
    final accentColor = data.isVolumeIndicator
        ? colors.primary
        : colors.tertiary;
    const transitionDuration = Duration(milliseconds: 180);
    const valueAnimationDuration = Duration(milliseconds: 80);

    return AnimatedOpacity(
      opacity: data.isVisible ? 1.0 : 0.0,
      duration: transitionDuration,
      curve: Curves.easeInOut,
      child: Align(
        alignment: data.isVolumeIndicator
            ? Alignment.centerLeft
            : Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: data.value),
            duration: valueAnimationDuration,
            curve: Curves.easeOut,
            builder: (context, animValue, _) {
              return Container(
                width: 88,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  border: Border.all(
                    color: accentColor,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.5),
                      blurRadius: 16,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: accentColor,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            data.icon,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(animValue * 100).round()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 140,
                      child: Stack(
                        children: [
                          for (int i = 0; i < 6; i++)
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: i * 22 + 6,
                              child: Container(
                                height: 14,
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: i < (animValue * 6).round()
                                      ? accentColor
                                      : Colors.grey.withOpacity(0.3),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
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
}
