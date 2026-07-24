import 'dart:ui';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/controllers/theme.dart';
import 'package:anymex/controllers/ui/greeting.dart';
import 'package:anymex/screens/manga/widgets/search_selector.dart';
import 'package:anymex/screens/search/search_view.dart';
import 'package:anymex/screens/search/source_search_page.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/custom_widgets/anymex_animated_logo.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';
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
import 'package:anymex/screens/library/widgets/library_deps.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:anymex/widgets/legacy_header.dart' as legacy;
import 'package:anymex/widgets/custom_widgets/anymex_tabbar.dart';
import 'package:anymex/screens/extensions/ExtensionTesting/extension_test_page.dart';
import 'package:anymex/screens/settings/sub_settings/settings_extensions.dart';

enum PageType { manga, anime, home, novel, library, extensions }

class Header extends StatelessWidget {
  final PageType type;
  const Header({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final profileData = Get.find<ServiceHandler>();
    final greetingController = Get.find<GreetingController>();

    return Obx(() {
      if (settingsController.useLegacyHeader) {
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

        legacy.PageType legacyType;
        switch (type) {
          case PageType.manga:
            legacyType = legacy.PageType.manga;
            break;
          case PageType.anime:
            legacyType = legacy.PageType.anime;
            break;
          case PageType.home:
            legacyType = legacy.PageType.home;
            break;
          case PageType.novel:
            legacyType = legacy.PageType.novel;
            break;
          case PageType.library:
            legacyType = legacy.PageType.library;
            break;
          case PageType.extensions:
            legacyType = legacy.PageType.extensions;
            break;
        }

        final libraryController = Get.isRegistered<LibraryController>()
            ? Get.find<LibraryController>()
            : null;

        return legacy.Header(
          type: legacyType,
          onSearchPressed: libraryController != null
              ? () => libraryController.toggleSearch()
              : null,
          onSortPressed: libraryController != null
              ? () => _showSortingSettings(context, libraryController)
              : null,
        );
      }
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
      case PageType.extensions:
        return const Text(
          "Extensions",
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
        "All your local shi",
        style: TextStyle(
          fontSize: 11,
          color: context.colors.onSurface.withOpacity(0.55),
        ),
      );
    }
    if (type == PageType.extensions) {
      return Text(
        "Manage plugins & sources",
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
    } else if (type == PageType.extensions) {
      list.add(
        _PillIconButton(
          onPressed: () => Get.to(() => const ExtensionTestPage()),
          icon: Icon(Icons.build_outlined, color: context.colors.primary, size: 18),
          context: context,
        ),
      );
      list.add(const SizedBox(width: 8));
      list.add(
        _PillIconButton(
          onPressed: () => navigate(() => const SettingsExtensions()),
          icon: Icon(HugeIcons.strokeRoundedGithub, color: context.colors.primary, size: 18),
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
        final itemType = type == PageType.manga
            ? ItemType.manga
            : (type == PageType.novel ? ItemType.novel : ItemType.anime);
        list.add(
          _PillIconButton(
            onPressed: () {
              navigateWithAnimation(() => SourceSearchPage(
                    initialTerm: '',
                    type: itemType,
                    source: null,
                  ));
            },
            icon: Icon(
              IconlyLight.search,
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
        child: Obx(() {
          final count = Get.find<SourceController>().extensionUpdatesCount.value;
          final avatar = CircleAvatar(
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
          );
          if (count > 0) {
            return Badge(
              label: Text(count.toString()),
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

  void _showSortingSettings(
          BuildContext context, LibraryController controller) =>
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) {
          return LibrarySettingsSheet(controller: controller);
        },
      );
}

class LibrarySettingsSheet extends StatefulWidget {
  final LibraryController controller;
  const LibrarySettingsSheet({super.key, required this.controller});

  @override
  State<LibrarySettingsSheet> createState() => LibrarySettingsSheetState();
}

class LibrarySettingsSheetState extends State<LibrarySettingsSheet>
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
    final maxH = MediaQuery.of(context).size.height * 0.75;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 16 + bottomInset),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxH),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, -2),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 3.5,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const Text(
                'Library Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
        ),
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
                onTap: () =>
                    widget.controller.handleSortChange(SortType.title),
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
                onTap: () =>
                    widget.controller.handleSortChange(SortType.title),
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
                title: 'Popularity',
                sortType: SortType.popularity,
                currentSort: widget.controller.currentSort.value,
                isAscending: widget.controller.isAscending.value,
                icon: Icons.trending_up,
                onTap: () =>
                    widget.controller.handleSortChange(SortType.popularity),
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
                onTap: () =>
                    widget.controller.handleSortChange(SortType.aired),
              ),
            ];

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: sortTiles,
      );
    });
  }

  Widget _buildLayoutTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() {
          return CustomSliderTile(
            icon: Icons.grid_view_rounded,
            title: 'Grid Size',
            description: 'Adjust Items per row',
            sliderValue: widget.controller.gridCount.value.toDouble(),
            onChanged: (e) {
              widget.controller.gridCount.value = e.toInt();
              widget.controller.savePreferences();
            },
            max: 10,
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
    return controller.type.value == ItemType.anime ? 'Watch Progress' : 'Read Progress';
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
        title: Text(
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
