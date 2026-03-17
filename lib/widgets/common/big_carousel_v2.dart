import 'dart:math';
import 'dart:ui';
import 'package:flutter/gestures.dart';

import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/carousel/carousel_types.dart';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/header.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:anymex_extension_bridge/Models/Source.dart';
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
              },
            ),
            child: CarouselSlider.builder(
              itemCount: newData.length,
              disableGesture: false,
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
                autoPlayAnimationDuration:
                    const Duration(milliseconds: 800),
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
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 16, bottom: 8),
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface.opaque(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: colorScheme.outline.opaque(0.08),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Description',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                    color: colorScheme.onSurface,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 2,
                              width: 32,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    colorScheme.primary,
                                    colorScheme.primary.opaque(0.3),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.outline.opaque(0.1),
                            ),
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.close_rounded,
                              color: colorScheme.onSurface.opaque(0.7),
                              size: 20,
                            ),
                            splashRadius: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: const BoxDecoration(
                        borderRadius:
                            BorderRadius.vertical(bottom: Radius.circular(24)),
                      ),
                      child: Scrollbar(
                        controller: scrollController,
                        thumbVisibility: true,
                        radius: const Radius.circular(8),
                        thickness: 6,
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: colorScheme.surface.opaque(0.3),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: colorScheme.outline.opaque(0.06),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (media.description.isEmpty) ...[
                                  Center(
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.description_outlined,
                                          size: 48,
                                          color: colorScheme.onSurface.opaque(0.3),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No Description Available',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                color: colorScheme.onSurface.opaque(0.6),
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Description not provided for this item',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: colorScheme.onSurface.opaque(0.4),
                                              ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else ...[
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: AnymeXImage(
                                          imageUrl: media.cover ?? '',
                                          height: 100,
                                          width: 70,
                                          fit: BoxFit.cover,
                                          radius: 0,
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
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
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

class _CarouselCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final tag = '${media.id}-carousel-${Random().nextInt(100)}';
    final colorScheme = Get.theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
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
                      mobileValue: media.largePoster != "?"
                          ? media.largePoster
                          : media.cover,
                      desktopValue: media.cover),
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
                              carouselType == CarouselType.manga
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
                                  media.title,
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
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Icon(Iconsax.star5,
                                        size: 12, color: colorScheme.primary),
                                    Text(
                                      media.rating.toString(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            colorScheme.onSurface.opaque(0.7),
                                      ),
                                    ),
                                    _buildDot(colorScheme),
                                    Icon(
                                        media.mediaType == ItemType.manga
                                            ? Iconsax.book
                                            : Icons.play_circle_rounded,
                                        size: 12,
                                        color: colorScheme.primary),
                                    Text(
                                      media.totalEpisodes,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color:
                                            colorScheme.onSurface.opaque(0.5),
                                      ),
                                    ),
                                    _buildDot(colorScheme),
                                    Icon(Icons.info_rounded,
                                        size: 12, color: colorScheme.primary),
                                    GestureDetector(
                                      onTap: onShowDescription,
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
