import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide CustomProgressIndicatorThemeData;

abstract class ProgressIndicator extends StatefulWidget {
  const ProgressIndicator({
    super.key,
    this.value,
    this.backgroundColor,
    this.color,
    this.valueColor,
    this.semanticsLabel,
    this.semanticsValue,
  });

  /// If non-null, the value of this progress indicator.
  ///
  /// A value of 0.0 means no progress and 1.0 means that progress is complete.
  /// The value will be clamped to be in the range 0.0-1.0.
  ///
  /// If null, this progress indicator is indeterminate, which means the
  /// indicator displays a predetermined animation that does not indicate how
  /// much actual progress is being made.
  final double? value;

  /// The progress indicator's background color.
  ///
  /// It is up to the subclass to implement this in whatever way makes sense
  /// for the given use case. See the subclass documentation for details.
  final Color? backgroundColor;

  /// {@template flutter.progress_indicator.ProgressIndicator.color}
  /// The progress indicator's color.
  ///
  /// This is only used if [ProgressIndicator.valueColor] is null.
  /// If [ProgressIndicator.color] is also null, then the ambient
  /// [CustomProgressIndicatorThemeData.color] will be used. If that
  /// is null then the current theme's [ColorScheme.primary] will
  /// be used by default.
  /// {@endtemplate}
  final Color? color;

  /// The progress indicator's color as an animated value.
  ///
  /// If null, the progress indicator is rendered with [color]. If that is null,
  /// then it will use the ambient [CustomProgressIndicatorThemeData.color]. If that
  /// is also null then it defaults to the current theme's [ColorScheme.primary].
  final Animation<Color?>? valueColor;

  /// {@template flutter.progress_indicator.ProgressIndicator.semanticsLabel}
  /// The [SemanticsProperties.label] for this progress indicator.
  ///
  /// This value indicates the purpose of the progress bar, and will be
  /// read out by screen readers to indicate the purpose of this progress
  /// indicator.
  /// {@endtemplate}
  final String? semanticsLabel;

  /// {@template flutter.progress_indicator.ProgressIndicator.semanticsValue}
  /// The [SemanticsProperties.value] for this progress indicator.
  ///
  /// This will be used in conjunction with the [semanticsLabel] by
  /// screen reading software to identify the widget, and is primarily
  /// intended for use with determinate progress indicators to announce
  /// how far along they are.
  ///
  /// For determinate progress indicators, this will be defaulted to
  /// [ProgressIndicator.value] expressed as a percentage, i.e. `0.1` will
  /// become '10%'.
  /// {@endtemplate}
  final String? semanticsValue;

  Color _getValueColor(BuildContext context, {Color? defaultColor}) {
    return valueColor?.value ??
        color ??
        ProgressIndicatorTheme.of(context).color ??
        defaultColor ??
        Theme.of(context).colorScheme.primary;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(PercentProperty('value', value,
        showName: false, ifNull: '<indeterminate>'));
  }

  Widget _buildSemanticsWrapper(
      {required BuildContext context, required Widget child}) {
    String? expandedSemanticsValue = semanticsValue;
    if (value != null) {
      expandedSemanticsValue ??= '${(value! * 100).round()}%';
    }
    return Semantics(
        label: semanticsLabel, value: expandedSemanticsValue, child: child);
  }
}

class _CircularProgressIndicatorPainter extends CustomPainter {
  _CircularProgressIndicatorPainter({
    this.trackColor,
    required this.valueColor,
    required this.value,
    required this.headValue,
    required this.tailValue,
    required this.offsetValue,
    required this.rotationValue,
    required this.strokeWidth,
    required this.strokeAlign,
    this.strokeCap,
    this.trackGap,
    this.year2023 = true,
  })  : arcStart = value != null
            ? _startAngle
            : _startAngle +
                tailValue * 3 / 2 * math.pi +
                rotationValue * math.pi * 2.0 +
                offsetValue * 0.5 * math.pi,
        arcSweep = value != null
            ? clampDouble(value, 0.0, 1.0) * _sweep
            : math.max(
                headValue * 3 / 2 * math.pi - tailValue * 3 / 2 * math.pi,
                _epsilon);

