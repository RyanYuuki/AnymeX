// ignore_for_file: non_constant_identifier_names, unused_field, library_private_types_in_public_api

import 'dart:math';

import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

enum CarouselType { anime, manga, simkl }

class BigCarousel extends StatefulWidget {
  final List<Media> data;
  final CarouselType carouselType;

  const BigCarousel({
    super.key,
    required this.data,
    this.carouselType = CarouselType.anime,
  });

  @override
  _BigCarouselState createState() => _BigCarouselState();
}

class _BigCarouselState extends State<BigCarousel> {
  int activeIndex = 0;
  final PageController _pageController = PageController();
  final CarouselSliderController controller = CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    final newData = widget.data.where((e) => e.cover != null).toList();
    final ColorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20),
      child: Column(
        children: [
          AnymexOnTapAdv(
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent) {
                if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                  setState(() {
                    controller.animateToPage(
                        (activeIndex - 1).clamp(0, newData.length - 1));
                  });
                } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                  setState(() {
                    controller
                        .animateToPage((activeIndex + 1) % newData.length);
                  });
                } else if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
                    event.logicalKey == LogicalKeyboardKey.arrowDown) {
                  return KeyEventResult.ignored;
                } else if (event.logicalKey == LogicalKeyboardKey.enter ||
                    event.logicalKey == LogicalKeyboardKey.space ||
                    event.logicalKey == LogicalKeyboardKey.select) {
                  navigateToDetailsPage(newData[activeIndex],
                      '${newData[activeIndex].title}-$activeIndex');
                }
              }
              return KeyEventResult.handled;
            },
            scale: 1,
            child: CarouselSlider.builder(
              itemCount: newData.length,
              itemBuilder: (context, index, realIndex) {
                final anime = newData[index];
                final String posterUrl = anime.cover!;
                final title = anime.title;
                final randNum = Random().nextInt(100000);
                final tag = '$randNum$index${anime.title}';
                String extraData = anime.rating.toString();

                return Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => navigateToDetailsPage(anime, tag),
                          child: _buildItem(context, tag, posterUrl),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  title ?? '??',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    (8.multiplyRadius()),
                                  ),
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondaryContainer,
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Iconsax.star5,
                                      size: 16,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      extraData,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontFamily: "Poppins-Bold",
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: AnymexText(
                            text: anime.description.isNotEmpty
                                ? anime.description
                                : 'Description Not Available',
                            size: 12,
                            color: ColorScheme.inverseSurface.withOpacity(0.7),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 3,
                            stripHtml: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
              options: CarouselOptions(
                height: getResponsiveSize(context,
                    mobileSize: 270, desktopSize: 450),
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
              carouselController: controller,
            ),
          ),
          const SizedBox(height: 16),
          AnimatedSmoothIndicator(
            activeIndex: activeIndex,
            count: widget.data.length,
            effect: WormEffect(
              dotHeight: 8,
              dotWidth: 8,
              activeDotColor: Theme.of(context).colorScheme.primary,
              dotColor:
                  Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  void navigateToDetailsPage(Media anime, String tag) {
    if (widget.carouselType == CarouselType.manga) {
      navigate(() => MangaDetailsPage(
            media: anime,
            tag: tag,
          ));
    } else {
      navigate(() => AnimeDetailsPage(
            media: anime,
            tag: tag,
          ));
    }
  }

  Container _buildItem(BuildContext context, String tag, String posterUrl) {
    return Container(
      height: getResponsiveSize(context, mobileSize: 170, desktopSize: 330),
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: Hero(
        tag: tag,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
              imageUrl: posterUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              alignment: Alignment.topCenter,
              placeholder: (context, url) => placeHolderWidget(context)),
        ),
      ),
    );
  }
}
