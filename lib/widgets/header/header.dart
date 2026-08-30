import 'dart:ui';

import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/controllers/ui/greeting.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/screens/profile/profile_page.dart';
import 'package:anymex/screens/library/controller/library_controller.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_animated_logo.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_badge.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_bottomsheet.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image_button.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tabbar.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/non_widgets/settings_sheet.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:iconsax/iconsax.dart';

enum PageType { manga, anime, home, novel, library, extensions, history, stats }

class Header extends StatelessWidget {
  final Widget? leading;
  final Widget? titleWidget;
  final String? title;
  final Color? titleColor;
  final Widget? subtitleWidget;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? bottom;
  final bool isSearchActive;
  final Widget? searchBar;

  const Header({
    super.key,
    this.leading,
    this.titleWidget,
    this.title,
    this.titleColor,
    this.subtitleWidget,
    this.subtitle,
    this.actions,
    this.bottom,
    this.isSearchActive = false,
    this.searchBar,
  });

  factory Header.fromType({
    Key? key,
    required PageType type,
    Widget? bottom,
    VoidCallback? onSearchPressed,
    VoidCallback? onSortPressed,
  }) {
    return _buildHeaderFromType(
      key: key,
      type: type,
      bottom: bottom,
      onSearchPressed: onSearchPressed,
      onSortPressed: onSortPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLegacy = settingsController.useLegacyHeader;
      final isDesktop = MediaQuery.sizeOf(context).width > 600;

      if (isSearchActive && searchBar != null) {
        if (isLegacy) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: searchBar!,
          );
        }
        return _FloatingHeaderWrapper(child: searchBar!);
      }

      final effectiveLeading = leading ?? const HeaderProfileAvatar();
      final effectiveTitle = titleWidget ??
          (title != null
              ? HeaderTitle(title: title!, color: titleColor)
              : const SizedBox.shrink());
      final effectiveSubtitle = subtitleWidget ??
          (subtitle != null
              ? HeaderSubtitle(subtitle: subtitle!)
              : const SizedBox.shrink());

      if (isLegacy) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  effectiveLeading,
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        effectiveTitle,
                        effectiveSubtitle,
                      ],
                    ),
                  ),
                  if (actions != null && actions!.isNotEmpty) ...[
                    const SizedBox(width: 15),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: actions!
                          .map((a) => Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: a,
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
              if (bottom != null) ...[
                const SizedBox(height: 8),
                bottom!,
              ],
            ],
          ),
        );
      }

      if (isDesktop) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _FloatingHeaderWrapper(
                  margin: const EdgeInsets.fromLTRB(24, 8, 0, 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      effectiveLeading,
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          effectiveTitle,
                          effectiveSubtitle,
                        ],
                      ),
                    ],
                  ),
                ),
                if (actions != null && actions!.isNotEmpty)
                  _FloatingHeaderWrapper(
                    margin: const EdgeInsets.fromLTRB(0, 8, 24, 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: actions!,
                    ),
                  ),
              ],
            ),
            if (bottom != null)
              _FloatingHeaderWrapper(
                margin: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: bottom!,
              ),
          ],
        );
      }

      final content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              effectiveLeading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    effectiveTitle,
                    effectiveSubtitle,
                  ],
                ),
              ),
              if (actions != null && actions!.isNotEmpty) ...[
                const SizedBox(width: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions!,
                ),
              ],
            ],
          ),
          if (bottom != null) ...[
            const SizedBox(height: 8),
            bottom!,
          ],
        ],
      );
      return _FloatingHeaderWrapper(child: content);
    });
  }
}

