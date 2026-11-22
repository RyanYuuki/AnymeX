import 'package:anymex/constants/dimensions.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/carousel/carousel_types.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/common/marquee_text.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/media_items/media_peek_popup.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:anymex/widgets/common/carousel/themes/base_big_carousel.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';

class BigCarouselPortrait extends BaseBigCarousel {
  const BigCarouselPortrait({
    super.key,
    required super.data,
    super.carouselType = CarouselType.anime,
  });

  @override
  State<BigCarouselPortrait> createState() => _BigCarouselPortraitState();
}

class _BigCarouselPortraitState
    extends BaseBigCarouselState<BigCarouselPortrait> {
  double _calculateViewportFraction(double width) {
    if (width > 1200) {
      return 0.22;
    } else if (width > 800) {
      return 0.28;
    } else if (width > maxMobileWidth) {
      return 0.42;
    } else {
      return 0.62;
    }
  }

  double _calculateCarouselHeight(
      double availableWidth, double viewportFraction) {
    final cardWidth = (availableWidth * viewportFraction) - 16;
    final imageWidth = cardWidth - 20;
    final imageHeight = imageWidth * 3 / 2;

    const chromeHeight = 10 + 30 + 8 + 44 + 22;

    final total = imageHeight + chromeHeight;

    final maxHeight = availableWidth > maxMobileWidth ? 620.0 : 480.0;

    return total.clamp(280.0, maxHeight);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final availableWidth = constraints.maxWidth;
      final viewportFraction = _calculateViewportFraction(availableWidth);
      final carouselHeight =
          _calculateCarouselHeight(availableWidth, viewportFraction);

      final mediaList = widget.data
          .where((item) =>
              (item.poster.isNotEmpty && item.poster != '?') ||
              (item.largePoster.isNotEmpty && item.largePoster != '?'))
          .toList();
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20),
        child: Column(
          children: [
            Listener(
              behavior: HitTestBehavior.translucent,
              onPointerSignal: (pointerSignal) {
                if (pointerSignal is PointerScrollEvent) {
                  onHorizontalScroll(
                      pointerSignal.scrollDelta, pointerSignal.kind);
                }
              },
              onPointerPanZoomUpdate: (event) {
                onHorizontalScroll(event.panDelta, event.kind);
              },
              child: AnymexOnTapAdv(
                onKeyEvent: (node, event) {
                  if (event is KeyDownEvent) {
                    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                      setState(() {
                        sliderController.animateToPage(
                            (activeIndex - 1).clamp(0, mediaList.length - 1));
                      });
                    } else if (event.logicalKey ==
                        LogicalKeyboardKey.arrowRight) {
                      setState(() {
                        sliderController.animateToPage(
                            (activeIndex + 1) % mediaList.length);
                      });
                    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
                        event.logicalKey == LogicalKeyboardKey.arrowDown) {
                      return KeyEventResult.ignored;
                    } else if (event.logicalKey == LogicalKeyboardKey.enter ||
                        event.logicalKey == LogicalKeyboardKey.space ||
                        event.logicalKey == LogicalKeyboardKey.select) {
                      navigateToDetailsPage(mediaList[activeIndex],
                          '${mediaList[activeIndex].id}-${widget.carouselType.name}-portrait-carousel-$activeIndex');
                    }
                  }
                  return KeyEventResult.handled;
                },
                scale: 1,
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                      PointerDeviceKind.trackpad,
                    },
                  ),
                  child: CarouselSlider.builder(
                    itemCount: mediaList.length,
                    disableGesture: false,
                    itemBuilder: (itemContext, index, realIndex) {
                      final media = mediaList[index];
                      final tag = '${media.id}-${widget.carouselType.name}-portrait-carousel-$index';

                      return _buildPortraitCard(
                        context: itemContext,
                        media: media,
                        tag: tag,
                        onTap: () => navigateToDetailsPage(media, tag),
                        onLongPress: () {
                          final itemType =
                              widget.carouselType == CarouselType.manga
                                  ? ItemType.manga
                                  : ItemType.anime;
                          if (media.userStatus == null ||
                              media.userStatus!.isEmpty) {
                            MediaPeekPopup.show(
                                itemContext, media, itemType, tag);
                          }
                        },
                        onDescriptionTap: () =>
                            openDescriptionSheet(context, media.description),
                      );
                    },
                    options: CarouselOptions(
                      height: carouselHeight,
                      viewportFraction: viewportFraction,
                      initialPage: 0,
                      enableInfiniteScroll: true,
                      reverse: false,
                      autoPlay: true,
                      autoPlayInterval: const Duration(seconds: 5),
                      autoPlayAnimationDuration:
                          const Duration(milliseconds: 800),
                      autoPlayCurve: Curves.easeInOutCubicEmphasized,
                      enlargeCenterPage: true,
                      enlargeFactor: 0.15,
                      scrollDirection: Axis.horizontal,
                      onPageChanged: (index, reason) {
                        setState(() {
                          activeIndex = index;
                        });
                      },
                    ),
                    carouselController: sliderController,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPortraitCard({
    required BuildContext context,
    required Media media,
    required String tag,
    required VoidCallback onTap,
    required VoidCallback onLongPress,
    required VoidCallback onDescriptionTap,
  }) {
    final colors = Theme.of(context).colorScheme;
    final rating = media.rating.toString();
    final cleanDescription = media.description
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final cardRadius = BorderRadius.circular(30).resolve(TextDirection.ltr);
    final imageUrl = (media.largePoster.isNotEmpty && media.largePoster != '?')
        ? media.largePoster
        : ((media.poster.isNotEmpty && media.poster != '?')
            ? media.poster
            : '');

    bool cardPressed = false;

    return StatefulBuilder(
      builder: (statefulContext, updateCardState) {
        return AnimatedScale(
          scale: cardPressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            clipBehavior: Clip.antiAlias,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: cardRadius,
                onTap: onTap,
                onLongPress: onLongPress,
                onTapDown: (_) => updateCardState(() => cardPressed = true),
                onTapCancel: () => updateCardState(() => cardPressed = false),
                onTapUp: (_) => updateCardState(() => cardPressed = false),
                splashColor: colors.primary.opaque(0.12),
                highlightColor: colors.primary.opaque(0.06),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: 2 / 3,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: Hero(
                                tag: tag,
                                transitionOnUserGestures: true,
                                flightShuttleBuilder:
                                    AnymeXImage.heroFlightShuttleBuilder,
                                child: AnymeXImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  alignment: Alignment.center,
                                  radius: 0,
                                  fadeInDuration: Duration.zero,
                                  fadeOutDuration: Duration.zero,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 14, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: MarqueeText(
                                  media.title,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: colors.tertiaryContainer
                                      .withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Iconsax.star5,
                                        size: 13,
                                        color: colors.onTertiaryContainer),
                                    const SizedBox(width: 3),
                                    AnymeXText(
                                      rating,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        color: colors.onTertiaryContainer,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Material(
                              color: colors.secondaryContainer
                                  .withValues(alpha: 0.2),
                              child: InkWell(
                                onTap: onDescriptionTap,
                                splashColor:
                                    colors.onSecondaryContainer.opaque(0.1),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: AnymeXText(cleanDescription.isNotEmpty
                                              ? cleanDescription
                                              : 'Tap to read description',
                                          size: 11.5,
                                          maxLines: 2,
                                          color: colors.onSecondaryContainer
                                              .opaque(
                                                  cleanDescription.isNotEmpty
                                                      ? 0.9
                                                      : 0.6),
                                          overflow: TextOverflow.ellipsis,
                                          stripHtml: true,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        Icons.arrow_outward_rounded,
                                        size: 15,
                                        color: colors.onSecondaryContainer,
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
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
