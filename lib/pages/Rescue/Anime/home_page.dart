import 'dart:math';

import 'package:aurora/components/common/IconWithLabel.dart';
import 'package:aurora/pages/Rescue/Anime/details_page.dart';
import 'package:aurora/utils/sources/anime/extensions/aniwatch/aniwatch.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class RescueAnimeHome extends StatefulWidget {
  const RescueAnimeHome({super.key});

  @override
  State<RescueAnimeHome> createState() => _RescueAnimeHomeState();
}

class _RescueAnimeHomeState extends State<RescueAnimeHome> {
  late Future<dynamic> _searchFuture;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchFuture = HiAnime().scrapeSearchResults('Attack on titan');
  }

  void _performSearch(String query) async {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _controller,
                onSubmitted: _performSearch,
                decoration: InputDecoration(
                  labelText: 'Search Anime',
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                  suffixIcon: const Icon(Iconsax.search_normal),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Colors.transparent,
                      width: 1,
                    ),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<dynamic>(
                future: _searchFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No results found'));
                  } else {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: ListView.builder(
                        itemCount: snapshot.data!.length,
                        itemBuilder: (BuildContext context, int index) {
                          final anime = snapshot.data![index];
                          return searchItemList(
                            context,
                            anime,
                          );
                        },
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

GestureDetector searchItemList(BuildContext context, dynamic anime) {
  final tag = '${anime['id']}-${Random().nextInt(1000)}';
  return GestureDetector(
    onTap: () {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => RescueDetailsPage(
                    id: anime['id'],
                    posterUrl: anime['poster'],
                    tag: tag,
                  )));
    },
    child: Container(
      height: 110,
      width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: Theme.of(context).colorScheme.surfaceContainer),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          SizedBox(
            height: 70,
            width: 50,
            child: Hero(
              tag: tag,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: CachedNetworkImage(
                  imageUrl: anime['poster'],
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                anime['name'].length > 28
                    ? '${anime['name'].toString().substring(0, 28)}...'
                    : anime['name'].toString(),
              ),
              const SizedBox(
                height: 5,
              ),
              Row(
                children: [
                  iconWithName(
                      isVertical: false,
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(5),
                          bottomLeft: Radius.circular(5)),
                      icon: Icons.closed_caption,
                      backgroundColor: const Color(0xFFb0e3af),
                      name: anime?['episodes']?['sub']?.toString() ?? '?'),
                  const SizedBox(width: 2),
                  iconWithName(
                      isVertical: false,
                      backgroundColor: const Color(0xFFb9e7ff),
                      borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(5),
                          bottomRight: Radius.circular(5)),
                      icon: Icons.mic,
                      name: anime?['episodes']?['dub']?.toString() ?? '?')
                ],
              )
            ],
          )
        ],
      ),
    ),
  );
}
