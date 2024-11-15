import 'package:aurora/auth/auth_provider.dart';
import 'package:aurora/components/common/IconWithLabel.dart';
import 'package:aurora/components/common/settings_modal.dart';
import 'package:aurora/fallbackData/anilist_homepage_data.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../components/anime/home/coverCarousel.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:aurora/components/anime/home/carousel.dart';
import 'package:aurora/components/anime/home/data_table.dart';
import 'package:aurora/components/common/reusable_carousel.dart';
import 'package:aurora/hiveData/themeData/theme_provider.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shimmer/shimmer.dart';

class AnimeHomePage extends StatefulWidget {
  const AnimeHomePage({super.key});

  @override
  State<AnimeHomePage> createState() => _AnimeHomePageState();
}

String getGreetingMessage() {
  DateTime now = DateTime.now();
  int hour = now.hour;

  if (hour >= 5 && hour < 12) {
    return 'Good morning,';
  } else if (hour >= 12 && hour < 17) {
    return 'Good afternoon,';
  } else if (hour >= 17 && hour < 21) {
    return 'Good evening,';
  } else {
    return 'Good night,';
  }
}

class _AnimeHomePageState extends State<AnimeHomePage> {
  bool? usingConsumet =
      Hive.box('app-data').get('using-consumet', defaultValue: false);
  bool isLoading = true;
  int currentTableIndex = 0;
  final TextEditingController _searchTerm = TextEditingController();
  final PageController _pageController = PageController();

  List<dynamic> filterAnimeData(List<dynamic> animeData) {
    final newData =
        animeData.where((anime) => anime['bannerImage'] != null).toList();
    return newData;
  }

