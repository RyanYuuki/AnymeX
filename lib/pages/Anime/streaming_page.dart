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
  bool isList = false;
  List<dynamic> filteredEpisodes = [];

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
        availEpisodes = animeData['anime']['info']['stats']['episodes']['dub'];
        isDub = true;
      }
    });
    fetchEpisodeSrcs();
  }

  void filterEpisodes() {
    setState(() {
      final filter = episodeFilterController.text;
      if (filter.isNotEmpty) {
        filteredEpisodes = episodesData.where((episode) {
          return episode['number'].toString().contains(filter);
        }).toList();
      } else {
        filteredEpisodes = episodesData;
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
                    if (episodeSrc != null)
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: TextField(
                                    controller: episodeFilterController,
                                    decoration: InputDecoration(
                                      hintText: 'Filter Episode...',
                                      suffixIcon:
                                          const Icon(Iconsax.search_normal),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondary,
                                          width: 1,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
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
                              ),
                              const SizedBox(width: 10),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                                child: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        isList = !isList;
                                      });
                                    },
                                    icon: Icon(isList
                                        ? Icons.menu
                                        : Icons.grid_on_rounded)),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isList ? 1 : 5,
                        mainAxisExtent: isList ? 50 : 40,
                      ),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredEpisodes.length,
                      itemBuilder: (context, index) {
                        final episode = filteredEpisodes[index];
                        return GestureDetector(
                          onTap: () => handleEpisode(episode['number']),
                          child: Container(
                            width: isList ? double.infinity : null,
                            height: 40,
                            margin: const EdgeInsets.all(4.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: currentEpisode == episode['number']
                                  ? Theme.of(context).colorScheme.primary
                                  : (episode['isFiller']
                                      ? Colors.lightGreen.shade700
                                      : Theme.of(context)
                                          .colorScheme
                                          .secondary),
                            ),
                            child: Padding(
                              padding:
                                  EdgeInsets.only(left: isList ? 8.0 : 0.0),
                              child: Row(
                                mainAxisAlignment: isList
                                    ? MainAxisAlignment.start
                                    : MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  currentEpisode == episode['number']
                                      ? const Icon(Icons.play_arrow_rounded)
                                      : Text(
                                          isList
                                              ? '${episode['number']}.'
                                              : episode['number'].toString(),
                                          style: TextStyle(
                                              color: currentEpisode ==
                                                      episode['number']
                                                  ? Colors.white
                                                  : null),
                                        ),
                                  SizedBox(width: isList ? 5 : 0),
                                  SizedBox(
                                    width: isList
                                        ? MediaQuery.of(context).size.width /
                                            1.5
                                        : 0,
                                    child: TextScroll(
                                      isList
                                          ? (episode['title'].length > 40
                                              ? '${episode['title'].toString().substring(0, 40)}...'
                                              : episode['title'])
                                          : '',
                                      mode: TextScrollMode.bouncing,
                                      velocity: const Velocity(
                                          pixelsPerSecond: Offset(10, 0)),
                                      delayBefore:
                                          const Duration(milliseconds: 500),
                                      pauseBetween:
                                          const Duration(milliseconds: 1000),
                                      textAlign: TextAlign.center,
                                      selectable: true,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Column(
                        children: [
                          if (animeData != null) ...[
                            ReusableCarousel(
                                title: 'Popular',
                                carouselData: animeData['mostPopularAnimes']),
                            const SizedBox(height: 10),
                            ReusableCarousel(
                                title: 'Related',
                                carouselData: animeData['relatedAnimes']),
                            const SizedBox(height: 10),
                            ReusableCarousel(
                                title: 'Recommended',
                                carouselData: animeData['recommendedAnimes']),
                          ],
                        ],
                      ),
                    )
                  ],
                ),
    );
  }
}
