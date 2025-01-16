import 'package:anymex/controllers/settings/methods.dart';
import 'package:blur/blur.dart';
import 'package:flutter/material.dart';

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

class BlurWrapper extends StatelessWidget {
  final BorderRadius? borderRadius;
  final double blurAmount;
  final Color? blurColor;
  final double colorOpacity;
  final Widget child;

  const BlurWrapper({
    super.key,
    this.borderRadius,
    this.blurAmount = 10.0,
    this.blurColor,
    this.colorOpacity = 0.1,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        Positioned.fill(
          child: Blur(
            blur: blurAmount,
            blurColor: blurColor ??
                Theme.of(context).colorScheme.primary.withAlpha(175),
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
                borderRadius:
                    borderRadius ?? BorderRadius.circular(12.multiplyRadius()),
                border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.1))),
            child: child),
      ],
    );
  }
}
