import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/screens/anime/watch/controller/player_utils.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum SliderStyle { capsule, ios }

class ProgressSlider extends StatefulWidget {
  final SliderStyle style;

  const ProgressSlider({
    super.key,
    this.style = SliderStyle.capsule,
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
            divisions: widget.style == SliderStyle.ios
                ? null
                : duration <= 0
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
      case SliderStyle.ios:
        return SliderThemeData(
          trackHeight: 5,
          thumbShape: SliderComponentShape.noThumb,
          trackShape: const IOSSliderTrackShape(),
          activeTrackColor: Colors.white,
          inactiveTrackColor: Colors.white.withOpacity(0.2),
          secondaryActiveTrackColor: Colors.white.withOpacity(0.4),
          overlayColor: Colors.transparent,
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

class IOSSliderTrackShape extends SliderTrackShape with BaseSliderTrackShape {
  const IOSSliderTrackShape();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 4;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;

    return Rect.fromLTWH(
        offset.dx, trackTop, parentBox.size.width, trackHeight);
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
    double additionalActiveTrackHeight = 0,
  }) {
    final Canvas canvas = context.canvas;
    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final double trackRadius = trackRect.height / 2;
    final Radius radius = Radius.circular(trackRadius);

    final Paint inactivePaint = Paint()
      ..color = sliderTheme.inactiveTrackColor!;
    canvas.drawRRect(RRect.fromRectAndRadius(trackRect, radius), inactivePaint);

    if (secondaryOffset != null) {
      final Paint secondaryPaint = Paint()
        ..color = sliderTheme.secondaryActiveTrackColor!;
      final Rect secondaryRect = Rect.fromLTRB(
        trackRect.left,
        trackRect.top,
        secondaryOffset.dx,
        trackRect.bottom,
      );

      canvas.drawRRect(
          RRect.fromRectAndRadius(secondaryRect, radius), secondaryPaint);
    }

    final Paint activePaint = Paint()..color = sliderTheme.activeTrackColor!;
    final Rect activeRect = Rect.fromLTRB(
      trackRect.left,
      trackRect.top,
      thumbCenter.dx,
      trackRect.bottom,
    );

    canvas.drawRRect(RRect.fromRectAndRadius(activeRect, radius), activePaint);
  }
}
