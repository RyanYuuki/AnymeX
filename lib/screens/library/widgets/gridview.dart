import 'package:anymex/controllers/settingss/methods.dart';
import 'package:anymex/models/Offline/Hive/offline_media.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/widgets/animation/slide_scale.dart';
import 'package:anymex/widgets/header.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';

class GridContent extends StatelessWidget {
  final String title;
  final List<OfflineMedia> data;
  final bool isAnime;

  const GridContent(
      {super.key,
      required this.title,
      required this.data,
      this.isAnime = true});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(10.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount:
              getResponsiveValue(context, mobileValue: 3, desktopValue: 8),
          crossAxisSpacing: 10.0,
          mainAxisSpacing: 30.0,
          mainAxisExtent:
              getResponsiveSize(context, mobileSize: 220, dektopSize: 280)),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];

        return SlideAndScaleAnimation(
          initialScale: 0.0,
          finalScale: 1.0,
          initialOffset: const Offset(1.0, 0.0),
          duration: Duration(milliseconds: getAnimationDuration()),
          child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.multiplyRoundness())),
            margin: const EdgeInsets.only(right: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  fit: StackFit.loose,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (isAnime) {
                          Get.to(() => AnimeDetailsPage(
                              anilistId: item.id.toString(),
                              posterUrl: item.poster!,
                              tag: ''));
                        }
                      },
                      child: NetworkSizedImage(
                        imageUrl: item.poster!,
                        radius: 16.multiplyRoundness(),
                        width: double.infinity,
                        height: getResponsiveSize(context,
                            mobileSize: 155, dektopSize: 200),
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
                          color:
                              Theme.of(context).colorScheme.secondaryContainer,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              isAnime ? IconlyBold.play : Iconsax.book,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              (isAnime
                                      ? item.currentEpisode?.number.toString()
                                      : item.currentChapter?.number
                                          ?.toStringAsFixed(0)) ??
                                  '?',
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
                  item.name ?? '?',
                  maxLines: 2,
                  style: const TextStyle(
                      fontSize: 14, fontFamily: "Poppins-SemiBold"),
                  overflow: TextOverflow.ellipsis,
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
