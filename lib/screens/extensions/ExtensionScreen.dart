import 'dart:async';

import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/database/database.dart';
import 'package:anymex/screens/extensions/ExtensionList.dart';
import 'package:anymex/screens/extensions/ExtensionTesting/extension_test_page.dart';
import 'package:anymex/screens/extensions/widgets/repo_sheet.dart';
import 'package:anymex/utils/language.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/AlertDialogBuilder.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/common/search_bar.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart'
    hide Extension, ExtensionList;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconsax/iconsax.dart';

class ExtensionScreen extends StatefulWidget {
  final bool disableGlow;
  const ExtensionScreen({super.key, this.disableGlow = false});

  @override
  State<ExtensionScreen> createState() => _ExtensionScreenState();
}

class _ExtensionScreenState extends State<ExtensionScreen>
    with TickerProviderStateMixin {
  late TabController _tabBarController;
  final _textEditingController = TextEditingController();
  final _searchQuery = ''.obs;
  final _selectedLanguage = 'all'.obs;
  final _extensionCounts = <String, int>{}.obs;

  Timer? _searchDebounce;
  List<Worker>? _workers;

  @override
  void initState() {
    super.initState();
    _tabBarController = TabController(length: 6, vsync: this);
    _tabBarController.addListener(_onTabChanged);
    _setupReactiveListeners();
    _fetchData();
    _checkPermission();
  }

  void _setupReactiveListeners() {
    _workers = [
      ever(sourceController.installedExtensions,
          (_) => _debouncedUpdateCounts()),
      ever(sourceController.installedMangaExtensions,
          (_) => _debouncedUpdateCounts()),
      ever(sourceController.installedNovelExtensions,
          (_) => _debouncedUpdateCounts()),
      ever(sourceController.availableExtensions,
          (_) => _debouncedUpdateCounts()),
      ever(sourceController.availableMangaExtensions,
          (_) => _debouncedUpdateCounts()),
      ever(sourceController.availableNovelExtensions,
          (_) => _debouncedUpdateCounts()),
      ever(_selectedLanguage, (_) => _updateExtensionCounts()),
    ];
    _updateExtensionCounts();
  }

  Timer? _countDebounce;
  void _debouncedUpdateCounts() {
    _countDebounce?.cancel();
    _countDebounce = Timer(const Duration(milliseconds: 100), () {
      _updateExtensionCounts();
    });
  }

  @override
  void dispose() {
    _tabBarController.removeListener(_onTabChanged);
    _tabBarController.dispose();
    _textEditingController.dispose();
    _searchDebounce?.cancel();
    _countDebounce?.cancel();
    if (_workers != null) {
      for (var worker in _workers!) {
        worker.dispose();
      }
    }
    super.dispose();
  }

  void _onTabChanged() {
    if (mounted) {
      _textEditingController.clear();
      _searchQuery.value = '';
    }
  }

  void _updateExtensionCounts() {
    final newCounts = <String, int>{};
    final lang = _selectedLanguage.value;

    for (final itemType in [ItemType.anime, ItemType.manga, ItemType.novel]) {
      for (final installed in [true, false]) {
        final key = '${itemType.toString()}_$installed';
        final extensions = installed
            ? sourceController.getInstalledExtensions(itemType)
            : sourceController.getAvailableExtensions(itemType);

        final filteredCount = lang == 'all'
            ? extensions.length
            : extensions
                .where(
                    (e) => e.lang?.toLowerCase() == completeLanguageCode(lang))
                .length;

        newCounts[key] = filteredCount;
      }
    }

    _extensionCounts.value = newCounts;
  }

  Future<void> _fetchData() async {
    await sourceController.fetchRepos();
    _updateExtensionCounts();
    await sourceController.sortAllExtensions();
  }

  Future<void> _checkPermission() async => await Database().requestPermission();

  void repoSheet() {
    RepoBottomSheet.show(
      context,
      onSave: _fetchData,
    );
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      _searchQuery.value = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.colors;
    return Glow(
      disabled: widget.disableGlow,
      child: DefaultTabController(
        length: 6,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: _buildAppBar(theme),
          body: Column(
            children: [
              _buildTabBar(),
              const SizedBox(height: 8.0),
              CustomSearchBar(
                disableIcons: true,
                controller: _textEditingController,
                onChanged: _onSearchChanged,
                onSubmitted: (_) {},
              ),
              const SizedBox(height: 8.0),
              Expanded(child: _buildTabBarView()),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ColorScheme theme) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: getResponsiveValue(context,
          mobileValue: Center(
            child: AnymexOnTap(
              onTap: () => Get.back(),
              child: Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  color: context.colors.surfaceContainer,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded),
              ),
            ),
          ),
          desktopValue: const SizedBox.shrink()),
      leadingWidth:
          getResponsiveValue(context, mobileValue: null, desktopValue: 0.0),
      title: Text(
        "Extensions",
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.bold,
          fontSize: 16.0,
          color: theme.primary,
        ),
      ),
      iconTheme: IconThemeData(color: theme.primary),
      actions: [
        AnymexOnTap(
          onTap: () => Get.to(() => const ExtensionTestPage()),
          child: IconButton(
            icon: Icon(Icons.build_outlined, color: theme.primary),
            onPressed: () => Get.to(() => const ExtensionTestPage()),
            tooltip: "Test Extensions",
          ),
        ),
        AnymexOnTap(
          onTap: repoSheet,
          child: IconButton(
            icon: Icon(HugeIcons.strokeRoundedGithub, color: theme.primary),
            onPressed: repoSheet,
            tooltip: "Repositories",
          ),
        ),
        AnymexOnTap(
          child: IconButton(
            icon: Icon(Iconsax.language_square, color: theme.primary),
            onPressed: () {
              AlertDialogBuilder(context)
                ..setTitle(_selectedLanguage.value)
                ..singleChoiceItems(
                  sortedLanguagesMap.keys.toList(),
                  sortedLanguagesMap.keys
                      .toList()
                      .indexOf(_selectedLanguage.value),
                  (index) {
                    final newLanguage =
                        sortedLanguagesMap.keys.elementAt(index);
                    _selectedLanguage.value = newLanguage;
                  },
                )
                ..show();
            },
            tooltip: "Language Filter",
          ),
        ),
        const SizedBox(width: 8.0),
      ],
    );
  }

  Widget _buildTabBar() {
    return Obx(() {
      final _ = _extensionCounts.value;
      return TabBar(
        indicatorSize: TabBarIndicatorSize.label,
        isScrollable: true,
        controller: _tabBarController,
        tabAlignment: TabAlignment.start,
        dragStartBehavior: DragStartBehavior.start,
        tabs: [
          _buildTab(ItemType.anime, "Installed Anime", true),
          _buildTab(ItemType.anime, "Available Anime", false),
          _buildTab(ItemType.manga, "Installed Manga", true),
          _buildTab(ItemType.manga, "Available Manga", false),
          _buildTab(ItemType.novel, "Installed Novel", true),
          _buildTab(ItemType.novel, "Available Novel", false),
        ],
      );
    });
  }

  Widget _buildTabBarView() {
    return Obx(() {
      final query = _searchQuery.value;
      final lang = _selectedLanguage.value;

      return TabBarView(
        controller: _tabBarController,
        children: [
          _buildExtensionList(
            itemType: ItemType.anime,
            installed: true,
            query: query,
            lang: lang,
            showRecommended: false,
          ),
          _buildExtensionList(
            itemType: ItemType.anime,
            installed: false,
            query: query,
            lang: lang,
          ),
          _buildExtensionList(
            itemType: ItemType.manga,
            installed: true,
            query: query,
            lang: lang,
            showRecommended: false,
          ),
          _buildExtensionList(
            itemType: ItemType.manga,
            installed: false,
            query: query,
            lang: lang,
          ),
          _buildExtensionList(
            itemType: ItemType.novel,
            installed: true,
            query: query,
            lang: lang,
            showRecommended: false,
          ),
          _buildExtensionList(
            itemType: ItemType.novel,
            installed: false,
            query: query,
            lang: lang,
          ),
        ],
      );
    });
  }

  Widget _buildExtensionList({
    required ItemType itemType,
    required bool installed,
    required String query,
    required String lang,
    bool showRecommended = true,
  }) {
    return ExtensionList(
      key: ValueKey('${itemType.name}_${installed}_${lang}'),
      installed: installed,
      query: query,
      itemType: itemType,
      selectedLanguage: lang,
      showRecommended: showRecommended,
    );
  }

  Widget _buildTab(ItemType itemType, String label, bool installed) {
    final key = '${itemType.toString()}_$installed';
    final count = _extensionCounts[key] ?? 0;

    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              fontSize: 14.0,
            ),
          ),
          if (count > 0) ...[
            const SizedBox(width: 8),
            Text(
              "($count)",
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
