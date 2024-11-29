import 'dart:math';
import 'package:anymex/pages/Android/Novel/details_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class DesktopCoverCarousel extends StatefulWidget {
  final List<dynamic>? animeData;
  final String? title;

  const DesktopCoverCarousel({
    super.key,
    this.animeData,
    this.title,
  });

  @override
  _DesktopCoverCarouselState createState() => _DesktopCoverCarouselState();
}

class _DesktopCoverCarouselState extends State<DesktopCoverCarousel> {
  int activeIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
            final String posterUrl = anime?['image'];
            final title = anime?['title'] ?? '??';
            final randNum = Random().nextInt(100000);
            final tag = '$randNum$index';
            const String proxyUrl = '';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => NovelDetailsPage(
                                  id: anime['id'],
                                  posterUrl: posterUrl,
                                  tag: tag,
                                )));
                  },
                  child: Container(
                    height: 300,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    child: Hero(
                      tag: tag,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: proxyUrl + posterUrl,
                          fit: BoxFit.cover,
                          width: double.maxFinite,
                          height: 400,
                          alignment: Alignment.center,
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
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.left,
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text(
                    (anime?['description']
                                ?.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ''))
                            ?.toString()
                            .trim() ??
                        '',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .inverseSurface
                          .withOpacity(0.7),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3,
                  ),
                ),
              ],
            );
          },
          options: CarouselOptions(
            height: 400,
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
        smoothIndicator(colorScheme),
      ],
    );
  }

  Widget smoothIndicator(ColorScheme colorScheme) {
    return AnimatedSmoothIndicator(
      activeIndex: activeIndex,
      count: widget.animeData!.length,
      effect: WormEffect(
        dotHeight: 8,
        dotWidth: 8,
        activeDotColor: colorScheme.primary,
        dotColor: colorScheme.onSurface.withOpacity(0.5),
      ),
    );
  }
}
