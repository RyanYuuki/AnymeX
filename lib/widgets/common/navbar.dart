import 'dart:ui';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NavItem {
  final IconData selectedIcon;
  final IconData unselectedIcon;
  final String label;
  final double? iconSize;
  final Function(int n) onTap;
  final Widget? altIcon;

  const NavItem({
    required this.selectedIcon,
    required this.unselectedIcon,
    required this.label,
    this.iconSize,
    this.altIcon,
    required this.onTap,
  });
}

class ResponsiveNavBar extends StatefulWidget {
  final bool isDesktop;
  final int currentIndex;
  final List<NavItem> items;
  final EdgeInsets? margin;
  final BorderRadius? borderRadius;

  const ResponsiveNavBar({
    super.key,
    required this.isDesktop,
    required this.currentIndex,
    required this.items,
    this.margin,
    this.borderRadius,
  });

  @override
  State<ResponsiveNavBar> createState() => _ResponsiveNavBarState();
}

class _ResponsiveNavBarState extends State<ResponsiveNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _indicatorController;
  late Animation<double> _indicatorPosition;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.currentIndex;
    _indicatorController = AnimationController(
      duration: const Duration(milliseconds: 400),
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
  void didUpdateWidget(ResponsiveNavBar oldWidget) {
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
          widget.isDesktop ? 24.multiplyRadius() : 28.multiplyRadius(),
        );

    final bottomPadding = widget.isDesktop ? 0.0 : MediaQuery.of(context).padding.bottom;
    final finalMargin = widget.margin != null
        ? widget.margin!.copyWith(
            bottom: widget.margin!.bottom + bottomPadding,
          )
        : EdgeInsets.only(
            left: widget.isDesktop ? 5 : 40,
            right: widget.isDesktop ? 5 : 40,
            top: widget.isDesktop ? 0 : 20,
            bottom: (widget.isDesktop ? 0 : 20) + bottomPadding,
          );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: finalMargin,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(
          color: theme.colorScheme.onSurface.opaque(0.08, iReallyMeanIt: true),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.opaque(0.08, iReallyMeanIt: true),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: theme.colorScheme.primary.opaque(0.04, iReallyMeanIt: true),
            blurRadius: 40,
            spreadRadius: -8,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Obx(() {
          final isTranslucent = translucent.value;
          return BackdropFilter(
            filter: isTranslucent
                ? ImageFilter.blur(sigmaX: 10, sigmaY: 10)
                : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
            child: Container(
              decoration: BoxDecoration(
                color: isTranslucent
                    ? theme.colorScheme.surfaceContainer.withValues(alpha: 0.45)
                    : theme.colorScheme.surfaceContainer
                        .withValues(alpha: 0.92),
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
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
                      left: pos * itemWidth + 4,
                      top: 3,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: itemWidth - 8,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(22.multiplyRadius()),
                          color: theme.colorScheme.primary
                              .opaque(0.12, iReallyMeanIt: true),
                          border: Border.all(
                            color: theme.colorScheme.primary
                                .opaque(0.15, iReallyMeanIt: true),
                            width: 0.5,
                          ),
                          boxShadow: [
                            glowingShadow(context),
                          ],
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
                        child: _MobileNavItem(
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
                      borderRadius: BorderRadius.circular(18.multiplyRadius()),
                      color: theme.colorScheme.primary
                          .opaque(0.12, iReallyMeanIt: true),
                      border: Border.all(
                        color: theme.colorScheme.primary
                            .opaque(0.15, iReallyMeanIt: true),
                        width: 0.5,
                      ),
                      boxShadow: [
                        lightGlowingShadow(context),
                      ],
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
                  child: AnymexOnTap(
                    margin: 0,
                    scale: 1,
                    onTap: () => item.onTap(index),
                    child: SizedBox(
                      height: itemHeight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            width: 3,
                            height: isSelected ? 24 : 0,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(1.5),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: theme.colorScheme.primary
                                            .opaque(0.5, iReallyMeanIt: true),
                                        blurRadius: 8,
                                        spreadRadius: 0,
                                      ),
                                    ]
                                  : [],
                            ),
                          ),
                          const SizedBox(width: 8),
                          item.altIcon ??
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: Icon(
                                  isSelected
                                      ? item.selectedIcon
                                      : item.unselectedIcon,
                                  key: ValueKey(isSelected),
                                  color: isSelected
                                      ? theme.colorScheme.primary
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
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileNavItem extends StatelessWidget {
  final NavItem item;
  final bool isSelected;
  final ThemeData theme;

  const _MobileNavItem({
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
                duration: const Duration(milliseconds: 250),
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
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
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
            child: AnymexText(
              text: item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              size: 12,
              variant: isSelected ? TextVariant.semiBold : TextVariant.regular,
            ),
          ),
        ],
      ),
    );
  }
}

class NavBarItem extends StatefulWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final bool isVertical;
  final IconData selectedIcon;
  final IconData unselectedIcon;
  final double iconSize;
  final Widget? altIcon;

  const NavBarItem({
    super.key,
    required this.isSelected,
    required this.onTap,
    required this.isVertical,
    required this.selectedIcon,
    required this.unselectedIcon,
    this.iconSize = 24.0,
    this.altIcon,
  });

  @override
  State<NavBarItem> createState() => _NavBarItemState();
}

class _NavBarItemState extends State<NavBarItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    if (widget.isSelected) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(NavBarItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _controller.forward(from: 0);
      } else {
        _controller.reverse(from: 1);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.isVertical) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        constraints: const BoxConstraints(minWidth: 30),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: 3,
              height: widget.isSelected ? 28 : 0,
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(1.5),
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.primary
                              .opaque(0.5, iReallyMeanIt: true),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ]
                    : [],
              ),
            ),
            AnymexOnTap(
              margin: 0,
              scale: 1,
              onTap: widget.onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? theme.colorScheme.primary
                          .opaque(0.1, iReallyMeanIt: true)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow:
                      widget.isSelected ? [lightGlowingShadow(context)] : [],
                ),
                child: widget.altIcon ??
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Icon(
                        widget.isSelected
                            ? widget.selectedIcon
                            : widget.unselectedIcon,
                        color: widget.isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface
                                .opaque(0.5, iReallyMeanIt: true),
                        size: widget.iconSize,
                      ),
                    ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        constraints: const BoxConstraints(minWidth: 30),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            width: widget.isSelected ? 72.0 : 50.0,
            height: 46.0,
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? theme.colorScheme.primary.opaque(0.1, iReallyMeanIt: true)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(22),
              boxShadow: widget.isSelected ? [glowingShadow(context)] : [],
            ),
            child: Center(
              child: widget.altIcon ??
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Icon(
                      widget.isSelected
                          ? widget.selectedIcon
                          : widget.unselectedIcon,
                      color: widget.isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface
                              .opaque(0.5, iReallyMeanIt: true),
                      size: widget.iconSize,
                    ),
                  ),
            ),
          ),
        ),
      );
    }
  }
}

