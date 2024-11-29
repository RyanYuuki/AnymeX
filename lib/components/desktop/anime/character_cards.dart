import 'package:anymex/components/android/helper/scroll_helper.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:iconsax/iconsax.dart';
import 'package:transformable_list_view/transformable_list_view.dart';

class HorizontalCharacterCards extends StatelessWidget {
  final dynamic carouselData;
  final bool isManga;
  HorizontalCharacterCards(
      {super.key, this.carouselData, required this.isManga});

  final ScrollDirectionHelper _scrollDirectionHelper = ScrollDirectionHelper();
  final ScrollController scrollController = ScrollController();
  final ScrollController voiceActorCarousel = ScrollController();

  @override
  Widget build(BuildContext context) {
    final bool usingSaikouCards =
        Hive.box('app-data').get('usingSaikouCards', defaultValue: true);
    if (carouselData == null || carouselData!.isEmpty) {
      return Container();
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

    void slideCarousel(bool left, ScrollController scrollController) {
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  Text(
                    'Characters',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => slideCarousel(true, scrollController),
                    icon: const Icon(Icons.arrow_left),
                  ),
                  IconButton(
                    onPressed: () => slideCarousel(false, scrollController),
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
                  final itemData = carouselData![index]['node'];
                  final title = itemData['name']['full'].toString().length > 25
                      ? '${itemData['name']['full'].toString().substring(0, 25)}...'
                      : itemData['name']['full'];
                  final role = itemData['favourites'].toString();
                  return Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: Column(
                      children: [
                        Stack(children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              itemData['image']['large'],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 200,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 8),
                              decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainer,
                                  borderRadius: const BorderRadius.only(
                                      bottomRight: Radius.circular(12),
                                      topLeft: Radius.circular(12))),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Iconsax.heart5,
                                    size: 12,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  Text(role,
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontStyle: FontStyle.italic,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.7)),
                                      textAlign: TextAlign.right),
                                ],
                              ),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 4),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title.toString(),
                              style: const TextStyle(fontSize: 12),
                              textAlign: TextAlign.left,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        if (!isManga)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    Text(
                      'Voice Actors',
                      style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => slideCarousel(true, voiceActorCarousel),
                      icon: const Icon(Icons.arrow_left),
                    ),
                    IconButton(
                      onPressed: () => slideCarousel(false, voiceActorCarousel),
                      icon: const Icon(Icons.arrow_right),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                height: 280,
                child: TransformableListView.builder(
                  controller: voiceActorCarousel,
                  padding: const EdgeInsets.only(left: 20),
                  physics: const BouncingScrollPhysics(
                      decelerationRate: ScrollDecelerationRate.fast),
                  getTransformMatrix: getTransformMatrix,
                  scrollDirection: Axis.horizontal,
                  itemCount: carouselData!.length,
                  itemExtent: 160,
                  itemBuilder: (context, index) {
                    if (carouselData![index]['voiceActors'] != null &&
                        carouselData![index]['voiceActors'].isNotEmpty) {
                      final itemData = carouselData![index]['voiceActors'][0];
                      final title = itemData?['name']?['full'] ?? 'Unknown';
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                itemData['image']['large'],
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center),
                          ],
                        ),
                      );
                    } else {
                      return Container(
                        height: 100,
                        margin: const EdgeInsets.only(right: 4),
                        alignment: Alignment.center,
                        child: const Text(
                          'No Voice Actor Data',
                          style: TextStyle(
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
      ],
    );
  }
}
