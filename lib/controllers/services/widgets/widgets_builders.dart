import 'package:anymex/controllers/services/underrated_service.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/big_carousel.dart';
import 'package:anymex/widgets/common/future_reusable_carousel.dart';
import 'package:anymex/widgets/common/reusable_carousel.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:dartotsu_extension_bridge/Models/Source.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
            height: 220,
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

/// Card widget for underrated items with recommendedBy badge and scrolling reason
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

class _UnderratedCardState extends State<_UnderratedCard> {
  late final ScrollController _scrollController;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _startScrolling() {
    if (_scrollController.hasClients && widget.item.reason != null) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      if (maxScroll > 0) {
        _scrollController.animateTo(
          maxScroll,
          duration: Duration(milliseconds: maxScroll.toInt() * 20),
          curve: Curves.linear,
        );
      }
    }
  }

  void _stopScrolling() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = widget.item.media;
    
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovering = true);
        _startScrolling();
      },
      onExit: (_) {
        setState(() => _isHovering = false);
        _stopScrolling();
      },
      child: GestureDetector(
        onTap: () {
          // Navigate to details page
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
        },
        child: Container(
          width: 130,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poster with recommendedBy badge
              Stack(
                children: [
                  // Poster image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      media.poster,
                      width: 130,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 130,
                        height: 180,
                        color: theme.colorScheme.surfaceContainerHigh,
                        child: Icon(
                          widget.type == ItemType.manga
                              ? Icons.book
                              : Icons.movie,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  // Recommended by badge
                  if (widget.item.recommendedBy != null)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '@${widget.item.recommendedBy}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                  // Score badge
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            size: 10,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            media.rating.toString(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Title (scrolling if reason exists)
              if (widget.item.reason != null && widget.item.reason!.isNotEmpty)
                SizedBox(
                  height: 28,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: Text(
                      widget.item.reason!,
                      maxLines: 2,
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                Text(
                  widget.item.displayTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
