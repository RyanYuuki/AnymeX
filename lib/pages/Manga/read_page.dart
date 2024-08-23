import 'dart:convert';
import 'dart:developer';
import 'package:aurora/components/MangaExclusive/toggle_bars.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ReadingPage extends StatefulWidget {
  final String id;
  final String mangaId;
  const ReadingPage({super.key, required this.id, required this.mangaId});

  @override
  State<ReadingPage> createState() => _ReadingPageState();
}

class _ReadingPageState extends State<ReadingPage> {
  List<dynamic>? chaptersList;
  List<dynamic>? chapterImages;
  String? currentChapter;
  String? mangaTitle;
  int? index;
  bool isLoading = true;
  bool hasError = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchChapterData();
  }

  Future<void> fetchChapterData() async {
    const String url =
        'https://anymey-proxy.vercel.app/cors?url=https://manga-ryan.vercel.app/api/manga/';
    try {
      final resp = await http.get(Uri.parse(url + widget.id));
      if (resp.statusCode == 200) {
        final tempData = jsonDecode(resp.body);
        setState(() {
          chaptersList = tempData['chapterListIds'];
          chapterImages = tempData['images'];
          currentChapter = tempData['currentChapter'];
          mangaTitle = tempData['title'];
          isLoading = false;
          index = tempData['chapterListIds']
              ?.indexWhere((chapter) => chapter['name'] == currentChapter);
        });
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  Future<void> fetchChapterImages() async {
    isLoading = true;
    const String url =
        'https://anymey-proxy.vercel.app/cors?url=https://manga-ryan.vercel.app/api/manga/';
    try {
      final resp = await http.get(
          Uri.parse('$url${widget.mangaId}/${chaptersList?[index!]['id']}'));
      if (resp.statusCode == 200) {
        final tempData = jsonDecode(resp.body);
        setState(() {
          chaptersList = tempData['chapterListIds'];
          chapterImages = tempData['images'];
          currentChapter = tempData['currentChapter'];
          mangaTitle = tempData['title'];
          isLoading = false;
        });
      }
    } catch (e) {
      log(e.toString());
    }
  }

  void handleChapter(String? direction) {
    if (direction == 'right') {
      index = ((chaptersList
                  ?.indexWhere((chapter) => chapter['name'] == currentChapter))!
              .toInt() -
          1);
    } else {
      index = ((chaptersList
                  ?.indexWhere((chapter) => chapter['name'] == currentChapter))!
              .toInt() +
          1);
    }
    fetchChapterImages();
  }

  @override
  Widget build(BuildContext context) {
    return ToggleBar(
      title: isLoading ? '??' : mangaTitle,
      chapter: isLoading ? 'Chapter ?' : currentChapter,
      totalImages: chapterImages?.length ?? 0,
      scrollController: _scrollController,
      handleChapter: handleChapter,
      child: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : hasError
                ? const Text('Failed to load data')
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: chapterImages!.length,
                    itemBuilder: (context, index) {
                      return Image.network(chapterImages![index]['image']);
                    },
                  ),
      ),
    );
  }
}
