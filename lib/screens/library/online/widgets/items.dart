import 'package:anymex/models/Anilist/anilist_media_user.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/utils/string_extensions.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

GestureDetector listItem(BuildContext context, AnilistMediaUser item,
    String tag, posterUrl, List<dynamic> filteredAnimeList, int index) {
  return GestureDetector(
    onTap: () {
      Get.to(() => AnimeDetailsPage(
          anilistId: item.id!, posterUrl: posterUrl, tag: tag));
    },
    child: Column(
      children: [
        Stack(children: [
          Hero(
            tag: tag,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: CachedNetworkImage(
                height: 170,
                width: double.infinity,
                fit: BoxFit.cover,
                imageUrl: posterUrl,
                placeholder: (context, url) => placeHolderWidget(context),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
          ),
          Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomRight: Radius.circular(16))),
                child: Row(
                  children: [
                    Icon(
                      Iconsax.star5,
                      size: 11,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      (item.rating) ?? '0.0',
                      style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.inverseSurface ==
                                  Theme.of(context)
                                      .colorScheme
                                      .onPrimaryFixedVariant
                              ? Colors.black
                              : Theme.of(context)
                                          .colorScheme
                                          .onPrimaryFixedVariant ==
                                      const Color(0xffe2e2e2)
                                  ? Colors.black
                                  : Colors.white),
                    ),
                  ],
                ),
              )),
        ]),
        const SizedBox(height: 7),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title ?? '?',
              maxLines: 2,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (item.episodeCount ?? '?').toString(),
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer),
                ),
                Text(' | ',
                    style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .inverseSurface
                            .withOpacity(0.5))),
                Text(
                  (item.totalEpisodes ?? '?').toString(),
                  style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .inverseSurface
                          .withOpacity(0.5)),
                ),
              ],
            ),
          ],
        )
      ],
    ),
  );
}

GestureDetector listItemDesktop(BuildContext context, AnilistMediaUser item,
    String tag, posterUrl, List<dynamic> filteredAnimeList, int index) {
  return GestureDetector(
    onTap: () {},
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(children: [
          SizedBox(
            height: 200,
            child: Hero(
              tag: tag,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: CachedNetworkImage(
                  fit: BoxFit.cover,
                  imageUrl: posterUrl,
                  placeholder: (context, url) => placeHolderWidget(context),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                  width: double.maxFinite,
                ),
              ),
            ),
          ),
          Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomRight: Radius.circular(16))),
                child: Row(
                  children: [
                    Icon(
                      Iconsax.star5,
                      size: 11,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      ((item.rating?.toDouble() ?? 0) / 10).toString(),
                      style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.inverseSurface ==
                                  Theme.of(context)
                                      .colorScheme
                                      .onPrimaryFixedVariant
                              ? Colors.black
                              : Theme.of(context)
                                          .colorScheme
                                          .onPrimaryFixedVariant ==
                                      const Color(0xffe2e2e2)
                                  ? Colors.black
                                  : Colors.white),
                    ),
                  ],
                ),
              )),
        ]),
        const SizedBox(height: 7),
        Text(
          item.title ?? '?',
          maxLines: 2,
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.episodeCount?.toString() ?? '?',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer),
            ),
            Text(' | ',
                style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .inverseSurface
                        .withOpacity(0.5))),
            Text(
              (item.totalEpisodes ?? '?'),
              style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .inverseSurface
                      .withOpacity(0.5)),
            ),
          ],
        )
      ],
    ),
  );
}
