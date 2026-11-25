import 'package:anymex/l10n/l10n_extension.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:flutter/material.dart';

class AnymeXBadge extends StatelessWidget {
  final Widget child;
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;
  final Offset offset;
  final bool visible;

  const AnymeXBadge({
    super.key,
    required this.child,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
    this.offset = const Offset(-2, -2),
    this.visible = true,
  });

  static Widget newBadge(BuildContext context, {bool inverted = false}) {
    final cs = Theme.of(context).colorScheme;
    final bgColor = inverted
        ? cs.onPrimary.opaque(0.22, iReallyMeanIt: true)
        : cs.primary.opaque(0.16, iReallyMeanIt: true);
    final borderColor = inverted
        ? cs.onPrimary.opaque(0.45, iReallyMeanIt: true)
        : cs.primary.opaque(0.35, iReallyMeanIt: true);
    final fgColor = inverted ? cs.onPrimary : cs.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: AnymeXText(
        context.l10n.newLabel.toUpperCase(),
        size: 8.5,
        variant: TextVariant.bold,
        color: fgColor,
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          height: 1.1,
          color: fgColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!visible || label.isEmpty || label == '0') {
      return child;
    }

    final theme = Theme.of(context);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: offset.dy,
          right: offset.dx,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: backgroundColor ?? theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(50),
            ),
            child: AnymeXText(
              label,
              variant: TextVariant.bold,
              size: fontSize ?? 9.0,
              color: textColor ?? theme.colorScheme.onPrimary,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
