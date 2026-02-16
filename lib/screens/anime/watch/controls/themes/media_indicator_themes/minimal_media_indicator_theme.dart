import 'package:anymex/screens/anime/watch/controls/themes/setup/media_indicator_theme.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:flutter/material.dart';

class MinimalMediaIndicatorTheme extends MediaIndicatorTheme {
  @override
  String get id => 'minimal';

  @override
  String get name => 'Minimal';

  @override
  Widget buildIndicator(
    BuildContext context,
    MediaIndicatorThemeData data,
  ) {
    final colors = Theme.of(context).colorScheme;
    final accentColor =
        data.isVolumeIndicator ? colors.primary : colors.tertiary;

    const transitionDuration = Duration(milliseconds: 220);
    const valueAnimationDuration = Duration(milliseconds: 150);

    return AnimatedSlide(
      offset: data.isVisible ? Offset.zero : const Offset(0, -1),
      duration: transitionDuration,
      curve: data.isVisible ? Curves.easeOutCubic : Curves.easeInCubic,
      child: AnimatedOpacity(
        opacity: data.isVisible ? 1.0 : 0.0,
        duration: transitionDuration,
        curve: Curves.easeInOut,
        child: Align(
          alignment: Alignment.topCenter,
          child: SafeArea(
            bottom: false,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _TopLineBar(
                  value: data.value,
                  accentColor: accentColor,
                  icon: data.icon,
                  isVolumeIndicator: data.isVolumeIndicator,
                  valueAnimationDuration: valueAnimationDuration,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopLineBar extends StatelessWidget {
  const _TopLineBar({
    required this.value,
    required this.accentColor,
    required this.icon,
    required this.isVolumeIndicator,
    required this.valueAnimationDuration,
  });

  final double value;
  final Color accentColor;
  final IconData icon;
  final bool isVolumeIndicator;
  final Duration valueAnimationDuration;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.black.opaque(0.54),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon on the left
          Icon(
            icon,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 10),

          // Animated progress line
          SizedBox(
            width: 160,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: value),
              duration: valueAnimationDuration,
              curve: Curves.easeOut,
              builder: (context, animValue, _) {
                return _GlowProgressBar(
                  value: animValue,
                  accentColor: accentColor,
                );
              },
            ),
          ),

          const SizedBox(width: 10),

          // Percentage label on the right
          TweenAnimationBuilder<double>(
            tween: Tween<double>(end: value),
            duration: valueAnimationDuration,
            curve: Curves.easeOut,
            builder: (context, animValue, _) {
              return SizedBox(
                width: 34,
                child: Text(
                  '${(animValue * 100).round()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                  textAlign: TextAlign.right,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// A rounded progress bar with a soft glow on the filled portion.
class _GlowProgressBar extends StatelessWidget {
  const _GlowProgressBar({
    required this.value,
    required this.accentColor,
  });

  final double value;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final filledWidth = (totalWidth * value).clamp(0.0, totalWidth);

        return SizedBox(
          height: 4,
          child: Stack(
            children: [
              // Track
              Container(
                width: totalWidth,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.opaque(0.18),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),

              // Filled portion with glow
              Container(
                width: filledWidth,
                height: 4,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.opaque(0.55),
                      blurRadius: 6,
                      spreadRadius: 0,
                    ),
                  ],
                ),
              ),

              // Leading dot / thumb
              if (filledWidth > 4)
                Positioned(
                  left: filledWidth - 4,
                  top: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.opaque(0.8),
                          blurRadius: 5,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
