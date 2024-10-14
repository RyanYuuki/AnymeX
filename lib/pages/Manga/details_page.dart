// ignore_for_file: prefer_const_constructors, deprecated_member_use, non_constant_identifier_names, must_be_immutable, avoid_print
import 'dart:ui';
import 'package:aurora/components/IconWithLabel.dart';
import 'package:aurora/components/MangaExclusive/chapters.dart';
import 'package:aurora/database/database.dart';
import 'package:aurora/database/scraper/mangakakalot/scraper_all.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:text_scroll/text_scroll.dart';

class MangaDetailsPage extends StatefulWidget {
  final String id;
  final String posterUrl;
  final String tag;
  const MangaDetailsPage(
      {super.key,
      required this.id,
      required this.posterUrl,
      required this.tag});

  @override
  State<MangaDetailsPage> createState() => _MangaDetailsPageState();
}

class _MangaDetailsPageState extends State<MangaDetailsPage> {
  dynamic mangaData;
  bool isLoading = true;
  dynamic charactersData;
  String? description;

  @override
  void initState() {
    super.initState();
    FetchMangaData();
  }

  Future<void> FetchMangaData() async {
    try {
      final tempData = await fetchMangaDetails(widget.id);
      setState(() {
        mangaData = tempData;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: TextScroll(
          isLoading || mangaData == null ? 'Loading...' : mangaData['name'],
          mode: TextScrollMode.bouncing,
          velocity: Velocity(pixelsPerSecond: Offset(30, 0)),
          delayBefore: Duration(milliseconds: 500),
          pauseBetween: Duration(milliseconds: 1000),
          textAlign: TextAlign.center,
          selectable: true,
          style: TextStyle(fontSize: 16),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(IconlyBold.arrow_left),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: isLoading
          ? Column(
              children: [
                Center(
                  child: Poster(posterUrl: widget.posterUrl, tag: widget.tag),
                ),
                const SizedBox(height: 30),
                CircularProgressIndicator(),
              ],
            )
          : Stack(
              children: [
                ListView(
                  children: [
                    Column(
                      children: [
                        Poster(
                          posterUrl: widget.posterUrl,
                          tag: widget.tag,
                        ),
                        const SizedBox(height: 30),
                        Info(context)
                      ],
                    ),
                  ],
                ),
                FloatingBar(
                  title: mangaData['name'],
                  id: widget.id,
                  posterUrl: widget.posterUrl,
                  chapterList: mangaData['chapterList'],
                ),
              ],
            ),
    );
  }

  Container Info(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    constraints: BoxConstraints(maxWidth: 170),
                    child: TextScroll(
                      mangaData['name'] ?? '??',
                      mode: TextScrollMode.endless,
                      velocity: Velocity(pixelsPerSecond: Offset(50, 0)),
                      delayBefore: Duration(milliseconds: 500),
                      pauseBetween: Duration(milliseconds: 1000),
                      textAlign: TextAlign.center,
                      selectable: true,
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    height: 18,
                    width: 3,
                    color: Theme.of(context).colorScheme.inverseSurface,
                  ),
                  const SizedBox(width: 10),
                  iconWithName(
                    backgroundColor:
                        Theme.of(context).colorScheme.onPrimaryFixedVariant,
                    icon: Iconsax.star1,
                    TextColor: Theme.of(context).colorScheme.inverseSurface ==
                            Theme.of(context).colorScheme.onPrimaryFixedVariant
                        ? Colors.black
                        : Theme.of(context).colorScheme.onPrimaryFixedVariant ==
                                Color(0xffe2e2e2)
                            ? Colors.black
                            : Colors.white,
                    color: Theme.of(context).colorScheme.inverseSurface ==
                            Theme.of(context).colorScheme.onPrimaryFixedVariant
                        ? Colors.black
                        : Theme.of(context).colorScheme.onPrimaryFixedVariant ==
                                Color(0xffe2e2e2)
                            ? Colors.black
                            : Colors.white,
                    name: '6.9',
                    isVertical: false,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ],
              ),
              const SizedBox(
                height: 15,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: (mangaData['genres'] as List<dynamic>? ??
                        ["Action", "Adventure", "Sigma"])
                    .take(3)
                    .map<Widget>(
                      (genre) => Container(
                        margin: EdgeInsets.only(right: 8),
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryFixedVariant,
                            borderRadius: BorderRadius.circular(12)),
                        child: Text(
                          genre as String,
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
                                          Color(0xffe2e2e2)
                                      ? Colors.black
                                      : Colors.white,
                              fontSize: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.fontSize,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 15),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  padding: EdgeInsets.all(7),
                  width: 130,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(5),
                          bottomLeft: Radius.circular(5)),
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest),
                  child: Column(
                    children: [
                      Text(
                          mangaData['view'] == null
                              ? '?'
                              : (mangaData['view'].toString()),
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text('Popularity')
                    ],
                  ),
                ),
                Container(
                  color: Theme.of(context).colorScheme.onPrimary,
                  height: 30,
                  width: 2,
                ),
                Container(
                  width: 130,
                  padding: EdgeInsets.all(7),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                          topRight: Radius.circular(5),
                          bottomRight: Radius.circular(5)),
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest),
                  child: Column(
                    children: [
                      Text(
                        mangaData['status'],
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      Text('Status')
                    ],
                  ),
                ),
              ])
            ],
          ),
          const SizedBox(
            height: 20,
          ),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            padding: EdgeInsets.all(10),
            child: Column(
              children: [
                Text(
                  mangaData['description'] ?? 'No description available',
                  maxLines: 13,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          ChapterList(
            chaptersData: mangaData['chapterList'],
            id: widget.id,
            posterUrl: widget.posterUrl,
          ),
          const SizedBox(height: 70)
        ],
      ),
    );
  }
}

