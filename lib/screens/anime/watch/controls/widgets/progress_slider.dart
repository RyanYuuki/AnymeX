import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/screens/anime/watch/controller/player_utils.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum SliderStyle {
  regular,
  modern,
  minimal,
  capsule,
}

class ProgressSlider extends StatefulWidget {
  final SliderStyle style;

  const ProgressSlider({
    super.key,
    this.style = SliderStyle.modern,
  });

  @override
  State<ProgressSlider> createState() => _ProgressSliderState();
}

class _ProgressSliderState extends State<ProgressSlider> {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PlayerController>();
    final colorScheme = context.colors;

    return Obx(() {
      final duration = controller.episodeDuration.value.inMilliseconds;
      final position = controller.currentPosition.value.inMilliseconds;
      final buffer = controller.bufferred.value.inMilliseconds;
      final fullDuration = Duration(milliseconds: duration);
      
      final maxValue = duration > 0 ? duration.toDouble() : 1.0;
      final clampedPosition = position.toDouble().clamp(0.0, maxValue);
      final clampedBuffer = buffer.toDouble().clamp(0.0, maxValue);

      return SizedBox(
        height: 27,
        child: SliderTheme(
          data: _getSliderTheme(colorScheme, widget.style),
          child: Slider(
            year2023: false,
            label: PlayerUtils.formatDuration(Duration(milliseconds: position)),
            divisions: duration <= 0
                ? 1
                : fullDuration.inSeconds < 60
                    ? fullDuration.inSeconds
                    : Duration(milliseconds: duration).inSeconds ~/ 10,
            focusNode: FocusNode(canRequestFocus: false, skipTraversal: true),
            min: 0,
            value: clampedPosition,
            max: maxValue,
            secondaryTrackValue: clampedBuffer,
            onChangeStart: (v) => controller.isSeeking.value = true,
            onChanged: (v) =>
                controller.seekTo(Duration(milliseconds: v.toInt())),
            onChangeEnd: (v) {
              controller.isSeeking.value = false;
            },
          ),
        ),
      );
    });
  }

  SliderThemeData _getSliderTheme(ColorScheme colorScheme, SliderStyle style) {
    switch (style) {
      case SliderStyle.regular:
        return SliderThemeData(
          trackHeight: 4,
          thumbShape: const CircularSliderThumb(
            enabledThumbRadius: 12,
            pressedThumbRadius: 15,
          ),
          trackShape: ModernSliderTrack(),
          activeTrackColor: colorScheme.primary,
          inactiveTrackColor: colorScheme.surfaceContainerHighest
              .opaque(0.4, iReallyMeanIt: true),
          secondaryActiveTrackColor:
              colorScheme.onSurface.opaque(0.3, iReallyMeanIt: true),
          thumbColor: colorScheme.primary,
          overlayColor: colorScheme.primary.opaque(0.12, iReallyMeanIt: true),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
        );

      case SliderStyle.modern:
        return SliderThemeData(
          trackHeight: 5,
          thumbShape: const ModernLineThumb(
            width: 4,
            height: 20,
            pressedHeight: 24,
          ),
          trackShape: ModernSliderTrack(),
          activeTrackColor: colorScheme.primary,
          inactiveTrackColor: colorScheme.surfaceContainerHighest
              .opaque(0.3, iReallyMeanIt: true),
          secondaryActiveTrackColor:
              colorScheme.onSurface.opaque(0.25, iReallyMeanIt: true),
          thumbColor: colorScheme.primary,
          overlayColor: colorScheme.primary.opaque(0.1, iReallyMeanIt: true),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        );

      case SliderStyle.minimal:
        return SliderThemeData(
          trackHeight: 2,
          thumbShape: const MinimalThumb(
            size: 16,
            pressedSize: 20,
          ),
          trackShape: MinimalSliderTrack(),
          activeTrackColor: colorScheme.primary,
          inactiveTrackColor:
              colorScheme.onSurface.opaque(0.2, iReallyMeanIt: true),
          secondaryActiveTrackColor:
              colorScheme.onSurface.opaque(0.15, iReallyMeanIt: true),
          thumbColor: colorScheme.surface,
          overlayColor: colorScheme.primary.opaque(0.08, iReallyMeanIt: true),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
        );

      case SliderStyle.capsule:
        return SliderThemeData(
          trackHeight: 8,
          thumbShape: const CapsuleThumb(
            width: 6,
            height: 24,
            pressedHeight: 28,
          ),
          trackShape: CapsuleSliderTrack(),
          activeTrackColor: colorScheme.primary,
          inactiveTrackColor: colorScheme.surfaceContainerHighest
              .opaque(0.5, iReallyMeanIt: true),
          secondaryActiveTrackColor:
              colorScheme.onSurface.opaque(0.3, iReallyMeanIt: true),
          thumbColor: colorScheme.surface,
          overlayColor: colorScheme.primary.opaque(0.1, iReallyMeanIt: true),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
        );
    }
  }
}

