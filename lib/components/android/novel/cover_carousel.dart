// ignore_for_file: non_constant_identifier_names, unused_field, library_private_types_in_public_api

import 'dart:math';

import 'package:anymex/components/android/common/IconWithLabel.dart';
import 'package:anymex/pages/Android/Novel/details_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class Covercarousel extends StatefulWidget {
  final List<dynamic>? animeData;

  const Covercarousel({super.key, this.animeData});

  @override
  _CovercarouselState createState() => _CovercarouselState();
}

class _CovercarouselState extends State<Covercarousel> {
  int activeIndex = 0;
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    final ColorScheme = Theme.of(context).colorScheme;
    if (widget.animeData == null) {
      return const Center(
        heightFactor: 300,
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: widget.animeData!.length,
          itemBuilder: (context, index, realIndex) {
            final anime = widget.animeData![index];
            final String posterUrl = anime?['image'] ?? '';
            final title = anime?['title'] ?? '??';
            final randNum = Random().nextInt(100000);
            final tag = '$randNum$index';
            const String proxyUrl = '';

            return Stack(
              children: [
                Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => NovelDetailsPage(
                                      id: anime['id'],
                                      posterUrl: anime['image'],
                                      tag: tag,
                                    )));
                      },
                      child: Container(
                        height: 170,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        child: Hero(
                          tag: tag,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: proxyUrl + posterUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              alignment: Alignment.topCenter,
                              placeholder: (context, url) => Shimmer.fromColors(
                                baseColor: Colors.grey[900]!,
                                highlightColor: Colors.grey[700]!,
                                child: Container(
                                  color: Colors.grey[400],
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 20),
                          iconWithName(
                            icon: Iconsax.star5,
                            name: (anime['rating']).toString(),
                            isVertical: false,
                            borderRadius: BorderRadius.circular(5),
                            backgroundColor: ColorScheme.onPrimaryFixedVariant,
                            color:
                                Theme.of(context).colorScheme.inverseSurface ==
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
                            TextColor:
                                Theme.of(context).colorScheme.inverseSurface ==
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
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Text(
                        (anime?['description']?.replaceAll(
                                    RegExp(r'<[^>]*>|&[^;]+;'), ''))
                                ?.toString()
                                .trim() ??
                            '',
                        style: TextStyle(
                          fontSize: 12,
                          color: ColorScheme.inverseSurface.withOpacity(0.7),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 3,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
          options: CarouselOptions(
            height: 270,
            viewportFraction: 1,
            initialPage: 0,
            enableInfiniteScroll: true,
            reverse: false,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.fastOutSlowIn,
            enlargeCenterPage: false,
            scrollDirection: Axis.horizontal,
            onPageChanged: (index, reason) {
              setState(() {
                activeIndex = index;
              });
            },
          ),
        ),
        const SizedBox(height: 16),
        AnimatedSmoothIndicator(
          activeIndex: activeIndex,
          count: widget.animeData!.length,
          effect: WormEffect(
            dotHeight: 8,
            dotWidth: 8,
            activeDotColor: Theme.of(context).colorScheme.primary,
            dotColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}
