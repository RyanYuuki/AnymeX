import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class ChapterList extends StatefulWidget {
  final dynamic chaptersData;
  final String? id;
  const ChapterList({super.key, this.chaptersData, required this.id});

  @override
  _ChapterListState createState() => _ChapterListState();
}

class _ChapterListState extends State<ChapterList> {
  TextEditingController _searchController = TextEditingController();
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
          .where((chapter) =>
              chapter['name'].toString().toLowerCase().contains(_searchController.text.toLowerCase()))
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
              SizedBox(
                width: 200,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    fillColor: Theme.of(context).colorScheme.tertiary,
                    filled: true,
                    hintText: 'Search Chapter...',
                    prefixIcon: const Icon(Iconsax.search_normal),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.secondary,
                        width: 1,
                      ),
                    ),
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
          ..._filteredChapters.map<Widget>((manga) {
            return Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              width: MediaQuery.of(context).size.width,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Theme.of(context).colorScheme.tertiary,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        manga['name'].toString().length > 17
                            ? manga['name']
                                .substring(17, manga['name'].toString().length)
                            : manga['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        manga['createdAt'].toString(),
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
                            manga['view'],
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
                                "id": manga['path'].toString().substring(
                                      8,
                                      manga['path'].toString().length,
                                    ),
                                "mangaId": widget.id
                              });
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          backgroundColor:
                              Theme.of(context).colorScheme.inverseSurface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Read',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.inversePrimary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