  final Color? trackColor;
  final Color valueColor;
  final double? value;
  final double headValue;
  final double tailValue;
  final double offsetValue;
  final double rotationValue;
  final double strokeWidth;
  final double strokeAlign;
  final double arcStart;
  final double arcSweep;
  final StrokeCap? strokeCap;
  final double? trackGap;
  final bool year2023;

  static const double _twoPi = math.pi * 2.0;
  static const double _epsilon = .001;
  // Canvas.drawArc(r, 0, 2*PI) doesn't draw anything, so just get close.
  static const double _sweep = _twoPi - _epsilon;
  static const double _startAngle = -math.pi / 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = valueColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // Use the negative operator as intended to keep the exposed constant value
    // as users are already familiar with.
    final double strokeOffset = strokeWidth / 2 * -strokeAlign;
    final Offset arcBaseOffset = Offset(strokeOffset, strokeOffset);
    final Size arcActualSize =
        Size(size.width - strokeOffset * 2, size.height - strokeOffset * 2);
    final bool hasGap = trackGap != null && trackGap! > 0;

    if (trackColor != null) {
      final Paint backgroundPaint = Paint()
        ..color = trackColor!
        ..strokeWidth = strokeWidth
        ..strokeCap = strokeCap ?? StrokeCap.round
        ..style = PaintingStyle.stroke;
      // If hasGap is true, draw the background arc with a gap.
      if (hasGap && value! > _epsilon) {
        final double arcRadius = arcActualSize.shortestSide / 2;
        final double strokeRadius = strokeWidth / arcRadius;
        final double gapRadius = trackGap! / arcRadius;
        final double startGap = strokeRadius + gapRadius;
        final double endGap = value! < _epsilon ? startGap : startGap * 2;
        final double startSweep = (-math.pi / 2.0) + startGap;
        final double endSweep = math.max(
          0.0,
          _twoPi - clampDouble(value!, 0.0, 1.0) * _twoPi - endGap,
        );
        // Flip the canvas for the background arc.
        canvas.save();
        canvas.scale(-1, 1);
        canvas.translate(-size.width, 0);
        canvas.drawArc(arcBaseOffset & arcActualSize, startSweep, endSweep,
            false, backgroundPaint);
        // Restore the canvas to draw the foreground arc.
        canvas.restore();
      } else {
        canvas.drawArc(
            arcBaseOffset & arcActualSize, 0, _sweep, false, backgroundPaint);
      }
    }

    if (year2023) {
      if (value == null && strokeCap == null) {
        // Indeterminate
        paint.strokeCap = StrokeCap.square;
      } else {
        // Butt when determinate (value != null) && strokeCap == null;
        paint.strokeCap = strokeCap ?? StrokeCap.butt;
      }
    } else {
      paint.strokeCap = strokeCap ?? StrokeCap.round;
    }

    canvas.drawArc(
        arcBaseOffset & arcActualSize, arcStart, arcSweep, false, paint);
  }

  @override
  bool shouldRepaint(_CircularProgressIndicatorPainter oldPainter) {
    return oldPainter.trackColor != trackColor ||
        oldPainter.valueColor != valueColor ||
        oldPainter.value != value ||
        oldPainter.headValue != headValue ||
        oldPainter.tailValue != tailValue ||
        oldPainter.offsetValue != offsetValue ||
        oldPainter.rotationValue != rotationValue ||
        oldPainter.strokeWidth != strokeWidth ||
        oldPainter.strokeAlign != strokeAlign ||
        oldPainter.strokeCap != strokeCap ||
        oldPainter.trackGap != trackGap ||
        oldPainter.year2023 != year2023;
  }
}

class CircularProgressIndicator extends ProgressIndicator {
  /// Creates a circular progress indicator.
  ///
  /// {@macro flutter.material.ProgressIndicator.ProgressIndicator}
  const CircularProgressIndicator({
    super.key,
    super.value,
    super.backgroundColor,
    super.color,
    super.valueColor,
    this.strokeWidth,
    this.strokeAlign,
    super.semanticsLabel,
    super.semanticsValue,
    this.strokeCap,
    this.constraints,
    this.trackGap,
    this.padding,
  });

  @override
  Color? get backgroundColor => super.backgroundColor;

  /// The width of the line used to draw the circle.
  final double? strokeWidth;

  final double? strokeAlign;

  final StrokeCap? strokeCap;

  final BoxConstraints? constraints;

  final double? trackGap;