class CircularSliderThumb extends SliderComponentShape {
  const CircularSliderThumb({
    this.enabledThumbRadius = 8.0,
    this.pressedThumbRadius = 10.0,
    this.disabledThumbRadius = 6.0,
  });

  final double enabledThumbRadius;
  final double pressedThumbRadius;
  final double disabledThumbRadius;

  double get _thumbRadius => enabledThumbRadius;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(_thumbRadius);
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
    final Canvas canvas = context.canvas;
    final double radius = enabledThumbRadius +
        (pressedThumbRadius - enabledThumbRadius) * activationAnimation.value;

    final Paint shadowPaint = Paint()
      ..color = Colors.black.opaque(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawCircle(center + const Offset(0, 1), radius + 2, shadowPaint);

    final Paint thumbPaint = Paint()
      ..color = sliderTheme.thumbColor ?? Colors.red
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, thumbPaint);

    final Paint highlightPaint = Paint()
      ..color = Colors.white.opaque(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
        center - const Offset(2, 2), radius * 0.4, highlightPaint);

    final Paint ringPaint = Paint()
      ..color = Colors.white.opaque(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius - 1, ringPaint);
  }
}

class ModernLineThumb extends SliderComponentShape {
  const ModernLineThumb({
    this.width = 4.0,
    this.height = 20.0,
    this.pressedHeight = 24.0,
  });

  final double width;
  final double height;
  final double pressedHeight;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size(width + 4, height + 4);
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
    final Canvas canvas = context.canvas;
    final double currentHeight =
        height + (pressedHeight - height) * activationAnimation.value;

    final Paint shadowPaint = Paint()
      ..color = Colors.black.opaque(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

    final RRect shadowRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center + const Offset(0, 1),
        width: width + 1,
        height: currentHeight + 1,
      ),
      Radius.circular(width / 2),
    );
    canvas.drawRRect(shadowRect, shadowPaint);

    final Rect thumbRect = Rect.fromCenter(
      center: center,
      width: width,
      height: currentHeight,
    );

    final Paint thumbPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.opaque(0.9),
          sliderTheme.thumbColor ?? Colors.white,
          (sliderTheme.thumbColor ?? Colors.white).opaque(0.8),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(thumbRect);

    final RRect thumbRRect = RRect.fromRectAndRadius(
      thumbRect,
      Radius.circular(width / 2),
    );
    canvas.drawRRect(thumbRRect, thumbPaint);

    final Paint borderPaint = Paint()
      ..color = sliderTheme.thumbColor?.opaque(0.3) ?? Colors.white.opaque(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawRRect(thumbRRect, borderPaint);
  }
}

class MinimalThumb extends SliderComponentShape {
  const MinimalThumb({
    this.size = 16.0,
    this.pressedSize = 20.0,
  });

