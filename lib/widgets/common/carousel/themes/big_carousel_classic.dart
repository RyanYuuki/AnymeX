import 'package:anymex/models/Media/media.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/carousel/carousel_types.dart';
import 'package:anymex/widgets/common/carousel/themes/base_big_carousel.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/common/marquee_text.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/media_items/media_peek_popup.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class BigCarouselClassic extends BaseBigCarousel {
  const BigCarouselClassic({
    super.key,
    required super.data,
    super.carouselType = CarouselType.anime,
  });

  @override
  State<BigCarouselClassic> createState() => BigCarouselClassicState();
}

class BigCarouselClassicState
    extends BaseBigCarouselState<BigCarouselClassic> {
  @override
  Widget build(BuildContext context) {
    final mediaList = widget.data.where((item) => item.cover != null).toList();
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20),
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
                      sliderController
                          .animateToPage((activeIndex + 1) % mediaList.length);
                    });
                  } else if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
                      event.logicalKey == LogicalKeyboardKey.arrowDown) {
                    return KeyEventResult.ignored;
                  } else if (event.logicalKey == LogicalKeyboardKey.enter ||
                      event.logicalKey == LogicalKeyboardKey.space ||
                      event.logicalKey == LogicalKeyboardKey.select) {
                    navigateToDetailsPage(mediaList[activeIndex],
                        '${mediaList[activeIndex].id}-classic-carousel');
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
                    final tag = '${media.id}-${widget.carouselType.name}-classic-carousel-$index';

                    return buildCarouselCard(
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
                    height: getResponsiveSize(context,
                        mobileSize: 335, desktopSize: 485),
                    viewportFraction: 1,
                    initialPage: 0,
                    enableInfiniteScroll: true,
                    reverse: false,
                    autoPlay: true,
                    autoPlayInterval: const Duration(seconds: 5),
                    autoPlayAnimationDuration:
                        const Duration(milliseconds: 800),
                    autoPlayCurve: Curves.easeInOutCubicEmphasized,
                    enlargeCenterPage: false,
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
          const SizedBox(height: 18),
          AnimatedSmoothIndicator(
            activeIndex: activeIndex,
            count: mediaList.length,
            effect: JumpingDotEffect(
              dotHeight: 8,
              dotWidth: 8,
              jumpScale: 1.6,
              verticalOffset: 8,
              activeDotColor: colors.primary,
              dotColor: colors.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}

Widget buildCarouselCard({
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
  final posterHeight =
      getResponsiveSize(context, mobileSize: 190, desktopSize: 340);
  final cardRadius = BorderRadius.circular(30).resolve(TextDirection.ltr);

  bool cardPressed = false;

  return StatefulBuilder(
    builder: (statefulContext, updateCardState) {
      return AnimatedScale(
        scale: cardPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
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
                  ClipRRect(
                    borderRadius: cardRadius,
                    child: Hero(
                      tag: tag,
                      transitionOnUserGestures: true,
                      flightShuttleBuilder:
                          AnymeXImage.heroFlightShuttleBuilder,
                      child: AnymeXImage(
                        imageUrl: media.cover!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: posterHeight,
                        alignment: Alignment.topCenter,
                        radius: 0,
                        fadeInDuration: Duration.zero,
                        fadeOutDuration: Duration.zero,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: colors.tertiaryContainer
                                    .withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Iconsax.star5,
                                      size: 14,
                                      color: colors.onTertiaryContainer),
                                  const SizedBox(width: 4),
                                  AnymeXText(
                                    rating,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: colors.onTertiaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
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
                                    horizontal: 14, vertical: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: AnymeXText(cleanDescription.isNotEmpty
                                            ? cleanDescription
                                            : 'Tap to read description',
                                        size: 12.5,
                                        maxLines: 3,
                                        color: colors.onSecondaryContainer
                                            .opaque(cleanDescription.isNotEmpty
                                                ? 0.9
                                                : 0.6),
                                        overflow: TextOverflow.ellipsis,
                                        stripHtml: true,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.arrow_outward_rounded,
                                      size: 16,
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
