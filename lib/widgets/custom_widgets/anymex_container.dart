import 'package:anymex/controllers/settings/methods.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AnymexContainer extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final BoxDecoration? decoration;
  final double? height;
  final double? width;
  final AlignmentGeometry? alignment;
  final BorderRadiusGeometry? borderRadius;
  final double? radius;
  final BoxBorder? border;
  final BoxShadow? shadow;
  final Clip clipBehavior;
  final bool enableGlow;

  const AnymexContainer({
    super.key,
    this.child,
    this.padding,
    this.margin,
    this.color,
    this.decoration,
    this.height,
    this.width,
    this.alignment,
    this.borderRadius,
    this.radius,
    this.border,
    this.shadow,
    this.clipBehavior = Clip.none,
    this.enableGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    final BorderRadiusGeometry? effectiveRadius = radius != null
        ? BorderRadius.circular(radius!.multiplyRadius())
        : borderRadius;

    final BoxDecoration effectiveDecoration = decoration ??
        BoxDecoration(
          color: color,
          borderRadius: effectiveRadius,
          border: border,
          boxShadow: enableGlow
              ? [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(.05.multiplyGlow()),
                    offset: const Offset(-1, 1),
                    blurRadius: 50.multiplyBlur(),
                    spreadRadius: 2.multiplyGlow(),
                  )
                ]
              : shadow != null
                  ? [shadow!]
                  : null,
        );

    return Obx(() {
      return ClipRRect(
        borderRadius: effectiveRadius ?? BorderRadius.circular(0),
        clipBehavior: clipBehavior,
        child: Container(
          height: height,
          width: width,
          alignment: alignment,
          margin: margin,
          padding: padding,
          decoration: effectiveDecoration,
          child: child,
        ),
      );
    });
  }
}
