// ignore_for_file: prefer_const_constructors, deprecated_member_use, non_constant_identifier_names, must_be_immutable, avoid_print, use_build_context_synchronously

import 'dart:convert';
import 'dart:developer';
import 'package:anymex/api/Mangayomi/Eval/dart/model/m_chapter.dart';
import 'package:anymex/api/Mangayomi/Eval/dart/model/m_manga.dart';
import 'package:anymex/api/Mangayomi/Eval/dart/model/video.dart' as v;
import 'package:anymex/api/Mangayomi/Extensions/extensions_provider.dart';
import 'package:anymex/api/Mangayomi/Model/Source.dart';
import 'package:anymex/api/Mangayomi/Search/getVideo.dart';
import 'package:anymex/api/Mangayomi/Search/get_detail.dart';
import 'package:anymex/auth/auth_provider.dart';
import 'package:anymex/components/android/anime/details/episode_buttons.dart';
import 'package:anymex/components/android/anime/details/episode_list.dart';
import 'package:anymex/components/desktop/anime/episode_grid.dart';
import 'package:anymex/components/platform_builder.dart';
import 'package:anymex/hiveData/appData/database.dart';
import 'package:anymex/models/server.dart';
import 'package:anymex/pages/Anime/widgets/goto_extensions.dart';
import 'package:anymex/pages/Anime/watch_page.dart';
import 'package:anymex/utils/downloader/downloader.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as rp;
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

class RescueDetailsPage extends rp.ConsumerStatefulWidget {
  final String id;
  final String? posterUrl;
  final String? tag;
  final String? title;
  final Source source;
  const RescueDetailsPage({
    super.key,
    required this.source,
    required this.id,
    this.posterUrl,
    this.tag,
    this.title,
  });

  @override
  rp.ConsumerState<RescueDetailsPage> createState() =>
      _RescueDetailsPageState();
}

class _RescueDetailsPageState extends rp.ConsumerState<RescueDetailsPage>
    with SingleTickerProviderStateMixin {
  bool isLoading = true;
  int selectedIndex = 0;
  // Episodes Section
  List<MChapter>? episodesData;
  int availEpisodes = 0;
  List<v.Video>? episodeSrc;
  int currentEpisode = 1;
  List<v.Track>? subtitleTracks;
  Server? activeServer;

  // Sources
  MManga? fetchedData;
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
    activeSource = widget.source;
    mapToAnilist();
  }

  String? errorMessage;

  Future<void> mapToAnilist({bool isFirstTime = true, Source? source}) async {
    try {
      final finalSource = source ?? activeSource;

      final episodeFuture = await getDetail(
        url: widget.id,
        source: finalSource!,
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
      animeId: '',
      animeTitle: fetchedData!.name!,
      currentEpisode: (isOOB ? currentEpisode : currentEpisode + 1).toString(),
      animePosterImageUrl: fetchedData!.imageUrl!,
      anilistAnimeId: widget.id.toString(),
      currentSource: activeSource!.name!,
      episodeList: episodesData,
      animeDescription: fetchedData!.description!,
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
                    animeId: -1000,
                    tracks: subtitleTracks ?? [],
                    animeTitle: widget.title!,
                    description: '',
                    posterImage: '',
                    activeSource: activeSource!,
                    streams: episodeSrc,
                  )));
    }
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme customScheme = Theme.of(context).colorScheme;

    Widget currentPage = originalDetailsPage(customScheme, context);

    return Scaffold(
      extendBody: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: currentPage,
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
        episodeImages: filteredEpisodes,
        episodes: filteredEpisodes,
        progress: 1,
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
        coverImage: widget.posterUrl ?? '',
        onEpisodeDownload: (String episodeId, String episodeNumber) async {
          try {
            showDownloadOptions(context,
                isLoading: true,
                server: '',
                source: '',
                sourcesData: [],
                episodeNumber: '');
            final downloadMeta = await downloadHelper(episodeId);
            Navigator.pop(context);
            showDownloadOptions(context,
                isLoading: false,
                server: "VidStream",
                source: activeSource!.name!,
                sourcesData: downloadMeta,
                episodeNumber: "Episode-$episodeNumber");
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
        episodeImages: filteredEpisodes,
        episodes: filteredEpisodes,
        progress: 1,
        layoutIndex: layoutIndex,
        onEpisodeSelected: (int episode) async {
          setState(() {
            currentEpisode = episode;
          });
          showLoading();
          await fetchEpisodeSrcs();
          selectServerDialog(context);
        },
        coverImage: widget.posterUrl!,
        onEpisodeDownload: (String episodeId, String episodeNumber) async {
          showDownloadOptions(context,
              isLoading: true,
              server: '',
              source: '',
              sourcesData: [],
              episodeNumber: '');
          final downloadMeta = await downloadHelper(episodeId);
          Navigator.pop(context);
          showDownloadOptions(context,
              isLoading: false,
              server: "VidStream",
              source: activeSource!.name!,
              sourcesData: downloadMeta,
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

  Future<dynamic> downloadHelper(String episodeId) async {
    String? episodeSrc;
    dynamic response;

    try {
      response = await getVideo(source: activeSource!, url: episodeId);

      if (response != null) {
        List<Map<String, dynamic>> qualitiesList = [];

        // Check if `multiSrc` exists in the response
        if (response['multiSrc'] != null) {
          for (var src in response['multiSrc']) {
            qualitiesList.add({
              'quality': src['quality'] ?? 'Unknown Quality',
              'url': src['url'] ?? '',
            });
          }
        } else {
          episodeSrc = response['sources'][0]['url'];
          String m3u8Url = episodeSrc!;
          final parts = m3u8Url.split('/');
          parts.removeLast();
          final baseUrl = '${parts.join('/')}/';
          log('base url: $baseUrl');
          log('m3u8 url: $m3u8Url');

          if (m3u8Url.contains("uwu.m3u8")) {
            m3u8Url = m3u8Url.replaceAll("uwu.m3u8", "master.m3u8");
            log('Changed to master.m3u8: $m3u8Url');
          }

          final fetchedQualities = await fetchM3u8Links(m3u8Url, baseUrl);
          qualitiesList.addAll(fetchedQualities);
        }

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

  Future<void> showDownloadOptions(
    BuildContext context, {
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
                          physics: const BouncingScrollPhysics(),
                          itemCount: sourcesData.length,
                          itemBuilder: (context, index) {
                            final quality = sourcesData[index]['quality'];
                            final url = sourcesData[index]['url'];
                            return _buildTile('$server - $quality', 'M3U8', () {
                              Downloader downloader = Downloader();
                              downloader.download(
                                  url, episodeNumber, widget.title ?? '??');
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
              imageUrl: poster!,
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
                        widget.title ?? 'Loading',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            overflow: TextOverflow.ellipsis),
                        maxLines: 2,
                      ),
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
      return originalInfoPage(CustomScheme, context);
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
              Text('Description',
                  style: TextStyle(fontFamily: 'Poppins-SemiBold')),
              const SizedBox(
                height: 5,
              ),
              Column(
                children: [
                  Text(
                    fetchedData?.description ?? 'Description Not Found',
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
              infoRow(field: 'Type', value: 'TV'),
              infoRow(field: 'Genres', value: fetchedData!.genre.toString()),
              infoRow(
                  field: 'Status', value: fetchedData?.status?.name ?? '??'),
              infoRow(field: 'Artist', value: fetchedData?.artist ?? '??'),
              infoRow(field: 'Studio', value: fetchedData?.author ?? '??'),
            ],
          ),
        ),
        const SizedBox(
          height: 20,
        ),
        episodeSection(context)
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
          Expanded(
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
