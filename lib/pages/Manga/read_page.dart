import 'dart:developer';
import 'dart:io';
import 'package:anymex/api/Mangayomi/Eval/dart/model/m_chapter.dart';
import 'package:anymex/api/Mangayomi/Eval/dart/model/page.dart';
import 'package:anymex/api/Mangayomi/Model/Source.dart';
import 'package:anymex/api/Mangayomi/Search/get_pages.dart';
import 'package:anymex/auth/auth_provider.dart';
import 'package:anymex/components/android/common/custom_tile_ui.dart';
import 'package:anymex/components/android/manga/toggle_bars.dart';
import 'package:anymex/components/platform_builder.dart';
import 'package:anymex/hiveData/appData/database.dart';
import 'package:anymex/pages/Manga/deps/chapter_recognition.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconly/iconly.dart';
import 'package:provider/provider.dart';

class ReadingPage extends StatefulWidget {
  final MChapter id;
  final String mangaId;
  final String posterUrl;
  final Source currentSource;
  final String anilistId;
  final List<MChapter> chapterList;
  final String description;
  final String mangaTitle;
  const ReadingPage(
      {super.key,
      required this.id,
      required this.mangaId,
      required this.posterUrl,
      required this.currentSource,
      required this.anilistId,
      required this.chapterList,
      required this.description,
      required this.mangaTitle});

  @override
  State<ReadingPage> createState() => _ReadingPageState();
}

class _ReadingPageState extends State<ReadingPage> {
  List<MChapter>? mangaData;
  List<PageUrl>? chapterImages;
  MChapter? currentChapter;
  String? mangaTitle;
  int? totalImages;
  bool isLoading = true;
  bool hasError = false;
  List<String> modes = ['Webtoon', 'RTL', 'LTR'];
  List<bool> selections = [true, false, false];
  String currentLayout = 'Webtoon';
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController();
  double imageWidthFactor = 1.0;
  FocusNode focusNode = FocusNode();
  double scrollMultiplier = 1.5;

  bool canGoForward = false;
  bool canGoBackward = false;

