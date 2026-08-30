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

class NewEpisodeReleaseCard extends StatelessWidget {
  final Media media;
  final int? watchedEpisode;
  final int? latestReleasedEpisode;

  const NewEpisodeReleaseCard({
    super.key,
    required this.media,
    this.watchedEpisode,
    this.latestReleasedEpisode,
  });

  String _getTimeAgo() {
    if (media.createdAt == null) return 'Recently';
    final now = DateTime.now();
    final difference = now.difference(media.createdAt!);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = difference.inDays ~/ 7;
      return '$weeks week${weeks == 1 ? '' : 's'} ago';
    } else {
      return 'Recently';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    final heroTag =
        '${media.id}-recent-${media.createdAt?.millisecondsSinceEpoch ?? ''}';
    final watched = watchedEpisode ?? 0;
    final latest = latestReleasedEpisode ?? watched;
    final behind = latest - watched;

    return AnymexOnTap(
      onTap: () {
        navigate(() => AnimeDetailsPage(media: media, tag: heroTag));
      },
      child: Container(
        margin: const EdgeInsets.only(left: 15),
        width: getResponsiveSize(context,
            mobileSize: MediaQuery.sizeOf(context).width / 1.15,
            desktopSize: MediaQuery.sizeOf(context).width / 2.5),
        child: AnymeXCard(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: colorScheme.primary.opaque(0.2),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(14.multiplyRadius()),
          ),
          color: colorScheme.secondaryContainer.withAlpha(100),
          child: SizedBox(
            height: 155,
            child: Row(
              children: [
                Hero(
                  tag: heroTag,
                  transitionOnUserGestures: true,
                  flightShuttleBuilder: AnymeXImage.heroFlightShuttleBuilder,
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(14.multiplyRadius()),
                      bottomLeft: Radius.circular(14.multiplyRadius()),
                    ),
                    child: AnymeXImage(
                      imageUrl: media.poster,
                      width: 105,
                      height: 155,
                      radius: 0,
                      fadeInDuration: Duration.zero,
                      fadeOutDuration: Duration.zero,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AnymeXText(
                          media.displayTitle.toUpperCase(),
                          size: 15.5,
                          variant: TextVariant.bold,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          isMarquee: true,
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: colorScheme.secondary.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    size: 12,
                                    color: colorScheme.secondary,
                                  ),
                                  const SizedBox(width: 4),
                                  AnymeXText(
                                    'NEW EPISODE',
                                    size: 10.5,
                                    variant: TextVariant.bold,
                                    color: colorScheme.secondary,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.play_arrow_rounded,
                                    size: 14,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 2),
                                  AnymeXText(
                                    'EPISODE $latest',
                                    size: 10.5,
                                    variant: TextVariant.bold,
                                    color: colorScheme.primary,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 13,
                                  color: colorScheme.onSurfaceVariant
                                      .withOpacity(0.7),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: AnymeXText(
                                    'Watched up to episode $watched',
                                    size: 11.5,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 13,
                                  color: colorScheme.onSurfaceVariant
                                      .withOpacity(0.7),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: AnymeXText(
                                    '$behind episode${behind == 1 ? '' : 's'} behind',
                                    size: 11.5,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Icon(
                                  Icons.newspaper_outlined,
                                  size: 13,
                                  color: colorScheme.onSurfaceVariant
                                      .withOpacity(0.7),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: AnymeXText(
                                    'Released ${_getTimeAgo()}',
                                    size: 11.5,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
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

typedef RecentlyOpenedAnimeCard = NewEpisodeReleaseCard;
