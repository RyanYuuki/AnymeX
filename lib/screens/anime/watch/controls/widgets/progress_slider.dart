import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/screens/anime/watch/controller/player_utils.dart';
import 'package:anymex/utils/aniskip.dart' as aniskip;
import 'package:anymex/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum SliderStyle { capsule, ios }

class ProgressSlider extends StatefulWidget {
  final SliderStyle style;
  final Color? activeTrackColor;
  final Color? inactiveTrackColor;
  final Color? secondaryActiveTrackColor;
  final Color? thumbColor;
  final Color? overlayColor;
  final Color? segmentColor;
  final Color? recapSegmentColor;

  const ProgressSlider({
    super.key,
    this.style = SliderStyle.capsule,
    this.activeTrackColor,
    this.inactiveTrackColor,
    this.secondaryActiveTrackColor,
    this.thumbColor,
    this.overlayColor,
    this.segmentColor,
    this.recapSegmentColor,
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

      final maxValue = duration > 0 ? duration.toDouble() : 1.0;
      final clampedPosition = position.toDouble().clamp(0.0, maxValue);
      final clampedBuffer = buffer.toDouble().clamp(0.0, maxValue);

      final skipTimes = controller.skipTimes;
      final totalDuration = controller.episodeDuration.value;

      return SizedBox(
        height: 27,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SliderTheme(
              data: _getSliderTheme(colorScheme, widget.style),
              child: Slider(
                year2023: false,
                label: PlayerUtils.formatDuration(
                    Duration(milliseconds: position)),
                divisions: null,
                focusNode:
                    FocusNode(canRequestFocus: false, skipTraversal: true),
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
            if (skipTimes != null && totalDuration.inMilliseconds > 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: SkipTimelinePainter(
                      skipTimes: skipTimes,
                      totalDuration: totalDuration,
                      currentPosition: Duration(
                        milliseconds: clampedPosition.toInt(),
                      ),
                      hideUnderThumb: widget.style != SliderStyle.ios,
                      segmentColor: widget.segmentColor,
                      recapSegmentColor: widget.recapSegmentColor,
                    ),
                  ),
                ),
              ),
          ],
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
          activeTrackColor: widget.activeTrackColor ?? Colors.white,
          inactiveTrackColor:
              widget.inactiveTrackColor ?? Colors.white.withOpacity(0.2),
          secondaryActiveTrackColor:
              widget.secondaryActiveTrackColor ?? Colors.white.withOpacity(0.4),
          thumbColor: widget.thumbColor,
          overlayColor: widget.overlayColor ?? Colors.transparent,
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
          activeTrackColor: widget.activeTrackColor ?? colorScheme.primary,
          inactiveTrackColor: widget.inactiveTrackColor ??
              colorScheme.surfaceContainerHighest
                  .opaque(0.5, iReallyMeanIt: true),
          secondaryActiveTrackColor: widget.secondaryActiveTrackColor ??
              colorScheme.onSurface.opaque(0.3, iReallyMeanIt: true),
          thumbColor: widget.thumbColor ?? Colors.white,
          overlayColor: widget.overlayColor ??
              colorScheme.primary.opaque(0.1, iReallyMeanIt: true),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
        );
    }
  }
}

class SkipTimelinePainter extends CustomPainter {
  final aniskip.EpisodeSkipTimes skipTimes;
  final Duration totalDuration;
  final Duration currentPosition;
  final bool hideUnderThumb;
  final Color? segmentColor;
  final Color? recapSegmentColor;
  static const Color _defaultSegmentColor = Color(0xFFEBC125);
  static const Color _defaultRecapColor = Color(0xFF4CAF50);

  const SkipTimelinePainter({
    required this.skipTimes,
    required this.totalDuration,
    required this.currentPosition,
    required this.hideUnderThumb,
    this.segmentColor,
    this.recapSegmentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (totalDuration.inMilliseconds <= 0) return;

    final double totalSeconds = totalDuration.inMilliseconds / 1000.0;
    final Paint paint = Paint()..style = PaintingStyle.fill;
    const double markerHeight = 4.0;
    const double thumbCutoutHalfWidth = 5.0;
    final double yOffset = (size.height - markerHeight) / 2;
    final double progressSeconds =
        (currentPosition.inMilliseconds / 1000.0).clamp(0.0, totalSeconds);
    final double thumbX =
        totalSeconds > 0 ? (progressSeconds / totalSeconds) * size.width : 0.0;

    void drawSegment(double startX, double endX, Color color) {
      final double clampedStart = startX.clamp(0.0, size.width);
      final double clampedEnd = endX.clamp(0.0, size.width);
      final double width = clampedEnd - clampedStart;
      if (width <= 0) return;

      paint.color = color;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(clampedStart, yOffset, width, markerHeight),
          const Radius.circular(2),
        ),
        paint,
      );
    }

    void drawInterval(aniskip.SkipIntervals? interval, {Color? colorOverride}) {
      if (interval == null) return;
      final double startX = (interval.start / totalSeconds) * size.width;
      final double endX = (interval.end / totalSeconds) * size.width;
      final Color color = colorOverride ?? segmentColor ?? _defaultSegmentColor;

      if (!hideUnderThumb) {
        drawSegment(startX, endX, color);
        return;
      }

      final double cutoutStart = thumbX - thumbCutoutHalfWidth;
      final double cutoutEnd = thumbX + thumbCutoutHalfWidth;
      if (cutoutEnd <= startX || cutoutStart >= endX) {
        drawSegment(startX, endX, color);
        return;
      }

      drawSegment(startX, cutoutStart, color);
      drawSegment(cutoutEnd, endX, color);
    }

    drawInterval(skipTimes.recap,
        colorOverride: recapSegmentColor ?? _defaultRecapColor);
    drawInterval(skipTimes.op);
    drawInterval(skipTimes.ed);
  }

  @override
  bool shouldRepaint(covariant SkipTimelinePainter oldDelegate) {
    return oldDelegate.skipTimes != skipTimes ||
        oldDelegate.totalDuration != totalDuration ||
        oldDelegate.currentPosition != currentPosition ||
        oldDelegate.hideUnderThumb != hideUnderThumb ||
        oldDelegate.segmentColor != segmentColor ||
        oldDelegate.recapSegmentColor != recapSegmentColor;
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
