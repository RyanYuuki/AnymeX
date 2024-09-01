import 'dart:io';
import 'dart:ui';

import 'package:aurora/components/homepage/homepage_carousel.dart';
import 'package:aurora/components/homepage/manga_homepage_carousel.dart';
import 'package:aurora/database/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:iconly/iconly.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    var box = Hive.box('login-data');
    final userInfo =
        box.get('userInfo', defaultValue: ['Guest', 'Guest', 'null']);
    final userName = userInfo?[0] ?? 'Guest';
    final avatarImagePath = userInfo?[2] ?? 'null';
    final isLoggedIn = userName != 'Guest';
    final hasAvatarImage = avatarImagePath != 'null';
    final totalWatchedAnimes =
        Provider.of<AppData>(context).watchedAnimes?.length.toString() ?? '00';
    final totalReadManga =
        Provider.of<AppData>(context).readMangas?.length.toString() ?? '00';
    final hiveBox = Hive.box('app-data');
    final List<dynamic>? watchingAnimeList = hiveBox.get('currently-watching');
    final List<dynamic>? readingMangaList = hiveBox.get('currently-reading');

    return Scaffold(
      body: ListView(children: [
        Stack(children: [
          Positioned(
            height: 200,
            width: MediaQuery.of(context).size.width,
            child: Stack(
              children: [
                if (hasAvatarImage)
                  Positioned.fill(
                    child: Image.file(
                      File(avatarImagePath),
                      fit: BoxFit.cover,
                    ),
                  ),
                if (hasAvatarImage)
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.6)
                            ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter)),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Colors.transparent,
                        Theme.of(context).colorScheme.surface,
                      ], stops: const [
                        1,
                        1,
                        0,
                        0.8
                      ]),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
              top: 30,
              left: 15,
              child: IconButton(
                  style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainer
                          .withOpacity(0.7)),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(IconlyBold.arrow_left))),
          Column(
            children: [
              const SizedBox(height: 70),
              SizedBox(
                height: 200,
                width: 200,
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainer,
                  backgroundImage:
                      hasAvatarImage ? FileImage(File(avatarImagePath)) : null,
                  child: hasAvatarImage
                      ? null
                      : Icon(
                          Icons.person,
                          color: Theme.of(context).colorScheme.inverseSurface,
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isLoggedIn ? userInfo[0] : 'Guest',
                style: TextStyle(
                    fontSize: 24, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 150,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Text(totalWatchedAnimes,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        const Text('Anime')
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 150,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Text(
                          totalReadManga,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        const Text('Manga')
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Stats',
                      style: TextStyle(fontSize: 24),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      margin: const EdgeInsets.all(5),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7),
                        color: Theme.of(context).colorScheme.surfaceContainer
                      ),
                      child: const Column(
                        children: [
                          StatsRow(
                            name: 'Episodes Watched',
                            value: '10',
                          ),
                          StatsRow(
                            name: 'Days Watched',
                            value: '1',
                          ),
                          StatsRow(
                            name: 'Anime Mean Score',
                            value: '12.02',
                          ),
                          StatsRow(
                            name: 'Chapters Read',
                            value: '400',
                          ),
                          StatsRow(
                            name: 'Volume Read',
                            value: '30',
                          ),
                          StatsRow(
                            name: 'Manga Mean Score',
                            value: '60',
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
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
                  ],
                ),
              )
            ],
          ),
        ]),
      ]),
    );
  }
}

class StatsRow extends StatelessWidget {
  final String name;
  final String value;
  const StatsRow({
    super.key,
    required this.name,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: TextStyle(
            color: Theme.of(context).colorScheme.inverseSurface.withOpacity(0.7)
          ),),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          )
        ],
      ),
    );
  }
}
