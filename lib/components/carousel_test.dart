// ignore_for_file: prefer_const_constructors

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';

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
        height: 300,
        viewportFraction: 1,
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
        final String posterUrl = anime['poster'] ?? '??';
        final tag = anime['name'] + anime['jname'] + anime['id'];

        return Builder(
          builder: (BuildContext context) {
            return Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/details',
                        arguments: {
                          'id': anime['id'],
                          'posterUrl': posterUrl,
                          "tag": tag
                        },
                      );
                    },
                    child: SizedBox(
                      height: 170,
                      width: MediaQuery.of(context).size.width,
                      child: Hero(
                        tag: tag,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: CachedNetworkImage(
                            imageUrl: posterUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    anime['name'].length > 20
                        ? '${anime['name'].toString().substring(0, 20)}...'
                        : anime['name'] ?? '??',
                    textAlign: TextAlign.left,
                  )
                ],
              ),
            );
          },
        );
      }).toList(),
    );
  }
}
