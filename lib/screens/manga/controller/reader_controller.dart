import 'dart:async';
import 'dart:developer';
import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/service_handler/params.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Offline/Hive/chapter.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

enum LoadingState { loading, loaded, error }

enum MangaPageViewMode {
  continuous,
  paged,
}

enum MangaPageViewDirection {
  up,
  down,
  left,
  right;

  Axis get axis {
    return switch (this) {
      MangaPageViewDirection.up => Axis.vertical,
      MangaPageViewDirection.down => Axis.vertical,
      MangaPageViewDirection.left => Axis.horizontal,
      MangaPageViewDirection.right => Axis.horizontal,
    };
  }

  bool get reversed => switch (this) {
        MangaPageViewDirection.up => true,
        MangaPageViewDirection.down => false,
        MangaPageViewDirection.left => true,
        MangaPageViewDirection.right => false,
      };
}

class ReaderController extends GetxController {
  late Media media;
  late List<Chapter> chapterList;
  final Rxn<Chapter> currentChapter = Rxn();
  final Rxn<Chapter> savedChapter = Rxn();
  final RxList<PageUrl> pageList = RxList();

  final SourceController sourceController = Get.find<SourceController>();
  final OfflineStorageController offlineStorageController =
      Get.find<OfflineStorageController>();

  final RxInt currentPageIndex = 1.obs;
  final RxDouble pageWidthMultiplier = 1.0.obs;
  final RxDouble scrollSpeedMultiplier = 1.0.obs;

  // Scroll Controllers
  ItemScrollController? itemScrollController;
  ScrollOffsetController? scrollOffsetController;
  ItemPositionsListener? itemPositionsListener;
  ScrollOffsetListener? scrollOffsetListener;

  PageController? pageController;
  final RxBool spacedPages = false.obs;
  final RxBool overscrollToChapter = true.obs;

  final defaultWidth = 400.obs;
  final defaultSpeed = 300.obs;
  RxInt preloadPages = 5.obs;
  RxBool showPageIndicator = false.obs;

  final Rx<MangaPageViewMode> readingLayout = MangaPageViewMode.continuous.obs;
  final Rx<MangaPageViewDirection> readingDirection =
      MangaPageViewDirection.down.obs;

  final RxBool showControls = true.obs;
  final Rx<LoadingState> loadingState = LoadingState.loading.obs;
  final RxString errorMessage = ''.obs;

  final Map<int, double> imageHeights = {};
  final totalOffset = 0.0.obs;

  RxBool canGoNext = false.obs;
  RxBool canGoPrev = false.obs;

  bool _isNavigating = false;

  void _initializeControllers() {
    itemScrollController = ItemScrollController();
    scrollOffsetController = ScrollOffsetController();
    itemPositionsListener = ItemPositionsListener.create();
    scrollOffsetListener = ScrollOffsetListener.create();
    _setupPositionListener();
  }

  void _getPreferences() {
    readingLayout.value = MangaPageViewMode.values[settingsController
        .preferences
        .get('reading_layout', defaultValue: 0 /* continuous */)];
    readingDirection.value = MangaPageViewDirection.values[settingsController
        .preferences
        .get('reading_direction', defaultValue: 1 /* down */)];
    pageWidthMultiplier.value =
        settingsController.preferences.get('image_width') ?? 1;
    scrollSpeedMultiplier.value =
        settingsController.preferences.get('scroll_speed') ?? 1;
    spacedPages.value =
        settingsController.preferences.get('spaced_pages', defaultValue: false);
    overscrollToChapter.value = settingsController.preferences
        .get('overscroll_to_chapter', defaultValue: true);
    preloadPages.value =
        settingsController.preferences.get('preload_pages', defaultValue: 3);
    showPageIndicator.value = settingsController.preferences
        .get('show_page_indicator', defaultValue: false);
  }

  void _savePreferences() {
    settingsController.preferences
        .put('reading_layout', readingLayout.value.index);
    settingsController.preferences
        .put('reading_direction', readingDirection.value.index);
    settingsController.preferences
        .put('image_width', pageWidthMultiplier.value);
    settingsController.preferences
        .put('scroll_speed', scrollSpeedMultiplier.value);
    settingsController.preferences.put('spaced_pages', spacedPages.value);
    settingsController.preferences
        .put('overscroll_to_chapter', overscrollToChapter.value);
    settingsController.preferences.put('preload_pages', preloadPages.value);
    settingsController.preferences
        .put('show_page_indicator', showPageIndicator.value);
  }

  void _setupPositionListener() {
    if (itemPositionsListener != null) {
      itemPositionsListener!.itemPositions.removeListener(_onPositionChanged);
      itemPositionsListener!.itemPositions.addListener(_onPositionChanged);
    }
  }

  void _onPositionChanged() async {
    if (itemPositionsListener == null) return;

    final positions = itemPositionsListener!.itemPositions.value;
    if (positions.isEmpty || _isNavigating) return;

    final topItem = currentPageIndex.value >= (pageList.length - 2)
        ? positions.last
        : positions.first;
    final number = topItem.index + 1;
    if (number < 0 && number > pageList.length) return;

    if (number != currentPageIndex.value) {
      currentPageIndex.value = number;
      currentChapter.value?.pageNumber = number;
    }

    if (number == currentChapter.value?.totalPages) {
      _saveTracking();
    }
  }

