import 'dart:io';
import 'package:aurora/components/IconWithLabel.dart';
import 'package:aurora/components/coverCarousel.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:aurora/components/carousel.dart';
import 'package:aurora/components/data_table.dart';
import 'package:aurora/components/reusable_carousel.dart';
import 'package:aurora/theme/theme_provider.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../fallbackData/anime_data.dart';

class AnimeHomePage extends StatefulWidget {
  const AnimeHomePage({super.key});

  @override
  State<AnimeHomePage> createState() => _AnimeHomePageState();
}

class _AnimeHomePageState extends State<AnimeHomePage> {
  List<dynamic>? spotlightAnimes;
  List<dynamic>? trendingAnimes;
  List<dynamic>? latestEpisodeAnimes;
  List<dynamic>? topUpcomingAnimes;
  Map<String, dynamic>? top10Animes;
  List<dynamic>? topAiringAnimes;
  List<dynamic>? mostPopularAnimes;
  List<dynamic>? mostFavoriteAnimes;
  List<dynamic>? latestCompletedAnimes;
  List<dynamic>? genres;
  int currentTableIndex = 0;
  final TextEditingController _searchTerm = TextEditingController();
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    InitFallbackData();
    fetchData();
  }

  void InitFallbackData() {
    spotlightAnimes = animeData['spotlightAnimes'];
    trendingAnimes = animeData['trendingAnimes'];
    latestEpisodeAnimes = animeData['latestEpisodeAnimes'];
    topUpcomingAnimes = animeData['topUpcomingAnimes'];
    top10Animes = animeData['top10Animes'];
    topAiringAnimes = animeData['topAiringAnimes'];
    mostPopularAnimes = animeData['mostPopularAnimes'];
    mostFavoriteAnimes = animeData['mostFavoriteAnimes'];
    latestCompletedAnimes = animeData['latestCompletedAnimes'];
    genres = animeData['genres'];
  }

  final String proxyUrl = 'https://goodproxy.goodproxy.workers.dev/fetch?url=';

  Future<void> fetchData() async {
    const String apiUrl = 'https://aniwatch-ryan.vercel.app/anime/home';
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          spotlightAnimes = data['spotlightAnimes'];
          trendingAnimes = data['trendingAnimes'];
          latestEpisodeAnimes = data['latestEpisodeAnimes'];
          topUpcomingAnimes = data['topUpcomingAnimes'];
          top10Animes = data['top10Animes'];
          topAiringAnimes = data['topAiringAnimes'];
          mostPopularAnimes = data['mostPopularAnimes'];
          mostFavoriteAnimes = data['mostFavoriteAnimes'];
          latestCompletedAnimes = data['latestCompletedAnimes'];
          genres = data['genres'];
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  void _onTableItemTapped(int index) {
    setState(() {
      currentTableIndex = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ListView(
          children: [
            Header(controller: _searchTerm),
            const SizedBox(height: 20),
            CoverCarousel(title: 'Spotlight', animeData: spotlightAnimes),
            const SizedBox(height: 20),
            Carousel(title: 'Trending', animeData: topAiringAnimes),
            ReusableCarousel(
              title: "Popular",
              carouselData: [...mostPopularAnimes!, ...mostFavoriteAnimes!],
              tag: '0',
            ),
            ReusableCarousel(
              title: "Completed",
              carouselData: latestCompletedAnimes,
              tag: '1',
            ),
            ReusableCarousel(
              title: "Latest",
              carouselData: latestEpisodeAnimes,
              tag: '2',
            ),
            ReusableCarousel(
              title: "Upcoming",
              carouselData: topUpcomingAnimes,
              tag: '3',
            ),
            Row(
              children: [
                Text(
                  'Top',
                  style: TextStyle(
                    fontSize: 22,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const Text(
                  ' Animes',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
                )
              ],
            ),
            const SizedBox(height: 20),
            AnimeTable(
                onTap: (value) {
                  _onTableItemTapped(value!);
                },
                currentIndex: currentTableIndex),
            Container(
              height: 1120,
              margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).colorScheme.surfaceContainer),
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    currentTableIndex = index;
                  });
                },
                children: [
                  ListItem(context,
                      data: animeData['top10Animes']['today'], tag: 1),
                  ListItem(context,
                      data: animeData['top10Animes']['week'], tag: 2),
                  ListItem(context,
                      data: animeData['top10Animes']['month'], tag: 3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Container ListItem(BuildContext context, {required data, required tag}) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
          children: data
              .map<Widget>(
                (anime) => GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/details', arguments: {
                      'id': anime['id'],
                      'posterUrl': proxyUrl + anime['poster'],
                      'tag': anime['name'] + tag.toString()
                    });
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    margin: const EdgeInsets.only(top: 20),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color:
                            Theme.of(context).colorScheme.surfaceContainerHigh),
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Container(
                          height: 50,
                          width: 45,
                          margin: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryFixedVariant,
                              borderRadius: BorderRadius.circular(14)),
                          child: Center(
                              child: Text(
                            anime['rank'].toString(),
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          )),
                        ),
                        SizedBox(
                          height: 70,
                          width: 50,
                          child: Hero(
                            tag: anime['name'] + tag.toString(),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: CachedNetworkImage(
                                imageUrl: proxyUrl + anime['poster'],
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(anime['name'].length > 17
                                ? anime['name'].substring(0, 17) + '...'
                                : anime['name']),
                            const SizedBox(
                              height: 5,
                            ),
                            Row(
                              children: [
                                iconWithName(
                                    isVertical: false,
                                    borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(5),
                                        bottomLeft: Radius.circular(5)),
                                    icon: Icons.closed_caption,
                                    backgroundColor: const Color(0xFFb0e3af),
                                    name: anime['episodes']['sub'].toString()),
                                const SizedBox(width: 2),
                                iconWithName(
                                    isVertical: false,
                                    backgroundColor: const Color(0xFFb9e7ff),
                                    borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(5),
                                        bottomRight: Radius.circular(5)),
                                    icon: Icons.mic,
                                    name: anime['episodes']['dub'].toString())
                              ],
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              )
              .toList()),
    );
  }
}

class Header extends StatefulWidget {
  final TextEditingController controller;
  const Header({super.key, required this.controller});

  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  @override
  Widget build(BuildContext context) {
    var box = Hive.box('login-data');
    final userInfo =
        box.get('userInfo', defaultValue: ['Guest', 'Guest', 'null']);
    final avatarImagePath = userInfo?[2] ?? 'null';
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  avatarImagePath != "null"
                      ? CircleAvatar(
                          radius: 24,
                          backgroundImage: FileImage(File(avatarImagePath)),
                        )
                      : CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.surfaceContainer,
                          radius: 24,
                          child: const Icon(
                            Icons.person,
                          ),
                        ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Good Afternoon,',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        userInfo[0].trim(),
                        style: const TextStyle(
                          fontFamily: 'Poppins-Bold',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(50)),
                child: IconButton(
                  icon: Icon(
                      themeProvider.selectedTheme.brightness == Brightness.dark
                          ? Iconsax.moon
                          : Icons.sunny),
                  onPressed: () {
                    themeProvider.toggleTheme();
                  },
                ),
              )
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: widget.controller,
            onSubmitted: (searchTerm) => {
              Navigator.pushNamed(context, '/anime/search', arguments: {
                "term": searchTerm,
              })
            },
            decoration: InputDecoration(
              hintText: 'Search Anime...',
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainer,
              prefixIcon: const Icon(Iconsax.search_normal),
              suffixIcon: const Icon(IconlyBold.filter),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
