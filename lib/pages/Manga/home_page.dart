import 'package:aurora/components/MangaExclusive/carousel.dart';
import 'package:aurora/components/MangaExclusive/reusable_carousel.dart';
import 'package:aurora/fallbackData/manga_data.dart';
import 'package:aurora/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

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

  @override
  void initState() {
    super.initState();
    InitFallbackData();
    fetchData();
  }

  void InitFallbackData() {
    mangaList = mangaData['mangaList'];
    CarouselData_1 = mangaList!.sublist(0, 8);
    CarouselData_2 = mangaList!.sublist(8, 16);
    CarouselData_3 = mangaList!.sublist(16, 24);
  }

  Future<void> fetchData() async {
    const String apiUrl =
        'https://anymey-proxy.vercel.app/cors?url=https://manga-ryan.vercel.app/api/mangalist';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          mangaList = data['mangaList'];
          if (mangaList != null && mangaList!.length == 24) {
            CarouselData_1 = mangaList!.sublist(0, 8);
            CarouselData_2 = mangaList!.sublist(8, 16);
            CarouselData_3 = mangaList!.sublist(16, 24);
          } else {
            throw Exception('Data length is not 24');
          }
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error fetching data: $e');
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: AssetImage('assets/images/avatar.png'),
                  ),
                  SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good Afternoon',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Ryan Yuuki',
                        style: TextStyle(
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
                        color: Theme.of(context).colorScheme.tertiary),
                    borderRadius: BorderRadius.circular(50)),
                child: IconButton(
                  icon: Icon(
                      themeProvider.selectedTheme.brightness == Brightness.dark
                          ? Iconsax.moon
                          : Iconsax.sun),
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
