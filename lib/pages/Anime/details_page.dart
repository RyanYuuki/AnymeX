// ignore_for_file: prefer_const_constructors, deprecated_member_use, non_constant_identifier_names, must_be_immutable, avoid_print, use_build_context_synchronously

import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:anymex/api/Mangayomi/Eval/dart/model/m_chapter.dart';
import 'package:anymex/api/Mangayomi/Eval/dart/model/video.dart' as v;
import 'package:anymex/api/Mangayomi/Eval/dart/model/video.dart';
import 'package:anymex/api/Mangayomi/Extensions/extensions_provider.dart';
import 'package:anymex/api/Mangayomi/Model/Source.dart';
import 'package:anymex/api/Mangayomi/Search/getVideo.dart';
import 'package:anymex/api/Mangayomi/Search/get_detail.dart';
import 'package:anymex/api/Mangayomi/Search/search.dart';
import 'package:anymex/auth/auth_provider.dart';
import 'package:anymex/components/android/common/IconWithLabel.dart';
import 'package:anymex/components/android/anilistExclusive/wong_title_dialog.dart';
import 'package:anymex/components/android/anime/details/episode_buttons.dart';
import 'package:anymex/components/android/anime/details/episode_list.dart';
import 'package:anymex/components/android/common/custom_slider.dart';
import 'package:anymex/components/android/common/expandable_page_view.dart';
import 'package:anymex/components/android/common/reusable_carousel.dart';
import 'package:anymex/components/android/anime/details/character_cards.dart';
import 'package:anymex/components/common/navbar.dart';
import 'package:anymex/components/desktop/anime/character_cards.dart';
import 'package:anymex/components/desktop/anime/episode_grid.dart';
import 'package:anymex/components/desktop/horizontal_list.dart';
import 'package:anymex/components/platform_builder.dart';
import 'package:anymex/fallbackData/anilist_homepage_data.dart';
import 'package:anymex/hiveData/appData/database.dart';
import 'package:anymex/models/server.dart';
import 'package:anymex/pages/Anime/widgets/goto_extensions.dart';
import 'package:anymex/utils/apiHooks/anilist/anime/details_page.dart';
import 'package:anymex/pages/Anime/watch_page.dart';
import 'package:anymex/utils/downloader/downloader.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as rp;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:iconly/iconly.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

Color? hexToColor(String hexColor) {
  if (hexColor == '??') {
    return null;
  } else {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }
}

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

class DetailsPage extends rp.ConsumerStatefulWidget {
  final int id;
  final String? posterUrl;
  final String? tag;
  const DetailsPage({
    super.key,
    required this.id,
    this.posterUrl,
    this.tag,
  });