  /// The padding around the indicator track.
  ///
  /// If null, then the [CustomProgressIndicatorThemeData.circularTrackPadding] will be
  /// used. If that is null and [year2023] is false, then defaults to `EdgeInsets.all(4.0)`
  /// padding. Otherwise, defaults to zero padding.
  final EdgeInsetsGeometry? padding;

  /// The indicator stroke is drawn fully inside of the indicator path.
  ///
  /// This is a constant for use with [strokeAlign].
  static const double strokeAlignInside = -1.0;

  /// The indicator stroke is drawn on the center of the indicator path,
  /// with half of the [strokeWidth] on the inside, and the other half
  /// on the outside of the path.
  ///
  /// This is a constant for use with [strokeAlign].
  ///
  /// This is the default value for [strokeAlign].
  static const double strokeAlignCenter = 0.0;

  /// The indicator stroke is drawn on the outside of the indicator path.
  ///
  /// This is a constant for use with [strokeAlign].
  static const double strokeAlignOutside = 1.0;

  @override
  State<CircularProgressIndicator> createState() =>
      _CircularProgressIndicatorState();
}

const int _kIndeterminateLinearDuration = 1800;
const int _kIndeterminateCircularDuration = 1333 * 2222;

class _CircularProgressIndicatorState extends State<CircularProgressIndicator>
    with SingleTickerProviderStateMixin {
  static const int _pathCount = _kIndeterminateCircularDuration ~/ 1333;
  static const int _rotationCount = _kIndeterminateCircularDuration ~/ 2222;

  static final Animatable<double> _strokeHeadTween = CurveTween(
    curve: const Interval(0.0, 0.5, curve: Curves.fastOutSlowIn),
  ).chain(CurveTween(curve: const SawTooth(_pathCount)));
  static final Animatable<double> _strokeTailTween = CurveTween(
    curve: const Interval(0.5, 1.0, curve: Curves.fastOutSlowIn),
  ).chain(CurveTween(curve: const SawTooth(_pathCount)));
  static final Animatable<double> _offsetTween =
      CurveTween(curve: const SawTooth(_pathCount));
  static final Animatable<double> _rotationTween = CurveTween(
    curve: const SawTooth(_rotationCount),
  );

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: _kIndeterminateCircularDuration),
      vsync: this,
    );
    if (widget.value == null) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(CircularProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == null && !_controller.isAnimating) {
      _controller.repeat();
    } else if (widget.value != null && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildMaterialIndicator(
    BuildContext context,
    double headValue,
    double tailValue,
    double offsetValue,
    double rotationValue,
  ) {
    final dynamic indicatorTheme = ProgressIndicatorTheme.of(context);
    const bool year2023 = false;
    final CustomProgressIndicatorThemeData defaults =
        _CircularProgressIndicatorDefaultsM3(context,
            indeterminate: widget.value == null);
    final Color? trackColor = widget.backgroundColor ??
        indicatorTheme.circularTrackColor ??
        defaults.circularTrackColor;
    final double strokeWidth = widget.strokeWidth ??
        indicatorTheme.strokeWidth ??
        defaults.strokeWidth!;
    final double strokeAlign = widget.strokeAlign ??
        indicatorTheme.strokeAlign ??
        defaults.strokeAlign!;
    final StrokeCap? strokeCap = widget.strokeCap ?? indicatorTheme.strokeCap;
    final BoxConstraints constraints = widget.constraints ??
        indicatorTheme.constraints ??
        defaults.constraints!;
    final double? trackGap =
        widget.trackGap ?? indicatorTheme.trackGap ?? defaults.trackGap;
    final EdgeInsetsGeometry? effectivePadding = widget.padding ??
        indicatorTheme.circularTrackPadding ??
        defaults.circularTrackPadding;

    Widget result = ConstrainedBox(
      constraints: constraints,
      child: CustomPaint(
        painter: _CircularProgressIndicatorPainter(
          trackColor: trackColor,
          valueColor:
              widget._getValueColor(context, defaultColor: defaults.color),
          value: widget.value, // may be null
          headValue:
              headValue, // remaining arguments are ignored if widget.value is not null
          tailValue: tailValue,
          offsetValue: offsetValue,
          rotationValue: rotationValue,
          strokeWidth: strokeWidth,
          strokeAlign: strokeAlign,
          strokeCap: strokeCap,
          trackGap: trackGap,
          year2023: year2023,
        ),
      ),
    );

    if (effectivePadding != null) {
      result = Padding(padding: effectivePadding, child: result);
    }

    return widget._buildSemanticsWrapper(context: context, child: result);
  }

  Widget _buildAnimation() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return _buildMaterialIndicator(
          context,
          _strokeHeadTween.evaluate(_controller),
          _strokeTailTween.evaluate(_controller),
          _offsetTween.evaluate(_controller),
          _rotationTween.evaluate(_controller),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.value != null) {
      return _buildMaterialIndicator(context, 0.0, 0.0, 0, 0.0);
    }
    return _buildAnimation();
  }
}