Header _buildHeaderFromType({
  Key? key,
  required PageType type,
  Widget? bottom,
  VoidCallback? onSearchPressed,
  VoidCallback? onSortPressed,
}) {
  final profileData = Get.find<ServiceHandler>();
  final isSimkl = profileData.serviceType.value == ServicesType.simkl;

  switch (type) {
    case PageType.home:
      return Header(
        key: key,
        leading: const HeaderLogoButton(),
        title: 'AnymeX',
        titleColor: Get.theme.colorScheme.primary,
        subtitleWidget: const HeaderGreetingSubtitle(),
        actions: const [HeaderProfileAvatar()],
        bottom: bottom,
      );
    case PageType.anime:
      return Header(
        key: key,
        leading: const HeaderProfileAvatar(),
        title: isSimkl ? 'Movies' : 'Anime',
        subtitleWidget: const HeaderGreetingSubtitle(),
        actions: [
          if (onSearchPressed != null)
            HeaderActionButton(
              icon: IconlyLight.search,
              onTap: onSearchPressed,
            ),
        ],
        bottom: bottom,
      );
    case PageType.manga:
      return Header(
        key: key,
        leading: const HeaderProfileAvatar(),
        title: isSimkl ? 'Series' : 'Manga',
        subtitleWidget: const HeaderGreetingSubtitle(),
        actions: [
          if (onSearchPressed != null)
            HeaderActionButton(
              icon: IconlyLight.search,
              onTap: onSearchPressed,
            ),
        ],
        bottom: bottom,
      );
    case PageType.novel:
      return Header(
        key: key,
        leading: const HeaderProfileAvatar(),
        title: 'Novels',
        subtitleWidget: const HeaderGreetingSubtitle(),
        actions: [
          if (onSearchPressed != null)
            HeaderActionButton(
              icon: IconlyLight.search,
              onTap: onSearchPressed,
            ),
        ],
        bottom: bottom,
      );
    case PageType.library:
      return Header(
        key: key,
        leading: const HeaderProfileAvatar(),
        title: 'Library',
        subtitle: 'All your local shi',
        actions: [
          if (onSearchPressed != null)
            HeaderActionButton(
              icon: IconlyLight.search,
              onTap: onSearchPressed,
            ),
          if (onSortPressed != null)
            HeaderActionButton(
              icon: Icons.sort_rounded,
              onTap: onSortPressed,
            ),
        ],
        bottom: bottom,
      );
    case PageType.history:
      return Header(
        key: key,
        leading: const HeaderProfileAvatar(),
        title: 'History',
        subtitle: 'Your watch & read history',
        actions: [
          if (onSearchPressed != null)
            HeaderActionButton(
              icon: IconlyLight.search,
              onTap: onSearchPressed,
            ),
        ],
        bottom: bottom,
      );
    case PageType.stats:
      return Header(
        key: key,
        leading: const HeaderProfileAvatar(),
        title: 'Stats',
        subtitle: 'Your watch & read statistics',
        bottom: bottom,
      );
    case PageType.extensions:
      return Header(
        key: key,
        leading: const HeaderProfileAvatar(),
        title: 'Extensions',
        subtitle: 'Manage plugins & sources',
        bottom: bottom,
      );
  }
}

class HeaderProfileAvatar extends StatelessWidget {
  final double radius;

  const HeaderProfileAvatar({super.key, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    final profileData = Get.find<ServiceHandler>();
    return AnymexOnTap(
      onTap: () => SettingsSheet.show(context),
      child: GestureDetector(
        onLongPress: () {
          if (profileData.isLoggedIn.value) {
            navigate(() => const ProfilePage());
          }
        },
        child: Obx(() {
          final count =
              Get.find<SourceController>().extensionUpdatesCount.value;
          final avatar = CircleAvatar(
            radius: radius,
            backgroundColor: context.colors.secondaryContainer.opaque(0.50),
            child: profileData.isLoggedIn.value
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: AnymeXImage(
                      width: radius * 2,
                      height: radius * 2,
                      fit: BoxFit.cover,
                      radius: 0,
                      errorImage: '',
                      imageUrl: profileData.profileData.value.avatar ?? '',
                    ),
                  )
                : Icon(
                    IconlyBold.profile,
                    color: context.colors.onSecondaryContainer,
                    size: 18,
                  ),
          );
          if (count > 0) {
            return AnymeXBadge(
              label: count.toString(),
              backgroundColor: context.colors.primary,
              textColor: context.colors.onPrimary,
              child: avatar,
            );
          }
          return avatar;
        }),
      ),
    );
  }
}

class HeaderLogoButton extends StatelessWidget {
  final double size;

  const HeaderLogoButton({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return AnymexOnTap(
      onTap: () => SettingsSheet().showServiceSelector(context),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: context.colors.secondaryContainer.opaque(0.5),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: AnymeXAnimatedLogo(
            size: size,
            color: context.colors.primary,
          ),
        ),
      ),
    );
  }
}

class HeaderActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final Widget? badge;

  const HeaderActionButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.color,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: context.colors.secondaryContainer.opaque(0.5),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon,
                color: color ?? context.colors.primary,
                size: 18,
              ),
              if (badge != null)
                Positioned(
                  top: -4,
                  right: -4,
                  child: badge!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class HeaderSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;
  final String hintText;

  const HeaderSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClose,
    this.hintText = 'Search...',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onClose,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: context.colors.secondaryContainer.opaque(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back_ios_new,
              color: context.colors.primary,
              size: 16,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            autofocus: true,
            style: const TextStyle(fontSize: 14, fontFamily: 'Poppins'),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: context.colors.onSurface.withOpacity(0.4),
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              filled: true,
              fillColor: context.colors.secondaryContainer.opaque(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
                  color: context.colors.primary.withOpacity(0.3),
                  width: 1.0,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class HeaderTitle extends StatelessWidget {
  final String title;
  final Color? color;

  const HeaderTitle({super.key, required this.title, this.color});

  @override
  Widget build(BuildContext context) {
    return AnymeXText(
      title,
      autoResize: true,
      maxLines: 1,
      size: 15,
      variant: TextVariant.bold,
      color: color,
    );
  }
}

class HeaderSubtitle extends StatelessWidget {
  final String subtitle;
  final Color? color;

  const HeaderSubtitle({super.key, required this.subtitle, this.color});

  @override
  Widget build(BuildContext context) {
    return AnymeXText(
      subtitle,
      autoResize: true,
      maxLines: 1,
      size: 11,
      color: color ?? context.colors.onSurface.withOpacity(0.55),
    );
  }
}

class HeaderGreetingSubtitle extends StatelessWidget {
  const HeaderGreetingSubtitle({super.key});

  @override
  Widget build(BuildContext context) {
    final greetingController = Get.find<GreetingController>();
    return Obx(
      () => AnymeXText(
        greetingController.currentGreeting.value,
        autoResize: true,
        maxLines: 1,
        size: 11,
        color: context.colors.onSurface.withOpacity(0.55),
      ),
    );
  }
}

void showLibrarySortSheet(BuildContext context, LibraryController controller) =>
    AnymeXSheet.custom(
      LibrarySettingsSheet(controller: controller),
      context,
      showDragHandle: true,
    );

class LibrarySettingsSheet extends StatefulWidget {
  final LibraryController controller;
  const LibrarySettingsSheet({super.key, required this.controller});

  @override
  State<LibrarySettingsSheet> createState() => _LibrarySettingsSheetState();
}

class _LibrarySettingsSheetState extends State<LibrarySettingsSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _selectedIndex = 0;

  static const _tabs = ['Sort Options', 'Layout Settings'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index != _selectedIndex) {
        setState(() {
          _selectedIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * 0.7;
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AnymeXText(
            'Library Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 8.0),
            child: AnymeXTabBar(
              selectTabs: _tabs,
              selectedIndex: _selectedIndex,
              activeColor: theme.colorScheme.secondary,
              activeTextColor: theme.colorScheme.onSecondary,
              inactiveTextColor: theme.colorScheme.onSurfaceVariant,
              onTabSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                  _tabController.animateTo(index);
                });
              },
            ),
          ),
          const SizedBox(height: 10),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: [
                  _buildSortTab(),
                  _buildLayoutTab(),
                ][_selectedIndex],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortTab() {
    return Obx(() {
      final isHistory = widget.controller.selectedListIndex.value == -1;

      final List<Widget> sortTiles = isHistory
          ? [
              SortTile(
                title: _getLastReadTitle(widget.controller),
                sortType: SortType.lastRead,
                currentSort: widget.controller.currentSort.value,
                isAscending: widget.controller.isAscending.value,
                icon: _getLastReadIcon(widget.controller),
                onTap: () =>
                    widget.controller.handleSortChange(SortType.lastRead),
              ),
              SortTile(
                title: 'Title',
                sortType: SortType.title,
                currentSort: widget.controller.currentSort.value,
                isAscending: widget.controller.isAscending.value,
                icon: Icons.sort_by_alpha,
                onTap: () => widget.controller.handleSortChange(SortType.title),
              ),
              SortTile(
                title: _getProgressTitle(widget.controller),
                sortType: SortType.progress,
                currentSort: widget.controller.currentSort.value,
                isAscending: widget.controller.isAscending.value,
                icon: Icons.play_circle_outline,
                onTap: () =>
                    widget.controller.handleSortChange(SortType.progress),
              ),
              SortTile(
                title: 'Rating',
                sortType: SortType.rating,
                currentSort: widget.controller.currentSort.value,
                isAscending: widget.controller.isAscending.value,
                icon: Icons.star_border,
                onTap: () =>
                    widget.controller.handleSortChange(SortType.rating),
              ),
            ]
          : [
              SortTile(
                title: 'Last Added',
                sortType: SortType.lastAdded,
                currentSort: widget.controller.currentSort.value,
                isAscending: widget.controller.isAscending.value,
                icon: Icons.add_circle_outline,
                onTap: () =>
                    widget.controller.handleSortChange(SortType.lastAdded),
              ),
              SortTile(
                title: 'Title',
                sortType: SortType.title,
                currentSort: widget.controller.currentSort.value,
                isAscending: widget.controller.isAscending.value,
                icon: Icons.sort_by_alpha,
                onTap: () => widget.controller.handleSortChange(SortType.title),
              ),
              SortTile(
                title: _getLastReadTitle(widget.controller),
                sortType: SortType.lastRead,
                currentSort: widget.controller.currentSort.value,
                isAscending: widget.controller.isAscending.value,
                icon: _getLastReadIcon(widget.controller),
                onTap: () =>
                    widget.controller.handleSortChange(SortType.lastRead),
              ),
              SortTile(
                title: 'Rating',
                sortType: SortType.rating,
                currentSort: widget.controller.currentSort.value,
                isAscending: widget.controller.isAscending.value,
                icon: Icons.star_border,
                onTap: () =>
                    widget.controller.handleSortChange(SortType.rating),
              ),
              SortTile(
                title: _getProgressTitle(widget.controller),
                sortType: SortType.progress,
                currentSort: widget.controller.currentSort.value,
                isAscending: widget.controller.isAscending.value,
                icon: Icons.play_circle_outline,
                onTap: () =>
                    widget.controller.handleSortChange(SortType.progress),
              ),
              SortTile(
                title: 'Release Date',
                sortType: SortType.aired,
                currentSort: widget.controller.currentSort.value,
                isAscending: widget.controller.isAscending.value,
                icon: Icons.calendar_today,
                onTap: () => widget.controller.handleSortChange(SortType.aired),
              ),
            ];

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: sortTiles,
      );
    });
  }

  Widget _buildLayoutTab() {
    final settings = Get.find<Settings>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() {
          return AnymeXTile.slider(
            icon: Icons.grid_view_rounded,
            title: 'Grid Size',
            subtitle: 'Adjust Items per row',
            value: widget.controller.gridCount.value.toDouble(),
            min: 0.0,
            max: 10.0,
            onChanged: (e) {
              widget.controller.gridCount.value = e.toInt();
              widget.controller.savePreferences();
            },
          );
        }),
        const SizedBox(height: 12),
        Obx(() {
          return AnymeXTile.toggle(
            icon: Icons.translate_rounded,
            title: 'Use Alternate Title',
            subtitle:
                'Switch between default title and romaji/alternate title across library & cards',
            value: settings.useAlternateTitle.value,
            onChanged: (e) {
              settings.useAlternateTitle.value = e;
              General.useAlternateTitle.set(e);
            },
          );
        }),
      ],
    );
  }

  String _getLastReadTitle(LibraryController controller) {
    switch (controller.type.value) {
      case ItemType.anime:
        return 'Last Watched';
      case ItemType.manga:
        return 'Last Read';
      case ItemType.novel:
        return 'Last Read';
    }
  }

  IconData _getLastReadIcon(LibraryController controller) {
    switch (controller.type.value) {
      case ItemType.anime:
        return Icons.visibility;
      case ItemType.manga:
        return Icons.menu_book;
      case ItemType.novel:
        return Iconsax.book;
    }
  }

  String _getProgressTitle(LibraryController controller) {
    return controller.type.value == ItemType.anime
        ? 'Watch Progress'
        : 'Read Progress';
  }
}

