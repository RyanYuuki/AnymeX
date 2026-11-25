import 'package:flutter/material.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

class AnymeXSegmentedButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isSelected;
  final String? title;
  final IconData? icon;
  final Widget? titleWidget;
  final double height;
  final double selectedRadius;
  final double unselectedRadius;
  final Color? selectedColor;
  final Color? unselectedColor;
  final Color? selectedTextColor;
  final Color? unselectedTextColor;

  const AnymeXSegmentedButton({
    super.key,
    this.onTap,
    required this.isSelected,
    this.title,
    this.titleWidget,
    this.icon,
    this.height = 56,
    this.selectedRadius = 28,
    this.unselectedRadius = 14,
    this.selectedColor,
    this.unselectedColor,
    this.selectedTextColor,
    this.unselectedTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final effectiveRadius = isSelected ? selectedRadius : unselectedRadius;
    final activeBg = selectedColor ?? colors.primary;
    final inactiveBg = unselectedColor ??
        colors.surfaceContainer.opaque(0.45, iReallyMeanIt: true);
    final activeText = selectedTextColor ?? colors.onPrimary;
    final inactiveText = unselectedTextColor ?? colors.onSurface;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(effectiveRadius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: height,
          decoration: BoxDecoration(
            color: isSelected ? activeBg : inactiveBg,
            borderRadius: BorderRadius.circular(effectiveRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          child: titleWidget ??
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 18,
                      color: isSelected ? activeText : inactiveText,
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (title != null)
                    Flexible(
                      child: AnymeXText.semiBold(
                        title!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: isSelected ? activeText : inactiveText,
                        ),
                      ),
                    ),
                ],
              ),
        ),
      ),
    );
  }
}

class AnymeXSegmentedButtonGroup<T> extends StatelessWidget {
  final T selected;
  final List<({T value, String title, IconData? icon})> items;
  final ValueChanged<T> onSelected;
  final List<Widget?>? badges;
  final Widget? Function(BuildContext context, int index, bool isSelected)?
      badgeBuilder;
  final double height;
  final double gap;
  final double selectedRadius;
  final double unselectedRadius;
  final Color? selectedColor;
  final Color? unselectedColor;
  final Color? selectedTextColor;
  final Color? unselectedTextColor;
  final bool scrollable;

  const AnymeXSegmentedButtonGroup({
    super.key,
    required this.selected,
    required this.items,
    required this.onSelected,
    this.badges,
    this.badgeBuilder,
    this.height = 56,
    this.gap = 8,
    this.selectedRadius = 28,
    this.unselectedRadius = 14,
    this.selectedColor,
    this.unselectedColor,
    this.selectedTextColor,
    this.unselectedTextColor,
    this.scrollable = false,
  });

  M3EButtonSize _resolveSize() {
    if (height <= 36) return M3EButtonSize.xs;
    if (height <= 48) return M3EButtonSize.sm;
    return M3EButtonSize.md;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final selectedIdx = items.indexWhere((e) => e.value == selected);
    final activeBg = selectedColor ?? colors.primary;
    final inactiveBg = unselectedColor ??
        colors.surfaceContainer.opaque(0.55, iReallyMeanIt: true);
    final activeFg = selectedTextColor ?? colors.onPrimary;
    final inactiveFg = unselectedTextColor ?? colors.onSurface;

    final group = M3EButtonGroup(
      type: M3EButtonGroupType.connected,
      direction: Axis.horizontal,
      shape: M3EButtonShape.round,
      size: _resolveSize(),
      style: M3EButtonStyle.filled,
      density: M3EButtonGroupDensity.regular,
      neighborSquish: true,
      expandedRatio: 0.15,
      overflow: M3EButtonGroupOverflow.scroll,
      selectionRequired: true,
      selectedIndex: selectedIdx >= 0 ? selectedIdx : null,
      decoration: M3EButtonDecoration(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return activeBg;
          return inactiveBg;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return activeFg;
          return inactiveFg;
        }),
      ),
      onSelectedIndexChanged: (int? index) {
        if (index != null && index >= 0 && index < items.length) {
          onSelected(items[index].value);
        }
      },
      actions: [
        for (int i = 0; i < items.length; i++)
          () {
            final isItemSelected = selected == items[i].value;
            final badge = badgeBuilder?.call(context, i, isItemSelected) ??
                ((badges != null && i < badges!.length) ? badges![i] : null);
            return M3EButtonGroupAction(
              icon: items[i].icon != null ? Icon(items[i].icon) : null,
              label: badge != null
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(items[i].title),
                        const SizedBox(width: 6),
                        badge,
                      ],
                    )
                  : Text(items[i].title),
            );
          }(),
      ],
    );

    if (scrollable) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: group,
      );
    }

    return group;
  }
}