class _RefreshProgressIndicatorPainter
    extends _CircularProgressIndicatorPainter {
  _RefreshProgressIndicatorPainter({
    required super.valueColor,
    required super.value,
    required super.headValue,
    required super.tailValue,
    required super.offsetValue,
    required super.rotationValue,
    required super.strokeWidth,
    required super.strokeAlign,
    required this.arrowheadScale,
    required super.strokeCap,
  });

  final double arrowheadScale;

  void paintArrowhead(Canvas canvas, Size size) {
    // ux, uy: a unit vector whose direction parallels the base of the arrowhead.
    // (So ux, -uy points in the direction the arrowhead points.)
    final double arcEnd = arcStart + arcSweep;
    final double ux = math.cos(arcEnd);
    final double uy = math.sin(arcEnd);

    assert(size.width == size.height);
    final double radius = size.width / 2.0;
    final double arrowheadPointX =
        radius + ux * radius + -uy * strokeWidth * 2.0 * arrowheadScale;
    final double arrowheadPointY =
        radius + uy * radius + ux * strokeWidth * 2.0 * arrowheadScale;
    final double arrowheadRadius = strokeWidth * 2.0 * arrowheadScale;
    final double innerRadius = radius - arrowheadRadius;
    final double outerRadius = radius + arrowheadRadius;

    final Path path = Path()
      ..moveTo(radius + ux * innerRadius, radius + uy * innerRadius)
      ..lineTo(radius + ux * outerRadius, radius + uy * outerRadius)
      ..lineTo(arrowheadPointX, arrowheadPointY)
      ..close();

    final Paint paint = Paint()
      ..color = valueColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    super.paint(canvas, size);
    if (arrowheadScale > 0.0) {
      paintArrowhead(canvas, size);
    }
  }
}

class _CircularProgressIndicatorDefaultsM3Year2023
    extends CustomProgressIndicatorThemeData {
  _CircularProgressIndicatorDefaultsM3Year2023(this.context,
      {required this.indeterminate});

  final BuildContext context;
  late final ColorScheme _colors = Theme.of(context).colorScheme;
  final bool indeterminate;

  @override
  Color get color => _colors.primary;

  @override
  double get strokeWidth => 4.0;

  @override
  double? get strokeAlign => CircularProgressIndicator.strokeAlignCenter;

  @override
  BoxConstraints get constraints =>
      const BoxConstraints(minWidth: 36.0, minHeight: 36.0);
}
// BEGIN GENERATED TOKEN PROPERTIES - ProgressIndicator

// Do not edit by hand. The code between the "BEGIN GENERATED" and
// "END GENERATED" comments are generated from data in the Material
// Design token database by the script:
//   dev/tools/gen_defaults/bin/gen_defaults.dart.

// dart format off
class _CircularProgressIndicatorDefaultsM3
    extends CustomProgressIndicatorThemeData {
  _CircularProgressIndicatorDefaultsM3(this.context,
      {required this.indeterminate});

  final BuildContext context;
  late final ColorScheme _colors = Theme.of(context).colorScheme;
  final bool indeterminate;

  @override
  Color get color => _colors.primary;

  @override
  Color? get circularTrackColor =>
      indeterminate ? null : _colors.secondaryContainer;

  @override
  double get strokeWidth => 4.0;

  @override
  double? get strokeAlign => CircularProgressIndicator.strokeAlignInside;

  @override
  BoxConstraints get constraints => const BoxConstraints(
        minWidth: 40.0,
        minHeight: 40.0,
      );

  @override
  double? get trackGap => 4.0;

  @override
  EdgeInsetsGeometry? get circularTrackPadding => const EdgeInsets.all(4.0);
}

