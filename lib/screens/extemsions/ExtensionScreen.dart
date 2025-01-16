import 'package:anymex/api/Mangayomi/Extensions/fetch_anime_sources.dart';
import 'package:anymex/api/Mangayomi/Extensions/fetch_manga_sources.dart';
import 'package:anymex/api/Mangayomi/Model/Source.dart';
import 'package:anymex/screens/extemsions/ExtensionList.dart';
import 'package:anymex/utils/StorageProvider.dart';
import 'package:anymex/utils/language.dart';
import 'package:anymex/widgets/AlertDialogBuilder.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/common/search_bar.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../api/Mangayomi/Model/Manga.dart';
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
              SizedBox(width: 8.0),
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
                      context, ItemType.anime, "Anime Installed", false, true),
                  _buildTab(
                      context, ItemType.anime, "Anime Available", false, false),
                  _buildTab(
                      context, ItemType.manga, "Manga Installed", true, true),
                  _buildTab(
                      context, ItemType.manga, "Manga Available", true, false),
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
                    ),
                    Extension(
                      installed: false,
                      query: _textEditingController.text,
                      itemType: ItemType.manga,
                      selectedLanguage: _selectedLanguage,
                    ),
                    // Extension(
                    //   installed: true,
                    //   query: _textEditingController.text,
                    //   itemType: ItemType.novel,
                    //   selectedLanguage: _selectedLanguage,
                    // ),
                    // Extension(
                    //   installed: false,
                    //   query: _textEditingController.text,
                    //   itemType: ItemType.novel,
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

  Widget _buildTab(BuildContext context, ItemType itemType, String label,
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
              context, itemType, installed, _selectedLanguage),
        ],
      ),
    );
  }
}

Widget _extensionUpdateNumbers(BuildContext context, ItemType itemType,
    bool installed, String selectedLanguage) {
  return StreamBuilder(
    stream: isar.sources
        .filter()
        .idIsNotNull()
        .and()
        .isAddedEqualTo(installed)
        .isActiveEqualTo(true)
        .isMangaEqualTo(itemType == ItemType.manga)
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
