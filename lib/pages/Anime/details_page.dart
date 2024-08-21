// ignore_for_file: prefer_const_constructors, deprecated_member_use, non_constant_identifier_names, must_be_immutable, avoid_print

import 'dart:convert';
import 'dart:ui';
import 'package:aurora/components/reusable_carousel.dart';
import 'package:aurora/components/character_cards.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'package:text_scroll/text_scroll.dart';

class DetailsPage extends StatefulWidget {
  final String id;
  final String? posterUrl;
  final String? tag;
  const DetailsPage({super.key, required this.id, this.posterUrl, this.tag});

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  dynamic data;
  dynamic animeInfo;
  dynamic animeFullInfo;
  bool isLoading = true;
  dynamic charactersData;
  String? description;

  final String baseUrl = 'https://aniwatch-ryan.vercel.app/anime/info?id=';

  @override
  void initState() {
    super.initState();
    FetchAnimeData();
  }

  Future<void> FetchAnimeData() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl${widget.id}'));
      if (response.statusCode == 200) {
        final tempData = jsonDecode(response.body);
        final newResponse = await http.get(Uri.parse(
            'https://consumet-api-two-nu.vercel.app/meta/anilist/info/${tempData['anime']['info']['anilistId']}'));
        if (newResponse.statusCode == 200) {
          final characterTemp = jsonDecode(newResponse.body);
          setState(() {
            description = characterTemp['description'];
            charactersData = characterTemp['characters'];
          });
        }
        setState(() {
          data = tempData;
          animeFullInfo = tempData['anime']['moreInfo'];
          animeInfo = tempData['anime']['info'];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: TextScroll(
          isLoading ? 'Loading...' : animeInfo['name'].toString(),
          mode: TextScrollMode.bouncing,
          velocity: const Velocity(pixelsPerSecond: Offset(30, 0)),
          delayBefore: const Duration(milliseconds: 500),
          pauseBetween: const Duration(milliseconds: 1000),
          textAlign: TextAlign.center,
          selectable: true,
          style: const TextStyle(fontSize: 16),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(IconlyBold.arrow_left),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: isLoading
          ? Column(
              children: [
                Center(
                  child: Poster(tag: widget.tag, poster: widget.posterUrl),
                ),
                const SizedBox(height: 30),
                CircularProgressIndicator(),
              ],
            )
          : Stack(
              children: [
                ListView(
                  children: [
                    Column(
                      children: [
                        Poster(tag: widget.tag, poster: widget.posterUrl),
                        const SizedBox(height: 30),
                        Info(context),
                      ],
                    ),
                  ],
                ),
                if (animeInfo['stats']['episodes']['sub'] != 0 &&
                    animeInfo['stats']['episodes']['sub'] != null)
                  (FloatingBar(
                    title: animeInfo['name'] ?? '??',
                    id: widget.id,
                  ))
              ],
            ),
    );
  }

  Container Info(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    constraints: BoxConstraints(maxWidth: 170),
                    child: TextScroll(
                      animeInfo['name']?.toString() ?? '??',
                      mode: TextScrollMode.endless,
                      velocity: Velocity(pixelsPerSecond: Offset(50, 0)),
                      delayBefore: Duration(milliseconds: 500),
                      pauseBetween: Duration(milliseconds: 1000),
                      textAlign: TextAlign.center,
                      selectable: true,
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    height: 15,
                    width: 3,
                    color: Color(0xFF8192CF),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: Colors.indigo.shade400,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    animeFullInfo['malscore']?.toString() ?? '??',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.primary),
                  ),
                ],
              ),
              const SizedBox(
                height: 15,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: (animeFullInfo['genres'] as List<dynamic>? ?? [])
                    .take(3)
                    .map<Widget>(
                      (genre) => Container(
                        margin: EdgeInsets.only(right: 8),
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.inverseSurface,
                            borderRadius: BorderRadius.circular(12)),
                        child: Text(
                          genre as String,
                          style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color,
                              fontSize: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.fontSize,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 15),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  padding: EdgeInsets.all(7),
                  width: 130,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(5),
                          bottomLeft: Radius.circular(5)),
                      color: Theme.of(context).colorScheme.tertiary),
                  child: Column(
                    children: [
                      Text(
                          animeInfo['stats']['episodes']['sub'] == null
                              ? '?'
                              : (animeInfo['stats']['episodes']['sub']
                                  .toString()),
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Episodes')
                    ],
                  ),
                ),
                Container(
                  color: Theme.of(context).colorScheme.primary,
                  height: 30,
                  width: 2,
                ),
                Container(
                  width: 130,
                  padding: EdgeInsets.all(7),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                          topRight: Radius.circular(5),
                          bottomRight: Radius.circular(5)),
                      color: Theme.of(context).colorScheme.tertiary),
                  child: Column(
                    children: [
                      Text(
                        animeInfo['stats']['duration'] == null
                            ? '??'
                            : (animeInfo['stats']['duration']
                                .toString()
                                .substring(
                                    0,
                                    animeInfo['stats']['duration']
                                            .toString()
                                            .length -
                                        1)),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('Per Ep')
                    ],
                  ),
                ),
              ])
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).colorScheme.tertiary,
            ),
            padding: EdgeInsets.all(10),
            child: Column(
              children: [
                Text(
                  description ??
                      animeInfo['description'] ??
                      'Description Not Found',
                  maxLines: 13,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          CharacterCards(carouselData: charactersData),
          ReusableCarousel(
              title: 'Popular', carouselData: data['mostPopularAnimes']),
          ReusableCarousel(
              title: 'Related', carouselData: data['relatedAnimes']),
          ReusableCarousel(
              title: 'Recommended', carouselData: data['recommendedAnimes']),
        ],
      ),
    );
  }
}

class FloatingBar extends StatelessWidget {
  final String? title;
  final String? id;
  const FloatingBar({super.key, this.title, this.id});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.all(20),
        height: 60,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 10,
              sigmaY: 10,
            ),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              constraints: BoxConstraints(maxWidth: 130),
                              child: TextScroll(
                                title!,
                                mode: TextScrollMode.bouncing,
                                velocity:
                                    Velocity(pixelsPerSecond: Offset(20, 0)),
                                delayBefore: Duration(milliseconds: 500),
                                pauseBetween: Duration(milliseconds: 1000),
                                textAlign: TextAlign.center,
                                selectable: true,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ),
                            const Text(
                              'Episode 1',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 10),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/watch',
                            arguments: {'id': id});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Iconsax.watch,
                            color: Colors.white, // Icon color
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Watch',
                            style: TextStyle(
                              color: Colors.white, // Text color
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Poster extends StatelessWidget {
  const Poster({super.key, required this.tag, required this.poster});
  final String? poster;
  final String? tag;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 30),
            height: 400,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  spreadRadius: 5,
                  blurRadius: 10,
                  offset: Offset(0, 7),
                ),
              ],
            ),
            width: MediaQuery.of(context).size.width - 100,
            child: Hero(
              tag: tag!,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CachedNetworkImage(
                  imageUrl: poster!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
