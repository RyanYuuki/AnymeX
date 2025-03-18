import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Offline/Hive/offline_media.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/anime/watch_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/custom_widgets/custom_expansion_tile.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/header.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:blur/blur.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class AnimeCard extends StatelessWidget {
  final OfflineMedia data;
  final RxInt cardtype;

  const AnimeCard({super.key, required this.data, required this.cardtype});
  @override
  Widget build(BuildContext context) {
    return AnymexOnTap(
      margin: 0,
      scale: 1,
      onTap: () {
        navigate(() => AnimeDetailsPage(
            media: Media.fromOfflineMedia(data, MediaType.anime),
            tag: '${data.id!}${UniqueKey().toString()}'));
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  NetworkSizedImage(
                    imageUrl: data.poster ?? '',
                    radius: 12.multiplyRadius(),
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(10, 4, 5, 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(12.multiplyRadius()),
                        ),
                        color: Theme.of(context).colorScheme.secondaryContainer,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.star5,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 3),
                          AnymexText(
                            text: data.rating ?? '0.0',
                            variant: TextVariant.bold,
                          ),
                          const SizedBox(width: 3),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(10, 4, 5, 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12.multiplyRadius()),
                          bottomRight: Radius.circular(12.multiplyRadius()),
                        ),
                        color: Theme.of(context).colorScheme.secondaryContainer,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.play5,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 3),
                          AnymexText(
                            text: data.currentEpisode?.number ?? '??',
                            variant: TextVariant.bold,
                          ),
                          const SizedBox(width: 3),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              width: double.infinity,
              child: Text(
                data.name ?? '??',
                style: const TextStyle(
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnimeHistoryCard extends StatelessWidget {
  final OfflineMedia data;

  const AnimeHistoryCard({super.key, required this.data});

  String _formatEpisodeNumber() {
    final episode = data.currentEpisode;
    if (episode == null) return 'Episode ??';
    return 'Episode ${episode.number}';
  }

  double _calculateProgress() {
    if (data.currentEpisode?.durationInMilliseconds == null ||
        data.currentEpisode?.timeStampInMilliseconds == null) {
      return 0.0;
    }

    final duration = data.currentEpisode!.durationInMilliseconds ?? 1;
    final timestamp = data.currentEpisode!.timeStampInMilliseconds ?? 0;

    return (timestamp / duration).clamp(0.0, 1.0);
  }

  String _formatTimeLeft() {
    if (data.currentEpisode?.durationInMilliseconds == null ||
        data.currentEpisode?.timeStampInMilliseconds == null) {
      return '--:--';
    }

    final duration = data.currentEpisode!.durationInMilliseconds ?? 0;
    final timestamp = data.currentEpisode!.timeStampInMilliseconds ?? 0;
    final timeLeft = Duration(milliseconds: duration - timestamp);

    String twoDigits(int n) => n.toString().padLeft(2, '0');

    final minutes = twoDigits(timeLeft.inMinutes.remainder(60));
    final seconds = twoDigits(timeLeft.inSeconds.remainder(60));

    return '$minutes:$seconds left';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = _calculateProgress();
    final gradientColors = [
      Theme.of(context).colorScheme.surface.withOpacity(0.3),
      Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      Theme.of(context).colorScheme.primaryContainer.withOpacity(0.8),
    ];

    return AnymexCard(
      shape: RoundedRectangleBorder(
          side: BorderSide(
            color: colorScheme.primary.withOpacity(0.3),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16)),
      color: Theme.of(context).colorScheme.secondaryContainer.withAlpha(120),
      child: AnymexOnTap(
        onTap: () {
          if (data.currentEpisode == null ||
              data.currentEpisode?.currentTrack == null ||
              data.episodes == null ||
              data.currentEpisode?.videoTracks == null) {
            snackBar(
              "Error: Missing required data. It seems you closed the app directly after watching the episode!",
              duration: 2000,
              maxLines: 3,
            );
          } else {
            if (data.currentEpisode?.source == null) {
              snackBar("Cant Play since user closed the app abruptly");
            }
            final source = Get.find<SourceController>()
                .getExtensionByName(data.currentEpisode!.source!);
            if (source == null) {
              snackBar(
                  "Install ${data.currentEpisode?.source} First, Then Click");
            } else {
              navigate(() => WatchPage(
                    episodeSrc: data.currentEpisode!.currentTrack!,
                    episodeList: data.episodes!,
                    anilistData: convertOfflineToMedia(data),
                    currentEpisode: data.currentEpisode!,
                    episodeTracks: data.currentEpisode!.videoTracks!,
                  ));
            }
          }
        },
        child: SizedBox(
          height: getResponsiveSize(context, mobileSize: 140, dektopSize: 180),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(children: [
              Positioned.fill(
                child: NetworkSizedImage(
                  imageUrl: data.currentEpisode?.thumbnail ??
                      data.cover ??
                      data.poster!,
                  radius: 0,
                  width: double.infinity,
                ),
              ),
              Positioned.fill(
                child: Blur(
                  blur: 4,
                  blurColor: Colors.transparent,
                  child: Container(),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: gradientColors)),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: getResponsiveSize(context,
                        mobileSize: 100, dektopSize: 130),
                    height: double.infinity,
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16.multiplyRadius()),
                        bottomLeft: Radius.circular(16.multiplyRadius()),
                      ),
                      child: NetworkSizedImage(
                        imageUrl: data.poster!,
                        width: double.infinity,
                        height: double.infinity,
                        radius: 0,
                      ),
                    ),
                  ),
                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Episode number
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(8.multiplyRadius()),
                              color: colorScheme.primary,
                            ),
                            child: AnymexText(
                              text: _formatEpisodeNumber(),
                              size: 12,
                              variant: TextVariant.bold,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Episode title
                          AnymexText(
                            text:
                                data.currentEpisode?.title ?? data.name ?? '??',
                            size: 15,
                            maxLines: getResponsiveValue(context,
                                mobileValue: 1, desktopValue: 2),
                            variant: TextVariant.bold,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          if (data.name != null &&
                              data.name != data.currentEpisode?.title)
                            AnymexText(
                              text: data.name!,
                              size: 14,
                              maxLines: 1,
                              variant: TextVariant.regular,
                              color: colorScheme.onSurface.withOpacity(0.7),
                              overflow: TextOverflow.ellipsis,
                            ),
                          const Spacer(),
                          // Progress indicator
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  AnymexText(
                                    text: formatTimeAgo(
                                        data.currentEpisode?.lastWatchedTime ??
                                            0),
                                    size: 12,
                                    color:
                                        colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                  AnymexText(
                                    text: _formatTimeLeft(),
                                    size: 12,
                                    color: colorScheme.primary,
                                    variant: TextVariant.bold,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              // Linear progress bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: colorScheme.surfaceVariant,
                                  color: colorScheme.primary,
                                  minHeight: 5,
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
            ]),
          ),
        ),
      ),
    );
  }
}

class AnimeHistoryCardV3 extends StatelessWidget {
  final OfflineMedia data;

  const AnimeHistoryCardV3({super.key, required this.data});

  String _formatEpisodeNumber() {
    final episode = data.currentEpisode;
    if (episode == null) return 'Episode ??';
    return 'Episode ${episode.number}';
  }

  double _calculateProgress() {
    if (data.currentEpisode?.durationInMilliseconds == null ||
        data.currentEpisode?.timeStampInMilliseconds == null) {
      return 0.0;
    }

    final duration = data.currentEpisode!.durationInMilliseconds ?? 1;
    final timestamp = data.currentEpisode!.timeStampInMilliseconds ?? 0;

    return (timestamp / duration).clamp(0.0, 1.0);
  }

  String _formatTimeLeft() {
    if (data.currentEpisode?.durationInMilliseconds == null ||
        data.currentEpisode?.timeStampInMilliseconds == null) {
      return '--:--';
    }

    final duration = data.currentEpisode!.durationInMilliseconds ?? 0;
    final timestamp = data.currentEpisode!.timeStampInMilliseconds ?? 0;
    final timeLeft = Duration(milliseconds: duration - timestamp);

    String twoDigits(int n) => n.toString().padLeft(2, '0');

    final minutes = twoDigits(timeLeft.inMinutes.remainder(60));
    final seconds = twoDigits(timeLeft.inSeconds.remainder(60));

    return '$minutes:$seconds left';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = _calculateProgress();

    return AnymexCard(
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: colorScheme.primary.withOpacity(0.3),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(16.multiplyRadius()),
      ),
      color: colorScheme.secondaryContainer.withAlpha(120),
      child: AnymexOnTap(
        onTap: () {
          if (data.currentEpisode == null ||
              data.currentEpisode?.currentTrack == null ||
              data.episodes == null ||
              data.currentEpisode?.videoTracks == null) {
            snackBar(
              "Error: Missing required data. It seems you closed the app directly after watching the episode!",
              duration: 2000,
              maxLines: 3,
            );
          } else {
            if (data.currentEpisode?.source == null) {
              snackBar("Cant Play since user closed the app abruptly");
            }
            final source = Get.find<SourceController>()
                .getExtensionByName(data.currentEpisode!.source!);
            if (source == null) {
              snackBar(
                  "Install ${data.currentEpisode?.source} First, Then Click");
            } else {
              navigate(() => WatchPage(
                    episodeSrc: data.currentEpisode!.currentTrack!,
                    episodeList: data.episodes!,
                    anilistData: convertOfflineToMedia(data),
                    currentEpisode: data.currentEpisode!,
                    episodeTracks: data.currentEpisode!.videoTracks!,
                  ));
            }
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thumbnail at the top (horizontal)
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.multiplyRadius()),
                topRight: Radius.circular(16.multiplyRadius()),
              ),
              child: NetworkSizedImage(
                imageUrl: data.currentEpisode?.thumbnail ??
                    data.cover ??
                    data.poster!,
                width: double.infinity,
                height: 130,
                radius: 0,
              ),
            ),
            // Info content below the thumbnail
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Episode number and watched time in the same row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(8.multiplyRadius()),
                          color: colorScheme.primary,
                        ),
                        child: AnymexText(
                          text: _formatEpisodeNumber(),
                          size: 12,
                          variant: TextVariant.bold,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(8.multiplyRadius()),
                          color: colorScheme.surfaceVariant,
                        ),
                        child: AnymexText(
                          text: formatTimeAgo(
                              data.currentEpisode?.lastWatchedTime ?? 0),
                          size: 12,
                          variant: TextVariant.regular,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Episode title
                  AnymexText(
                    text: data.currentEpisode?.title ?? '??',
                    size: 15,
                    maxLines: 1,
                    variant: TextVariant.bold,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Anime name if different
                  if (data.name != null &&
                      data.name != data.currentEpisode?.title)
                    AnymexText(
                      text: data.name!,
                      size: 13,
                      maxLines: 1,
                      variant: TextVariant.regular,
                      color: colorScheme.onSurface.withOpacity(0.7),
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 12),
                  // Progress info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Progress bar with flex for size
                      Expanded(
                        flex: 3,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: colorScheme.surfaceVariant,
                            color: colorScheme.primary,
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Time left
                      AnymexText(
                        text: _formatTimeLeft(),
                        size: 12,
                        color: colorScheme.primary,
                        variant: TextVariant.bold,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnimeHistoryCardV2 extends StatelessWidget {
  final OfflineMedia data;

  const AnimeHistoryCardV2({super.key, required this.data});

  String _formatEpisodeNumber() {
    final episode = data.currentEpisode;
    if (episode == null) return 'Episode ??';
    return 'Episode ${episode.number}';
  }

  double _calculateProgress() {
    if (data.currentEpisode?.durationInMilliseconds == null ||
        data.currentEpisode?.timeStampInMilliseconds == null) {
      return 0.0;
    }

    final duration = data.currentEpisode!.durationInMilliseconds ?? 1;
    final timestamp = data.currentEpisode!.timeStampInMilliseconds ?? 0;

    return (timestamp / duration).clamp(0.0, 1.0);
  }

  String _formatTimeLeft() {
    if (data.currentEpisode?.durationInMilliseconds == null ||
        data.currentEpisode?.timeStampInMilliseconds == null) {
      return '--:--';
    }

    final duration = data.currentEpisode!.durationInMilliseconds ?? 0;
    final timestamp = data.currentEpisode!.timeStampInMilliseconds ?? 0;
    final timeLeft = Duration(milliseconds: duration - timestamp);

    String twoDigits(int n) => n.toString().padLeft(2, '0');

    final minutes = twoDigits(timeLeft.inMinutes.remainder(60));
    final seconds = twoDigits(timeLeft.inSeconds.remainder(60));

    return '$minutes:$seconds left';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = _calculateProgress();

    return AnymexCard(
      shape: RoundedRectangleBorder(
          side: BorderSide(
            color: colorScheme.primary.withOpacity(0.3),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16)),
      color: Theme.of(context).colorScheme.secondaryContainer.withAlpha(120),
      child: AnymexOnTap(
        onTap: () {
          if (data.currentEpisode == null ||
              data.currentEpisode?.currentTrack == null ||
              data.episodes == null ||
              data.currentEpisode?.videoTracks == null) {
            snackBar(
              "Error: Missing required data. It seems you closed the app directly after watching the episode!",
              duration: 2000,
              maxLines: 3,
            );
          } else {
            if (data.currentEpisode?.source == null) {
              snackBar("Cant Play since user closed the app abruptly");
            }
            final source = Get.find<SourceController>()
                .getExtensionByName(data.currentEpisode!.source!);
            if (source == null) {
              snackBar(
                  "Install ${data.currentEpisode?.source} First, Then Click");
            } else {
              navigate(() => WatchPage(
                    episodeSrc: data.currentEpisode!.currentTrack!,
                    episodeList: data.episodes!,
                    anilistData: convertOfflineToMedia(data),
                    currentEpisode: data.currentEpisode!,
                    episodeTracks: data.currentEpisode!.videoTracks!,
                  ));
            }
          }
        },
        child: SizedBox(
          height: getResponsiveSize(context, mobileSize: 140, dektopSize: 180),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: getResponsiveSize(context,
                    mobileSize: 100, dektopSize: 130),
                height: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.multiplyRadius()),
                    bottomLeft: Radius.circular(16.multiplyRadius()),
                  ),
                  child: NetworkSizedImage(
                    imageUrl: data.poster!,
                    width: double.infinity,
                    height: double.infinity,
                    radius: 0,
                  ),
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Episode number
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(8.multiplyRadius()),
                          color: colorScheme.primary,
                        ),
                        child: AnymexText(
                          text: _formatEpisodeNumber(),
                          size: 12,
                          variant: TextVariant.bold,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Episode title
                      AnymexText(
                        text: data.currentEpisode?.title ?? data.name ?? '??',
                        size: 15,
                        maxLines: getResponsiveValue(context,
                            mobileValue: 1, desktopValue: 2),
                        variant: TextVariant.bold,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (data.name != null &&
                          data.name != data.currentEpisode?.title)
                        AnymexText(
                          text: data.name!,
                          size: 14,
                          maxLines: 1,
                          variant: TextVariant.regular,
                          color: colorScheme.onSurface.withOpacity(0.7),
                          overflow: TextOverflow.ellipsis,
                        ),
                      const Spacer(),
                      // Progress indicator
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              AnymexText(
                                text: formatTimeAgo(
                                    data.currentEpisode?.lastWatchedTime ?? 0),
                                size: 12,
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                              AnymexText(
                                text: _formatTimeLeft(),
                                size: 12,
                                color: colorScheme.primary,
                                variant: TextVariant.bold,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Linear progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: colorScheme.surfaceVariant,
                              color: colorScheme.primary,
                              minHeight: 5,
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
    );
  }
}
