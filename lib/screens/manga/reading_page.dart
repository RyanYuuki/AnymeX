import 'dart:async';
import 'dart:io';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/core/Eval/dart/model/page.dart';
import 'package:anymex/core/Search/get_pages.dart';
import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Offline/Hive/chapter.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/widgets/common/slider_semantics.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

enum ReadingMode {
  webtoon,
  ltr,
  rtl,
}

class ReadingPage extends StatefulWidget {
  final Media anilistData;
  final List<Chapter> chapterList;
  final Chapter currentChapter;

  const ReadingPage({
    super.key,
    required this.anilistData,
    required this.chapterList,
    required this.currentChapter,
  });

  @override
  State<ReadingPage> createState() => _ReadingPageState();
}

class _ReadingPageState extends State<ReadingPage> {
  final sourceController = Get.find<SourceController>();
  ScrollController scrollController = ScrollController();
  PageController pageController = PageController();
  final isMenuToggled = true.obs;

  late Rx<Chapter> currentChapter;
  late Rx<Media> anilistData;
  late RxList<Chapter> chapterList;

  final mangaPages = <PageUrl>[].obs;
  final currentPageIndex = 0.obs;
  final canGoForward = false.obs;
  final canGoBackward = true.obs;
  final isLoading = true.obs;
  Timer? _debounce;
  int _pointersCount = 0;
  final TransformationController _zoomController = TransformationController();
  double currentScaleValue = 1.0;
  // Settings
  final activeMode = ReadingMode.webtoon.obs;
  final pageWidthMultiplier = 1.0.obs;
  final scrollSpeedMultiplier = 1.0.obs;
  final defaultWidth = 400.obs;
  final defaultSpeed = 300.obs;
  final FocusNode _focusNode = FocusNode();

  // Offline Storage
  final offlineStorage = Get.find<OfflineStorageController>();
  final anilist = Get.find<ServiceHandler>();

  // Timers
  Timer? _scrollDelayTimer;
  Timer? _scrollTimer;
  Timer? _keyPressTimer;

  // Flag to prevent multiple chapter loads
  final _isLoadingNextChapter = false.obs;
  final scrolledToNext = false.obs;

