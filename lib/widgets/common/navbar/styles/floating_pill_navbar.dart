import 'dart:ui';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/common/navbar.dart';
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

class _FloatingPillNavBarState extends State<_FloatingPillNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _subWidgetController;
  late CurvedAnimation _subWidgetCurve;

  bool _hasSubWidget(int index) {
    final itemCount = widget.items.length;
    if (index < 0 || index >= itemCount) return false;
    final item = widget.items[index];
    return item.subWidget != null ||
        (item.subItems != null && item.subItems!.isNotEmpty);
  }

  @override
  void initState() {
    super.initState();
    _subWidgetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: _hasSubWidget(widget.currentIndex) ? 1.0 : 0.0,
    );
    _subWidgetCurve = CurvedAnimation(
      parent: _subWidgetController,
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  void didUpdateWidget(_FloatingPillNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      if (_hasSubWidget(widget.currentIndex)) {
        _subWidgetController.forward();
      } else {
        _subWidgetController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _subWidgetCurve.dispose();
    _subWidgetController.dispose();
    super.dispose();
  }

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

    final mainContent = RepaintBoundary(
      child: SizedBox(
        width: widget.isDesktop
            ? double.infinity
            : MediaQuery.of(context).size.width * 0.85,
        child: Container(
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

    final currentItem =
        (widget.currentIndex >= 0 && widget.currentIndex < itemCount)
            ? widget.items[widget.currentIndex]
            : null;
    final hasSubWidget = currentItem != null &&
        (currentItem.subWidget != null ||
            (currentItem.subItems != null && currentItem.subItems!.isNotEmpty));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _subWidgetCurve,
          builder: (context, child) => ClipRect(
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: _subWidgetCurve.value,
              child: child,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 2),
            child: hasSubWidget
                ? (currentItem.subWidget != null
                    ? currentItem.subWidget!
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (final sub in currentItem.subItems!)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: _buildSubNavItem(theme, sub),
                              ),
                          ],
                        ),
                      ))
                : const SizedBox.shrink(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: SizedBox(
            height: 52,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;
                return Row(
                  children: List.generate(itemCount, (index) {
                    final isSelected = widget.currentIndex == index;
                    final flex = isSelected ? selectedFlex : unselectedFlex;
                    final targetWidth = totalWidth * flex / totalFlex;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 450),
                      curve: const Cubic(0.34, 1.56, 0.64, 1.0),
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
        ),
      ],
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
          final hasSubItems = isSelected && (item.subWidget != null || (item.subItems != null && item.subItems!.isNotEmpty));
          return Padding(
            padding: EdgeInsets.only(bottom: index < itemCount - 1 ? 8 : 12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              decoration: BoxDecoration(
                color: hasSubItems
                    ? theme.colorScheme.onSurface.opaque(0.04, iReallyMeanIt: true)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: hasSubItems
                      ? theme.colorScheme.onSurface.opaque(0.08, iReallyMeanIt: true)
                      : Colors.transparent,
                  width: 0.8,
                ),
              ),
              padding: hasSubItems ? const EdgeInsets.all(6) : EdgeInsets.zero,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => item.onTap(index),
                    behavior: HitTestBehavior.opaque,
                    child: _FloatingPillNavItem(
                      item: item,
                      isSelected: isSelected,
                      theme: theme,
                      isVertical: true,
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    child: hasSubItems
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 8),
                              if (item.subWidget != null)
                                item.subWidget!
                              else
                                for (final sub in item.subItems!)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: _buildSubNavItem(theme, sub),
                                  ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSubNavItem(ThemeData theme, NavItem sub) {
    final active = sub.isSelected;
    final iconColor = active
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.opaque(0.6, iReallyMeanIt: true);

    return Tooltip(
      message: sub.label,
      child: InkWell(
        onTap: () => sub.onTap(0),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? theme.colorScheme.primary.opaque(0.12, iReallyMeanIt: true)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active
                  ? theme.colorScheme.primary.opaque(0.3, iReallyMeanIt: true)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                active ? sub.selectedIcon : sub.unselectedIcon,
                color: iconColor,
                size: 16,
              ),
              const SizedBox(width: 4),
              AnymeXText(
                sub.label,
                size: 11,
                variant: active ? TextVariant.semiBold : TextVariant.regular,
                color: iconColor,
              ),
            ],
          ),
        ),
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
    final double horizontalPadding = isVertical ? 4.0 : (isSelected ? 18.0 : 12.0);
    final double verticalPadding = isVertical ? 6.0 : 10.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 450),
      curve: const Cubic(0.34, 1.56, 0.64, 1.0),
      width: isVertical ? 76 : null,
      height: isVertical ? 60 : null,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primary
            : Colors.transparent,
        borderRadius: BorderRadius.circular(isVertical ? 16 : 30),
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
        duration: const Duration(milliseconds: 450),
        curve: const Cubic(0.34, 1.56, 0.64, 1.0),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: isSelected ? 1.0 : 0.0,
          child: isSelected
              ? (isVertical
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 2),
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
