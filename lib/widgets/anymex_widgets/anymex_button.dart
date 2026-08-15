import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:blur/blur.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum ButtonVariant { simple, outline }

class AnymeXButton extends StatelessWidget {
  final Function() onTap;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final Widget child;
  final ButtonVariant variant;
  final double? width;
  final double? height;
  final bool isBlurred;

  const AnymeXButton({
    super.key,
    required this.onTap,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.variant = ButtonVariant.simple,
    this.width,
    this.height,
    required this.child,
    this.isBlurred = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOutline = variant == ButtonVariant.outline;

    return Stack(
      children: [
        if (isBlurred)
          Positioned.fill(
            child: Blur(
              blur: 10,
              blurColor: theme.colorScheme.primary,
              colorOpacity: 0.5,
              borderRadius: borderRadius ?? BorderRadius.circular(8),
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
        SizedBox(
          width: width,
          height: height,
          child: ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: isOutline
                  ? Colors.transparent
                  : (backgroundColor ?? theme.colorScheme.primary),
              side: isOutline
                  ? BorderSide(
                      color: borderColor ?? theme.colorScheme.primary,
                      width: 1.5,
                    )
                  : null,
              shape: RoundedRectangleBorder(
                borderRadius: borderRadius ?? BorderRadius.circular(8),
              ),
            ),
            child: child,
          ),
        ),
      ],
    );
  }
}

class AnymeXContainerButton extends StatelessWidget {
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
  final BorderSide? border;
  final BoxShadow? shadow;
  final Clip clipBehavior;
  final bool enableGlow;
  final Function()? onTap;
  final VoidCallback? onLongPress;

  const AnymeXContainerButton({
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
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      0.multiplyRadius();
      final BorderRadiusGeometry? effectiveRadius = radius != null
          ? BorderRadius.circular(radius!.multiplyRadius())
          : borderRadius;

      final BoxDecoration effectiveDecoration = decoration ??
          BoxDecoration(
            color: color,
            borderRadius: effectiveRadius,
            boxShadow: enableGlow
                ? [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .opaque(.05.multiplyGlow(), iReallyMeanIt: true),
                      offset: const Offset(-1, 1),
                      blurRadius: 50.multiplyBlur(),
                      spreadRadius: 2.multiplyGlow(),
                    )
                  ]
                : shadow != null
                    ? [shadow!]
                    : null,
          );
      return ClipRRect(
        borderRadius: effectiveRadius ?? BorderRadius.circular(0),
        clipBehavior: clipBehavior,
        child: ElevatedButtonTheme(
          data: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                  minimumSize: width != null && height != null
                      ? Size(width!, height!)
                      : Size.zero,
                  maximumSize: width != null && height != null
                      ? Size(width!, height!)
                      : null,
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: color,
                  shape: RoundedRectangleBorder(
                      borderRadius: effectiveRadius ?? BorderRadius.circular(0),
                      side: border ??
                          const BorderSide(color: Colors.transparent)))),
          child: ElevatedButton(
            onPressed: onTap,
            onLongPress: onLongPress,
            child: Container(
              height: height,
              width: width,
              alignment: Alignment.center,
              margin: margin,
              padding: padding,
              decoration: effectiveDecoration,
              child: child,
            ),
          ),
        ),
      );
    });
  }
}

enum ButtonType { ticon, child }

class AnymeXButton2 extends StatelessWidget {
  final Widget? child;
  final VoidCallback onTap;
  final ButtonType type;
  final String? label;
  final IconData? icon;

  const AnymeXButton2({
    super.key,
    this.child,
    required this.onTap,
    this.type = ButtonType.child,
    this.label,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colors.outline.opaque(0.2, iReallyMeanIt: true),
        ),
        color: context.colors.surfaceContainer.opaque(0.5, iReallyMeanIt: true),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null)
                Icon(
                  icon,
                  color: context.colors.onSurface,
                  size: 20,
                ),
              const SizedBox(width: 8),
              if (label != null)
                Text(
                  label!,
                  style: TextStyle(
                    color: context.colors.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class BlurWrapper extends StatelessWidget {
  final BorderRadius? borderRadius;
  final double blurAmount;
  final Color? blurColor;
  final double colorOpacity;
  final Widget child;
  final bool enableGlow;

  const BlurWrapper({
    super.key,
    this.borderRadius,
    this.blurAmount = 10.0,
    this.blurColor,
    this.colorOpacity = 0.1,
    required this.child,
    this.enableGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<Settings>();
    final theme = Theme.of(context);

    return Obx(() => Stack(
          children: [
            if (controller.playerStyle == 2)
              Positioned.fill(
                child: Blur(
                  blur: blurAmount,
                  blurColor:
                      blurColor ?? theme.colorScheme.primary.withAlpha(175),
                  colorOpacity: colorOpacity,
                  borderRadius: borderRadius ?? BorderRadius.circular(12),
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
            Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                    boxShadow: enableGlow ? [glowingShadow(context)] : [],
                    borderRadius: borderRadius ??
                        BorderRadius.circular(12.multiplyRadius()),
                    border: Border.all(
                        color: controller.playerStyle == 0
                            ? Colors.transparent
                            : theme.colorScheme.primary.opaque(0.1))),
                child: child),
          ],
        ));
  }
}
