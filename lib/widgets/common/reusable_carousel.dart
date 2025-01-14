import 'dart:developer';
import 'dart:math' show Random;

import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/models/Carousel/carousel.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/screens/novel/details_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/animation/slide_scale.dart';
import 'package:anymex/widgets/header.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class ReusableCarousel extends StatelessWidget {
  final List<dynamic> data;
  final String title;
  final bool isManga;
  final DataVariant variant;
  const ReusableCarousel(
      {super.key,
      required this.data,
      required this.title,
      this.isManga = false,
      this.variant = DataVariant.regular});

  @override
  Widget build(BuildContext context) {
    if (data == null || data.isEmpty) {
      return const SizedBox.shrink();
    }
    final isDesktop = MediaQuery.of(context).size.width > 600;
    final newData = convertData(data, variant: variant);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20.0),
          child: Text(title,
              style: TextStyle(
                fontFamily: "Poppins-SemiBold",
                fontSize: 18,
                color: Theme.of(context).colorScheme.primary,
              )),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: isDesktop ? 280 : 220,
          child: ListView.builder(
            itemCount: newData.length,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 20),
            itemBuilder: (BuildContext context, int index) {
              final itemData = newData[index];
              final tag = generateTag('${itemData.id}-$index');
              final isMangaAlt = itemData.extraData == "MANGA";

              return Obx(() => GestureDetector(
                    onTap: () {
                      final isMangaPage =
                          (variant == DataVariant.relation && isMangaAlt) ||
                              isManga;

                      final page = variant == DataVariant.extension
                          ? const NovelDetailsPage()
                          : isMangaPage
                              ? MangaDetailsPage(
                                  key: ValueKey(itemData.id),
                                  anilistId: itemData.id!,
                                  tag: tag,
                                  posterUrl: itemData.poster!,
                                )
                              : AnimeDetailsPage(
                                  key: ValueKey(itemData.id),
                                  anilistId: itemData.id!,
                                  tag: tag,
                                  posterUrl: itemData.poster!,
                                );
                      Get.to(() => page, preventDuplicates: false);
                    },
                    child: SlideAndScaleAnimation(
                      initialScale: 0.0,
                      finalScale: 1.0,
                      initialOffset: const Offset(1.0, 0.0),
                      duration: Duration(milliseconds: getAnimationDuration()),
                      child: Container(
                        decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(12.multiplyRoundness())),
                        clipBehavior: Clip.antiAlias,
                        margin: const EdgeInsets.only(right: 10),
                        constraints:
                            BoxConstraints(maxWidth: isDesktop ? 150 : 105),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                Hero(
                                  tag: tag,
                                  child: NetworkSizedImage(
                                      imageUrl: itemData.poster!,
                                      radius: 12.multiplyRoundness(),
                                      height: isDesktop ? 200 : 160,
                                      width: double.infinity),
                                ),
                                _buildExtraData(context, itemData)
                              ],
                            ),
                            const SizedBox(height: 10),
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
                  ));
            },
          ),
        )
      ],
    );
  }

  Positioned _buildExtraData(BuildContext context, CarouselData itemData) {
    return Positioned(
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
              getIcon(variant, itemData.extraData ?? ''),
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 3),
            Text(
              itemData.extraData.toString(),
              style: const TextStyle(
                fontSize: 12,
                fontFamily: "Poppins-Bold",
              ),
            ),
            const SizedBox(width: 3),
          ],
        ),
      ),
    );
  }

  IconData getIcon(DataVariant variant, String extraData) {
    switch (variant) {
      case DataVariant.anilist:
        final icon = isManga ? Iconsax.book : Iconsax.play5;
        return icon;
      case DataVariant.relation:
        final icon = extraData == "MANGA" ? Iconsax.book : Iconsax.play5;
        return icon;
      case DataVariant.extension:
        return Iconsax.status;
      default:
        return Iconsax.star5;
    }
  }
}

String generateTag(String url) {
  final randomNum = Random().nextInt(10000);
  return '$url-$randomNum';
}
