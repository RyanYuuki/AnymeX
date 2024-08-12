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
              ' Animes',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
            )
          ],
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 270,
          child: InfiniteCarousel.builder(
            itemCount: carouselData!.length,
            itemExtent: MediaQuery.of(context).size.width / 3,
            center: false,
            anchor: 0.0,
            loop: false,
            velocityFactor: 0.2,
            axisDirection: Axis.horizontal,
            itemBuilder: (context, itemIndex, realIndex) {
              final itemData = carouselData![itemIndex];
              final title = itemData['name'].toString().length > 25
                  ? '${itemData['name'].toString().substring(0, 25)}...'
                  : itemData['name'];
              return Container(
                margin: const EdgeInsets.only(right: 4),
                child: Card(
                  color: Theme.of(context).colorScheme.surface,
                  elevation: 0,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 170,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/details',
                              arguments: {'id': itemData['id']},
                            );
                          },
                          child: Hero(
                            tag: itemData['id'].toString(),
                            child: Container(
                              color: Colors.transparent,
                              width: 200,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  itemData['poster'],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(title.toString(),
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center)
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
