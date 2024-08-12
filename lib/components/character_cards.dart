import 'package:flutter/material.dart';
import 'package:infinite_carousel/infinite_carousel.dart';

class CharacterCards extends StatelessWidget {
  final List<dynamic>? carouselData;

  const CharacterCards({super.key, this.carouselData});

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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text(
              'Characters',
              style: TextStyle(
                fontSize: 22,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
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
                  final title = itemData['name']['full'].toString().length > 25
                      ? '${itemData['name']['full'].toString().substring(0, 25)}...'
                      : itemData['name']['full'];
                  return Container(
                    margin: const EdgeInsets.only(right: 4),
                    child: Card(
                      color: Theme.of(context).colorScheme.surface,
                      elevation: 0,
                      child: Column(
                        children: [
                          SizedBox(
                            height: 170,
                            child: Container(
                                color: Colors.transparent,
                                width: 200,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    itemData['image'],
                                    fit: BoxFit.cover,
                                  ),
                                )),
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
        ),
        const SizedBox(height: 30),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text(
              'Voice Actors',
              style: TextStyle(
                fontSize: 22,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
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
                  final itemData = carouselData![itemIndex]['voiceActors'];
                  final title = itemData[0]['name']['full'];
                  return Container(
                    margin: const EdgeInsets.only(right: 4),
                    child: Card(
                      color: Theme.of(context).colorScheme.surface,
                      elevation: 0,
                      child: Column(
                        children: [
                          SizedBox(
                            height: 170,
                            child: Container(
                                color: Colors.transparent,
                                width: 200,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    itemData[0]['image'],
                                    fit: BoxFit.cover,
                                  ),
                                )),
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
        ),
      ],
    );
  }
}
