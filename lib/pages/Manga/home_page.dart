import 'dart:developer';

import 'package:aurora/auth/auth_provider.dart';
import 'package:aurora/components/MangaExclusive/carousel.dart';
import 'package:aurora/components/MangaExclusive/manga_list.dart';
import 'package:aurora/components/MangaExclusive/reusable_carousel.dart';
import 'package:aurora/components/SettingsModal.dart';
import 'package:aurora/fallbackData/manga_data.dart';
import 'package:aurora/pages/onboarding_screens/avatar_page.dart';
import 'package:aurora/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:io';

class MangaHomePage extends StatefulWidget {
  const MangaHomePage({super.key});

  @override
  State<MangaHomePage> createState() => _MangaHomePageState();
}

class _MangaHomePageState extends State<MangaHomePage> {
  List<dynamic>? mangaList;
  List<dynamic>? CarouselData_1;
  List<dynamic>? CarouselData_2;
  List<dynamic>? CarouselData_3;
  List<dynamic>? MangaListData;

  @override
  void initState() {
    super.initState();
    InitFallbackData();
    fetchData();
  }

  void InitFallbackData() {
    mangaList = mangaData['mangaList'];
    CarouselData_1 = moreMangaData!['mangaList'].sublist(0, 8);
    CarouselData_2 = moreMangaData!['mangaList'].sublist(8, 16);
    CarouselData_3 = moreMangaData!['mangaList'].sublist(16, 24);
    MangaListData = carousalMangaData['mangaList'];
  }

  Future<void> fetchData() async {
    const String apiUrl =
        'https://anymey-proxy.vercel.app/cors?url=https://manga-ryan.vercel.app/api/mangalist';

    try {
      final response1 = await http.get(Uri.parse(apiUrl));
      final response2 = await http.get(Uri.parse('$apiUrl?page=2'));
      final response3 = await http.get(Uri.parse('$apiUrl?page=3'));

      if (response1.statusCode == 200 &&
          response2.statusCode == 200 &&
          response3.statusCode == 200) {
        final data1 = json.decode(response1.body);
        final data2 = json.decode(response2.body);
        final data3 = json.decode(response3.body);
        setState(() {
          mangaList = data1['mangaList'];
          CarouselData_1 = data2!.sublist(0, 8);
          CarouselData_2 = data2!.sublist(8, 16);
          CarouselData_3 = data2!.sublist(16, 24);
          MangaListData = data3;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      log('Error fetching data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    log(Theme.of(context).colorScheme.onPrimaryFixedVariant.toString());
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ListView(
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
            ReusableCarousel(
              title: "Popular",
              carouselData: CarouselData_1,
              tag: '1',
            ),
            ReusableCarousel(
              title: "Latest",
              carouselData: CarouselData_2,
              tag: '2',
            ),
            ReusableCarousel(
              title: "Favorite",
              carouselData: CarouselData_3,
              tag: '3',
            ),
            MangaList(data: [
              ...MangaListData!,
            ]),
          ],
        ),
      ),
    );
  }
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
    final userName = anilistProvider.userData['name'] ?? 'Guest';
    final avatarImagePath = anilistProvider.userData?['avatar']?['large'];
    final isLoggedIn = anilistProvider.userData.isNotEmpty;
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
                                    builder: (context) => const AvatarPage()));
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
