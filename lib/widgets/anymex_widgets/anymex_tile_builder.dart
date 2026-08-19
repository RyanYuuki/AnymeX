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
  final IconData Function(T)? getIcon;
  final Widget Function(T)? getLeading;
  final Widget Function(T)? getTrailing;
  final Function(T) onItemPressed;
  final bool isRadio;
  final bool isSelection;
  final bool Function(T)? showChevron;
  final TextStyle Function(T)? getTitleStyle;
  final TextStyle Function(T)? getSubtitleStyle;

  const AnymeXTileBuilder({
    super.key,
    required this.items,
    this.selectedItem,
    this.selectedItems,
    this.isSelected,
    required this.getTitle,
    this.getSubtitle,
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
  });

  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final hasIcons = getIcon != null || getLeading != null;
    final separatorIndent = hasIcons ? 66.0 : 16.0;

    return AnymeXSectionBuilder(
      margin: EdgeInsets.zero,
      separatorIndent: separatorIndent,
      children: items.map((item) {
        if (!isSelection) {
          return AnymeXTile(
            title: getTitle(item),
            subtitle: getSubtitle?.call(item),
            icon: getIcon?.call(item),
            leading: getLeading?.call(item),
            trailing: getTrailing?.call(item),
            onTap: () => onItemPressed(item),
            showChevron: showChevron?.call(item) ?? false,
            maxLines: maxLines,
            titleStyle: getTitleStyle?.call(item),
            subtitleStyle: getSubtitleStyle?.call(item),
          );
        }

        final checked = isSelected != null
            ? isSelected!(item)
            : (selectedItems != null ? selectedItems!.contains(item) : item == selectedItem);

        if (isRadio) {
          return AnymeXTile.radio(
            title: getTitle(item),
            subtitle: getSubtitle?.call(item),
            icon: getIcon?.call(item),
            selected: checked,
            onTap: () => onItemPressed(item),
            titleStyle: getTitleStyle?.call(item),
            subtitleStyle: getSubtitleStyle?.call(item),
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
          );
        }
      }).toList(),
    );
  }
}
