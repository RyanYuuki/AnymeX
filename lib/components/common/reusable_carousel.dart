// ignore_for_file: must_be_immutable

import 'dart:math';

import 'package:aurora/components/helper/scroll_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shimmer/shimmer.dart';
import 'package:transformable_list_view/transformable_list_view.dart';

class ReusableCarousel extends StatelessWidget {
  dynamic carouselData;
  final String? title;
  final String? tag;
  final bool? detailsPage;
  final bool? secondary;
  final bool isManga;

  ReusableCarousel({
    super.key,
    this.title,
    this.carouselData,
    this.tag,
    this.secondary = true,
    this.detailsPage = false,
    this.isManga = false,
  });

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
        final bool usingCompactCards =
            box.get('usingCompactCards', defaultValue: false);
        final bool usingSaikouCards =
            box.get('usingSaikouCards', defaultValue: true);
        final double cardRoundness =
            box.get('cardRoundness', defaultValue: 18.0);

        return normalCard(customScheme, context, usingCompactCards,
            usingSaikouCards, cardRoundness);
      },
    );
  }

  Column normalCard(ColorScheme customScheme, BuildContext context,
      bool usingCompactCards, bool usingSaikouCards, double cardRoundness) {
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
              const Icon(Icons.arrow_right)
            ],
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: usingSaikouCards
              ? (usingCompactCards ? 180 : 210)
              : (usingCompactCards ? 280 : 300),
          child: TransformableListView.builder(
            padding: const EdgeInsets.only(left: 20),
            physics: const BouncingScrollPhysics(
                decelerationRate: ScrollDecelerationRate.fast),
            getTransformMatrix: getTransformMatrix,
            scrollDirection: Axis.horizontal,
            itemCount: carouselData!.length,
            itemExtent: MediaQuery.of(context).size.width /
                (usingSaikouCards ? 3.3 : 2.3),
            itemBuilder: (context, index) {
              dynamic itemData = detailsPage!
                  ? carouselData![index]['node']['mediaRecommendation']
                  : carouselData[index];
              final String posterUrl = itemData['coverImage']['large'] ?? '??';
              final String title = itemData['title']['romaji'] ??
                  itemData['title']['romaji'] ??
                  '?';
              final random = Random().nextInt(100000);
              final tagg = '${itemData['id']}$tag$random';
              String extraData =
                  ((itemData['averageScore'] ?? 0) / 10)?.toString() ?? '??';

              return Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: GestureDetector(
                  onTap: () {
                    if (isManga) {
                      Navigator.pushNamed(
                        context,
                        '/manga/details',
                        arguments: {
                          'id': itemData['id'],
                          'posterUrl': posterUrl,
                          'tag': tagg
                        },
                      );
                    } else {
                      Navigator.pushNamed(
                        context,
                        '/details',
                        arguments: {
                          'id': itemData['id'],
                          'posterUrl': posterUrl,
                          'tag': tagg
                        },
                      );
                    }
                  },
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Stack(children: [
                            SizedBox(
                              height: usingSaikouCards ? 160 : 240,
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
                                    height: usingSaikouCards
                                        ? (usingCompactCards ? 200 : 170)
                                        : (usingCompactCards ? 280 : 250),
                                  ),
                                ),
                              ),
                            ),
                            if (!usingCompactCards)
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
                                            topLeft: Radius.circular(
                                                cardRoundness - 5),
                                            bottomRight: Radius.circular(
                                                cardRoundness))),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Iconsax.star5,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
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
                            if (usingCompactCards)
                              Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4, horizontal: 12),
                                    decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainer,
                                        borderRadius: BorderRadius.only(
                                            bottomLeft:
                                                Radius.circular(cardRoundness),
                                            topRight: Radius.circular(
                                                cardRoundness - 5))),
                                    child: Text(
                                      extraData,
                                      style: TextStyle(
                                          fontFamily: 'Poppins-Bold',
                                          fontSize: 11,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .inverseSurface),
                                    ),
                                  )),
                          ]),
                          if (usingCompactCards)
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.8),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          if (usingCompactCards)
                            Positioned(
                              bottom: 10,
                              left: 10,
                              right: 10,
                              child: Text(
                                title,
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .inverseSurface,
                                  fontSize: usingSaikouCards ? 10 : 13,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 4,
                                      color: Colors.black.withOpacity(0.7),
                                      offset: const Offset(2, 2),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                          else
                            Column(
                              children: [
                                SizedBox(
                                  height: usingSaikouCards ? 164 : 248,
                                  width: MediaQuery.of(context).size.width /
                                      (usingSaikouCards ? 3.3 : 2.3),
                                ),
                                Text(
                                  title,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .inverseSurface,
                                    fontSize: usingSaikouCards ? 10 : 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                        ],
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
}
