// ignore_for_file: camel_case_types, use_build_context_synchronously, must_be_immutable
import 'dart:math';
import 'package:anymex/components/android/helper/scroll_helper.dart';
import 'package:anymex/pages/Android/Novel/details_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:shimmer/shimmer.dart';
import 'package:transformable_list_view/transformable_list_view.dart';

class DesktopNovelContinue extends StatelessWidget {
  final List<dynamic>? carouselData;
  final String? title;
  final String? tag;
  DesktopNovelContinue({
    super.key,
    this.title,
    this.carouselData,
    this.tag,
  });

  final ScrollDirectionHelper _scrollDirectionHelper = ScrollDirectionHelper();
  final ScrollController scrollController = ScrollController();

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
          height: 280,
          child: TransformableListView.builder(
            padding: const EdgeInsets.only(left: 20),
            physics: const BouncingScrollPhysics(
                decelerationRate: ScrollDecelerationRate.fast),
            getTransformMatrix: getTransformMatrix,
            scrollDirection: Axis.horizontal,
            itemCount: carouselData!.length,
            itemExtent: 160,
            itemBuilder: (context, index) {
              final itemData = carouselData?[index];
              final String posterUrl = itemData?['novelImage'];
              int random = Random().nextInt(100000);
              final tagg = '$random$index';
              const String proxyUrl = '';
              dynamic extraData = 'Chapter ${itemData['chapterNumber']}';
              return Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => NovelDetailsPage(
                                  id: itemData['novelId'],
                                  posterUrl: posterUrl,
                                  tag: tag,
                                )));
                  },
                  child: Column(
                    children: [
                      Stack(children: [
                        Hero(
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
                              height: 200,
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
                      const SizedBox(height: 8),
                      Text(
                        itemData?['novelTitle'] ?? '??',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.inverseSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
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
}
