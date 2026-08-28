import 'dart:ui';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/common/navbar.dart';
import 'package:anymex/widgets/common/navbar/navbar_registry.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ClassicNavBarStyle extends NavBarStyleDef {
  @override
  String get id => 'classic';

  @override
  String get displayName => 'Classic';

  @override
  String get description => 'Pill indicator with icon and label';

  @override
  Widget buildNavBar(BuildContext context, NavBarProps props) {
    return _ClassicNavBar(
      items: props.items,
      currentIndex: props.currentIndex,
      isDesktop: props.isDesktop,
      margin: props.margin,
      borderRadius: props.borderRadius,
    );
  }
}

class _ClassicNavBar extends StatefulWidget {
  final List<dynamic> items;
  final int currentIndex;
  final bool isDesktop;
  final EdgeInsets? margin;
  final BorderRadius? borderRadius;

  const _ClassicNavBar({
    required this.items,
    required this.currentIndex,
    required this.isDesktop,
    this.margin,
    this.borderRadius,
  });

  @override
  State<_ClassicNavBar> createState() => _ClassicNavBarState();
}

class _ClassicNavBarState extends State<_ClassicNavBar>
    with TickerProviderStateMixin {
  late AnimationController _indicatorController;
  late Animation<double> _indicatorPosition;
  int _previousIndex = 0;

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
    _previousIndex = widget.currentIndex;
    _indicatorController = AnimationController(
      duration: const Duration(milliseconds: 320),
      vsync: this,
    );
    _indicatorPosition = Tween<double>(
      begin: widget.currentIndex.toDouble(),
      end: widget.currentIndex.toDouble(),
    ).animate(CurvedAnimation(
      parent: _indicatorController,
      curve: Curves.easeOutCubic,
    ));
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
  void didUpdateWidget(_ClassicNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _previousIndex = oldWidget.currentIndex;
      _indicatorPosition = Tween<double>(
        begin: _previousIndex.toDouble(),
        end: widget.currentIndex.toDouble(),
      ).animate(CurvedAnimation(
        parent: _indicatorController,
        curve: Curves.easeOutCubic,
      ));
      _indicatorController.forward(from: 0);

      if (_hasSubWidget(widget.currentIndex)) {
        _subWidgetController.forward();
      } else {
        _subWidgetController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _indicatorController.dispose();
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
            bottom: widget.margin!.bottom + bottomPadding,
          )
        : EdgeInsets.only(
            left: widget.isDesktop ? 8 : 20,
            right: widget.isDesktop ? 8 : 20,
            top: widget.isDesktop ? 0 : 12,
            bottom: (widget.isDesktop ? 0 : 12) + bottomPadding,
          );

    return RepaintBoundary(
      child: Container(
        margin: finalMargin,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border.all(
            color: theme.colorScheme.onSurface.opaque(0.12, iReallyMeanIt: true),
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
                      ? theme.colorScheme.surfaceContainer.withValues(alpha: 0.6)
                      : theme.colorScheme.surfaceContainer
                          .withValues(alpha: 0.95),
                  borderRadius: borderRadius,
                ),
                child: widget.isDesktop
                    ? _buildDesktopLayout(theme)
                    : _buildMobileLayout(theme),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(ThemeData theme) {
    final itemCount = widget.items.length;
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
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: SizedBox(
            height: 58,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;
                final itemWidth = totalWidth / itemCount;

                return Stack(
                  children: [
                    AnimatedBuilder(
                      animation: _indicatorPosition,
                      builder: (context, _) {
                        final pos = _indicatorPosition.value;
                        return Positioned(
                          left: pos * itemWidth + 3,
                          top: 3,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: itemWidth - 6,
                            height: 52,
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(28.multiplyRadius()),
                              color: theme.colorScheme.primary
                                  .opaque(0.14, iReallyMeanIt: true),
                              border: Border.all(
                                color: theme.colorScheme.primary
                                    .opaque(0.2, iReallyMeanIt: true),
                                width: 0.6,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    Row(
                      children: List.generate(itemCount, (index) {
                        final item = widget.items[index];
                        final isSelected = widget.currentIndex == index;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => item.onTap(index),
                            behavior: HitTestBehavior.opaque,
                            child: _ClassicMobileNavItem(
                              item: item,
                              isSelected: isSelected,
                              theme: theme,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
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
    const gap = 4.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(itemCount, (index) {
            final item = widget.items[index];
            final isSelected = widget.currentIndex == index;
            final hasSubItems = isSelected &&
                (item.subWidget != null ||
                    (item.subItems != null && item.subItems!.isNotEmpty));
            return Padding(
              padding: EdgeInsets.only(bottom: index < itemCount - 1 ? gap : 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                decoration: BoxDecoration(
                  color: hasSubItems
                      ? theme.colorScheme.onSurface
                          .opaque(0.04, iReallyMeanIt: true)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: hasSubItems
                        ? theme.colorScheme.onSurface
                            .opaque(0.08, iReallyMeanIt: true)
                        : Colors.transparent,
                    width: 0.8,
                  ),
                ),
                padding:
                    hasSubItems ? const EdgeInsets.all(6) : EdgeInsets.zero,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ClassicDesktopNavItem(
                      item: item,
                      isSelected: isSelected,
                      theme: theme,
                      index: index,
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
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 2),
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
              if (!active) ...[
                Icon(
                  sub.unselectedIcon,
                  color: iconColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
              ],
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

class _ClassicMobileNavItem extends StatelessWidget {
  final dynamic item;
  final bool isSelected;
  final ThemeData theme;

  const _ClassicMobileNavItem({
    required this.item,
    required this.isSelected,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          item.altIcon ??
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: Icon(
                  isSelected ? item.selectedIcon : item.unselectedIcon,
                  key: ValueKey(isSelected),
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface
                          .opaque(0.45, iReallyMeanIt: true),
                  size: item.iconSize ?? 22,
                ),
              ),
          const SizedBox(height: 3),
          SizedBox(
            width: double.infinity,
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: TextStyle(
                fontSize: isSelected ? 10.5 : 10,
                fontFamily: isSelected ? 'Poppins-SemiBold' : 'Poppins',
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface
                        .opaque(0.45, iReallyMeanIt: true),
                height: 1.2,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: AnymeXText(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  size: isSelected ? 10.5 : 10,
                  variant:
                      isSelected ? TextVariant.semiBold : TextVariant.regular,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface
                          .opaque(0.45, iReallyMeanIt: true),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassicDesktopNavItem extends StatefulWidget {
  final dynamic item;
  final bool isSelected;
  final ThemeData theme;
  final int index;

  const _ClassicDesktopNavItem({
    required this.item,
    required this.isSelected,
    required this.theme,
    required this.index,
  });

  @override
  State<_ClassicDesktopNavItem> createState() => _ClassicDesktopNavItemState();
}

class _ClassicDesktopNavItemState extends State<_ClassicDesktopNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final theme = widget.theme;
    final item = widget.item;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnymexOnTap(
        margin: 0,
        scale: 0.97,
        onTap: () => item.onTap(widget.index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: isSelected
                ? theme.colorScheme.primary.opaque(0.14, iReallyMeanIt: true)
                : _isHovered
                    ? theme.colorScheme.onSurface
                        .opaque(0.06, iReallyMeanIt: true)
                    : Colors.transparent,
            border: isSelected
                ? Border.all(
                    color: theme.colorScheme.primary
                        .opaque(0.2, iReallyMeanIt: true),
                    width: 0.6,
                  )
                : Border.all(color: Colors.transparent, width: 0.6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                width: 3,
                height: isSelected ? 24 : 0,
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
              const SizedBox(width: 8),
              item.altIcon ??
                  AnimatedScale(
                    scale: _isHovered || isSelected ? 1.08 : 1.0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    child: Icon(
                      isSelected ? item.selectedIcon : item.unselectedIcon,
                      key: ValueKey(isSelected),
                      color: isSelected
                          ? theme.colorScheme.primary
                          : _isHovered
                              ? theme.colorScheme.onSurface
                                  .opaque(0.85, iReallyMeanIt: true)
                              : theme.colorScheme.onSurface
                                  .opaque(0.5, iReallyMeanIt: true),
                      size: item.iconSize ?? 22,
                    ),
                  ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
