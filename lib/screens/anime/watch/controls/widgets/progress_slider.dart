import 'package:anymex/l10n/l10n_extension.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/seek_preview_card.dart';
import 'package:anymex/screens/anime/watch/chapters/models/playback_chapter.dart';
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/screens/anime/watch/controller/player_utils.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/controllers/watchium/watchium_service.dart';
import 'package:anymex/utils/aniskip.dart' as aniskip;
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/anymex_slider_m3.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

enum SliderStyle { defaultM3, capsule, ios, wavy }

SliderStyle parseSliderStyle(String value) {
  switch (value.toLowerCase()) {
    case 'wavy':
      return SliderStyle.wavy;
    case 'capsule':
      return SliderStyle.capsule;
    case 'ios':
      return SliderStyle.ios;
    case 'defaultm3':
    case 'default':
    default:
      return SliderStyle.defaultM3;
  }
}

class ProgressSlider extends StatefulWidget {
  final SliderStyle? style;
  final Color? activeTrackColor;
  final Color? inactiveTrackColor;
  final Color? secondaryActiveTrackColor;
  final Color? thumbColor;
  final Color? overlayColor;
  final Color? segmentColor;
  final Color? recapSegmentColor;

  const ProgressSlider({
    super.key,
    this.style,
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
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(canRequestFocus: false, skipTraversal: true);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _scheduleScrubbingEndCheck(PlayerController controller) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          (controller.isSeeking.value ||
              controller.scrubbingPosition.value != null)) {
        controller.onScrubbingEnd();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PlayerController>();
    final settings = Get.find<Settings>();
    final colorScheme = context.colors;

    return Obx(() {
      final duration = controller.episodeDuration.value.inMilliseconds;
      final scrubPos = controller.scrubbingPosition.value;
      final position = scrubPos?.inMilliseconds ??
          controller.currentPosition.value.inMilliseconds;
      final buffer = controller.bufferred.value.inMilliseconds;

      final maxValue = duration > 0 ? duration.toDouble() : 1.0;
      final clampedPosition = position.toDouble().clamp(0.0, maxValue);
      final clampedBuffer = buffer.toDouble().clamp(0.0, maxValue);

      final skipTimes = controller.skipTimes;
      final totalDuration = controller.episodeDuration.value;

      final effectiveStyle = settings.overrideSliderTheme
          ? parseSliderStyle(settings.progressSliderStyle)
          : (widget.style ?? parseSliderStyle(settings.progressSliderStyle));
      final isDefaultStyle = effectiveStyle == SliderStyle.defaultM3;
      final isWavyStyle = effectiveStyle == SliderStyle.wavy;
      final containerHeight = isWavyStyle ? 44.0 : 27.0;
      final markerSize = isDefaultStyle ? 15.0 : 4.0;

      bool isFollowMode() {
        try {
          final watchium = Get.find<WatchiumService>();
          return watchium.inRoom.value &&
              watchium.followHost.value &&
              !watchium.isHost.value;
        } catch (_) {
          return false;
        }
      }

      return IgnorePointer(
        ignoring: isFollowMode(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scrubPos = controller.scrubbingPosition.value;
            final engine = controller.seekPreviewEngine;
            const previewCardWidth = 160.0;
            final totalDurationMs = totalDuration.inMilliseconds;

            double? previewLeft;
            if (scrubPos != null &&
                totalDurationMs > 0 &&
                constraints.maxWidth > previewCardWidth) {
              final ratio =
                  (scrubPos.inMilliseconds / totalDurationMs).clamp(0.0, 1.0);
              final desiredCenter = ratio * constraints.maxWidth;
              previewLeft = (desiredCenter - (previewCardWidth / 2.0))
                  .clamp(0.0, constraints.maxWidth - previewCardWidth);
            }

            final isScrubbing = scrubPos != null;

            return Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) {
                controller.isSeeking.value = true;
              },
              onPointerUp: (_) => _scheduleScrubbingEndCheck(controller),
              onPointerCancel: (_) => _scheduleScrubbingEndCheck(controller),
              child: SizedBox(
                height: containerHeight,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  if (isWavyStyle)
                    M3ETheme(
                      data: M3ETheme.of(context).copyWith(
                        colorScheme: M3ETheme.of(context).colorScheme.copyWith(
                              primary: widget.activeTrackColor ??
                                  colorScheme.primary,
                              secondaryContainer: widget.inactiveTrackColor ??
                                  colorScheme.surfaceContainerHighest
                                      .opaque(0.5, iReallyMeanIt: true),
                            ),
                      ),
                      child: M3ESlider.wavy(
                        value: clampedPosition,
                        min: 0,
                        max: maxValue,
                        size: M3ESliderSize.xs,
                        wavelength: 40,
                        trackThickness: 8,
                        thumbLength: 30,
                        amplitude: 1,
                        enabled: true,
                        semanticLabel: context.l10n.playback,
                        focusNode: _focusNode,
                        onChanged: (double value) {
                          controller.onScrubbingUpdate(
                              Duration(milliseconds: value.toInt()));
                        },
                        onChangeEnd: (double value) {
                          controller.onScrubbingEnd();
                        },
                      ),
                    )
                  else if (isDefaultStyle)
                    AnymeXSliderM3(
                      theme: AnymeXSliderM3Theme(
                        trackHeight: 15,
                        thumbHeight: 20,
                        activeColor: widget.activeTrackColor,
                        inactiveColor: widget.inactiveTrackColor,
                        secondaryActiveColor: widget.secondaryActiveTrackColor,
                      ),
                      label: isScrubbing
                          ? null
                          : PlayerUtils.formatDuration(
                              Duration(milliseconds: position)),
                      showValueIndicator: !isScrubbing,
                      divisions: null,
                      focusNode: _focusNode,
                      min: 0,
                      value: clampedPosition,
                      max: maxValue,
                      secondaryTrackValue: clampedBuffer,
                      onChangeStart: (v) {
                        controller.onScrubbingUpdate(
                            Duration(milliseconds: v.toInt()));
                      },
                      onChanged: (v) => controller
                          .onScrubbingUpdate(Duration(milliseconds: v.toInt())),
                      onChangeEnd: (v) {
                        controller.onScrubbingEnd();
                      },
                    )
                  else
                    SliderTheme(
                      data: _getSliderTheme(colorScheme, effectiveStyle,
                          isScrubbing: isScrubbing),
                      child: Slider(
                        focusNode: _focusNode,
                        min: 0,
                        value: clampedPosition,
                        max: maxValue,
                        secondaryTrackValue: clampedBuffer,
                        label: isScrubbing
                            ? null
                            : PlayerUtils.formatDuration(
                                Duration(milliseconds: position)),
                        onChangeStart: (v) {
                          controller.onScrubbingUpdate(
                              Duration(milliseconds: v.toInt()));
                        },
                        onChanged: (v) => controller.onScrubbingUpdate(
                            Duration(milliseconds: v.toInt())),
                        onChangeEnd: (v) {
                          controller.onScrubbingEnd();
                        },
                      ),
                    ),
                  if (totalDuration.inMilliseconds > 0)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: SkipTimelinePainter(
                            skipTimes: skipTimes,
                            skipSegments: controller.skipSegments.toList(),
                            chapters: controller.chapters.toList(),
                            totalDuration: totalDuration,
                            currentPosition: Duration(
                              milliseconds: clampedPosition.toInt(),
                            ),
                            markerHeight: markerSize,
                            horizontalPadding: isWavyStyle ? 4.0 : 0.0,
                            hideUnderThumb: effectiveStyle != SliderStyle.ios,
                            segmentColor: widget.segmentColor,
                            recapSegmentColor: widget.recapSegmentColor,
                          ),
                        ),
                      ),
                    ),
                  if (previewLeft != null && scrubPos != null && engine != null)
                    Positioned(
                      left: previewLeft,
                      bottom: containerHeight + 14.0,
                      child: IgnorePointer(
                        child: SeekPreviewCard(
                          engine: engine,
                          position: scrubPos,
                          chapterTitle: controller.getChapterTitleAt(scrubPos),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
          },
        ),
      );
    });
  }

