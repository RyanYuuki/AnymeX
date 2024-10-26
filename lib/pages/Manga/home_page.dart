import 'dart:developer';

import 'package:aurora/auth/auth_provider.dart';
import 'package:aurora/components/common/IconWithLabel.dart';
import 'package:aurora/components/manga/carousel.dart';
import 'package:aurora/components/manga/reusable_carousel.dart';
import 'package:aurora/components/common/SettingsModal.dart';
import 'package:aurora/components/anime/home/data_table.dart';
import 'package:aurora/utils/scrapers/manga/mangakakalot/scraper_all.dart';
import 'package:aurora/fallbackData/manga_data.dart';
import 'package:aurora/hiveData/themeData/theme_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class MangaHomePage extends StatefulWidget {
  const MangaHomePage({super.key});

  @override
  State<MangaHomePage> createState() => _MangaHomePageState();
}

class _MangaHomePageState extends State<MangaHomePage> {
  int currentTableIndex = 0;
  final PageController _pageController = PageController();
  List<dynamic> mangaList = [];
  List<dynamic> trendingData = [];
  List<dynamic> popularData = [];
  List<dynamic> latestData = [];
  List<dynamic> favouriteData = [];

  @override
  void initState() {
    super.initState();
    _initFallback();
    // fetchData();
  }

  void _initFallback() {
    mangaList = mangaData['mangaList'];
    trendingData = moreMangaData!['mangaList'].sublist(0, 8);
    popularData = moreMangaData!['mangaList'].sublist(8, 16);
    latestData = moreMangaData!['mangaList'].sublist(16, 24);
    favouriteData = carousalMangaData['mangaList'];
  }

  // Future<void> fetchData() async {
  //   try {
  //     final data1 = await scrapHottestManga(1);
  //     final data2 = await scrapHottestManga(1);
  //     final data3 = await scrapHottestManga(1);
  //     setState(() {
  //       mangaList = data1;
  //       trendingData = data1;
  //       popularData = data2;
  //       latestData = data3;
  //       favouriteData = data1;
  //     });
  //   } catch (e) {
  //     log('Error fetching data: $e');
  //   }
  // }

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
    int index = 0;
    log(Theme.of(context).colorScheme.onPrimaryFixedVariant.toString());
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Header(),
                const SizedBox(height: 20),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Trending ',
                        style: TextStyle(
                          fontSize: 22,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      TextSpan(
                        text: 'Manga',
                        style: TextStyle(
                          fontSize: 22,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.normal,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Carousel(animeData: mangaList),
              ],
            ),
          ),
          ReusableCarousel(
            title: "Popular",
            carouselData: trendingData,
            tag: '1',
          ),
          ReusableCarousel(
            title: "Latest",
            carouselData: popularData,
            tag: '2',
          ),
          ReusableCarousel(
            title: "Favorite",
            carouselData: latestData,
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
                  ' Mangas',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
            height: 1150,
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
                ListItem(context,
                    data: moreMangaData['mangaList'].sublist(0, 10), tag: 1, index: index),
                ListItem(context,
                    data: moreMangaData['mangaList'].sublist(10, 20), tag: 2, index: index),
                ListItem(context,
                    data: moreMangaData['mangaList'].sublist(0, 10), tag: 3, index: index),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Container ListItem(BuildContext context,
    {required data, required tag, required index}) {
  return Container(
    padding: const EdgeInsets.all(10),
    child: Column(
        children: data.map<Widget>(
      (anime) {
        if (index == 11) {
          index = 1;
        } else {
          index++;
        }
        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/manga/details', arguments: {
              'id': anime['id'],
              'posterUrl': anime['image'],
              'tag': anime['title'] + tag.toString()
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
                    tag: anime['title'] + tag.toString(),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: CachedNetworkImage(
                        imageUrl: anime['image'],
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
                    Text(anime['title'].length > 17
                        ? anime['title'].substring(0, 17) + '...'
                        : anime['title']),
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
                            icon: Iconsax.book,
                            backgroundColor: const Color(0xFFb0e3af),
                            name: anime['chapter'].toString().length > 11
                                ? anime['chapter'].toString().substring(0, 11)
                                : anime['chapter'].toString()),
                        const SizedBox(width: 2),
                        iconWithName(
                            isVertical: false,
                            backgroundColor: const Color(0xFFb9e7ff),
                            borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(5),
                                bottomRight: Radius.circular(5)),
                            icon: Iconsax.like_tag5,
                            name: anime['view'].toString())
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

class Header extends StatefulWidget {
  const Header({super.key});

  @override
  State<Header> createState() => _HeaderState();
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

class _HeaderState extends State<Header> {
  final TextEditingController _controller = TextEditingController();

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
    final avatarImagePath = anilistProvider.userData?['user']?['avatar']?['large'];
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
            controller: _controller,
            onSubmitted: (value) {
              Navigator.pushNamed(context, '/manga/search',
                  arguments: {'term': value});
            },
            decoration: InputDecoration(
              hintText: 'Search Manga...',
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
