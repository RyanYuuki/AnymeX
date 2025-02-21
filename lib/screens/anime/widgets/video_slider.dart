import 'package:flutter/material.dart';

class VideoSliderTheme extends StatefulWidget {
  final Slider child;
  final Color? color;
  final Color? inactiveTrackColor;
  const VideoSliderTheme({
    super.key,
    required this.child,
    this.color,
    this.inactiveTrackColor,
  });

  @override
  State<VideoSliderTheme> createState() => VideoSliderThemeState();
}

class VideoSliderThemeState extends State<VideoSliderTheme> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SliderTheme(
        data: SliderThemeData(
          thumbColor: colorScheme.primary,
          activeTrackColor: widget.color ?? colorScheme.primary,
          inactiveTrackColor: widget.inactiveTrackColor ??
              Theme.of(context).colorScheme.surface.withOpacity(0.8),
          secondaryActiveTrackColor: colorScheme.primary.withAlpha(144),
          trackHeight: 6,
          thumbShape: RoundedRectangularThumbShape(
              width: 3, height: 23, radius: 30, colorScheme),
          trackShape: const MarginedTrack(),
        ),
        child: widget.child);
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
    // Adjust center to match image height
    final adjustedCenter = Offset(center.dx, center.dy);

    final rect =
        Rect.fromCenter(center: adjustedCenter, width: width, height: height);
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      Paint()..color = colorScheme.primary,
    );

    // Add subtle border effect
    final strokeRect =
        Rect.fromCenter(center: adjustedCenter, width: width, height: height);
    context.canvas.drawRRect(
        RRect.fromRectAndRadius(strokeRect, Radius.circular(radius)),
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2); // Reduced stroke width for subtler border
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
    final double trackHeight = sliderTheme.trackHeight ?? 20;
    final double trackLeft = offset.dx;
    final double trackTop = (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
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
    Offset? secondaryOffset, // Secondary thumb for the secondary track
    bool isEnabled = true,
    bool isDiscrete = true,
    required TextDirection textDirection,
  }) {
    final ColorTween activeTrackColorTween = ColorTween(
      begin: sliderTheme.disabledActiveTrackColor,
      end: sliderTheme.activeTrackColor,
    );
    final ColorTween inactiveTrackColorTween = ColorTween(
      begin: sliderTheme.disabledInactiveTrackColor,
      end: sliderTheme.inactiveTrackColor,
    );
    final ColorTween secondaryTrackColorTween = ColorTween(
      begin: sliderTheme.disabledSecondaryActiveTrackColor,
      end: sliderTheme.secondaryActiveTrackColor,
    );

    final Paint activePaint = Paint()
      ..color = activeTrackColorTween.evaluate(enableAnimation)!;
    final Paint inactivePaint = Paint()
      ..color = inactiveTrackColorTween.evaluate(enableAnimation)!;
    final Paint secondaryPaint = Paint()
      ..color = secondaryTrackColorTween.evaluate(enableAnimation)!;

    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    // Draw the inactive track first
    final Rect rightTrackSegment = Rect.fromLTRB(
      thumbCenter.dx + 6,
      trackRect.top,
      trackRect.right,
      trackRect.bottom,
    );

    context.canvas.drawRRect(
      RRect.fromRectAndCorners(
        rightTrackSegment,
        topLeft: const Radius.circular(8),
        bottomLeft: const Radius.circular(8),
        topRight: const Radius.circular(50),
        bottomRight: const Radius.circular(50),
      ),
      inactivePaint,
    );

    // Draw the secondary track above the inactive track
    if (secondaryOffset != null) {
      final double secondaryStart = thumbCenter.dx + 6;
      final double secondaryEnd = secondaryOffset.dx - 6;

      if (secondaryEnd > secondaryStart) {
        final Rect secondaryTrackSegment = Rect.fromLTRB(
          secondaryStart,
          trackRect.top,
          secondaryEnd,
          trackRect.bottom,
        );

        context.canvas.drawRRect(
          RRect.fromRectAndCorners(
            secondaryTrackSegment,
            topLeft: const Radius.circular(0),
            bottomLeft: const Radius.circular(0),
            topRight: const Radius.circular(8),
            bottomRight: const Radius.circular(8),
          ),
          secondaryPaint,
        );
      }
    }

    // Draw the active track on top
    final Rect leftTrackSegment = Rect.fromLTRB(
      trackRect.left,
      trackRect.top,
      thumbCenter.dx - 6,
      trackRect.bottom,
    );

    context.canvas.drawRRect(
      RRect.fromRectAndCorners(
        leftTrackSegment,
        topLeft: const Radius.circular(50),
        bottomLeft: const Radius.circular(50),
        topRight: const Radius.circular(8),
        bottomRight: const Radius.circular(8),
      ),
      activePaint,
    );
  }
}
