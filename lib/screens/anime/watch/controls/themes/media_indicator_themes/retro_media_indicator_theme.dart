import 'package:anymex/screens/anime/watch/controls/themes/setup/media_indicator_theme.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:flutter/material.dart';

class RetroMediaIndicatorTheme extends MediaIndicatorTheme {
  @override
  String get id => 'retro';

  @override
  String get name => 'Retro';

  @override
  Widget buildIndicator(BuildContext context, MediaIndicatorThemeData data) {
    final colors = Theme.of(context).colorScheme;
    final accentColor = data.isVolumeIndicator
        ? colors.primary
        : colors.tertiary;
    const transitionDuration = Duration(milliseconds: 200);
    const valueAnimationDuration = Duration(milliseconds: 180);

    return AnimatedOpacity(
      opacity: data.isVisible ? 1.0 : 0.0,
      duration: transitionDuration,
      curve: Curves.easeInOut,
      child: Align(
        alignment: data.isVolumeIndicator
            ? Alignment.centerLeft
            : Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: data.value),
            duration: valueAnimationDuration,
            curve: Curves.easeInOut,
            builder: (context, animValue, _) {
              return Container(
                width: 60,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  border: Border.all(
                    color: Colors.white.opaque(0.3),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.opaque(0.5),
                      offset: const Offset(4, 4),
                      blurRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.white.opaque(0.1),
                      offset: const Offset(-4, -4),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 160,
                      width: double.infinity,
                      child: Stack(
                        children: [
                          for (int i = 0; i < 10; i++)
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: i * 16.0 + 4,
                              child: Container(
                                height: 10,
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: i < (animValue * 10).round()
                                      ? accentColor
                                      : Colors.grey.opaque(0.4),
                                  border: Border.all(
                                    color: Colors.white.opaque(0.2),
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      width: double.infinity,
                      color: accentColor,
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              data.icon,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${(animValue * 100).round()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Courier',
                              ),
                            ),
                          ],
                        ),
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
