import 'dart:developer';

import 'package:anymex/auth/auth_provider.dart';
import 'package:anymex/components/android/novel/cover_carousel.dart';
import 'package:anymex/components/android/common/settings_modal.dart';
import 'package:anymex/components/android/novel/carousel.dart';
import 'package:anymex/components/android/novel/reusable_carousel.dart';
import 'package:anymex/components/desktop/novel/cover_carousel.dart';
import 'package:anymex/components/desktop/novel/horizontal_list.dart';
import 'package:anymex/components/platform_builder.dart';
import 'package:anymex/fallbackData/novel_cover_carousel.dart';
import 'package:anymex/fallbackData/novel_homepage.dart';
import 'package:anymex/hiveData/themeData/theme_provider.dart';
import 'package:anymex/pages/Android/Anime/home_page.dart' hide Header;
import 'package:anymex/pages/Android/Novel/search_page.dart';
import 'package:anymex/utils/sources/novel/extensions/novel_buddy.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class NovelHomePage extends StatefulWidget {
  const NovelHomePage({super.key});

  @override
  State<NovelHomePage> createState() => _NovelHomePageState();
}

class _NovelHomePageState extends State<NovelHomePage> {
  late Future<dynamic> novelData;
  final TextEditingController _searchTerm = TextEditingController();

  @override
  void initState() {
    super.initState();
    novelData = Future.value(novelFallbackData);
    fetchNovelData();
  }

  Future<dynamic> fetchNovelData() async {
    try {
      final tempData = await NovelBuddy().scrapeNovelsHomePage();
      setState(() {
        novelData = Future.value(tempData);
      });
    } catch (error) {
      log('Failed to fetch novel data: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: novelData,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    Header(controller: _searchTerm),
                    PlatformBuilder(
                      androidBuilder: Covercarousel(
                        animeData: snapshot.data!.sublist(0,10),
                      ),
                      desktopBuilder: DesktopCoverCarousel(
                        animeData: snapshot.data!.sublist(0,10),
                      ),
                    ),
                    const SizedBox(height: 10),
                    PlatformBuilder(
                        androidBuilder: Carousel(
                          title: 'Trending',
                          animeData: snapshot.data!.sublist(0, 10),
                          span: 'Novels',
                        ),
                        desktopBuilder: const SizedBox.shrink()),
                  ],
                ),
              ),
              PlatformBuilder(
                  androidBuilder: ReusableCarousel(
                    title: "Popular",
                    carouselData: snapshot.data!.sublist(10, 20),
                  ),
                  desktopBuilder: HorizontalList(
                    title: "Popular",
                    carouselData: snapshot.data!.sublist(10, 20),
                  )),
              PlatformBuilder(
                  androidBuilder: ReusableCarousel(
                    title: "Favorite",
                    carouselData: snapshot.data!.sublist(30, 40),
                  ),
                  desktopBuilder: HorizontalList(
                    title: "Favorite",
                    carouselData: snapshot.data!.sublist(30, 40),
                  )),
              PlatformBuilder(
                  androidBuilder: ReusableCarousel(
                    title: "Latest",
                    carouselData: snapshot.data!.sublist(20, 30),
                  ),
                  desktopBuilder: HorizontalList(
                    title: "Latest",
                    carouselData: snapshot.data!.sublist(20, 30),
                  )),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
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
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => SearchPage(searchTerm: searchTerm)))
            },
            decoration: InputDecoration(
              hintText: 'Search Novel...',
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
