// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:developer';

import 'package:aurora/components/episode_list.dart';
import 'package:aurora/components/episodelist_dropdown.dart';
import 'package:aurora/database/api.dart';
import 'package:aurora/database/database.dart';
import 'package:aurora/database/scraper/scraper_details.dart';
import 'package:aurora/database/scraper/scraper_episodes.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:aurora/components/better_player.dart';
import 'package:aurora/components/reusable_carousel.dart';
import '../../components/tab_bar.dart';

class StreamingPage extends StatefulWidget {
  final String? id;
  const StreamingPage({super.key, this.id});

  @override
  State<StreamingPage> createState() => _StreamingPageState();
}

class _StreamingPageState extends State<StreamingPage> {
  bool usingConsumet =
      Hive.box('app-data').get('using-consumet', defaultValue: false);
  dynamic episodesData;
  dynamic episodeSrc;
  dynamic subtitleTracks;
  dynamic animeData;
  bool isLoading = false;
  bool isInfoLoading = false;
  bool hasError = false;
  int? currentEpisode;
  bool isDub = false;
  int? availEpisodes;
  bool isList = true;
  List<dynamic>? filteredEpisodes = [];
  String? selectedRange;
  int selectedIndex = 0;
  String? activeServer = 'VidStream';

  TextEditingController episodeFilterController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchAnimeData();
    episodeFilterController.addListener(filterEpisodes);
  }

  @override
  void dispose() {
    episodeFilterController.dispose();
    super.dispose();
  }

  Future<void> fetchAnimeData() async {
    setState(() {
      usingConsumet =
          Hive.box('app-data').get('using-consumet', defaultValue: false);
      isLoading = true;
      isInfoLoading = true;
      availEpisodes = 0;
      hasError = false;
    });

    final provider = Provider.of<AppData>(context, listen: false);

    try {
      if (usingConsumet) {
        await fetchFromConsumet(provider);
      } else {
        await fetchFromAniwatch(provider);
      }
    } catch (e) {
      log('Primary fetch attempt failed: $e');
      try {
        await fetchFromAniwatch(provider);
      } catch (aniwatchError) {
        log('Aniwatch fallback failed: $aniwatchError');
        try {
          await fetchFromConsumet(provider);
        } catch (consumetError) {
          setState(() {
            isLoading = false;
            hasError = true;
          });
          log('Both sources failed: $consumetError');
        }
      }
    }
  }

  Future<void> fetchFromAniwatch(AppData provider) async {
    // final tempAnimeData = await fetchAnimeDetailsAniwatch(widget.id!);
    final tempAnimeData = await scrapeAnimeAboutInfo(widget.id!);
    final tempData = await scrapeAnimeEpisodes(widget.id!);

    try {
      final _animeData = conditionDetailPageData((tempAnimeData), false);
      setState(() {
        animeData = _animeData;
        availEpisodes = int.parse(
            _animeData['totalEpisodes'] ?? _animeData['stats']['sub']);
        isInfoLoading = false;
        isLoading = false;
        episodesData = tempData['episodes'];
        filteredEpisodes = tempData['episodes'];
        currentEpisode = int.tryParse(
            provider.getCurrentEpisodeForAnime(_animeData['id'] ?? 1)!);
        provider.addWatchedAnime(
            animeId: _animeData['id'],
            animeTitle: _animeData['name'],
            currentEpisode: currentEpisode!.toString(),
            animePosterImageUrl: _animeData['poster'],
            isConsumet: usingConsumet);
      });
      await fetchEpisodeSrcs();
    } catch (e) {
      throw Exception('Aniwatch data is null $e');
    }
  }

  Future<void> fetchFromConsumet(AppData provider) async {
    final consumetAnimeData = await fetchAnimeDetailsConsumet(widget.id!);
    final consumetEpisodesDatas = await fetchStreamingDataConsumet(widget.id!);

    if (consumetAnimeData != null && consumetEpisodesDatas != null) {
      final _animeData =
          conditionDetailPageData(consumetAnimeData, usingConsumet);
      final consumetEpisodesData = consumetEpisodesDatas;
      setState(() {
        animeData = _animeData;
        availEpisodes = consumetEpisodesData.length;
        episodesData = consumetEpisodesData;
        filteredEpisodes = consumetEpisodesData;
        currentEpisode = int.tryParse(
            provider.getCurrentEpisodeForAnime(_animeData['id'] ?? 1)!);
        provider.addWatchedAnime(
            animeId: _animeData['id'],
            animeTitle: _animeData['name'],
            currentEpisode: currentEpisode!.toString(),
            animePosterImageUrl: _animeData['poster'],
            isConsumet: usingConsumet);
      });
      await fetchEpisodeSrcsConsumet();
    } else {
      throw Exception('Consumet data is null');
    }
  }

  Future<void> fetchEpisodeSrcs() async {
    episodeSrc = null;
    final provider = Provider.of<AppData>(context, listen: false);
    if (episodesData == null || currentEpisode == null) return;

    try {
      final response = await fetchStreamingLinksAniwatch(
          episodesData[(currentEpisode! - 1)]['episodeId'],
          activeServer!,
          isDub ? 'dub' : 'sub');
      if (response != null) {
        final episodeSrcs = response;
        setState(() {
          usingConsumet = false;
          subtitleTracks = episodeSrcs['tracks'];
          episodeSrc = episodeSrcs['sources'][0]['url'];
          isLoading = false;
          isInfoLoading = false;
        });
        provider.addWatchedAnime(
            animeId: animeData['id'],
            animeTitle: animeData['name'],
            currentEpisode: currentEpisode!.toString(),
            animePosterImageUrl: animeData['poster'],
            isConsumet: usingConsumet);
      } else {
        SnackBar(
          content: const Text(
              "Whoopsy! just ran into a server error, either switch the server or please wait until the server is up again, thanks love!"),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        );
      }
    } catch (e) {
      setState(() {
        hasError = true;
        isInfoLoading = false;
        isLoading = false;
      });
      log('Error fetching episode sources: $e');
      SnackBar(
        content: const Text(
            "Whoopsy! just ran into a server error, either switch the server or please wait until the server is up again, thanks love!"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      );
    }
  }

  Future<void> fetchEpisodeSrcsConsumet() async {
    final provider = Provider.of<AppData>(context, listen: false);
    if (episodesData == null || currentEpisode == null) return;

    try {
      final response = await fetchStreamingLinksConsumet(
          '${episodesData[(currentEpisode! - 1)]['id']}');
      if (response != null) {
        final episodeSrcs = response;
        setState(() {
          usingConsumet = true;
          subtitleTracks = null;
          episodeSrc = episodeSrcs['sources'][4]['url'];
          isLoading = false;
          isInfoLoading = false;
        });
        provider.addWatchedAnime(
            animeId: animeData['id'],
            animeTitle: animeData['name'],
            currentEpisode: currentEpisode!.toString(),
            animePosterImageUrl: animeData['poster'],
            isConsumet: usingConsumet);
      } else {
        throw Exception('Failed to load episode sources');
      }
    } catch (e) {
      setState(() {
        hasError = true;
        isInfoLoading = false;
        isLoading = false;
      });
      log('Error fetching episode sources: $e');
    }
  }

  void handleEpisode(int? episode) {
    setState(() {
      currentEpisode = episode;
    });
    if (usingConsumet) {
      fetchEpisodeSrcsConsumet();
    } else {
      fetchEpisodeSrcs();
    }
  }

  void handleLanguage(int? index) {
    log('yoo');
    setState(() {
      if (index == 1) {
        isDub = false;
        availEpisodes = animeData['stats']['episodes']['sub'];
      } else {
        availEpisodes = animeData['stats']['episodes']['dub'] ?? 0;
        isDub = true;
      }
      filteredEpisodes = episodesData.sublist(0, availEpisodes);
      filterEpisodes();
      fetchEpisodeSrcs();
    });
  }

  void filterEpisodes() {
    setState(() {
      final filter = episodeFilterController.text;
      dynamic newData = episodesData.sublist(0, availEpisodes);

      if (selectedRange != null) {
        final parts = selectedRange!.split('-');
        final start = int.parse(parts[0]);
        final end = int.parse(parts[1]);
        newData = newData.where((episode) {
          final episodeNumber = episode['number'];
          return episodeNumber >= start && episodeNumber <= end;
        }).toList();
      }

      if (filter.isNotEmpty) {
        filteredEpisodes = newData.where((episode) {
          return episode['number'].toString().contains(filter);
        }).toList();
      } else {
        filteredEpisodes = newData;
      }
    });
  }

  void serverSwitch(int index, String name) {
    String newName = name.toLowerCase();
    if (index == 2) {
      if (usingConsumet) {
        newName = 'streamsb';
      } else {
        newName = 'hd-1';
      }
    }
    setState(() {
      selectedIndex = index;
      activeServer = newName;
    });
    if (usingConsumet) {
      fetchEpisodeSrcsConsumet();
    } else {
      fetchEpisodeSrcs();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeProvider = Theme.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(IconlyBold.arrow_left),
        ),
        title: TextScroll(
          isInfoLoading ? 'Loading' : animeData['name'].toString(),
          mode: TextScrollMode.bouncing,
          velocity: const Velocity(pixelsPerSecond: Offset(30, 0)),
          delayBefore: const Duration(milliseconds: 500),
          pauseBetween: const Duration(milliseconds: 1000),
          textAlign: TextAlign.center,
          selectable: true,
          style: const TextStyle(fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
              ? const Center(child: Text('Failed to load data.'))
              : ListView(
                  children: [
                    if (episodeSrc == null)
                      const SizedBox(
                          height: 200,
                          child: Center(
                            child: SizedBox(
                              height: 50,
                              width: 50,
                              child: CircularProgressIndicator(),
                            ),
                          ))
                    else
                      VideoPlayerAlt(
                          videoUrl: episodeSrc,
                          tracks: subtitleTracks,
                          provider: ThemeProvider),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Column(
                        children: [
                          if (!usingConsumet)
                            MyTabBar(
                              onTap: handleLanguage,
                            ),
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Servers',
                                  style: TextStyle(
                                      fontSize: 20,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                ),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      Server_Button(
                                        name: 'VidStream',
                                        index: 0,
                                        selectedIndex: selectedIndex,
                                        onPressed: (int index, String name) =>
                                            serverSwitch(index, name),
                                      ),
                                      Server_Button(
                                        name: 'MegaCloud',
                                        index: 1,
                                        selectedIndex: selectedIndex,
                                        onPressed: (int index, String name) =>
                                            serverSwitch(index, name),
                                      ),
                                      Server_Button(
                                        name: 'StreamSB',
                                        index: 2,
                                        selectedIndex: selectedIndex,
                                        onPressed: (int index, String name) =>
                                            serverSwitch(index, name),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                          const SizedBox(height: 15),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10.0),
                            child: SizedBox(
                              height: 50,
                              width: double.infinity,
                              child: Row(
                                children: [
                                  Container(
                                      height: 50,
                                      width: 100,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainer,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: EpisodeDropdown(
                                        episodesData: filteredEpisodes ?? [],
                                        selectedRange: selectedRange,
                                        onRangeSelected: (range) {
                                          setState(() {
                                            selectedRange = range;
                                            final parts = range.split('-');
                                            final start = int.parse(parts[0]);
                                            final end = int.parse(parts[1]);
                                            filteredEpisodes =
                                                episodesData?.where((episode) {
                                                      final episodeNumber =
                                                          episode['number'];
                                                      return episodeNumber >=
                                                              start &&
                                                          episodeNumber <= end;
                                                    }).toList() ??
                                                    [];
                                            filterEpisodes();
                                          });
                                        },
                                      )),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: episodeFilterController,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        hintText: 'Filter Episode...',
                                        suffixIcon:
                                            const Icon(Iconsax.search_normal),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainer,
                                    ),
                                    child: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          isList = !isList;
                                        });
                                      },
                                      icon: Icon(
                                        isList
                                            ? Icons.menu
                                            : Icons.grid_on_rounded,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    EpisodeGrid(
                        currentEpisode: currentEpisode!,
                        episodes: filteredEpisodes!,
                        isList: isList,
                        onEpisodeSelected: (int episode) {
                          handleEpisode(episode);
                        }),
                    const SizedBox(height: 20),
                    Column(children: [
                      ReusableCarousel(
                        title: 'Seasons',
                        carouselData: animeData['seasons'],
                        tag: 'streaming-page1',
                      ),
                      const SizedBox(height: 10),
                      ReusableCarousel(
                        title: 'Related',
                        carouselData: animeData['relatedAnimes'],
                        tag: 'streaming-page2',
                      ),
                      ReusableCarousel(
                        title: 'Recommended',
                        carouselData: animeData['recommendedAnimes'],
                        tag: 'streaming-page2',
                      ),
                    ]),
                  ],
                ),
    );
  }
}

class Server_Button extends StatelessWidget {
  final String? name;
  final int? index;
  final int? selectedIndex;
  final void Function(int, String) onPressed;
  const Server_Button(
      {super.key,
      required this.name,
      this.index,
      this.selectedIndex,
      required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: ChoiceChip(
        label: Text(name!),
        selected: index == selectedIndex,
        onSelected: (bool selected) => onPressed(index!, name!),
      ),
    );
  }
}
