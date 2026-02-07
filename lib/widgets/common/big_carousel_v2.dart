import 'dart:math';
import 'dart:ui';

import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/utils/color_extractor.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/big_carousel.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/header.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dartotsu_extension_bridge/Models/Source.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class BigCarouselV2 extends StatefulWidget {
  final List<Media> data;
  final CarouselType carouselType;

  const BigCarouselV2({
    super.key,
    required this.data,
    this.carouselType = CarouselType.anime,
  });

  @override
  _BigCarouselV2State createState() => _BigCarouselV2State();
}

class _BigCarouselV2State extends State<BigCarouselV2> {
  int activeIndex = 0;
  final CarouselSliderController controller = CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    final newData = widget.data.where((e) => e.cover != null).toList();
    if (newData.isEmpty) return const SizedBox.shrink();

    final colorScheme = Get.theme.colorScheme;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              CarouselSlider.builder(
                itemCount: newData.length,
                itemBuilder: (context, index, realIndex) {
                  final item = newData[index];
                  final isActive = index == activeIndex;
                  return _CarouselCard(
                    media: item,
                    isActive: isActive,
                    carouselType: widget.carouselType,
                    onTap: () => navigateToDetailsPage(item),
                    onShowDescription: () =>
                        _showDescriptionSheet(context, item),
                  );
                },
                options: CarouselOptions(
                  height: 400,
                  viewportFraction: 0.65,
                  enlargeCenterPage: true,
                  enlargeFactor: 0.2,
                  initialPage: 0,
                  enableInfiniteScroll: true,
                  autoPlay: !kDebugMode,
                  autoPlayInterval: const Duration(seconds: 6),
                  autoPlayAnimationDuration: const Duration(milliseconds: 800),
                  autoPlayCurve: Curves.fastOutSlowIn,
                  scrollDirection: Axis.horizontal,
                  onPageChanged: (index, reason) {
                    setState(() {
                      activeIndex = index;
                    });
                  },
                ),
                carouselController: controller,
              ),
              const SizedBox(height: 20),
              AnimatedSmoothIndicator(
                activeIndex: activeIndex,
                count: newData.length,
                effect: ScrollingDotsEffect(
                  activeDotColor: colorScheme.primary,
                  dotColor: colorScheme.onSurface.opaque(0.1),
                  dotHeight: 6,
                  dotWidth: 6,
                  activeDotScale: 1.5,
                  spacing: 8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDescriptionSheet(BuildContext context, Media media) {
    final colorScheme = Get.theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Stack(
                children: [
                  ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: media.cover ?? '',
                              height: 100,
                              width: 70,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  media.title,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: (media.genres ?? []).map((genre) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary.opaque(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        genre,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 24),
                      Divider(color: colorScheme.onSurface.opaque(0.1)),
                      const SizedBox(height: 16),
                      Text(
                        "Synopsis",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AnymexText(
                        text: media.description,
                        size: 14,
                        color: colorScheme.onSurface.opaque(0.8),
                        stripHtml: true,
                        maxLines: 999,
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                  Positioned(
                    top: 10,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colorScheme.onSurface.opaque(0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  void navigateToDetailsPage(Media item) {
    final tag = '${item.id}-carousel-${Random().nextInt(100)}';
    if (widget.carouselType == CarouselType.manga) {
      navigate(() => MangaDetailsPage(media: item, tag: tag));
    } else {
      navigate(() => AnimeDetailsPage(media: item, tag: tag));
    }
  }
}

class _CarouselCard extends StatefulWidget {
  final Media media;
  final bool isActive;
  final CarouselType carouselType;
  final VoidCallback onTap;
  final VoidCallback onShowDescription;

  const _CarouselCard({
    required this.media,
    required this.isActive,
    required this.carouselType,
    required this.onTap,
    required this.onShowDescription,
  });

  @override
  State<_CarouselCard> createState() => _CarouselCardState();
}

class _CarouselCardState extends State<_CarouselCard> {
  ColorScheme? _colorScheme;
  bool _isExtracted = false;

  @override
  void initState() {
    super.initState();
    _extractColorLazily();
  }

  void _extractColorLazily() async {
    if (_isExtracted) return;
    _isExtracted = true;

    final cachedColor = ImageColorExtractor.getCachedColor(widget.media.poster);
    if (cachedColor != null) {
      if (mounted) {
        setState(() {
          _colorScheme = ColorScheme.fromSeed(
            seedColor: cachedColor,
            brightness: Get.theme.brightness,
          );
        });
      }
      return;
    }

    final color = await ImageColorExtractor.extractColor(
      widget.media.poster,
      targetSize: const Size(50, 50),
    );

    if (color != null && mounted) {
      setState(() {
        _colorScheme = ColorScheme.fromSeed(
          seedColor: color,
          brightness: Get.theme.brightness,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tag = '${widget.media.id}-carousel-${Random().nextInt(100)}';
    final colorScheme = _colorScheme ?? Get.theme.colorScheme;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.onSurface.opaque(0.05, iReallyMeanIt: true),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Hero(
                tag: tag,
                child: AnymeXImage(
                  imageUrl: getResponsiveValue(context,
                      mobileValue: widget.media.largePoster,
                      desktopValue: widget.media.cover),
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surface
                            .opaque(0.7, iReallyMeanIt: true),
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              widget.carouselType == CarouselType.manga
                                  ? Iconsax.book_1
                                  : Iconsax.play5,
                              color: colorScheme.onPrimary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.media.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Poppins-Bold',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(Iconsax.star5,
                                        size: 12, color: colorScheme.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.media.rating.toString(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            colorScheme.onSurface.opaque(0.7),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildDot(colorScheme),
                                    const SizedBox(width: 8),
                                    Icon(
                                        widget.media.mediaType == ItemType.manga
                                            ? Iconsax.book
                                            : Icons.play_circle_rounded,
                                        size: 12,
                                        color: colorScheme.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.media.totalEpisodes,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color:
                                            colorScheme.onSurface.opaque(0.5),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildDot(colorScheme),
                                    const SizedBox(width: 8),
                                    Icon(Icons.info_rounded,
                                        size: 12, color: colorScheme.primary),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: widget.onShowDescription,
                                      child: Container(
                                        color: Colors.transparent,
                                        child: Text(
                                          "Info",
                                          style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.primary,
                                              decoration:
                                                  TextDecoration.underline,
                                              decorationColor: colorScheme
                                                  .primary
                                                  .opaque(0.5)),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDot(ColorScheme colorScheme) {
    return Container(
      width: 3,
      height: 3,
      decoration: BoxDecoration(
        color: colorScheme.onSurface.opaque(0.3),
        shape: BoxShape.circle,
      ),
    );
  }
}
