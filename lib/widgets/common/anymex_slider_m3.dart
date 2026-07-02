import 'package:flutter/material.dart';

@immutable
class AnymeXSliderM3Theme {
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? secondaryActiveColor;
  final double height;
  final double trackHeight;
  final double outerRadius;
  final double innerRadius;
  final double thumbGap;
  final double edgeInset;
  final double thumbWidth;
  final double thumbHeight;
  final double thumbCornerRadius;

  const AnymeXSliderM3Theme({
    this.activeColor,
    this.inactiveColor,
    this.secondaryActiveColor,
    this.height = 32,
    this.trackHeight = 32,
    this.outerRadius = 12,
    this.innerRadius = 2,
    this.thumbGap = 12,
    this.edgeInset = 6,
    this.thumbWidth = 4,
    this.thumbHeight = 40,
    this.thumbCornerRadius = 2,
  });

  AnymeXSliderM3Theme _resolve(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final resolvedActive = activeColor ?? scheme.primary;
    return AnymeXSliderM3Theme(
      activeColor: resolvedActive,
      inactiveColor: inactiveColor ?? resolvedActive.withOpacity(0.2),
      secondaryActiveColor:
          secondaryActiveColor ?? resolvedActive.withOpacity(0.4),
      height: height,
      trackHeight: trackHeight,
      outerRadius: outerRadius,
      innerRadius: innerRadius,
      thumbGap: thumbGap,
      edgeInset: edgeInset,
      thumbWidth: thumbWidth,
      thumbHeight: thumbHeight,
      thumbCornerRadius: thumbCornerRadius,
    );
  }

  AnymeXSliderM3Theme copyWith({
    Color? activeColor,
    Color? inactiveColor,
    Color? secondaryActiveColor,
    double? height,
    double? trackHeight,
    double? outerRadius,
    double? innerRadius,
    double? thumbGap,
    double? edgeInset,
    double? thumbWidth,
    double? thumbHeight,
    double? thumbCornerRadius,
  }) {
    return AnymeXSliderM3Theme(
      activeColor: activeColor ?? this.activeColor,
      inactiveColor: inactiveColor ?? this.inactiveColor,
      secondaryActiveColor: secondaryActiveColor ?? this.secondaryActiveColor,
      height: height ?? this.height,
      trackHeight: trackHeight ?? this.trackHeight,
      outerRadius: outerRadius ?? this.outerRadius,
      innerRadius: innerRadius ?? this.innerRadius,
      thumbGap: thumbGap ?? this.thumbGap,
      edgeInset: edgeInset ?? this.edgeInset,
      thumbWidth: thumbWidth ?? this.thumbWidth,
      thumbHeight: thumbHeight ?? this.thumbHeight,
      thumbCornerRadius: thumbCornerRadius ?? this.thumbCornerRadius,
    );
  }
}

class AnymeXSliderM3 extends StatelessWidget {
  final double value;
  final double? secondaryTrackValue;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;
  final double min;
  final double max;
  final int? divisions;
  final String? label;
  final FocusNode? focusNode;
  final AnymeXSliderM3Theme theme;

  const AnymeXSliderM3({
    super.key,
    required this.value,
    this.secondaryTrackValue,
    this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.label,
    this.focusNode,
    this.theme = const AnymeXSliderM3Theme(),
  });

  @override
  Widget build(BuildContext context) {
    final resolvedTheme = theme._resolve(context);

    return SliderTheme(
      data: SliderThemeData(
        trackHeight: resolvedTheme.trackHeight,
        activeTrackColor: resolvedTheme.activeColor,
        inactiveTrackColor: resolvedTheme.inactiveColor,
        secondaryActiveTrackColor: resolvedTheme.secondaryActiveColor,
        thumbColor: resolvedTheme.activeColor,
        overlayShape: SliderComponentShape.noOverlay,
        trackShape: _AnymeXSliderM3TrackShape(
          outerRadius: resolvedTheme.outerRadius,
          innerRadius: resolvedTheme.innerRadius,
          thumbGap: resolvedTheme.thumbGap,
          edgeInset: resolvedTheme.edgeInset,
        ),
        thumbShape: _AnymeXSliderM3ThumbShape(
          width: resolvedTheme.thumbWidth,
          height: resolvedTheme.thumbHeight,
          cornerRadius: resolvedTheme.thumbCornerRadius,
        ),
        tickMarkShape: SliderTickMarkShape.noTickMark,
        padding: EdgeInsets.zero,
      ),
      child: Slider(
        focusNode:
            focusNode ?? FocusNode(canRequestFocus: false, skipTraversal: true),
        value: value,
        secondaryTrackValue: secondaryTrackValue,
        onChanged: onChanged,
        onChangeStart: onChangeStart,
        onChangeEnd: onChangeEnd,
        min: min,
        max: max,
        divisions: divisions ?? (max * 10).toInt(),
        label: label ?? value.toStringAsFixed(1),
      ),
    );
  }
}

class _AnymeXSliderM3TrackShape extends SliderTrackShape {
  const _AnymeXSliderM3TrackShape({
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

    if (secondaryOffset != null &&
        sliderTheme.secondaryActiveTrackColor != null) {
      final secondaryX = secondaryOffset.dx.clamp(
        baseTrackRect.left,
        baseTrackRect.right,
      );
      final secondaryRect = Rect.fromLTRB(
        baseTrackRect.left,
        baseTrackRect.top,
        secondaryX,
        baseTrackRect.bottom,
      );
      if (secondaryRect.width > 0) {
        _paintSegment(
          canvas: canvas,
          segmentRect: secondaryRect,
          color: sliderTheme.secondaryActiveTrackColor!,
          startRadius: outerRadius,
          endRadius: innerRadius,
          anchorToStart: true,
        );
      }
    }

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

class _AnymeXSliderM3ThumbShape extends SliderComponentShape {
  const _AnymeXSliderM3ThumbShape({
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
