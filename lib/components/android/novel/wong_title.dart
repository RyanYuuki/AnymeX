// ignore_for_file: library_private_types_in_public_api
import 'dart:math' hide log;
import 'package:anymex/utils/sources/novel/handler/novel_sources_handler.dart';
import 'package:anymex/utils/sources/unified_handler.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

class NovelSearchModal extends StatefulWidget {
  final String initialText;
  final Function(String mangaId) onMangaSelected;

  const NovelSearchModal({
    super.key,
    required this.initialText,
    required this.onMangaSelected,
  });

  @override
  _NovelSearchModalState createState() => _NovelSearchModalState();
}

class _NovelSearchModalState extends State<NovelSearchModal> {
  late Future<dynamic> _searchFuture;
  final TextEditingController _controller = TextEditingController();
  final Random _random = Random();
  late NovelSourcesHandler novelInstance;
  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialText;
    novelInstance = Provider.of<UnifiedSourcesHandler>(context, listen: false)
        .getNovelInstance();
    _searchFuture = novelInstance.fetchNovelSearchResults(
      widget.initialText,
    );
  }

  Future<void> _performSearch(String searchTerm) async {
    setState(() {
      _searchFuture = novelInstance.fetchNovelSearchResults(
        searchTerm,
      );
    });
  }

  Widget searchItemList(
      BuildContext context, Map<String, String> manga, String tag) {
    return GestureDetector(
      onTap: () {
        widget.onMangaSelected(manga['id']!);
        Navigator.pop(context);
      },
      child: Container(
        height: 110,
        width: MediaQuery.of(context).size.width,
        margin: const EdgeInsets.only(top: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: Theme.of(context).colorScheme.surfaceContainer,
        ),
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
                    imageUrl: manga['image']!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                manga['title']!,
                style: Theme.of(context).textTheme.bodyLarge,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
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
                labelText: 'Search Novel',
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
            child: FutureBuilder<dynamic>(
              future: _searchFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData ||
                    (snapshot.data as List).isEmpty) {
                  return const Center(child: Text('No results found'));
                } else {
                  final mangaList = snapshot.data as List;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: ListView.builder(
                      itemCount: mangaList.length,
                      itemBuilder: (BuildContext context, int index) {
                        final manga = mangaList[index];
                        final tag = '${_random.nextInt(100000)}${manga['id']}';
                        return searchItemList(context, manga, tag);
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

void showNovelSearchModal(
  BuildContext context,
  String initialText,
  Function(String) onMangaSelected,
) {
  showModalBottomSheet(
    showDragHandle: true,
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return NovelSearchModal(
        initialText: initialText,
        onMangaSelected: onMangaSelected,
      );
    },
  );
}
