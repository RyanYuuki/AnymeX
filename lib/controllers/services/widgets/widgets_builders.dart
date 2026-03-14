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
            height: cardHeight + 40, // Extra space for reason text
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
class _UnderratedCard extends StatefulWidget {
  final UnderratedMedia item;
  final ItemType type;

  const _UnderratedCard({
    required this.item,
    required this.type,
  });

  @override
  State<_UnderratedCard> createState() => _UnderratedCardState();
}

class _UnderratedCardState extends State<_UnderratedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _marqueeController;
  late Animation<double> _marqueeAnimation;

  @override
  void initState() {
    super.initState();
    _initMarquee();
  }

  void _initMarquee() {
    final reason = widget.item.reason;
    final hasReason = reason != null && reason.isNotEmpty;

    _marqueeController = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: hasReason ? (reason.length * 100).clamp(3000, 15000) : 3000,
      ),
    );

    _marqueeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _marqueeController,
      curve: Curves.linear,
    ));

    // Start scrolling automatically
    if (hasReason) {
      _marqueeController.repeat();
    }
  }

  @override
  void dispose() {
    _marqueeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 600;
    final cardWidth = isDesktop ? 160.0 : 118.0;
    final carouselData = widget.item.toCarouselData(isManga: widget.type == ItemType.manga);
    final tag = 'underrated-${carouselData.id}-${widget.item.media.hashCode}';

    return GestureDetector(
      onTap: () => _navigateToDetails(context),
      child: SizedBox(
        width: cardWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card with MediaCardGate (same as other sections)
            Expanded(
              child: Stack(
                children: [
                  // Use the same card system as the rest of the app
                  MediaCardGate(
                    itemData: carouselData,
                    tag: tag,
                    variant: DataVariant.underrated,
                    cardStyle: CardStyle.values[settingsController.cardStyle],
                    type: widget.type,
                  ),
                  // Recommended by badge (overlay on top-left)
                  if (widget.item.recommendedBy != null &&
                      widget.item.recommendedBy!.isNotEmpty)
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
                              '@${widget.item.recommendedBy}',
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
            // Scrolling reason text (always scrolls automatically)
            if (widget.item.reason != null && widget.item.reason!.isNotEmpty)
              _buildScrollingReason(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollingReason(ThemeData theme) {
    final reason = widget.item.reason!;
    final textWidth = reason.length * 6.0; // Approximate text width

    return Container(
      height: 16,
      margin: const EdgeInsets.only(top: 4),
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _marqueeAnimation,
          builder: (context, child) {
            // Scroll from left to right (text moves right)
            return Transform.translate(
              offset: Offset(
                -textWidth + (textWidth * 2 * _marqueeAnimation.value),
                0,
              ),
              child: Row(
                children: [
                  Text(
                    reason,
                    style: TextStyle(
                      fontSize: 9,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 80), // Gap between repeats
                  Text(
                    reason,
                    style: TextStyle(
                      fontSize: 9,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _navigateToDetails(BuildContext context) {
    final media = widget.item.media;
    final tag = 'underrated-${media.id}';
    if (widget.type == ItemType.manga) {
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
