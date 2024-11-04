// ignore_for_file: prefer_const_constructors, deprecated_member_use, non_constant_identifier_names, must_be_immutable, avoid_print, use_build_context_synchronously
import 'dart:developer';
import 'package:aurora/components/common/IconWithLabel.dart';
import 'package:aurora/pages/Novel/reading_page.dart';
import 'package:aurora/utils/sources/novel/wuxia_click.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:text_scroll/text_scroll.dart';

class NovelDetailsPage extends StatefulWidget {
  final String id;
  final String? posterUrl;
  final String? tag;
  const NovelDetailsPage({
    super.key,
    required this.id,
    this.posterUrl,
    this.tag,
  });

  @override
  State<NovelDetailsPage> createState() => _NovelDetailsPageState();
}

class _NovelDetailsPageState extends State<NovelDetailsPage>
    with SingleTickerProviderStateMixin {
  bool usingSaikouLayout =
      Hive.box('app-data').get('usingSaikouLayout', defaultValue: false);
  dynamic data;
  bool isLoading = true;
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final tempdata = await scrapeNovelDetails(widget.id);
      setState(() {
        data = tempdata;
        isLoading = false;
      });
    } catch (e) {
      log('Failed to fetch Anime Info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme customScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: originalDetailsPage(customScheme, context),
    );
  }

  Scaffold originalDetailsPage(ColorScheme CustomScheme, BuildContext context) {
    return Scaffold(
      backgroundColor: CustomScheme.surface,
      body: isLoading
          ? Column(
              children: [
                Center(
                  child: Poster(
                    context,
                    tag: widget.tag,
                    poster: widget.posterUrl,
                    isLoading: true,
                  ),
                ),
                const SizedBox(height: 30),
                CircularProgressIndicator(),
              ],
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  Poster(
                    context,
                    isLoading: false,
                    tag: widget.tag,
                    poster: widget.posterUrl,
                  ),
                  const SizedBox(height: 30),
                  originalInfoPage(CustomScheme, context),
                ],
              ),
            ),
    );
  }

  Widget Poster(
    BuildContext context, {
    required String? tag,
    required String? poster,
    required bool? isLoading,
  }) {
    return SizedBox(
      height: 300,
      width: MediaQuery.of(context).size.width,
      child: Stack(
        children: [
          Positioned.fill(
            child: CachedNetworkImage(
              fit: BoxFit.cover,
              imageUrl: widget.posterUrl!,
              alignment: Alignment.topCenter,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).colorScheme.surface.withOpacity(0.4),
                    Theme.of(context).colorScheme.surface.withOpacity(0.6),
                    Theme.of(context).colorScheme.surface,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 25,
            child: Row(
              children: [
                Hero(
                  tag: tag!,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: CachedNetworkImage(
                      imageUrl: poster!,
                      fit: BoxFit.cover,
                      width: 70,
                      height: 100,
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width - 100,
                      child: Text(
                        data?['title'] ?? 'Loading',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            overflow: TextOverflow.ellipsis),
                        maxLines: 2,
                      ),
                    ),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        iconWithName(
                          icon: Iconsax.star5,
                          name: data?['rating'] ?? '6.9',
                          isVertical: false,
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 2,
                          height: 18,
                          color: Theme.of(context)
                              .colorScheme
                              .inverseSurface
                              .withOpacity(0.4),
                        ),
                        const SizedBox(width: 10),
                        Text(data?['status'] ?? '??',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontFamily: 'Poppins-SemiBold'))
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Column originalInfoPage(ColorScheme CustomScheme, BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              Text('Description',
                  style: TextStyle(fontFamily: 'Poppins-SemiBold')),
              const SizedBox(
                height: 5,
              ),
              Column(
                children: [
                  Text(
                    data['description']?.replaceAll(RegExp(r'<[^>]*>'), '') ??
                        data?['description']
                            ?.replaceAll(RegExp(r'<[^>]*>'), '') ??
                        'Description Not Found',
                    maxLines: 13,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[400]),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Statistics',
                  style:
                      TextStyle(fontFamily: 'Poppins-SemiBold', fontSize: 16)),
              infoRow(field: 'Author', value: data['author']),
              infoRow(field: 'Rating', value: data?['rating']),
              infoRow(field: 'Total Chapters', value: data['chapters']),
              infoRow(field: 'Views', value: data['views']),
              infoRow(field: 'Reviews', value: data?['reviews'] ?? '??'),
              infoRow(field: 'Status', value: data?['status'] ?? '??'),
              const SizedBox(height: 30),
              ChapterList(
                title: data['title'],
                chaptersData: data['chapterList'],
              )
            ],
          ),
        ),
      ],
    );
  }
}

class infoRow extends StatelessWidget {
  final String value;
  final String field;

  const infoRow({super.key, required this.field, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(right: 10),
      margin: EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(field,
              style: TextStyle(
                  fontFamily: 'Poppins-Bold',
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.7))),
          SizedBox(
            width: 170,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontFamily: 'Poppins-Bold')),
            ),
          ),
        ],
      ),
    );
  }
}

class ChapterList extends StatefulWidget {
  final dynamic chaptersData;
  final String title;
  const ChapterList({
    super.key,
    this.chaptersData,
    required this.title,
  });

  @override
  _ChapterListState createState() => _ChapterListState();
}

class _ChapterListState extends State<ChapterList> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _filteredChapters = [];
  bool isSortedDown = true;

  @override
  void initState() {
    super.initState();
    if (isSortedDown) {
      _filteredChapters = widget.chaptersData;
    } else {
      _filteredChapters = widget.chaptersData.reversed.toList();
    }
    _searchController.addListener(_filterChapters);
  }

  void _filterChapters() {
    setState(() {
      if (isSortedDown) {
        _filteredChapters = widget.chaptersData
            .where((chapter) => chapter['title']
                .toString()
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()))
            .toList();
      } else {
        final newList = widget.chaptersData.reversed.toList();
        _filteredChapters = newList
            .where((chapter) => chapter['title']
                .toString()
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void sortFilteredChapter() {
    setState(() {
      isSortedDown = !isSortedDown;
      if (isSortedDown) {
        _filteredChapters = widget.chaptersData;
      } else {
        _filteredChapters = widget.chaptersData.reversed.toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Chapters',
                style: TextStyle(
                  fontSize: 22,
                  fontFamily: "Poppins-Bold",
                ),
                textAlign: TextAlign.left,
              ),
              IconButton(
                  onPressed: () {
                    sortFilteredChapter();
                  },
                  icon: Icon(
                      isSortedDown ? Icons.arrow_downward : Icons.arrow_upward))
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
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
              ),
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
                      Text(
                        manga['title'],
                        style: TextStyle(
                            fontSize: 16, fontFamily: 'Poppins-SemiBold'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => NovelReadingPage(
                                        id: manga['id'],
                                        novelTitle: widget.title,
                                      )));
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
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
                            color:
                                Theme.of(context).colorScheme.inverseSurface ==
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
                );
              },
            ),
          ),
          const SizedBox(
            height: 50,
          ),
        ],
      ),
    );
  }
}