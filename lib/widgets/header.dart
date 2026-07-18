import 'dart:ui';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/controllers/theme.dart';
import 'package:anymex/controllers/ui/greeting.dart';
import 'package:anymex/screens/manga/widgets/search_selector.dart';
import 'package:anymex/screens/search/search_view.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/custom_widgets/anymex_animated_logo.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/non_widgets/settings_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:anymex/screens/profile/profile_page.dart';
import 'package:anymex/screens/library/controller/library_controller.dart';
import 'package:anymex/widgets/custom_widgets/anymex_bottomsheet.dart';
import 'package:anymex/widgets/custom_widgets/custom_expansion_tile.dart';
import 'package:anymex/screens/library/widgets/library_deps.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';

enum PageType { manga, anime, home, novel, library }

class Header extends StatelessWidget {
  final PageType type;
  const Header({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final profileData = Get.find<ServiceHandler>();
    final greetingController = Get.find<GreetingController>();

    return Obx(() {
      final isDesktop = MediaQuery.of(context).size.width > 600;
      final isLibrarySearchActive = type == PageType.library &&
          Get.isRegistered<LibraryController>() &&
          Get.find<LibraryController>().isSearchActive.value;

      if (isLibrarySearchActive) {
        final libraryController = Get.find<LibraryController>();
        final searchContent = Row(
          children: [
            GestureDetector(
              onTap: libraryController.toggleSearch,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: context.colors.secondaryContainer.opaque(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_back_ios_new,
                    color: context.colors.primary, size: 16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: libraryController.searchController,
                onChanged: libraryController.search,
                autofocus: true,
                style: const TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                decoration: InputDecoration(
                  hintText: 'Search in Library...',
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
        return _FloatingHeaderWrapper(child: searchContent);
      }

      if (isDesktop) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _FloatingHeaderWrapper(
              margin: const EdgeInsets.fromLTRB(24, 8, 0, 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  type == PageType.home
                      ? _buildActionButtons(context, profileData)
                      : _profileIcon(context, profileData),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildHeaderTitle(
                          context, greetingController, profileData),
                      _buildHeaderSubtitle(
                          context, greetingController, profileData),
                    ],
                  ),
                ],
              ),
            ),
            _FloatingHeaderWrapper(
              margin: const EdgeInsets.fromLTRB(0, 8, 24, 8),
              child: type == PageType.home
                  ? _profileIcon(context, profileData)
                  : _buildActionButtons(context, profileData),
            ),
          ],
        );
      } else {
        final content = Row(
          children: [
            type == PageType.home
                ? _buildActionButtons(context, profileData)
                : _profileIcon(context, profileData),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildHeaderTitle(context, greetingController, profileData),
                _buildHeaderSubtitle(context, greetingController, profileData),
              ],
            ),
            const Spacer(),
            type == PageType.home
                ? _profileIcon(context, profileData)
                : _buildActionButtons(context, profileData),
          ],
        );
        return _FloatingHeaderWrapper(child: content);
      }
    });
  }

  Widget _buildHeaderTitle(BuildContext context,
      GreetingController greetingController, ServiceHandler profileData) {
    final isSimkl = profileData.serviceType.value == ServicesType.simkl;

    switch (type) {
      case PageType.home:
        return Text(
          "AnymeX",
          style: TextStyle(
            fontFamily: "Poppins-Bold",
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: context.colors.primary,
          ),
        );
      case PageType.anime:
        return Text(
          isSimkl ? "Movies" : "Anime",
          style: const TextStyle(
            fontFamily: "Poppins-Bold",
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        );
      case PageType.manga:
        return Text(
          isSimkl ? "Series" : "Manga",
          style: const TextStyle(
            fontFamily: "Poppins-Bold",
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        );
      case PageType.novel:
        return const Text(
          "Novels",
          style: TextStyle(
            fontFamily: "Poppins-Bold",
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        );
      case PageType.library:
        return const Text(
          "Library",
          style: TextStyle(
            fontFamily: "Poppins-Bold",
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        );
    }
  }

  Widget _buildHeaderSubtitle(BuildContext context,
      GreetingController greetingController, ServiceHandler profileData) {
    if (type == PageType.library) {
      return Text(
        "Discover favorites",
        style: TextStyle(
          fontSize: 11,
          color: context.colors.onSurface.withOpacity(0.55),
        ),
      );
    }

    final greeting = greetingController.currentGreeting.value;
    return Text(
      greeting,
      style: TextStyle(
        fontSize: 11,
        color: context.colors.onSurface.withOpacity(0.55),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ServiceHandler profileData) {
    final list = <Widget>[];

    if (type == PageType.library && Get.isRegistered<LibraryController>()) {
      final libraryController = Get.find<LibraryController>();
      list.add(
        _PillIconButton(
          onPressed: libraryController.toggleSearch,
          icon:
              Icon(IconlyLight.search, color: context.colors.primary, size: 18),
          context: context,
        ),
      );
      list.add(const SizedBox(width: 8));
      list.add(
        _PillIconButton(
          onPressed: () => _showSortingSettings(context, libraryController),
          icon: Icon(Icons.sort, color: context.colors.primary, size: 18),
          context: context,
        ),
      );
    } else if (type == PageType.home) {
      list.add(
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: context.colors.secondaryContainer.opaque(0.5),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: AnymeXAnimatedLogo(
              size: 36,
              color: context.colors.primary,
            ),
          ),
        ),
      );
    } else {
      if (profileData.serviceType.value == ServicesType.extensions) {
        list.add(
          _PillIconButton(
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
            icon: Icon(
              Get.theme.brightness == Brightness.light
                  ? HugeIcons.strokeRoundedSun03
                  : HugeIcons.strokeRoundedMoon01,
              color: context.colors.primary,
              size: 18,
            ),
            context: context,
          ),
        );
      } else {
        list.add(
          _PillIconButton(
            onPressed: () => _handleSearchPress(context, profileData),
            icon: Icon(IconlyLight.search,
                color: context.colors.primary, size: 18),
            context: context,
          ),
        );
      }
    }

    return Row(children: list);
  }

  void _handleSearchPress(BuildContext context, ServiceHandler profileData) {
    final hasNovelExts = sourceController.installedNovelExtensions.isNotEmpty;
    final isSimkl = profileData.serviceType.value == ServicesType.simkl;

    if (type == PageType.manga) {
      if (isSimkl) {
        navigate(() => const SearchPage(searchTerm: '', isManga: false));
        return;
      }
      if (!hasNovelExts) {
        navigate(() => const SearchPage(searchTerm: '', isManga: true));
        return;
      }
      searchTypeSheet(context);
    } else {
      navigate(() => const SearchPage(searchTerm: '', isManga: false));
    }
  }

  AnymexOnTap _profileIcon(BuildContext context, ServiceHandler profileData) {
    return AnymexOnTap(
      onTap: () => SettingsSheet.show(context),
      child: GestureDetector(
        onLongPress: () {
          if (profileData.isLoggedIn.value) {
            navigate(() => const ProfilePage());
          }
        },
        child: CircleAvatar(
          radius: 20,
          backgroundColor: context.colors.secondaryContainer.opaque(0.50),
          child: profileData.isLoggedIn.value
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: AnymeXImage(
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    radius: 0,
                    errorImage: '',
                    imageUrl: profileData.profileData.value.avatar ?? '',
                  ),
                )
              : Icon(IconlyBold.profile,
                  color: context.colors.onSecondaryContainer, size: 18),
        ),
      ),
    );
  }

  void _showSortingSettings(
          BuildContext context, LibraryController controller) =>
      AnymexSheet(
        title: 'Settings',
        contentWidget: StatefulBuilder(
          builder: (context, setState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnymexExpansionTile(
                      title: 'Sort By',
                      initialExpanded: true,
                      content: Obx(() {
                        final isHistory =
                            controller.selectedListIndex.value == -1;
                        return Column(children: [
                          Row(
                            children: [
                              _SortBox(
                                title: 'Title',
                                currentSort: controller.currentSort.value,
                                sortType: SortType.title,
                                isAscending: controller.isAscending.value,
                                onTap: () {
                                  controller.handleSortChange(SortType.title);
                                },
                                icon: Icons.sort_by_alpha,
                              ),
                              if (!isHistory)
                                _SortBox(
                                  title: 'Last Added',
                                  currentSort: controller.currentSort.value,
                                  sortType: SortType.lastAdded,
                                  isAscending: controller.isAscending.value,
                                  onTap: () {
                                    controller
                                        .handleSortChange(SortType.lastAdded);
                                  },
                                  icon: Icons.add_circle_outline,
                                ),
                              if (isHistory)
                                _SortBox(
                                  title: _getLastReadTitle(controller),
                                  currentSort: controller.currentSort.value,
                                  sortType: SortType.lastRead,
                                  isAscending: controller.isAscending.value,
                                  onTap: () {
                                    controller
                                        .handleSortChange(SortType.lastRead);
                                  },
                                  icon: _getLastReadIcon(controller),
                                ),
                            ],
                          ),
                          if (!isHistory)
                            Row(
                              children: [
                                _SortBox(
                                  title: _getLastReadTitle(controller),
                                  currentSort: controller.currentSort.value,
                                  sortType: SortType.lastRead,
                                  isAscending: controller.isAscending.value,
                                  onTap: () {
                                    controller
                                        .handleSortChange(SortType.lastRead);
                                  },
                                  icon: _getLastReadIcon(controller),
                                ),
                                _SortBox(
                                  title: 'Rating',
                                  currentSort: controller.currentSort.value,
                                  sortType: SortType.rating,
                                  isAscending: controller.isAscending.value,
                                  onTap: () {
                                    controller
                                        .handleSortChange(SortType.rating);
                                  },
                                  icon: Icons.star_border,
                                ),
                              ],
                            ),
                        ]);
                      }),
                    ),
                    AnymexExpansionTile(
                      title: 'Grid',
                      content: Column(
                        children: [
                          Obx(() {
                            return CustomSliderTile(
                              icon: Icons.grid_view_rounded,
                              title: 'Grid Size',
                              description: 'Adjust Items per row',
                              sliderValue:
                                  controller.gridCount.value.toDouble(),
                              onChanged: (e) {
                                controller.gridCount.value = e.toInt();
                                controller.savePreferences();
                              },
                              max: 10,
                            );
                          })
                        ],
                      ),
                    ),
                    20.height()
                  ],
                ),
              ),
            );
          },
        ),
      ).show(context);

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
    final isDesktop = MediaQuery.of(context).size.width > 600;

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

