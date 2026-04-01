import 'dart:async';
import 'dart:io';

import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/database/database.dart';
import 'package:flutter/foundation.dart';
import 'package:anymex/screens/extensions/ExtensionList.dart';
import 'package:anymex/screens/extensions/ExtensionTesting/extension_test_page.dart';
import 'package:anymex/screens/extensions/widgets/plugin_manager.dart';
import 'package:anymex/screens/settings/sub_settings/settings_extensions.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/language.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/AlertDialogBuilder.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/common/search_bar.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart'
    hide Extension;
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
    with SingleTickerProviderStateMixin {
  late TabController _tabBarController;
  final _textEditingController = TextEditingController();
  final _searchQuery = ''.obs;
  final _selectedLanguage = 'all'.obs;
  final _pluginManager = PluginManager();

  Timer? _searchDebounce;
  var _lastTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabBarController = TabController(length: 6, vsync: this);
    _tabBarController.addListener(_onTabChanged);
    _checkPermission();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showPluginLoader());
  }

  void _showPluginLoader() async {
    final status = await AnymeXRuntimeBridge.isLoaded();

    if (kDebugMode) {
      _pluginManager.forceSyncLocalApk();
    } else {
      if (AnymeXRuntimeBridge.isSupportedPlatform && !status) {
        _pluginManager.ensurePluginLoaded(context);
      } else if (AnymeXRuntimeBridge.isSupportedPlatform && status) {
        _pluginManager.checkForUpdates(
          context,
          showIfUpToDate: true,
        );
      }
    }
  }

  @override
  void dispose() {
    _tabBarController.removeListener(_onTabChanged);
    _tabBarController.dispose();
    _textEditingController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onTabChanged() {
    if (!mounted) return;

    final nextIndex = _tabBarController.index;
    if (nextIndex == _lastTabIndex) return;

    _lastTabIndex = nextIndex;
    if (_textEditingController.text.isEmpty && _searchQuery.value.isEmpty) {
      return;
    }

    _textEditingController.clear();
    _searchQuery.value = '';
  }

  Future<void> _checkPermission() async => await Database().requestPermission();

  void repoSheet() {
    navigate(() => const SettingsExtensions());
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
      final lang = _selectedLanguage.value;
      return TabBar(
        indicatorSize: TabBarIndicatorSize.label,
        isScrollable: true,
        controller: _tabBarController,
        tabAlignment: TabAlignment.start,
        dragStartBehavior: DragStartBehavior.start,
        tabs: [
          _buildTab(
            "Installed Anime",
            _countFor(ItemType.anime, true, lang),
          ),
          _buildTab(
            "Available Anime",
            _countFor(ItemType.anime, false, lang),
          ),
          _buildTab(
            "Installed Manga",
            _countFor(ItemType.manga, true, lang),
          ),
          _buildTab(
            "Available Manga",
            _countFor(ItemType.manga, false, lang),
          ),
          _buildTab(
            "Installed Novel",
            _countFor(ItemType.novel, true, lang),
          ),
          _buildTab(
            "Available Novel",
            _countFor(ItemType.novel, false, lang),
          ),
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
      key: ValueKey('${itemType.name}_$installed'),
      installed: installed,
      query: query,
      itemType: itemType,
      selectedLanguage: lang,
      showRecommended: showRecommended,
    );
  }

  List<Source> _extensionsFor(ItemType itemType, bool installed) {
    return switch (itemType) {
      ItemType.anime => installed
          ? sourceController.installedExtensions
          : sourceController.availableExtensions,
      ItemType.manga => installed
          ? sourceController.installedMangaExtensions
          : sourceController.availableMangaExtensions,
      ItemType.novel => installed
          ? sourceController.installedNovelExtensions
          : sourceController.availableNovelExtensions,
    };
  }

  int _countFor(ItemType itemType, bool installed, String lang) {
    final extensions = _extensionsFor(itemType, installed);
    if (lang == 'all') return extensions.length;

    final targetLang = completeLanguageCode(lang);
    return extensions.where((e) => e.lang?.toLowerCase() == targetLang).length;
  }

  Widget _buildTab(String label, int count) {
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
