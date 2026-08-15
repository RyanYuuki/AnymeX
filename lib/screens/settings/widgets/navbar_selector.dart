import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/common/dynamic_style_selector.dart';
import 'package:anymex/widgets/common/navbar/navbar_registry.dart';
import 'package:anymex/widgets/common/navbar/navbar_styles.dart';
import 'package:anymex/widgets/common/navbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void showNavBarStyleSwitcher(BuildContext context) {
  registerBuiltInNavBarStyles();
  final selectedStyle =
      NavStyleVariant.values[settingsController.navBarStyle].obs;

  showDialog(
    context: context,
    builder: (dialogContext) {
      return Obx(() {
        return AnymeXDialog(
          title: 'Nav Bar Style',
          onConfirm: () {
            settingsController.navBarStyle = selectedStyle.value.index;
          },
          contentWidget: NavBarStyleSelector(
            onStyleChanged: (e) {
              selectedStyle.value = e;
            },
            initialStyle: selectedStyle.value,
          ),
        );
      });
    },
  );
}

class NavBarStyleSelector extends StatelessWidget {
  final Function(NavStyleVariant) onStyleChanged;
  final NavStyleVariant initialStyle;

  const NavBarStyleSelector({
    super.key,
    required this.onStyleChanged,
    required this.initialStyle,
  });

  @override
  Widget build(BuildContext context) {
    registerBuiltInNavBarStyles();

    final previewItems = [
      NavItem(
        selectedIcon: Icons.home_rounded,
        unselectedIcon: Icons.home_outlined,
        label: 'Home',
        onTap: (_) {},
      ),
      NavItem(
        selectedIcon: Icons.explore_rounded,
        unselectedIcon: Icons.explore_outlined,
        label: 'Explore',
        onTap: (_) {},
      ),
      NavItem(
        selectedIcon: Icons.library_books_rounded,
        unselectedIcon: Icons.library_books_outlined,
        label: 'Library',
        onTap: (_) {},
      ),
    ];

    return DynamicStyleSelector<NavStyleVariant>(
      values: NavStyleVariant.values,
      selectedValue: initialStyle,
      getTitle: (style) =>
          NavBarRegistry.getByIndex(style.index).displayName,
      getDescription: (style) =>
          NavBarRegistry.getByIndex(style.index).description,
      buildPreview: (style) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: NavBarRegistry.buildByIndex(
          context: context,
          index: style.index,
          props: NavBarProps(
            items: previewItems,
            currentIndex: 0,
            isDesktop: false,
          ),
        ),
      ),
      onValueChanged: onStyleChanged,
    );
  }
}
