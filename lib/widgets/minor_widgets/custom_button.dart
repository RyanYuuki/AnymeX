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
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOutline = variant == ButtonVariant.outline;

    return SizedBox(
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
                  color: borderColor ?? theme.colorScheme.primary, width: 1.5)
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(8),
          ),
        ),
        child: child,
      ),
    );
  }
}
