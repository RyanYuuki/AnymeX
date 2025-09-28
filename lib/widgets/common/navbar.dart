import 'dart:io';

import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/widgets/animation/slide_scale.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

import 'package:get/get.dart';

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
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final int itemsCount = widget.items.length;
    final double calculatedHeight = widget.isDesktop
        ? (itemsCount * 71.0)
            .clamp(100, MediaQuery.of(context).size.height - 100)
        : widget.height ?? 75;
    final settings = Get.find<Settings>();
    final RxBool translucent = settings.transculentBar.obs;

    return AnimatedContainer(
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.2),
          width: 1,
        ),
        borderRadius: widget.borderRadius ??
            BorderRadius.circular(
                widget.isDesktop ? 40.multiplyRadius() : 24.multiplyRadius()),
      ),
      padding: widget.padding ?? const EdgeInsets.all(0),
      margin: widget.margin ??
          EdgeInsets.symmetric(
            horizontal: widget.isDesktop ? 5 : 40,
            vertical: widget.isDesktop ? 0 : 20,
          ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: calculatedHeight,
      child: ClipRRect(
        borderRadius: widget.borderRadius ??
            BorderRadius.circular(
                widget.isDesktop ? 40.multiplyRadius() : 24.multiplyRadius()),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Obx(() {
              if (translucent.value) {
                return Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: widget.blurIntensity ?? 15,
                      sigmaY: widget.blurIntensity ?? 15,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: widget.backgroundColor ?? Colors.transparent,
                      ),
                    ),
                  ),
                );
              } else {
                return Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.backgroundColor ??
                          theme.colorScheme.secondaryContainer,
                    ),
                  ),
                );
              }
            }),
            getResponsiveValue(context,
                strictMode: true,
                mobileValue: getResponsiveValue(context,
                    mobileValue: _buildFlex(
                      widget.items,
                      widget.isDesktop,
                      const Key('normalItems'),
                    ),
                    desktopValue: settings.isTV.value
                        ? _buildFlex(
                            widget.items,
                            widget.isDesktop,
                            const Key('normalItems'),
                          )
                        : SingleChildScrollView(
                            child: _buildFlex(
                              widget.items,
                              widget.isDesktop,
                              const Key('normalItems'),
                            ),
                          )),
                desktopValue: !Platform.isIOS && !Platform.isAndroid
                    ? _buildFlex(
                        widget.items,
                        widget.isDesktop,
                        const Key('normalItems'),
                      )
                    : SingleChildScrollView(
                        child: _buildFlex(
                          widget.items,
                          widget.isDesktop,
                          const Key('normalItems'),
                        ),
                      )),
          ],
        ),
      ),
    );
  }

  Widget _buildFlex(List<NavItem> items, bool isDesktop, Key key) {
    return Flex(
      key: key,
      direction: isDesktop ? Axis.vertical : Axis.horizontal,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: widget.fit ? MainAxisSize.min : MainAxisSize.max,
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return SlideAndScaleAnimation(
          initialScale: 0.0,
          finalScale: 1.0,
          initialOffset: const Offset(0.0, 0.0),
          duration: Duration(milliseconds: getAnimationDuration() + 100),
          child: NavBarItem(
            altIcon: item.altIcon,
            iconSize: item.iconSize,
            isSelected: widget.currentIndex == index,
            onTap: () => item.onTap(index),
            isVertical: isDesktop,
            selectedIcon: item.selectedIcon,
            unselectedIcon: item.unselectedIcon,
            label: item.label,
          ),
        );
      }).toList(),
    );
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

    return Container(
      padding:
          widget.isVertical ? const EdgeInsets.symmetric(vertical: 5) : null,
      constraints: const BoxConstraints(minWidth: 30),
      child: widget.isVertical
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
                AnymexOnTap(
                  margin: 0,
                  scale: 1,
                  onTap: widget.onTap,
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
                        boxShadow: [lightGlowingShadow(context)]),
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
                        color: (widget.isSelected
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1)
                            : Colors.transparent),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow:
                            widget.isSelected ? [glowingShadow(context)] : []),
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
            color: borderColor ?? theme.colorScheme.onSurface.withOpacity(0.2),
            width: borderWidth,
          ),
          boxShadow: elevation != null
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
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
                  ? theme.colorScheme.primary.withOpacity(0.2)
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
