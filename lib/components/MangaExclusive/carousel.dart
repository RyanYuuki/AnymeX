// ignore_for_file: prefer_const_constructors

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
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
        const String type = 'MANGA';
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
                        color: Theme.of(context).colorScheme.secondary,
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
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(7)),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(Iconsax.book, color: Colors.white),
                                    const SizedBox(width: 5),
                                    SizedBox(
                                      child: TextScroll(
                                        anime['chapter'].substring(0, 10) +
                                            '..',
                                        mode: TextScrollMode.bouncing,
                                        velocity: const Velocity(
                                            pixelsPerSecond: Offset(10, 0)),
                                        delayBefore:
                                            const Duration(milliseconds: 500),
                                        pauseBetween:
                                            const Duration(milliseconds: 1000),
                                        selectable: true,
                                        style: const TextStyle(
                                            fontSize: 16, color: Colors.white),
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
                  right: 25,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      type,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }).toList(),
    );
  }
}
