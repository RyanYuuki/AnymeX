import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:flutter/material.dart';

enum PillStyle { connective, standalone }

class PillItem {
  final String label;

  final String? iconUrl;

  final IconData? icon;

  final bool isSelected;

  final VoidCallback onTap;

  final Widget? child;

  final int? count;

  final String? countText;

  const PillItem({
    this.label = '',
    this.iconUrl,
    this.icon,
    required this.isSelected,
    required this.onTap,
    this.child,
    this.count,
    this.countText,
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

  final bool expandEqually;

  final bool wrap;

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
    this.expandEqually = false,
    this.wrap = false,
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

    if (wrap) {
      return Padding(
        padding: scrollPadding,
        child: Wrap(
          spacing: _effectiveGap,
          runSpacing: 8.0,
          children: [
            for (int i = 0; i < items.length; i++)
              _buildPillCell(
                context: context,
                item: items[i],
                borderRadius: _borderFor(i),
                selectedBorderRadius: _selectedBorderFor(i),
              ),
          ],
        ),
      );
    }

    final row = Row(
      mainAxisSize: expandEqually ? MainAxisSize.max : MainAxisSize.min,
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) SizedBox(width: _effectiveGap),
          if (expandEqually)
            Expanded(
              child: _buildPillCell(
                context: context,
                item: items[i],
                borderRadius: _borderFor(i),
                selectedBorderRadius: _selectedBorderFor(i),
                isExpanded: true,
              ),
            )
          else
            _buildPillCell(
              context: context,
              item: items[i],
              borderRadius: _borderFor(i),
              selectedBorderRadius: _selectedBorderFor(i),
              isExpanded: false,
            ),
        ],
      ],
    );

    if (expandEqually || !scrollable) return row;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: scrollPadding,
      child: row,
    );
  }

  Widget _buildPillCell({
    required BuildContext context,
    required PillItem item,
    required BorderRadius borderRadius,
    required BorderRadius selectedBorderRadius,
    bool isExpanded = false,
  }) {
    final colors = Theme.of(context).colorScheme;
    final activeRadius = item.isSelected ? selectedBorderRadius : borderRadius;

    return GestureDetector(
      onTap: item.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        alignment: isExpanded ? Alignment.center : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: item.isSelected
              ? colors.primary
              : colors.surfaceContainerHighest.opaque(0.3, iReallyMeanIt: true),
          borderRadius: activeRadius,
          border: Border.all(
            color: item.isSelected
                ? colors.primary
                : colors.onSurface.opaque(0.08, iReallyMeanIt: true),
            width: 0.5,
          ),
        ),
        child: item.child ?? _buildDefaultPillContent(item, colors),
      ),
    );
  }

  Widget _buildDefaultPillContent(PillItem item, ColorScheme colors) {
    final foregroundColor =
        item.isSelected ? colors.onPrimary : colors.onSurface;
    final iconColor = item.isSelected
        ? colors.onPrimary
        : colors.onSurface.opaque(0.75, iReallyMeanIt: true);
    final countBgColor = item.isSelected
        ? colors.onPrimary.opaque(0.2, iReallyMeanIt: true)
        : colors.surfaceContainerHighest.opaque(0.6, iReallyMeanIt: true);
    final countTextColor = item.isSelected
        ? colors.onPrimary
        : colors.onSurface.opaque(0.75, iReallyMeanIt: true);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (item.icon != null) ...[
          Icon(
            item.icon,
            size: 14,
            color: iconColor,
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
        AnymeXText.semiBold(
          item.label,
          size: 12,
          color: foregroundColor,
        ),
        if (item.countText != null || item.count != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: countBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: AnymeXText(
              item.countText ?? item.count.toString(),
              size: 10,
              variant: TextVariant.bold,
              color: countTextColor,
            ),
          ),
        ],
      ],
    );
  }
}
