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

  static Widget newBadge(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: primary.opaque(0.15, iReallyMeanIt: true),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: primary.opaque(0.3, iReallyMeanIt: true),
          width: 1,
        ),
      ),
      child: AnymeXText(
        context.l10n.newLabel,
        size: 9.5,
        variant: TextVariant.bold,
        color: primary,
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
