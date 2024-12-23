import 'dart:math';
import 'package:anymex/api/Mangayomi/Eval/dart/model/m_manga.dart';
import 'package:anymex/api/Mangayomi/Model/Source.dart';
import 'package:anymex/api/Mangayomi/Search/search.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:anymex/components/android/common/IconWithLabel.dart';

const String proxyUrl = '';

class AnimeSearchModal extends StatefulWidget {
  final String initialText;
  final Function(String mangaId) onAnimeSelected;
  final Source activeSource;

  const AnimeSearchModal(
      {super.key,
      required this.initialText,
      required this.onAnimeSelected,
      required this.activeSource});

  @override
  _AnimeSearchModalState createState() => _AnimeSearchModalState();
}

class _AnimeSearchModalState extends State<AnimeSearchModal> {
  late Future<List<MManga>> _searchFuture;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialText;
    _searchFuture = fetchData(widget.initialText);
  }

  Future<List<MManga>> fetchData(String query) async {
    final searchList = await search(
        source: widget.activeSource, query: query, page: 1, filterList: []);
    return searchList!.list;
  }

  void _performSearch(String searchTerm) {
    setState(() {
      _searchFuture = fetchData(searchTerm);
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
            child: FutureBuilder<List<MManga>>(
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
                      physics: const BouncingScrollPhysics(),
                      itemCount: snapshot.data!.length,
                      itemBuilder: (BuildContext context, int index) {
                        final anime = snapshot.data![index];
                        final random = Random().nextInt(100000);
                        final tag = '$random${anime.link}';
                        return searchItemList(
                          context,
                          anime,
                          tag,
                          widget.onAnimeSelected, // Pass the callback
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
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

void showAnimeSearchModal(BuildContext context, String initialText,
    Function(String animeId) onAnimeSelected, Source activeSource) {
  showModalBottomSheet(
    showDragHandle: true,
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return AnimeSearchModal(
        initialText: initialText,
        onAnimeSelected: onAnimeSelected,
        activeSource: activeSource,
      );
    },
  );
}

GestureDetector searchItemList(BuildContext context, MManga anime, String tag,
    Function(String) onAnimeSelected) {
  return GestureDetector(
    onTap: () {
      onAnimeSelected(anime.link!);
      Navigator.pop(context);
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
                  imageUrl: proxyUrl + anime.imageUrl!,
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
                anime.name.toString(),
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
                      name: anime.chapters?.toString() ?? '?'),
                  const SizedBox(width: 2),
                  iconWithName(
                      isVertical: false,
                      backgroundColor: const Color(0xFFb9e7ff),
                      borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(5),
                          bottomRight: Radius.circular(5)),
                      icon: Icons.mic,
                      name: anime.author?.toString() ?? '?')
                ],
              )
            ],
          )
        ],
      ),
    ),
  );
}
