import 'dart:developer';

import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/core/Extensions/extensions_provider.dart';
import 'package:anymex/core/Extensions/fetch_anime_sources.dart';
import 'package:anymex/core/Extensions/fetch_manga_sources.dart';
import 'package:anymex/core/Extensions/fetch_novel_sources.dart';
import 'package:anymex/core/Model/Source.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/extensions/ExtensionList.dart';
import 'package:anymex/utils/StorageProvider.dart';
import 'package:anymex/utils/language.dart';
import 'package:anymex/widgets/AlertDialogBuilder.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/common/search_bar.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconsax/iconsax.dart';
import 'package:isar/isar.dart';
import '../../main.dart';

class ExtensionScreen extends ConsumerStatefulWidget {
  const ExtensionScreen({super.key});

  @override
  ConsumerState<ExtensionScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<ExtensionScreen>
    with TickerProviderStateMixin {
  late TabController _tabBarController;

  @override
  void initState() {
    super.initState();
    _checkPermission();
    _tabBarController = TabController(length: 6, vsync: this);
    _tabBarController.animateTo(0);
    _tabBarController.addListener(() {
      setState(() {
        _textEditingController.clear();
        //_isSearch = false;
      });
    });
  }

  @override
  void dispose() {
    sourceController.initExtensions();
    super.dispose();
  }

  Future<void> removeOldData() async {
    await isar.writeTxn(() async {
      await isar.sources.filter().isAddedEqualTo(false).deleteAll();
    });
  }

  Future<void> _fetchData() async {
    ref.watch(fetchMangaSourcesListProvider(id: null, reFresh: false));
    ref.watch(fetchAnimeSourcesListProvider(id: null, reFresh: false));
    ref.watch(fetchNovelSourcesListProvider(id: null, reFresh: false));
  }

  Future<void> _refreshData() async {
    await ref
        .refresh(fetchMangaSourcesListProvider(id: null, reFresh: true).future);
    await ref
        .refresh(fetchAnimeSourcesListProvider(id: null, reFresh: true).future);
    await ref
        .refresh(fetchNovelSourcesListProvider(id: null, reFresh: true).future);
  }

  _checkPermission() async {
    await StorageProvider().requestPermission();
  }

  final _textEditingController = TextEditingController();
  late var _selectedLanguage = 'all';

  void repoSheet() {
    final controller = Get.find<SourceController>();
    final animeRepoController = TextEditingController(
      text: controller.activeAnimeRepo,
    );
    final mangaRepoController = TextEditingController(
      text: controller.activeMangaRepo,
    );
    final novelRepoController = TextEditingController(
      text: controller.activeNovelRepo,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withOpacity(0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // Title and warning
                      Row(
                        children: [
                          Icon(
                            Icons.storage_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Repository Settings",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Theme.of(context).colorScheme.errorContainer,
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Theme.of(context).colorScheme.error,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Adding third-party repositories is not encouraged by the developer. Ensure you add links for both anime and manga, as using only one won't work.",
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onErrorContainer,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      Text(
                        "Anime Repository",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      CustomSearchBar(
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withOpacity(0.5),
                          width: 1.5,
                        ),
                        prefixIcon: Icons.movie_filter_outlined,
                        controller: animeRepoController,
                        onSubmitted: (value) {},
                        hintText: "Enter anime repository URL...",
                        disableIcons: true,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                      ),

                      const SizedBox(height: 20),

                      Text(
                        "Manga Repository",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      CustomSearchBar(
                        prefixIcon: Iconsax.book,
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withOpacity(0.5),
                          width: 1.5,
                        ),
                        controller: mangaRepoController,
                        onSubmitted: (value) {},
                        hintText: "Enter manga repository URL...",
                        disableIcons: true,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 0, vertical: 4),
                      ),
                      const SizedBox(height: 20),

                      Text(
                        "Novel Repository",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      CustomSearchBar(
                        prefixIcon: Iconsax.book,
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withOpacity(0.5),
                          width: 1.5,
                        ),
                        controller: novelRepoController,
                        onSubmitted: (value) {},
                        hintText: "Enter novel repository URL...",
                        disableIcons: true,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 0, vertical: 4),
                      ),

                      const SizedBox(height: 32),

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Get.back();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onSurface,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                "Cancel",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                controller.activeAnimeRepo =
                                    animeRepoController.text;
                                controller.activeMangaRepo =
                                    mangaRepoController.text;
                                await removeOldData();
                                _fetchData();
                                _refreshData();
                                Get.back();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                "Save Changes",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
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

  Future<void> _fixSources() async {
    AlertDialogBuilder(context)
      ..setTitle("Fix Sources")
      ..setMessage("Are you sure you want to fix sources?")
      ..setNegativeButton('No', () {})
      ..setPositiveButton("Yes", () async {
        await _fetchData();
        final allExtensions = await ref
            .watch(getExtensionsStreamProvider(MediaType.manga).future);

        List<int> currentInstalledAnimeExtensions = [];
        List<int> currentInstalledMangaExtensions = [];

        for (var e in allExtensions) {
          if (e.isAdded!) {
            if (e.isManga == true) {
              currentInstalledMangaExtensions.add(e.id!);
              print('Manga Extension ID: ${e.name} - ${e.id}');
            } else {
              currentInstalledAnimeExtensions.add(e.id!);
              print('Anime Extension ID: ${e.name} - ${e.id}');
            }
          }
        }

        for (int e in currentInstalledAnimeExtensions) {
          log('installing $e');
          await ref.watch(
              fetchAnimeSourcesListProvider(id: e, reFresh: true).future);
        }

        for (int e in currentInstalledMangaExtensions) {
          log('installing $e');
          await ref.watch(
              fetchMangaSourcesListProvider(id: e, reFresh: true).future);
        }
        removeOldData();
        await _fetchData();
      })
      ..show();
  }

  @override
  Widget build(BuildContext context) {
    _fetchData();
    var theme = Theme.of(context).colorScheme;
    return Glow(
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
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
                  onTap: _fixSources,
                  child: IconButton(
                      onPressed: _fixSources,
                      icon: const Icon(Icons.bug_report))),
              AnymexOnTap(
                onTap: () {
                  repoSheet();
                },
                child: IconButton(
                  icon:
                      Icon(HugeIcons.strokeRoundedGithub, color: theme.primary),
                  onPressed: () {
                    repoSheet();
                  },
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
                          setState(() => _selectedLanguage =
                              sortedLanguagesMap.keys.elementAt(index));
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
                  _buildTab(context, MediaType.anime, "Installed Anime", true),
                  _buildTab(context, MediaType.anime, "Available Anime", false),
                  _buildTab(context, MediaType.manga, "Installed Manga", true),
                  _buildTab(context, MediaType.manga, "Available Manga", false),
                  _buildTab(context, MediaType.novel, "Installed Novel", true),
                  _buildTab(context, MediaType.novel, "Available Novel", false),
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
                      mediaType: MediaType.anime,
                      selectedLanguage: _selectedLanguage,
                      showRecommended: false,
                    ),
                    Extension(
                      installed: false,
                      query: _textEditingController.text,
                      mediaType: MediaType.anime,
                      selectedLanguage: _selectedLanguage,
                    ),
                    Extension(
                      installed: true,
                      query: _textEditingController.text,
                      mediaType: MediaType.manga,
                      selectedLanguage: _selectedLanguage,
                      showRecommended: false,
                    ),
                    Extension(
                      installed: false,
                      query: _textEditingController.text,
                      mediaType: MediaType.manga,
                      selectedLanguage: _selectedLanguage,
                    ),
                    Extension(
                      installed: true,
                      query: _textEditingController.text,
                      mediaType: MediaType.novel,
                      selectedLanguage: _selectedLanguage,
                      showRecommended: false,
                    ),
                    Extension(
                      installed: false,
                      query: _textEditingController.text,
                      mediaType: MediaType.novel,
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
      BuildContext context, MediaType mediaType, String label, bool installed) {
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
          _extensionUpdateNumbers(
              context, mediaType, installed, _selectedLanguage),
        ],
      ),
    );
  }
}

Widget _extensionUpdateNumbers(BuildContext context, MediaType mediaType,
    bool installed, String selectedLanguage) {
  return StreamBuilder(
    stream: isar.sources
        .filter()
        .idIsNotNull()
        .and()
        .isAddedEqualTo(installed)
        .isActiveEqualTo(true)
        .itemTypeEqualTo(mediaType)
        .watch(fireImmediately: true),
    builder: (context, snapshot) {
      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
        final entries = snapshot.data!
            .where(
              (element) => selectedLanguage != 'all'
                  ? element.lang!.toLowerCase() ==
                      completeLanguageCode(selectedLanguage)
                  : true,
            )
            .toList();
        return entries.isEmpty
            ? Container()
            : Text(
                "(${entries.length.toString()})",
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                ),
              );
      }
      return Container();
    },
  );
}
