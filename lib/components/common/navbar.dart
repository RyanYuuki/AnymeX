import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:ui';

import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ResponsiveNavBar extends StatefulWidget {
  final bool isDesktop;
  final int currentIndex;
  final List<NavItem> items;
  final bool fit;
  final double? height;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final double? elevation;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final double? blurIntensity;
  final EdgeInsets? itemPadding;

  const ResponsiveNavBar({
    super.key,
    required this.isDesktop,
    required this.currentIndex,
    required this.items,
    this.fit = false,
    this.height,
    this.margin,
    this.padding,
    this.elevation,
    this.borderRadius,
    this.backgroundColor,
    this.blurIntensity,
    this.itemPadding,
  });

  @override
  State<ResponsiveNavBar> createState() => _ResponsiveNavBarState();
}

class _ResponsiveNavBarState extends State<ResponsiveNavBar> {
  final GlobalKey _navBarKey = GlobalKey();
  Size? _contentSize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateContentSize();
    });
  }

  void _updateContentSize() {
    final RenderBox? renderBox =
        _navBarKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      setState(() {
        _contentSize = renderBox.size;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder(
        valueListenable: Hive.box("app-data").listenable(),
        builder: (context, box, ref) {
          double radiusMultiplier =
              box.get("radiusMultiplier", defaultValue: 1.0);
          return AnimatedContainer(
            decoration: BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.onSurface.withOpacity(0.2),
                  width: 1,
                ),
                borderRadius: widget.borderRadius ??
                    BorderRadius.circular((widget.isDesktop ? 50 : 24) * radiusMultiplier)),
            padding: widget.padding ?? const EdgeInsets.all(0),
            margin: widget.margin ??
                EdgeInsets.symmetric(
                    horizontal: widget.isDesktop ? 5 : 40,
                    vertical: widget.isDesktop ? 0 : 10),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: widget.fit && _contentSize != null
                ? (widget.isDesktop
                    ? _contentSize!.width + 32
                    : double.infinity)
                : (double.infinity),
            height: widget.height ?? (widget.isDesktop ? 400 : 75),
            child: ClipRRect(
              borderRadius: widget.borderRadius ??
                  BorderRadius.circular(
                      (widget.isDesktop ? 50 : 24) * radiusMultiplier),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: widget.blurIntensity ?? 15,
                        sigmaY: widget.blurIntensity ?? 15,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: widget.backgroundColor ??
                              theme.colorScheme.surfaceContainer
                                  .withOpacity(0.1),
                        ),
                      ),
                    ),
                  ),
                  Flex(
                    key: _navBarKey,
                    direction:
                        widget.isDesktop ? Axis.vertical : Axis.horizontal,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    mainAxisSize:
                        widget.fit ? MainAxisSize.min : MainAxisSize.max,
                    children: widget.items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return NavBarItem(
                        altIcon: item.altIcon,
                        iconSize: item.iconSize,
                        isSelected: widget.currentIndex == index,
                        onTap: () => item.onTap(index),
                        isVertical: widget.isDesktop,
                        selectedIcon: item.selectedIcon,
                        unselectedIcon: item.unselectedIcon,
                        label: item.label,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        });
  }
}

class NavBarItem extends StatefulWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final bool isVertical;
  final IconData selectedIcon;
  final IconData unselectedIcon;
  final String label;
  final double? iconSize;
  final Widget? altIcon;

  const NavBarItem({
    super.key,
    required this.isSelected,
    required this.onTap,
    required this.isVertical,
    required this.selectedIcon,
    required this.unselectedIcon,
    required this.label,
    this.iconSize,
    this.altIcon,
  });

  @override
  State<NavBarItem> createState() => _NavBarItemState();
}

class _NavBarItemState extends State<NavBarItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _indicatorAnimation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _indicatorAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
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
    bool isDesktop = MediaQuery.of(context).size.width > 500;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 30),
      child: isDesktop
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _indicatorAnimation,
                  builder: (context, child) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Transform.scale(
                        scaleY: _indicatorAnimation.value,
                        alignment: Alignment.topCenter,
                        child: Container(
                          height: 32,
                          width: 3,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(1.5),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    theme.colorScheme.primary.withOpacity(0.6),
                                blurRadius: 12,
                                spreadRadius: 1,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.isSelected
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: widget.altIcon ??
                        Icon(
                          widget.isSelected
                              ? widget.selectedIcon
                              : widget.unselectedIcon,
                          color: widget.isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.inverseSurface,
                          size: widget.iconSize,
                        ),
                  ),
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.isSelected
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: widget.altIcon ??
                        Icon(
                          widget.isSelected
                              ? widget.selectedIcon
                              : widget.unselectedIcon,
                          color: widget.isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.inverseSurface,
                          size: widget.iconSize,
                        ),
                  ),
                ),
                AnimatedBuilder(
                  animation: _indicatorAnimation,
                  builder: (context, child) {
                    return Align(
                      alignment: Alignment.bottomCenter,
                      child: Transform.scale(
                        scaleX: _indicatorAnimation.value,
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: 3,
                          width: 32,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(1.5),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    theme.colorScheme.primary.withOpacity(0.6),
                                blurRadius: 12,
                                spreadRadius: 1,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }
}

class NavItem {
  final IconData selectedIcon;
  final IconData unselectedIcon;
  final String label;
  final double? iconSize;
  final Function(int n) onTap;
  final Widget? altIcon;

  const NavItem(
      {required this.selectedIcon,
      required this.unselectedIcon,
      required this.label,
      this.iconSize,
      this.altIcon,
      required this.onTap});
}
