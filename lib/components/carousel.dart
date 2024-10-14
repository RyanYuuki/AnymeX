// ignore_for_file: prefer_const_constructors

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shimmer/shimmer.dart';

class Carousel extends StatelessWidget {
  final List<dynamic>? animeData;
  final String? title;
  const Carousel({super.key, this.animeData, this.title});

  @override
  Widget build(BuildContext context) {
    final ColorScheme = Theme.of(context).colorScheme;
    if (animeData == null) {
      return Center(
          heightFactor: 300,
          child: const CupertinoActivityIndicator(
            radius: 50,
          ));
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
                  text: 'Animes',
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
            final String posterUrl = anime['poster'] ?? '??';
            final String? type = anime['type'] ?? 'TV';
            final tag = anime['name'] + anime['jname'] + anime['id'];
            const String proxyUrl =
                'https://goodproxy.goodproxy.workers.dev/fetch?url=';

            return Builder(
              builder: (BuildContext context) {
                return Stack(
                  children: [
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/details',
                              arguments: {
                                'id': anime['id'],
                                'posterUrl': proxyUrl + posterUrl,
                                "tag": tag
                              },
                            );
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
                                  imageUrl: proxyUrl + posterUrl,
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
                          padding: EdgeInsets.symmetric(vertical: 7),
                          margin: EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: ColorScheme.surfaceContainer,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text(
                                anime['name'].length > 20
                                    ? '${anime['name'].toString().substring(0, 20)}...'
                                    : anime['name'] ?? '??',
                                style: TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Container(
                                    height: 35,
                                    width: 80,
                                    decoration: BoxDecoration(
                                        color:
                                            ColorScheme.onPrimaryFixedVariant,
                                        borderRadius: BorderRadius.circular(7)),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.closed_caption,
                                          color: Theme.of(context)
                                                      .colorScheme
                                                      .inverseSurface ==
                                                  Theme.of(context)
                                                      .colorScheme
                                                      .onPrimaryFixedVariant
                                              ? Colors.black
                                              : Theme.of(context)
                                                          .colorScheme
                                                          .onPrimaryFixedVariant ==
                                                      Color(0xffe2e2e2)
                                                  ? Colors.black
                                                  : Colors.white,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                            anime['episodes']['sub'].toString(),
                                            style: TextStyle(
                                                color: Theme.of(context)
                                                            .colorScheme
                                                            .inverseSurface ==
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .onPrimaryFixedVariant
                                                    ? Colors.black
                                                    : Theme.of(context)
                                                                .colorScheme
                                                                .onPrimaryFixedVariant ==
                                                            Color(0xffe2e2e2)
                                                        ? Colors.black
                                                        : Colors.white)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    height: 35,
                                    width: 80,
                                    decoration: BoxDecoration(
                                        color:
                                            ColorScheme.onPrimaryFixedVariant,
                                        borderRadius: BorderRadius.circular(7)),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.mic,
                                          color: Theme.of(context)
                                                      .colorScheme
                                                      .inverseSurface ==
                                                  Theme.of(context)
                                                      .colorScheme
                                                      .onPrimaryFixedVariant
                                              ? Colors.black
                                              : Theme.of(context)
                                                          .colorScheme
                                                          .onPrimaryFixedVariant ==
                                                      Color(0xffe2e2e2)
                                                  ? Colors.black
                                                  : Colors.white,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                            anime['episodes']['dub'].toString(),
                                            style: TextStyle(
                                                color: Theme.of(context)
                                                            .colorScheme
                                                            .inverseSurface ==
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .onPrimaryFixedVariant
                                                    ? Colors.black
                                                    : Theme.of(context)
                                                                .colorScheme
                                                                .onPrimaryFixedVariant ==
                                                            Color(0xffe2e2e2)
                                                        ? Colors.black
                                                        : Colors.white)),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            ],
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
                          color: ColorScheme.onPrimaryFixedVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Iconsax.play_circle5,
                                color: Theme.of(context)
                                            .colorScheme
                                            .inverseSurface ==
                                        Theme.of(context)
                                            .colorScheme
                                            .onPrimaryFixedVariant
                                    ? Colors.black
                                    : Theme.of(context)
                                                .colorScheme
                                                .onPrimaryFixedVariant ==
                                            Color(0xffe2e2e2)
                                        ? Colors.black
                                        : Colors.white),
                            const SizedBox(width: 2),
                            Text(
                              type ?? 'TV',
                              style: TextStyle(
                                  color: Theme.of(context)
                                              .colorScheme
                                              .inverseSurface ==
                                          Theme.of(context)
                                              .colorScheme
                                              .onPrimaryFixedVariant
                                      ? Colors.black
                                      : Theme.of(context)
                                                  .colorScheme
                                                  .onPrimaryFixedVariant ==
                                              Color(0xffe2e2e2)
                                          ? Colors.black
                                          : Colors.white,
                                  fontSize: 14),
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
