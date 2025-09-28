import 'dart:async';
import 'dart:io';

import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/screens/extensions/ExtensionList.dart';
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
  const ExtensionScreen({super.key});

  @override
  State<ExtensionScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<ExtensionScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
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
    final controller = Get.find<SourceController>();
    final isAndroid = Platform.isAndroid;

    final selectedTab = 0.obs;

    late final TextEditingController animeRepoController;
    late final TextEditingController mangaRepoController;
    late final TextEditingController novelRepoController;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) {
        return Obx(
          () {
            final type = isAndroid && selectedTab.value == 1
                ? ExtensionType.aniyomi
                : ExtensionType.mangayomi;

            animeRepoController = TextEditingController(
              text: sourceController.getAnimeRepo(type),
            );
            mangaRepoController = TextEditingController(
              text: sourceController.getMangaRepo(type),
            );
            novelRepoController = TextEditingController(
              text: controller.activeNovelRepo,
            );

            void onTabChanged(int index) {
              selectedTab.value = index;
            }

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 32,
                        height: 3,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Text(
                        "Repository Settings",
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 24),
                      if (isAndroid)
                        Container(
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => onTabChanged(0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    decoration: BoxDecoration(
                                      color: selectedTab.value == 0
                                          ? Theme.of(context)
                                              .colorScheme
                                              .surface
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: selectedTab.value == 0
                                          ? [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.1),
                                                blurRadius: 4,
                                                offset: const Offset(0, 1),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Text(
                                      "Mangayomi",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: selectedTab.value == 0
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: selectedTab.value == 0
                                            ? Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => onTabChanged(1),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    decoration: BoxDecoration(
                                      color: selectedTab.value == 1
                                          ? Theme.of(context)
                                              .colorScheme
                                              .surface
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: selectedTab.value == 1
                                          ? [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.1),
                                                blurRadius: 4,
                                                offset: const Offset(0, 1),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Text(
                                      "Aniyomi",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: selectedTab.value == 1
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: selectedTab.value == 1
                                            ? Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .errorContainer
                              .withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .error
                                .withOpacity(0.2),
                          ),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Theme.of(context).colorScheme.error,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Third-party repositories are not officially supported",
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onErrorContainer,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (selectedTab.value == 0) ...[
                        _buildRepoField(
                          context,
                          "Anime Repository",
                          animeRepoController,
                          Icons.play_circle_outline,
                          "Enter anime repository URL",
                        ),
                        const SizedBox(height: 16),
                        _buildRepoField(
                          context,
                          "Manga Repository",
                          mangaRepoController,
                          Icons.book_outlined,
                          "Enter manga repository URL",
                        ),
                        const SizedBox(height: 16),
                        _buildRepoField(
                          context,
                          "Novel Repository",
                          novelRepoController,
                          Icons.menu_book_outlined,
                          "Enter novel repository URL",
                        ),
                      ] else ...[
                        _buildRepoField(
                          context,
                          "Anime Repository",
                          animeRepoController,
                          Icons.play_circle_outline,
                          "Enter anime repository URL",
                        ),
                        const SizedBox(height: 16),
                        _buildRepoField(
                          context,
                          "Manga Repository",
                          mangaRepoController,
                          Icons.book_outlined,
                          "Enter manga repository URL",
                        ),
                      ],
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                animeRepoController.dispose();
                                mangaRepoController.dispose();
                                novelRepoController.dispose();
                                Get.back();
                              },
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                "Cancel",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                print(
                                    '${type.name} - ${animeRepoController.text}');
                                controller.setAnimeRepo(
                                    animeRepoController.text, type);
                                controller.setMangaRepo(
                                    mangaRepoController.text, type);
                                if (selectedTab.value == 0) {
                                  controller.activeNovelRepo =
                                      novelRepoController.text;
                                }

                                animeRepoController.dispose();
                                mangaRepoController.dispose();
                                novelRepoController.dispose();

                                await _fetchData();
                                Get.back();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                "Save",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRepoField(
    BuildContext context,
    String label,
    TextEditingController controller,
    IconData icon,
    String hint,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var theme = Theme.of(context).colorScheme;
    return Glow(
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
