import 'package:flutter/material.dart';
import 'package:infinite_carousel/infinite_carousel.dart';

class CharacterCards extends StatelessWidget {
  final List<dynamic>? carouselData;
  const CharacterCards({super.key, this.carouselData});

  @override
  Widget build(BuildContext context) {
    if (carouselData == null || carouselData!.isEmpty) {
      return Container();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            const Text(
              'Characters',
              style: TextStyle(
                fontSize: 22,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              height: 220,
              child: InfiniteCarousel.builder(
                itemCount: carouselData!.length,
                itemExtent: MediaQuery.of(context).size.width / 3.3,
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
                  final role = itemData['role'].toString();
                  return Container(
                    margin: const EdgeInsets.only(right: 4),
                    child: Card(
                      color: Colors.transparent,
                      elevation: 0,
                      child: Column(
                        children: [
                          SizedBox(
                            height: 150,
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
                              const SizedBox(height: 3),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Text(role,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                                    textAlign: TextAlign.right),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            const Text(
              'Voice Actors',
              style: TextStyle(
                fontSize: 22,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              height: 220,
              child: InfiniteCarousel.builder(
                itemCount: carouselData!.length,
                itemExtent: MediaQuery.of(context).size.width / 3.3,
                center: false,
                anchor: 0.0,
                loop: false,
                velocityFactor: 0.2,
                axisDirection: Axis.horizontal,
                itemBuilder: (context, itemIndex, realIndex) {
                  final itemData = carouselData![itemIndex]?['voiceActors'];
                  final title = itemData?[0]?['name']?['full'];
                  return Container(
                    margin: const EdgeInsets.only(right: 4),
                    child: Card(
                      color: Colors.transparent,
                      elevation: 0,
                      child: Column(
                        children: [
                          SizedBox(
                            height: 150,
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
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(title.toString(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center),
                          )
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
