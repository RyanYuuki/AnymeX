import 'dart:ui';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:anymex/widgets/common/navbar/navbar_registry.dart';
import 'package:anymex/widgets/common/navbar/navbar_styles.dart';

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

class _ResponsiveNavBarState extends State<ResponsiveNavBar> {
  @override
  Widget build(BuildContext context) {
    registerBuiltInNavBarStyles();
    final navStyle = settingsController.navBarStyle;
    return NavBarRegistry.buildByIndex(
      context: context,
      index: navStyle,
      props: NavBarProps(
        items: widget.items,
        currentIndex: widget.currentIndex,
        isDesktop: widget.isDesktop,
        margin: widget.margin,
        borderRadius: widget.borderRadius,
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
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
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
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: 3,
              height: widget.isSelected ? 26 : 0,
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
            AnymexOnTap(
              margin: 0,
              scale: 1,
              onTap: widget.onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? theme.colorScheme.primary
                          .opaque(0.1, iReallyMeanIt: true)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
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
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            width: widget.isSelected ? 72.0 : 50.0,
            height: 46.0,
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? theme.colorScheme.primary.opaque(0.1, iReallyMeanIt: true)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(22),
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
      width: MediaQuery.sizeOf(context).width,
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