  final String proxyUrl = '';

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
      body: Consumer<AniListProvider>(
        builder: (context, aniListProvider, child) {
          final userData = aniListProvider.userData;

          final baseAnimeData =
              userData?['data'] ?? fallbackAnilistData?['data'];
          final spotlightAnimes =
              filterAnimeData(baseAnimeData['trendingAnimes']['media']);
          // final trendingAnimes = baseAnimeData['trendingAnimes']['media'];
          final mostPopularAnimes = baseAnimeData['popularAnimes']['media'];
          // final latestCompletedAnimes = baseAnimeData['popularAnimes']['media'];
          final latestEpisodeAnimes = baseAnimeData['latestAnimes']['media'];
          // final topUpcomingAnimes = baseAnimeData['upcomingAnimes']['media'];
          final top10Animes = {
            'today': baseAnimeData['top10Today']['media'],
            'week': baseAnimeData['top10Week']['media'],
            'month': baseAnimeData['top10Month']['media'],
          };

          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Header(controller: _searchTerm),
                    const SizedBox(height: 20),
                    Covercarousel(
                        title: 'Spotlight', animeData: spotlightAnimes),
                    const SizedBox(height: 20),
                    Carousel(title: 'Trending', animeData: spotlightAnimes),
                  ],
                ),
              ),
              // ReusableCarousel(
              //   title: "Trending",
              //   carouselData: topAiringAnimes,
              //   tag: '01',
              // ),
              ReusableCarousel(
                title: "Popular",
                carouselData: mostPopularAnimes!,
                tag: '0',
              ),
              ReusableCarousel(
                title: "Completed",
                carouselData: top10Animes['week'],
                tag: '1',
              ),
              ReusableCarousel(
                title: "Latest",
                carouselData: latestEpisodeAnimes,
                tag: '2',
              ),
              ReusableCarousel(
                title: "More Popular",
                carouselData: top10Animes['month'],
                tag: '3',
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    Text(
                      'Top',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const Text(
                      ' Animes',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 10),
              AnimeTable(
                  onTap: (value) {
                    _onTableItemTapped(value!);
                  },
                  currentIndex: currentTableIndex),
              Container(
                height: 1120,
                margin: const EdgeInsets.only(top: 10, left: 10, right: 10),
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
                    tableColumn(context, data: top10Animes['today'], tag: 1),
                    tableColumn(context, data: top10Animes['week'], tag: 2),
                    tableColumn(context, data: top10Animes['month'], tag: 3),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Container tableColumn(BuildContext context, {required data, required tag}) {
    int index = 0;
    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
          children: data.map<Widget>(
        (anime) {
          index++;
          String title =
              anime['title']['english'] ?? anime['title']['romaji'] ?? '?';
          return GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/details', arguments: {
                'id': anime['id'],
                'posterUrl': proxyUrl + anime['coverImage']['large'],
                'tag': title + tag.toString()
              });
            },
            child: Container(
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsets.only(top: 20),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: Theme.of(context).colorScheme.surfaceContainerHigh),
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Container(
                    height: 50,
                    width: 45,
                    margin: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                        color:
                            Theme.of(context).colorScheme.onPrimaryFixedVariant,
                        borderRadius: BorderRadius.circular(14)),
                    child: Center(
                        child: Text(
                      index.toString(),
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.inverseSurface ==
                                  Theme.of(context)
                                      .colorScheme
                                      .onPrimaryFixedVariant
                              ? Colors.black
                              : Theme.of(context)
                                          .colorScheme
                                          .onPrimaryFixedVariant ==
                                      const Color(0xffe2e2e2)
                                  ? Colors.black
                                  : Colors.white),
                    )),
                  ),
                  SizedBox(
                    height: 70,
                    width: 50,
                    child: Hero(
                      tag: title + tag.toString(),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: CachedNetworkImage(
                          imageUrl: proxyUrl + anime['coverImage']['large'],
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey[900]!,
                            highlightColor: Colors.grey[700]!,
                            child: Container(
                              color: Colors.grey[600],
                              height: 250,
                              width: double.infinity,
                            ),
                          ),
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
                      Text(title.length > 17
                          ? '${title.substring(0, 17)}...'
                          : title),
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
                              icon: Iconsax.folder5,
                              backgroundColor: const Color(0xFFb0e3af),
                              name: anime?['episodes']?.toString() ?? '?'),
                          const SizedBox(width: 2),
                          iconWithName(
                              isVertical: false,
                              backgroundColor: const Color(0xFFb9e7ff),
                              borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(5),
                                  bottomRight: Radius.circular(5)),
                              icon: Iconsax.star5,
                              name: anime['averageScore'].toString())
                        ],
                      )
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ).toList()),
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
    // var box = Hive.box('login-data');
    // final userInfo =
    //     box.get('userInfo', defaultValue: ['Guest', 'Guest', 'null']);
    // final userName = userInfo?[0] ?? 'Guest';
    // final avatarImagePath = userInfo?[2] ?? 'null';
    // final isLoggedIn = userName != 'Guest';
    // final hasAvatarImage = avatarImagePath != 'null';
    final anilistProvider = Provider.of<AniListProvider>(context);
    final userName = anilistProvider.userData?['user']?['name'] ?? 'Guest';
    final avatarImagePath =
        anilistProvider.userData?['user']?['avatar']?['large'];
    final isLoggedIn = anilistProvider.userData?['user']?['name'] != null;
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
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder: (context) {
                          return const SettingsModal();
                        },
                      );
                    },
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainer,
                      child: isLoggedIn
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: Image.network(
                                  fit: BoxFit.cover, avatarImagePath),
                            )
                          : Icon(
                              Icons.person,
                              color:
                                  Theme.of(context).colorScheme.inverseSurface,
                            ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        getGreetingMessage(),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        userName,
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
                  borderRadius: BorderRadius.circular(50),
                ),
                child: IconButton(
                  icon: Icon(
                      themeProvider.selectedTheme.brightness == Brightness.dark
                          ? Iconsax.moon
                          : Icons.sunny),
                  onPressed: () {
                    themeProvider.toggleTheme();
                  },
                ),
              ),
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
