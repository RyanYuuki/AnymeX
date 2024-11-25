import 'dart:async'; // Add this import for Timer
import 'dart:math';
import 'package:aurora/components/android/common/IconWithLabel.dart';
import 'package:aurora/pages/Android/Anime/details_page.dart';
import 'package:aurora/pages/Android/Manga/details_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class DesktopCoverCarousel extends StatefulWidget {
  final List<dynamic>? animeData;
  final String? title;
  final bool isManga;

  const DesktopCoverCarousel({
    super.key,
    this.animeData,
    this.title,
    this.isManga = false,
  });

  @override
  _DesktopCoverCarouselState createState() => _DesktopCoverCarouselState();
}

class _DesktopCoverCarouselState extends State<DesktopCoverCarousel> {
  int activeIndex = 0;
  final PageController _pageController = PageController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        int nextPage = (activeIndex + 1) % widget.animeData!.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void slideCarousel(bool left) {
    if (left) {
      _pageController.animateToPage(
        (_pageController.page! - 1).toInt(),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _pageController.animateToPage(
        (_pageController.page! + 1).toInt(),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

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
        SizedBox(
          height: 360,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.animeData!.length,
            onPageChanged: (index) {
              setState(() {
                activeIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final anime = widget.animeData![index];
              final String posterUrl =
                  anime?['bannerImage'] ?? anime?['coverImage']['large'];
              final title = anime?['title']?['english'] ??
                  anime?['title']?['romaji'] ??
                  '??';
              final randNum = Random().nextInt(100000);
              final tag = '$randNum$index';

              return GestureDetector(
                onTap: () {
                  if (widget.isManga) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MangaDetailsPage(
                          id: anime['id'],
                          posterUrl: posterUrl,
                          tag: tag,
                        ),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailsPage(
                          id: anime['id'],
                          posterUrl: posterUrl,
                          tag: tag,
                        ),
                      ),
                    );
                  }
                },
                child: Stack(
                  children: [
                    Column(
                      children: [
                        Hero(
                          tag: tag,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: posterUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 260,
                              alignment: Alignment.topCenter,
                              placeholder: (context, url) => Shimmer.fromColors(
                                baseColor: Colors.grey[900]!,
                                highlightColor: Colors.grey[700]!,
                                child: Container(
                                  color: Colors.grey[400],
                                  height: 170,
                                  width: double.infinity,
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
                                name: (anime['averageScore'] / 10).toString(),
                                isVertical: false,
                                borderRadius: BorderRadius.circular(5),
                                backgroundColor: colorScheme.secondaryContainer,
                                color: colorScheme.inverseSurface,
                                TextColor: colorScheme.inverseSurface,
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
                              color:
                                  colorScheme.inverseSurface.withOpacity(0.7),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 3,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox.shrink(),
            AnimatedSmoothIndicator(
              activeIndex: activeIndex,
              count: widget.animeData!.length,
              effect: WormEffect(
                dotHeight: 8,
                dotWidth: 8,
                activeDotColor: colorScheme.primary,
                dotColor: colorScheme.onSurface.withOpacity(0.5),
              ),
              onDotClicked: (index) {
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () => slideCarousel(true),
                  icon: const Icon(Icons.arrow_left),
                ),
                IconButton(
                  onPressed: () => slideCarousel(false),
                  icon: const Icon(Icons.arrow_right),
                )
              ],
            )
          ],
        ),
      ],
    );
  }
}
