import 'dart:developer';

import 'package:aurora/components/IconWithLabel.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:infinite_carousel/infinite_carousel.dart';
import 'package:shimmer/shimmer.dart';

class MangaHomepageCarousel extends StatelessWidget {
  final List<dynamic>? carouselData;
  final String? title;
  final String? tag;
  const MangaHomepageCarousel(
      {super.key, this.title, this.carouselData, this.tag});

  @override
  Widget build(BuildContext context) {
    // if (carouselData == null || carouselData!.isEmpty) {
    //   return SizedBox(
    //     height: 300,
    //     width: MediaQuery.of(context).size.width,
    //     child: Column(
    //       crossAxisAlignment: CrossAxisAlignment.start,
    //       children: [
    //         Text(
    //           'Currently Reading',
    //           style: TextStyle(
    //             fontSize: 22,
    //             fontFamily: 'Poppins',
    //             fontWeight: FontWeight.bold,
    //             color: Theme.of(context).colorScheme.primary,
    //           ),
    //         ),
    //         const Expanded(
    //           child: Center(
    //             child: Text("Guess it's your first time here huh?"),
    //           ),
    //         ),
    //       ],
    //     ),
    //   );
    // }
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
              log(itemData.toString());
              final String posterUrl = itemData['poster'] ?? '??';
              final tagg = itemData.toString() + tag!;
              String? extraData = itemData['currentChapter']!.toString().length > 20 ? itemData['currentChapter']?.toString().substring(0,20) : itemData['currentChapter']?.toString() ?? '??';

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/manga/details',
                      arguments: {
                        'id': itemData['mangaId'],
                        'posterUrl': posterUrl,
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
                              itemData['mangaTitle'].toString(),
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
                                            const Color(0xffe2e2e2)
                                        ? Colors.black
                                        : Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    blurRadius: 4,
                                    color: Colors.black.withOpacity(0.7),
                                    offset: const Offset(2, 2),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Positioned(
                              top: 7,
                              right: 7,
                              child: iconWithName(
                                icon: Iconsax.book,
                                TextColor: Theme.of(context)
                                            .colorScheme
                                            .inverseSurface ==
                                        Theme.of(context)
                                            .colorScheme
                                            .onPrimaryFixedVariant
                                    ? Colors.black
                                    : Theme.of(context)
                                                .colorScheme
                                                .onPrimaryFixedVariant ==
                                            const Color(0xffe2e2e2)
                                        ? Colors.black
                                        : Colors.white,
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
                                            const Color(0xffe2e2e2)
                                        ? Colors.black
                                        : Colors.white,
                                name: extraData!,
                                isVertical: false,
                                borderRadius: BorderRadius.circular(5),
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryFixedVariant,
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
