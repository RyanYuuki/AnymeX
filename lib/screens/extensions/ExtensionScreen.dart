import 'dart:async';

import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/screens/extensions/ExtensionList.dart';
import 'package:anymex/screens/extensions/widgets/repo_sheet.dart';
import 'package:anymex/screens/extensions/ExtensionTesting/extension_test_page.dart';
import 'package:anymex/utils/language.dart';
import 'package:anymex/utils/storage_provider.dart';
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
  final RxString _selectedLanguage = 'all'.obs;
  final RxMap<String, int> _extensionCounts = <String, int>{}.obs;

  List<Worker>? _workers;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _checkPermission();
    _tabBarController = TabController(length: 6, vsync: this);
    _tabBarController.animateTo(0);
    _tabBarController.addListener(_onTabChanged);

    _setupReactiveListeners();
  }

  void _setupReactiveListeners() {
    _workers = [
      ever(sourceController.installedExtensions,
          (_) => _updateExtensionCounts()),
      ever(sourceController.installedMangaExtensions,
          (_) => _updateExtensionCounts()),
      ever(sourceController.installedNovelExtensions,
          (_) => _updateExtensionCounts()),
      ever(_selectedLanguage, (_) => _updateExtensionCounts()),
    ];

    _updateExtensionCounts();
  }

  @override
  void dispose() {
    _tabBarController.removeListener(_onTabChanged);
    _tabBarController.dispose();
    _textEditingController.dispose();

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
    }
  }

  void _updateExtensionCounts() {
    final newCounts = <String, int>{};

    for (final itemType in [ItemType.anime, ItemType.manga, ItemType.novel]) {
      for (final installed in [true, false]) {
        final key = '${itemType.toString()}_$installed';
        final extensions = installed
            ? sourceController.getInstalledExtensions(itemType)
            : sourceController.getAvailableExtensions(itemType);

        final filteredCount = extensions
            .where((element) => _selectedLanguage.value != 'all'
                ? element.lang!.toLowerCase() ==
                    completeLanguageCode(_selectedLanguage.value)
                : true)
            .length;

        newCounts[key] = filteredCount;
      }
    }

    _extensionCounts.value = newCounts;
    sourceController.availableExtensions.refresh();
    sourceController.availableMangaExtensions.refresh();
    sourceController.availableNovelExtensions.refresh();
  }

  Future<void> _fetchData() async {
    await sourceController.fetchRepos();
    Future.microtask(() {
      _updateExtensionCounts();

      if (mounted) {
        setState(() {});
      }
    });

    await sourceController.sortAllExtensions();
  }

  Future<void> _checkPermission() async {
    await StorageProvider().requestPermission();
  }

  void repoSheet() {
    RepoBottomSheet.show(
      context,
      onSave: _fetchData,
    );
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context).colorScheme;
    return Glow(
      disabled: widget.disableGlow,
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
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
                            color:
                                Theme.of(context).colorScheme.surfaceContainer),
                        child: const Icon(Icons.arrow_back_ios_new_rounded)),
                  ),
                ),
                desktopValue: const SizedBox.shrink()),
            leadingWidth: getResponsiveValue(context,
                mobileValue: null, desktopValue: 0.0),
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
              // Extension Test Button
              AnymexOnTap(
                onTap: () => Get.to(() => const ExtensionTestPage()),
                child: IconButton(
                  icon:
                      Icon(Icons.build_outlined, color: theme.primary),
                  onPressed: () => Get.to(() => const ExtensionTestPage()),
                  tooltip: "Test Extensions",
                ),
              ),
              // Repository Settings Button
              AnymexOnTap(
                onTap: repoSheet,
                child: IconButton(
                  icon:
                      Icon(HugeIcons.strokeRoundedGithub, color: theme.primary),
                  onPressed: repoSheet,
                  tooltip: "Repositories",
                ),
              ),
              // Language Filter Button
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
                          if (_selectedLanguage.value != newLanguage) {
                            _selectedLanguage.value = newLanguage;
                          }
                        },
                      )
                      ..show();
                  },
                  tooltip: "Language Filter",
                ),
              ),
              const SizedBox(width: 8.0),
            ],
          ),
          body: Column(
            children: [
              Obx(() => TabBar(
                    indicatorSize: TabBarIndicatorSize.label,
                    isScrollable: true,
                    controller: _tabBarController,
                    tabAlignment: TabAlignment.start,
                    dragStartBehavior: DragStartBehavior.start,
                    tabs: [
                      _buildTab(
                          context, ItemType.anime, "Installed Anime", true),
                      _buildTab(
                          context, ItemType.anime, "Available Anime", false),
                      _buildTab(
                          context, ItemType.manga, "Installed Manga", true),
                      _buildTab(
                          context, ItemType.manga, "Available Manga", false),
                      _buildTab(
                          context, ItemType.novel, "Installed Novel", true),
                      _buildTab(
                          context, ItemType.novel, "Available Novel", false),
                    ],
                  )),
              const SizedBox(height: 8.0),
              CustomSearchBar(
                  disableIcons: true,
                  controller: _textEditingController,
                  onChanged: (v) => setState(() {}),
                  onSubmitted: (v) {}),
              const SizedBox(height: 8.0),
              Expanded(
                child: Obx(() {
                  return TabBarView(
                    controller: _tabBarController,
                    children: [
                      ExtensionList(
                        key: ValueKey(
                            'anime_installed_${_selectedLanguage.value}_${sourceController.activeAnimeRepo}'),
                        installed: true,
                        query: _textEditingController.text,
                        itemType: ItemType.anime,
                        selectedLanguage: _selectedLanguage.value,
                        showRecommended: false,
                      ),
                      ExtensionList(
                        key: ValueKey(
                            'anime_available_${_selectedLanguage.value}_${sourceController.activeAnimeRepo}'),
                        installed: false,
                        query: _textEditingController.text,
                        itemType: ItemType.anime,
                        selectedLanguage: _selectedLanguage.value,
                      ),
                      ExtensionList(
                        key: ValueKey(
                            'manga_installed_${_selectedLanguage.value}_${sourceController.activeMangaRepo}'),
                        installed: true,
                        query: _textEditingController.text,
                        itemType: ItemType.manga,
                        selectedLanguage: _selectedLanguage.value,
                        showRecommended: false,
                      ),
                      ExtensionList(
                        key: ValueKey(
                            'manga_available_${_selectedLanguage.value}_${sourceController.activeMangaRepo}'),
                        installed: false,
                        query: _textEditingController.text,
                        itemType: ItemType.manga,
                        selectedLanguage: _selectedLanguage.value,
                      ),
                      ExtensionList(
                        key: ValueKey(
                            'novel_installed_${_selectedLanguage.value}_${sourceController.activeNovelRepo}'),
                        installed: true,
                        query: _textEditingController.text,
                        itemType: ItemType.novel,
                        selectedLanguage: _selectedLanguage.value,
                        showRecommended: false,
                      ),
                      ExtensionList(
                        key: ValueKey(
                            'novel_available_${_selectedLanguage.value}_${sourceController.activeNovelRepo}'),
                        installed: false,
                        query: _textEditingController.text,
                        itemType: ItemType.novel,
                        selectedLanguage: _selectedLanguage.value,
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(
      BuildContext context, ItemType itemType, String label, bool installed) {
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
          const SizedBox(width: 8),
          _buildExtensionCount(itemType, installed),
        ],
      ),
    );
  }

  Widget _buildExtensionCount(ItemType itemType, bool installed) {
    final key = '${itemType.toString()}_$installed';
    final count = _extensionCounts[key] ?? 0;

    return count > 0
        ? Text(
            "($count)",
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
            ),
          )
        : const SizedBox.shrink();
  }
}