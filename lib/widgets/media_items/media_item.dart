import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/models/Anilist/anilist_media_user.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/screens/novel/details/details_view.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/media_items/media_peek_popup.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:blur/blur.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/models/models_convertor/carousel/carousel_data.dart';
import 'package:anymex/widgets/common/cards/card_gate.dart';
import 'package:anymex/widgets/common/cards/media_cards.dart';

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
          romajiTitle: data.romajiTitle ?? '',
          rating: data.rating ?? '',
          poster: data.poster ?? '',
          mediaType: data.type == 'MANGA' ? ItemType.manga : ItemType.anime,
          serviceType: data.servicesType),
    );
  }

  factory CardData.fromMedia(Media data) {
    return CardData(
      id: data.id,
      title: data.displayTitle,
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
    this.type,
    this.tagPrefix,
  });
  final dynamic data;
  final bool isManga;
  final CardVariant? variant;
  final ItemType? type;
  final String? tagPrefix;

  @override
  Widget build(BuildContext context) {
    registerBuiltInMediaCardStyles();
    
    final media = data is Media
        ? CardData.fromMedia(data)
        : CardData.fromTrackedMedia(data);
    final itemType = type ?? (isManga ? ItemType.manga : ItemType.anime);

    final isOnlineList = variant == CardVariant.onlinelist;
    final extraData = isOnlineList
        ? "${media.episodeCount ?? '??'} | ${media.totalEpisodes ?? '??'}"
        : (media.score ?? media.rating ?? '');

    final carouselData = CarouselData(
      id: media.id,
      title: media.title,
      poster: media.poster,
      extraData: extraData,
      source: (media.data.sourceId != null && media.data.sourceId != 'N/A')
          ? media.data.sourceId
          : (media.episodeCount ?? '?'),
      releasing: media.mediaStatus == "RELEASING",
      servicesType: media.data.serviceType,
    );

    final prefix = tagPrefix != null ? '${tagPrefix!}-' : '';
    final heroTag = '$prefix${media.id}-${itemType.name}-grid-card';

    final cardWidget = MediaCardGate(
      itemData: carouselData,
      tag: heroTag,
      variant: variant == CardVariant.search
          ? DataVariant.regular
          : (isOnlineList ? DataVariant.anilist : DataVariant.library),
      type: itemType,
    );

    return GestureDetector(
      onSecondaryTap: () {
        MediaPeekPopup.showIfUntracked(
          context,
          media.data,
          itemType,
          media.title,
        );
      },
      onLongPress: () {
        MediaPeekPopup.showIfUntracked(
          context,
          media.data,
          itemType,
          media.title,
        );
      },
      child: AnymexOnTap(
        margin: 0,
        onTap: () {
          if (itemType == ItemType.novel) {
            final sourceController = Get.find<SourceController>();
            var novSource = sourceController.getNovelExtensionByName(media.data.season);
            novSource ??= sourceController.activeNovelSource.value ??
                sourceController.installedNovelExtensions.firstOrNull;
            if (novSource != null) {
              final Source activeSource = novSource;
              navigate(() => NovelDetailsPage(
                    media: media.data,
                    tag: heroTag,
                    source: activeSource,
                  ));
            }
          } else if (itemType == ItemType.manga) {
            navigate(() => MangaDetailsPage(media: media.data, tag: heroTag));
          } else {
            navigate(() => AnimeDetailsPage(media: media.data, tag: heroTag));
          }
        },
        child: cardWidget,
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
      context.colors.surface.opaque(0.3),
      context.colors.primaryContainer.opaque(0.3),
      context.colors.primaryContainer.opaque(0.8),
    ];

    return AnymexOnTap(
      onTap: () {
        navigate(() => AnimeDetailsPage(media: data, tag: data.title));
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          border: Border(
              right: BorderSide(width: 2, color: context.colors.primary)),
          borderRadius: BorderRadius.circular(12.multiplyRadius()),
          color: context.colors.surface.withAlpha(144),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.multiplyRadius()),
          child: Stack(children: [
            // Background image
            Positioned.fill(
              child: AnymeXImage(
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
                AnymeXImage(
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
                        AnymeXText("Episode ${data.nextAiringEpisode!.episode}",
                          size: 14,
                          maxLines: 2,
                          color: context.colors.primary,
                          variant: TextVariant.bold,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        AnymeXText(data.title,
                          size: 14,
                          maxLines: 2,
                          variant: TextVariant.bold,
                          isMarquee: true,
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
                    color: context.colors.primary,
                  ),
                  child: AnymeXText('',
                    size: 12,
                    color: context.colors.onPrimary,
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
