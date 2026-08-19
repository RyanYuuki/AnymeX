import 'dart:ui';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
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
    with SingleTickerProviderStateMixin {
  late AnimationController _indicatorController;
  late Animation<double> _indicatorPosition;
  int _previousIndex = 0;

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
    }
  }

  @override
  void dispose() {
    _indicatorController.dispose();
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
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
                    : theme.colorScheme.surfaceContainer.withValues(alpha: 0.95),
                borderRadius: borderRadius,
              ),
              child: widget.isDesktop
                  ? _buildDesktopLayout(theme)
                  : _buildMobileLayout(theme),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMobileLayout(ThemeData theme) {
    final itemCount = widget.items.length;
    return Padding(
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
    );
  }

  Widget _buildDesktopLayout(ThemeData theme) {
    final itemCount = widget.items.length;
    const itemHeight = 56.0;
    const gap = 4.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: SizedBox(
        height: itemCount * (itemHeight + gap) - gap,
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _indicatorPosition,
              builder: (context, _) {
                final pos = _indicatorPosition.value;
                return Positioned(
                  top: pos * (itemHeight + gap) + 2,
                  left: 2,
                  right: 2,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: itemHeight - 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22.multiplyRadius()),
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
            Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(itemCount, (index) {
                final item = widget.items[index];
                final isSelected = widget.currentIndex == index;
                return Padding(
                  padding:
                      EdgeInsets.only(bottom: index < itemCount - 1 ? gap : 0),
                  child: _ClassicDesktopNavItem(
                    item: item,
                    isSelected: isSelected,
                    theme: theme,
                    index: index,
                  ),
                );
              }),
            ),
          ],
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
                child: AnymeXText(item.label,
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
            color: _isHovered && !isSelected
                ? theme.colorScheme.onSurface.opaque(0.06, iReallyMeanIt: true)
                : Colors.transparent,
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
