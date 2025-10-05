import 'dart:async';
import 'dart:io';

import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/screens/extensions/ExtensionList.dart';
import 'package:anymex/screens/extensions/widgets/repo_sheet.dart';
import 'package:anymex/utils/language.dart';
import 'package:anymex/utils/storage_provider.dart';
import 'package:anymex/widgets/AlertDialogBuilder.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/common/search_bar.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart'
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
  State<ExtensionScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<ExtensionScreen>
    with TickerProviderStateMixin {
  late TabController _tabBarController;
  final _textEditingController = TextEditingController();
  late String _selectedLanguage = 'all';

  final Map<String, int> _extensionCounts = {};

  Timer? _updateTimer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _checkPermission();
    _tabBarController = TabController(length: 6, vsync: this);
    _tabBarController.animateTo(0);
    _tabBarController.addListener(_onTabChanged);

    _startPeriodicUpdates();
  }

  @override
  void dispose() {
    _tabBarController.removeListener(_onTabChanged);
    _tabBarController.dispose();
    _textEditingController.dispose();
    _updateTimer?.cancel();
    super.dispose();
  }

  void _onTabChanged() {
    if (mounted) {
      setState(() {
        _textEditingController.clear();
      });
    }
  }

  void _startPeriodicUpdates() {
    _updateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        _updateExtensionCounts();
      }
    });
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
            .where((element) => _selectedLanguage != 'all'
                ? element.lang!.toLowerCase() ==
                    completeLanguageCode(_selectedLanguage)
                : true)
            .length;

        newCounts[key] = filteredCount;
      }
    }

    if (_extensionCounts.toString() != newCounts.toString()) {
      setState(() {
        _extensionCounts.clear();
        _extensionCounts.addAll(newCounts);
      });
    }
  }

  Future<void> removeOldData() async {}

  Future<void> _fetchData() async {
    await sourceController.fetchRepos();
    if (mounted) {
      setState(() {});
      _updateExtensionCounts();
    }
  }

  _checkPermission() async {
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
              AnymexOnTap(
                onTap: repoSheet,
                child: IconButton(
                  icon:
                      Icon(HugeIcons.strokeRoundedGithub, color: theme.primary),
                  onPressed: repoSheet,
                ),
              ),
              AnymexOnTap(
                child: IconButton(
                  icon: Icon(Iconsax.language_square, color: theme.primary),
                  onPressed: () {
                    AlertDialogBuilder(context)
                      ..setTitle(_selectedLanguage)
                      ..singleChoiceItems(
                        sortedLanguagesMap.keys.toList(),
                        sortedLanguagesMap.keys
                            .toList()
                            .indexOf(_selectedLanguage),
                        (index) {
                          final newLanguage =
                              sortedLanguagesMap.keys.elementAt(index);
                          if (_selectedLanguage != newLanguage) {
                            setState(() => _selectedLanguage = newLanguage);
                            _updateExtensionCounts();
                          }
                        },
                      )
                      ..show();
                  },
                ),
              ),
              const SizedBox(width: 8.0),
            ],
          ),
          body: Column(
            children: [
              TabBar(
                indicatorSize: TabBarIndicatorSize.label,
                isScrollable: true,
                controller: _tabBarController,
                tabAlignment: TabAlignment.start,
                dragStartBehavior: DragStartBehavior.start,
                tabs: [
                  _buildTab(context, ItemType.anime, "Installed Anime", true),
                  _buildTab(context, ItemType.anime, "Available Anime", false),
                  _buildTab(context, ItemType.manga, "Installed Manga", true),
                  _buildTab(context, ItemType.manga, "Available Manga", false),
                  _buildTab(context, ItemType.novel, "Installed Novel", true),
                  _buildTab(context, ItemType.novel, "Available Novel", false),
                ],
              ),
              const SizedBox(height: 8.0),
              CustomSearchBar(
                  disableIcons: true,
                  controller: _textEditingController,
                  onChanged: (v) => setState(() {}),
                  onSubmitted: (v) {}),
              const SizedBox(height: 8.0),
              Expanded(
                child: TabBarView(
                  controller: _tabBarController,
                  children: [
                    Extension(
                      installed: true,
                      query: _textEditingController.text,
                      itemType: ItemType.anime,
                      selectedLanguage: _selectedLanguage,
                      showRecommended: false,
                    ),
                    Extension(
                      installed: false,
                      query: _textEditingController.text,
                      itemType: ItemType.anime,
                      selectedLanguage: _selectedLanguage,
                    ),
                    Extension(
                      installed: true,
                      query: _textEditingController.text,
                      itemType: ItemType.manga,
                      selectedLanguage: _selectedLanguage,
                      showRecommended: false,
                    ),
                    Extension(
                      installed: false,
                      query: _textEditingController.text,
                      itemType: ItemType.manga,
                      selectedLanguage: _selectedLanguage,
                    ),
                    Extension(
                      installed: true,
                      query: _textEditingController.text,
                      itemType: ItemType.novel,
                      selectedLanguage: _selectedLanguage,
                      showRecommended: false,
                    ),
                    Extension(
                      installed: false,
                      query: _textEditingController.text,
                      itemType: ItemType.novel,
                      selectedLanguage: _selectedLanguage,
                    ),
                  ],
                ),
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
