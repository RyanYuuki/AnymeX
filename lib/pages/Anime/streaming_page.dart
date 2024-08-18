import 'package:flutter/material.dart';
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

  final String baseUrl = 'https://aniwatch-ryan.vercel.app/anime/';
  final String episodeDataUrl =
      'https://aniwatch-ryan.vercel.app/anime/episodes/';
  final String episodeUrl =
      'https://aniwatch-ryan.vercel.app/anime/episode-srcs?id=';

  @override
  void initState() {
    super.initState();
    fetchAnimeData();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
                      child: Row(
                        children: [
                          MyTabBar(
                            onTap: handleLanguage,
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        mainAxisExtent: 40,
                      ),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: availEpisodes ?? 0,
                      itemBuilder: (context, index) {
                        final episode = episodesData[index];
                        return RepaintBoundary(
                          child: GestureDetector(
                            onTap: () => handleEpisode(episode['number']),
                            child: Container(
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
                              child: Center(
                                child: Text(
                                  episode['number'].toString(),
                                  style: TextStyle(
                                      color: currentEpisode == episode['number']
                                          ? Colors.white
                                          : null),
                                ),
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
                            const SizedBox(height: 20),
                            ReusableCarousel(
                                title: 'Related',
                                carouselData: animeData['relatedAnimes']),
                            const SizedBox(height: 20),
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
