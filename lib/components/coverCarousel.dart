// ignore_for_file: prefer_const_constructors

import 'package:aurora/components/IconWithLabel.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class CoverCarousel extends StatelessWidget {
  final List<dynamic>? animeData;
  final String? title;
  const CoverCarousel({super.key, this.animeData, this.title});

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
        height: 350,
        viewportFraction: 1,
        initialPage: 0,
        enlargeCenterPage: true,
        enlargeFactor: 0.2,
        scrollDirection: Axis.horizontal,
      ),
      items: animeData!.map((anime) {
        final String posterUrl = anime['poster'] ?? '??';
        final String type = anime['type'] ?? '??';
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
                        height: 200,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              anime['name'],
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 20),
                          iconWithName(
                            icon: Iconsax.calendar5,
                            name: anime['otherInfo'][2],
                            isVertical: false,
                            borderRadius: BorderRadius.circular(5),
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            color: Colors.white,
                            TextColor: Colors.white,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Expanded(
                          child: Text(
                        anime['description'],
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .inverseSurface
                                .withOpacity(0.7)),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 3,
                      )),
                    )
                  ],
                ),
              ],
            );
          },
        );
      }).toList(),
    );
  }
}
