import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

class AnymeXTileBuilder<T> extends StatelessWidget {
  final List<T> items;
  final T? selectedItem;
  final List<T>? selectedItems;
  final bool Function(T)? isSelected;
  final String Function(T) getTitle;
  final String Function(T)? getSubtitle;
  final Widget Function(T)? getSubtitleWidget;
  final IconData Function(T)? getIcon;
  final Widget Function(T)? getLeading;
  final Widget Function(T)? getTrailing;
  final Function(T) onItemPressed;
  final bool isRadio;
  final bool isSelection;
  final bool Function(T)? showChevron;
  final TextStyle Function(T)? getTitleStyle;
  final TextStyle Function(T)? getSubtitleStyle;
  final bool Function(T)? isEnabled;
  final int? maxLines;
  final bool autoResize;
  final bool lazy;
  final TileStyle? style;
  final M3EShapeKind? iconShape;

  final List<Widget>? headerChildren;
  final List<Widget>? children;

  final List<Widget>? footerChildren;

  const AnymeXTileBuilder({
    super.key,
    required this.items,
    this.selectedItem,
    this.selectedItems,
    this.isSelected,
    required this.getTitle,
    this.getSubtitle,
    this.getSubtitleWidget,
    this.getIcon,
    this.getLeading,
    this.getTrailing,
    required this.onItemPressed,
    this.isRadio = true,
    this.isSelection = true,
    this.showChevron,
    this.isEnabled,
    this.maxLines = 4,
    this.autoResize = true,
    this.getTitleStyle,
    this.getSubtitleStyle,
    this.lazy = false,
    this.style,
    this.iconShape,
    this.headerChildren,
    this.children,
    this.footerChildren,
  });

