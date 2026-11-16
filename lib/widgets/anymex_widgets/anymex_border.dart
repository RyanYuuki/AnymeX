import 'package:flutter/material.dart';

class Ios27BoxBorder extends BoxBorder {
  final double width;
  final bool isDark;
  final Alignment lightSource;
  final Color? specularColor;
  final Color? shadowColor;

  const Ios27BoxBorder({
    this.width = 0.75,
    this.isDark = true,
    this.lightSource = Alignment.topLeft,
    this.specularColor,
    this.shadowColor,
  });

  @override
  BorderSide get top => BorderSide(width: width);

  @override
  BorderSide get bottom => BorderSide(width: width);

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(width);

  @override
  bool get isUniform => true;

  @override
  Ios27BoxBorder scale(double t) {
    return Ios27BoxBorder(
      width: width * t,
      isDark: isDark,
      lightSource: lightSource,
      specularColor: specularColor,
      shadowColor: shadowColor,
    );
  }

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection? textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius? borderRadius,
  }) {
    if (width <= 0.0) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;

    final startColor = specularColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.65));

    final midColor = isDark
        ? Colors.white.withValues(alpha: 0.09)
        : Colors.black.withValues(alpha: 0.05);

    final endColor = shadowColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.12));

    final gradient = LinearGradient(
      begin: lightSource,
      end: Alignment(-lightSource.x, -lightSource.y),
      colors: [startColor, midColor, endColor],
      stops: const [0.0, 0.45, 1.0],
    );

    paint.shader = gradient.createShader(rect);

    final halfWidth = width / 2.0;
    final strokeRect = rect.deflate(halfWidth);

    if (shape == BoxShape.circle) {
      canvas.drawOval(strokeRect, paint);
    } else if (borderRadius != null && borderRadius != BorderRadius.zero) {
      final rrect = borderRadius.toRRect(strokeRect);
      canvas.drawRRect(rrect, paint);
    } else {
      canvas.drawRect(strokeRect, paint);
    }
  }
}

class AnymeXBorder extends StatelessWidget {
  final Widget child;
  final double radius;
  final double width;
  final BorderRadius? borderRadius;
  final Alignment lightSource;
  final Color? specularColor;
  final Color? shadowColor;

  const AnymeXBorder({
    super.key,
    required this.child,
    this.radius = 16.0,
    this.width = 0.75,
    this.borderRadius,
    this.lightSource = Alignment.topLeft,
    this.specularColor,
    this.shadowColor,
  });

  static Ios27BoxBorder boxBorder(
    BuildContext context, {
    double width = 0.75,
    Alignment lightSource = Alignment.topLeft,
    Color? specularColor,
    Color? shadowColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Ios27BoxBorder(
      width: width,
      isDark: isDark,
      lightSource: lightSource,
      specularColor: specularColor,
      shadowColor: shadowColor,
    );
  }

  static BoxDecoration decoration(
    BuildContext context, {
    Color? color,
    double radius = 16.0,
    BorderRadius? borderRadius,
    double width = 0.75,
    List<BoxShadow>? boxShadow,
    BoxShape shape = BoxShape.rectangle,
    Alignment lightSource = Alignment.topLeft,
    Color? specularColor,
    Color? shadowColor,
  }) {
    final effectiveRadius = shape == BoxShape.circle
        ? null
        : (borderRadius ?? BorderRadius.circular(radius));

    return BoxDecoration(
      color: color,
      shape: shape,
      borderRadius: effectiveRadius,
      border: boxBorder(
        context,
        width: width,
        lightSource: lightSource,
        specularColor: specularColor,
        shadowColor: shadowColor,
      ),
      boxShadow: boxShadow,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(radius);
    final border = boxBorder(
      context,
      width: width,
      lightSource: lightSource,
      specularColor: specularColor,
      shadowColor: shadowColor,
    );

    return RepaintBoundary(
      child: CustomPaint(
        foregroundPainter: _Ios27BorderCustomPainter(
          border: border,
          borderRadius: effectiveRadius,
        ),
        child: child,
      ),
    );
  }
}

class _Ios27BorderCustomPainter extends CustomPainter {
  final Ios27BoxBorder border;
  final BorderRadius borderRadius;

  const _Ios27BorderCustomPainter({
    required this.border,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    border.paint(
      canvas,
      Offset.zero & size,
      borderRadius: borderRadius,
    );
  }

  @override
  bool shouldRepaint(covariant _Ios27BorderCustomPainter oldDelegate) {
    return oldDelegate.border.width != border.width ||
        oldDelegate.border.isDark != border.isDark ||
        oldDelegate.border.lightSource != border.lightSource ||
        oldDelegate.borderRadius != borderRadius;
  }
}

extension Ios27BorderExtension on Widget {
  Widget withIos27Border({
    double radius = 16.0,
    double width = 0.75,
    BorderRadius? borderRadius,
    Alignment lightSource = Alignment.topLeft,
    Color? specularColor,
    Color? shadowColor,
  }) {
    return AnymeXBorder(
      radius: radius,
      width: width,
      borderRadius: borderRadius,
      lightSource: lightSource,
      specularColor: specularColor,
      shadowColor: shadowColor,
      child: this,
    );
  }

  Widget ios27Border({
    double radius = 16.0,
    double width = 0.75,
    BorderRadius? borderRadius,
    Alignment lightSource = Alignment.topLeft,
    Color? specularColor,
    Color? shadowColor,
  }) {
    return withIos27Border(
      radius: radius,
      width: width,
      borderRadius: borderRadius,
      lightSource: lightSource,
      specularColor: specularColor,
      shadowColor: shadowColor,
    );
  }
}
