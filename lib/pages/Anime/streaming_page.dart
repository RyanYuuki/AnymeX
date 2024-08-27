import 'package:aurora/components/episode_list.dart';
import 'package:aurora/components/episodelist_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';
import 'package:text_scroll/text_scroll.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
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

  final String baseUrl = 'https://aniwatch-ryan.vercel.app/anime/';
  final String episodeDataUrl =
      'https://aniwatch-ryan.vercel.app/anime/episodes/';
  final String episodeUrl =
      'https://aniwatch-ryan.vercel.app/anime/episode-srcs?id=';

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
      isLoading = true;
      isInfoLoading = true;
      availEpisodes = 0;
      hasError = false;
    });

    try {
      final response = await http.get(Uri.parse('$episodeDataUrl${widget.id}'));
      final animeDataResponse =
          await http.get(Uri.parse('${baseUrl}info?id=${widget.id!}'));

      if (response.statusCode == 200 && animeDataResponse.statusCode == 200) {
        final tempAnimeData = jsonDecode(animeDataResponse.body);
        final tempData = jsonDecode(response.body);

        setState(() {
          animeData = tempAnimeData;
          availEpisodes =
              tempAnimeData['anime']['info']['stats']['episodes']['sub'];
          isInfoLoading = false;
          episodesData = tempData['episodes'];
          filteredEpisodes = tempData['episodes'];
          currentEpisode = 1;
        });

        fetchEpisodeSrcs();
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
      print('Error fetching data: $e');
    }
  }

  Future<void> fetchEpisodeSrcs() async {
    episodeSrc = null;
    if (episodesData == null || currentEpisode == null) return;

    try {
      final response = await http.get(Uri.parse(
        '$episodeUrl${episodesData[currentEpisode! - 1]['episodeId']}&category=${isDub ? 'dub' : 'sub'}',
      ));

      if (response.statusCode == 200) {
        final episodeSrcs = jsonDecode(response.body);
        setState(() {
          subtitleTracks = episodeSrcs['tracks'];
          episodeSrc = episodeSrcs['sources'][0]['url'];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load episode sources');
      }
    } catch (e) {
      setState(() {
        hasError = true;
      });
      print('Error fetching episode sources: $e');
    }
  }

  void handleEpisode(int? episode) {
    setState(() {
      currentEpisode = episode;
    });
    fetchEpisodeSrcs();
  }

  void handleLanguage(int? index) {
    setState(() {
      if (index == 1) {
        isDub = false;
        availEpisodes = animeData['anime']['info']['stats']['episodes']['sub'];
      } else {
        availEpisodes =
            animeData['anime']['info']['stats']['episodes']['dub'] ?? 0;
        isDub = true;
      }
      filteredEpisodes = episodesData.sublist(0, availEpisodes);
      filterEpisodes();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(IconlyBold.arrow_left),
        ),
        title: TextScroll(
          isInfoLoading
              ? 'Loading'
              : animeData['anime']['info']['name'].toString(),
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
                          videoUrl: episodeSrc, tracks: subtitleTracks),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Column(
                        children: [
                          MyTabBar(
                            onTap: handleLanguage,
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
                        episodes: filteredEpisodes!,
                        isList: isList,
                        onEpisodeSelected: (int episode) {
                          handleEpisode(episode);
                        }),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Column(
                        children: [
                          if (animeData != null) ...[
                            if (animeData['seasons'].length > 0)
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
                            )
                          ]
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
