// ignore_for_file: prefer_const_constructors, deprecated_member_use, non_constant_identifier_names, must_be_immutable, avoid_print

import 'dart:convert';
import 'dart:developer';
import 'dart:ui';
import 'package:aurora/components/anime/details/episode_list.dart';
import 'package:aurora/components/common/IconWithLabel.dart';
import 'package:aurora/pages/Mobile/Anime/watch_page.dart';
import 'package:aurora/utils/downloader/downloader.dart';
import 'package:aurora/utils/sources/anime/extensions/aniwatch/aniwatch.dart';
import 'package:aurora/utils/sources/anime/extensions/aniwatch_api/api.dart';
import 'package:aurora/utils/sources/anime/handler/sources_handler.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:html/parser.dart';
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
  const RescueDetailsPage(
      {super.key, required this.id, this.posterUrl, this.tag});

  @override
  State<RescueDetailsPage> createState() => _RescueDetailsPageState();
}

class _RescueDetailsPageState extends State<RescueDetailsPage>
    with SingleTickerProviderStateMixin {
  bool usingConsumet =
      Hive.box('app-data').get('using-consumet', defaultValue: false);
  bool usingSaikouLayout =
      Hive.box('app-data').get('usingSaikouLayout', defaultValue: false);
  bool consumetSesh = false;
  dynamic data;
  bool isLoading = true;
  dynamic altdata;
  dynamic charactersdata;
  String? description;
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
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    fetchFromAniwatch();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: -1.0, end: -2.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));
  }

  Future<void> fetchFromAniwatch() async {
    try {
      setState(() {
        isLoading = true;
      });

      final tempData = await scrapeAnimeAboutInfo(widget.id);
      final hiAnimeInstance = HiAnimeApi();

      final tempepisodesData = await hiAnimeInstance.scrapeEpisodes(widget.id);

      setState(() {
        data = tempData;
        episodesData = tempepisodesData;
        consumetSesh = false;
        description = data?['description'];
        isLoading = false;
      });
    } catch (e) {
      log("Error in fetchFromAniwatch: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<dynamic> downloadHelper(String episodeId) async {
    String? episodeSrc;
    final provider = HiAnimeApi();
    dynamic response;

    try {
      response = await provider.scrapeEpisodesSrcs(episodeId,
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
            Provider.of<SourcesHandler>(context).getSelectedSource(),
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
      response = await HiAnimeApi().scrapeEpisodesSrcs(
          episodesData?['episodes'][(currentEpisode - 1)]['episodeId'],
          category: isDub ? 'dub' : 'sub',
          lang: activeServer);

      if (response != null) {
        log(response.toString());
        setState(() {
          subtitleTracks = response['tracks'];
          episodeSrc = response['sources'];
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
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => WatchPage(
                    episodeSrc: episodeSrc ?? [],
                    episodeData: episodesData?['episodes'],
                    currentEpisode: currentEpisode,
                    episodeTitle: episodesData?['episodes'][currentEpisode - 1]
                            ['title'] ??
                        '',
                    animeTitle: data['name'] ?? data['jname'],
                    activeServer: activeServer,
                    isDub: isDub,
                    animeId: 0,
                    tracks: subtitleTracks,
                    provider: Theme.of(context),
                    sourceAnimeId: data['id'],
                    description: data?['description'] ?? '',
                    posterImage: widget.posterUrl!,
                  )));
    }
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme CustomScheme = Theme.of(context).colorScheme;
    if (usingSaikouLayout) {
      return saikouDetailsPage(context);
    } else {
      return originalDetailsPage(CustomScheme, context);
    }
  }

  Scaffold saikouDetailsPage(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Section
            saikouTopSection(context),
            // Mid Section
            isLoading
                ? Padding(
                    padding: const EdgeInsets.only(top: 30.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 25.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text.rich(
                              TextSpan(
                                text: 'Total of ',
                                style: TextStyle(fontSize: 15),
                                children: [
                                  TextSpan(
                                    text:
                                        '${data?['stats']?['episodes']?['sub'] ?? data?['totalEpisodes']}',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontFamily: 'Poppins-Bold',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(child: SizedBox.shrink()),
                            IconButton(
                                onPressed: () {}, icon: Icon(Iconsax.heart)),
                            IconButton(
                                onPressed: () {}, icon: Icon(Icons.share)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        infoRow(
                            field: 'Rating',
                            value:
                                '${data?['malscore']?.toString() ?? (int.parse(data?['rating']) / 10).toString()}/10'),
                        infoRow(
                            field: 'Studios',
                            value: data?['studios'] ??
                                data?['studios']?[0] ??
                                '??'),
                        infoRow(
                            field: 'Total Episodes',
                            value: data?['stats']?['episodes']?['sub']
                                    .toString() ??
                                data?['totalEpisodes'] ??
                                '??'),
                        infoRow(field: 'Type', value: 'TV'),
                        infoRow(
                            field: 'Romaji Name',
                            value: data?['jname'] ?? data?['japanese'] ?? '??'),
                        infoRow(
                            field: 'Premiered',
                            value: data?['premiered'] ?? '??'),
                        infoRow(
                            field: 'Duration',
                            value:
                                '${data?['duration']}${consumetSesh ? 'M' : ''}'),
                        const SizedBox(height: 20),
                        Text('Synopsis',
                            style: TextStyle(fontFamily: 'Poppins-Bold')),
                        const SizedBox(height: 10),
                        Text(description!.toString().length > 250
                            ? '${description!.toString().substring(0, 250)}...'
                            : description!),

                        // Grid Section
                        const SizedBox(height: 20),
                        Text('Genres',
                            style: TextStyle(fontFamily: 'Poppins-Bold')),
                        Flexible(
                          flex: 0,
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: data?['genres'].length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisExtent: 55,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemBuilder: (context, itemIndex) {
                              String genre = data?['genres'][itemIndex];
                              String buttonBackground = genrePreviews[genre] ??
                                  genrePreviews['default'];

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
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          image: DecorationImage(
                                            image:
                                                NetworkImage(buttonBackground),
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
                        const SizedBox(height: 15),
                        const SizedBox(
                          height: 30,
                        ),
                        Row(
                          children: [
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
                                      child:
                                          Icon(Iconsax.microphone5, size: 30)),
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
                                }),
                          ],
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Episodes',
                              style: TextStyle(
                                  fontSize: 24, fontFamily: "Poppins-SemiBold"),
                            ),
                            IconButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainer),
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
                        EpisodeGrid(
                          episodes: episodesData?['episodes'],
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
                                episodeNumber: '');
                            final downloadMeta =
                                await downloadHelper(episodeId);
                            Navigator.pop(context);
                            showDownloadOptions(
                                isLoading: false,
                                server: "MegaCloud",
                                source: "HiAnime (API)",
                                sourcesData: downloadMeta,
                                episodeNumber: "Episode-$episodeNumber");
                          },
                        ),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Stack saikouTopSection(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        if (altdata?['cover'] != null)
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Positioned(
                left: MediaQuery.of(context).size.width * _animation.value,
                child: CachedNetworkImage(
                  height: 450,
                  alignment: Alignment.center,
                  fit: BoxFit.cover,
                  imageUrl: altdata?['cover'] ?? '',
                ),
              );
            },
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
                            width: 200,
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
                  onPressed: () {},
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
                    'ADD TO LIST',
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: TextScroll(
          data == null ? 'Loading...' : data?['name'] ?? '??',
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

  Container Info(BuildContext context) {
    ColorScheme CustomScheme = Theme.of(context).colorScheme;
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CustomScheme.surfaceContainer,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    constraints: BoxConstraints(maxWidth: 170),
                    child: TextScroll(
                      data == null ? 'Loading...' : data?['name'] ?? '??',
                      mode: TextScrollMode.endless,
                      velocity: Velocity(pixelsPerSecond: Offset(50, 0)),
                      delayBefore: Duration(milliseconds: 500),
                      pauseBetween: Duration(milliseconds: 1000),
                      textAlign: TextAlign.center,
                      selectable: true,
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    height: 18,
                    width: 3,
                    color: CustomScheme.inverseSurface,
                  ),
                  const SizedBox(width: 10),
                  iconWithName(
                    backgroundColor: CustomScheme.onPrimaryFixedVariant,
                    icon: Iconsax.star1,
                    TextColor: CustomScheme.inverseSurface ==
                            CustomScheme.onPrimaryFixedVariant
                        ? Colors.black
                        : CustomScheme.onPrimaryFixedVariant ==
                                Color(0xffe2e2e2)
                            ? Colors.black
                            : Colors.white,
                    color: CustomScheme.inverseSurface ==
                            CustomScheme.onPrimaryFixedVariant
                        ? Colors.black
                        : CustomScheme.onPrimaryFixedVariant ==
                                Color(0xffe2e2e2)
                            ? Colors.black
                            : Colors.white,
                    name: data?['rating'] ?? data?['malscore'] ?? '?',
                    isVertical: false,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ],
              ),
              const SizedBox(
                height: 15,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: (data?['genres'] as List<dynamic>? ?? [])
                    .take(3)
                    .map<Widget>(
                      (genre) => Container(
                        margin: EdgeInsets.only(right: 8),
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: CustomScheme.onPrimaryFixedVariant,
                            borderRadius: BorderRadius.circular(5)),
                        child: Text(
                          genre as String,
                          style: TextStyle(
                              color: Theme.of(context)
                                          .colorScheme
                                          .inverseSurface ==
                                      Theme.of(context)
                                          .colorScheme
                                          .onPrimaryFixedVariant
                                  ? Colors.black
                                  : Theme.of(context)
                                              .colorScheme
                                              .onPrimaryFixedVariant ==
                                          Color(0xffe2e2e2)
                                      ? Colors.black
                                      : Colors.white,
                              fontSize: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.fontSize,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 15),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  padding: EdgeInsets.all(7),
                  width: 130,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(5),
                          bottomLeft: Radius.circular(5)),
                      color: CustomScheme.surfaceContainerHighest),
                  child: Column(
                    children: [
                      Text(
                          data?['stats']?['episodes']?['sub']?.toString() ??
                              data?['totalEpisodes'] ??
                              '??',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Episodes')
                    ],
                  ),
                ),
                Container(
                  color: CustomScheme.onPrimaryFixed,
                  height: 30,
                  width: 2,
                ),
                Container(
                  width: 130,
                  padding: EdgeInsets.all(7),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                          topRight: Radius.circular(5),
                          bottomRight: Radius.circular(5)),
                      color: CustomScheme.surfaceContainerHighest),
                  child: Column(
                    children: [
                      Text(
                        data?['duration'] ?? '??',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('Per Ep')
                    ],
                  ),
                ),
              ])
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: CustomScheme.surfaceContainerHighest,
            ),
            padding: EdgeInsets.all(10),
            child: Column(
              children: [
                Text(
                  description?.replaceAll(RegExp(r'<[^>]*>'), '') ??
                      data?['description'].replaceAll(RegExp(r'<[^>]*>'), '') ??
                      'Description Not Found',
                  maxLines: 13,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 30,
          ),
          Row(
            children: [
              if (Provider.of<SourcesHandler>(context).selectedSource !=
                  "GogoAnime") ...[
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
                    }),
              ],
            ],
          ),
          const SizedBox(
            height: 10,
          ),
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
          ),
          const SizedBox(height: 10),
          EpisodeGrid(
            episodes: episodesData?['episodes'],
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
            onEpisodeDownload: (String episodeId, String episodeNumber) async {
              showDownloadOptions(
                  isLoading: true,
                  server: '',
                  source: '',
                  sourcesData: [],
                  episodeNumber: '');
              final downloadMeta = await downloadHelper(episodeId);
              Navigator.pop(context);
              showDownloadOptions(
                  isLoading: false,
                  server: "MegaCloud",
                  source: "HiAnime (API)",
                  sourcesData: downloadMeta,
                  episodeNumber: "Episode-$episodeNumber");
            },
          ),
          const SizedBox(height: 100),
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
          Container(
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
        ],
      ),
    );
  }
}

Future<Map<String, dynamic>> scrapeAnimeAboutInfo(String animeId) async {
  final result = <String, dynamic>{
    'id': animeId,
    'stats': {},
    'promotionalVideos': [],
    'charactersVoiceActors': [],
    'seasons': [],
    'mostPopularAnimes': [],
    'relatedAnimes': [],
    'recommendedAnimes': [],
  };

  try {
    final response = await http.get(Uri.parse('https://hianime.to/$animeId'));

    if (response.statusCode != 200) {
      throw Exception('Failed to load page');
    }

    final document = parse(response.body);

    try {
      final syncData = document.querySelector('#syncData')?.text;
      if (syncData != null) {
        final jsonData = json.decode(syncData);
        result['anilistId'] = jsonData['anilist_id'];
        result['malId'] = jsonData['mal_id'];
      }
    } catch (e) {
      log(e.toString());
    }

    const selector = '#ani_detail .container .anis-content';

    result['name'] = document
        .querySelector('$selector .anisc-detail .film-name.dynamic-name')
        ?.text
        .trim();
    result['description'] = document
        .querySelector('$selector .anisc-detail .film-description .text')
        ?.text
        .split('[')
        .first
        .trim();
    result['poster'] = document
        .querySelector('$selector .film-poster .film-poster-img')
        ?.attributes['src']
        ?.trim();

    result['stats']['rating'] = document
        .querySelector('$selector .film-stats .tick .tick-pg')
        ?.text
        .trim();
    result['stats']['quality'] = document
        .querySelector('$selector .film-stats .tick .tick-quality')
        ?.text
        .trim();
    result['stats']['episodes'] = {
      'sub': int.tryParse(document
              .querySelector('$selector .film-stats .tick .tick-sub')
              ?.text
              .trim() ??
          ''),
      'dub': int.tryParse(document
              .querySelector('$selector .film-stats .tick .tick-dub')
              ?.text
              .trim() ??
          ''),
    };
    final statsText = document
        .querySelector('$selector .film-stats .tick')
        ?.text
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .split(' ');
    result['stats']['type'] = statsText?.elementAt(statsText.length - 2);
    result['stats']['duration'] = statsText?.last;

    document
        .querySelectorAll(
            '.block_area.block_area-promotions .block_area-promotions-list .screen-items .item')
        .forEach((element) {
      result['promotionalVideos'].add({
        'title': element.attributes['data-title'],
        'source': element.attributes['data-src'],
        'thumbnail': element.querySelector('img')?.attributes['src'],
      });
    });

    document
        .querySelectorAll(
            '.block_area.block_area-actors .block-actors-content .bac-list-wrap .bac-item')
        .forEach((element) {
      result['charactersVoiceActors'].add({
        'character': {
          'id': element
              .querySelector('.per-info.ltr .pi-avatar')
              ?.attributes['href']
              ?.split('/')[2],
          'poster': element
              .querySelector('.per-info.ltr .pi-avatar img')
              ?.attributes['data-src'],
          'name': element.querySelector('.per-info.ltr .pi-detail a')?.text,
          'cast':
              element.querySelector('.per-info.ltr .pi-detail .pi-cast')?.text,
        },
        'voiceActor': {
          'id': element
              .querySelector('.per-info.rtl .pi-avatar')
              ?.attributes['href']
              ?.split('/')[2],
          'poster': element
              .querySelector('.per-info.rtl .pi-avatar img')
              ?.attributes['data-src'],
          'name': element.querySelector('.per-info.rtl .pi-detail a')?.text,
          'cast':
              element.querySelector('.per-info.rtl .pi-detail .pi-cast')?.text,
        },
      });
    });

    document
        .querySelectorAll(
            '$selector .anisc-info-wrap .anisc-info .item:not(.w-hide)')
        .forEach((element) {
      String key = element
              .querySelector('.item-head')
              ?.text
              .toLowerCase()
              .replaceAll(':', '')
              .trim() ??
          '';
      key = key.contains(' ') ? key.replaceAll(' ', '') : key;

      final value = element
          .querySelectorAll('*:not(.item-head)')
          .map((e) => e.text.trim())
          .join(', ');

      if (key == 'genres' || key == 'producers') {
        result[key] = value.split(',').map((e) => e.trim()).toList();
      } else {
        result[key] = value;
      }
    });

    document
        .querySelectorAll('#main-content .os-list a.os-item')
        .forEach((element) {
      result['seasons'].add({
        'id': element.attributes['href']?.substring(1).trim(),
        'name': element.attributes['title']?.trim(),
        'title': element.querySelector('.title')?.text.trim(),
        'poster': element
            .querySelector('.season-poster')
            ?.attributes['style']
            ?.split(' ')
            .last
            .split('(')
            .last
            .split(')')
            .first,
        'isCurrent': element.classes.contains('active'),
      });
    });

    final sidebarBlocks = document.querySelectorAll(
        '#main-sidebar .block_area.block_area_sidebar.block_area-realtime');
    if (sidebarBlocks.length >= 2) {
      result['relatedAnimes'] =
          extractMostPopularAnimes(sidebarBlocks[0], '.anif-block-ul ul li');
      result['mostPopularAnimes'] =
          extractMostPopularAnimes(sidebarBlocks[1], '.anif-block-ul ul li');
    }
    result['recommendedAnimes'] = extractAnimes(document,
        '#main-content .block_area.block_area_category .tab-content .flw-item');
    log(result['malscore'].toString());
    return result;
  } catch (e) {
    throw Exception('Failed to scrape anime info $e');
  }
}

List<Map<String, dynamic>> extractMostPopularAnimes(
    dynamic parentElement, String selector) {
  final animes = <Map<String, dynamic>>[];
  parentElement.querySelectorAll(selector).forEach((element) {
    animes.add({
      'id': element
          .querySelector('.film-detail .dynamic-name')
          ?.attributes['href']
          ?.substring(1)
          .trim(),
      'name': element.querySelector('.film-detail .dynamic-name')?.text.trim(),
      'jname': element
          .querySelector('.film-detail .film-name .dynamic-name')
          ?.attributes['data-jname']
          ?.trim(),
      'poster': element
          .querySelector('.film-poster .film-poster-img')
          ?.attributes['data-src']
          ?.trim(),
      'episodes': {
        'sub': int.tryParse(
            element.querySelector('.fd-infor .tick .tick-sub')?.text.trim() ??
                ''),
        'dub': int.tryParse(
            element.querySelector('.fd-infor .tick .tick-dub')?.text.trim() ??
                ''),
      },
      'type': element
          .querySelector('.fd-infor .tick')
          ?.text
          .trim()
          .replaceAll(RegExp(r'\s+'), ' ')
          .split(' ')
          .last,
    });
  });
  return animes;
}

List<Map<String, dynamic>> extractAnimes(dynamic document, String selector) {
  final animes = <Map<String, dynamic>>[];
  document.querySelectorAll(selector).forEach((element) {
    final animeId = element
        .querySelector('.film-detail .film-name .dynamic-name')
        ?.attributes['href']
        ?.substring(1)
        .split('?ref=search')[0];
    final fdiItems =
        element.querySelectorAll('.film-detail .fd-infor .fdi-item');
    final type = fdiItems.isNotEmpty ? fdiItems[0].text.trim() : null;
    final duration = fdiItems.length > 1 ? fdiItems[1].text.trim() : null;

    animes.add({
      'id': animeId,
      'name': element
          .querySelector('.film-detail .film-name .dynamic-name')
          ?.text
          .trim(),
      'jname': element
          .querySelector('.film-detail .film-name .dynamic-name')
          ?.attributes['data-jname']
          ?.trim(),
      'poster': element
          .querySelector('.film-poster .film-poster-img')
          ?.attributes['data-src']
          ?.trim(),
      'duration': duration,
      'type': type,
      'rating': element.querySelector('.film-poster .tick-rate')?.text.trim(),
      'episodes': {
        'sub': int.tryParse(element
                .querySelector('.film-poster .tick-sub')
                ?.text
                .trim()
                .split(' ')
                .last ??
            ''),
        'dub': int.tryParse(element
                .querySelector('.film-poster .tick-dub')
                ?.text
                .trim()
                .split(' ')
                .last ??
            ''),
      },
    });
  });
  return animes;
}
