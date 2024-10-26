import 'dart:convert';
import 'dart:developer';
import 'package:aurora/components/manga/toggle_bars.dart';
import 'package:aurora/hiveData/appData/database.dart';
import 'package:aurora/utils/scrapers/manga/mangakakalot/scraper_all.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class ReadingPage extends StatefulWidget {
  final String id;
  final String mangaId;
  final String posterUrl;
  const ReadingPage(
      {super.key,
      required this.id,
      required this.mangaId,
      required this.posterUrl});

  @override
  State<ReadingPage> createState() => _ReadingPageState();
}

class _ReadingPageState extends State<ReadingPage> {
  List<dynamic>? chaptersList;
  List<dynamic>? chapterImages;
  String? currentChapter;
  String? mangaTitle;
  int? totalImages;
  int? index;
  bool isLoading = true;
  bool hasError = false;
  List<String> modes = ['Webtoon', 'RTL', 'LTR'];
  List<bool> selections = [true, false, false];
  String currentLayout = 'Webtoon';

  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    fetchChapterData();
  }

  String url = '${dotenv.get('PROXY_URL')}${dotenv.get('MANGA_URL')}api/manga/';

  Future<void> fetchChapterData() async {
    try {
      final provider = Provider.of<AppData>(context, listen: false);
      final tempData = await fetchChapterDetails(
          mangaId: widget.mangaId, chapterId: widget.id);
      setState(() {
        chaptersList = tempData['chapterListIds'];
        chapterImages = tempData['images'];
        currentChapter = tempData['currentChapter'];
        mangaTitle = tempData['title'];
        totalImages = tempData['totalImages'];
        index = tempData['chapterListIds']
            ?.indexWhere((chapter) => chapter['name'] == currentChapter);
        isLoading = false;
      });
      provider.addReadManga(
          mangaId: widget.mangaId,
          mangaTitle: tempData['title'],
          currentChapter: currentChapter.toString(),
          mangaPosterImage: widget.posterUrl);
    } catch (e) {
      log(e.toString());
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  Future<void> fetchChapterImages() async {
    setState(() {
      isLoading = true;
    });
    try {
      final provider = Provider.of<AppData>(context, listen: false);
      final tempData = await fetchChapterDetails(
          mangaId: widget.mangaId, chapterId: chaptersList?[index!]['id']);
      setState(() {
        totalImages = tempData['totalImages'];
        chapterImages = tempData['images'];
        currentChapter = tempData['currentChapter'];
        isLoading = false;
      });
      provider.addReadManga(
          mangaId: widget.mangaId,
          mangaTitle: mangaTitle!,
          currentChapter: currentChapter.toString(),
          mangaPosterImage: widget.posterUrl);
    } catch (e) {
      log(e.toString());
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  void handleChapter(String? direction) {
    if (direction == 'right') {
      index = ((chaptersList?.indexWhere(
                  (chapter) => chapter['name'] == currentChapter))! -
              1)
          .clamp(0, chaptersList!.length - 1);
    } else {
      index = ((chaptersList?.indexWhere(
                  (chapter) => chapter['name'] == currentChapter))! +
              1)
          .clamp(0, chaptersList!.length - 1);
    }
    fetchChapterImages();
  }

  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return ToggleBar(
      pageNumber: _getPageNumber(),
      title: isLoading ? 'Loading...' : mangaTitle ?? 'Unknown Title',
      chapter: isLoading ? 'Loading...' : currentChapter ?? 'Unknown Chapter',
      totalImages: totalImages ?? 10,
      scrollController: _scrollController,
      handleChapter: handleChapter,
      showChapters: _showChapters,
      showSettings: _showSettings,
      pageController: _pageController,
      currentLayout: currentLayout,
      child: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : hasError
                ? const Text('Failed to load data')
                : _buildLayoutContent(),
      ),
    );
  }

  double? _getPageNumber() {
    if (currentLayout == 'Webtoon') {
      return null;
    }
    return _currentPage + 1;
  }

  Widget _buildLayoutContent() {
    switch (currentLayout) {
      case 'Webtoon':
        return ListView.builder(
          controller: _scrollController,
          itemCount: chapterImages!.length,
          itemBuilder: (context, index) {
            return CachedNetworkImage(
              imageUrl: chapterImages![index]['image'],
              fit: BoxFit.cover,
              placeholder: (context, progress) => SizedBox(
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                child: const Center(
                    child: SizedBox(
                        height: 50,
                        width: 50,
                        child: CircularProgressIndicator())),
              ),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            );
          },
        );
      case 'RTL':
      case 'LTR':
        return PageView.builder(
          controller: _pageController,
          reverse: currentLayout == 'RTL',
          itemCount: chapterImages!.length,
          onPageChanged: (int page) {
            setState(() {
              _currentPage = page;
            });
          },
          itemBuilder: (context, index) {
            return CachedNetworkImage(
              imageUrl: chapterImages![index]['image'],
              fit: BoxFit.contain,
              placeholder: (context, progress) => const Center(
                child: CircularProgressIndicator(),
              ),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            );
          },
        );
      default:
        return const Text('Unknown layout');
    }
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          String activeMode =
              modes[selections.indexWhere((element) => element)];

          return Container(
            height: 150,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 10),
                  child: Center(
                    child: Text(
                      'Reader Settings',
                      style: TextStyle(
                          fontSize: 18, fontFamily: 'Poppins-SemiBold'),
                    ),
                  ),
                ),
                ListTile(
                  title: const Text('Layout'),
                  subtitle: Text(activeMode),
                  trailing: ToggleButtons(
                    isSelected: selections,
                    onPressed: (int index) {
                      setModalState(() {
                        for (int i = 0; i < selections.length; i++) {
                          selections[i] = i == index;
                        }
                        currentLayout =
                            modes[selections.indexWhere((element) => element)];
                      });
                      setState(() {
                        currentLayout =
                            modes[selections.indexWhere((element) => element)];
                        if (currentLayout != 'Webtoon') {}
                      });
                    },
                    children: const [
                      Tooltip(
                        message: 'Webtoon',
                        child: Icon(Icons.view_day),
                      ),
                      Tooltip(
                        message: 'RTL',
                        child: Icon(Icons.format_textdirection_r_to_l),
                      ),
                      Tooltip(
                        message: 'LTR',
                        child: Icon(Icons.format_textdirection_l_to_r),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showChapters(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: 600,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'Chapters',
                    style:
                        TextStyle(fontSize: 18, fontFamily: 'Poppins-SemiBold'),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: 50,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer),
                        ),
                      ),
                      title: Text('Chapter ${index + 1}'),
                      subtitle: Text('Subtitle for Chapter ${index + 1}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {},
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
