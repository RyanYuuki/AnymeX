import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Offline/Hive/offline_media.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/header.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:dartotsu_extension_bridge/Models/Source.dart';
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
            media: Media.fromOfflineMedia(data, ItemType.anime),
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
