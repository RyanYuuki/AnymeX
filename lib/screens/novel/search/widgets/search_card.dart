import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/novel/details/details_view.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/animation/animations.dart';
import 'package:anymex/widgets/header.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class GridNovelCard extends StatelessWidget {
  const GridNovelCard({super.key, required this.data, this.source});
  final DMedia data;
  final Source? source;

  @override
  Widget build(BuildContext context) {
    const double cardWidth = 108;
    const double cardHeight = 270;
    final media = Media.fromDManga(data, ItemType.novel);
    return StaggeredAnimatedItemWrapper(
      index: 2,
      child: SizedBox(
        width: cardWidth,
        height: cardHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              children: [
                AnymexOnTap(
                  margin: 0,
                  onTap: () {
                    navigate(() {
                      NovelDetailsPage(
                          media: media, tag: media.title, source: source!);
                    });
                  },
                  child: Hero(
                    tag: media.title,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: NetworkSizedImage(
                        radius: 12,
                        imageUrl: media.poster,
                        width: cardWidth,
                        height: 160,
                        errorImage:
                            'https://s4.anilist.co/file/anilistcdn/character/large/default.jpg',
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: _buildEpisodeChip(context, media),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Iconsax.book, color: Colors.grey, size: 16),
                const SizedBox(width: 2),
                AnymexText(
                  text: media.title.toUpperCase(),
                  maxLines: 1,
                  variant: TextVariant.regular,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                  size: 12,
                ),
              ],
            ),
            const SizedBox(height: 5),
            SizedBox(
              width: cardWidth,
              child: AnymexText(
                text: media.title,
                maxLines: 2,
                size: 14,
                variant: TextVariant.semiBold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEpisodeChip(BuildContext context, Media media) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Iconsax.star5,
            size: 16,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          const SizedBox(width: 4),
          AnymexText(
            text: media.rating,
            color: Theme.of(context).colorScheme.onPrimary,
            size: 12,
            variant: TextVariant.bold,
          ),
        ],
      ),
    );
  }
}
