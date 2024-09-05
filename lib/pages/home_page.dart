import 'dart:io';
import 'package:aurora/components/SettingsModal.dart';
import 'package:aurora/components/homepage/homepage_carousel.dart';
import 'package:aurora/components/reusable_carousel.dart';
import 'package:aurora/components/MangaExclusive/reusable_carousel.dart'
    as MangaCarousel;
import 'package:aurora/components/homepage/manga_homepage_carousel.dart';
import 'package:aurora/fallbackData/anime_data.dart';
import 'package:aurora/fallbackData/manga_data.dart';
import 'package:aurora/pages/onboarding_screens/avatar_page.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box('login-data').listenable(),
      builder: (context, Box box, _) {
        final hiveBox = Hive.box('app-data');
        final List<dynamic>? watchingAnimeList =
            hiveBox.get('currently-watching');
        final List<dynamic>? readingMangaList =
            hiveBox.get('currently-reading');
        final userInfo =
            box.get('userInfo', defaultValue: ['Guest', 'Guest', 'null']);
        final userName = userInfo?[0] ?? 'Guest';
        final avatarImagePath = userInfo?[2] ?? 'null';
        final isLoggedIn = userName != 'Guest';
        final hasAvatarImage = avatarImagePath != 'null';

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: Padding(
            padding: const EdgeInsets.only(top: 20.0, left: 20, right: 20),
            child: ListView(
              children: [
                Column(
                  children: [
                    SizedBox(
                      height: 350,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(
                                width: 50,
                                height: 70,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(30),
                                  child: Image.asset(
                                    'assets/images/logo_transparent.png',
                                    fit: BoxFit.cover,
                                    alignment: Alignment.center,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .inverseSurface,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: isLoggedIn
                                    ? () {
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
                                      }
                                    : () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const AvatarPage()));
                                      },
                                child: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainer,
                                  backgroundImage: hasAvatarImage
                                      ? FileImage(File(avatarImagePath))
                                      : null,
                                  child: hasAvatarImage
                                      ? null
                                      : Icon(
                                          Icons.person,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .inverseSurface,
                                        ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 60),
                          Text(
                            'Hey ${isLoggedIn ? userName : 'Guest'}, What are we doing today?',
                            style: const TextStyle(
                                fontSize: 30, fontFamily: 'Poppins-Bold'),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'Find your favorite anime or manga, manhwa or whatever you like!',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .inverseSurface
                                    .withOpacity(0.8),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        HomepageCarousel(
                          title: 'Currently Watching',
                          carouselData: watchingAnimeList,
                          tag: 'home-page',
                        ),
                        MangaHomepageCarousel(
                          title: 'Currently Reading',
                          carouselData: readingMangaList,
                          tag: 'home-page',
                        ),
                        ReusableCarousel(
                          title: 'Recommended',
                          carouselData: animeData['topAiringAnimes'],
                          tag: 'home-page-recommended',
                          secondary: true,
                        ),
                        MangaCarousel.ReusableCarousel(
                          title: 'Recommended',
                          carouselData: mangaData['mangaList'],
                          tag: 'home-page-recommended',
                          secondary: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
