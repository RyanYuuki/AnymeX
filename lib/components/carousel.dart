// ignore_for_file: prefer_const_constructors

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:iconly/iconly.dart';

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
        height: 400, 
        aspectRatio: 2 / 3,
        viewportFraction: 0.7,
        initialPage: 0,
        enableInfiniteScroll: true,
        reverse: false,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 3),
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
        autoPlayCurve: Curves.fastOutSlowIn,
        enlargeCenterPage: true,
        enlargeFactor: 0.3,
        scrollDirection: Axis.horizontal,
      ),
      items: animeData!.map((anime) {
        final String posterUrl = anime['poster'] ?? '??';
        final String rating = anime['rating'] ?? '??';

        return Builder(
          builder: (BuildContext context) {
            return Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,  // Constrain the size of the Column
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/details',
                            arguments: {"id": anime['id']});
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        height: 300,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            posterUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      anime['name'].length > 20
                          ? '${anime['name'].toString().substring(0, 20)}...'
                          : anime['name'] ?? '??',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
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
                    child: Row(
                      children: [
                        const Icon(IconlyBold.star,
                            color: Colors.yellow, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          rating,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
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
    );
  }
}
