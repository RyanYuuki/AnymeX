import 'package:anymex/screens/anime/watch/controls/themes/setup/media_indicator_theme.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:flutter/material.dart';

class DefaultMediaIndicatorTheme extends MediaIndicatorTheme {
  @override
  String get id => 'default';

  @override
  String get name => 'Default';

  @override
  Widget buildIndicator(BuildContext context, MediaIndicatorThemeData data) {
    final colors = Theme.of(context).colorScheme;
    final accentColor =
        data.isVolumeIndicator ? colors.primary : colors.tertiary;
    const transitionDuration = Duration(milliseconds: 200);
    const valueAnimationDuration = Duration(milliseconds: 130);
    const hiddenScale = 0.95;

    return AnimatedOpacity(
      opacity: data.isVisible ? 1.0 : 0.0,
      duration: transitionDuration,
      curve: Curves.easeInOut,
      child: AnimatedScale(
        scale: data.isVisible ? 1.0 : hiddenScale,
        duration: transitionDuration,
        curve: Curves.easeOutCubic,
        child: Align(
          alignment: data.isVolumeIndicator
              ? Alignment.centerLeft
              : Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.black.opaque(0.54),
                borderRadius: BorderRadius.circular(100),
              ),
              width: 42,
              child: UnconstrainedBox(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(5),
                        child: RotatedBox(
                          quarterTurns: -1,
                          child: SizedBox(
                            width: 168,
                            height: 24,
                            child: TweenAnimationBuilder<double>(
                              tween: Tween<double>(end: data.value),
                              duration: valueAnimationDuration,
                              curve: Curves.easeOut,
                              builder: (context, animValue, _) {
                                return LinearProgressIndicator(
                                  value: animValue,
                                  borderRadius: BorderRadius.circular(100),
                                  minHeight: 6,
                                  backgroundColor: Colors.white.opaque(0.18),
                                  color: accentColor,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Icon(
                        data.icon,
                        color: Colors.white,
                        size: 24,
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
  }
}