  SliderThemeData _getSliderTheme(
    ColorScheme colorScheme,
    SliderStyle style, {
    bool isScrubbing = false,
  }) {
    final indicator =
        isScrubbing ? ShowValueIndicator.never : ShowValueIndicator.always;

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
          showValueIndicator: indicator,
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
          showValueIndicator: indicator,
        );
      case SliderStyle.wavy:
      case SliderStyle.defaultM3:
        return SliderThemeData(
          showValueIndicator: indicator,
        );
    }
  }
}

class SkipTimelinePainter extends CustomPainter {
  final aniskip.EpisodeSkipTimes? skipTimes;
  final List<PlaybackSkipSegment> skipSegments;
  final List<PlaybackChapter> chapters;
  final Duration totalDuration;
  final Duration currentPosition;
  final bool hideUnderThumb;
  final Color? segmentColor;
  final Color? recapSegmentColor;
  final double markerHeight;
  final double horizontalPadding;
  static const Color _defaultSegmentColor = Color(0xFFEBC125);
  static const Color _defaultRecapColor = Color(0xFF4CAF50);

  const SkipTimelinePainter({
    this.skipTimes,
    this.skipSegments = const [],
    this.chapters = const [],
    required this.totalDuration,
    required this.currentPosition,
    required this.hideUnderThumb,
    this.markerHeight = 4.0,
    this.horizontalPadding = 0.0,
    this.segmentColor,
    this.recapSegmentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (totalDuration.inMilliseconds <= 0) return;

    final double availableWidth =
        (size.width - (horizontalPadding * 2)).clamp(0.0, double.infinity);
    final double totalSeconds = totalDuration.inMilliseconds / 1000.0;
    final Paint paint = Paint()..style = PaintingStyle.fill;
    const double thumbCutoutHalfWidth = 5.0;
    final double yOffset = (size.height - markerHeight) / 2;
    final double progressSeconds =
        (currentPosition.inMilliseconds / 1000.0).clamp(0.0, totalSeconds);
    final double thumbX = totalSeconds > 0
        ? horizontalPadding + (progressSeconds / totalSeconds) * availableWidth
        : horizontalPadding;

    void drawSegment(double startX, double endX, Color color) {
      final double clampedStart =
          startX.clamp(horizontalPadding, size.width - horizontalPadding);
      final double clampedEnd =
          endX.clamp(horizontalPadding, size.width - horizontalPadding);
      final double width = clampedEnd - clampedStart;
      if (width <= 0) return;

      paint.color = color;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(clampedStart, yOffset, width, markerHeight),
          Radius.circular(markerHeight / 2),
        ),
        paint,
      );
    }

