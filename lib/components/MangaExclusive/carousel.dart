// ignore_for_file: prefer_const_constructors

import 'package:aurora/components/IconWithLabel.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shimmer/shimmer.dart';
import 'package:text_scroll/text_scroll.dart';

class Carousel extends StatelessWidget {
  final List<dynamic>? animeData;

  const Carousel({super.key, this.animeData});

  @override
  Widget build(BuildContext context) {
    if (animeData == null) {
      return Center(
          heightFactor: 300,
          child: const CupertinoActivityIndicator(
            radius: 50,
          ));
    }

    return CarouselSlider(
      options: CarouselOptions(
        height: 440,
        viewportFraction: 0.7,
        initialPage: 0,
        enableInfiniteScroll: true,
        reverse: false,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 3),
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
        autoPlayCurve: Curves.fastOutSlowIn,
        enlargeCenterPage: true,
        enlargeFactor: 0.2,
        scrollDirection: Axis.horizontal,
      ),
      items: animeData!.map((anime) {
        final String posterUrl = anime['image'] ?? '??';
        String type = anime['view'] ?? '??';
        final tag = anime['title'] + anime['id'];
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
                          '/manga/details',
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
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Hero(
                          tag: tag,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: proxyUrl + posterUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(
                                  color: Colors.grey[300],
                                  height: 250,
                                  width: double.infinity,
                                ),
                              ),
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
                        color: Theme.of(context).colorScheme.surfaceContainer,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text(
                            anime['title'].length > 20
                                ? '${anime['title'].toString().substring(0, 20)}...'
                                : anime['title'] ?? '??',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Container(
                                height: 35,
                                width: 150,
                                decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryFixedVariant,
                                    borderRadius: BorderRadius.circular(7)),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(Iconsax.book,
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
                                    const SizedBox(width: 5),
                                    SizedBox(
                                      child: Text(
                                        anime['chapter'].toString().length > 11
                                            ? anime['chapter']
                                                .toString()
                                                .substring(0, 11)
                                            : anime['chapter'],
                                        style: TextStyle(
                                            fontSize: 16,
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
                                      ),
                                    ),
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
                    child: iconWithName(
                      icon: Iconsax.heart5,
                      name: type,
                      isVertical: false,
                      backgroundColor:
                          Theme.of(context).colorScheme.onPrimaryFixedVariant,
                      TextColor: Theme.of(context).colorScheme.inverseSurface ==
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
                      color: Theme.of(context).colorScheme.inverseSurface ==
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
                      borderRadius: BorderRadius.circular(5),
                    )),
              ],
            );
          },
        );
      }).toList(),
    );
  }
}
