import 'dart:io';
import 'package:aurora/components/SettingsModal.dart';
import 'package:aurora/components/reusable_carousel.dart';
import 'package:aurora/components/MangaExclusive/reusable_carousel.dart'
    as ReusableCarouselManga;
import 'package:aurora/fallbackData/anime_data.dart';
import 'package:aurora/fallbackData/manga_data.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:iconsax/iconsax.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    var box = Hive.box('login-data');
    final userInfo = box.get('userInfo', defaultValue: ['Guest', 'Guest', 'null']);
    final userName = userInfo?[0] ?? 'Guest';
    final avatarImagePath = userInfo?[2] ?? 'null';
    final isLoggedIn = userName != 'Guest';
    final hasAvatarImage = avatarImagePath != 'null';

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: ListView(
        children: [
          Column(
            children: [
              SizedBox(
                height: 400,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            width: 70,
                            height: 50,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: Image.asset(
                                'assets/images/logo_transparent.png',
                                fit: BoxFit.cover,
                                alignment: Alignment.center,
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
                                    Navigator.pushNamed(context, '/login-page');
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
                                  : const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 70),
                    const Text(
                      'What are you looking for?',
                      style: TextStyle(fontSize: 40, fontFamily: 'Poppins-Bold'),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    ReusableCarousel(
                      title: 'Top Airing',
                      carouselData: animeData['topAiringAnimes'],
                      tag: 'home-page',
                    ),
                    ReusableCarouselManga.ReusableCarousel(
                      title: 'Top',
                      carouselData: moreMangaData['mangaList'],
                      tag: 'home-page',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