  void onPageChanged(int index) async {
    final number = index + 1;
    if (number < 0 && number > pageList.length) return;
    currentPageIndex.value = number;
    currentChapter.value?.pageNumber = number;
    currentChapter.value?.totalPages = pageList.length;
    if (number == currentChapter.value?.totalPages) {
      _saveTracking();
    }
  }

  Future<void> init(Media data, List<Chapter> chList, Chapter curCh) async {
    media = data;
    chapterList = chList;
    currentChapter.value = curCh;

    _initializeControllers();
    _getPreferences();

    fetchImages(currentChapter.value!.link!);
  }

  void _initTracking() {
    savedChapter.value = offlineStorageController.getReadChapter(
        media.id, currentChapter.value!.number!);
    if (savedChapter.value == null) {
      offlineStorageController.addOrUpdateManga(
          media, chapterList, currentChapter.value);
    }

    serviceHandler.updateListEntry(UpdateListEntryParams(
        listId: media.id,
        status: "CURRENT",
        progress: currentChapter.value!.number!.toInt(),
        syncIds: [media.idMal],
        isAnime: false));
  }

  void _saveTracking() {
    currentChapter.value!.pageNumber = currentPageIndex.value;
    offlineStorageController.addOrUpdateManga(
        media, chapterList, currentChapter.value);
    offlineStorageController.addOrUpdateReadChapter(
        media.id, currentChapter.value!);
  }

  void toggleControls() {
    showControls.value = !showControls.value;

    if (!showControls.value) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void togglePageIndicator() {
    showPageIndicator.value = !showPageIndicator.value;
    savePreferences();
  }

  void toggleSpacedPages() {
    spacedPages.value = !spacedPages.value;
    savePreferences();
  }

  void toggleOverscrollToChapter() {
    overscrollToChapter.value = !overscrollToChapter.value;
    savePreferences();
  }

  void navigateToChapter(int index) async {
    if (index < 0 || index >= chapterList.length) return;
    _saveTracking();
    currentChapter.value = chapterList[index];
    currentPageIndex.value = 1;
    await fetchImages(currentChapter.value!.link!);
  }

  void navigateToPage(int index) async {
    if (index < 0 || index > pageList.length) return;
    currentPageIndex.value = index;
    if (readingLayout.value == MangaPageViewMode.continuous) {
      itemScrollController?.jumpTo(index: currentPageIndex.value);
    } else {
      pageController?.jumpToPage(index);
    }
  }

  void chapterNavigator(bool next) async {
    final current = currentChapter.value;
    if (current == null) return;

    final targetNumber = next ? current.number! + 1 : current.number! - 1;

    final numberMatchIndex =
        chapterList.indexWhere((chapter) => chapter.number == targetNumber);

    if (numberMatchIndex != -1) {
      navigateToChapter(numberMatchIndex);
      return;
    }

    final index = chapterList.indexOf(current);
    if (index == -1) return;

    final newIndex = next ? index + 1 : index - 1;
    if (newIndex >= 0 && newIndex < chapterList.length) {
      navigateToChapter(newIndex);
    }
  }

  void _syncAvailability() {
    final index = chapterList.indexOf(currentChapter.value!);
    canGoPrev.value = index > 0;
    canGoNext.value = index < chapterList.length - 1;
  }

  Future<void> fetchImages(String url) async {
    _isNavigating = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _initTracking());
    currentPageIndex.value = 1;
    try {
      loadingState.value = LoadingState.loading;
      pageList.clear();
      errorMessage.value = '';

      final data = await sourceController.activeMangaSource.value!.methods
          .getPageList(DEpisode(episodeNumber: '1', url: url));

      if (data.isNotEmpty) {
        pageList.value = data;
        loadingState.value = LoadingState.loaded;
        currentPageIndex.value = 1;
        currentChapter.value?.totalPages = pageList.length;
        if (savedChapter.value!.pageNumber! <= pageList.length) {
          _syncAvailability();
          currentChapter.value?.totalPages = pageList.length;
          if (savedChapter.value?.pageNumber != null &&
              savedChapter.value!.pageNumber! > 1) {
            currentPageIndex.value = savedChapter.value!.pageNumber!;
            await Future.delayed(const Duration(milliseconds: 100));
            navigateToPage(savedChapter.value!.pageNumber! - 1);
          }
        }
      } else {
        throw Exception('No pages found for this chapter');
      }
    } catch (e) {
      log('Error fetching images: ${e.toString()}');
      loadingState.value = LoadingState.error;
      errorMessage.value = e.toString();
    } finally {
      _isNavigating = false;
    }
  }

  void retryFetchImages() {
    if (currentChapter.value?.link != null) {
      fetchImages(currentChapter.value!.link!);
    }
  }

  void changeReadingLayout(MangaPageViewMode mode) async {
    readingLayout.value = mode;
    savePreferences();
  }

  void changeReadingDirection(MangaPageViewDirection direction) async {
    readingDirection.value = direction;
    savePreferences();
  }

  void savePreferences() => _savePreferences();

  @override
  void onClose() {
    Future.microtask(() {
      _saveTracking();
      if (currentChapter.value!.pageNumber ==
              currentChapter.value!.totalPages &&
          chapterList.last.number! < currentChapter.value!.number!) {
        try {
          serviceHandler.updateListEntry(UpdateListEntryParams(
              listId: media.id,
              status: "CURRENT",
              progress: currentChapter.value!.number!.toInt() + 1,
              syncIds: [media.idMal],
              isAnime: false));
        } catch (e) {
          log('Error saving tracking on close: ${e.toString()}');
        }
      }
    });

    pageController?.dispose();
    super.onClose();
  }
}
