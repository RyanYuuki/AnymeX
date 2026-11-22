import 'package:flutter/material.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';

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
                    const SizedBox(width: 8),
                  ],
                  if (title != null)
                    AnymeXText.semiBold(
                      title!,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected ? activeText : inactiveText,
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
  final double height;
  final double gap;
  final double selectedRadius;
  final double unselectedRadius;

  const AnymeXSegmentedButtonGroup({
    super.key,
    required this.selected,
    required this.items,
    required this.onSelected,
    this.height = 56,
    this.gap = 8,
    this.selectedRadius = 28,
    this.unselectedRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) SizedBox(width: gap),
          AnymeXSegmentedButton(
            title: items[i].title,
            icon: items[i].icon,
            isSelected: selected == items[i].value,
            height: height,
            selectedRadius: selectedRadius,
            unselectedRadius: unselectedRadius,
            onTap: () => onSelected(items[i].value),
          ),
        ],
      ],
    );
  }
}
