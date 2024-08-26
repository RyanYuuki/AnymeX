// ignore_for_file: must_be_immutable

import 'package:aurora/components/IconWithLabel.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:infinite_carousel/infinite_carousel.dart';

class ReusableCarousel extends StatelessWidget {
  final List<dynamic>? carouselData;
  final String? title;
  final String? tag;

  const ReusableCarousel(
      {super.key, this.title, this.carouselData, required this.tag});

  @override
  Widget build(BuildContext context) {
    if (carouselData == null || carouselData!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Row(
          children: [
            Text(
              title ?? '??',
              style: TextStyle(
                fontSize: 22,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const Text(
              ' Mangas',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
            )
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 260,
          child: InfiniteCarousel.builder(
            itemCount: carouselData!.length,
            itemExtent: MediaQuery.of(context).size.width / 2.3,
            center: false,
            anchor: 0,
            loop: false,
            velocityFactor: 0.7,
            axisDirection: Axis.horizontal,
            itemBuilder: (context, itemIndex, realIndex) {
              final itemData = carouselData![itemIndex];
              final String posterUrl = itemData['image'] ?? '??';
              final tagg = itemData['id'] + tag!;
              const String proxyUrl =
                  'https://goodproxy.goodproxy.workers.dev/fetch?url=';

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/manga/details',
                      arguments: {
                        'id': itemData['id'],
                        'posterUrl': proxyUrl + posterUrl,
                        'tag': tagg
                      },
                    );
                  },
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Hero(
                            tag: tagg,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: proxyUrl + posterUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 250,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.8),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 10,
                            left: 10,
                            right: 10,
                            child: Text(
                              itemData['title'].toString(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    blurRadius: 4,
                                    color: Colors.black.withOpacity(0.7),
                                    offset: Offset(2, 2),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Positioned(
                              top: 5,
                              right: 5,
                              child: iconWithName(
                                icon: Iconsax.heart5,
                                TextColor: Colors.white,
                                color: Colors.white,
                                name: itemData['view'] ?? '69M',
                                isVertical: false,
                                borderRadius: BorderRadius.circular(5),
                                backgroundColor:
                                    Theme.of(context).colorScheme.onPrimaryFixedVariant,
                              ))
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
