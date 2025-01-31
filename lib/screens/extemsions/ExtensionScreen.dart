import 'dart:developer';

import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/core/Extensions/fetch_anime_sources.dart';
import 'package:anymex/core/Extensions/fetch_manga_sources.dart';
import 'package:anymex/core/Model/Source.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/extemsions/ExtensionList.dart';
import 'package:anymex/utils/StorageProvider.dart';
import 'package:anymex/utils/language.dart';
import 'package:anymex/widgets/AlertDialogBuilder.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/common/search_bar.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
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
    _tabBarController = TabController(length: 4, vsync: this);
    _tabBarController.animateTo(0);
    _tabBarController.addListener(() {
      setState(() {
        _textEditingController.clear();
        //_isSearch = false;
      });
    });
  }

  Future<void> _fetchData() async {
    ref.watch(fetchMangaSourcesListProvider(id: null, reFresh: false));
    ref.watch(fetchAnimeSourcesListProvider(id: null, reFresh: false));
  }

  Future<void> _refreshData() async {
    await ref
        .refresh(fetchMangaSourcesListProvider(id: null, reFresh: true).future);
    await ref
        .refresh(fetchAnimeSourcesListProvider(id: null, reFresh: true).future);
  }

  _checkPermission() async {
    await StorageProvider().requestPermission();
  }

  final _textEditingController = TextEditingController();
  late var _selectedLanguage = 'all';

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
              IconButton(
                icon: Icon(Icons.language_rounded, color: theme.primary),
                onPressed: () {
                  final controller = Get.find<SourceController>();
                  final animeRepoController = TextEditingController(
                    text: controller.activeAnimeRepo,
                  );
                  final mangaRepoController = TextEditingController(
                    text: controller.activeMangaRepo,
                  );

                  AlertDialogBuilder(context)
                    ..setTitle("Add Repo")
                    ..setCustomView(
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomSearchBar(
                            controller: animeRepoController,
                            onSubmitted: (value) {},
                            hintText: "Add Anime Repo...",
                            disableIcons: true,
                          ),
                          const SizedBox(height: 10), // Add spacing between fields
                          CustomSearchBar(
                            controller: mangaRepoController,
                            onSubmitted: (value) {},
                            hintText: "Add Manga Repo...",
                            disableIcons: true,
                          ),
                        ],
                      ),
                    )
                    ..setPositiveButton("Confirm", () async {
                      if (animeRepoController.text.isNotEmpty) {
                        controller.activeAnimeRepo = animeRepoController.text;
                      }
                      if (mangaRepoController.text.isNotEmpty) {
                        controller.activeMangaRepo = mangaRepoController.text;
                      }

                      await _fetchData();
                      await _refreshData();
                    })
                    ..show();
                },
              ),
              IconButton(
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
                  _buildTab(
                      context, MediaType.anime, "Installed Anime", false, true),
                  _buildTab(context, MediaType.anime, "Available Anime", false,
                      false),
                  _buildTab(
                      context, MediaType.manga, "Installed Manga", true, true),
                  _buildTab(
                      context, MediaType.manga, "Available Manga", true, false),
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
                    ),
                    Extension(
                      installed: false,
                      query: _textEditingController.text,
                      mediaType: MediaType.manga,
                      selectedLanguage: _selectedLanguage,
                    ),
                    // Extension(
                    //   installed: true,
                    //   query: _textEditingController.text,
                    //   MediaType: MediaType.novel,
                    //   selectedLanguage: _selectedLanguage,
                    // ),
                    // Extension(
                    //   installed: false,
                    //   query: _textEditingController.text,
                    //   MediaType: MediaType.novel,
                    //   selectedLanguage: _selectedLanguage,
                    // ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(BuildContext context, MediaType MediaType, String label,
      bool isManga, bool installed) {
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
              context, MediaType, installed, _selectedLanguage),
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
        .isMangaEqualTo(mediaType == MediaType.manga)
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
