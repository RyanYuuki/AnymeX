import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/models_convertor/carousel/carousel_data.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/screens/other_features.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/cards/base_card.dart';
import 'package:anymex/widgets/common/cards/card_gate.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/media_items/media_peek_popup.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MediaSeeAllPage extends StatefulWidget {
  final String title;
  final List<dynamic> dataList;
  final RxList<Media>? mediaList;
  final ItemType type;
  final DataVariant variant;
  final VoidCallback? onRefresh;

  const MediaSeeAllPage({
    super.key,
    required this.title,
    required this.dataList,
    this.mediaList,
    required this.type,
    this.variant = DataVariant.regular,
    this.onRefresh,
  });

  @override
  State<MediaSeeAllPage> createState() => _MediaSeeAllPageState();
}

class _MediaSeeAllPageState extends State<MediaSeeAllPage> {
  bool _isRefreshing = false;

  void _handleRefresh() {
    if (widget.onRefresh == null) return;
    setState(() => _isRefreshing = true);
    widget.onRefresh!();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _isRefreshing = false);
    });
  }

  void _navigateToDetails(CarouselData itemData) {
    final media = Media.fromCarouselData(itemData, widget.type);
    final tag = 'see-all-${media.id}';
    if (widget.type == ItemType.manga) {
      navigate(() => MangaDetailsPage(media: media, tag: tag));
    } else {
      navigate(() => AnimeDetailsPage(media: media, tag: tag));
    }
  }

  void _showPeekPopup(BuildContext context, CarouselData itemData) {
    final media = Media.fromCarouselData(itemData, widget.type);
    final tag = 'see-all-${media.id}';
    MediaPeekPopup.show(context, media, widget.type, tag);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = getPlatform(context);

    return Glow(
      child: Scaffold(
        body: Column(
          children: [
            NestedHeader(
              title: widget.title,
              action: widget.onRefresh != null
                  ? IconButton(
                      onPressed: _isRefreshing ? null : _handleRefresh,
                      icon: _isRefreshing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.refresh_rounded),
                    )
                  : null,
            ),
            Expanded(
              child: Obx(() {
                final List<dynamic> rawData;
                if (widget.mediaList != null) {
                  rawData = widget.mediaList!.toList();
                } else {
                  rawData = widget.dataList;
                }

                if (rawData.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded,
                            size: 48,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withOpacity(0.5)),
                        const SizedBox(height: 12),
                        Text('No results found',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withOpacity(0.7),
                              fontFamily: 'Poppins-SemiBold',
                            )),
                      ],
                    ),
                  );
                }

                final processedData = convertData(rawData,
                    variant: widget.variant, isManga: widget.type == ItemType.manga);
                final cardStyle =
                    CardStyle.values[settingsController.cardStyle];
                final cardHeight = getCardHeight(cardStyle, isDesktop);
                final crossAxisCount = isDesktop ? 5 : 3;

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    mainAxisExtent: cardHeight,
                  ),
                  itemCount: processedData.length,
                  itemBuilder: (context, index) {
                    final carouselData = processedData[index];
                    final tag =
                        'see-all-${carouselData.id}-${carouselData.hashCode}';

                    return GestureDetector(
                      onTap: () => _navigateToDetails(carouselData),
                      onLongPress: () =>
                          _showPeekPopup(context, carouselData),
                      child: MediaCardGate(
                        itemData: carouselData,
                        tag: tag,
                        variant: widget.variant,
                        cardStyle: cardStyle,
                        type: widget.type,
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