class FloatingBar extends StatelessWidget {
  final String? title;
  final String? id;
  final String? posterUrl;
  final List<dynamic> chapterList;
  const FloatingBar(
      {super.key,
      this.title,
      this.id,
      this.posterUrl,
      required this.chapterList});
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppData>(context, listen: false);
    final currentChapter =
        provider.getCurrentChapterForManga(id!) ?? 'Chapter 1';
    final currentChapterList = chapterList
        .where((chapter) => chapter['name'] == currentChapter)
        .toList();
    final currentChapterId = currentChapterList.isNotEmpty
        ? currentChapterList.first['id']
        : 'chapter-1';

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.all(20),
        height: 60,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 10,
              sigmaY: 10,
            ),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              constraints: BoxConstraints(maxWidth: 130),
                              child: TextScroll(
                                title!,
                                mode: TextScrollMode.bouncing,
                                velocity:
                                    Velocity(pixelsPerSecond: Offset(20, 0)),
                                delayBefore: Duration(milliseconds: 500),
                                pauseBetween: Duration(milliseconds: 1000),
                                textAlign: TextAlign.center,
                                selectable: true,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
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
                                                Color(0xffe2e2e2)
                                            ? Colors.black
                                            : Colors.white),
                              ),
                            ),
                            SizedBox(
                              width: 180,
                              child: Text(
                                currentChapter.isEmpty
                                    ? 'Chapter 1'
                                    : currentChapter,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
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
                                              Color(0xffe2e2e2)
                                          ? Colors.black
                                          : Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 10),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/manga/read', arguments: {
                          'id': currentChapterId,
                          'mangaId': id,
                          'posterUrl': posterUrl
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.onPrimaryFixedVariant,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Iconsax.book,
                            color:
                                Theme.of(context).colorScheme.inverseSurface ==
                                        Theme.of(context)
                                            .colorScheme
                                            .onPrimaryFixedVariant
                                    ? Colors.black
                                    : Theme.of(context)
                                                .colorScheme
                                                .onPrimaryFixedVariant ==
                                            Color(0xffe2e2e2)
                                        ? Colors.black
                                        : Colors.white,
                          ),
                          SizedBox(width: 8),
                          Text(
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
                                          Color(0xffe2e2e2)
                                      ? Colors.black
                                      : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Poster extends StatelessWidget {
  String? posterUrl;
  String? tag;
  Poster({
    super.key,
    required this.posterUrl,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 30),
            height: 400,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  spreadRadius: 5,
                  blurRadius: 10,
                  offset: Offset(0, 7),
                ),
              ],
            ),
            width: MediaQuery.of(context).size.width - 100,
            child: Hero(
              tag: tag!,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CachedNetworkImage(
                  imageUrl: posterUrl!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
