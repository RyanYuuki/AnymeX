import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_expansion_tile.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:anymex/utils/theme_extensions.dart';

class RecentlyOpenedAnimeCard extends StatelessWidget {
  final Media media;
  final int? watchedEpisode;
  final int? latestReleasedEpisode;

  const RecentlyOpenedAnimeCard({
    super.key,
    required this.media,
    this.watchedEpisode,
    this.latestReleasedEpisode,
  });

  String _getTimeAgo() {
    if (media.createdAt == null) return 'Recently';
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
    final colorScheme = context.colors;
    final heroTag =
        '${media.id}-recent-${media.createdAt?.millisecondsSinceEpoch ?? ''}';
    final hasNewEpisode = latestReleasedEpisode != null &&
        watchedEpisode != null &&
        latestReleasedEpisode! > watchedEpisode!;

    return AnymexOnTap(
      onTap: () {
        navigate(() => AnimeDetailsPage(media: media, tag: heroTag));
      },
      child: Container(
        margin: const EdgeInsets.only(left: 15),
        width: getResponsiveSize(context,
            mobileSize: MediaQuery.sizeOf(context).width / 1.45,
            desktopSize: MediaQuery.sizeOf(context).width / 3),
        child: AnymeXCard(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: colorScheme.primary.opaque(0.2),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12.multiplyRadius()),
          ),
          color: colorScheme.secondaryContainer.withAlpha(100),
          child: SizedBox(
            height: 100,
            child: Row(
              children: [
                Hero(
                  tag: heroTag,
                  transitionOnUserGestures: true,
                  flightShuttleBuilder: AnymeXImage.heroFlightShuttleBuilder,
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12.multiplyRadius()),
                      bottomLeft: Radius.circular(12.multiplyRadius()),
                    ),
                    child: AnymeXImage(
                      imageUrl: media.poster,
                      width: 80,
                      height: 100,
                      radius: 0,
                      fadeInDuration: Duration.zero,
                      fadeOutDuration: Duration.zero,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: AnymeXText(
                                    media.displayTitle,
                                    size: 13.5,
                                    variant: TextVariant.bold,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    isMarquee: true,
                                  ),
                                ),
                                if (media.rating != '?') ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 2),
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
                                          size: 11,
                                        ),
                                        const SizedBox(width: 2),
                                        AnymeXText(
                                          media.rating,
                                          color: colorScheme.onPrimary,
                                          size: 10.5,
                                          variant: TextVariant.bold,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 5),
                            if (hasNewEpisode)
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: colorScheme.secondary,
                                      borderRadius:
                                          const BorderRadius.horizontal(
                                        left: Radius.circular(6),
                                        right: Radius.circular(3),
                                      ),
                                    ),
                                    child: AnymeXText(
                                      'NEW EP',
                                      style: TextStyle(
                                        fontFamily: 'Poppins-SemiBold',
                                        fontSize: 9.5,
                                        color: colorScheme.secondary
                                                    .computeLuminance() >
                                                0.5
                                            ? Colors.black
                                            : Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: colorScheme.tertiary,
                                      borderRadius:
                                          const BorderRadius.horizontal(
                                        left: Radius.circular(3),
                                        right: Radius.circular(6),
                                      ),
                                    ),
                                    child: AnymeXText(
                                      'EP $latestReleasedEpisode',
                                      style: TextStyle(
                                        fontFamily: 'Poppins-SemiBold',
                                        fontSize: 9.5,
                                        color: colorScheme.tertiary
                                                    .computeLuminance() >
                                                0.5
                                            ? Colors.black
                                            : Colors.white,
                                      ),
                                    ),
                                  ),
                                  if ((latestReleasedEpisode! -
                                          watchedEpisode!) >
                                      1) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary.opaque(0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: AnymeXText(
                                        '+${latestReleasedEpisode! - watchedEpisode!} new',
                                        size: 9.5,
                                        variant: TextVariant.bold,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ],
                              )
                            else if (media.format.isNotEmpty &&
                                media.format != '?')
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(
                                      4.multiplyRadius()),
                                ),
                                child: AnymeXText(
                                  media.format.toUpperCase(),
                                  size: 9.5,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                        if (hasNewEpisode)
                          AnymeXText(
                            'Watched Ep $watchedEpisode • Ep $latestReleasedEpisode Out',
                            size: 11,
                            color: colorScheme.onSurfaceVariant,
                            variant: TextVariant.regular,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        else
                          AnymeXText(
                            media.createdAt != null
                                ? 'Opened ${_getTimeAgo()}'
                                : 'Anime',
                            size: 11,
                            color: colorScheme.onSurfaceVariant,
                            variant: TextVariant.regular,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