  @override
  Widget build(BuildContext context) {
    final hasIcons = getIcon != null || getLeading != null;
    final separatorIndent = hasIcons ? 66.0 : 16.0;
    final colors = context.colors;
    final resolvedHeaderChildren = headerChildren ?? children ?? [];
    final footerItems = footerChildren ?? [];
    final effectiveStyle = style ??
        (settingsController.tileStyle == 1
            ? TileStyle.modern
            : TileStyle.classic);
    final isModern = effectiveStyle == TileStyle.modern;
    final effectiveIconShape =
        iconShape ?? AnymeXTileScope.of(context)?.iconShape;

    if (lazy) {
      final totalCount =
          resolvedHeaderChildren.length + items.length + footerItems.length;

      final listView = ListView.separated(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        itemCount: totalCount,
        separatorBuilder: (context, index) => isModern
            ? const SizedBox(height: 2.0)
            : Divider(
                height: 1,
                thickness: 0.6,
                indent: separatorIndent,
                endIndent: 16,
                color: colors.onSurface.opaque(0.08, iReallyMeanIt: true),
              ),
        itemBuilder: (context, index) {
          BorderRadius radius;
          if (isModern) {
            if (totalCount == 1) {
              radius = BorderRadius.circular(18.0);
            } else if (index == 0) {
              radius = const BorderRadius.vertical(
                top: Radius.circular(18.0),
                bottom: Radius.circular(4.0),
              );
            } else if (index == totalCount - 1) {
              radius = const BorderRadius.vertical(
                top: Radius.circular(4.0),
                bottom: Radius.circular(18.0),
              );
            } else {
              radius = BorderRadius.circular(4.0);
            }
          } else {
            if (totalCount == 1) {
              radius = BorderRadius.circular(18.0);
            } else if (index == 0) {
              radius = const BorderRadius.vertical(top: Radius.circular(18.0));
            } else if (index == totalCount - 1) {
              radius =
                  const BorderRadius.vertical(bottom: Radius.circular(18.0));
            } else {
              radius = BorderRadius.zero;
            }
          }

          if (index < resolvedHeaderChildren.length) {
            final child = resolvedHeaderChildren[index];
            return AnymeXTileScope(
              borderRadius: radius,
              backgroundColor: isModern
                  ? colors.surfaceContainer.opaque(0.45, iReallyMeanIt: true)
                  : null,
              style: effectiveStyle,
              iconShape: effectiveIconShape,
              child: ClipRRect(
                borderRadius: radius,
                child: child,
              ),
            );
          }

          final footerStartIndex =
              resolvedHeaderChildren.length + items.length;
          if (index >= footerStartIndex) {
            final child = footerItems[index - footerStartIndex];
            return AnymeXTileScope(
              borderRadius: radius,
              backgroundColor: isModern
                  ? colors.surfaceContainer.opaque(0.45, iReallyMeanIt: true)
                  : null,
              style: effectiveStyle,
              iconShape: effectiveIconShape,
              child: ClipRRect(
                borderRadius: radius,
                child: child,
              ),
            );
          }

          final itemIndex = index - resolvedHeaderChildren.length;
          final item = items[itemIndex];

          if (!isSelection) {
            return AnymeXTile(
              title: getTitle(item),
              subtitle: getSubtitle?.call(item),
              subtitleWidget: getSubtitleWidget?.call(item),
              icon: getIcon?.call(item),
              leading: getLeading?.call(item),
              trailing: getTrailing?.call(item),
              onTap: () => onItemPressed(item),
              enabled: isEnabled?.call(item) ?? true,
              showChevron: showChevron?.call(item) ?? false,
              maxLines: maxLines,
              autoResize: autoResize,
              titleStyle: getTitleStyle?.call(item),
              subtitleStyle: getSubtitleStyle?.call(item),
              borderRadius: radius,
              style: effectiveStyle,
              iconShape: effectiveIconShape,
            );
          }

          final checked = isSelected != null
              ? isSelected!(item)
              : (selectedItems != null
                  ? selectedItems!.contains(item)
                  : item == selectedItem);

          if (isRadio) {
            return AnymeXTile.radio(
              title: getTitle(item),
              subtitle: getSubtitle?.call(item),
              subtitleWidget: getSubtitleWidget?.call(item),
              icon: getIcon?.call(item),
              leading: getLeading?.call(item),
              selected: checked,
              onTap: () => onItemPressed(item),
              titleStyle: getTitleStyle?.call(item),
              subtitleStyle: getSubtitleStyle?.call(item),
              borderRadius: radius,
              style: effectiveStyle,
              iconShape: effectiveIconShape,
            );
          } else {
            return AnymeXTile.checkbox(
              title: getTitle(item),
              subtitle: getSubtitle?.call(item),
              icon: getIcon?.call(item),
              value: checked,
              onChanged: (_) => onItemPressed(item),
              titleStyle: getTitleStyle?.call(item),
              subtitleStyle: getSubtitleStyle?.call(item),
              borderRadius: radius,
              style: effectiveStyle,
            );
          }
        },
      );

      if (isModern) {
        return listView;
      }

      return Container(
        margin: EdgeInsets.zero,
        decoration: BoxDecoration(
          color: colors.surfaceContainer.opaque(0.45, iReallyMeanIt: true),
          borderRadius: BorderRadius.circular(18.0),
          border: Border.all(
            color: colors.onSurface.opaque(0.08, iReallyMeanIt: true),
            width: 0.8,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18.0),
          child: listView,
        ),
      );
    }

    final itemWidgets = items.map((item) {
      if (!isSelection) {
        return AnymeXTile(
          title: getTitle(item),
          subtitle: getSubtitle?.call(item),
          subtitleWidget: getSubtitleWidget?.call(item),
          icon: getIcon?.call(item),
          leading: getLeading?.call(item),
          trailing: getTrailing?.call(item),
          onTap: () => onItemPressed(item),
          enabled: isEnabled?.call(item) ?? true,
          showChevron: showChevron?.call(item) ?? false,
          maxLines: maxLines,
          autoResize: autoResize,
          titleStyle: getTitleStyle?.call(item),
          subtitleStyle: getSubtitleStyle?.call(item),
          style: effectiveStyle,
          iconShape: effectiveIconShape,
        ) as Widget;
      }

      final checked = isSelected != null
          ? isSelected!(item)
          : (selectedItems != null
              ? selectedItems!.contains(item)
              : item == selectedItem);

      if (isRadio) {
        return AnymeXTile.radio(
          title: getTitle(item),
          subtitle: getSubtitle?.call(item),
          subtitleWidget: getSubtitleWidget?.call(item),
          icon: getIcon?.call(item),
          leading: getLeading?.call(item),
          selected: checked,
          onTap: () => onItemPressed(item),
          titleStyle: getTitleStyle?.call(item),
          subtitleStyle: getSubtitleStyle?.call(item),
          style: effectiveStyle,
          iconShape: effectiveIconShape,
        ) as Widget;
      } else {
        return AnymeXTile.checkbox(
          title: getTitle(item),
          subtitle: getSubtitle?.call(item),
          icon: getIcon?.call(item),
          value: checked,
          onChanged: (_) => onItemPressed(item),
          titleStyle: getTitleStyle?.call(item),
          subtitleStyle: getSubtitleStyle?.call(item),
          style: effectiveStyle,
        ) as Widget;
      }
    }).toList();

    return AnymeXSectionBuilder(
      margin: EdgeInsets.zero,
      separatorIndent: separatorIndent,
      style: effectiveStyle,
      iconShape: effectiveIconShape,
      children: [
        ...resolvedHeaderChildren,
        ...itemWidgets,
        ...footerItems,
      ],
    );
  }
}
