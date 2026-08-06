import 'package:anymex/widgets/common/glow.dart';
import 'package:flutter/material.dart';

class CustomSlider extends StatefulWidget {
  final double? min;
  final double? max;
  final double value;
  final void Function(double) onChanged;
  final void Function(double)? onDragStart;
  final void Function(double)? onDragEnd;
  final int? divisions;
  final RoundedSliderValueIndicator? customValueIndicatorSize;
  final EdgeInsets? padding;
  final bool enableComfortPadding;
  final bool enableGlow;
  final double glowSpreadMultiplier;
  final double glowBlurMultiplier;
  final FocusNode? focusNode;
  final String? label;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool disableMinMax;
  const CustomSlider({
    super.key,
    required this.onChanged,
    this.max,
    this.min,
    required this.value,
    this.onDragEnd,
    this.onDragStart,
    this.divisions,
    this.customValueIndicatorSize,
    this.padding,
    this.enableComfortPadding = true,
    this.enableGlow = false,
    this.glowSpreadMultiplier = 1.0,
    this.glowBlurMultiplier = 1.0,
    this.focusNode,
    this.label,
    this.activeColor,
    this.inactiveColor,
    this.disableMinMax = false,
  });

  @override
  State<CustomSlider> createState() => CustomSliderState();
}

class CustomSliderState extends State<CustomSlider> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          boxShadow:
              widget.glowBlurMultiplier == 0 || widget.glowSpreadMultiplier == 0
                  ? []
                  : [glowingShadow(context)]),
      child: widget.disableMinMax
          ? Slider(
              focusNode: widget.focusNode,
              onChanged: widget.onChanged,
              onChangeStart: widget.onDragStart,
              onChangeEnd: widget.onDragEnd,
              divisions: widget.divisions,
              value: widget.value,
              label: widget.label ?? widget.value.toString(),
              year2023: false,
            )
          : Slider(
              focusNode: widget.focusNode,
              min: widget.min ?? 0,
              max: widget.max ?? 100,
              onChanged: widget.onChanged,
              onChangeStart: widget.onDragStart,
              onChangeEnd: widget.onDragEnd,
              divisions: widget.divisions,
              value: widget.value,
              label: widget.label ?? widget.value.toString(),
              year2023: false,
            ),
    );
  }
}

class SmallTickMarkShape extends SliderTickMarkShape {
  final double maxSize;

  const SmallTickMarkShape({this.maxSize = 4});

  @override
  Size getPreferredSize({
    required bool isEnabled,
    required SliderThemeData sliderTheme,
  }) {
    return Size(maxSize, maxSize);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    required bool isEnabled,
  }) {
    final bool isActive = center.dx <= thumbCenter.dx;

    final Paint paint = Paint()
      ..color = isActive
          ? sliderTheme.activeTickMarkColor ?? Colors.blue
          : sliderTheme.inactiveTickMarkColor ?? Colors.grey
      ..style = PaintingStyle.fill;

    context.canvas.drawCircle(center, maxSize / 2, paint);
  }
}

class RoundedSliderValueIndicator extends SliderComponentShape {
  final double width;
  final double height;
  final double radius;
  final bool onBottom;
  final ColorScheme colorScheme;

  RoundedSliderValueIndicator(this.colorScheme,
      {required this.width,
      required this.height,
      this.radius = 5,
      this.onBottom = false});

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
    final verticalValue = onBottom ? 35 : -45;
    final centerWithVerticalOffset =
        Offset(center.dx, center.dy + verticalValue);

    final rect = Rect.fromCenter(
        center: centerWithVerticalOffset, height: height, width: width);

    final TextPainter tp = labelPainter;

    tp.layout();

    context.canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(radius)),
        Paint()..color = colorScheme.primary);
    tp.paint(
        context.canvas,
        Offset(center.dx - (tp.width / 2),
            centerWithVerticalOffset.dy - (tp.height / 2)));
  }
}

class MarginedTrack extends SliderTrackShape {
  const MarginedTrack();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = true,
    bool isDiscrete = true,
  }) {
    final double overlayWidth =
        sliderTheme.overlayShape!.getPreferredSize(isEnabled, isDiscrete).width;
    final double trackHeight = sliderTheme.trackHeight ?? 20;
    final double trackLeft = offset.dx + overlayWidth / 2;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width - overlayWidth;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
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
    bool isEnabled = true,
    bool isDiscrete = true,
    required TextDirection textDirection,
  }) {
    final ColorTween activeTrackColorTween = ColorTween(
        begin: sliderTheme.disabledActiveTrackColor,
        end: sliderTheme.activeTrackColor);
    final ColorTween inactiveTrackColorTween = ColorTween(
        begin: sliderTheme.disabledInactiveTrackColor,
        end: sliderTheme.inactiveTrackColor);

    final Paint activePaint = Paint()
      ..color = activeTrackColorTween.evaluate(enableAnimation)!;
    final Paint inactivePaint = Paint()
      ..color = inactiveTrackColorTween.evaluate(enableAnimation)!;

    Paint leftTrackPaint;
    Paint rightTrackPaint;

    switch (textDirection) {
      case TextDirection.ltr:
        leftTrackPaint = activePaint;
        rightTrackPaint = inactivePaint;
        break;
      case TextDirection.rtl:
        leftTrackPaint = inactivePaint;
        rightTrackPaint = activePaint;
        break;
    }

    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final Rect leftTrackSegment = Rect.fromLTRB(
        trackRect.left, trackRect.top, thumbCenter.dx - 6, trackRect.bottom);
    final Rect rightTrackSegment = Rect.fromLTRB(
        thumbCenter.dx + 6, trackRect.top, trackRect.right, trackRect.bottom);

    context.canvas.drawRRect(
        RRect.fromRectAndCorners(
          leftTrackSegment,
          topLeft: const Radius.circular(50),
          bottomLeft: const Radius.circular(50),
          topRight: const Radius.circular(8),
          bottomRight: const Radius.circular(8),
        ),
        leftTrackPaint);

    context.canvas.drawRRect(
        RRect.fromRectAndCorners(
          rightTrackSegment,
          topLeft: const Radius.circular(8),
          bottomLeft: const Radius.circular(8),
          topRight: const Radius.circular(50),
          bottomRight: const Radius.circular(50),
        ),
        rightTrackPaint);
  }
}

class RoundedRectangularThumbShape extends SliderComponentShape {
  final double width;
  final double radius;
  final double height;
  final ColorScheme colorScheme;

  RoundedRectangularThumbShape(this.colorScheme,
      {required this.width, this.radius = 4, this.height = 25});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size(width, 10);
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
    final rect = Rect.fromCenter(center: center, width: width, height: height);
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      Paint()..color = colorScheme.primary,
    );

    final strokeRect =
        Rect.fromCenter(center: center, width: width, height: height);
    context.canvas.drawRRect(
        RRect.fromRectAndRadius(strokeRect, Radius.circular(radius)),
        Paint()
          ..color = colorScheme.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }
}
