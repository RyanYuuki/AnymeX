import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/custom_widgets/custom_expansion_tile.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/header.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:flutter/material.dart';

class RecentlyOpenedAnimeCard extends StatelessWidget {
  final Media media;

  const RecentlyOpenedAnimeCard({
    super.key,
    required this.media,
  });

  String _getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(media.createdAt!);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnymexOnTap(
      onTap: () {
        if (serviceHandler.serviceType.value == ServicesType.simkl) {
          navigate(() =>
              AnimeDetailsPage(media: media, tag: media.createdAt.toString()));
          return;
        }
        if (media.type == "ANIME") {
          navigate(() =>
              AnimeDetailsPage(media: media, tag: media.createdAt.toString()));
        } else {
          navigate(() =>
              MangaDetailsPage(media: media, tag: media.createdAt.toString()));
        }
      },
      child: Container(
        margin: const EdgeInsets.only(left: 15),
        width: getResponsiveSize(context,
            mobileSize: MediaQuery.of(context).size.width / 1.5,
            desktopSize: MediaQuery.of(context).size.width / 3),
        child: AnymexCard(
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: colorScheme.primary.withOpacity(0.2),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12.multiplyRadius()),
          ),
          color: colorScheme.secondaryContainer.withAlpha(100),
          child: SizedBox(
            height: 100,
            child: Row(
              children: [
                // Poster image
                Hero(
                  tag: media.createdAt.toString(),
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12.multiplyRadius()),
                      bottomLeft: Radius.circular(12.multiplyRadius()),
                    ),
                    child: NetworkSizedImage(
                      imageUrl: media.poster,
                      width: 80,
                      height: 100,
                      radius: 0,
                    ),
                  ),
                ),

                // Content
                Expanded(
                  child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Title row
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: AnymexText(
                                        text: media.title,
                                        size: 14,
                                        variant: TextVariant.bold,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (media.rating != '?') ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: colorScheme.primary,
                                          borderRadius: BorderRadius.circular(
                                              6.multiplyRadius()),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.star,
                                              color: colorScheme.onPrimary,
                                              size: 12,
                                            ),
                                            const SizedBox(width: 2),
                                            AnymexText(
                                              text: media.rating,
                                              color: colorScheme.onPrimary,
                                              size: 11,
                                              variant: TextVariant.bold,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),

                                const SizedBox(height: 4),

                                // Time opened and type/format badge
                                Row(
                                  children: [
                                    // Time opened text
                                    Expanded(
                                      child: AnymexText(
                                        text: 'Opened ${_getTimeAgo()}',
                                        size: 11,
                                        color: colorScheme.onSurfaceVariant,
                                        variant: TextVariant.regular,
                                      ),
                                    ),

                                    // Type badge (Anime, Movie, etc)
                                    if (media.format != '?') ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: colorScheme
                                              .surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(
                                              4.multiplyRadius()),
                                        ),
                                        child: AnymexText(
                                          text: media.format.toUpperCase(),
                                          size: 10,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