class _LinearProgressIndicatorDefaultsM3
    extends CustomProgressIndicatorThemeData {
  _LinearProgressIndicatorDefaultsM3(this.context);

  final BuildContext context;
  late final ColorScheme _colors = Theme.of(context).colorScheme;

  @override
  Color get color => _colors.primary;

  @override
  Color get linearTrackColor => _colors.secondaryContainer;

  @override
  double get linearMinHeight => 4.0;

  @override
  BorderRadius get borderRadius => BorderRadius.circular(4.0 / 2);

  @override
  Color get stopIndicatorColor => _colors.primary;

  @override
  double? get stopIndicatorRadius => 4.0 / 2;

  @override
  double? get trackGap => 4.0;
}
// dart format on

// END GENERATED TOKEN PROPERTIES - ProgressIndicator

class CustomProgressIndicator extends StatelessWidget {
  const CustomProgressIndicator({
    super.key,
    this.value,
    this.backgroundColor,
    this.color,
    this.strokeWidth = 4.0,
    this.valueColor,
    this.semanticsLabel,
    this.semanticsValue,
  });

  final double? value;
  final Color? backgroundColor;
  final Color? color;
  final double strokeWidth;
  final Animation<Color?>? valueColor;
  final String? semanticsLabel;
  final String? semanticsValue;

  @override
  Widget build(BuildContext context) {
    return CircularProgressIndicator(
      value: value,
      backgroundColor: backgroundColor,
      color: color,
      strokeWidth: strokeWidth,
      valueColor: valueColor,
      semanticsLabel: semanticsLabel,
      semanticsValue: semanticsValue,
    );
  }
}

class CustomProgressIndicatorThemeData with Diagnosticable {
  /// Creates the set of properties used to configure [ProgressIndicator] widgets.
  const CustomProgressIndicatorThemeData({
    this.color,
    this.linearTrackColor,
    this.linearMinHeight,
    this.circularTrackColor,
    this.refreshBackgroundColor,
    this.borderRadius,
    this.stopIndicatorColor,
    this.stopIndicatorRadius,
    this.strokeWidth,
    this.strokeAlign,
    this.strokeCap,
    this.constraints,
    this.trackGap,
    this.circularTrackPadding,
    @Deprecated(
      'Use ProgressIndicatorTheme to customize the ProgressIndicator appearance. '
      'This feature was deprecated after v3.27.0-0.2.pre.',
    )
    this.year2023,
  });

  /// The color of the [ProgressIndicator]'s indicator.
  ///
  /// If null, then it will use [ColorScheme.primary] of the ambient
  /// [ThemeData.colorScheme].
  ///
  /// See also:
  ///
  ///  * [ProgressIndicator.color], which specifies the indicator color for a
  ///    specific progress indicator.
  ///  * [ProgressIndicator.valueColor], which specifies the indicator color
  ///    a an animated color.
  final Color? color;

  /// {@macro flutter.material.LinearProgressIndicator.trackColor}
  final Color? linearTrackColor;

  /// {@macro flutter.material.LinearProgressIndicator.minHeight}
  final double? linearMinHeight;

  /// {@macro flutter.material.CircularProgressIndicator.trackColor}
  final Color? circularTrackColor;

  /// {@macro flutter.material.RefreshProgressIndicator.backgroundColor}
  final Color? refreshBackgroundColor;

  /// Overrides the border radius of the [ProgressIndicator].
  final BorderRadiusGeometry? borderRadius;

  /// Overrides the stop indicator color of the [LinearProgressIndicator].
  ///
  /// If [LinearProgressIndicator.year2023] is false or [ThemeData.useMaterial3]
  /// is false, then no stop indicator will be drawn.
  final Color? stopIndicatorColor;

  /// Overrides the stop indicator radius of the [LinearProgressIndicator].
  ///
  /// If [LinearProgressIndicator.year2023] is false or [ThemeData.useMaterial3]
  /// is false, then no stop indicator will be drawn.
  final double? stopIndicatorRadius;

  /// Overrides the stroke width of the [CircularProgressIndicator].
  final double? strokeWidth;

  /// Overrides the stroke align of the [CircularProgressIndicator].
  final double? strokeAlign;

  /// Overrides the stroke cap of the [CircularProgressIndicator].
  final StrokeCap? strokeCap;

