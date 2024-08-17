// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:infinite_carousel/infinite_carousel.dart';

class ReusableCarousel extends StatelessWidget {
  final List<dynamic>? carouselData;
  final String? title;

  const ReusableCarousel({super.key, this.title, this.carouselData});

  @override
  Widget build(BuildContext context) {
    if (carouselData == null || carouselData!.isEmpty) {
      return Container(
        height: 300,
        alignment: Alignment.center,
        child: const Text('No data provided'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Row(
          children: [
            Text(
              title ?? '??',
              style: TextStyle(
                fontSize: 22,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const Text(
              ' Manga',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
            )
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 250,
          child: InfiniteCarousel.builder(
            itemCount: carouselData!.length,
            itemExtent: MediaQuery.of(context).size.width / 3,
            center: false,
            anchor: 0.0,
            loop: true,
            velocityFactor: 0.2,
            axisDirection: Axis.horizontal,
            itemBuilder: (context, itemIndex, realIndex) {
              final itemData = carouselData![itemIndex];
              return Container(
                margin: const EdgeInsets.only(right: 4),
                color: Colors.transparent,
                child: Card(
                  color: Colors.transparent,
                  elevation: 0,
                  child: Column(
                    children: [
                      SizedBox(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/manga/details',
                                arguments: {'id': itemData['id']});
                          },
                          child: Hero(
                            tag: itemData['id'].toString(),
                            child: SizedBox(
                              height: 180,
                              width: 160,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  itemData['image'],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        itemData['title'].toString(),
                        style: const TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      )
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
