// ignore_for_file: library_private_types_in_public_api

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:aurora/components/common/IconWithLabel.dart';
import 'package:aurora/utils/scrapers/anime/aniwatch/scraper_search.dart';

const String proxyUrl = 'https://goodproxy.goodproxy.workers.dev/fetch?url=';

class AnimeSearchModal extends StatefulWidget {
  final String initialText;

  const AnimeSearchModal({super.key, required this.initialText});

  @override
  _AnimeSearchModalState createState() => _AnimeSearchModalState();
}

class _AnimeSearchModalState extends State<AnimeSearchModal> {
  late Future<List<dynamic>> _searchFuture;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialText;
    _searchFuture = scrapeAnimeSearch(widget.initialText);
  }

  void _performSearch(String searchTerm) {
    setState(() {
      _searchFuture = scrapeAnimeSearch(searchTerm);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
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
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
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
            child: FutureBuilder<List<dynamic>>(
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
                        final random = Random().nextInt(100000);
                        final tag = '$random${anime['id']}';
                        return searchItemList(context, anime, tag);
                      },
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

void showAnimeSearchModal(BuildContext context, String initialText) {
  showModalBottomSheet(
    showDragHandle: true,
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return AnimeSearchModal(initialText: initialText);
    },
  );
}

GestureDetector searchItemList(
    BuildContext context, dynamic anime, String tag) {
  return GestureDetector(
    onTap: () {
      Navigator.pushReplacementNamed(context, '/details', arguments: {
        'id': anime['id'],
        'posterUrl': proxyUrl + anime['poster'],
        'tag': tag
      });
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
                  imageUrl: proxyUrl + anime['poster'],
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
                      name: anime['episodes']['sub']?.toString() ?? '?'),
                  const SizedBox(width: 2),
                  iconWithName(
                      isVertical: false,
                      backgroundColor: const Color(0xFFb9e7ff),
                      borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(5),
                          bottomRight: Radius.circular(5)),
                      icon: Icons.mic,
                      name: anime['episodes']['dub']?.toString() ?? '?')
                ],
              )
            ],
          )
        ],
      ),
    ),
  );
}
