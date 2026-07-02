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
    final primaryColor = colors.primary;
    final tertiaryColor = colors.tertiary;

    final progress = data.isVolumeIndicator
        ? (data.value / 2.0).clamp(0.0, 1.0)
        : data.value.clamp(0.0, 1.0);

    const duration = Duration(milliseconds: 200);

    final accent = data.isVolumeIndicator ? primaryColor : tertiaryColor;
    final container = data.isVolumeIndicator ? primaryColor : tertiaryColor;
    final onContainer =
        data.isVolumeIndicator ? colors.onPrimary : colors.onTertiary;
    final surface = colors.surfaceVariant.opaque(0.85);
    final border = colors.outline.opaque(0.2);

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 40.0),
        child: AnimatedOpacity(
          opacity: data.isVisible ? 1.0 : 0.0,
          duration: duration,
          curve: Curves.easeOutCubic,
          child: AnimatedSlide(
            offset: data.isVisible ? Offset.zero : const Offset(0, -0.18),
            duration: duration,
            curve: Curves.easeOutCubic,
            child: AnimatedScale(
              scale: data.isVisible ? 1.0 : 0.92,
              duration: duration,
              curve: Curves.easeOutBack,
              child: Container(
                width: 210,
                height: 44,
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: border),
                  boxShadow: [
                    BoxShadow(
                      color: accent.opaque(data.isVisible ? 0.24 : 0),
                      blurRadius: 32,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: Colors.black.opaque(0.28),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: container,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: AnimatedSwitcher(
                            duration: duration,
                            switchInCurve: Curves.easeOutBack,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (child, animation) {
                              return ScaleTransition(
                                scale: animation,
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              );
                            },
                            child: Icon(
                              data.icon,
                              key: ValueKey(data.icon),
                              color: onContainer,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 32,
                              activeTrackColor: container,
                              inactiveTrackColor: container.opaque(0.2),
                              thumbColor: container,
                              overlayShape: SliderComponentShape.noOverlay,
                              trackShape: const _HudSliderTrackShape(
                                outerRadius: 12,
                                innerRadius: 2,
                                thumbGap: 12,
                                edgeInset: 6,
                              ),
                              thumbShape: const _HudSliderThumbShape(
                                width: 4,
                                height: 40,
                                cornerRadius: 2,
                              ),
                              tickMarkShape: SliderTickMarkShape.noTickMark,
                              padding: EdgeInsets.zero,
                            ),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween<double>(end: progress),
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOutCubic,
                              builder: (context, animatedProgress, child) {
                                return Slider(
                                  value: animatedProgress,
                                  onChanged: (_) {},
                                );
                              },
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
  }
}

class _HudSliderTrackShape extends SliderTrackShape {
  const _HudSliderTrackShape({
    required this.outerRadius,
    required this.innerRadius,
    this.thumbGap = 10,
    this.edgeInset = 6,
  });

  final double outerRadius;
  final double innerRadius;
  final double thumbGap;
  final double edgeInset;

  Rect _baseTrackRect({
    required RenderBox parentBox,
    required Offset offset,
    required SliderThemeData sliderTheme,
    required bool isEnabled,
    required bool isDiscrete,
  }) {
    final thumbWidth =
        sliderTheme.thumbShape?.getPreferredSize(isEnabled, isDiscrete).width ??
            0;
    final trackHeight = sliderTheme.trackHeight ?? 0;
    final trackLeft = offset.dx + thumbWidth / 2;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final trackWidth = parentBox.size.width - thumbWidth;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final baseTrackRect = _baseTrackRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final safeInset = edgeInset.clamp(0.0, baseTrackRect.width / 2).toDouble();
    return Rect.fromLTRB(
      baseTrackRect.left + safeInset,
      baseTrackRect.top,
      baseTrackRect.right - safeInset,
      baseTrackRect.bottom,
    );
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
  }) {
    final canvas = context.canvas;
    final baseTrackRect = _baseTrackRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final effectiveTrackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final activeColor = ColorTween(
          begin: sliderTheme.disabledActiveTrackColor,
          end: sliderTheme.activeTrackColor,
        ).evaluate(enableAnimation) ??
        Colors.transparent;
    final inactiveColor = ColorTween(
          begin: sliderTheme.disabledInactiveTrackColor,
          end: sliderTheme.inactiveTrackColor,
        ).evaluate(enableAnimation) ??
        Colors.transparent;

    final thumbX = thumbCenter.dx.clamp(
      effectiveTrackRect.left,
      effectiveTrackRect.right,
    );
    var halfGap = thumbGap / 2;
    final leftRoom = thumbX - baseTrackRect.left;
    final rightRoom = baseTrackRect.right - thumbX;
    if (halfGap > leftRoom) {
      halfGap = leftRoom;
    }
    if (halfGap > rightRoom) {
      halfGap = rightRoom;
    }

    final leftEnd = (thumbX - halfGap).clamp(
      baseTrackRect.left,
      baseTrackRect.right,
    );
    final rightStart = (thumbX + halfGap).clamp(
      baseTrackRect.left,
      baseTrackRect.right,
    );

    final leftRect = Rect.fromLTRB(
      baseTrackRect.left,
      baseTrackRect.top,
      leftEnd,
      baseTrackRect.bottom,
    );
    final rightRect = Rect.fromLTRB(
      rightStart,
      baseTrackRect.top,
      baseTrackRect.right,
      baseTrackRect.bottom,
    );

    final leftColor =
        textDirection == TextDirection.ltr ? activeColor : inactiveColor;
    final rightColor =
        textDirection == TextDirection.ltr ? inactiveColor : activeColor;
    final hasLeftSegment = leftRect.width > 0;
    final hasRightSegment = rightRect.width > 0;

    if (hasLeftSegment) {
      _paintSegment(
        canvas: canvas,
        segmentRect: leftRect,
        color: leftColor,
        startRadius: outerRadius,
        endRadius: innerRadius,
        anchorToStart: true,
      );
    }

    if (hasRightSegment) {
      _paintSegment(
        canvas: canvas,
        segmentRect: rightRect,
        color: rightColor,
        startRadius: innerRadius,
        endRadius: outerRadius,
        anchorToStart: false,
      );
    }
  }

  void _paintSegment({
    required Canvas canvas,
    required Rect segmentRect,
    required Color color,
    required double startRadius,
    required double endRadius,
    required bool anchorToStart,
  }) {
    if (segmentRect.width <= 0) {
      return;
    }

    final minTemplateWidth = startRadius + endRadius;
    final templateWidth = segmentRect.width < minTemplateWidth
        ? minTemplateWidth
        : segmentRect.width;
    final templateRect = anchorToStart
        ? Rect.fromLTWH(
            segmentRect.left,
            segmentRect.top,
            templateWidth,
            segmentRect.height,
          )
        : Rect.fromLTWH(
            segmentRect.right - templateWidth,
            segmentRect.top,
            templateWidth,
            segmentRect.height,
          );

    canvas.save();
    canvas.clipRect(segmentRect);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        templateRect,
        topLeft: Radius.circular(startRadius),
        bottomLeft: Radius.circular(startRadius),
        topRight: Radius.circular(endRadius),
        bottomRight: Radius.circular(endRadius),
      ),
      Paint()..color = color,
    );
    canvas.restore();
  }
}

class _HudSliderThumbShape extends SliderComponentShape {
  const _HudSliderThumbShape({
    required this.width,
    required this.height,
    required this.cornerRadius,
  });

  final double width;
  final double height;
  final double cornerRadius;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size(width, height);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final thumbColor = ColorTween(
          begin: sliderTheme.disabledThumbColor,
          end: sliderTheme.thumbColor,
        ).evaluate(enableAnimation) ??
        Colors.transparent;
    final canvas = context.canvas;

    final thumbRect = Rect.fromCenter(
      center: center,
      width: width,
      height: height,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        thumbRect,
        Radius.circular(cornerRadius),
      ),
      Paint()..color = thumbColor,
    );
  }
}