class SortTile extends StatelessWidget {
  final String title;
  final SortType sortType;
  final SortType currentSort;
  final bool isAscending;
  final IconData icon;
  final VoidCallback onTap;

  const SortTile({
    super.key,
    required this.title,
    required this.sortType,
    required this.currentSort,
    required this.isAscending,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentSort == sortType;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.secondary.withOpacity(0.08)
            : theme.colorScheme.surfaceVariant.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.secondary.withOpacity(0.3)
              : theme.colorScheme.outline.withOpacity(0.08),
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: isSelected
              ? theme.colorScheme.secondary
              : theme.colorScheme.onSurfaceVariant,
        ),
        title: AnymeXText(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontFamily: 'Poppins',
            color: isSelected
                ? theme.colorScheme.secondary
                : theme.colorScheme.onSurface,
          ),
        ),
        trailing: isSelected
            ? Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  color: theme.colorScheme.onSecondary,
                  size: 14,
                ),
              )
            : null,
      ),
    );
  }
}

class _FloatingHeaderWrapper extends StatelessWidget {
  final Widget child;
  final EdgeInsets? margin;
  const _FloatingHeaderWrapper({required this.child, this.margin});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = Get.find<Settings>();
    final RxBool translucent = settings.transculentBar.obs;
    final isDesktop = MediaQuery.sizeOf(context).width > 600;

    final borderRadius = BorderRadius.circular(
      isDesktop ? 24.multiplyRadius() : 28.multiplyRadius(),
    );

    return Container(
      margin: margin ??
          EdgeInsets.symmetric(
            horizontal: isDesktop ? 24 : 16,
            vertical: 8,
          ),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isTranslucent
                    ? theme.colorScheme.surfaceContainer.withValues(alpha: 0.45)
                    : theme.colorScheme.surfaceContainer
                        .withValues(alpha: 0.92),
                borderRadius: borderRadius,
              ),
              child: child,
            ),
          );
        }),
      ),
    );
  }
}
