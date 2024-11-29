// ignore_for_file: camel_case_types, use_build_context_synchronously, must_be_immutable
import 'dart:math';
import 'package:anymex/components/android/helper/scroll_helper.dart';
import 'package:anymex/pages/Android/Anime/details_page.dart';
import 'package:anymex/pages/Android/Manga/details_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:transformable_list_view/transformable_list_view.dart';

class DesktopAnilistCarousel extends StatelessWidget {
  final List<dynamic>? carouselData;
  final String? title;
  final String? tag;
  bool isManga;
  DesktopAnilistCarousel(
      {super.key,
      this.title,
      this.carouselData,
      this.tag,
      this.isManga = false});
  final ScrollController scrollController = ScrollController();

  final ScrollDirectionHelper _scrollDirectionHelper = ScrollDirectionHelper();

  @override
  Widget build(BuildContext context) {
    if (carouselData == null || carouselData!.isEmpty) {
      return const SizedBox.shrink();
    }

    Matrix4 getTransformMatrix(TransformableListItem item) {
      const maxScale = 1;
      const minScale = 0.9;
      final viewportWidth = item.constraints.viewportMainAxisExtent;
      final itemLeftEdge = item.offset.dx;
      final itemRightEdge = item.offset.dx + item.size.width;

      bool isScrollingRight =
          _scrollDirectionHelper.isScrollingRight(item.offset);

      double visiblePortion;
      if (isScrollingRight) {
        visiblePortion = (viewportWidth - itemLeftEdge) / item.size.width;
      } else {
        visiblePortion = (itemRightEdge) / item.size.width;
      }

      if ((isScrollingRight && itemLeftEdge < viewportWidth) ||
          (!isScrollingRight && itemRightEdge > 0)) {
        const scaleRange = maxScale - minScale;
        final scale =
            minScale + (scaleRange * visiblePortion).clamp(0.0, scaleRange);

        return Matrix4.identity()
          ..translate(item.size.width / 2, 0, 0)
          ..scale(scale)
          ..translate(-item.size.width / 2, 0, 0);
      }

      return Matrix4.identity();
    }

    void slideCarousel(bool left) {
      final maxScrollExtent = scrollController.position.maxScrollExtent;
      final currentOffset = scrollController.offset;
      const scrollAmount = 500.0;

      if (left && currentOffset > 0) {
        scrollController.animateTo(
          (currentOffset - scrollAmount).clamp(0.0, maxScrollExtent),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      } else if (!left && currentOffset < maxScrollExtent) {
        scrollController.animateTo(
          (currentOffset + scrollAmount).clamp(0.0, maxScrollExtent),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: [
              Text(
                title ?? '??',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const Expanded(child: SizedBox.shrink()),
              IconButton(
                onPressed: () => slideCarousel(true),
                icon: const Icon(Icons.arrow_left),
              ),
              IconButton(
                onPressed: () => slideCarousel(false),
                icon: const Icon(Icons.arrow_right),
              )
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 260,
          child: TransformableListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.only(left: 20),
            physics: const BouncingScrollPhysics(
                decelerationRate: ScrollDecelerationRate.fast),
            getTransformMatrix: getTransformMatrix,
            scrollDirection: Axis.horizontal,
            itemCount: carouselData!.length,
            itemExtent: 160,
            itemBuilder: (context, index) {
              final itemData = carouselData?[index]['media'];
              final String posterUrl = itemData?['coverImage']?['large'] ??
                  'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx16498-73IhOXpJZiMF.jpg';
              int random = Random().nextInt(100000);
              final tagg = '$random$index';
              const String proxyUrl = '';
              dynamic extraData =
                  '${isManga ? 'Chapter' : 'Episode'} ${carouselData?[index]?['progress']?.toString() ?? '?'}';
              '1';
              return Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: GestureDetector(
                  onTap: () {
                    if (isManga) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => MangaDetailsPage(
                                    id: itemData['id'],
                                    tag: tagg,
                                    posterUrl: proxyUrl + posterUrl,
                                  )));
                    } else {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => DetailsPage(
                                    id: itemData['id'],
                                    tag: tagg,
                                    posterUrl: proxyUrl + posterUrl,
                                  )));
                    }
                  },
                  child: Column(
                    children: [
                      Stack(children: [
                        SizedBox(
                          height: 200,
                          child: Hero(
                            tag: tagg,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: CachedNetworkImage(
                                imageUrl: proxyUrl + posterUrl,
                                placeholder: (context, url) => Shimmer.fromColors(
                                  baseColor: Colors.grey[900]!,
                                  highlightColor: Colors.grey[700]!,
                                  child: Container(
                                    color: Colors.grey[900],
                                    width: double.infinity,
                                  ),
                                ),
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 6, horizontal: 12),
                              decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainer,
                                  borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(18),
                                      bottomRight: Radius.circular(16))),
                              child: Text(
                                extraData,
                                style: TextStyle(
                                    fontFamily: 'Poppins-SemiBold',
                                    fontSize: 11,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .inverseSurface),
                              ),
                            )),
                      ]),
                      const SizedBox(height: 10),
                      Text(
                        itemData?['title']?['english'] ??
                            itemData?['title']?['romaji'] ??
                            '?',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.inverseSurface,
                          fontSize: 13,
                          fontFamily: 'Poppins-SemiBold',
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
