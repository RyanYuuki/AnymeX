/*
import 'package:anymex/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/common/navbar.dart';
import 'package:anymex/widgets/common/navbar/navbar_registry.dart';

class LiquidGlassNavBarStyle extends NavBarStyleDef {
  @override
  String get id => 'liquidGlass';

  @override
  String get displayName => 'Liquid Glass (Experimental)';

  @override
  String get description =>
      'IOS 27 Knockoff. Looks downright dogshit on desktop so dont use it and complain.';

  @override
  Widget buildNavBar(BuildContext context, NavBarProps props) {
    return _LiquidGlassNavBar(
      items: props.items,
      currentIndex: props.currentIndex,
      isDesktop: props.isDesktop,
      margin: props.margin,
      borderRadius: props.borderRadius,
    );
  }
}

class _LiquidGlassNavBar extends StatefulWidget {
  final List<dynamic> items;
  final int currentIndex;
  final bool isDesktop;
  final EdgeInsets? margin;
  final BorderRadius? borderRadius;

  const _LiquidGlassNavBar({
    required this.items,
    required this.currentIndex,
    required this.isDesktop,
    this.margin,
    this.borderRadius,
  });

  @override
  State<_LiquidGlassNavBar> createState() => _LiquidGlassNavBarState();
}

class _LiquidGlassNavBarState extends State<_LiquidGlassNavBar> {
  int _lastPillIndex = 0;

  bool get _hasStandalone => widget.items.length >= 3;
  int get _pillItemCount =>
      _hasStandalone ? widget.items.length - 1 : widget.items.length;
  int get _standaloneIndex => widget.items.length - 1;

  @override
  void initState() {
    super.initState();
    if (widget.currentIndex < _pillItemCount) {
      _lastPillIndex = widget.currentIndex.clamp(0, _pillItemCount - 1);
    }
  }

  @override
  void didUpdateWidget(_LiquidGlassNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex < _pillItemCount) {
      _lastPillIndex = widget.currentIndex.clamp(0, _pillItemCount - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bottomPadding =
        widget.isDesktop ? 0.0 : MediaQuery.paddingOf(context).bottom;
    final horizontalMargin = widget.isDesktop
        ? (widget.margin?.left ?? 16.0)
        : 16.0;
    final bottomMargin = widget.margin != null
        ? (widget.margin!.bottom + bottomPadding)
        : (bottomPadding + 6.0);

    final finalMargin = EdgeInsets.only(
      left: horizontalMargin,
      right: horizontalMargin,
      bottom: bottomMargin,
      top: widget.isDesktop ? 0.0 : 6.0,
    );

    final currentItem =
        (widget.currentIndex >= 0 && widget.currentIndex < widget.items.length)
            ? widget.items[widget.currentIndex]
            : null;
    final hasSubWidget = currentItem != null &&
        (currentItem.subWidget != null ||
            (currentItem.subItems != null && currentItem.subItems!.isNotEmpty));

    if (widget.isDesktop) {
      return _buildDesktopLayout(theme, isDark, finalMargin);
    }

    final activeColor = theme.colorScheme.primary;
    final inactiveColor = theme.colorScheme.onSurface.withValues(alpha: 0.60);

    final isStandaloneActive =
        _hasStandalone && widget.currentIndex == _standaloneIndex;
    final activeTabIndex = (isStandaloneActive
            ? _lastPillIndex
            : widget.currentIndex)
        .clamp(0, _pillItemCount - 1);

    final tabs = List<GlassTab>.generate(_pillItemCount, (index) {
      final item = widget.items[index];
      return GlassTab(
        icon: item.altIcon ??
            Icon(
              item.unselectedIcon,
              size: item.iconSize ?? 24,
              color: inactiveColor,
            ),
        activeIcon: item.altIcon ??
            Icon(
              item.selectedIcon,
              size: item.iconSize ?? 24,
              color: activeColor,
            ),
        label: item.label,
        glowColor: null,
      );
    });

    final extraButton = _hasStandalone
        ? GlassTabBarExtraButton(
            size: 64,
            placement: GlassExtraButtonPlacement.right,
            label: widget.items[_standaloneIndex].label,
            onTap: () {
              if (!isStandaloneActive) {
                HapticFeedback.lightImpact();
              }
              widget.items[_standaloneIndex].onTap(_standaloneIndex);
            },
            icon: widget.items[_standaloneIndex].altIcon ??
                Icon(
                  isStandaloneActive
                      ? widget.items[_standaloneIndex].selectedIcon
                      : widget.items[_standaloneIndex].unselectedIcon,
                  size: widget.items[_standaloneIndex].iconSize ?? 24,
                  color: isStandaloneActive ? activeColor : inactiveColor,
                ),
          )
        : null;

    final subWidgetSection = hasSubWidget
        ? _buildSubWidgetSection(theme, isDark, currentItem)
        : null;

    final glassSettings =
        isDark ? LiquidGlassSettings.ios27Dark : LiquidGlassSettings.ios27Light;

    final indicatorColor = theme.colorScheme.primary.withValues(
      alpha: isDark ? 0.22 : 0.15,
    );

    return Align(
      alignment: Alignment.bottomCenter,
      heightFactor: 1.0,
      child: GlassTabBar.bottom(
        tabs: tabs,
        selectedIndex: activeTabIndex,
        onTabSelected: (index) {
          _lastPillIndex = index;
          if (widget.currentIndex != index) {
            HapticFeedback.lightImpact();
          }
          widget.items[index].onTap(index);
        },
        extraButton: extraButton,
        barHeight: 64,
        spacing: 8,
        horizontalPadding: horizontalMargin,
        verticalPadding: bottomMargin,
        settings: glassSettings.copyWith(
          glassColor: theme.colorScheme.surface.opaque(0.1)
        ),
        indicatorSettings: AnimatedGlassIndicator.baseIndicatorSettings.copyWith(
          thickness: 5,
          refractiveIndex: 1.04,
          chromaticAberration: 0.0,
        ),
        indicatorColor: indicatorColor,
        showIndicator: !isStandaloneActive,
        indicatorPinchStrength: 0.0,
        indicatorExpansion: EdgeInsets.zero,
        pressScale: 1.0,
        glowOpacity: 0.8,
        selectedIconColor: activeColor,
        unselectedIconColor: inactiveColor,
        selectedLabelColor: activeColor,
        unselectedLabelColor: inactiveColor,
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
        bottomAccessory: subWidgetSection,
        bottomAccessoryEnabled: hasSubWidget,
        bottomAccessorySpacing: 8,
      ),
    );
  }

  Widget _buildSubWidgetSection(
    ThemeData theme,
    bool isDark,
    dynamic currentItem,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: currentItem.subWidget != null
          ? currentItem.subWidget!
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final sub in currentItem.subItems!)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _buildSubNavItem(theme, isDark, sub),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildSubNavItem(ThemeData theme, bool isDark, NavItem sub) {
    final active = sub.isSelected;
    final activeColor = theme.colorScheme.primary;
    final inactiveColor = theme.colorScheme.onSurface.withValues(alpha: 0.60);
    final color = active ? activeColor : inactiveColor;

    return Tooltip(
      message: sub.label,
      child: InkWell(
        onTap: () => sub.onTap(0),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? theme.colorScheme.primary.withValues(
                    alpha: isDark ? 0.22 : 0.15,
                  )
                : (isDark
                    ? const Color(0xFF0C0C0E).withValues(alpha: 0.45)
                    : const Color(0xFFF7F7F8).withValues(alpha: 0.45)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active
                  ? theme.colorScheme.primary.withValues(alpha: 0.40)
                  : Colors.white.withValues(alpha: isDark ? 0.12 : 0.18),
              width: 0.65,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                active ? sub.selectedIcon : sub.unselectedIcon,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 5),
              AnymeXText(
                sub.label,
                size: 11,
                variant: active ? TextVariant.semiBold : TextVariant.regular,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(
    ThemeData theme,
    bool isDark,
    EdgeInsets finalMargin,
  ) {
    final itemCount = widget.items.length;
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(28);
    final glassSettings =
        isDark ? LiquidGlassSettings.ios27Dark : LiquidGlassSettings.ios27Light;
    final activeColor = theme.colorScheme.primary;
    final inactiveColor = theme.colorScheme.onSurface.withValues(alpha: 0.60);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: finalMargin,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
        ),
        child: GlassContainer(
          settings: glassSettings,
          shape: const LiquidRoundedSuperellipse(borderRadius: 28),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(itemCount, (index) {
              final item = widget.items[index];
              final isSelected = widget.currentIndex == index;
              final color = isSelected ? activeColor : inactiveColor;

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < itemCount - 1 ? 8.0 : 0.0,
                ),
                child: InkWell(
                  onTap: () {
                    if (!isSelected) {
                      HapticFeedback.lightImpact();
                    }
                    item.onTap(index);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary.withValues(
                              alpha: isDark ? 0.22 : 0.15,
                            )
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary.withValues(alpha: 0.40)
                            : Colors.transparent,
                        width: 0.65,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        item.altIcon ??
                            Icon(
                              isSelected
                                  ? item.selectedIcon
                                  : item.unselectedIcon,
                              color: color,
                              size: item.iconSize ?? 24,
                            ),
                        const SizedBox(height: 3),
                        AnymeXText(
                          item.label,
                          size: 11,
                          variant: isSelected
                              ? TextVariant.semiBold
                              : TextVariant.regular,
                          color: color,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
*/
