import 'dart:io';

import 'package:aurora/components/reusable_carousel.dart';
import 'package:aurora/components/MangaExclusive/reusable_carousel.dart'
    as ReusableCarouselManga;
import 'package:aurora/fallbackData/anime_data.dart';
import 'package:aurora/fallbackData/manga_data.dart';
import 'package:aurora/pages/Anime/search_page.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
    final userInfo =
        box.get('userInfo', defaultValue: ['Guest', 'Guest', 'null']);
    final avatarImagePath = userInfo?[2] ?? 'null';
    return Scaffold(
      body: ListView(
        children: [
          Column(
            children: [
              Container(
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
                          avatarImagePath != "null"
                              ? CircleAvatar(
                                  radius: 24,
                                  backgroundImage:
                                      FileImage(File(avatarImagePath)),
                                )
                              : const CircleAvatar(
                                  backgroundColor: Colors.black,
                                  radius: 24,
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.white,
                                  ),
                                ),
                          IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SearchPage(
                                      searchTerm: 'Attack on Titan',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Iconsax.search_normal,
                                size: 24,
                              ))
                        ],
                      ),
                    ),
                    const SizedBox(height: 70),
                    const Text(
                      'What are you looking for?',
                      style:
                          TextStyle(fontSize: 40, fontFamily: 'Poppins-Bold'),
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
                    ),
                    ReusableCarouselManga.ReusableCarousel(
                      title: 'Top',
                      carouselData: moreMangaData['mangaList'],
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
