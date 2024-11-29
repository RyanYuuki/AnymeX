// ignore_for_file: prefer_const_constructors

import 'dart:math';

import 'package:anymex/pages/Android/Anime/details_page.dart';
import 'package:anymex/pages/Android/Manga/details_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shimmer/shimmer.dart';

class Carousel extends StatelessWidget {
  final List<dynamic>? animeData;
  final String? title;
  final String? span;
  final bool isManga;
  const Carousel(
      {super.key,
      this.animeData,
      this.title,
      this.span = 'Animes',
      this.isManga = false});

  @override
  Widget build(BuildContext context) {
    final ColorScheme = Theme.of(context).colorScheme;
    if (animeData == null) {
      return Center(
          heightFactor: 300, child: const CircularProgressIndicator());
    }

    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$title ',
                  style: TextStyle(
                    fontSize: 22,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                TextSpan(
                  text: span,
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
        ),
        const SizedBox(height: 15),
        CarouselSlider(
          options: CarouselOptions(
            height: 440,
            viewportFraction: 0.7,
            initialPage: 0,
            enableInfiniteScroll: true,
            reverse: false,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 10),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.fastOutSlowIn,
            enlargeCenterPage: true,
            enlargeFactor: 0.2,
            scrollDirection: Axis.horizontal,
          ),
          items: animeData!.map((anime) {
            final String posterUrl = anime['coverImage']['large'] ?? '??';
            String rating = anime?['averageScore'] != null
                ? (anime['averageScore'] / 10).toStringAsFixed(1)
                : '0.0';
            final tag = '${anime["id"]}${Random().nextInt(100000)}';
            final String title =
                anime['title']['english'] ?? anime['title']['romaji'] ?? '?';

            return Builder(
              builder: (BuildContext context) {
                return Stack(
                  children: [
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (isManga) {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => MangaDetailsPage(
                                            id: anime['id'],
                                            posterUrl: posterUrl,
                                            tag: tag,
                                          )));
                            } else {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => DetailsPage(
                                            id: anime['id'],
                                            posterUrl: posterUrl,
                                            tag: tag,
                                          )));
                            }
                          },
                          child: Container(
                            height: 300,
                            width: 270,
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            child: Hero(
                              tag: tag,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: posterUrl,
                                  placeholder: (context, url) =>
                                      Shimmer.fromColors(
                                    baseColor: Colors.grey[900]!,
                                    highlightColor: Colors.grey[700]!,
                                    child: Container(
                                      color: Colors.grey[400],
                                      height: 250,
                                      width: double.infinity,
                                    ),
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          height: 70,
                          margin: EdgeInsets.symmetric(horizontal: 7),
                          padding: EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: ColorScheme.surfaceContainer,
                          ),
                          child: Center(
                            child: Text(
                              title,
                              maxLines: 2,
                              style: TextStyle(
                                  fontSize: 16, fontFamily: 'Poppins-SemiBold'),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      ],
                    ),
                    Positioned(
                      top: 8,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: ColorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Iconsax.star5,
                                color: Theme.of(context).colorScheme.primary,
                                size: 18),
                            const SizedBox(width: 2),
                            Text(
                              rating,
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .inverseSurface,
                                  fontSize: 14,
                                  fontFamily: 'Poppins-SemiBold'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
