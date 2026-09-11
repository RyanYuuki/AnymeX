import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/screens/novel/details/details_view.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_bottomsheet.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/common/carousel/carousel_types.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

abstract class BaseBigCarousel extends StatefulWidget {
  final List<Media> data;
  final CarouselType carouselType;

  const BaseBigCarousel({
    super.key,
    required this.data,
    this.carouselType = CarouselType.anime,
  });
}

abstract class BaseBigCarouselState<T extends BaseBigCarousel>
    extends State<T> {
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const AnymeXText(
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
                    : AnymeXText(
                        cleanDescription,
                        maxLines: 1000,
                        overflow: TextOverflow.visible,
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
      context,
    );
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
            AnymeXText(
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
}
