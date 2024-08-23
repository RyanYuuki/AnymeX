import 'dart:developer';

import 'package:aurora/components/MangaExclusive/carousel.dart';
import 'package:aurora/components/MangaExclusive/manga_list.dart';
import 'package:aurora/components/MangaExclusive/reusable_carousel.dart';
import 'package:aurora/fallbackData/manga_data.dart';
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
            ReusableCarousel(title: "Popular", carouselData: CarouselData_1),
            ReusableCarousel(title: "Latest", carouselData: CarouselData_2),
            ReusableCarousel(title: "Favorite", carouselData: CarouselData_3),
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

class _HeaderState extends State<Header> {
  final TextEditingController _controller = TextEditingController();

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
                      : const CircleAvatar(
                          radius: 24,
                          child: Icon(Icons.person),
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
                        userInfo[0],
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
                  border: Border.all(
                    width: 1,
                    style: BorderStyle.solid,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: IconButton(
                  icon: Icon(
                    themeProvider.selectedTheme.brightness == Brightness.dark
                        ? Iconsax.moon
                        : Iconsax.sun,
                  ),
                  onPressed: () {
                    themeProvider.toggleTheme();
                  },
                  color: Theme.of(context).iconTheme.color,
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
              prefixIcon: const Icon(Iconsax.search_normal),
              suffixIcon: const Icon(IconlyBold.filter),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.secondary,
                  width: 1,
                ),
              ),
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
