// ignore_for_file: prefer_const_constructors, deprecated_member_use, non_constant_identifier_names, must_be_immutable, avoid_print, use_build_context_synchronously

import 'dart:developer';
import 'dart:io';
import 'package:anymex/api/Mangayomi/Eval/dart/model/m_chapter.dart';
import 'package:anymex/api/Mangayomi/Eval/dart/model/m_manga.dart';
import 'package:anymex/api/Mangayomi/Extensions/extensions_provider.dart';
import 'package:anymex/api/Mangayomi/Model/Source.dart';
import 'package:anymex/api/Mangayomi/Search/get_detail.dart';
import 'package:anymex/api/Mangayomi/Search/search.dart';
import 'package:anymex/auth/auth_provider.dart';
import 'package:anymex/components/android/anilistExclusive/wrong_tile_manga.dart';
import 'package:anymex/components/android/common/IconWithLabel.dart';
import 'package:anymex/components/android/common/custom_slider.dart';
import 'package:anymex/components/android/common/expandable_page_view.dart';
import 'package:anymex/components/android/common/reusable_carousel.dart';
import 'package:anymex/components/android/anime/details/character_cards.dart';
import 'package:anymex/components/android/manga/chapter_ranges.dart';
import 'package:anymex/components/android/manga/chapters.dart';
import 'package:anymex/components/common/navbar.dart';
import 'package:anymex/components/desktop/anime/character_cards.dart';
import 'package:anymex/components/desktop/horizontal_list.dart';
import 'package:anymex/components/desktop/manga/chapters.dart';
import 'package:anymex/components/platform_builder.dart';
import 'package:anymex/fallbackData/anilist_manga_homepage.dart';
import 'package:anymex/hiveData/appData/database.dart';
import 'package:anymex/models/server.dart';
import 'package:anymex/pages/Anime/widgets/goto_extensions.dart';
import 'package:anymex/pages/Manga/deps/chapter_recognition.dart';
import 'package:anymex/pages/Manga/read_page.dart';
import 'package:anymex/utils/apiHooks/anilist/anime/details_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as rp;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

dynamic genrePreviews = {
  'Action': 'https://s4.anilist.co/file/anilistcdn/media/anime/banner/1735.jpg',
  'Adventure':
      'https://s4.anilist.co/file/anilistcdn/media/anime/banner/154587-ivXNJ23SM1xB.jpg',
  'School':
      'https://s4.anilist.co/file/anilistcdn/media/anime/banner/21459-yeVkolGKdGUV.jpg',
  'Shounen':
      'https://s4.anilist.co/file/anilistcdn/media/anime/banner/101922-YfZhKBUDDS6L.jpg',
  'Super Power':
      'https://s4.anilist.co/file/anilistcdn/media/anime/banner/21087-sHb9zUZFsHe1.jpg',
  'Supernatural':
      'https://s4.anilist.co/file/anilistcdn/media/anime/banner/113415-jQBSkxWAAk83.jpg',
  'Slice of Life':
      'https://s4.anilist.co/file/anilistcdn/media/anime/banner/133965-spTi0WE7jR0r.jpg',
  'Romance':
      'https://s4.anilist.co/file/anilistcdn/media/anime/banner/162804-NwvD3Lya8IZp.jpg',
  'Fantasy':
      'https://s4.anilist.co/file/anilistcdn/media/anime/banner/108465-RgsRpTMhP9Sv.jpg',
  'Comedy':
      'https://s4.anilist.co/file/anilistcdn/media/anime/banner/100922-ef1bBJCUCfxk.jpg',
  'Mystery':
      'https://s4.anilist.co/file/anilistcdn/media/anime/banner/110277-iuGn6F5bK1U1.jpg',
  'default':
      'https://s4.anilist.co/file/anilistcdn/media/anime/banner/1-OquNCNB6srGe.jpg'
};

class MangaDetailsPage extends StatefulWidget {
  final int id;
  final String? posterUrl;
  final String? tag;
  const MangaDetailsPage({
    super.key,
    required this.id,
    this.posterUrl,
    this.tag,
  });

  @override
  State<MangaDetailsPage> createState() => _MangaDetailsPageState();
}

