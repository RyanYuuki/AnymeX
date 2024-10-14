import 'package:aurora/components/IconWithLabel.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shimmer/shimmer.dart';

class MangaList extends StatelessWidget {
  final List<dynamic>? data;

  const MangaList({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    const String proxyUrl =
        'https://goodproxy.goodproxy.workers.dev/fetch?url=';
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
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/manga/details',
                            arguments: {
                              'id': manga['id'],
                              'posterUrl': proxyUrl + manga['image'],
                              'tag': manga['id']
                            });
                      },
                      child: SizedBox(
                          width: 125,
                          height: 165,
                          child: Hero(
                            tag: manga['id'],
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: proxyUrl + manga['image'],
                                fit: BoxFit.cover,
                                placeholder:(context, url) => Shimmer.fromColors(
                                  baseColor: Colors.grey[900]!,
                                  highlightColor: Colors.grey[700]!,
                                  child: Container(
                                    color: Colors.grey[600],
                                    height: 250,
                                    width: double.infinity,
                                  ),
                                ),
                              ),
                            ),
                          )),
                    ),
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
                            iconWithName(
                                TextColor: Theme.of(context)
                                            .colorScheme
                                            .inverseSurface ==
                                        Theme.of(context)
                                            .colorScheme
                                            .onPrimaryFixedVariant
                                    ? Colors.black
                                    : Theme.of(context)
                                                .colorScheme
                                                .onPrimaryFixedVariant ==
                                            const Color(0xffe2e2e2)
                                        ? Colors.black
                                        : Colors.white,
                                color: Theme.of(context)
                                            .colorScheme
                                            .inverseSurface ==
                                        Theme.of(context)
                                            .colorScheme
                                            .onPrimaryFixedVariant
                                    ? Colors.black
                                    : Theme.of(context)
                                                .colorScheme
                                                .onPrimaryFixedVariant ==
                                            const Color(0xffe2e2e2)
                                        ? Colors.black
                                        : Colors.white,
                                isVertical: false,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryFixedVariant,
                                borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(5),
                                    bottomLeft: Radius.circular(5)),
                                icon: Iconsax.book_1,
                                name: manga['author'].length > 10
                                    ? manga['author']
                                        .toString()
                                        .substring(0, 10)
                                    : manga['author'].toString()),
                            const SizedBox(width: 2),
                            iconWithName(
                                TextColor: Theme.of(context)
                                            .colorScheme
                                            .inverseSurface ==
                                        Theme.of(context)
                                            .colorScheme
                                            .onPrimaryFixedVariant
                                    ? Colors.black
                                    : Theme.of(context)
                                                .colorScheme
                                                .onPrimaryFixedVariant ==
                                            const Color(0xffe2e2e2)
                                        ? Colors.black
                                        : Colors.white,
                                color: Theme.of(context)
                                            .colorScheme
                                            .inverseSurface ==
                                        Theme.of(context)
                                            .colorScheme
                                            .onPrimaryFixedVariant
                                    ? Colors.black
                                    : Theme.of(context)
                                                .colorScheme
                                                .onPrimaryFixedVariant ==
                                            const Color(0xffe2e2e2)
                                        ? Colors.black
                                        : Colors.white,
                                isVertical: false,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryFixedVariant,
                                borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(5),
                                    bottomRight: Radius.circular(5)),
                                icon: IconlyBold.heart,
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
                          maxLines: 3,
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryFixedVariant,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)
                                  )
                            ),
                            onPressed: () {
                              Navigator.pushNamed(context, '/manga/read',
                                  arguments: {
                                    'id': manga['id'] + '/' + 'chapter-1',
                                    'mangaId': manga['id'] + '/' + 'chapter-1',
                                  });
                            },
                            child: Text(
                              'Read Now',
                              style: TextStyle(
                                  color: Theme.of(context)
                                              .colorScheme
                                              .inverseSurface ==
                                          Theme.of(context)
                                              .colorScheme
                                              .onPrimaryFixedVariant
                                      ? Colors.black
                                      : Theme.of(context)
                                                  .colorScheme
                                                  .onPrimaryFixedVariant ==
                                              const Color(0xffe2e2e2)
                                          ? Colors.black
                                          : Colors.white),
                            ))
                      ],
                    ))
                  ],
                ),
              ))
          .toList(),
    );
  }
}