  final double size;
  final double pressedSize;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(size / 2 + 2);
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
    final Canvas canvas = context.canvas;
    final double currentSize =
        size + (pressedSize - size) * activationAnimation.value;
    final double radius = currentSize / 2;

    final Paint outerPaint = Paint()
      ..color = sliderTheme.activeTrackColor ?? Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius, outerPaint);

    final Paint innerPaint = Paint()
      ..color = sliderTheme.thumbColor ?? Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 3, innerPaint);
  }
}

class CapsuleThumb extends SliderComponentShape {
  const CapsuleThumb({
    this.width = 6.0,
    this.height = 24.0,
    this.pressedHeight = 28.0,
  });

  final double width;
  final double height;
  final double pressedHeight;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size(width + 6, height + 4);
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
    final Canvas canvas = context.canvas;
    final double currentHeight =
        height + (pressedHeight - height) * activationAnimation.value;

    final Paint shadowPaint = Paint()
      ..color = Colors.black.opaque(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    final RRect shadowRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center + const Offset(0, 0.5),
        width: width + 1,
        height: currentHeight + 1,
      ),
      Radius.circular(width / 2),
    );
    canvas.drawRRect(shadowRect, shadowPaint);

    final Paint thumbPaint = Paint()
      ..color = sliderTheme.thumbColor ?? Colors.white
      ..style = PaintingStyle.fill;

    final RRect thumbRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: width,
        height: currentHeight,
      ),
      Radius.circular(width / 2),
    );
    canvas.drawRRect(thumbRRect, thumbPaint);

    final Paint borderPaint = Paint()
      ..color =
          sliderTheme.activeTrackColor?.opaque(0.5) ?? Colors.blue.opaque(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(thumbRRect, borderPaint);
  }
}

class ModernSliderTrack extends SliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 4;
    final double trackLeft = offset.dx;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
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
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isEnabled = false,
    bool isDiscrete = false,
    double additionalActiveTrackHeight = 2,
  }) {
    final Canvas canvas = context.canvas;
    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final double trackHeight = sliderTheme.trackHeight ?? 4;
    final double trackRadius = trackHeight / 2;

    final Paint inactiveTrackPaint = Paint()
      ..color = sliderTheme.inactiveTrackColor ?? Colors.white.opaque(0.3)
      ..style = PaintingStyle.fill;

    final RRect trackRRect = RRect.fromRectAndRadius(
      trackRect,
      Radius.circular(trackRadius),
    );
    canvas.drawRRect(trackRRect, inactiveTrackPaint);

    if (secondaryOffset != null) {
      final double secondaryTrackRight = secondaryOffset.dx;
      final Rect secondaryTrackRect = Rect.fromLTRB(
        trackRect.left,
        trackRect.top,
        secondaryTrackRight,
        trackRect.bottom,
      );

      final Paint secondaryTrackPaint = Paint()
        ..color =
            sliderTheme.secondaryActiveTrackColor ?? Colors.white.opaque(0.5)
        ..style = PaintingStyle.fill;

      final RRect secondaryTrackRRect = RRect.fromRectAndRadius(
        secondaryTrackRect,
        Radius.circular(trackRadius),
      );
      canvas.drawRRect(secondaryTrackRRect, secondaryTrackPaint);
    }

    final double activeTrackRight = thumbCenter.dx;
    final Rect activeTrackRect = Rect.fromLTRB(
      trackRect.left,
      trackRect.top,
      activeTrackRight,
      trackRect.bottom,
    );

    final Paint activeTrackPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          sliderTheme.activeTrackColor ?? Colors.red,
          (sliderTheme.activeTrackColor ?? Colors.red).opaque(0.8),
        ],
        stops: const [0.0, 1.0],
      ).createShader(activeTrackRect)
      ..style = PaintingStyle.fill;

    final RRect activeTrackRRect = RRect.fromRectAndRadius(
      activeTrackRect,
      Radius.circular(trackRadius),
    );
    canvas.drawRRect(activeTrackRRect, activeTrackPaint);
  }
}

