import 'dart:developer';
import 'package:aurora/auth/auth_provider.dart';
import 'package:aurora/components/android/manga/toggle_bars.dart';
import 'package:aurora/components/platform_builder.dart';
import 'package:aurora/hiveData/appData/database.dart';
import 'package:aurora/utils/sources/manga/handlers/manga_sources_handler.dart';
import 'package:aurora/utils/sources/unified_handler.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:provider/provider.dart';

class ReadingPage extends StatefulWidget {
  final String id;
  final String mangaId;
  final String posterUrl;
  final String currentSource;
  final String anilistId;
  final dynamic chapterList;
  final String description;
  const ReadingPage(
      {super.key,
      required this.id,
      required this.mangaId,
      required this.posterUrl,
      required this.currentSource,
      required this.anilistId,
      required this.chapterList,
      required this.description});

  @override
  State<ReadingPage> createState() => _ReadingPageState();
}

class _ReadingPageState extends State<ReadingPage> {
  dynamic mangaData;
  List<dynamic>? chapterImages;
  String? currentChapter;
  String? mangaTitle;
  int? totalImages;
  bool isLoading = true;
  bool hasError = false;
  List<String> modes = ['Webtoon', 'RTL', 'LTR'];
  List<bool> selections = [true, false, false];
  String currentLayout = 'Webtoon';
  late MangaSourceHandler mangaSourceHandler;
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    mangaSourceHandler =
        Provider.of<UnifiedSourcesHandler>(context, listen: false)
            .getMangaInstance();
    fetchChapterData();
  }

  Future<void> fetchChapterData() async {
    try {
      final provider = Provider.of<AppData>(context, listen: false);
      final tempData = await mangaSourceHandler.fetchChapterImages(
        mangaId: widget.mangaId,
        chapterId: widget.id,
      );
      setState(() {
        mangaData = tempData;
        chapterImages = tempData?['images'];
        currentChapter = tempData?['currentChapter'];
        mangaTitle = tempData?['title'];
        totalImages = tempData?['totalImages'];
        isLoading = false;
      });
      await _updateMangaProgress();
      provider.addReadManga(
        mangaId: widget.mangaId,
        mangaTitle: tempData['title'],
        currentChapter: currentChapter!.split(':').first.toString(),
        mangaPosterImage: widget.posterUrl,
        anilistMangaId: widget.anilistId,
        currentSource: widget.currentSource,
        chapterList: widget.chapterList,
        description: widget.description,
      );
    } catch (e) {
      log(e.toString());
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  Future<void> _updateMangaProgress() async {
    if (mangaSourceHandler.selectedSourceName == "ComicK") {
      final chapterNumber =
          mangaData['currentChapter'].split('Chapter').last.trim();
      await AniListProvider().updateMangaProgress(
          mangaId: int.parse(widget.anilistId),
          chapterProgress: int.parse(chapterNumber),
          status: 'CURRENT');
    } else {
      final chapterNumber =
          RegExp(r'\d+').firstMatch(currentChapter!)?.group(0) ?? '';
      await AniListProvider().updateMangaProgress(
          mangaId: int.parse(widget.anilistId),
          chapterProgress: int.parse(chapterNumber),
          status: 'CURRENT');
    }
  }

  Future<void> fetchChapterImages(String chapterId) async {
    setState(() {
      isLoading = true;
    });
    try {
      final provider = Provider.of<AppData>(context, listen: false);
      final tempData = await mangaSourceHandler.fetchChapterImages(
        mangaId: widget.mangaId,
        chapterId: chapterId,
      );
      setState(() {
        mangaData = tempData;
        totalImages = tempData?['totalImages'];
        chapterImages = tempData?['images'];
        currentChapter = tempData?['currentChapter'];
        isLoading = false;
      });
      provider.addReadManga(
          mangaId: widget.mangaId,
          mangaTitle: mangaTitle!,
          currentChapter: currentChapter!.split(':').first.toString(),
          mangaPosterImage: widget.posterUrl,
          anilistMangaId: (widget.anilistId),
          currentSource: widget.currentSource,
          chapterList: widget.chapterList,
          description: widget.description);
      _updateMangaProgress();
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
      if (mangaData['nextChapterId'] == '') {
      } else {
        fetchChapterImages(mangaData['nextChapterId']);
      }
    } else {
      if (mangaData['prevChapterId'] == '') {
      } else {
        fetchChapterImages(mangaData['prevChapterId']);
      }
    }
  }

  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return ToggleBar(
      mangaData: mangaData,
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
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
              ? const Text('Failed to load data')
              : PlatformBuilder(
                  desktopBuilder: _buildLayoutContent(true),
                  androidBuilder: _buildLayoutContent(false),
                ),
    );
  }

  double? _getPageNumber() {
    if (currentLayout == 'Webtoon') {
      return null;
    }
    return _currentPage + 1;
  }

  double? getPageWidth() {}

  Widget _buildLayoutContent(bool isDesktop) {
    switch (currentLayout) {
      case 'Webtoon':
        return ListView(
          controller: _scrollController,
          children: chapterImages!.map((imageData) {
            return Center(
              child: CachedNetworkImage(
                imageUrl: imageData['image'],
                httpHeaders: const {'Referer': 'https://chapmanganato.to/'},
                fit: BoxFit.cover,
                width: isDesktop
                    ? MediaQuery.of(context).size.width * 0.5
                    : MediaQuery.of(context).size.width,
                progressIndicatorBuilder: (context, url, progress) => SizedBox(
                  child: Center(
                    child: SizedBox(
                      height: 50,
                      width: 50,
                      child: CircularProgressIndicator(
                        value: progress.progress,
                      ),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            );
          }).toList(),
        );

      case 'RTL':
      case 'LTR':
        if (isDesktop) {
          return Stack(
            children: [
              PageView(
                controller: _pageController,
                reverse: currentLayout == 'RTL',
                onPageChanged: (pageNumber) {
                  setState(() {
                    _currentPage = pageNumber;
                  });
                },
                children: chapterImages!.map((imageData) {
                  return CachedNetworkImage(
                    imageUrl: imageData['image'],
                    fit: BoxFit.contain,
                    progressIndicatorBuilder: (context, url, progress) =>
                        Center(
                      child: CircularProgressIndicator(
                        value: progress.progress,
                      ),
                    ),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                  );
                }).toList(),
              ),
              // Previous Page Button
              Positioned(
                left: MediaQuery.of(context).size.width * .25,
                top: MediaQuery.of(context).size.height / 2 - 30,
                child: IconButton(
                  icon: const Icon(IconlyBold.arrow_left_2,
                      size: 50, color: Colors.white),
                  onPressed: () {
                    if (_pageController.page! > 0) {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                ),
              ),
              // Next Page Button
              Positioned(
                right: MediaQuery.of(context).size.width * .25,
                top: MediaQuery.of(context).size.height / 2 - 30,
                child: IconButton(
                  icon: const Icon(IconlyBold.arrow_right_2,
                      size: 50, color: Colors.white),
                  onPressed: () {
                    if (_pageController.page! < chapterImages!.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                ),
              ),
            ],
          );
        } else {
          return PageView(
            controller: _pageController,
            reverse: currentLayout == 'RTL',
            onPageChanged: (pageNumber) {
              setState(() {
                _currentPage = pageNumber;
              });
            },
            children: chapterImages!.map((imageData) {
              return CachedNetworkImage(
                imageUrl: imageData['image'],
                fit: BoxFit.contain,
                progressIndicatorBuilder: (context, url, progress) => Center(
                  child: CircularProgressIndicator(
                    value: progress.progress,
                  ),
                ),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              );
            }).toList(),
          );
        }
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
