import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:text_scroll/text_scroll.dart';

class ChapterList extends StatefulWidget {
  final dynamic chaptersData;
  final String? id;
  final String? posterUrl;
  const ChapterList(
      {super.key,
      this.chaptersData,
      required this.id,
      required this.posterUrl});

  @override
  _ChapterListState createState() => _ChapterListState();
}

class _ChapterListState extends State<ChapterList> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _filteredChapters = [];

  @override
  void initState() {
    super.initState();
    _filteredChapters = widget.chaptersData;
    _searchController.addListener(_filterChapters);
  }

  void _filterChapters() {
    setState(() {
      _filteredChapters = widget.chaptersData
          .where((chapter) => chapter['name']
              .toString()
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Chapters',
                style: TextStyle(
                  fontSize: 24,
                  fontFamily: "Poppins-Bold",
                ),
                textAlign: TextAlign.left,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    fillColor:
                        Theme.of(context).colorScheme.surfaceContainerHigh,
                    filled: true,
                    hintText: 'Search Chapter...',
                    prefixIcon: const Icon(Iconsax.search_normal),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1,
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 400,
            child: ListView.builder(
              itemCount: _filteredChapters.length,
              itemBuilder: (context, index) {
                final manga = _filteredChapters[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  width: MediaQuery.of(context).size.width,
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 140,
                            child: TextScroll(
                              manga['title'],
                              mode: TextScrollMode.endless,
                              velocity: const Velocity(
                                  pixelsPerSecond: Offset(30, 0)),
                              delayBefore: const Duration(milliseconds: 500),
                              pauseBetween: const Duration(milliseconds: 1000),
                              textAlign: TextAlign.center,
                              selectable: true,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            manga['date'].toString(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.whatshot,
                                size: 16,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                manga['views'],
                                style: const TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 15),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/manga/read',
                                  arguments: {
                                    "id": manga['path']
                                        .toString()
                                        .split('/')
                                        .last,
                                    "mangaId": widget.id,
                                    'posterUrl': widget.posterUrl
                                  });
                            },
                            style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryFixedVariant,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Read',
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
                                        : Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