  @override
  rp.ConsumerState<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends rp.ConsumerState<DetailsPage>
    with SingleTickerProviderStateMixin {
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
  // Episodes Section
  List<MChapter>? episodesData;
  dynamic episodeImages;
  int availEpisodes = 0;
  List<v.Video>? episodeSrc;
  int currentEpisode = 1;
  List<v.Track>? subtitleTracks;
  Server? activeServer;
  bool isDub = false;
  int watchProgress = 1;

  // Sources
  dynamic fetchedData;
  bool isFavourite = false;
  String? animeId;

  // Layout Buttons
  List<IconData> layoutIcons = [
    IconlyBold.image,
    Icons.list_rounded,
    Iconsax.grid_25
  ];
  int layoutIndex = 0;

  // Mangayomi Extensions
  dynamic streamExtensions;
  List<Source>? installedExtensions;
  Source? activeSource;

  List<Server> serverList = [];

  @override
  void initState() {
    super.initState();
    fetchData();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);
    watchProgress = returnProgress();
    _animation = Tween<double>(begin: -1.0, end: -3.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));
    _initExtensions();
  }

  Future<void> _initExtensions() async {
    final container = rp.ProviderContainer();
    final sourcesAsyncValue =
        await container.read(getExtensionsStreamProvider(false).future);
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

  Future<void> fetchData() async {
    try {
      final tempdata = await fetchAnimeInfo(widget.id);
      setState(() {
        data = tempdata;
        description = data['description'] ?? data?['description'];
        charactersdata = data['characters'] ?? [];
        altdata = data;
        isFavourite = Provider.of<AppData>(context, listen: false)
            .getAnimeAvail(widget.id.toString());
        isLoading = false;
      });
      await mapToAnilist();
    } catch (e) {
      log('Failed to fetch Anime Info: $e');
    }
  }

  String? errorMessage;

  Future<void> mapToAnilist({bool isFirstTime = true, Source? source}) async {
    try {
      final finalSource = source ?? activeSource;

      var searchData = await search(
        source: finalSource!,
        query: data['jname'],
        page: 1,
        filterList: [],
      );
      print('Length is ${searchData!.list.length}');
      if (searchData.list.isEmpty) {
        searchData = await search(
          source: finalSource,
          query: data['jname'].split(' ').first,
          page: 1,
          filterList: [],
        );
      }

      if (searchData?.list.isEmpty ?? true) {
        throw Exception("No anime found for the provided query.");
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

      final episodeData = episodeFuture.chapters!.reversed.toList();
      final firstEpisodeNum =
          int.parse(episodeData[0].name!.split("Episode ").last);
      final renewepisodeData = firstEpisodeNum > 3
          ? episodeData.map((ep) {
              final index = episodeData.indexOf(ep) + 1;
              ep.name = "Episode $index";
              return ep;
            }).toList()
          : episodeData;

      setState(() {
        fetchedData = episodeFuture;
        episodesData = renewepisodeData;
        availEpisodes = renewepisodeData.length;
        episodeImages = renewepisodeData;
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

  Future<void> fetchEpisodeSrcs() async {
    final url = getEpisodeFromProgress().url;
    episodeSrc = null;
    if (episodesData == null) return;
    try {
      List<v.Video> response = await getVideo(source: activeSource!, url: url!);
      setState(() {
        subtitleTracks = response.first.subtitles;
        episodeSrc = response;
        isLoading = false;
        serverList = response.map((el) {
          final index = response.indexOf(el);
          return Server(index, activeSource!.name!, el.quality);
        }).toList();
      });
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      log('Error fetching episode sources: $e');
    }
    final isOOB = currentEpisode == episodesData?.length;
    Provider.of<AppData>(context, listen: false).addWatchedAnime(
      animeId: data['id'].toString(),
      animeTitle: data['name'],
      currentEpisode: (isOOB ? currentEpisode : currentEpisode + 1).toString(),
      animePosterImageUrl: data['poster'],
      anilistAnimeId: widget.id.toString(),
      currentSource: activeSource!.name!,
      episodeList: episodesData,
      animeDescription: data['description'],
    );
  }

  void navigateToStreaming() {
    if (episodeSrc != null) {
      Navigator.pop(context);
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => WatchPage(
                    episodeSrc: episodeSrc![activeServer!.index],
                    episodeData: episodesData,
                    currentEpisode: currentEpisode,
                    activeServer: activeServer!,
                    animeId: widget.id,
                    tracks: subtitleTracks ?? [],
                    animeTitle: data['name'] ?? data?['jname'] ?? '',
                    description: data['description'],
                    posterImage: data['poster'],
                    activeSource: activeSource!,
                    streams: episodeSrc,
                  )));
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
                      selectedIcon: IconlyBold.play,
                      unselectedIcon: IconlyLight.play,
                      label: "Watch",
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
            selectedIcon: IconlyBold.play,
            unselectedIcon: IconlyLight.play,
            label: "Watch",
            onTap: (index) => setState(() {
                  selectedIndex = index;
                  pageController.animateToPage(index,
                      duration: Duration(milliseconds: 300),
                      curve: Curves.linear);
                })),
      ],
    );
  }

  String checkAvailability(BuildContext context) {
    final animeList = Provider.of<AniListProvider>(context, listen: false)
        .userData?['animeList'];

    final matchingAnime = animeList?.firstWhere(
      (anime) => anime?['media']?['id']?.toString() == widget.id.toString(),
      orElse: () => null,
    );

    if (matchingAnime != null) {
      String status = matchingAnime['status'];

      switch (status) {
        case 'CURRENT':
          return 'Watching';
        case 'COMPLETED':
          return 'Completed';
        case 'PAUSED':
          return 'Paused';
        case 'DROPPED':
          return 'Dropped';
        case 'PLANNING':
          return 'Planning to Watch';
        case 'REPEATING':
          return 'Rewatching';
        default:
          return 'Add To List';
      }
    }

    return 'Add To List';
  }

  Widget saikouDetailsPage(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(bottom: 100),
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
              onPageChanged: (value) {
                if (mounted) {
                  setState(() {
                    selectedIndex = value;
                  });
                }
              },
              itemBuilder: (BuildContext context, int index) {
                return index == 0
                    ? saikouDetails(context)
                    : episodeSection(context);
              },
            ),
        ],
      ),
    );
  }

  bool isList = true;
  List<MChapter> filteredEpisodes = [];
  List<List<int>> episodeRanges = [];

  bool hasError = false;

  void initializeEpisodes() {
    try {
      if (episodesData != null && episodeRanges.isEmpty) {
        setState(() {
          final startEpisodeNumber = int.parse(
            episodesData!.first.name!.split("Episode ").last,
          );

          if (episodesData!.length > 50 && episodesData!.length < 100) {
            episodeRanges =
                getEpisodeRanges(episodesData!, 24, startEpisodeNumber);
          } else if (episodesData!.length > 200 && episodesData!.length < 300) {
            episodeRanges =
                getEpisodeRanges(episodesData!, 40, startEpisodeNumber);
          } else if (episodesData!.length > 300) {
            episodeRanges =
                getEpisodeRanges(episodesData!, 50, startEpisodeNumber);
          } else {
            episodeRanges =
                getEpisodeRanges(episodesData!, 12, startEpisodeNumber);
          }

          filteredEpisodes = episodesData!.where((episode) {
            final episodeNumber =
                int.parse(episode.name!.split("Episode ").last);
            return episodeNumber >= episodeRanges[0][0] &&
                episodeNumber <= episodeRanges[0][1];
          }).toList();
        });
      }
    } catch (e) {
      log(e.toString());
      setState(() {
        hasError = true;
        filteredEpisodes = episodesData ?? [];
      });
    }
  }

  MChapter getEpisodeFromProgress() {
    return episodesData!.firstWhere(
        (ep) => int.parse(ep.name!.split("Episode ").last) == currentEpisode);
  }

  Widget buildEpisodeWidget(BuildContext context) {
    if (episodesData == null && activeSource != null) {
      return Center(child: CircularProgressIndicator());
    }

    if (activeSource == null) {
      return NoSourceSelectedWidget();
    }

    return PlatformBuilder(
      androidBuilder: EpisodeGrid(
        currentEpisode: currentEpisode,
        episodeImages: episodeImages,
        episodes: filteredEpisodes,
        progress: watchProgress,
        layoutIndex: layoutIndex,
        onEpisodeSelected: (int episode) async {
          try {
            setState(() {
              currentEpisode = episode;
            });
            showLoading();
            await fetchEpisodeSrcs();
            selectServerDialog(context);
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Error loading episode: ${e.toString()}"),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        coverImage: data?['poster'] ?? widget.posterUrl!,
        onEpisodeDownload: (String episodeId, String episodeNumber) async {
          try {
            showLoading();
            final downloadMeta = await downloadHelper(episodeId);
            Navigator.pop(context);
            showDownloadOptions(context,
                source: activeSource!.name!,
                Videos: downloadMeta!,
                episodeNumber: "Episode $episodeNumber");
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Error downloading episode: ${e.toString()}"),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
      ),
      desktopBuilder: DesktopEpisodeGrid(
        currentEpisode: currentEpisode,
        episodeImages: episodeImages,
        episodes: filteredEpisodes,
        progress: watchProgress,
        layoutIndex: layoutIndex,
        onEpisodeSelected: (int episode) async {
          setState(() {
            currentEpisode = episode;
          });
          showLoading();
          await fetchEpisodeSrcs();
          selectServerDialog(context);
        },
        coverImage: data?['poster'] ?? widget.posterUrl!,
        onEpisodeDownload: (String episodeId, String episodeNumber) async {
          showLoading();
          final downloadMeta = await downloadHelper(episodeId);
          Navigator.pop(context);
          showDownloadOptions(context,
              source: activeSource!.name!,
              Videos: downloadMeta!,
              episodeNumber: "Episode-$episodeNumber");
        },
      ),
    );
  }

  Widget episodeSection(BuildContext context) {
    initializeEpisodes();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            height: 30,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  'Found: ${fetchedData?.name ?? '??'}',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontFamily: "Poppins-SemiBold"),
                ),
              ),
              TextButton(
                onPressed: () {
                  showAnimeSearchModal(context, data['name'], (animeId) async {
                    setState(() {
                      episodesData = null;
                    });
                    final data =
                        await getDetail(source: activeSource!, url: animeId);
                    final episodes = data.chapters!.reversed.toList();
                    final firstEpisodeNum =
                        int.parse(episodes[0].name!.split("Episode ").last);
                    final renewEpisodes = firstEpisodeNum > 3
                        ? episodes.map((ep) {
                            final index = episodes.indexOf(ep) + 1;
                            ep.name = "Episode $index";
                            return ep;
                          }).toList()
                        : episodes;

                    setState(() {
                      filteredEpisodes = [];
                      fetchedData = data;
                      episodesData = renewEpisodes;
                      availEpisodes = renewEpisodes.length;
                      episodeRanges = [];
                      episodeImages = renewEpisodes;
                    });
                    initializeEpisodes();
                  }, activeSource!);
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
              )
            ],
          ),
          const SizedBox(
            height: 20,
          ),
          DropdownButtonFormField<String>(
            value: installedExtensions?.isEmpty ?? true
                ? "No Sources Installed"
                : '${activeSource!.name} (${activeSource!.lang?.toUpperCase()})',
            decoration: InputDecoration(
              labelText: 'Select Source',
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              labelStyle: TextStyle(
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
                  episodesData = null;
                  activeSource = selectedSource;
                });

                await mapToAnilist(source: selectedSource);
                initializeEpisodes();
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
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Episodes',
                  style:
                      TextStyle(fontSize: 18, fontFamily: 'Poppins-SemiBold')),
              Row(
                children: [
                  IconButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.surfaceContainer),
                    onPressed: () {
                      setState(() {
                        layoutIndex++;
                        if (layoutIndex > layoutIcons.length - 1) {
                          layoutIndex = 0;
                        }
                      });
                    },
                    icon: Icon(layoutIcons[layoutIndex]),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 10),
          if (activeSource != null && episodesData != null)
            InkWell(
              onTap: () async {
                setState(() {
                  currentEpisode = returnProgress();
                });
                showLoading();
                await fetchEpisodeSrcs();
                selectServerDialog(
                  context,
                );
              },
              child: Container(
                height: 75,
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border:
                      Border.all(color: Theme.of(context).colorScheme.primary),
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                    image: NetworkImage(altdata?['cover'] ??
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
                        returnProgressString(),
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
          if (episodesData != null)
            SizedBox(
              height: 40,
              child: Stack(
                children: [
                  EpisodeButtons(
                    episodeRanges: episodeRanges,
                    onRangeSelected: (range) {
                      setState(() {
                        filteredEpisodes = episodesData!
                            .where((episode) =>
                                (int.parse(episode.name!
                                        .split("Episode ")
                                        .last)) >=
                                    range[0] &&
                                (int.parse(episode.name!
                                        .split("Episode ")
                                        .last)) <=
                                    range[1])
                            .toList();
                      });
                    },
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.black.withOpacity(0.3),
                              Colors.transparent,
                              Colors.transparent,
                              Colors.transparent,
                              Colors.transparent,
                              Colors.transparent,
                              Colors.transparent,
                              Colors.transparent,
                              Colors.transparent,
                              Colors.black.withOpacity(0.3),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          const SizedBox(height: 10),
          buildEpisodeWidget(context)
        ],
      ),
    );
  }

  Future<List<Video>?> downloadHelper(String episodeId) async {
    List<Video>? response;

    try {
      response = await getVideo(source: activeSource!, url: episodeId);

      if (response != null) {
        List<Video> qualitiesList = [];

        for (Video video in response) {
          String videoUrl = video.url;

          log('Skipping non-M3U8 URL: $videoUrl');
          qualitiesList.add(video);
        }

        if (qualitiesList.isNotEmpty) {
          return qualitiesList;
        } else {
          log('No qualities found in processed list.');
        }
      } else {
        log('Error: No sources found in the initial response.');
      }
    } catch (e) {
      log('Error fetching episode sources: $e');
    }

    return null;
  }

  Future<List<Map<String, dynamic>>> fetchM3u8Links(
      String m3u8Url, String baseUrl) async {
    final List<Map<String, dynamic>> qualitiesList = [];

    try {
      final response = await http.get(Uri.parse(m3u8Url));

      if (response.statusCode == 200) {
        final lines = LineSplitter.split(response.body).toList();
        String? currentUrl;

        for (String line in lines) {
          if (line.startsWith('#EXT-X-I-FRAME-STREAM-INF')) {
            continue;
          }

          if (line.startsWith('#EXT-X-STREAM-INF')) {
            final Map<String, String> attributes = {};

            final regex = RegExp(r'(\w+)=["]?([^",]+)["]?');
            final matches = regex.allMatches(line);

            for (var match in matches) {
              final key = match.group(1);
              final value = match.group(2);
              if (key != null && value != null) {
                attributes[key] = value;
              }
            }

            String quality = attributes['RESOLUTION'] ?? 'Unknown Quality';

            if (quality == '1920x1080') {
              quality = '1080p';
            } else if (quality == '1280x720') {
              quality = '720p';
            } else if (quality == '640x360') {
              quality = '360p';
            } else {
              quality = attributes['NAME'] ?? 'Unknown Quality';
            }

            print('Found quality: $quality');
            final index = lines.indexOf(line) + 1;
            if (index < lines.length) {
              currentUrl = lines[index].trim();

              if (!currentUrl.startsWith('http')) {
                currentUrl = '$baseUrl$currentUrl';
              }

              qualitiesList.add({
                'quality': quality,
                'url': currentUrl,
              });
            }
          }
        }
      }
    } catch (e) {
      print('Error fetching M3U8 links: $e');
    }

    return qualitiesList;
  }

  Future<void> showDownloadOptions(
    BuildContext context, {
    required String source,
    required List<Video> Videos,
    required String episodeNumber,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Select Server',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isLoading)
                    const Center(
                      child: CircularProgressIndicator(),
                    )
                  else
                    SizedBox(
                      height: 300,
                      child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: Videos.length,
                          itemBuilder: (context, index) {
                            final quality = Videos[index].quality;
                            final url = Videos[index].url;
                            return _buildTile(quality, 'M3U8', () {
                              Downloader downloader = Downloader();
                              downloader.download(
                                  url, episodeNumber, data['name']);
                              Navigator.pop(context);
                            });
                          }),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTile(String title, String type, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          title: Text(
            title,
            style: TextStyle(
                fontFamily: 'Poppins-SemiBold',
                color: Theme.of(context).colorScheme.primary),
          ),
          subtitle: Text(
            'M3U8',
            style: TextStyle(color: Colors.grey[400]),
          ),
          trailing: const Icon(Icons.download),
        ),
      ),
    );
  }

  Widget _buildServerTile(Server server, String type, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          title: Text(
            server.quality!,
            style: TextStyle(
                fontFamily: 'Poppins-SemiBold',
                color: Theme.of(context).colorScheme.primary),
          ),
          subtitle: Text(
            server.serverName!,
            style: TextStyle(color: Colors.grey[400]),
          ),
          trailing: const Icon(Iconsax.play5),
        ),
      ),
    );
  }

  int returnProgress() {
    if (mounted) {
      final animeList = Provider.of<AniListProvider>(context, listen: false)
          .userData?['currentlyWatching'];
      if (animeList == null) {
        final provider = Provider.of<AppData>(context, listen: false);
        final currentEpisode =
            provider.getCurrentEpisodeForAnime(widget.id.toString()) ?? '0';
        return int.parse(currentEpisode);
      }

      final matchingAnime = animeList.firstWhere(
        (anime) => anime?['media']?['id'] == widget.id,
        orElse: () => null,
      );

      return matchingAnime?['progress'] ?? 0;
    } else {
      return 0;
    }
  }

  String returnProgressString() {
    final animeList = Provider.of<AniListProvider>(context, listen: false)
        .userData?['currentlyWatching'];

    if (animeList == null) {
      final provider = Provider.of<AppData>(context, listen: false);
      final currentEpisode =
          provider.getCurrentEpisodeForAnime(widget.id.toString()) ?? '1';
      return "Watch: Episode $currentEpisode";
    }

    final matchingAnime = animeList.firstWhere(
      (anime) => anime?['media']?['id'] == widget.id,
      orElse: () => null,
    );

    if (matchingAnime == null) return "Watch: Episode 1";

    return 'Continue: Episode ${matchingAnime?['progress']}';
  }

  List<List<int>> getEpisodeRanges(
      List<dynamic> episodes, int step, int startEpisodeNumber) {
    List<List<int>> episodeRanges = [];
    int currentStart = 1;

    for (int i = 0; i < episodes.length; i += step) {
      int currentEnd = currentStart + step - 1;
      currentEnd = (i + step > episodes.length)
          ? (startEpisodeNumber + episodes.length - 1)
          : currentEnd;

      episodeRanges.add([currentStart, currentEnd]);
      currentStart += step;
    }

    return episodeRanges;
  }

  void selectServerDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: ListView(
                children: [
                  Column(children: const [
                    Text(
                      'Select Server',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ]),
                  SizedBox(height: 16),
                  for (var server in serverList) ...[
                    _buildServerTile(server, 'FAST', () async {
                      setState(() {
                        activeServer = server;
                      });
                      navigateToStreaming();
                    })
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  void showLoading() {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        return Container(
          height: 200,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(16),
            ),
          ),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }

  Column saikouDetails(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 25.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (Provider.of<AniListProvider>(context).userData?['user']
                      ?['name'] !=
                  null)
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
                        showListEditorModal(
                            context, data['totalEpisodes'] ?? '?');
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text.rich(
                    TextSpan(
                      text: 'Watched ',
                      style: TextStyle(fontSize: 15),
                      children: [
                        TextSpan(
                          text: "${returnProgress()} ",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontFamily: 'Poppins-Bold',
                          ),
                        ),
                        TextSpan(text: 'Out of ${data?['totalEpisodes']}')
                      ],
                    ),
                  ),
                  Expanded(child: SizedBox.shrink()),
                  IconButton(
                      onPressed: () {
                        if (data != null && episodesData != null) {
                          setState(() {
                            isFavourite = !isFavourite;
                          });
                          if (isFavourite) {
                            Provider.of<AppData>(context, listen: false)
                                .addWatchedAnime(
                                    currentSource: activeSource!.name!,
                                    anilistAnimeId: widget.id.toString(),
                                    animeId:
                                        fetchedData?['id']?.toString() ?? '',
                                    animeTitle: data['name'],
                                    currentEpisode: currentEpisode.toString(),
                                    animePosterImageUrl: widget.posterUrl!,
                                    episodeList: episodesData,
                                    animeDescription: data['description']);
                          } else {
                            Provider.of<AppData>(context, listen: false)
                                .removeAnimeByAnilistId(widget.id.toString());
                          }
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
                                        .inverseSurface),
                              )));
                        }
                      },
                      icon: Icon(
                          isFavourite ? IconlyBold.heart : IconlyLight.heart)),
                  IconButton(onPressed: () {}, icon: Icon(Icons.share)),
                ],
              ),
              const SizedBox(height: 20),
              infoRow(
                  field: 'Rating',
                  value:
                      '${data?['malscore']?.toString() ?? ((data?['rating'])).toString()}/10'),
              infoRow(
                  field: 'Total Episodes',
                  value: data?['stats']?['episodes']?['sub'].toString() ??
                      data?['totalEpisodes'] ??
                      '??'),
              infoRow(field: 'Type', value: 'TV'),
              infoRow(
                  field: 'Romaji Name',
                  value: data?['jname'] ?? data?['japanese'] ?? '??'),
              infoRow(field: 'Premiered', value: data?['premiered'] ?? '??'),
              infoRow(field: 'Duration', value: '${data?['duration']}'),
              const SizedBox(height: 20),
              Text('Synopsis', style: TextStyle(fontFamily: 'Poppins-Bold')),
              const SizedBox(height: 10),
              Text(description!.toString().length > 250
                  ? '${description!.toString().substring(0, 250)}...'
                  : description!),

              // Grid Section
              PlatformBuilder(
                  androidBuilder: saikouGenreButtons(false),
                  desktopBuilder: saikouGenreButtons(true)),
            ],
          ),
        ),
        const SizedBox(height: 15),
        // Text('Characters',
        //     style: TextStyle(fontFamily: 'Poppins-Bold')),
        PlatformBuilder(
            androidBuilder:
                CharacterCards(carouselData: charactersdata, isManga: false),
            desktopBuilder: HorizontalCharacterCards(
                carouselData: charactersdata, isManga: false)),

        PlatformBuilder(
            androidBuilder: ReusableCarousel(
              title: 'Popular',
              carouselData: fallbackAnilistData?['data']['popularAnimes']
                  ['media'],
              tag: 'details-page1',
            ),
            desktopBuilder: HorizontalList(
              title: 'Popular',
              carouselData: fallbackAnilistData?['data']['popularAnimes']
                  ['media'],
              tag: 'details-page1',
            )),
        PlatformBuilder(
            androidBuilder: ReusableCarousel(
              title: 'Related',
              carouselData: data?['relations'],
              tag: 'details-page2',
              detailsPage: true,
            ),
            desktopBuilder: HorizontalList(
              title: 'Related',
              carouselData: data?['relations'],
              tag: 'details-page2',
              detailsPage: true,
            )),
        PlatformBuilder(
            androidBuilder: ReusableCarousel(
              detailsPage: true,
              title: 'Recommended',
              carouselData: data?['recommendations'],
              tag: 'details-page3',
            ),
            desktopBuilder: HorizontalList(
              detailsPage: true,
              title: 'Recommended',
              carouselData: data?['recommendations'],
              tag: 'details-page3',
            )),
        const SizedBox(height: 100),
      ],
    );
  }

  Column saikouGenreButtons(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text('Genres', style: TextStyle(fontFamily: 'Poppins-Bold')),
        const SizedBox(height: 10),
        Flexible(
          flex: 0,
          child: GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: data?['genres'].length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isDesktop ? 5 : 2,
              mainAxisExtent: isDesktop ? 80 : 55,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, itemIndex) {
              String genre = data?['genres'][itemIndex];
              String buttonBackground =
                  genrePreviews[genre] ?? genrePreviews['default'];

              return Container(
                clipBehavior: Clip.antiAlias,
                decoration:
                    BoxDecoration(borderRadius: BorderRadius.circular(15)),
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
                            color:
                                Theme.of(context).colorScheme.surfaceContainer),
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
                  alignment: Alignment.center,
                  fit: BoxFit.cover,
                  imageUrl: altdata?['cover'] ?? widget.posterUrl,
                ),
              );
            },
          )
        else
          CachedNetworkImage(
            height: 450,
            alignment: Alignment.center,
            fit: BoxFit.cover,
            imageUrl: altdata?['cover'] ?? widget.posterUrl,
          ),
        Positioned(
          child: Container(
            height: 450,
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

  double getScore() {
    if (mounted) {
      final animeList = Provider.of<AniListProvider>(context, listen: false)
          .userData["animeList"];
      if (animeList == null) {
        return 1.0;
      }

      final matchingAnime = animeList.firstWhere(
        (anime) => anime?['media']?['id'] == widget.id,
        orElse: () => null,
      );
      log("Matches Anime: $matchingAnime");
      return double.tryParse((matchingAnime?['score'])?.toString() ?? '1') ??
          1.0;
    } else {
      return 1.0;
    }
  }

  String getStatus() {
    if (mounted) {
      final animeList = Provider.of<AniListProvider>(context, listen: false)
          .userData["animeList"];
      if (animeList == null) {
        return "CURRENT";
      }

      final matchingAnime = animeList.firstWhere(
        (anime) => anime?['media']?['id'] == widget.id,
        orElse: () => null,
      );
      return matchingAnime?['status'] ?? "CURRENT";
    } else {
      return "CURRENT";
    }
  }

  String selectedStatus = 'CURRENT';
  double score = 1.0;

  void showListEditorModal(BuildContext context, String totalEpisodes) {
    selectedStatus = getStatus();
    score = getScore();
    showModalBottomSheet(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
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
                  bottom: MediaQuery.of(context).viewInsets.bottom + 80.0,
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
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondaryContainer,
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
                              'REPEATING',
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
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
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
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondaryContainer,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    width: 1,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                labelText: 'Progress',
                                labelStyle: const TextStyle(
                                  fontFamily: 'Poppins-Bold',
                                ),
                              ),
                              initialValue: watchProgress.toString(),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (String value) {
                                int? newProgress = int.tryParse(value);
                                if (newProgress != null && newProgress >= 0) {
                                  setState(() {
                                    if (totalEpisodes == '?') {
                                      watchProgress = newProgress;
                                    } else {
                                      int totalEp = int.parse(totalEpisodes);
                                      watchProgress = newProgress <= totalEp
                                          ? newProgress
                                          : totalEp;
                                    }
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                          CustomSlider(
                            value: score,
                            min: 0.0,
                            max: 10.0,
                            divisions: 100,
                            label: score.toStringAsFixed(1),
                            activeColor: Theme.of(context).colorScheme.primary,
                            inactiveColor: Theme.of(context)
                                .colorScheme
                                .secondaryContainer,
                            onChanged: (double newValue) {
                              setState(() {
                                score = newValue;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SizedBox(
                          height: 50,
                          width: 120,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Provider.of<AniListProvider>(context,
                                      listen: false)
                                  .deleteAnimeFromList(animeId: widget.id);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              side: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondaryContainer),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18)),
                            ),
                            child: const Text('Delete'),
                          ),
                        ),
                        SizedBox(
                          height: 50,
                          width: 120,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Provider.of<AniListProvider>(context,
                                      listen: false)
                                  .updateAnimeList(
                                      animeId: data['id'],
                                      episodeProgress: watchProgress,
                                      rating: score,
                                      status: selectedStatus);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              side: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondaryContainer),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18)),
                            ),
                            child: const Text('Save'),
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
      },
    );
  }

  Widget originalDetailsPage(ColorScheme CustomScheme, BuildContext context) {
    return isLoading
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
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(bottom: 100),
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
        ],
      ),
    );
  }

  Info(BuildContext context) {
    ColorScheme CustomScheme = Theme.of(context).colorScheme;
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.only(top: 30.0),
        child: Center(child: CircularProgressIndicator()),
      );
    } else {
      return ExpandablePageView(
        controller: pageController,
        itemCount: 2,
        onPageChanged: (value) {
          if (mounted) {
            setState(() {
              selectedIndex = value;
            });
          }
        },
        itemBuilder: (BuildContext context, int index) {
          return index == 0
              ? originalInfoPage(CustomScheme, context)
              : episodeSection(context);
        },
      );
    }
  }

  Column originalInfoPage(ColorScheme CustomScheme, BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        width: MediaQuery.of(context).size.width - 40,
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
                                  context, data['totalEpisodes'] ?? '?');
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
                                  : Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest),
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
                          if (data != null && episodesData != null) {
                            setState(() {
                              isFavourite = !isFavourite;
                            });
                            if (isFavourite) {
                              Provider.of<AppData>(context, listen: false)
                                  .addWatchedAnime(
                                      currentSource: activeSource!.name!,
                                      anilistAnimeId: widget.id.toString(),
                                      animeId:
                                          fetchedData?['id']?.toString() ?? '',
                                      animeTitle: data['name'],
                                      currentEpisode: currentEpisode.toString(),
                                      animePosterImageUrl: widget.posterUrl!,
                                      episodeList: episodesData,
                                      animeDescription: data['description']);
                            } else {
                              Provider.of<AppData>(context, listen: false)
                                  .removeAnimeByAnilistId(widget.id.toString());
                            }
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
                  style:
                      TextStyle(fontFamily: 'Poppins-SemiBold', fontSize: 16)),
              infoRow(
                  field: 'Rating',
                  value:
                      '${data?['malscore']?.toString() ?? ((data?['rating'])).toString()}/10'),
              infoRow(
                  field: 'Total Episodes',
                  value: data?['stats']?['episodes']?['sub'].toString() ??
                      data?['totalEpisodes'] ??
                      '??'),
              infoRow(field: 'Type', value: 'TV'),
              infoRow(
                  field: 'Romaji Name',
                  value: data?['jname'] ?? data?['japanese'] ?? '??'),
              infoRow(field: 'Premiered', value: data?['premiered'] ?? '??'),
              infoRow(field: 'Duration', value: '${data?['duration']}'),
            ],
          ),
        ),
        PlatformBuilder(
            androidBuilder:
                CharacterCards(carouselData: charactersdata, isManga: false),
            desktopBuilder: HorizontalCharacterCards(
                carouselData: charactersdata, isManga: false)),
        PlatformBuilder(
            androidBuilder: ReusableCarousel(
              title: 'Related',
              carouselData: data?['relations'],
              tag: 'details-page2',
              detailsPage: true,
            ),
            desktopBuilder: HorizontalList(
              title: 'Related',
              carouselData: data?['relations'],
              tag: 'details-page2',
              detailsPage: true,
            )),
        PlatformBuilder(
            androidBuilder: ReusableCarousel(
              title: 'Popular',
              carouselData: fallbackAnilistData?['data']['popularAnimes']
                  ['media'],
              tag: 'details-page1',
            ),
            desktopBuilder: HorizontalList(
              title: 'Popular',
              carouselData: fallbackAnilistData?['data']['popularAnimes']
                  ['media'],
              tag: 'details-page1',
            )),
        PlatformBuilder(
            androidBuilder: ReusableCarousel(
              detailsPage: true,
              title: 'Recommended',
              carouselData: data?['recommendations'],
              tag: 'details-page3',
            ),
            desktopBuilder: HorizontalList(
              detailsPage: true,
              title: 'Recommended',
              carouselData: data?['recommendations'],
              tag: 'details-page3',
            )),
        const SizedBox(height: 100),
      ],
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
