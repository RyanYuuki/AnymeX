import 'package:flutter/material.dart';
import 'package:dartotsu_extension_bridge/Models/Source.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Offline/Hive/offline_media.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/header.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class MediaCard extends StatelessWidget {
  final OfflineMedia data;
  final RxInt cardType;
  final bool isManga;

  const MediaCard(
      {super.key,
      required this.data,
      required this.cardType,
      required this.isManga});
  @override
  Widget build(BuildContext context) {
    final tag = getRandomTag();
    return AnymexOnTap(
      onTap: () => navGate(tag),
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
                  Hero(
                    tag: tag,
                    child: NetworkSizedImage(
                      imageUrl: data.poster ?? '',
                      radius: 12.multiplyRadius(),
                      width: double.infinity,
                      height: double.infinity,
                    ),
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
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.star5,
                            size: 16,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                          const SizedBox(width: 3),
                          AnymexText(
                            text: data.rating ?? '0.0',
                            variant: TextVariant.bold,
                            color: Theme.of(context).colorScheme.onPrimary,
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
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: getExtraData(context)),
                  )
                ],
              ),
            ),
            Container(
              height: 50,
              padding: const EdgeInsets.fromLTRB(6, 8, 0, 0),
              width: double.infinity,
              child: AnymexText(
                text: data.name ?? '??',
                size: 13,
                variant: TextVariant.semiBold,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void navGate(tag) {
    if (isManga) {
      navigate(() => MangaDetailsPage(
          media: Media.fromOfflineMedia(data, ItemType.manga), tag: tag));
    } else {
      navigate(() => AnimeDetailsPage(
          media: Media.fromOfflineMedia(data, ItemType.anime), tag: tag));
    }
  }

  Row getExtraData(BuildContext context) {
    if (isManga) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Iconsax.book,
            size: 16,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          const SizedBox(width: 3),
          AnymexText(
            text: data.currentChapter?.number.toString() ?? '??',
            variant: TextVariant.bold,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          const SizedBox(width: 3),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Iconsax.play5,
            size: 16,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          const SizedBox(width: 3),
          AnymexText(
            text: data.currentEpisode?.number ?? '??',
            variant: TextVariant.bold,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          const SizedBox(width: 3),
        ],
      );
    }
  }
}