    void drawInterval(double startSec, double endSec, {Color? colorOverride}) {
      final double startX =
          horizontalPadding + (startSec / totalSeconds) * availableWidth;
      final double endX =
          horizontalPadding + (endSec / totalSeconds) * availableWidth;
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

    if (skipTimes != null) {
      if (skipTimes!.recap != null) {
        drawInterval(
          skipTimes!.recap!.start.toDouble(),
          skipTimes!.recap!.end.toDouble(),
          colorOverride: recapSegmentColor ?? _defaultRecapColor,
        );
      }
      if (skipTimes!.op != null) {
        drawInterval(
          skipTimes!.op!.start.toDouble(),
          skipTimes!.op!.end.toDouble(),
        );
      }
      if (skipTimes!.ed != null) {
        drawInterval(
          skipTimes!.ed!.start.toDouble(),
          skipTimes!.ed!.end.toDouble(),
        );
      }
    } else if (skipSegments.isNotEmpty) {
      for (final seg in skipSegments) {
        final color = seg.kind == PlaybackSegmentKind.recap
            ? (recapSegmentColor ?? _defaultRecapColor)
            : (segmentColor ?? _defaultSegmentColor);
        drawInterval(seg.startSeconds, seg.endSeconds, colorOverride: color);
      }
    }

    if (chapters.isNotEmpty) {
      final tickPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.fill;
      for (final ch in chapters) {
        final tickX = horizontalPadding +
            (ch.startSeconds / totalSeconds) * availableWidth;
        if (tickX > horizontalPadding + 3 &&
            tickX < size.width - horizontalPadding - 3) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(tickX - 1.0, yOffset - 1, 2.0, markerHeight + 2),
              const Radius.circular(1),
            ),
            tickPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant SkipTimelinePainter oldDelegate) {
    return oldDelegate.skipTimes != skipTimes ||
        oldDelegate.skipSegments != skipSegments ||
        oldDelegate.chapters != chapters ||
        oldDelegate.totalDuration != totalDuration ||
        oldDelegate.currentPosition != currentPosition ||
        oldDelegate.hideUnderThumb != hideUnderThumb ||
        oldDelegate.markerHeight != markerHeight ||
        oldDelegate.horizontalPadding != horizontalPadding ||
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

class ProgressSliderPreview extends StatelessWidget {
  final SliderStyle style;

  const ProgressSliderPreview({super.key, required this.style});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    final isWavy = style == SliderStyle.wavy;
    final isDefault = style == SliderStyle.defaultM3;

    if (isWavy) {
      return SizedBox(
        height: 32,
        child: M3ETheme(
          data: M3ETheme.of(context).copyWith(
            colorScheme: M3ETheme.of(context).colorScheme.copyWith(
                  primary: colorScheme.primary,
                  secondaryContainer:
                      colorScheme.surfaceContainerHighest.opaque(0.5, iReallyMeanIt: true),
                ),
          ),
          child: M3ESlider.wavy(
            value: 0.45,
            min: 0,
            max: 1,
            size: M3ESliderSize.xs,
            wavelength: 32,
            trackThickness: 6,
            thumbLength: 22,
            amplitude: 1,
            enabled: true,
            semanticLabel: 'Preview',
            onChanged: (_) {},
          ),
        ),
      );
    }

    if (isDefault) {
      return SizedBox(
        height: 26,
        child: AnymeXSliderM3(
          theme: const AnymeXSliderM3Theme(
            trackHeight: 12,
            thumbHeight: 18,
          ),
          showValueIndicator: false,
          min: 0,
          value: 0.45,
          max: 1,
          secondaryTrackValue: 0.72,
          onChanged: (_) {},
        ),
      );
    }

    final sliderTheme = style == SliderStyle.ios
        ? SliderThemeData(
            trackHeight: 5,
            thumbShape: SliderComponentShape.noThumb,
            trackShape: const IOSSliderTrackShape(),
            activeTrackColor: colorScheme.primary,
            inactiveTrackColor:
                colorScheme.onSurface.opaque(0.2, iReallyMeanIt: true),
            secondaryActiveTrackColor:
                colorScheme.onSurface.opaque(0.35, iReallyMeanIt: true),
            overlayColor: Colors.transparent,
            showValueIndicator: ShowValueIndicator.never,
          )
        : SliderThemeData(
            trackHeight: 7,
            thumbShape: const CapsuleThumb(
              width: 5,
              height: 20,
              pressedHeight: 22,
            ),
            trackShape: CapsuleSliderTrack(),
            activeTrackColor: colorScheme.primary,
            inactiveTrackColor: colorScheme.surfaceContainerHighest
                .opaque(0.5, iReallyMeanIt: true),
            secondaryActiveTrackColor:
                colorScheme.onSurface.opaque(0.3, iReallyMeanIt: true),
            thumbColor: colorScheme.onPrimary,
            overlayColor: Colors.transparent,
            showValueIndicator: ShowValueIndicator.never,
          );

    return SizedBox(
      height: 26,
      child: SliderTheme(
        data: sliderTheme,
        child: Slider(
          min: 0,
          max: 1,
          value: 0.45,
          secondaryTrackValue: 0.72,
          onChanged: (_) {},
        ),
      ),
    );
  }
}