  /// Overrides the constraints of the [CircularProgressIndicator].
  final BoxConstraints? constraints;

  /// Overrides the active indicator and the background track.
  ///
  /// If [CircularProgressIndicator.year2023] is false or [ThemeData.useMaterial3]
  /// is false, then no track gap will be drawn.
  ///
  /// If [LinearProgressIndicator.year2023] is false or [ThemeData.useMaterial3]
  /// is false, then no track gap will be drawn.
  final double? trackGap;

  /// Overrides the padding of the [CircularProgressIndicator].
  final EdgeInsetsGeometry? circularTrackPadding;

  /// Overrides the [CircularProgressIndicator.year2023] and
  /// [LinearProgressIndicator.year2023] properties.
  ///
  /// When true, the [CircularProgressIndicator] and [LinearProgressIndicator]
  /// will use the 2023 Material Design 3 appearance. Defaults to true.
  ///
  /// If this is set to false, the [CircularProgressIndicator] and
  /// [LinearProgressIndicator] will use the latest Material Design 3 appearance,
  /// which was introduced in December 2023.
  ///
  /// If [ThemeData.useMaterial3] is false, then this property is ignored.
  @Deprecated(
    'Use ProgressIndicatorTheme to customize the ProgressIndicator appearance. '
    'This feature was deprecated after v3.27.0-0.2.pre.',
  )
  final bool? year2023;

  /// Creates a copy of this object but with the given fields replaced with the
  /// new values.
  CustomProgressIndicatorThemeData copyWith({
    Color? color,
    Color? linearTrackColor,
    double? linearMinHeight,
    Color? circularTrackColor,
    Color? refreshBackgroundColor,
    BorderRadiusGeometry? borderRadius,
    Color? stopIndicatorColor,
    double? stopIndicatorRadius,
    double? strokeWidth,
    double? strokeAlign,
    StrokeCap? strokeCap,
    BoxConstraints? constraints,
    double? trackGap,
    EdgeInsetsGeometry? circularTrackPadding,
    bool? year2023,
  }) {
    return CustomProgressIndicatorThemeData(
      color: color ?? this.color,
      linearTrackColor: linearTrackColor ?? this.linearTrackColor,
      linearMinHeight: linearMinHeight ?? this.linearMinHeight,
      circularTrackColor: circularTrackColor ?? this.circularTrackColor,
      refreshBackgroundColor:
          refreshBackgroundColor ?? this.refreshBackgroundColor,
      borderRadius: borderRadius ?? this.borderRadius,
      stopIndicatorColor: stopIndicatorColor ?? this.stopIndicatorColor,
      stopIndicatorRadius: stopIndicatorRadius ?? this.stopIndicatorRadius,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      strokeAlign: strokeAlign ?? this.strokeAlign,
      strokeCap: strokeCap ?? this.strokeCap,
      constraints: constraints ?? this.constraints,
      trackGap: trackGap ?? this.trackGap,
      circularTrackPadding: circularTrackPadding ?? this.circularTrackPadding,
      year2023: year2023 ?? this.year2023,
    );
  }

  /// Linearly interpolate between two progress indicator themes.
  ///
  /// If both arguments are null, then null is returned.
  static CustomProgressIndicatorThemeData? lerp(
    CustomProgressIndicatorThemeData? a,
    CustomProgressIndicatorThemeData? b,
    double t,
  ) {
    if (identical(a, b)) {
      return a;
    }
    return CustomProgressIndicatorThemeData(
      color: Color.lerp(a?.color, b?.color, t),
      linearTrackColor: Color.lerp(a?.linearTrackColor, b?.linearTrackColor, t),
      linearMinHeight: lerpDouble(a?.linearMinHeight, b?.linearMinHeight, t),
      circularTrackColor:
          Color.lerp(a?.circularTrackColor, b?.circularTrackColor, t),
      refreshBackgroundColor:
          Color.lerp(a?.refreshBackgroundColor, b?.refreshBackgroundColor, t),
      borderRadius:
          BorderRadiusGeometry.lerp(a?.borderRadius, b?.borderRadius, t),
      stopIndicatorColor:
          Color.lerp(a?.stopIndicatorColor, b?.stopIndicatorColor, t),
      stopIndicatorRadius:
          lerpDouble(a?.stopIndicatorRadius, b?.stopIndicatorRadius, t),
      strokeWidth: lerpDouble(a?.strokeWidth, b?.strokeWidth, t),
      strokeAlign: lerpDouble(a?.strokeAlign, b?.strokeAlign, t),
      strokeCap: t < 0.5 ? a?.strokeCap : b?.strokeCap,
      constraints: BoxConstraints.lerp(a?.constraints, b?.constraints, t),
      trackGap: lerpDouble(a?.trackGap, b?.trackGap, t),
      circularTrackPadding: EdgeInsetsGeometry.lerp(
        a?.circularTrackPadding,
        b?.circularTrackPadding,
        t,
      ),
      year2023: t < 0.5 ? a?.year2023 : b?.year2023,
    );
  }

