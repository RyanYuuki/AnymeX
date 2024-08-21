import 'dart:ui';

import 'package:aurora/components/IconWithLabel.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class MangaList extends StatelessWidget {
  final List<dynamic>? data;

  const MangaList({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: data!
          .map<Widget>((manga) => Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                width: MediaQuery.of(context).size.width,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(
                        width: 125,
                        height: 165,
                        child: Hero(
                          tag: manga['id'],
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: manga['image'],
                              fit: BoxFit.cover,
                            ),
                          ),
                        )),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          manga['title'],
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            IconWithName(
                                TextColor: Theme.of(context)
                                    .colorScheme
                                    .inverseSurface,
                                color: Theme.of(context)
                                    .colorScheme
                                    .inverseSurface,
                                isVertical: false,
                                backgroundColor:
                                    Theme.of(context).colorScheme.tertiary,
                                borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(5),
                                    bottomLeft: Radius.circular(5)),
                                icon: Iconsax.book,
                                name: manga['chapter'].length > 10
                                    ? manga['chapter']
                                        .toString()
                                        .substring(0, 10)
                                    : manga['chapter'].toString()),
                            const SizedBox(width: 2),
                            IconWithName(
                                TextColor: Theme.of(context)
                                    .colorScheme
                                    .inverseSurface,
                                color: Theme.of(context)
                                    .colorScheme
                                    .inverseSurface,
                                isVertical: false,
                                backgroundColor:
                                    Theme.of(context).colorScheme.tertiary,
                                borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(5),
                                    bottomRight: Radius.circular(5)),
                                icon: Iconsax.heart,
                                name: manga['view'].toString()),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          manga['description'],
                          style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context)
                                  .colorScheme
                                  .inverseSurface
                                  .withOpacity(0.8)),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/manga/details',
                                  arguments: {
                                    'id': manga['id'],
                                    'posterUrl': manga['image'],
                                    'tag': manga['id']
                                  });
                            },
                            child: Text('Read Now'))
                      ],
                    ))
                  ],
                ),
              ))
          .toList(),
    );
  }
}