class _MangaDetailsPageState extends State<MangaDetailsPage>
    with TickerProviderStateMixin {
  bool usingSaikouLayout =
      Hive.box('app-data').get('usingSaikouLayout', defaultValue: false);
  dynamic data;
  bool isLoading = true;
  dynamic altdata;
  dynamic charactersdata;
  String? description;
  late AnimationController _controller;
  late Animation<double> _animation;
  int selectedIndex = 0;
  PageController pageController = PageController();
  late bool isFavourite;

  // Chapter section
  MManga? mangaData;

  // Manga Sources
  late int chapterProgress;

  // Group Sorting
  String? activeGroup;
  List<MChapter>? groupChapters;

  // Layout Buttons
  List<IconData> layoutIcons = [
    IconlyBold.image,
    Icons.list_rounded,
    Iconsax.grid_25
  ];
  int layoutIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchData();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);
    isFavourite = Provider.of<AppData>(context, listen: false)
        .getMangaAvail(widget.id.toString());
    chapterProgress = returnMangaProgress();
    _animation = Tween<double>(begin: -1.0, end: -2.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));
    _initExtensions();
  }

  // Mangayomi Extensions
  dynamic streamExtensions;
  List<Source>? installedExtensions;
  Source? activeSource;

  List<Server> serverList = [];

  Future<void> _initExtensions() async {
    final container = rp.ProviderContainer();
    final sourcesAsyncValue =
        await container.read(getExtensionsStreamProvider(true).future);
    installedExtensions =
        sourcesAsyncValue.where((source) => source.isAdded!).toList();
    activeSource = installedExtensions?[0] ?? Source();
  }

  @override
  void dispose() {
    _controller.dispose();
    pageController.dispose();
    super.dispose();
  }

  String? errorMessage;

  Future<void> mapToAnilist({bool isFirstTime = true, Source? source}) async {
    try {
      final finalSource = source ?? activeSource;
      var searchData = await search(
        source: finalSource!,
        query: data['name'],
        page: 1,
        filterList: [],
      );
      print('Length is ${searchData!.list.length}');
      if (searchData.list.isEmpty) {
        searchData = await search(
          source: finalSource,
          query: data['name'].split(' ').first,
          page: 1,
          filterList: [],
        );
      }

      if (searchData?.list.isEmpty ?? true) {
        throw Exception("No Manga found for the provided query.");
      }

      final animeList = searchData!.list;
      final matchedAnime = animeList.firstWhere(
        (an) => an.name == data['jname'] || an.name == data['name'],
        orElse: () => animeList[0],
      );
      final episodeFuture = await getDetail(
        url: matchedAnime.link!,
        source: finalSource,
      );

      episodeFuture.chapters = episodeFuture.chapters!.reversed.toList();
      episodeFuture.name = matchedAnime.name ?? '??';
      setState(() {
        mangaData = episodeFuture;
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      log("Error in mapToAnilist: $e");
      setState(() {
        isLoading = false;
        errorMessage = "Failed to fetch episodes: ${e.toString()}";
      });
    }
  }

  Future<void> fetchData() async {
    try {
      final tempdata = await fetchAnimeInfo(widget.id);
      if (mounted) {
        setState(() {
          data = tempdata;
          description = data?['description'];
          description = data['description'] ?? data?['description'];
          charactersdata = data['characters'] ?? [];
          altdata = data;
          isLoading = false;
        });
      }
      await mapToAnilist();
    } catch (e) {
      log('Failed to fetch Anime Info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme customScheme = Theme.of(context).colorScheme;

    Widget currentPage = usingSaikouLayout
        ? saikouDetailsPage(context)
        : originalDetailsPage(customScheme, context);

    return PlatformBuilder(
      androidBuilder: Scaffold(
        extendBody: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        bottomNavigationBar: (altdata?['status'] != 'CANCELLED' &&
                altdata?['status'] != 'NOT_YET_RELEASED' &&
                data != null)
            ? bottomBar(context)
            : null,
        body: currentPage,
      ),
      desktopBuilder: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              height: 300,
              child: ResponsiveNavBar(
                backgroundColor: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(50),
                fit: true,
                isDesktop: true,
                currentIndex: selectedIndex + 1,
                margin: const EdgeInsets.fromLTRB(20, 30, 15, 10),
                items: [
                  NavItem(
                    selectedIcon: Iconsax.arrow_left5,
                    unselectedIcon: Iconsax.arrow_left,
                    label: "Back",
                    onTap: (index) => {Navigator.pop(context)},
                  ),
                  NavItem(
                      selectedIcon: Iconsax.info_circle5,
                      unselectedIcon: Iconsax.info_circle,
                      label: "Info",
                      onTap: (index) => setState(() {
                            selectedIndex = 0;
                            pageController.animateToPage(0,
                                duration: Duration(milliseconds: 300),
                                curve: Curves.linear);
                          })),
                  NavItem(
                      selectedIcon: Iconsax.book,
                      unselectedIcon: Iconsax.book,
                      label: "Read",
                      onTap: (index) => setState(() {
                            selectedIndex = 1;
                            pageController.animateToPage(1,
                                duration: Duration(milliseconds: 300),
                                curve: Curves.linear);
                          })),
                ],
              ),
            ),
            Expanded(child: currentPage),
          ],
        ),
      ),
    );
  }

  double getProperSize(double size) {
    if (size >= 0.0 && size < 5.0) {
      return 50.0;
    } else if (size >= 5.0 && size < 10.0) {
      return 45.0;
    } else if (size >= 10.0 && size < 15.0) {
      return 40.0;
    } else if (size >= 15.0 && size < 20.0) {
      return 35.0;
    } else if (size >= 20.0 && size < 25.0) {
      return 30.0;
    } else if (size >= 25.0 && size < 30.0) {
      return 25.0;
    } else if (size >= 30.0 && size < 35.0) {
      return 20.0;
    } else if (size >= 35.0 && size < 40.0) {
      return 15.0;
    } else if (size >= 40.0 && size < 45.0) {
      return 10.0;
    } else if (size >= 45.0 && size < 50.0) {
      return 5.0;
    } else {
      return 0.0;
    }
  }

  ResponsiveNavBar bottomBar(BuildContext context) {
    return ResponsiveNavBar(
      isDesktop: false,
      fit: true,
      currentIndex: selectedIndex,
      borderRadius: BorderRadius.circular(16),
      margin: const EdgeInsets.fromLTRB(80, 0, 80, 20),
      items: [
        NavItem(
            selectedIcon: Iconsax.info_circle5,
            unselectedIcon: Iconsax.info_circle,
            label: "Info",
            onTap: (index) => setState(() {
                  selectedIndex = index;
                  pageController.animateToPage(index,
                      duration: Duration(milliseconds: 300),
                      curve: Curves.linear);
                })),
        NavItem(
            selectedIcon: Iconsax.book,
            unselectedIcon: Iconsax.book,
            label: "Read",
            onTap: (index) => setState(() {
                  selectedIndex = 1;
                  pageController.animateToPage(1,
                      duration: Duration(milliseconds: 300),
                      curve: Curves.linear);
                })),
      ],
    );
  }

  String checkAvailability(BuildContext context) {
    final animeList = Provider.of<AniListProvider>(context, listen: false)
        .userData?['mangaList'];

    final matchingAnime = animeList?.firstWhere(
      (anime) => anime?['media']?['id']?.toString() == widget.id.toString(),
      orElse: () => null,
    );

    if (matchingAnime != null) {
      String status = matchingAnime['status'];

      switch (status) {
        case 'CURRENT':
          return 'Currently Reading';
        case 'COMPLETED':
          return 'Completed';
        case 'PAUSED':
          return 'Paused';
        case 'DROPPED':
          return 'Dropped';
        case 'PLANNING':
          return 'Planning to Read';
        case 'REPEATING':
          return 'REREADING';
        default:
          return 'Add To List';
      }
    }

    return 'Add To List';
  }

  double? getSize() {
    if (selectedIndex == 1) {
      Future.delayed(Duration(seconds: 1), () => 700);
    }
    return 1950;
  }

  Scaffold saikouDetailsPage(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SingleChildScrollView(
        child: Column(
          children: [
            saikouTopSection(context),
            if (isLoading)
              Padding(
                padding: const EdgeInsets.only(top: 30.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              ExpandablePageView(
                controller: pageController,
                itemCount: 2,
                itemBuilder: (context, page) {
                  return page == 0 ? saikouDetails(context) : chapterSection();
                },
              ),
          ],
        ),
      ),
    );
  }

  MChapter? getChapterId({
    required MManga mangaData,
    required int progress,
  }) {
    List<MChapter>? ChapterList = mangaData.chapters;
    final matchingCh = ChapterList!.firstWhere((chapter) =>
        extractChapterNumber(chapter.name!).toString() ==
        progress.toDouble().toString());
    return matchingCh;
  }

  void initializeChapters() {
    groupChapters = mangaData?.chapters;
    if (mangaData?.chapters != null) {
      groupChapters = mangaData!.chapters;
      setState(() {
        int step;
        int length = groupChapters!.length;

        if (length > 50 && length < 100) {
          step = 24;
        } else if (length > 200 && length < 300) {
          step = 40;
        } else if (length > 300) {
          step = 50;
        } else {
          step = 12;
        }

        chapterRanges = getChapterRanges(groupChapters!, step);

        filteredChapters = groupChapters!.where((chapter) {
          double chapterNumber = extractChapterNumber(chapter.name!);
          return chapterNumber >= chapterRanges[0][0] &&
              chapterNumber <= chapterRanges[0][1];
        }).toList();
      });
    }
  }

  double extractChapterNumber(String title) {
    return ChapterRecognition.parseChapterNumber(data['name'], title)
        .toDouble();
  }

  List<List<double>> getChapterRanges(List<MChapter> chapters, int step) {
    List<List<double>> ranges = [];
    int length = chapters.length;

    for (int i = 0; i < length; i += step) {
      double start = extractChapterNumber(chapters[i].name!);
      double end;

      if ((i + step) >= length) {
        end = extractChapterNumber(chapters.last.name!);
      } else {
        end = extractChapterNumber(chapters[i + step - 1].name!);
      }

      List<double> range = start <= end ? [start, end] : [end, start];

      bool isDuplicate = false;
      for (var existingRange in ranges) {
        if (existingRange[0] == range[0] && existingRange[1] == range[1]) {
          isDuplicate = true;
          break;
        }
      }

      if (!isDuplicate) {
        ranges.add(range);
      }
    }

    return ranges;
  }

  List<List<double>> chapterRanges = [];
  List<MChapter>? filteredChapters = [];

  Widget chapterSection() {
    if (mangaData?.chapters != null && chapterRanges.isEmpty) {
      initializeChapters();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 0, 20, 100),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),
          Text(
            'Found: ${mangaData?.name ?? '?'}',
            style: TextStyle(fontFamily: 'Poppins-SemiBold'),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: installedExtensions?.isEmpty ?? true
                ? "No Sources Installed"
                : '${activeSource!.name} (${activeSource!.lang?.toUpperCase()})',
            decoration: InputDecoration(
              labelText: activeSource != null
                  ? 'Select Source'
                  : "No Sources Installed",
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              labelStyle: TextStyle(
                  fontFamily: "Poppins-SemiBold",
                  color: Theme.of(context).colorScheme.inverseSurface),
              border: OutlineInputBorder(
                borderSide:
                    BorderSide(color: Theme.of(context).colorScheme.primary),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.onPrimaryFixedVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide:
                    BorderSide(color: Theme.of(context).colorScheme.primary),
              ),
            ),
            isExpanded: true,
            items: [
              if (installedExtensions?.isEmpty ?? true)
                DropdownMenuItem<String>(
                  value: "No Sources Installed",
                  child: Text(
                    "No Sources Installed",
                    style: const TextStyle(fontFamily: 'Poppins-SemiBold'),
                  ),
                ),
              ...?installedExtensions?.map<DropdownMenuItem<String>>((source) {
                return DropdownMenuItem<String>(
                  value: '${source.name} (${source.lang?.toUpperCase()})',
                  child: Text(
                    '${source.name} (${source.lang?.toUpperCase()})',
                    style: const TextStyle(fontFamily: 'Poppins-SemiBold'),
                  ),
                );
              }),
            ],
            onChanged: (value) async {
              try {
                final selectedSource = installedExtensions?.firstWhere(
                    (source) =>
                        '${source.name} (${source.lang?.toUpperCase()})' ==
                        value);

                if (selectedSource == null) {
                  throw Exception("Selected source not found.");
                }

                setState(() {
                  mangaData = null;
                  activeSource = selectedSource;
                });

                await mapToAnilist(source: selectedSource);
                initializeChapters();
              } catch (e) {
                log(e.toString());
              }
            },
            dropdownColor: Theme.of(context).colorScheme.surface,
            icon: Icon(Icons.arrow_drop_down,
                color: Theme.of(context).colorScheme.primary),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                showMangaSearchModal(
                  context,
                  data['name'],
                  (mangaId) async {
                    setState(() {
                      filteredChapters = null;
                    });
                    final chapterData =
                        await getDetail(url: mangaId, source: activeSource!);
                    setState(() {
                      mangaData = chapterData;
                      mangaData!.chapters =
                          chapterData.chapters!.reversed.toList();
                      activeGroup = null;
                      initializeChapters();
                    });
                  },
                  activeSource!,
                );
              },
              child: Stack(
                children: [
                  Text('Wrong Title?',
                      style: TextStyle(
                        fontFamily: 'Poppins-Bold',
                      )),
                  Positioned(
                    bottom: 0,
                    child: Container(
                      width: 100,
                      height: 1,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                ],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Chapters',
                  style:
                      TextStyle(fontSize: 18, fontFamily: 'Poppins-SemiBold')),
              // IconButton(
              //   style: ElevatedButton.styleFrom(
              //       backgroundColor:
              //           Theme.of(context).colorScheme.surfaceContainer),
              //   onPressed: () {
              //     setState(() {
              //       layoutIndex++;
              //       if (layoutIndex > layoutIcons.length - 1) {
              //         layoutIndex = 0;
              //       }
              //     });
              //   },
              //   icon: Icon(layoutIcons[layoutIndex]),
              // )
            ],
          ),
          const SizedBox(height: 10),
          if (activeSource == null) ...[
            NoSourceSelectedWidget(),
          ] else ...[
            if (mangaData != null)
              InkWell(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ReadingPage(
                                id: getChapterId(
                                    mangaData: mangaData!,
                                    progress: returnMangaProgress())!,
                                mangaId: mangaData?.link ?? '',
                                posterUrl: widget.posterUrl!,
                                currentSource: activeSource!,
                                anilistId: data['id'].toString(),
                                chapterList: mangaData!.chapters!,
                                description: data['description'],
                                mangaTitle: data['name'],
                              )));
                },
                child: Container(
                  height: 75,
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Theme.of(context).colorScheme.primary),
                    borderRadius: BorderRadius.circular(20),
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                      image: NetworkImage(data?['cover'] ??
                          data?['poster'] ??
                          widget.posterUrl),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.7),
                                Colors.black.withOpacity(0.7),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          returnMangaProgressString(),
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                              fontSize: 16,
                              fontFamily: 'Poppins-SemiBold'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              height: 40,
              child: ChapterRanges(
                chapterRanges: chapterRanges,
                onRangeSelected: (range) {
                  setState(() {
                    filteredChapters = groupChapters!
                        .where((episode) =>
                            extractChapterNumber(episode.name!) >= range[0] &&
                            extractChapterNumber(episode.name!) <= range[1])
                        .toList();
                  });
                },
              ),
            ),
            const SizedBox(height: 10),
            if (mangaData == null || filteredChapters == null)
              SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()))
            else
              PlatformBuilder(
                desktopBuilder: DesktopChapterList(
                  id: mangaData!.link ?? "",
                  posterUrl: widget.posterUrl,
                  chaptersData: filteredChapters!,
                  currentSource: activeSource!,
                  anilistId: data['id'].toString(),
                  rawChapters: mangaData!.chapters,
                  description: data['description'],
                  title: data['name'],
                ),
                androidBuilder: ChapterList(
                  id: mangaData?.link,
                  posterUrl: widget.posterUrl,
                  chaptersData: filteredChapters!,
                  currentSource: activeSource!,
                  anilistId: data['id'].toString(),
                  rawChapters: mangaData!.chapters,
                  description: data['description'],
                  mangaTitle: data['name'],
                ),
              )
          ],
        ],
      ),
    );
  }

  String selectedStatus = 'CURRENT';
  double score = 1.0;

  double getScore() {
    if (mounted) {
      final mangaList = Provider.of<AniListProvider>(context, listen: false)
          .userData["mangaList"];
      if (mangaList == null) {
        return 1.0;
      }

      final matchingManga = mangaList.firstWhere(
        (anime) => anime?['media']?['id'] == widget.id,
        orElse: () => null,
      );
      log("Matches Anime: $matchingManga");
      return double.tryParse((matchingManga?['score'])?.toString() ?? '1') ??
          1.0;
    } else {
      return 1.0;
    }
  }

  String getStatus() {
    if (mounted) {
      final mangaList = Provider.of<AniListProvider>(context, listen: false)
          .userData["mangaList"];
      if (mangaList == null) {
        return "CURRENT";
      }

      final matchingManga = mangaList.firstWhere(
        (anime) => anime?['media']?['id'] == widget.id,
        orElse: () => null,
      );
      return matchingManga?['status'] ?? "CURRENT";
    } else {
      return "CURRENT";
    }
  }

  void showListEditorModal(BuildContext context, String totalEpisodes) {
    selectedStatus = getStatus();
    score = getScore();
    showModalBottomSheet(
      backgroundColor: Theme.of(context).colorScheme.surface,
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 30.0,
                  right: 30.0,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 40.0,
                  top: 20.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'List Editor',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Status Dropdown
                    SizedBox(
                      height: 55,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.transparent,
                          prefixIcon: Icon(Icons.playlist_add),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              width: 1,
                              color:
                                  Theme.of(context).colorScheme.inversePrimary,
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              width: 1,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          labelText: 'Status',
                          labelStyle: const TextStyle(
                            fontFamily: 'Poppins-Bold',
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: selectedStatus,
                            items: [
                              'PLANNING',
                              'CURRENT',
                              'COMPLETED',
                              'PAUSED',
                              'DROPPED',
                            ].map((String status) {
                              return DropdownMenuItem<String>(
                                value: status,
                                child: Text(status),
                              );
                            }).toList(),
                            onChanged: (String? newStatus) {
                              setState(() {
                                selectedStatus = newStatus!;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 55,
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.add),
                          suffixText: '/$totalEpisodes',
                          filled: true,
                          fillColor: Colors.transparent,
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              width: 1,
                              color:
                                  Theme.of(context).colorScheme.inversePrimary,
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              width: 1,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          labelText: 'Progress',
                          labelStyle: const TextStyle(
                            fontFamily: 'Poppins-Bold',
                          ),
                        ),
                        initialValue: chapterProgress.toString(),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (String value) {
                          int? newProgress = int.tryParse(value);
                          if (newProgress != null && newProgress >= 0) {
                            setState(() {
                              if (totalEpisodes == '?') {
                                chapterProgress = newProgress;
                              } else {
                                int totalEp = int.parse(totalEpisodes);
                                chapterProgress = newProgress <= totalEp
                                    ? newProgress
                                    : totalEp;
                              }
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Icon(Icons.star,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Score: ${score.toStringAsFixed(1)}/10',
                          style: const TextStyle(
                            fontFamily: 'Poppins-Bold',
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    CustomSlider(
                      enableComfortPadding: true,
                      value: score,
                      min: 0.0,
                      max: 10.0,
                      divisions: 100,
                      label: score.toStringAsFixed(1),
                      activeColor: Theme.of(context).colorScheme.primary,
                      inactiveColor:
                          Theme.of(context).colorScheme.secondaryContainer,
                      onChanged: (double newValue) {
                        setState(() {
                          score = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Provider.of<AniListProvider>(context, listen: false)
                                .deleteMangaFromList(mangaId: widget.id);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.surface,
                            side: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .inversePrimary),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18)),
                          ),
                          child: const Text('Delete'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Provider.of<AniListProvider>(context, listen: false)
                                .updateMangaList(
                                    mangaId: data['id'],
                                    chapterProgress: chapterProgress,
                                    rating: score,
                                    status: selectedStatus);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.surface,
                            side: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .inversePrimary),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18)),
                          ),
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  int returnMangaProgress() {
    final animeList = Provider.of<AniListProvider>(context, listen: false)
        .userData?['mangaList'];

    if (animeList == null) return 1;

    final matchingAnime = animeList.firstWhere(
      (anime) => anime?['media']?['id'] == widget.id,
      orElse: () => null,
    );

    return matchingAnime?['progress'] ?? 1;
  }

  String returnMangaProgressString() {
    final animeList = Provider.of<AniListProvider>(context, listen: false)
        .userData?['mangaList'];

    if (animeList == null) return "Read: Chapter 1";

    final matchingAnime = animeList.firstWhere(
      (anime) => anime?['media']?['id'] == widget.id,
      orElse: () => null,
    );

    if (matchingAnime == null) return "Read: Chapter 1";

    return 'Continue: Chapter ${matchingAnime?['progress']}';
  }

  Column saikouDetails(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 25.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text.rich(
                    TextSpan(
                      text: 'Read ',
                      style: TextStyle(fontSize: 15),
                      children: [
                        TextSpan(
                          text: "${returnMangaProgress()} ",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontFamily: 'Poppins-Bold',
                          ),
                        ),
                        TextSpan(text: 'Out of ${data?['totalChapters']}')
                      ],
                    ),
                  ),
                  Expanded(child: SizedBox.shrink()),
                  IconButton(
                      onPressed: () {
                        if (mangaData != null && data != null) {
                          setState(() {
                            isFavourite = !isFavourite;
                          });
                          // if (isFavourite) {
                          //   Provider.of<AppData>(context, listen: false)
                          //       .addReadManga(
                          //           mangaId: mangaData['id'],
                          //           mangaTitle: mangaData['title'],
                          //           currentChapter: chapterProgress.toString(),
                          //           mangaPosterImage: widget.posterUrl!,
                          //           anilistMangaId: widget.id.toString(),
                          //           currentSource:
                          //               mangaSourceHandler.selectedSourceName!,
                          //           chapterList: mangaData['chapterList'],
                          //           description: data['description']);
                          // } else {
                          //   Provider.of<AppData>(context, listen: false)
                          //       .removeMangaByAnilistId(widget.id.toString());
                          // }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainer,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              content: Text(
                                  'What are you? flash? you${"'"}re gonna have to wait few secs',
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .inverseSurface))));
                        }
                      },
                      icon: Icon(isFavourite ? Iconsax.heart5 : Iconsax.heart)),
                  IconButton(onPressed: () {}, icon: Icon(Icons.share)),
                ],
              ),
              const SizedBox(height: 20),
              infoRow(
                  field: 'Rating',
                  value:
                      '${data?['malscore']?.toString() ?? ((data?['rating'])).toString()}/10'),
              // infoRow(
              //     field: 'Studios',
              //     value: data?['studios'] ?? data?['studios']?[0] ?? '??'),
              infoRow(
                  field: 'Total Chapters',
                  value: data['totalChapters'].toString()),
              infoRow(field: 'Type', value: 'TV'),
              infoRow(
                  field: 'Romaji Name',
                  value: data?['jname'] ?? data?['japanese'] ?? '??'),
              infoRow(field: 'Premiered', value: data?['premiered'] ?? '??'),
              infoRow(field: 'Duration', value: '${data?['duration']}' ''),
              const SizedBox(height: 20),
              Text('Synopsis', style: TextStyle(fontFamily: 'Poppins-Bold')),
              const SizedBox(height: 10),
              Text(description!.toString().length > 250
                  ? '${description!.toString().substring(0, 250)}...'
                  : description!),

              // Grid Section
              const SizedBox(height: 20),
              Text('Genres', style: TextStyle(fontFamily: 'Poppins-Bold')),
              Flexible(
                flex: 0,
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: data?['genres'].length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisExtent: 55,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemBuilder: (context, itemIndex) {
                    String genre = data?['genres'][itemIndex];
                    String buttonBackground =
                        genrePreviews[genre] ?? genrePreviews['default'];

                    return Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15)),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(2.3),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                image: DecorationImage(
                                  image: NetworkImage(buttonBackground),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          // Gradient overlay
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                  width: 3,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainer),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withOpacity(0.5),
                                  Colors.black.withOpacity(0.5)
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                          ),
                          // ElevatedButton
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: () {},
                            child: Text(
                              genre.toUpperCase(),
                              style: TextStyle(
                                fontFamily: 'Poppins-Bold',
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        PlatformBuilder(
            androidBuilder: CharacterCards(
              isManga: true,
              carouselData: charactersdata,
            ),
            desktopBuilder: HorizontalCharacterCards(
              isManga: true,
              carouselData: charactersdata,
            )),
        PlatformBuilder(
            androidBuilder: ReusableCarousel(
              title: 'Related',
              carouselData: data?['relations'],
              detailsPage: true,
              secondary: false,
            ),
            desktopBuilder: HorizontalList(
              title: 'Related',
              carouselData: data?['relations'],
              detailsPage: true,
              secondary: false,
            )),
        PlatformBuilder(
            androidBuilder: ReusableCarousel(
              title: 'Recommended',
              carouselData: data?['recommendations'],
              detailsPage: true,
              isManga: true,
            ),
            desktopBuilder: HorizontalList(
              title: 'Recommended',
              carouselData: data?['recommendations'],
              detailsPage: true,
              isManga: true,
            )),
        const SizedBox(height: 100),
      ],
    );
  }

  Stack saikouTopSection(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        if (altdata?['cover'] != null && (Platform.isAndroid || Platform.isIOS))
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Positioned(
                left: MediaQuery.of(context).size.width * _animation.value,
                child: CachedNetworkImage(
                  height: 450,
                  fit: BoxFit.cover,
                  imageUrl: altdata?['cover'] ?? widget.posterUrl,
                  errorWidget: (context, url, error) => CachedNetworkImage(
                    height: 450,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    imageUrl: widget.posterUrl!,
                  ),
                ),
              );
            },
          )
        else
          CachedNetworkImage(
            height: 450,
            fit: BoxFit.cover,
            imageUrl: altdata?['cover'] ?? widget.posterUrl,
            errorWidget: (context, url, error) => CachedNetworkImage(
              height: 450,
              width: double.infinity,
              fit: BoxFit.cover,
              imageUrl: widget.posterUrl!,
            ),
          ),
        Positioned(
          child: Container(
            height: 455,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Theme.of(context).colorScheme.surface.withOpacity(0.7),
                  Theme.of(context).colorScheme.surface,
                ],
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomLeft,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Hero(
                      tag: widget.tag!,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          height: 170,
                          width: 120,
                          imageUrl: widget.posterUrl!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      height: 180,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.5,
                            child: Text(
                              data?['name'] ?? 'Loading...',
                              style: TextStyle(
                                fontFamily: 'Poppins-Bold',
                                fontSize: 16,
                                overflow: TextOverflow.ellipsis,
                              ),
                              maxLines: 4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            altdata?['status'] ??
                                data?['status'] ??
                                'RELEASING',
                            style: TextStyle(
                              fontFamily: 'Poppins-Bold',
                              color: Theme.of(context).colorScheme.primary,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 50,
                width: MediaQuery.of(context).size.width - 40,
                child: ElevatedButton(
                  onPressed: () {
                    if (Provider.of<AniListProvider>(context, listen: false)
                            .userData?['user']?['name'] ==
                        null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          backgroundColor:
                              Theme.of(context).colorScheme.surfaceContainer,
                          content: Text(
                            'Login on AniList First!',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                      );
                    } else {
                      showListEditorModal(context, data['chapters'] ?? '?');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        width: 2,
                        color: Theme.of(context).colorScheme.surfaceContainer,
                      ),
                    ),
                  ),
                  child: Text(
                    (checkAvailability(context)).toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontFamily: 'Poppins-Bold',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 30,
          right: 20,
          child: Material(
            borderOnForeground: false,
            color: Colors.transparent,
            child: IconButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(Icons.close),
            ),
          ),
        ),
      ],
    );
  }

  Scaffold originalDetailsPage(ColorScheme CustomScheme, BuildContext context) {
    return Scaffold(
      backgroundColor: CustomScheme.surface,
      body: isLoading
          ? Column(
              children: [
                Center(
                  child: Poster(
                    context,
                    tag: widget.tag,
                    poster: widget.posterUrl,
                    isLoading: true,
                  ),
                ),
                const SizedBox(height: 30),
                CircularProgressIndicator(),
              ],
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  Poster(
                    context,
                    isLoading: false,
                    tag: widget.tag,
                    poster: widget.posterUrl,
                  ),
                  const SizedBox(height: 30),
                  Info(context),
                ],
              ),
            ),
    );
  }

  Widget Poster(
    BuildContext context, {
    required String? tag,
    required String? poster,
    required bool? isLoading,
  }) {
    return SizedBox(
      height: 300,
      width: MediaQuery.of(context).size.width,
      child: Stack(
        children: [
          Positioned.fill(
            child: CachedNetworkImage(
              fit: BoxFit.cover,
              imageUrl:
                  (data?['cover'] == '' ? poster : data?['cover']) ?? poster!,
              alignment: Alignment.topCenter,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).colorScheme.surface.withOpacity(0.4),
                    Theme.of(context).colorScheme.surface.withOpacity(0.6),
                    Theme.of(context).colorScheme.surface,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 25,
            child: Row(
              children: [
                Hero(
                  tag: tag!,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: CachedNetworkImage(
                      imageUrl: poster!,
                      fit: BoxFit.cover,
                      width: 70,
                      height: 100,
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width - 100,
                      child: Text(
                        data?['name'] ?? 'Loading',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            overflow: TextOverflow.ellipsis),
                        maxLines: 2,
                      ),
                    ),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        iconWithName(
                          icon: Iconsax.star5,
                          name: data?['rating'] ?? '6.9',
                          isVertical: false,
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 2,
                          height: 18,
                          color: Theme.of(context)
                              .colorScheme
                              .inverseSurface
                              .withOpacity(0.4),
                        ),
                        const SizedBox(width: 10),
                        Text(data?['status'] ?? '??',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontFamily: 'Poppins-SemiBold'))
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 30,
            right: 20,
            child: Material(
              borderOnForeground: false,
              color: Colors.transparent,
              child: IconButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainer,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(Icons.close),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Info(BuildContext context) {
    ColorScheme CustomScheme = Theme.of(context).colorScheme;
    return isLoading
        ? Padding(
            padding: const EdgeInsets.only(top: 30.0),
            child: Center(child: CircularProgressIndicator()),
          )
        : ExpandablePageView(
            controller: pageController,
            itemCount: 2,
            itemBuilder: (context, page) {
              return page == 0
                  ? originalInfoPage(CustomScheme, context)
                  : chapterSection();
            },
          );
  }

  Widget originalInfoPage(ColorScheme CustomScheme, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 100.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 60,
                        child: ElevatedButton(
                          onPressed: () {
                            if (Provider.of<AniListProvider>(context,
                                        listen: false)
                                    .userData?['user']?['name'] ==
                                null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainer,
                                  content: Text(
                                    'Login on AniList First!',
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary),
                                  ),
                                ),
                              );
                            } else {
                              showListEditorModal(
                                  context, data['chapters'] ?? '?');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                width: 2,
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainer,
                              ),
                            ),
                          ),
                          child: Text(
                            (checkAvailability(context)).toUpperCase(),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontFamily: 'Poppins-Bold',
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    AnimatedContainer(
                      width: 60,
                      height: 60,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                          border: Border.all(
                              color: isFavourite
                                  ? Theme.of(context)
                                      .colorScheme
                                      .secondaryContainer
                                  : Theme.of(context).colorScheme.primary),
                          color: isFavourite
                              ? Theme.of(context).colorScheme.secondaryContainer
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(50)),
                      duration: Duration(milliseconds: 300),
                      child: IconButton(
                        icon: Icon(
                          isFavourite ? IconlyBold.heart : IconlyLight.heart,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                        ),
                        onPressed: () {
                          if (mangaData != null && data != null) {
                            setState(() {
                              isFavourite = !isFavourite;
                            });
                            // if (isFavourite) {
                            //   Provider.of<AppData>(context, listen: false)
                            //       .addReadManga(
                            //           mangaId: mangaData!.link!,
                            //           mangaTitle: mangaData!.name!,
                            //           currentChapter:
                            //               chapterProgress.toString(),
                            //           mangaPosterImage: widget.posterUrl!,
                            //           anilistMangaId: widget.id.toString(),
                            //           currentSource: mangaSourceHandler
                            //               .selectedSourceName!,
                            //           chapterList: mangaData!.chapters,
                            //           description: data['description']);
                            // } else {
                            //   Provider.of<AppData>(context, listen: false)
                            //       .removeMangaByAnilistId(widget.id.toString());
                            // }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainer,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                content: Text(
                                    'What are you? flash? you${"'"}re gonna have to wait few secs',
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .inverseSurface))));
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Text('Description',
                    style: TextStyle(fontFamily: 'Poppins-SemiBold')),
                const SizedBox(
                  height: 5,
                ),
                Column(
                  children: [
                    Text(
                      description?.replaceAll(RegExp(r'<[^>]*>'), '') ??
                          data?['description']
                              ?.replaceAll(RegExp(r'<[^>]*>'), '') ??
                          'Description Not Found',
                      maxLines: 13,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[400]),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Statistics',
                    style: TextStyle(
                        fontFamily: 'Poppins-SemiBold', fontSize: 16)),
                infoRow(
                    field: 'Rating',
                    value:
                        '${data?['malscore']?.toString() ?? ((data?['rating'])).toString()}/10'),
                infoRow(
                    field: 'Total Chapters',
                    value: data['totalChapters'].toString()),
                infoRow(field: 'Type', value: 'TV'),
                infoRow(
                    field: 'Romaji Name',
                    value: data?['jname'] ?? data?['japanese'] ?? '??'),
                infoRow(field: 'Premiered', value: data?['premiered'] ?? '??'),
                infoRow(field: 'Duration', value: '${data?['duration']}' ''),
              ],
            ),
          ),
          PlatformBuilder(
              androidBuilder: CharacterCards(
                isManga: true,
                carouselData: charactersdata,
              ),
              desktopBuilder: HorizontalCharacterCards(
                isManga: true,
                carouselData: charactersdata,
              )),
          PlatformBuilder(
              androidBuilder: ReusableCarousel(
                title: 'Related',
                carouselData: data?['relations'],
                detailsPage: true,
                secondary: false,
              ),
              desktopBuilder: HorizontalList(
                title: 'Related',
                carouselData: data?['relations'],
                detailsPage: true,
                secondary: false,
              )),
          PlatformBuilder(
              androidBuilder: ReusableCarousel(
                title: 'Recommended',
                carouselData: data?['recommendations'],
                detailsPage: true,
                isManga: true,
              ),
              desktopBuilder: HorizontalList(
                title: 'Recommended',
                carouselData: data?['recommendations'],
                detailsPage: true,
                isManga: true,
              )),
          PlatformBuilder(
              androidBuilder: ReusableCarousel(
                title: 'Popular',
                carouselData: fallbackMangaData?['data']['popularMangas']
                    ['media'],
                detailsPage: false,
                isManga: true,
              ),
              desktopBuilder: HorizontalList(
                title: 'Popular',
                carouselData: fallbackMangaData?['data']?['popularManga']
                    ?['media'],
                detailsPage: false,
                isManga: true,
              )),
        ],
      ),
    );
  }
}

class infoRow extends StatelessWidget {
  final String value;
  final String field;

  const infoRow({super.key, required this.field, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(right: 10),
      margin: EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(field,
              style: TextStyle(
                  fontFamily: 'Poppins-Bold',
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.7))),
          SizedBox(
            width: 170,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontFamily: 'Poppins-Bold')),
            ),
          ),
        ],
      ),
    );
  }
}
