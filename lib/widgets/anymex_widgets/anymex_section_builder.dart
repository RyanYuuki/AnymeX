import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/animation/widget_animations.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_expansion_tile.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

class AnymeXSectionBuilder extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? backgroundColor;
  final double separatorIndent;
  final BoxBorder? borderSide;
  final bool disableSeperator;
  final TileStyle? style;
  final M3EShapeKind? iconShape;

  const AnymeXSectionBuilder({
    super.key,
    this.title,
    required this.children,
    this.margin,
    this.padding,
    this.borderRadius = 18.0,
    this.backgroundColor,
    this.disableSeperator = false,
    this.borderSide,
    this.separatorIndent = 66.0,
    this.style,
    this.iconShape,
  });

  bool _isCheckboxTile(Widget w) {
    if (w is AnymeXTile) {
      return w.isCheckbox;
    }
    return false;
  }

  bool _isExpansionTile(Widget w) {
    return w is AnymeXExpansionTile;
  }

  bool _shouldAddSeparator(Widget a, Widget b) {
    if ((_isExpansionTile(a) && _isCheckboxTile(b)) ||
        (_isCheckboxTile(a) && _isExpansionTile(b)) ||
        (_isExpansionTile(a) && _isExpansionTile(b)) ||
        (_isCheckboxTile(a) && _isCheckboxTile(b))) {
      return false;
    }
    if (a is! AnymeXTile && a is! AnymeXExpansionTile) {
      return false;
    }
    if (b is! AnymeXTile && b is! AnymeXExpansionTile) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    final colors = context.colors;
    final effectiveStyle = style ??
        (settingsController.tileStyle == 1
            ? TileStyle.modern
            : TileStyle.classic);
    final isModern = effectiveStyle == TileStyle.modern;
    final effectiveIconShape =
        iconShape ?? AnymeXTileScope.of(context)?.iconShape;
    final itemCount = children.length;

    final List<Widget> formattedChildren = [];

    for (int i = 0; i < itemCount; i++) {
      final child = children[i];

      BorderRadius radius;
      if (isModern) {
        if (itemCount == 1) {
          radius = BorderRadius.circular(borderRadius);
        } else if (i == 0) {
          radius = BorderRadius.vertical(
            top: Radius.circular(borderRadius),
            bottom: const Radius.circular(4.0),
          );
        } else if (i == itemCount - 1) {
          radius = BorderRadius.vertical(
            top: const Radius.circular(4.0),
            bottom: Radius.circular(borderRadius),
          );
        } else {
          radius = BorderRadius.circular(4.0);
        }
      } else {
        if (itemCount == 1) {
          radius = BorderRadius.circular(borderRadius);
        } else if (i == 0) {
          radius = BorderRadius.vertical(top: Radius.circular(borderRadius));
        } else if (i == itemCount - 1) {
          radius =
              BorderRadius.vertical(bottom: Radius.circular(borderRadius));
        } else {
          radius = BorderRadius.zero;
        }
      }

      Widget tileWidget = child;
      if (child is AnymeXTile) {
        tileWidget = child.copyWith(
          borderRadius: child.borderRadius ?? radius,
          style: effectiveStyle,
          backgroundColor: child.backgroundColor ??
              (isModern
                  ? (backgroundColor ??
                      colors.surfaceContainer.opaque(0.45, iReallyMeanIt: true))
                  : null),
          iconShape: child.iconShape ?? effectiveIconShape,
        );
      } else {
        tileWidget = ClipRRect(
          borderRadius: radius,
          child: child,
        );
      }

      formattedChildren.add(
        AnymeXTileScope(
          borderRadius: radius,
          backgroundColor: backgroundColor ??
              (isModern
                  ? colors.surfaceContainer.opaque(0.45, iReallyMeanIt: true)
                  : null),
          style: effectiveStyle,
          iconShape: effectiveIconShape,
          child: tileWidget,
        ),
      );

      if (i < itemCount - 1) {
        if (isModern) {
          formattedChildren.add(const SizedBox(height: 2.0));
        } else if (!disableSeperator) {
          final nextChild = children[i + 1];
          if (_shouldAddSeparator(child, nextChild)) {
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
      }
    }

    final Widget sectionContent = isModern
        ? ((title != null && title!.isNotEmpty)
            ? ExpansionSectionScope(
                sectionTitle: title!,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: formattedChildren,
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: formattedChildren,
              ))
        : Container(
            decoration: BoxDecoration(
              color: backgroundColor ??
                  colors.surfaceContainer.opaque(0.45, iReallyMeanIt: true),
              borderRadius: BorderRadius.circular(borderRadius),
              border: borderSide ??
                  Border.all(
                    color: colors.onSurface.opaque(0.08, iReallyMeanIt: true),
                    width: 0.8,
                  ),
            ),
            child: (title != null && title!.isNotEmpty)
                ? ExpansionSectionScope(
                    sectionTitle: title!,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: formattedChildren,
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: formattedChildren,
                  ),
          ).animateSection();

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
                title!.toUpperCase(),
                size: 11.5,
                variant: TextVariant.bold,
                color: colors.onSurface.opaque(0.45, iReallyMeanIt: true),
              ),
            ),
          ],
          sectionContent,
        ],
      ),
    );
  }
}
