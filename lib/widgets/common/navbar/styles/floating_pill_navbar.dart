import 'dart:ui';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/common/navbar/navbar_registry.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FloatingPillNavBarStyle extends NavBarStyleDef {
  @override
  String get id => 'floatingPill';

  @override
  String get displayName => 'Dynamic Pill';

  @override
  String get description => 'Selected tab expands with label, others shrink to icon only';

  @override
  Widget buildNavBar(BuildContext context, NavBarProps props) {
    return _FloatingPillNavBar(
      items: props.items,
      currentIndex: props.currentIndex,
      isDesktop: props.isDesktop,
      margin: props.margin,
      borderRadius: props.borderRadius,
    );
  }
}

class _FloatingPillNavBar extends StatefulWidget {
  final List<dynamic> items;
  final int currentIndex;
  final bool isDesktop;
  final EdgeInsets? margin;
  final BorderRadius? borderRadius;

  const _FloatingPillNavBar({
    required this.items,
    required this.currentIndex,
    required this.isDesktop,
    this.margin,
    this.borderRadius,
  });

  @override
  State<_FloatingPillNavBar> createState() => _FloatingPillNavBarState();
}

class _FloatingPillNavBarState extends State<_FloatingPillNavBar> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = Get.find<Settings>();
    final RxBool translucent = settings.transculentBar.obs;

    final borderRadius = widget.borderRadius ??
        BorderRadius.circular(
          widget.isDesktop ? 30.multiplyRadius() : 36.multiplyRadius(),
        );

    final bottomPadding =
        widget.isDesktop ? 0.0 : MediaQuery.paddingOf(context).bottom;
    final finalMargin = widget.margin != null
        ? widget.margin!.copyWith(
            left: widget.isDesktop ? widget.margin!.left : 0.0,
            right: widget.isDesktop ? widget.margin!.right : 0.0,
            bottom: widget.margin!.bottom + bottomPadding,
          )
        : EdgeInsets.only(
            left: 0.0,
            right: 0.0,
            top: widget.isDesktop ? 0 : 12,
            bottom: (widget.isDesktop ? 0 : 12) + bottomPadding,
          );

    final mainContent = SizedBox(
      width: widget.isDesktop
          ? double.infinity
          : MediaQuery.of(context).size.width * 0.85,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: finalMargin,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border.all(
            color: theme.colorScheme.onSurface
                .opaque(0.12, iReallyMeanIt: true),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.opaque(0.12, iReallyMeanIt: true),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Obx(() {
            final isTranslucent = translucent.value;
            return BackdropFilter(
              filter: isTranslucent
                  ? ImageFilter.blur(sigmaX: 25, sigmaY: 25)
                  : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
              child: Container(
                decoration: BoxDecoration(
                  color: isTranslucent
                      ? theme.colorScheme.surfaceContainer
                          .withValues(alpha: 0.6)
                      : theme.colorScheme.surfaceContainer
                          .withValues(alpha: 0.95),
                  borderRadius: borderRadius,
                ),
                child: widget.isDesktop
                    ? _buildDesktopLayout(theme)
                    : _buildMobileLayout(context, theme),
              ),
            );
          }),
        ),
      ),
    );

    if (widget.isDesktop) {
      return mainContent;
    }

    return Align(
      alignment: Alignment.bottomCenter,
      heightFactor: 1.0,
      child: mainContent,
    );
  }

  Widget _buildMobileLayout(BuildContext context, ThemeData theme) {
    final itemCount = widget.items.length;
    const double selectedFlex = 2.4;
    const double unselectedFlex = 1.0;
    final totalFlex = selectedFlex + unselectedFlex * (itemCount - 1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: SizedBox(
        height: 50,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;
            return Row(
              children: List.generate(itemCount, (index) {
                final isSelected = widget.currentIndex == index;
                final flex = isSelected ? selectedFlex : unselectedFlex;
                final targetWidth = totalWidth * flex / totalFlex;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  width: targetWidth,
                  child: GestureDetector(
                    onTap: () => widget.items[index].onTap(index),
                    behavior: HitTestBehavior.opaque,
                    child: _FloatingPillNavItem(
                      item: widget.items[index],
                      isSelected: isSelected,
                      theme: theme,
                      isVertical: false,
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(ThemeData theme) {
    final itemCount = widget.items.length;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(itemCount, (index) {
          final item = widget.items[index];
          final isSelected = widget.currentIndex == index;
          return Padding(
            padding: EdgeInsets.only(bottom: index < itemCount - 1 ? 8 : 12),
            child: GestureDetector(
              onTap: () => item.onTap(index),
              behavior: HitTestBehavior.opaque,
              child: _FloatingPillNavItem(
                item: item,
                isSelected: isSelected,
                theme: theme,
                isVertical: true,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _FloatingPillNavItem extends StatelessWidget {
  final dynamic item;
  final bool isSelected;
  final ThemeData theme;
  final bool isVertical;

  const _FloatingPillNavItem({
    required this.item,
    required this.isSelected,
    required this.theme,
    required this.isVertical,
  });

  @override
  Widget build(BuildContext context) {
    final double horizontalPadding = isVertical ? 6.0 : (isSelected ? 14.0 : 10.0);
    final double verticalPadding = isVertical ? 8.0 : 10.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primary
            : Colors.transparent,
        borderRadius: BorderRadius.circular(isVertical ? 16 : 22),
      ),
      child: isVertical
          ? Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: _buildContent(),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: _buildContent(),
            ),
    );
  }

  List<Widget> _buildContent() {
    final iconColor = isSelected
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface.opaque(0.6, iReallyMeanIt: true);

    return [
      item.altIcon ??
          Icon(
            isSelected ? item.selectedIcon : item.unselectedIcon,
            color: iconColor,
            size: item.iconSize ?? 20,
          ),
      AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isSelected ? 1.0 : 0.0,
          child: isSelected
              ? (isVertical
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 4),
                        AnymeXText(item.label,
                          size: 10,
                          variant: TextVariant.semiBold,
                          color: theme.colorScheme.onPrimary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 8),
                        AnymeXText(item.label,
                          size: 12,
                          variant: TextVariant.semiBold,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ],
                    ))
              : const SizedBox.shrink(),
        ),
      ),
    ];
  }
}
