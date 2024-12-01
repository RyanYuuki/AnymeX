// ignore_for_file: prefer_const_constructors, deprecated_member_use, non_constant_identifier_names, must_be_immutable, avoid_print, use_build_context_synchronously

import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:anymex/components/android/anime/details/episode_list.dart';
import 'package:anymex/components/desktop/anime/episode_grid.dart';
import 'package:anymex/components/platform_builder.dart';
import 'package:anymex/pages/Android/Anime/watch_page.dart';
import 'package:anymex/pages/Desktop/watch_page.dart';
import 'package:anymex/utils/downloader/downloader.dart';
import 'package:anymex/utils/sources/anime/extensions/aniwatch/aniwatch.dart';
import 'package:anymex/utils/sources/anime/handler/sources_handler.dart';
import 'package:anymex/utils/sources/unified_handler.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:text_scroll/text_scroll.dart';

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

class RescueDetailsPage extends StatefulWidget {
  final String id;
  final String? posterUrl;
  final String? tag;
  final String title;
  const RescueDetailsPage(
      {super.key,
      required this.id,
      this.posterUrl,
      this.tag,
      required this.title});

  @override
  State<RescueDetailsPage> createState() => _RescueDetailsPageState();
}

class _RescueDetailsPageState extends State<RescueDetailsPage> {
  bool isLoading = true;
  dynamic episodesData;
  dynamic episodeSrc;

