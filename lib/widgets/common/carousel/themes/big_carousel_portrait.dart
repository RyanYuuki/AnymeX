import 'package:anymex/constants/dimensions.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:anymex/screens/novel/details/details_view.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/carousel/carousel_types.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_bottomsheet.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/common/marquee_text.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/media_items/media_peek_popup.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';

class BigCarouselPortrait extends StatefulWidget {
  final List<Media> data;
  final CarouselType carouselType;

  const BigCarouselPortrait({
    super.key,
    required this.data,
    this.carouselType = CarouselType.anime,
  });

  @override
  State<BigCarouselPortrait> createState() => _BigCarouselPortraitState();
}

class _BigCarouselPortraitState extends State<BigCarouselPortrait> {
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
      if (media.mediaType == ItemType.novel) {
        navigate(() => NovelDetailsPage(media: media));
      } else {
        navigate(() => MangaDetailsPage(media: media, tag: tag));
      }
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

    AnymeXSheet.custom(
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.4,
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
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
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
            ],
          ),
        ),
        context);
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
                          '${mediaList[activeIndex].id}-portrait-carousel');
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
                      final tag = '${media.id}-portrait-carousel';

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
                                    Text(
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
                                        child: AnymeXText(
                                          text: cleanDescription.isNotEmpty
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
