import 'package:flutter/material.dart';

class NavBarProps {
  final List<dynamic> items;
  final int currentIndex;
  final bool isDesktop;
  final EdgeInsets? margin;
  final BorderRadius? borderRadius;

  const NavBarProps({
    required this.items,
    required this.currentIndex,
    required this.isDesktop,
    this.margin,
    this.borderRadius,
  });
}

abstract class NavBarStyleDef {
  String get id;
  String get displayName;
  String get description;
  Widget buildNavBar(BuildContext context, NavBarProps props);
}

class NavBarRegistry {
  static final List<NavBarStyleDef> _styles = [];

  static List<NavBarStyleDef> get styles => List.unmodifiable(_styles);

  static void register(NavBarStyleDef style) {
    if (!_styles.any((s) => s.id == style.id)) {
      _styles.add(style);
    }
  }

  static NavBarStyleDef getById(String id) {
    return _styles.firstWhere(
      (s) => s.id.toLowerCase() == id.toLowerCase(),
      orElse: () => _styles.first,
    );
  }

  static NavBarStyleDef getByIndex(int index) {
    if (_styles.isEmpty) {
      throw StateError('NavBarRegistry is empty. Ensure styles are registered.');
    }
    final safeIndex = index.clamp(0, _styles.length - 1);
    return _styles[safeIndex];
  }

  static Widget buildByIndex({
    required BuildContext context,
    required int index,
    required NavBarProps props,
  }) {
    final style = getByIndex(index);
    return style.buildNavBar(context, props);
  }
}
