import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:flutter/material.dart';

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
  final int? maxLines;
  final bool lazy;

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
    this.maxLines,
    this.getTitleStyle,
    this.getSubtitleStyle,
    this.lazy = false,
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

    if (lazy) {
      final totalCount =
          resolvedHeaderChildren.length + items.length + footerItems.length;

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
          child: ListView.separated(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            itemCount: totalCount,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              thickness: 0.6,
              indent: separatorIndent,
              endIndent: 16,
              color: colors.onSurface.opaque(0.08, iReallyMeanIt: true),
            ),
            itemBuilder: (context, index) {
              BorderRadius radius;
              if (totalCount == 1) {
                radius = BorderRadius.circular(18.0);
              } else if (index == 0) {
                radius =
                    const BorderRadius.vertical(top: Radius.circular(18.0));
              } else if (index == totalCount - 1) {
                radius =
                    const BorderRadius.vertical(bottom: Radius.circular(18.0));
              } else {
                radius = BorderRadius.zero;
              }

              if (index < resolvedHeaderChildren.length) {
                return ClipRRect(
                  borderRadius: radius,
                  child: resolvedHeaderChildren[index],
                );
              }

              final footerStartIndex =
                  resolvedHeaderChildren.length + items.length;
              if (index >= footerStartIndex) {
                return ClipRRect(
                  borderRadius: radius,
                  child: footerItems[index - footerStartIndex],
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
                  showChevron: showChevron?.call(item) ?? false,
                  maxLines: maxLines,
                  titleStyle: getTitleStyle?.call(item),
                  subtitleStyle: getSubtitleStyle?.call(item),
                  borderRadius: radius,
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
                  icon: getIcon?.call(item),
                  selected: checked,
                  onTap: () => onItemPressed(item),
                  titleStyle: getTitleStyle?.call(item),
                  subtitleStyle: getSubtitleStyle?.call(item),
                  borderRadius: radius,
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
                );
              }
            },
          ),
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
          showChevron: showChevron?.call(item) ?? false,
          maxLines: maxLines,
          titleStyle: getTitleStyle?.call(item),
          subtitleStyle: getSubtitleStyle?.call(item),
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
          icon: getIcon?.call(item),
          selected: checked,
          onTap: () => onItemPressed(item),
          titleStyle: getTitleStyle?.call(item),
          subtitleStyle: getSubtitleStyle?.call(item),
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
        ) as Widget;
      }
    }).toList();

    return AnymeXSectionBuilder(
      margin: EdgeInsets.zero,
      separatorIndent: separatorIndent,
      children: [
        ...resolvedHeaderChildren,
        ...itemWidgets,
        ...footerItems,
      ],
    );
  }
}