  @override
  int get hashCode => Object.hash(
        color,
        linearTrackColor,
        linearMinHeight,
        circularTrackColor,
        refreshBackgroundColor,
        borderRadius,
        stopIndicatorColor,
        stopIndicatorRadius,
        strokeAlign,
        strokeWidth,
        strokeCap,
        constraints,
        trackGap,
        circularTrackPadding,
        year2023,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is CustomProgressIndicatorThemeData &&
        other.color == color &&
        other.linearTrackColor == linearTrackColor &&
        other.linearMinHeight == linearMinHeight &&
        other.circularTrackColor == circularTrackColor &&
        other.refreshBackgroundColor == refreshBackgroundColor &&
        other.borderRadius == borderRadius &&
        other.stopIndicatorColor == stopIndicatorColor &&
        other.stopIndicatorRadius == stopIndicatorRadius &&
        other.strokeAlign == strokeAlign &&
        other.strokeWidth == strokeWidth &&
        other.strokeCap == strokeCap &&
        other.constraints == constraints &&
        other.trackGap == trackGap &&
        other.circularTrackPadding == circularTrackPadding &&
        other.year2023 == year2023;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('color', color, defaultValue: null));
    properties.add(ColorProperty('linearTrackColor', linearTrackColor,
        defaultValue: null));
    properties.add(
        DoubleProperty('linearMinHeight', linearMinHeight, defaultValue: null));
    properties.add(ColorProperty('circularTrackColor', circularTrackColor,
        defaultValue: null));
    properties.add(
      ColorProperty('refreshBackgroundColor', refreshBackgroundColor,
          defaultValue: null),
    );
    properties.add(
      DiagnosticsProperty<BorderRadiusGeometry>('borderRadius', borderRadius,
          defaultValue: null),
    );
    properties.add(ColorProperty('stopIndicatorColor', stopIndicatorColor,
        defaultValue: null));
    properties.add(DoubleProperty('stopIndicatorRadius', stopIndicatorRadius,
        defaultValue: null));
    properties
        .add(DoubleProperty('strokeWidth', strokeWidth, defaultValue: null));
    properties
        .add(DoubleProperty('strokeAlign', strokeAlign, defaultValue: null));
    properties.add(DiagnosticsProperty<StrokeCap>('strokeCap', strokeCap,
        defaultValue: null));
    properties.add(
      DiagnosticsProperty<BoxConstraints>('constraints', constraints,
          defaultValue: null),
    );
    properties.add(DoubleProperty('trackGap', trackGap, defaultValue: null));
    properties.add(
      DiagnosticsProperty<EdgeInsetsGeometry>(
        'circularTrackPadding',
        circularTrackPadding,
        defaultValue: null,
      ),
    );
    properties.add(
        DiagnosticsProperty<bool>('year2023', year2023, defaultValue: null));
  }
}

double? lerpDouble(num? a, num? b, double t) {
  if (a == b || (a?.isNaN ?? false) && (b?.isNaN ?? false)) {
    return a?.toDouble();
  }
  a ??= 0.0;
  b ??= 0.0;
  assert(a.isFinite, 'Cannot interpolate between finite and non-finite values');
  assert(b.isFinite, 'Cannot interpolate between finite and non-finite values');
  assert(t.isFinite, 't must be finite when interpolating between values');
  return a * (1.0 - t) + b * t;
}

/// Linearly interpolate between two doubles.
///
/// Same as [lerpDouble] but specialized for non-null `double` type.
double _lerpDouble(double a, double b, double t) {
  return a * (1.0 - t) + b * t;
}