class MinimalSliderTrack extends SliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 2;
    final double trackLeft = offset.dx;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
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
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isEnabled = false,
    bool isDiscrete = false,
    double additionalActiveTrackHeight = 2,
  }) {
    final Canvas canvas = context.canvas;
    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final double trackHeight = sliderTheme.trackHeight ?? 2;

    final Paint inactiveTrackPaint = Paint()
      ..color = sliderTheme.inactiveTrackColor ?? Colors.white.opaque(0.2)
      ..strokeWidth = trackHeight
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(trackRect.left, trackRect.center.dy),
      Offset(trackRect.right, trackRect.center.dy),
      inactiveTrackPaint,
    );

    if (secondaryOffset != null) {
      final Paint secondaryTrackPaint = Paint()
        ..color =
            sliderTheme.secondaryActiveTrackColor ?? Colors.white.opaque(0.15)
        ..strokeWidth = trackHeight
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(trackRect.left, trackRect.center.dy),
        Offset(secondaryOffset.dx, trackRect.center.dy),
        secondaryTrackPaint,
      );
    }

    final Paint activeTrackPaint = Paint()
      ..color = sliderTheme.activeTrackColor ?? Colors.blue
      ..strokeWidth = trackHeight
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(trackRect.left, trackRect.center.dy),
      Offset(thumbCenter.dx, trackRect.center.dy),
      activeTrackPaint,
    );
  }
}

class CapsuleSliderTrack extends SliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 8;
    final double trackLeft = offset.dx;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
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
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isEnabled = false,
    bool isDiscrete = false,
    double additionalActiveTrackHeight = 2,
  }) {
    final Canvas canvas = context.canvas;
    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final double trackHeight = sliderTheme.trackHeight ?? 8;
    final double trackRadius = trackHeight / 2;

    final Paint inactiveTrackPaint = Paint()
      ..color = sliderTheme.inactiveTrackColor ?? Colors.white.opaque(0.5)
      ..style = PaintingStyle.fill;

    final RRect trackRRect = RRect.fromRectAndRadius(
      trackRect,
      Radius.circular(trackRadius),
    );
    canvas.drawRRect(trackRRect, inactiveTrackPaint);

    final Paint shadowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.black.opaque(0.1),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3],
      ).createShader(trackRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          trackRect.left,
          trackRect.top,
          trackRect.right,
          trackRect.top + trackHeight * 0.4,
        ),
        Radius.circular(trackRadius),
      ),
      shadowPaint,
    );

    if (secondaryOffset != null) {
      final double secondaryTrackRight = secondaryOffset.dx;
      final Rect secondaryTrackRect = Rect.fromLTRB(
        trackRect.left,
        trackRect.top,
        secondaryTrackRight,
        trackRect.bottom,
      );

      final Paint secondaryTrackPaint = Paint()
        ..color =
            sliderTheme.secondaryActiveTrackColor ?? Colors.white.opaque(0.3)
        ..style = PaintingStyle.fill;

      final RRect secondaryTrackRRect = RRect.fromRectAndRadius(
        secondaryTrackRect,
        Radius.circular(trackRadius),
      );
      canvas.drawRRect(secondaryTrackRRect, secondaryTrackPaint);
    }

    final double activeTrackRight = thumbCenter.dx;
    final Rect activeTrackRect = Rect.fromLTRB(
      trackRect.left,
      trackRect.top,
      activeTrackRight,
      trackRect.bottom,
    );

    final Paint activeTrackPaint = Paint()
      ..color = sliderTheme.activeTrackColor ?? Colors.blue
      ..style = PaintingStyle.fill;

    final RRect activeTrackRRect = RRect.fromRectAndRadius(
      activeTrackRect,
      Radius.circular(trackRadius),
    );
    canvas.drawRRect(activeTrackRRect, activeTrackPaint);
  }
}