  int currentEpisode = 1;
  dynamic subtitleTracks;
  String activeServer = 'vidstream';
  bool isDub = false;
  int watchProgress = 1;
  final serverList = ['HD-1', 'HD-2', 'Vidstream'];
  List<IconData> layoutIcons = [
    IconlyBold.image,
    Icons.list_rounded,
    Iconsax.grid_25
  ];
  int layoutIndex = 0;
  late SourcesHandler sourcesHandler;

  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    sourcesHandler = Provider.of<UnifiedSourcesHandler>(context, listen: false)
        .getAnimeInstance();
    fetchEpisodes();
  }

  Future<void> fetchEpisodes() async {
    try {
      setState(() {
        isLoading = true;
      });

      final tempepisodesData = await sourcesHandler.fetchEpisodes(widget.id);
      setState(() {
        episodesData = tempepisodesData;
        isLoading = false;
        filteredEpisodes = episodesData['episodes'];
      });
      log(tempepisodesData.toString());
    } catch (e) {
      log("Error in fetchFromAniwatch: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<dynamic> downloadHelper(String episodeId) async {
    String? episodeSrc;
    dynamic response;

    try {
      response = await sourcesHandler.fetchEpisodesSrcs(episodeId,
          category: isDub ? 'dub' : 'sub',
          server: AnimeServers.MegaCloud,
          lang: activeServer);

      if (response != null) {
        episodeSrc = response['sources'][0]['url'];
        final m3u8Url = episodeSrc;
        final parts = m3u8Url!.split('/');
        parts.removeLast();
        final baseUrl = '${parts.join('/')}/';
        log('base url: $baseUrl');
        log('m3u8 url: $m3u8Url');

        final qualitiesList = await fetchM3u8Links(m3u8Url, baseUrl);

        if (qualitiesList.isNotEmpty) {
          return qualitiesList;
        } else {
          print('No qualities found.');
        }
      } else {
        print('Error: No sources found in the response.');
      }
    } catch (e) {
      print('Error fetching episode sources: $e');
    }
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

  Future<void> showDownloadOptions({
    required bool isLoading,
    required String server,
    required String source,
    required dynamic sourcesData,
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
                          itemCount: sourcesData.length,
                          itemBuilder: (context, index) {
                            final quality = sourcesData[index]['quality'];
                            final url = sourcesData[index]['url'];
                            return _buildTile('$server - $quality', 'M3U8', () {
                              Downloader downloader = Downloader();
                              downloader.download(
                                  url, episodeNumber, widget.title);
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

  Widget _buildServerTile(String title, String type, VoidCallback onTap) {
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
            sourcesHandler.getSelectedSource(),
            style: TextStyle(color: Colors.grey[400]),
          ),
          trailing: const Icon(Iconsax.play5),
        ),
      ),
    );
  }

  showLoading() {
    Navigator.pop(context);
    showDialog(
        context: context,
        builder: (context) => Center(
              child: CircularProgressIndicator(),
            ));
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
                color:
                    Theme.of(context).colorScheme.surface, // Background color
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    height: 4,
                    width: 40,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
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
                  for (int i = 0; i < 3; i++) ...[
                    _buildServerTile(serverList[i], 'FAST', () async {
                      setState(() {
                        activeServer = (serverList[i]).toLowerCase();
                      });
                      showLoading();
                      await fetchEpisodeSrcs();
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

  Future<void> fetchEpisodeSrcs() async {
    episodeSrc = null;
    if (episodesData == null) return;
    try {
      dynamic response;
      response = await sourcesHandler.fetchEpisodesSrcs(
          episodesData?['episodes'][(currentEpisode - 1)]['episodeId'],
          category: isDub ? 'dub' : 'sub',
          lang: activeServer);

      if (response != null) {
        log(response.toString());
        setState(() {
          subtitleTracks = response['tracks'];
          episodeSrc = response;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      log('Error fetching episode sources: $e');
    }

    if (episodeSrc != null) {
      Navigator.pop(context);
      if (!Platform.isAndroid && !Platform.isIOS) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => WatchPage(
                      episodeSrc: episodeSrc ?? [],
                      episodeData: episodesData?['episodes'],
                      currentEpisode: currentEpisode,
                      episodeTitle: episodesData?['episodes']
                              [currentEpisode - 1]['title'] ??
                          '',
                      animeTitle: widget.title,
                      activeServer: activeServer,
                      isDub: isDub,
                      animeId: 0,
                      tracks: subtitleTracks,
                      provider: Theme.of(context),
                      sourceAnimeId: episodesData['id'] ?? 'rescue',
                      description: '',
                      posterImage: widget.posterUrl!,
                    )));
      } else {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => DesktopWatchPage(
                      episodeSrc: episodeSrc ?? [],
                      episodeData: episodesData?['episodes'],
                      currentEpisode: currentEpisode,
                      episodeTitle: episodesData?['episodes']
                              [currentEpisode - 1]['title'] ??
                          '',
                      animeTitle: widget.title,
                      activeServer: activeServer,
                      isDub: isDub,
                      animeId: 0,
                      tracks: subtitleTracks,
                      provider: Theme.of(context),
                      sourceAnimeId: episodesData['id'] ?? 'rescue',
                      description: '',
                      posterImage: widget.posterUrl!,
                    )));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme CustomScheme = Theme.of(context).colorScheme;
    return originalDetailsPage(CustomScheme, context);
  }

  Scaffold originalDetailsPage(ColorScheme CustomScheme, BuildContext context) {
    return Scaffold(
      backgroundColor: CustomScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: TextScroll(
          widget.title,
          mode: TextScrollMode.bouncing,
          velocity: const Velocity(pixelsPerSecond: Offset(30, 0)),
          delayBefore: const Duration(milliseconds: 500),
          pauseBetween: const Duration(milliseconds: 1000),
          textAlign: TextAlign.center,
          selectable: true,
          style: const TextStyle(fontSize: 16),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(IconlyBold.arrow_left),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: isLoading
          ? Column(
              children: [
                Center(
                  child: Poster(tag: widget.tag, poster: widget.posterUrl),
                ),
                const SizedBox(height: 30),
                CircularProgressIndicator(),
              ],
            )
          : ListView(
              children: [
                Column(
                  children: [
                    Poster(
                      tag: widget.tag,
                      poster: widget.posterUrl,
                    ),
                    const SizedBox(height: 30),
                    Info(context),
                  ],
                ),
              ],
            ),
    );
  }

  List<dynamic> filteredEpisodes = [];

  void filterEpisodes(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredEpisodes = episodesData?['episodes'] ?? [];
      } else {
        filteredEpisodes = episodesData?['episodes']
                .where((episode) =>
                    episode['title']
                        .toLowerCase()
                        .contains(query.toLowerCase()) ||
                    episode['number']
                        .toString()
                        .contains(query)) // Filtering by episode number
                .toList() ??
            [];
      }
    });
  }

  Container Info(BuildContext context) {
    ColorScheme CustomScheme = Theme.of(context).colorScheme;

    return Container(
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Platform.isAndroid
            ? CustomScheme.surfaceContainer
            : CustomScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (sourcesHandler.selectedSource != "GogoAnime") ...[
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedPositioned(
                          top: isDub ? 40 : 5,
                          duration: Duration(milliseconds: 300),
                          child: Icon(Iconsax.subtitle5, size: 30)),
                      AnimatedPositioned(
                          top: isDub ? 5 : 40,
                          duration: Duration(milliseconds: 300),
                          child: Icon(Iconsax.microphone5, size: 30)),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                Switch(
                  value: isDub,
                  onChanged: (value) {
                    setState(() {
                      isDub = !isDub;
                    });
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search by title or episode number...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: CustomScheme.onSurface),
              ),
              contentPadding:
                  EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            ),
            onChanged: (query) {
              filterEpisodes(query);
            },
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Episodes',
                style: TextStyle(fontSize: 24, fontFamily: "Poppins-SemiBold"),
              ),
              IconButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainer,
                ),
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
          ),
          const SizedBox(height: 10),
          PlatformBuilder(
            androidBuilder: EpisodeGrid(
              episodes: filteredEpisodes,
              layoutIndex: layoutIndex,
              currentEpisode: currentEpisode,
              onEpisodeSelected: (int episode) {
                setState(() {
                  currentEpisode = episode;
                });
                selectServerDialog(context);
              },
              progress: watchProgress,
              coverImage: widget.posterUrl!,
              onEpisodeDownload:
                  (String episodeId, String episodeNumber) async {
                showDownloadOptions(
                  isLoading: true,
                  server: '',
                  source: '',
                  sourcesData: [],
                  episodeNumber: '',
                );
                final downloadMeta = await downloadHelper(episodeId);
                Navigator.pop(context);
                showDownloadOptions(
                  isLoading: false,
                  server: "MegaCloud",
                  source: "HiAnime (API)",
                  sourcesData: downloadMeta,
                  episodeNumber: "Episode-$episodeNumber",
                );
              },
            ),
            desktopBuilder: DesktopEpisodeGrid(
              episodes: filteredEpisodes,
              layoutIndex: layoutIndex,
              currentEpisode: currentEpisode,
              onEpisodeSelected: (int episode) {
                setState(() {
                  currentEpisode = episode;
                });
                selectServerDialog(context);
              },
              progress: watchProgress,
              coverImage: widget.posterUrl!,
              onEpisodeDownload:
                  (String episodeId, String episodeNumber) async {
                showDownloadOptions(
                  isLoading: true,
                  server: '',
                  source: '',
                  sourcesData: [],
                  episodeNumber: '',
                );
                final downloadMeta = await downloadHelper(episodeId);
                Navigator.pop(context);
                showDownloadOptions(
                  isLoading: false,
                  server: "MegaCloud",
                  source: "HiAnime (API)",
                  sourcesData: downloadMeta,
                  episodeNumber: "Episode-$episodeNumber",
                );
              },
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class Poster extends StatelessWidget {
  const Poster({
    super.key,
    required this.tag,
    required this.poster,
  });
  final String? poster;
  final String? tag;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          PlatformBuilder(
            androidBuilder: Container(
              margin: EdgeInsets.only(top: 30),
              height: 400,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    spreadRadius: 5,
                    blurRadius: 10,
                    offset: Offset(0, 7),
                  ),
                ],
              ),
              width: MediaQuery.of(context).size.width - 100,
              child: Hero(
                tag: tag!,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CachedNetworkImage(
                    imageUrl: poster!,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                ),
              ),
            ),
            desktopBuilder: Container(
              margin: EdgeInsets.only(top: 30),
              height: 400,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    spreadRadius: 5,
                    blurRadius: 10,
                    offset: Offset(0, 7),
                  ),
                ],
              ),
              width: 300,
              child: Hero(
                tag: tag!,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CachedNetworkImage(
                    imageUrl: poster!,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
