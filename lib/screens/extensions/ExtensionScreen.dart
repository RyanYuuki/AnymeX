import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/core/Extensions/fetch_anime_sources.dart';
import 'package:anymex/core/Extensions/fetch_manga_sources.dart';
import 'package:anymex/core/Model/Source.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/extensions/ExtensionList.dart';
import 'package:anymex/utils/StorageProvider.dart';
import 'package:anymex/utils/language.dart';
import 'package:anymex/widgets/AlertDialogBuilder.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/common/search_bar.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/custom_widgets/custom_button.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
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
    _tabBarController = TabController(length: 4, vsync: this);
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

  void repoSheet() {
    final controller = Get.find<SourceController>();
    final animeRepoController = TextEditingController(
      text: controller.activeAnimeRepo,
    );
    final mangaRepoController = TextEditingController(
      text: controller.activeMangaRepo,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: AnymexText(
                    text: "Add Repository",
                    size: 20,
                    variant: TextVariant.semiBold,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHigh),
                  padding: const EdgeInsets.all(7),
                  child: Text(
                    "WARNING: Adding third-party repositories is not encouraged by the developer. Also make sure to add links for both anime and manga, it won’t work if you add only one.",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),

                // Anime Repository Input
                const Padding(
                  padding: EdgeInsets.only(left: 5, bottom: 5),
                  child: Text(
                    "Anime Repository",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                CustomSearchBar(
                  prefixIcon: Icons.movie_filter_outlined,
                  controller: animeRepoController,
                  onSubmitted: (value) {},
                  hintText: "Add Anime Repo...",
                  disableIcons: true,
                  padding: const EdgeInsets.all(0),
                ),

                const SizedBox(height: 15),

                // Manga Repository Input
                const Padding(
                  padding: EdgeInsets.only(left: 5, bottom: 5),
                  child: Text(
                    "Manga Repository",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                CustomSearchBar(
                  prefixIcon: Iconsax.book,
                  controller: mangaRepoController,
                  onSubmitted: (value) {},
                  hintText: "Add Manga Repo...",
                  disableIcons: true,
                  padding: const EdgeInsets.all(0),
                ),

                const SizedBox(height: 20),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TVWrapper(
                        onTap: () {
                          Get.back();
                        },
                        child: AnymeXButton(
                          height: 50,
                          width: double.infinity,
                          borderRadius: BorderRadius.circular(30),
                          backgroundColor:
                              Theme.of(context).colorScheme.secondaryContainer,
                          variant: ButtonVariant.outline,
                          onTap: () {
                            Get.back();
                          },
                          child: const Text("Cancel"),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TVWrapper(
                        onTap: () async {
                          controller.activeAnimeRepo = animeRepoController.text;
                          controller.activeMangaRepo = mangaRepoController.text;
                          removeOldData();
                          _fetchData();
                          _refreshData();
                          Get.back();
                          await removeOldData();
                        },
                        child: AnymeXButton(
                          height: 50,
                          width: double.infinity,
                          borderRadius: BorderRadius.circular(30),
                          backgroundColor:
                              Theme.of(context).colorScheme.secondaryContainer,
                          variant: ButtonVariant.outline,
                          onTap: () async {
                            controller.activeAnimeRepo =
                                animeRepoController.text;
                            controller.activeMangaRepo =
                                mangaRepoController.text;
                            await removeOldData();
                            _fetchData();
                            _refreshData();
                            Get.back();
                          },
                          child: const Text("Confirm"),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
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
              TVWrapper(
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
              TVWrapper(
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
