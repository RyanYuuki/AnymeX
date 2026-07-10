import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/carousel/carousel_types.dart';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/common/marquee_text.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/media_items/media_peek_popup.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class BigCarouselClassic extends StatefulWidget {
  final List<Media> data;
  final CarouselType carouselType;

  const BigCarouselClassic({
    super.key,
    required this.data,
    this.carouselType = CarouselType.anime,
  });

  @override
  State<BigCarouselClassic> createState() => BigCarouselClassicState();
}

class BigCarouselClassicState extends State<BigCarouselClassic> {
  int activeIndex = 0;
  final CarouselSliderController sliderController = CarouselSliderController();
  double horizontalScrollDelta = 0;
  DateTime lastScrollTime = DateTime.now();

  void onHorizontalScroll(Offset delta, PointerDeviceKind kind) {
    final now = DateTime.now();
    if (now.difference(lastScrollTime) < const Duration(milliseconds: 300)) {
      return;
    }

    if (delta.dx != 0) {
      horizontalScrollDelta -= delta.dx;
    }

    if (horizontalScrollDelta.abs() > 50) {
      if (horizontalScrollDelta > 0) {
        sliderController.nextPage();
      } else {
        sliderController.previousPage();
      }
      horizontalScrollDelta = 0;
      lastScrollTime = now;
    }
  }

  void navigateToDetailsPage(Media media, String tag) {
    if (widget.carouselType == CarouselType.manga) {
      navigate(() => MangaDetailsPage(media: media, tag: tag));
    } else {
      navigate(() => AnimeDetailsPage(media: media, tag: tag));
    }
  }

  void openDescriptionSheet(BuildContext context, String description) {
    final cleanDescription = description
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\n\s*\n'), '\n')
        .trim();
    final colors = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (sheetContext, scrollController) => Container(
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 14, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.onSurfaceVariant.opaque(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Scrollbar(
                  controller: scrollController,
                  thumbVisibility: true,
                  radius: const Radius.circular(8),
                  thickness: 5,
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
                    child: cleanDescription.isEmpty
                        ? buildEmptyDescriptionState(colors)
                        : Text(
                            cleanDescription,
                            style: TextStyle(
                              fontSize: 15.5,
                              height: 1.75,
                              letterSpacing: 0.1,
                              color: colors.onSurfaceVariant,
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
                    final tag = '${media.id}-classic-carousel';

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

Widget buildEmptyDescriptionState(ColorScheme colors) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 48),
    child: Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colors.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.description_outlined,
              size: 32,
              color: colors.onSecondaryContainer,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Description Available',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: colors.onSurface,
            ),
          ),
        ],
      ),
    ),
  );
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
            color: colors.surfaceContainerLow.withValues(alpha: 0.4),
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
                                  Text(
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
                                .withValues(alpha: 0.4),
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
                                      child: AnymexText(
                                        text: cleanDescription.isNotEmpty
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
