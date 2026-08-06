import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:flutter/material.dart';

enum PillStyle { connective, standalone }

class PillItem {
  final String label;

  final String? iconUrl;

  final IconData? icon;

  final bool isSelected;

  final VoidCallback onTap;

  final Widget? child;

  const PillItem({
    this.label = '',
    this.iconUrl,
    this.icon,
    required this.isSelected,
    required this.onTap,
    this.child,
  });
}

class AnymeXPills extends StatelessWidget {
  final List<PillItem> items;

  final PillStyle style;

  final double outerRadius;

  final double innerRadius;

  final double? gap;

  final bool scrollable;

  final EdgeInsetsGeometry scrollPadding;
  
  final double selectedOuterRadius;

  const AnymeXPills({
    super.key,
    required this.items,
    this.style = PillStyle.connective,
    this.outerRadius = 16.0,
    this.innerRadius = 5.0,
    this.gap,
    this.scrollable = true,
    this.scrollPadding = const EdgeInsets.symmetric(vertical: 4),
    this.selectedOuterRadius = 50.0,
  });

  double get _effectiveGap =>
      gap ?? (style == PillStyle.connective ? 3.0 : 8.0);

  BorderRadius _borderFor(int index) {
    if (style == PillStyle.standalone) {
      return BorderRadius.circular(outerRadius);
    }

    final isFirst = index == 0;
    final isLast = index == items.length - 1;

    if (isFirst && isLast) return BorderRadius.circular(outerRadius);

    if (isFirst) {
      return BorderRadius.only(
        topLeft: Radius.circular(outerRadius),
        bottomLeft: Radius.circular(outerRadius),
        topRight: Radius.circular(innerRadius),
        bottomRight: Radius.circular(innerRadius),
      );
    }

    if (isLast) {
      return BorderRadius.only(
        topRight: Radius.circular(outerRadius),
        bottomRight: Radius.circular(outerRadius),
        topLeft: Radius.circular(innerRadius),
        bottomLeft: Radius.circular(innerRadius),
      );
    }

    return BorderRadius.circular(innerRadius);
  }

  
  BorderRadius _selectedBorderFor(int index) {
    return BorderRadius.circular(selectedOuterRadius);
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) SizedBox(width: _effectiveGap),
          _PillCell(
            item: items[i],
            borderRadius: _borderFor(i),
            selectedBorderRadius: _selectedBorderFor(i),
          ),
        ],
      ],
    );

    if (!scrollable) return row;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: scrollPadding,
      child: row,
    );
  }
}

class _PillCell extends StatelessWidget {
  final PillItem item;
  final BorderRadius borderRadius;
  final BorderRadius selectedBorderRadius;

  const _PillCell({
    required this.item,
    required this.borderRadius,
    required this.selectedBorderRadius,
  });

  BorderRadius get _activeRadius =>
      item.isSelected ? selectedBorderRadius : borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: item.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: item.isSelected
              ? colors.primary.opaque(0.15, iReallyMeanIt: true)
              : colors.surfaceContainerHighest.opaque(0.3, iReallyMeanIt: true),
          borderRadius: _activeRadius,
          border: Border.all(
            color: item.isSelected
                ? colors.primary.opaque(0.4, iReallyMeanIt: true)
                : colors.onSurface.opaque(0.08, iReallyMeanIt: true),
            width: 0.5,
          ),
        ),
        child: item.child ?? _DefaultPillContent(item: item, colors: colors),
      ),
    );
  }
}

class _DefaultPillContent extends StatelessWidget {
  final PillItem item;
  final ColorScheme colors;

  const _DefaultPillContent({required this.item, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (item.icon != null) ...[
          Icon(
            item.icon,
            size: 14,
            color:
                item.isSelected ? colors.primary : colors.onSurface.opaque(0.7),
          ),
          const SizedBox(width: 4),
        ] else if (item.iconUrl != null && item.iconUrl!.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: AnymeXImage(
              width: 16,
              height: 16,
              imageUrl: item.iconUrl!,
            ),
          ),
          const SizedBox(width: 6),
        ],
        AnymexText.semiBold(
          text: item.label,
          size: 12,
          color: item.isSelected ? colors.primary : colors.onSurface,
        ),
      ],
    );
  }
}
