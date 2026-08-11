import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';

class AnymeXExpansionTile extends StatelessWidget {
  final String title;
  final Widget content;
  final bool initialExpanded;
  final Widget? leading;

  const AnymeXExpansionTile({
    super.key,
    required this.title,
    required this.content,
    this.initialExpanded = false,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final highlightProvider = SettingsHighlightProvider.of(context);
    final shouldExpand =
        initialExpanded || (highlightProvider?.expansionTitle == title);

    return AnymeXCard(
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          iconColor: context.colors.primary,
          collapsedIconColor: context.colors.onSurfaceVariant,
          leading: leading,
          title: AnymeXText(
            text: title,
            size: 15,
            variant: TextVariant.semiBold,
            color: context.colors.onSurface,
          ),
          initiallyExpanded: shouldExpand,
          children: [
            ExpansionSectionScope(
              sectionTitle: title,
              child: SizedBox(
                width: double.infinity,
                child: content,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnymeXCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final bool enableAnimation;
  final Color? color;
  final ShapeBorder? shape;
  final Clip? clipBehavior;

  const AnymeXCard({
    super.key,
    required this.child,
    this.padding,
    this.enableAnimation = false,
    this.color,
    this.shape,
    this.clipBehavior,
  });

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<Settings>();
    final cardColor = color ??
        (settings.disableGradient
            ? context.colors.surfaceContainerLow
            : context.colors.surfaceContainerLow.opaque(0.35));

    return Card(
      clipBehavior: clipBehavior ?? Clip.antiAlias,
      color: cardColor,
      elevation: 0,
      shape: shape ??
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: context.colors.outline.opaque(0.08),
            ),
          ),
      child: enableAnimation
          ? AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: padding ?? const EdgeInsets.all(0.0),
              child: child,
            )
          : Padding(
              padding: padding ?? const EdgeInsets.all(0.0),
              child: child,
            ),
    );
  }
}