class BlurredContainer extends StatelessWidget {
  final List<Widget> children;
  final double? height;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final double? elevation;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final double blurIntensity;
  final Color? borderColor;
  final double borderWidth;

  const BlurredContainer({
    super.key,
    required this.children,
    this.height,
    this.margin,
    this.padding,
    this.elevation,
    this.borderRadius,
    this.backgroundColor,
    this.blurIntensity = 15.0,
    this.borderColor,
    this.borderWidth = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: height,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: padding ?? const EdgeInsets.all(16),
        margin: margin ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: borderRadius ?? BorderRadius.circular(24),
          border: Border.all(
            color: borderColor ??
                theme.colorScheme.onSurface.opaque(0.2, iReallyMeanIt: true),
            width: borderWidth,
          ),
          boxShadow: elevation != null
              ? [
                  BoxShadow(
                    color: Colors.black.opaque(0.1, iReallyMeanIt: true),
                    blurRadius: elevation!,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: blurIntensity,
                  sigmaY: blurIntensity,
                ),
                child: Container(),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: children,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BlurredContainerItem extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final IconData selectedIcon;
  final IconData unselectedIcon;
  final String label;

  const BlurredContainerItem({
    super.key,
    required this.isSelected,
    required this.onTap,
    required this.selectedIcon,
    required this.unselectedIcon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? theme.colorScheme.primary.opaque(0.2, iReallyMeanIt: true)
                  : Colors.transparent,
            ),
            padding: const EdgeInsets.all(12),
            child: Icon(
              isSelected ? selectedIcon : unselectedIcon,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
