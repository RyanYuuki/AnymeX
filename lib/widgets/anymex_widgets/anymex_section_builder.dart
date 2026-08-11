import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:flutter/material.dart';

class AnymeXSectionBuilder extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? backgroundColor;
  final double separatorIndent;

  const AnymeXSectionBuilder({
    super.key,
    this.title,
    required this.children,
    this.margin,
    this.padding,
    this.borderRadius = 18.0,
    this.backgroundColor,
    this.separatorIndent = 66.0,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    final colors = context.colors;
    final itemCount = children.length;

    final List<Widget> formattedChildren = [];

    for (int i = 0; i < itemCount; i++) {
      final child = children[i];

      BorderRadius radius;
      if (itemCount == 1) {
        radius = BorderRadius.circular(borderRadius);
      } else if (i == 0) {
        radius = BorderRadius.vertical(top: Radius.circular(borderRadius));
      } else if (i == itemCount - 1) {
        radius = BorderRadius.vertical(bottom: Radius.circular(borderRadius));
      } else {
        radius = BorderRadius.zero;
      }

      Widget tileWidget = child;
      if (child is AnymeXTile) {
        tileWidget = AnymeXTile(
          icon: child.icon,
          leading: child.leading,
          title: child.title,
          subtitle: child.subtitle,
          trailing: child.trailing,
          onTap: child.onTap,
          iconColor: child.iconColor,
          iconBackgroundColor: child.iconBackgroundColor,
          showChevron: child.showChevron,
          borderRadius: radius,
          padding: child.padding,
          enabled: child.enabled,
          customContent: child.customContent,
        );
      } else {
        tileWidget = ClipRRect(
          borderRadius: radius,
          child: child,
        );
      }

      formattedChildren.add(tileWidget);

      if (i < itemCount - 1) {
        formattedChildren.add(
          Divider(
            height: 1,
            thickness: 0.6,
            indent: separatorIndent,
            endIndent: 16,
            color: colors.onSurface.opaque(0.08, iReallyMeanIt: true),
          ),
        );
      }
    }

    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 20),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null && title!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 8),
              child: AnymeXText(
                text: title!.toUpperCase(),
                size: 11.5,
                variant: TextVariant.bold,
                color: colors.onSurface.opaque(0.45, iReallyMeanIt: true),
              ),
            ),
          ],
          Container(
            decoration: BoxDecoration(
              color: backgroundColor ??
                  colors.surfaceContainer.opaque(0.45, iReallyMeanIt: true),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: colors.onSurface.opaque(0.08, iReallyMeanIt: true),
                width: 0.8,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: formattedChildren,
            ),
          ),
        ],
      ),
    );
  }
}