class _PillIconButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget icon;
  final BuildContext context;

  const _PillIconButton({
    required this.onPressed,
    required this.icon,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: context.colors.secondaryContainer.opaque(0.5),
          shape: BoxShape.circle,
        ),
        child: Center(child: icon),
      ),
    );
  }
}

class _SortBox extends StatelessWidget {
  final String title;
  final SortType currentSort;
  final SortType sortType;
  final bool isAscending;
  final VoidCallback onTap;
  final IconData icon;

  const _SortBox({
    required this.title,
    required this.currentSort,
    required this.sortType,
    required this.isAscending,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentSort == sortType;
    final theme = Theme.of(context);

    return Expanded(
      child: SizedBox(
        height: 90,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          child: Material(
            clipBehavior: Clip.antiAlias,
            elevation: isSelected ? 3 : 0,
            shadowColor: isSelected
                ? theme.colorScheme.primary.opaque(0.4, iReallyMeanIt: true)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: onTap,
              splashColor:
                  theme.colorScheme.primary.opaque(0.15, iReallyMeanIt: true),
              highlightColor:
                  theme.colorScheme.primary.opaque(0.05, iReallyMeanIt: true),
              child: Container(
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.colorScheme.primary
                                .opaque(0.15, iReallyMeanIt: true),
                            theme.colorScheme.primaryContainer,
                          ],
                        )
                      : null,
                  color: isSelected
                      ? null
                      : theme.colorScheme.surfaceVariant
                          .opaque(0.7, iReallyMeanIt: true),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline
                            .opaque(0.2, iReallyMeanIt: true),
                    width: isSelected ? 1.5 : 0.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        if (isSelected)
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.colorScheme.primary
                                  .opaque(0.12, iReallyMeanIt: true),
                            ),
                          ),
                        Icon(
                          icon,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                          size: 24,
                        ),
                        if (isSelected)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isAscending
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                color: theme.colorScheme.onPrimary,
                                size: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      child: AnymexText(
                        text: title,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