  @override
  void initState() {
    super.initState();
    _initScrollController();
    _initPageController();
    _initWidgetVars();
    _getPreferences();
    ever(currentChapter, (_) => fetchImages());
    ever(isMenuToggled, (_) {
      SystemChrome.setEnabledSystemUIMode(isMenuToggled.value
          ? SystemUiMode.edgeToEdge
          : SystemUiMode.immersiveSticky);
    });
    fetchImages();
    _focusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      updateAnilist(false);
    });
  }

  void _initWidgetVars() {
    currentChapter = Rx(widget.currentChapter);
    anilistData = Rx(widget.anilistData);
    chapterList = RxList(widget.chapterList);
  }

  void _initScrollController({double offset = 0}) {
    scrollController = ScrollController(initialScrollOffset: offset);
    scrollController.addListener(_updateScrollProgress);
  }

  void _initPageController({int page = 0}) {
    pageController = PageController(initialPage: page);
    pageController.addListener(() {});
  }

  void _getPreferences() {
    activeMode.value = ReadingMode.values[
        settingsController.preferences.get('reading_mode', defaultValue: 0)];
    pageWidthMultiplier.value =
        settingsController.preferences.get('image_width') ?? 1;
    scrollSpeedMultiplier.value =
        settingsController.preferences.get('scroll_speed') ?? 1;
  }

  void _savePreferences() {
    settingsController.preferences.put('reading_mode', activeMode.value.index);
    settingsController.preferences
        .put('image_width', pageWidthMultiplier.value);
    settingsController.preferences
        .put('scroll_speed', scrollSpeedMultiplier.value);
  }

  void _loadNextChapter() {
    if (canGoForward.value && !_isLoadingNextChapter.value) {
      debugPrint("Loading next chapter...");
      _isLoadingNextChapter.value = true;
      navigateToChapter(false).then((_) {
        _isLoadingNextChapter.value = false;
      });
    }
  }

  void _initTracker() {
    final isExtensions = anilist.serviceType.value == ServicesType.extensions;
    currentChapter.value.sourceName =
        sourceController.activeMangaSource.value?.name;
    offlineStorage.addOrUpdateManga(
        widget.anilistData, widget.chapterList, currentChapter.value);
    final savedChapter = offlineStorage.getReadChapter(
        widget.anilistData.id, currentChapter.value.number ?? -1);
    if (savedChapter != null && savedChapter.currentOffset != null) {
      currentChapter.value.maxOffset = savedChapter.maxOffset;
      scrollToProgress(savedChapter);
    }
    if (isExtensions) {
    } else {
      updateAnilist(false);
    }
  }

  Future<void> updateAnilist(bool next) async {
    currentChapter.value.sourceName =
        sourceController.activeMangaSource.value!.name;
    offlineStorage.addOrUpdateManga(
        anilistData.value, chapterList, currentChapter.value);
    offlineStorage.addOrUpdateReadChapter(
        widget.anilistData.id, currentChapter.value);
    await anilist.updateListEntry(
      listId: anilistData.value.id,
      status: "CURRENT",
      isAnime: false,
      progress: next
          ? currentChapter.value.number!.toInt()
          : currentChapter.value.number!.toInt() - 1,
    );
  }

  @override
  void dispose() {
    Future.delayed(Duration.zero, () async {
      await updateAnilist(true);
    });
    scrollController.removeListener(_updateScrollProgress);
    scrollController.dispose();
    pageController.dispose();
    super.dispose();
  }

  void scrollToProgress(Chapter chapter) {
    currentPageIndex.value = chapter.pageNumber ?? 1;

    if (activeMode.value != ReadingMode.webtoon) {
      _initPageController(page: chapter.pageNumber ?? 0);
    } else {
      _initScrollController(offset: chapter.currentOffset ?? 0);
    }

    _updateNavigationState();
  }

  void navigateToPage(int pageIndex) {
    currentPageIndex.value = pageIndex;

    if (activeMode.value != ReadingMode.webtoon) {
      if (pageController.hasClients) {
        pageController.animateToPage(
          pageIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      if (scrollController.hasClients) {
        final maxScrollExtent = scrollController.position.maxScrollExtent;
        final targetScroll =
            (pageIndex / (mangaPages.length - 1)) * maxScrollExtent;

        scrollController.animateTo(
          targetScroll,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }

    _updateNavigationState();
  }

  Future<void> fetchImages() async {
    try {
      isLoading.value = true;
      final chapterLink = currentChapter.value.link;
      if (chapterLink != null) {
        final data = await getPagesList(
          source: sourceController.activeMangaSource.value!,
          mangaId: chapterLink,
        );
        mangaPages.value = data ?? [];
        currentPageIndex.value = 0;
        currentChapter.value.totalPages = mangaPages.length;
        _updateNavigationState();
        _initTracker();
      }
    } catch (e) {
      debugPrint('Error fetching images: $e');
      mangaPages.clear();
    } finally {
      isLoading.value = false;
    }
  }

  void handleKeyPress(KeyEvent event) {
    if (event is KeyDownEvent) {
      _keyPressTimer ??= Timer(const Duration(milliseconds: 150), () {
        _keyPressTimer = null;
      });

      if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
          event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _startScrollingLeft();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
          event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _startScrollingRight();
      }
    } else if (event is KeyUpEvent) {
      if (_keyPressTimer?.isActive ?? false) {
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
            event.logicalKey == LogicalKeyboardKey.arrowUp) {
          _scrollSingleStep(-1);
        } else if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
            event.logicalKey == LogicalKeyboardKey.arrowDown) {
          _scrollSingleStep(1);
        }
      }
      _stopScrolling();
      _keyPressTimer?.cancel();
      _keyPressTimer = null;
    }
  }

  void _scrollSingleStep(int direction) {
    if (activeMode.value == ReadingMode.webtoon) {
      scrollController.animateTo(
          scrollController.offset +
              (direction * (defaultSpeed.value * scrollSpeedMultiplier.value)),
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOut);
    } else {
      pageController.animateToPage((pageController.page! + direction).toInt(),
          duration: const Duration(milliseconds: 100), curve: Curves.easeInOut);
    }
  }

  void _startScrollingLeft() {
    _scrollDelayTimer?.cancel();
    _scrollTimer?.cancel();
    _scrollDelayTimer = Timer(const Duration(milliseconds: 150), () {
      _scrollTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
        if (activeMode.value == ReadingMode.webtoon) {
          scrollController.animateTo(
              scrollController.offset -
                  (defaultSpeed.value * scrollSpeedMultiplier.value),
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeInOut);
        } else {
          pageController.animateToPage((pageController.page! - 1).toInt(),
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeInOut);
        }
        setState(() {});
      });
    });
  }

  void _startScrollingRight() {
    _scrollDelayTimer?.cancel();
    _scrollTimer?.cancel();
    _scrollDelayTimer = Timer(const Duration(milliseconds: 150), () {
      _scrollTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
        if (activeMode.value == ReadingMode.webtoon) {
          scrollController.animateTo(
              scrollController.offset +
                  (defaultSpeed.value * scrollSpeedMultiplier.value),
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeInOut);
        } else {
          pageController.animateToPage((pageController.page! + 1).toInt(),
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeInOut);
        }
        setState(() {});
      });
    });
  }

  void _stopScrolling() {
    _scrollDelayTimer?.cancel();
    _scrollTimer?.cancel();
    _scrollDelayTimer = null;
    _scrollTimer = null;
  }

  void _updateScrollProgress() {
    if (scrollController.hasClients && mangaPages.isNotEmpty) {
      _debounce?.cancel();

      final maxScrollExtent = scrollController.position.maxScrollExtent;
      final currentScroll = scrollController.position.pixels;
      final progress = currentScroll / maxScrollExtent;

      final currentPage = (progress * (mangaPages.length - 1)).round();
      currentChapter.value.pageNumber = currentPage;
      currentChapter.value.currentOffset = currentScroll;
      currentChapter.value.maxOffset = maxScrollExtent;

      if (scrollController.position.pixels.floor() ==
          (scrollController.position.maxScrollExtent + 120).floor()) {
        _loadNextChapter();
      }

      if (currentPage != currentPageIndex.value) {
        currentPageIndex.value = currentPage;
      }
    }
  }

  Future<void> navigateToChapter(bool prev) async {
    final currentChapterIndex = chapterList.indexOf(currentChapter.value);

    if (prev) {
      if (currentChapterIndex - 1 >= 0) {
        currentChapter.value = chapterList[currentChapterIndex - 1];
      }
    } else {
      if (currentChapterIndex + 1 < chapterList.length) {
        currentChapter.value = chapterList[currentChapterIndex + 1];
      }
    }
    _updateNavigationState();
  }

  void _updateNavigationState() {
    final currentChapterIndex = chapterList.indexOf(currentChapter.value);
    canGoBackward.value = currentChapterIndex > 0;
    canGoForward.value = currentChapterIndex < chapterList.length - 1;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => isMenuToggled.value = !isMenuToggled.value,
      child: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: handleKeyPress,
        child: Scaffold(
          body: Obx(() {
            if (isLoading.value) {
              return const Center(
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: AnymexProgressIndicator(),
                ),
              );
            }

            if (mangaPages.isEmpty) {
              return const Center(child: Text('No pages available'));
            }

            return Stack(
              children: [
                if (!Platform.isAndroid && !Platform.isIOS)
                  if (activeMode.value != ReadingMode.webtoon)
                    _buildPageViewMode()
                  else
                    _buildWebtoonMode()
                else if (activeMode.value != ReadingMode.webtoon)
                  InteractiveViewer(
                      minScale: 0.5, maxScale: 4, child: _buildPageViewMode())
                else
                  InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4,
                      transformationController: _zoomController,
                      onInteractionEnd: (details) {
                        currentScaleValue =
                            _zoomController.value.getMaxScaleOnAxis();
                      },
                      child: Listener(
                          onPointerDown: (_) =>
                              setState(() => _pointersCount++),
                          onPointerUp: (_) => setState(() => _pointersCount--),
                          child: _buildWebtoonMode())),
                _buildTopControls(context),
                _bottomControls(context),
                if (!isMenuToggled.value)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Theme.of(context)
                                .colorScheme
                                .surface
                                .withOpacity(0.5),
                            Colors.transparent,
                          ],
                          stops: const [0.5, 1.0],
                        ),
                      ),
                      child: Row(
                        children: [
                          AnymexText(
                            text:
                                "Page $currentPageIndex / ${mangaPages.length}",
                            size: 12,
                            variant: TextVariant.semiBold,
                          ),
                          10.width(),
                          AnymexText(
                            text: "Ch. ${currentChapter.value.number}/",
                            size: 12,
                            variant: TextVariant.semiBold,
                          ),
                          AnymexText(
                            text: "Ch. ${chapterList.length}",
                            size: 12,
                            variant: TextVariant.semiBold,
                          ),
                          const Spacer(),
                          AnymexText(
                            text: DateFormat("hh:mm a").format(DateTime.now()),
                            size: 12,
                            variant: TextVariant.semiBold,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }

  PageView _buildPageViewMode() {
    return PageView.builder(
      controller: pageController,
      scrollDirection: Axis.horizontal,
      reverse: activeMode.value == ReadingMode.rtl,
      onPageChanged: (index) {
        currentPageIndex.value = index;
        _updateNavigationState();
      },
      itemCount: mangaPages.length,
      itemBuilder: (context, index) {
        return Center(
          child: CachedNetworkImage(
              imageUrl: mangaPages[index].url,
              fit: BoxFit.contain,
              httpHeaders: {
                'Referer': sourceController.activeMangaSource.value!.baseUrl!,
              },
              width: getResponsiveSize(context,
                  mobileSize: double.infinity,
                  dektopSize: defaultWidth.value * pageWidthMultiplier.value),
              progressIndicatorBuilder: (context, url, progress) => SizedBox(
                  height: ((currentChapter.value.maxOffset ??
                          (MediaQuery.of(context).size.height *
                              mangaPages.length)) /
                      mangaPages.length),
                  width: double.infinity,
                  child: Center(
                    child: AnymexProgressIndicator(
                      value: progress.progress,
                    ),
                  ))),
        );
      },
    );
  }

  SingleChildScrollView _buildWebtoonMode() {
    return SingleChildScrollView(
      controller: scrollController,
      physics: (_pointersCount < 2) || (currentScaleValue > 1)
          ? const BouncingScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ...mangaPages.map((page) {
            return Center(
              child: CachedNetworkImage(
                  imageUrl: page.url,
                  fit: BoxFit.cover,
                  httpHeaders: {
                    'Referer':
                        sourceController.activeMangaSource.value!.baseUrl!,
                  },
                  width: getResponsiveSize(context,
                      mobileSize: double.infinity,
                      dektopSize:
                          defaultWidth.value * pageWidthMultiplier.value),
                  progressIndicatorBuilder: (context, url, progress) =>
                      SizedBox(
                          height: ((currentChapter.value.maxOffset ??
                                  (MediaQuery.of(context).size.height *
                                      mangaPages.length)) /
                              mangaPages.length),
                          width: double.infinity,
                          child: Center(
                            child: AnymexProgressIndicator(
                              value: progress.progress,
                            ),
                          ))),
            );
          }),
          const SizedBox(height: 10),
          const AnymexText(
            text: "Scroll To Next Chapter!",
            variant: TextVariant.semiBold,
          )
        ],
      ),
    );
  }

  AnimatedPositioned _buildTopControls(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: isMenuToggled.value ? 0 : -120,
      left: 0,
      right: 0,
      child: Container(
        height: 90,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface.withOpacity(0.5),
              Colors.transparent,
            ],
            stops: const [0.5, 1.0],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(IconlyBold.arrow_left, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width - 190,
                  child: Text(
                      currentChapter.value.title ??
                          'Chapter ${currentChapter.value.number}',
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(fontSize: 16, color: Colors.white)),
                ),
                const SizedBox(height: 3),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 190,
                  child: Text(anilistData.value.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white70)),
                ),
              ],
            ),
            const Spacer(),
            IconButton(
                onPressed: () {
                  showSettings(context);
                },
                icon: const Icon(Icons.settings))
          ],
        ),
      ),
    );
  }

  AnimatedPositioned _bottomControls(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      bottom: isMenuToggled.value ? 0 : -150,
      left: getResponsiveSize(context,
          mobileSize: 0, dektopSize: Get.width * 0.3),
      right: getResponsiveSize(context,
          mobileSize: 0, dektopSize: Get.width * 0.3),
      child: Container(
        padding: getResponsiveValue(context,
            mobileValue:
                const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
            desktopValue: const EdgeInsets.all(0)),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.5),
              Colors.transparent,
            ],
            stops: const [0.5, 1.0],
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
              color: getResponsiveValue(context,
                  mobileValue: Colors.transparent,
                  desktopValue: Theme.of(context)
                      .colorScheme
                      .secondaryContainer
                      .withOpacity(0.6)),
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20), topRight: Radius.circular(20))),
          padding: EdgeInsets.all(
              getResponsiveSize(context, mobileSize: 0, dektopSize: 10)),
          margin: EdgeInsets.only(
              bottom:
                  getResponsiveSize(context, mobileSize: 30, dektopSize: 0)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 5),
              Container(
                decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surface.withOpacity(0.80),
                    borderRadius: BorderRadius.circular(30)),
                child: IconButton(
                  icon: Icon(Icons.skip_previous_rounded,
                      color: canGoBackward.value ? Colors.white : Colors.grey,
                      size: 35),
                  onPressed: () async {
                    await navigateToChapter(true);
                    navigateToPage(1);
                  },
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surface
                          .withOpacity(0.80),
                      borderRadius: BorderRadius.circular(20)),
                  child: CustomSlider(
                    enableComfortPadding: true,
                    disableMinMax: false,
                    min: 0.0,
                    max: currentPageIndex.value.toDouble() <
                            (mangaPages.length.toDouble() - 1)
                        ? (mangaPages.length.toDouble() - 1)
                        : currentPageIndex.value.toDouble(),
                    focusNode: FocusNode(canRequestFocus: false),
                    divisions: mangaPages.length - 1,
                    value: currentPageIndex.value.toDouble(),
                    label: currentPageIndex.value.toString(),
                    onChanged: (value) {
                      navigateToPage(value.toInt());
                    },
                    activeColor: Theme.of(context).colorScheme.primary,
                    inactiveColor: Theme.of(context)
                        .colorScheme
                        .inverseSurface
                        .withOpacity(0.1),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Container(
                decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surface.withOpacity(0.80),
                    borderRadius: BorderRadius.circular(30)),
                child: IconButton(
                  icon: const Icon(Icons.skip_next_rounded,
                      size: 35, color: Colors.white),
                  onPressed: () async {
                    await navigateToChapter(false);
                    navigateToPage(1);
                  },
                ),
              ),
              const SizedBox(width: 5),
            ],
          ),
        ),
      ),
    );
  }

  void showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SingleChildScrollView(
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
                Obx(() {
                  return CustomTile(
                    title: 'Layout',
                    description:
                        'Currently: ${activeMode.value.name.toUpperCase()}',
                    icon: Iconsax.card,
                    postFix: 0.height(),
                  );
                }),
                Obx(() {
                  final selections = List<bool>.generate(
                    ReadingMode.values.length,
                    (index) =>
                        index == ReadingMode.values.indexOf(activeMode.value),
                  );
                  return Center(
                    child: ToggleButtons(
                      isSelected: selections,
                      onPressed: (int index) {
                        final pageIndex = currentPageIndex.value;
                        activeMode.value = ReadingMode.values[index];
                        _savePreferences();
                        Future.delayed(const Duration(milliseconds: 50), () {
                          navigateToPage(pageIndex);
                        });
                      },
                      children: const [
                        Tooltip(
                          message: 'Webtoon',
                          child: Icon(Icons.view_day),
                        ),
                        Tooltip(
                          message: 'LTR',
                          child: Icon(Icons.format_textdirection_l_to_r),
                        ),
                        Tooltip(
                          message: 'RTL',
                          child: Icon(Icons.format_textdirection_r_to_l),
                        ),
                      ],
                    ),
                  );
                }),
                if (!Platform.isAndroid && !Platform.isIOS)
                  Obx(() {
                    return CustomSliderTile(
                      title: 'Image Width',
                      sliderValue: pageWidthMultiplier.value,
                      onChanged: (double value) {
                        pageWidthMultiplier.value = value;
                      },
                      onChangedEnd: (e) => _savePreferences(),
                      description: 'Only Works with webtoon mode',
                      icon: Icons.image_aspect_ratio_rounded,
                      min: 1.0,
                      max: 4.0,
                      divisions: 39,
                    );
                  }),
                if (!Platform.isAndroid && !Platform.isIOS)
                  Obx(() {
                    return CustomSliderTile(
                      title: 'Scroll Multiplier',
                      sliderValue: scrollSpeedMultiplier.value,
                      onChanged: (double value) {
                        scrollSpeedMultiplier.value = value;
                      },
                      onChangedEnd: (e) => _savePreferences(),
                      description:
                          'Adjust Key Scrolling Speed (Up, Down, Left, Right)',
                      icon: Icons.speed,
                      min: 1.0,
                      max: 5.0,
                      divisions: 9,
                    );
                  }),
                20.height()
              ],
            ),
          ),
        );
      },
    );
  }

  List<bool> createSelectionRange() {
    const readingModes = ReadingMode.values;
    final trueIndex = readingModes.indexOf(activeMode.value);
    final newRange = [false, false, false];
    newRange[trueIndex] = true;
    return newRange;
  }
}
