import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/underrated_service.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/models_convertor/carousel/carousel_data.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/big_carousel.dart';
import 'package:anymex/widgets/common/cards/base_card.dart';
import 'package:anymex/widgets/common/cards/card_gate.dart';
import 'package:anymex/widgets/common/future_reusable_carousel.dart';
import 'package:anymex/widgets/common/reusable_carousel.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/media_items/media_peek_popup.dart';
import 'package:dartotsu_extension_bridge/Models/Source.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

Widget buildSection(String title, dynamic data,
    {DataVariant variant = DataVariant.regular,
    bool isLoading = false,
    ItemType type = ItemType.anime,
    Source? source}) {
  if (data is Stream) {
    return StreamBuilder(
      stream: data,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return buildLoader(title);
        }
        return ReusableCarousel(
          data: snapshot.data ?? [],
          title: title,
          type: type,
          variant: variant,
          isLoading: isLoading,
          source: source,
        );
      },
    );
  }
  return ReusableCarousel(
    data: data,
    title: title,
    type: type,
    variant: variant,
    isLoading: isLoading,
    source: source,
  );
}

Widget buildUnderratedSection(String title, List<UnderratedMedia> data,
    {ItemType type = ItemType.anime}) {
  if (data.isEmpty) return const SizedBox.shrink();
  return _UnderratedCarousel(
    title: title,
    data: data,
    type: type,
  );
}

Widget buildLoader(String title) {
  return ReusableCarousel(
    data: const [],
    title: title,
    isLoading: true,
  );
}

Container buildChip(String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
    margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 10),
    decoration: BoxDecoration(
      color: Get.theme.colorScheme.primary,
      borderRadius: BorderRadius.circular(10),
    ),
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: AnymexText(
        text: label,
        variant: TextVariant.bold,
        color: Get.theme.colorScheme.onPrimary,
        size: 14,
      ),
    ),
  );
}

Widget buildBigCarousel(List<Media> data, bool isManga, {CarouselType? type}) {
  return BigCarousel(
      data: data,
      carouselType:
          type ?? (isManga ? CarouselType.manga : CarouselType.anime));
}

Widget buildMangaSection(String title, List<Media> data,
    {bool isAnilist = false}) {
  return ReusableCarousel(
    data: data,
    title: title,
    type: ItemType.manga,
    variant: isAnilist ? DataVariant.anilist : DataVariant.regular,
  );
}

Widget buildUnderratedMangaSection(String title, List<UnderratedMedia> data) {
  if (data.isEmpty) return const SizedBox.shrink();
  return _UnderratedCarousel(
    title: title,
    data: data,
    type: ItemType.manga,
  );
}

Widget buildFutureSection(
  String title,
  Future<List<dynamic>> future, {
  DataVariant variant = DataVariant.regular,
  ItemType type = ItemType.anime,
  Source? source,
  Widget? errorWidget,
  Widget? emptyWidget,
}) {
  return FutureReusableCarousel(
    future: future,
    title: title,
    variant: variant,
    type: type,
    source: source,
    errorWidget: errorWidget,
    emptyWidget: emptyWidget,
  );
}

/// Custom carousel widget for underrated anime/manga with special styling
class _UnderratedCarousel extends StatelessWidget {
  final String title;
  final List<UnderratedMedia> data;
  final ItemType type;

  const _UnderratedCarousel({
    required this.title,
    required this.data,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardHeight = getCardHeight(
        CardStyle.values[settingsController.cardStyle], getPlatform(context));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.only(left: 20.0),
            child: Text(
              title,
              style: TextStyle(
                fontFamily: "Poppins-SemiBold",
                fontSize: 17,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Carousel list
          SizedBox(
            height: cardHeight,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 15, top: 5, bottom: 10),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final item = data[index];
                return _UnderratedCard(
                  item: item,
                  type: type,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Card widget for underrated items - uses same cards as the rest of the app
class _UnderratedCard extends StatelessWidget {
  final UnderratedMedia item;
  final ItemType type;

  const _UnderratedCard({
    required this.item,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 600;
    final cardWidth = isDesktop ? 160.0 : 118.0;
    final carouselData = item.toCarouselData(isManga: type == ItemType.manga);
    final tag = 'underrated-${carouselData.id}-${item.media.hashCode}';

    return GestureDetector(
      onTap: () => _navigateToDetails(context),
      onLongPress: () => _showPeekPopup(context),
      child: SizedBox(
        width: cardWidth,
        child: Stack(
          children: [
            // Use the same card system as the rest of the app
            MediaCardGate(
              itemData: carouselData,
              tag: tag,
              variant: DataVariant.underrated,
              cardStyle: CardStyle.values[settingsController.cardStyle],
              type: type,
            ),
            // Recommended by badge (overlay on top-left)
            if (item.recommendedBy != null && item.recommendedBy!.isNotEmpty)
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Iconsax.user,
                        size: 10,
                        color: theme.colorScheme.onPrimary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '@${item.recommendedBy}',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showPeekPopup(BuildContext context) {
    MediaPeekPopup.show(
      context,
      item.media,
      type,
      'underrated-${item.media.id}',
      recommendedBy: item.recommendedBy,
      reason: item.reason,
    );
  }

  void _navigateToDetails(BuildContext context) {
    final media = item.media;
    final tag = 'underrated-${media.id}';
    if (type == ItemType.manga) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MangaDetailsPage(
            media: media,
            tag: tag,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AnimeDetailsPage(
            media: media,
            tag: tag,
          ),
        ),
      );
    }
  }
}
