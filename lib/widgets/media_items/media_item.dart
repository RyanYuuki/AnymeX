import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/models/Anilist/anilist_media_user.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/animation/animations.dart';
import 'package:anymex/widgets/header.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/custom_widgets/custom_textspan.dart';
import 'package:blur/blur.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class CardData {
  String id;
  String title;
  String poster;
  String? episodeCount;
  String? rating;
  String? totalEpisodes;
  String? format;
  String? mediaStatus;
  String? score;
  String? type;
  Media data;
  String? nextEpisode;

  CardData(
      {required this.id,
      required this.title,
      required this.poster,
      this.episodeCount,
      this.rating,
      this.totalEpisodes,
      this.format,
      this.mediaStatus,
      this.score,
      this.type,
      this.nextEpisode,
      required this.data});

  factory CardData.fromTrackedMedia(TrackedMedia data) {
    return CardData(
      id: data.id ?? '',
      title: data.title ?? '',
      poster: data.poster ?? '',
      episodeCount: data.episodeCount,
      rating: data.rating,
      totalEpisodes: data.totalEpisodes ?? '?',
      score: data.score,
      type: data.type,
      data: Media(
          id: data.id!,
          title: data.title ?? '??',
          poster: data.poster ?? '',
          serviceType: data.servicesType),
    );
  }

  factory CardData.fromMedia(Media data) {
    return CardData(
      id: data.id,
      title: data.title,
      poster: data.poster,
      rating: data.rating,
      episodeCount: 'N/A',
      totalEpisodes: data.totalEpisodes,
      nextEpisode: data.nextAiringEpisode?.episode.toString(),
      score: data.rating,
      type: data.type,
      data: data,
    );
  }
}

enum CardVariant {
  search,
  onlinelist,
}

class GridAnimeCard extends StatelessWidget {
  const GridAnimeCard({
    super.key,
    required this.data,
    required this.isManga,
    this.variant,
  });
  final dynamic data;
  final bool isManga;
  final CardVariant? variant;

  @override
  Widget build(BuildContext context) {
    const double cardWidth = 108;
    const double cardHeight = 270;
    final media = data is Media
        ? CardData.fromMedia(data)
        : CardData.fromTrackedMedia(data);
    return SizedBox(
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
                  navigate(() => isManga
                      ? MangaDetailsPage(media: media.data, tag: media.title)
                      : AnimeDetailsPage(media: media.data, tag: media.title));
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
          if (data is Media &&
              ((variant ?? CardVariant.onlinelist) != CardVariant.search))
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isManga ? Iconsax.book : Icons.movie_filter_rounded,
                    color: Colors.grey, size: 16),
                const SizedBox(width: 2),
                AnymexText(
                  text: isManga ? "MANGA" : 'ANIME',
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
          const SizedBox(height: 3),
          if (media.episodeCount != 'N/A')
            SizedBox(
              width: cardWidth,
              child: AnymexTextSpans(
                text: '  |  ~',
                maxLines: 1,
                fontSize: 14,
                spans: [
                  AnymexTextSpan(
                      text: "${media.episodeCount} ",
                      color: Theme.of(context).colorScheme.primary,
                      variant: TextVariant.semiBold),
                  if (media.nextEpisode != null)
                    AnymexTextSpan(
                        text: "| ${media.nextEpisode} ",
                        color: Colors.grey,
                        variant: TextVariant.semiBold),
                  AnymexTextSpan(
                      text:
                          "| ${media.totalEpisodes == '0' ? '?' : media.totalEpisodes} ",
                      color: Colors.grey,
                      variant: TextVariant.semiBold),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEpisodeChip(BuildContext context, CardData media) {
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
            text: media.rating ?? '0.0',
            color: Theme.of(context).colorScheme.onPrimary,
            size: 12,
            variant: TextVariant.bold,
          ),
        ],
      ),
    );
  }
}

class BlurAnimeCard extends StatelessWidget {
  final Media data;

  const BlurAnimeCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final gradientColors = [
      Theme.of(context).colorScheme.surface.withOpacity(0.3),
      Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      Theme.of(context).colorScheme.primaryContainer.withOpacity(0.8),
    ];

    return AnymexOnTap(
      onTap: () {
        navigate(() => AnimeDetailsPage(media: data, tag: data.title));
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          border: Border(
              right: BorderSide(
                  width: 2, color: Theme.of(context).colorScheme.primary)),
          borderRadius: BorderRadius.circular(12.multiplyRadius()),
          color: Theme.of(context).colorScheme.surface.withAlpha(144),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.multiplyRadius()),
          child: Stack(children: [
            // Background image
            Positioned.fill(
              child: NetworkSizedImage(
                imageUrl: data.cover ?? data.poster,
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
                NetworkSizedImage(
                  width: getResponsiveSize(context,
                      mobileSize: 120, desktopSize: 130),
                  height: getResponsiveSize(context,
                      mobileSize: 150, desktopSize: 180),
                  radius: 0,
                  imageUrl: data.poster,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                            height: getResponsiveSize(context,
                                mobileSize: 10, desktopSize: 30)),
                        AnymexText(
                          text: "Episode ${data.nextAiringEpisode!.episode}",
                          size: 14,
                          maxLines: 2,
                          color: Theme.of(context).colorScheme.primary,
                          variant: TextVariant.bold,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        AnymexText(
                          text: data.title,
                          size: 14,
                          maxLines: 2,
                          variant: TextVariant.bold,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              right: 10,
              bottom: 10,
              child: Obx(() {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular((8.multiplyRadius())),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  child: AnymexText(
                    text: '',
                    size: 12,
                    color: Theme.of(context).colorScheme.onPrimary,
                    variant: TextVariant.bold,
                  ),
                );
              }),
            ),
          ]),
        ),
      ),
    );
  }
}
