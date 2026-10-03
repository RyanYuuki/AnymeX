import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_expansion_tile.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_linear_indicator.dart';
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
  final DateTime? releaseDate;

  const NewEpisodeReleaseCard({
    super.key,
    required this.media,
    this.watchedEpisode,
    this.latestReleasedEpisode,
    this.releaseDate,
  });

  static DateTime? calculateReleaseDate({
    required Media media,
    int? latestReleasedEpisode,
    DateTime? itemEndDate,
    String? mediaStatus,
  }) {
    if (media.nextAiringEpisode != null &&
        media.nextAiringEpisode!.airingAt > 0) {
      final nextAiringSec = media.nextAiringEpisode!.airingAt;
      final nextAiringDate =
          DateTime.fromMillisecondsSinceEpoch(nextAiringSec * 1000);
      final now = DateTime.now();
      if (nextAiringDate.isBefore(now)) {
        return nextAiringDate;
      }
      final nextEp = media.nextAiringEpisode!.episode;
      final currentEp = latestReleasedEpisode ?? (nextEp - 1);
      final epDiff = (nextEp - currentEp).clamp(0, 52);
      final releasedSec = nextAiringSec - (epDiff * 7 * 86400);
      final date = DateTime.fromMillisecondsSinceEpoch(releasedSec * 1000);
      if (date.isAfter(now)) {
        return date.subtract(const Duration(days: 7));
      }
      return date;
    }
    if (itemEndDate != null) {
      final now = DateTime.now();
      if (itemEndDate.isBefore(now)) {
        return itemEndDate;
      }
    }
    final status = mediaStatus?.toUpperCase();
    final isCompleted = status == 'COMPLETED' || status == 'FINISHED';
    if (!isCompleted && media.createdAt != null) {
      final now = DateTime.now();
      if (media.createdAt!.isBefore(now)) {
        return media.createdAt;
      }
    }
    return null;
  }

  DateTime? _getReleaseDate() {
    if (releaseDate != null) return releaseDate;
    return calculateReleaseDate(
      media: media,
      latestReleasedEpisode: latestReleasedEpisode,
    );
  }

  String? _getReleaseDateText() {
    final releaseDate = _getReleaseDate();
    if (releaseDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final aDate =
        DateTime(releaseDate.year, releaseDate.month, releaseDate.day);
    final diffDays = today.difference(aDate).inDays;

    if (diffDays <= 0) {
      return 'Today';
    } else if (diffDays == 1) {
      return 'Yesterday';
    } else if (diffDays <= 7) {
      return '$diffDays days ago';
    } else if (diffDays < 30) {
      final weeks = diffDays ~/ 7;
      return '$weeks week${weeks == 1 ? '' : 's'} ago';
    } else if (diffDays < 365) {
      final months = diffDays ~/ 30;
      return '$months month${months == 1 ? '' : 's'} ago';
    } else {
      final years = diffDays ~/ 365;
      return '$years year${years == 1 ? '' : 's'} ago';
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
        width: getResponsiveSize(
          context,
          mobileSize: (MediaQuery.sizeOf(context).width * 0.75).clamp(260.0, 310.0),
          desktopSize: 320.0,
        ),
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
            height: 110,
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
                      width: 78,
                      height: 110,
                      radius: 0,
                      fadeInDuration: Duration.zero,
                      fadeOutDuration: Duration.zero,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: AnymeXText(
                                media.displayTitle,
                                size: 13,
                                variant: TextVariant.bold,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                isMarquee: true,
                              ),
                            ),
                            if (_getReleaseDateText() != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest.opaque(0.6),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: AnymeXText(
                                  _getReleaseDateText()!,
                                  size: 9.5,
                                  variant: TextVariant.semiBold,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.opaque(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.play_arrow_rounded,
                                    size: 13,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 2),
                                  AnymeXText(
                                    'EP $latest',
                                    size: 10,
                                    variant: TextVariant.bold,
                                    color: colorScheme.primary,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: colorScheme.error.opaque(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 11,
                                    color: colorScheme.error,
                                  ),
                                  const SizedBox(width: 3),
                                  AnymeXText(
                                    '$behind behind',
                                    size: 10,
                                    variant: TextVariant.bold,
                                    color: colorScheme.error,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnymeXText(
                              'Watched $watched of $latest',
                              size: 10.5,
                              variant: TextVariant.regular,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: AnymeXLinearIndicator(
                                value: latest > 0 ? (watched / latest).clamp(0.0, 1.0) : 0.05,
                                minHeight: 7,
                                color: colorScheme.primary,
                                backgroundColor: colorScheme.onSurface.withOpacity(0.1),
                              ),
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
