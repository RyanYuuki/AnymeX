import 'package:anymex/controllers/Settings/methods.dart';
import 'package:anymex/models/Anilist/anilist_media_user.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/widgets/animation/slide_scale.dart';
import 'package:anymex/widgets/common/reusable_carousel.dart';
import 'package:anymex/widgets/header.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconsax/iconsax.dart';

class AnilistMediaCarousel extends StatelessWidget {
  final List<AnilistMediaUser> data;
  final String title;
  final bool isManga;
  const AnilistMediaCarousel(
      {super.key,
      required this.data,
      required this.title,
      this.isManga = false});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20.0),
          child: Text(title,
              style: TextStyle(
                  fontFamily: "Poppins-SemiBold",
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.primary)),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: isDesktop ? 280 : 220,
          child: ListView.builder(
            itemCount: data.length,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 20),
            itemBuilder: (BuildContext context, int index) {
              final itemData = data[index];
              final tag = generateTag('${itemData.id}-$index');

              return Obx(() {
                return GestureDetector(
                  onTap: () {
                    if (isManga) {
                      Get.to(() => const MangaDetailsPage());
                    } else {
                      Get.to(() => AnimeDetailsPage(
                            anilistId: itemData.id!,
                            tag: tag,
                            posterUrl: itemData.poster!,
                          ));
                    }
                  },
                  child: SlideAndScaleAnimation(
                    initialScale: 0.0,
                    finalScale: 1.0,
                    initialOffset: const Offset(1.0, 0.0),
                    duration: Duration(milliseconds: getAnimationDuration()),
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(16.multiplyRadius())),
                      margin: const EdgeInsets.only(right: 10),
                      clipBehavior: Clip.antiAlias,
                      constraints: BoxConstraints(
                        maxWidth: isDesktop ? 150 : 110,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              Hero(
                                tag: tag,
                                child: NetworkSizedImage(
                                    imageUrl: itemData.poster!,
                                    radius: 16.multiplyRadius(),
                                    height: isDesktop ? 200 : 155,
                                    width: double.infinity),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(10, 4, 5, 2),
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      bottomRight: Radius.circular(12),
                                    ),
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainer,
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Icon(
                                        isManga
                                            ? HugeIcons.strokeRoundedBook04
                                            : Iconsax.play5,
                                        size: 16,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        itemData.episodeCount ??
                                            itemData.chapterCount ??
                                            '0',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontFamily: "Poppins-Bold",
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            itemData.title ?? '?',
                            maxLines: 2,
                            style: TextStyle(
                                fontSize: isDesktop ? 14 : 12,
                                fontFamily: "Poppins-SemiBold"),
                            overflow: TextOverflow.ellipsis,
                          )
                        ],
                      ),
                    ),
                  ),
                );
              });
            },
          ),
        ),
      ],
    );
  }
}