  int currentChapIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchChapterData();
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  Future<void> fetchChapterData() async {
    try {
      final provider = Provider.of<AppData>(context, listen: false);
      final tempData = await getPagesList(
          source: widget.currentSource, mangaId: widget.id.url!);
      setState(() {
        mangaData = widget.chapterList;
        chapterImages = tempData?.map((el) {
          el.headers = {"Referer": widget.currentSource.baseUrl!};
          return el;
        }).toList();
        currentChapter = widget.id;
        currentChapIndex = widget.chapterList.indexOf(widget.id);
        mangaTitle = widget.mangaTitle;
        totalImages = tempData?.length ?? 0;
        isLoading = false;
      });
      await _updateMangaProgress();
      updateNavigationButtons();
      provider.addReadManga(
        mangaId: widget.mangaId,
        mangaTitle: widget.mangaId,
        currentChapter: currentChapter!.name!.split(':').first.toString(),
        mangaPosterImage: widget.posterUrl,
        anilistMangaId: widget.anilistId,
        currentSource: widget.currentSource.name!,
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
    final chapterNumber = ChapterRecognition.parseChapterNumber(
        widget.mangaTitle, currentChapter!.name!);
    await AniListProvider().updateMangaProgress(
        mangaId: int.parse(widget.anilistId),
        chapterProgress: int.parse(chapterNumber.toString()),
        status: 'CURRENT');
  }

  Future<void> fetchChapterImages(String chapterId) async {
    setState(() {
      isLoading = true;
    });
    try {
      final provider = Provider.of<AppData>(context, listen: false);
      final tempData =
          await getPagesList(source: widget.currentSource, mangaId: chapterId);
      setState(() {
        chapterImages = tempData?.map((el) {
          el.headers = {"Referer": widget.currentSource.baseUrl!};
          return el;
        }).toList();
        totalImages = tempData?.length ?? 0;
        isLoading = false;
      });
      await _updateMangaProgress();
      updateNavigationButtons();
      provider.addReadManga(
        mangaId: widget.mangaId,
        mangaTitle: widget.mangaId,
        currentChapter: currentChapter!.name!.split(':').first.toString(),
        mangaPosterImage: widget.posterUrl,
        anilistMangaId: widget.anilistId,
        currentSource: widget.currentSource.name!,
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

  void handleChapter(String? direction) {
    setState(() {
      if (direction == 'right' && canGoForward) {
        currentChapIndex++;
      } else if (direction == 'left' && canGoBackward) {
        currentChapIndex--;
      }
      currentChapter = widget.chapterList[currentChapIndex];
      fetchChapterImages(currentChapter!.url!);
    });
  }

  void updateNavigationButtons() {
    setState(() {
      canGoForward = currentChapIndex < widget.chapterList.length - 1;
      canGoBackward = currentChapIndex > 0;
    });
  }

  void handleKeyPress(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
          event.logicalKey == LogicalKeyboardKey.arrowUp) {
        if (currentLayout == "Webtoon") {
          _scrollController.animateTo(
              _scrollController.offset - (200 * scrollMultiplier),
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeInOut);
        } else {
          _pageController.animateToPage((_pageController.page! - 1).toInt(),
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeInOut);
        }
        setState(() {});
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
          event.logicalKey == LogicalKeyboardKey.arrowDown) {
        if (currentLayout == "Webtoon") {
          _scrollController.animateTo(
              _scrollController.offset + (200 * scrollMultiplier),
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeInOut);
        } else {
          _pageController.animateToPage((_pageController.page! + 1).toInt(),
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeInOut);
        }
        setState(() {});
      }
    }
  }

  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: focusNode,
      onKeyEvent: handleKeyPress,
      child: ToggleBar(
        mangaData: mangaData,
        pageNumber: _getPageNumber(),
        title: isLoading ? 'Loading...' : mangaTitle ?? 'Unknown Title',
        chapter: isLoading
            ? 'Loading...'
            : currentChapter!.name ?? 'Unknown Chapter',
        totalImages: totalImages ?? 10,
        scrollController: _scrollController,
        handleChapter: handleChapter,
        showChapters: _showChapters,
        showSettings: _showSettings,
        pageController: _pageController,
        currentLayout: currentLayout,
        validators: [canGoBackward, canGoForward],
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : hasError
                ? const Text('Failed to load data')
                : PlatformBuilder(
                    desktopBuilder: _buildLayoutContent(true),
                    androidBuilder: _buildLayoutContent(false),
                  ),
      ),
    );
  }

  double? _getPageNumber() {
    if (currentLayout == 'Webtoon') {
      return null;
    }
    return _currentPage + 1;
  }

  Widget _buildLayoutContent(bool isDesktop) {
    switch (currentLayout) {
      case 'Webtoon':
        return ListView(
          physics: const BouncingScrollPhysics(),
          controller: _scrollController,
          children: chapterImages!.map((imageData) {
            return Center(
              child: CachedNetworkImage(
                httpHeaders: imageData.headers,
                imageUrl: imageData.url,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                width: isDesktop
                    ? MediaQuery.of(context).size.width * 0.5 * imageWidthFactor
                    : MediaQuery.of(context).size.width,
                progressIndicatorBuilder: (context, url, progress) => SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: progress.progress,
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
                    httpHeaders: imageData.headers,
                    imageUrl: imageData.url,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    progressIndicatorBuilder: (context, url, progress) =>
                        SizedBox(
                      height: MediaQuery.of(context).size.height,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: progress.progress,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                  );
                }).toList(),
              ),
              if (isDesktop)
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
              if (isDesktop)
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
                httpHeaders: imageData.headers,
                imageUrl: imageData.url,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                progressIndicatorBuilder: (context, url, progress) => SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: progress.progress,
                    ),
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
            padding: const EdgeInsets.symmetric(vertical: 20),
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
                if (!Platform.isAndroid && !Platform.isIOS)
                  TileWithSlider(
                    title: 'Image Width',
                    sliderValue: imageWidthFactor,
                    onChanged: (double value) {
                      setModalState(() {
                        imageWidthFactor = value;
                      });
                      setState(() {});
                    },
                    description: 'Only Works with webtoon mode',
                    icon: Icons.image_aspect_ratio_rounded,
                    min: 0.5,
                    max: 1.5,
                    divisions: 10,
                  ),
                if (!Platform.isAndroid && !Platform.isIOS)
                  TileWithSlider(
                    title: 'Scroll Multiplier',
                    sliderValue: scrollMultiplier,
                    onChanged: (double value) {
                      setModalState(() {
                        scrollMultiplier = value;
                      });
                      setState(() {});
                    },
                    description:
                        'Adjust Key Scrolling Speed (Up, Down, Left, Right)',
                    icon: Icons.image_aspect_ratio_rounded,
                    min: 1.0,
                    max: 10.0,
                    divisions: 9,
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
                  physics: const BouncingScrollPhysics(),
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

class TileWithSlider extends StatefulWidget {
  const TileWithSlider({
    super.key,
    required this.sliderValue,
    required this.onChanged,
    required this.title,
    required this.description,
    required this.icon,
    required this.min,
    required this.max,
    this.divisions,
    this.iconSize,
  });
  final String title;
  final String description;
  final double sliderValue;
  final ValueChanged<double> onChanged;
  final IconData icon;
  final double min;
  final double max;
  final int? divisions;
  final double? iconSize;

  @override
  State<TileWithSlider> createState() => _TileWithSliderState();
}

class _TileWithSliderState extends State<TileWithSlider> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomTileUi(
          icon: widget.icon,
          title: widget.title,
          description: widget.description,
          size: widget.iconSize ?? 30,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Text('${(widget.sliderValue * 100).floor()}%',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary)),
              ),
              Expanded(
                child: Slider(
                  value: widget.sliderValue,
                  onChanged: (newValue) => widget.onChanged(newValue),
                  min: widget.min,
                  max: widget.max,
                  label: '${(widget.sliderValue * 100).floor()}%',
                  divisions: widget.divisions ?? (widget.max * 10).toInt(),
                ),
              ),
              SizedBox(
                width: 40,
                child: Text('${(widget.max * 100).floor()}%',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
