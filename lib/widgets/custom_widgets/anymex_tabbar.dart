import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:anymex/utils/theme_extensions.dart';

class AnymeXTabBar extends StatelessWidget {
  final List<String> selectTabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final double height;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? activeTextColor;
  final Color? inactiveTextColor;
  final List<IconData?>? icons;
  final double? minTabWidth;

  const AnymeXTabBar({
    super.key,
    required this.selectTabs,
    required this.selectedIndex,
    required this.onTabSelected,
    this.height = 46.0,
    this.activeColor,
    this.inactiveColor,
    this.activeTextColor,
    this.inactiveTextColor,
    this.icons,
    this.minTabWidth,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final total = selectTabs.length;
    final alignX = total > 1 ? -1.0 + (2.0 * selectedIndex / (total - 1)) : 0.0;

    Widget buildBar(double width) {
      return Container(
        height: height,
        width: width,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color:
              inactiveColor ?? colors.surfaceContainerHighest.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.outline.withOpacity(0.1)),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutQuint,
              alignment: Alignment(alignX, 0),
              child: FractionallySizedBox(
                widthFactor: total > 0 ? 1 / total : 1,
                heightFactor: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: activeColor ?? colors.secondary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (activeColor ?? colors.secondary).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                ),
              ),
            ),
            Row(
              children: selectTabs.asMap().entries.map((e) {
                final selected = selectedIndex == e.key;
                final icon = (icons != null && e.key < icons!.length)
                    ? icons![e.key]
                    : null;

                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (!selected) {
                        HapticFeedback.lightImpact();
                        onTabSelected(e.key);
                      }
                    },
                    child: AnimatedScale(
                      scale: selected ? 1.03 : 1.0,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: AnimatedOpacity(
                        opacity: selected ? 1.0 : 0.6,
                        duration: const Duration(milliseconds: 200),
                        child: SizedBox.expand(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (icon != null) ...[
                                Icon(
                                  icon,
                                  size: 15,
                                  color: selected
                                      ? (activeTextColor ?? colors.onSecondary)
                                      : (inactiveTextColor ??
                                          colors.onSurfaceVariant),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Flexible(
                                child: AnymexText(
                                  text: e.value,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  size: 13,
                                  variant: selected
                                      ? TextVariant.semiBold
                                      : TextVariant.regular,
                                  color: selected
                                      ? (activeTextColor ?? colors.onSecondary)
                                      : (inactiveTextColor ??
                                          colors.onSurfaceVariant),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    }

    if (minTabWidth != null) {
      return LayoutBuilder(builder: (context, constraints) {
        final naturalTabWidth = constraints.maxWidth / total;
        final tabWidth =
            naturalTabWidth < minTabWidth! ? minTabWidth! : naturalTabWidth;
        final totalWidth = tabWidth * total;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: buildBar(totalWidth),
        );
      });
    }

    return buildBar(double.infinity);
  }
}
