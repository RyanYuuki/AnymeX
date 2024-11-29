// ignore_for_file: must_be_immutable

import 'dart:math';

import 'package:anymex/components/android/helper/scroll_helper.dart';
import 'package:anymex/pages/Android/Anime/details_page.dart';
import 'package:anymex/pages/Android/Manga/details_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shimmer/shimmer.dart';
import 'package:transformable_list_view/transformable_list_view.dart';

class HorizontalList extends StatelessWidget {
  dynamic carouselData;
  final String? title;
  final String? tag;
  final bool? detailsPage;
  final bool? secondary;
  final bool isManga;

  HorizontalList({
    super.key,
    this.title,
    this.carouselData,
    this.tag,
    this.secondary = true,
    this.detailsPage = false,
    this.isManga = false,
  });
  final ScrollController scrollController = ScrollController();
  final ScrollDirectionHelper _scrollDirectionHelper = ScrollDirectionHelper();

  @override
  Widget build(BuildContext context) {
    final customScheme = Theme.of(context).colorScheme;
    if (carouselData == null || carouselData!.isEmpty) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder(
      valueListenable: Hive.box('app-data').listenable(),
      builder: (context, Box box, _) {
        final double cardRoundness =
            box.get('cardRoundness', defaultValue: 18.0);

        return normalCard(customScheme, context, cardRoundness);
      },
    );
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

  Column normalCard(
      ColorScheme customScheme, BuildContext context, double cardRoundness) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                  color: customScheme.primary,
                ),
              ),
              secondary!
                  ? Text(
                      isManga ? ' Manga' : ' Animes',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500),
                    )
                  : const SizedBox.shrink(),
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
        const SizedBox(height: 15),
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
              dynamic itemData = detailsPage!
                  ? title!.contains('Related')
                      ? carouselData[index]['node']
                      : carouselData![index]['node']['mediaRecommendation']
                  : carouselData[index];
              final String posterUrl = itemData['coverImage']['large'] ?? '??';
              final String animeTitle = itemData['title']['english'] ??
                  itemData['title']['romaji'] ??
                  '?';
              final random = Random().nextInt(100000);
              final tagg = '${itemData['id']}$tag$random';
              String extraData = itemData?['averageScore'] != null
                  ? (itemData['averageScore'] / 10).toStringAsFixed(1)
                  : '0.0';

              return Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: GestureDetector(
                  onTap: () {
                    bool isTypeManga =
                        itemData['type']?.toString().toLowerCase() == 'manga';

                    if (isTypeManga || (itemData['type'] == null && isManga)) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MangaDetailsPage(
                            id: itemData['id'],
                            posterUrl: posterUrl,
                            tag: tagg,
                          ),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailsPage(
                            id: itemData['id'],
                            posterUrl: posterUrl,
                            tag: tagg,
                          ),
                        ),
                      );
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
                              borderRadius:
                                  BorderRadius.circular(cardRoundness),
                              child: CachedNetworkImage(
                                imageUrl: posterUrl,
                                placeholder: (context, url) =>
                                    Shimmer.fromColors(
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
                                  vertical: 5, horizontal: 8),
                              decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainer,
                                  borderRadius: BorderRadius.only(
                                      topLeft:
                                          Radius.circular(cardRoundness - 5),
                                      bottomRight:
                                          Radius.circular(cardRoundness))),
                              child: Row(
                                children: [
                                  Icon(
                                    Iconsax.star5,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    extraData,
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontFamily: 'Poppins-Bold',
                                        color: Theme.of(context)
                                            .colorScheme
                                            .inverseSurface),
                                  ),
                                ],
                              ),
                            )),
                      ]),
                      const SizedBox(height: 8),
                      Text(
                        animeTitle,
                        style: const TextStyle(
                          fontFamily: 'Poppins-SemiBold',
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
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

  Matrix4 getTransformMatrix(TransformableListItem item) {
    const maxScale = 1;
    const minScale = 0.8;
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
}
