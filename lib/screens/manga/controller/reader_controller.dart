import 'dart:async';
import 'dart:math' as math;
import 'package:anymex/utils/logger.dart';
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
import 'package:preload_page_view/preload_page_view.dart';
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

class ReaderController extends GetxController with WidgetsBindingObserver {
  late Media media;
  late List<Chapter> chapterList;
  final Rxn<Chapter> currentChapter = Rxn();
  final Rxn<Chapter> savedChapter = Rxn();
  final RxList<PageUrl> pageList = RxList();
  late ServicesType serviceHandler;

  final SourceController sourceController = Get.find<SourceController>();
  final OfflineStorageController offlineStorageController =
      Get.find<OfflineStorageController>();

  final RxInt currentPageIndex = 1.obs;
  final RxDouble pageWidthMultiplier = 1.0.obs;
  final RxDouble scrollSpeedMultiplier = 1.0.obs;

  ItemScrollController? itemScrollController;
  ScrollOffsetController? scrollOffsetController;
  ItemPositionsListener? itemPositionsListener;
  ScrollOffsetListener? scrollOffsetListener;

  PreloadPageController? pageController;
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

  final RxBool isOverscrolling = false.obs;
  final RxDouble overscrollProgress = 0.0.obs;
  final RxBool isOverscrollingNext = true.obs;
  double _overscrollStartOffset = 0.0;
  final double _maxOverscrollDistance = 50.0;
  Timer? _overscrollResetTimer;

  bool _isNavigating = false;

  @override
  void onInit() {
    super.onInit();

    WidgetsBinding.instance.addObserver(this);
    _performSave(reason: 'Page opened');
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);

    Future.microtask(() {
      _performFinalSave();
    });

    _overscrollResetTimer?.cancel();
    pageController?.dispose();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
        Logger.i('App paused - saving reading progress');
        _performSave(reason: 'App paused');
        break;
      case AppLifecycleState.detached:
        Logger.i('App detached - performing final save');
        _performFinalSave();
        break;
      case AppLifecycleState.resumed:
        Logger.i('App resumed');
        break;
      case AppLifecycleState.inactive:
        Logger.i('App inactive');
        break;
      case AppLifecycleState.hidden:
        Logger.i('App hidden - saving progress');
        _performSave(reason: 'App hidden');
        break;
    }
  }

  void _performSave({required String reason}) {
    try {
      if (!_canSaveProgress()) {
        Logger.i('Cannot save progress - invalid state ($reason)');
        return;
      }

      Logger.i('Saving reading progress - reason: $reason');
      _saveTracking();
    } catch (e) {
      Logger.i('Error during save ($reason): ${e.toString()}');
    }
  }

  void _performFinalSave() {
    try {
      if (!_canSaveProgress()) {
        Logger.i('Cannot perform final save - invalid state');
        return;
      }

      Logger.i('Performing final save');
      _saveTracking();

      final chapter = currentChapter.value;
      if (chapter != null &&
          chapter.pageNumber != null &&
          chapter.totalPages != null &&
          chapter.number != null &&
          chapter.pageNumber == chapter.totalPages &&
          chapterList.isNotEmpty &&
          chapterList.last.number != null &&
          chapterList.last.number! < chapter.number!) {
        serviceHandler.onlineService.updateListEntry(UpdateListEntryParams(
            listId: media.id,
            status: "CURRENT",
            progress: chapter.number!.toInt() + 1,
            syncIds: [media.idMal],
            isAnime: false));
      }
    } catch (e) {
      Logger.i('Error during final save: ${e.toString()}');
    }
  }

  bool _canSaveProgress() {
    final chapter = currentChapter.value;
    return chapter != null &&
        _isValidPageNumber(currentPageIndex.value) &&
        pageList.isNotEmpty;
  }

  void forceSave() {
    _performSave(reason: 'Manual save');
  }

  bool _isValidPageNumber(int pageNumber) {
    return pageNumber > 0 && pageNumber <= pageList.length;
  }

  void _safelyUpdateChapterPageNumber(int pageNumber) {
    final chapter = currentChapter.value;
    if (chapter != null && _isValidPageNumber(pageNumber)) {
      chapter.pageNumber = pageNumber;
    }
  }

  void _safelyUpdateTotalPages(int totalPages) {
    final chapter = currentChapter.value;
    if (chapter != null && totalPages > 0) {
      chapter.totalPages = totalPages;
    }
  }

  void _initializeControllers() {
    itemScrollController = ItemScrollController();
    scrollOffsetController = ScrollOffsetController();
    itemPositionsListener = ItemPositionsListener.create();
    scrollOffsetListener = ScrollOffsetListener.create();
    pageController = PreloadPageController(initialPage: 0);
    _setupPositionListener();
    _setupScrollListener();
  }

  void _getPreferences() {
    readingLayout.value = MangaPageViewMode.values[
        settingsController.preferences.get('reading_layout', defaultValue: 0)];
    readingDirection.value = MangaPageViewDirection.values[settingsController
        .preferences
        .get('reading_direction', defaultValue: 1)];
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

  void _setupScrollListener() {
    if (scrollOffsetListener != null) {
      scrollOffsetListener!.changes.listen(_onScrollChanged);
    }
  }

  void _onScrollChanged(double offset) {
    if (!overscrollToChapter.value ||
        readingLayout.value != MangaPageViewMode.continuous ||
        pageList.isEmpty ||
        _isNavigating) {
      return;
    }

    final positions = itemPositionsListener?.itemPositions.value;
    if (positions == null || positions.isEmpty) return;

    final lastPosition = positions.firstWhere(
      (pos) => pos.index == pageList.length - 1,
      orElse: () => positions.first,
    );

    final isAtLastPage = lastPosition.index == pageList.length - 1;

    final firstPosition = positions.firstWhere(
      (pos) => pos.index == 0,
      orElse: () => positions.first,
    );

    final isAtFirstPage = firstPosition.index == 0;

    // if (isAtLastPage &&
    //     canGoNext.value &&
    //     lastPosition.itemTrailingEdge <= 1.0) {
    //   if (!isOverscrolling.value) {
    //     _startOverscroll(true, offset);
    //   } else {
    //     _updateOverscroll(offset);
    //   }
    // } else if (isAtFirstPage &&
    //     canGoPrev.value &&
    //     firstPosition.itemLeadingEdge >= 0.0) {
    //   if (!isOverscrolling.value) {
    //     _startOverscroll(false, offset);
    //   } else {
    //     _updateOverscroll(offset);
    //   }
    // } else if (isOverscrolling.value) {
    //   _resetOverscroll();
    // }
  }

  void _startOverscroll(bool isNext, double offset) {
    isOverscrolling.value = true;
    isOverscrollingNext.value = isNext;
    _overscrollStartOffset = offset;
    overscrollProgress.value = 0.0;

    if (showControls.value) {
      showControls.value = false;
    }
  }

  void _updateOverscroll(double currentOffset) {
    final scrollDelta = (currentOffset - _overscrollStartOffset).abs();
    final progress = (scrollDelta / _maxOverscrollDistance).clamp(0.0, 1.0);

    overscrollProgress.value = progress;

    if (progress >= 1.0) {
      _triggerChapterChange();
    }

    _overscrollResetTimer?.cancel();
    _overscrollResetTimer = Timer(const Duration(milliseconds: 1000), () {
      if (overscrollProgress.value < 1.0) {
        _resetOverscroll();
      }
    });
  }

  void _resetOverscroll() {
    isOverscrolling.value = false;
    overscrollProgress.value = 0.0;
    _overscrollStartOffset = 0.0;
    _overscrollResetTimer?.cancel();
  }

  void _triggerChapterChange() {
    _resetOverscroll();
    chapterNavigator(isOverscrollingNext.value);
  }

  void _onPositionChanged() async {
    if (itemPositionsListener == null || pageList.isEmpty) return;

    final positions = itemPositionsListener!.itemPositions.value;
    if (positions.isEmpty || _isNavigating) return;

    ItemPosition? mostVisibleItem;
    double maxVisibleExtent = 0.0;

    final lastItemPosition = positions.firstWhere(
      (pos) => pos.index == pageList.length - 1,
      orElse: () => positions.first,
    );

    final isAtEnd = lastItemPosition.index == pageList.length - 1 &&
        lastItemPosition.itemTrailingEdge <= 1.0;

    for (final position in positions) {
      final leadingEdge = position.itemLeadingEdge;
      final trailingEdge = position.itemTrailingEdge;

      final visibleExtent =
          (math.min(1.0, trailingEdge) - math.max(0.0, leadingEdge))
              .clamp(0.0, 1.0);

      if (isAtEnd && position.index == pageList.length - 1) {
        if (visibleExtent > 0.3) {
          mostVisibleItem = position;
          break;
        }
      }

      if (visibleExtent > maxVisibleExtent) {
        maxVisibleExtent = visibleExtent;
        mostVisibleItem = position;
      }
    }

    if (mostVisibleItem == null) return;

    final number = mostVisibleItem.index + 1;

    if (!_isValidPageNumber(number)) return;

    if (number != currentPageIndex.value) {
      currentPageIndex.value = number;
      _safelyUpdateChapterPageNumber(number);
    }
  }

  void onPageChanged(int index) async {
    final number = index + 1;
    if (!_isValidPageNumber(number)) return;

    currentPageIndex.value = number;
    _safelyUpdateChapterPageNumber(number);
    _safelyUpdateTotalPages(pageList.length);
  }

  Future<void> init(Media data, List<Chapter> chList, Chapter curCh) async {
    media = data;
    chapterList = chList;
    currentChapter.value = curCh;
    serviceHandler = data.serviceType;
    _initializeControllers();
    _getPreferences();

    if (curCh.link != null) {
      fetchImages(curCh.link!);
    }
  }

  void _initTracking() {
    final chapter = currentChapter.value;
    if (chapter == null || chapter.number == null) return;

    savedChapter.value =
        offlineStorageController.getReadChapter(media.id, chapter.number!);

    if (savedChapter.value == null) {
      offlineStorageController.addOrUpdateManga(media, chapterList, chapter);
    }

    final chapterNumber = chapter.number?.toInt();
    if (chapterNumber != null) {
      serviceHandler.onlineService.updateListEntry(UpdateListEntryParams(
          listId: media.id,
          status: "CURRENT",
          progress: chapterNumber,
          syncIds: [media.idMal],
          isAnime: false));
    }
  }

  void _saveTracking() {
    final chapter = currentChapter.value;
    if (chapter == null) return;

    if (_isValidPageNumber(currentPageIndex.value)) {
      chapter.pageNumber = currentPageIndex.value;
    }

    offlineStorageController.addOrUpdateManga(media, chapterList, chapter);
    offlineStorageController.addOrUpdateReadChapter(media.id, chapter);
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

    _performSave(reason: 'Chapter navigation');

    currentChapter.value = chapterList[index];
    currentPageIndex.value = 1;

    final chapter = currentChapter.value;
    if (chapter?.link != null) {
      await fetchImages(chapter!.link!);
    }
  }

  void navigateToPage(int index) async {
    if (index < 0 || index >= pageList.length) return;

    final pageNumber = index + 1;
    if (!_isValidPageNumber(pageNumber)) return;

    currentPageIndex.value = pageNumber;

    if (readingLayout.value == MangaPageViewMode.continuous) {
      itemScrollController?.jumpTo(index: index);
    } else {
      Logger.i('[PAGE CONTROLLER] Navigating to page $index');
      pageController?.jumpToPage(index);
    }
  }

  void chapterNavigator(bool next) async {
    final current = currentChapter.value;
    if (current == null || current.number == null) return;

    final index = chapterList.indexOf(current);
    if (index == -1) return;

    final newIndex = next ? index + 1 : index - 1;
    if (newIndex >= 0 && newIndex < chapterList.length) {
      navigateToChapter(newIndex);
    }
  }

  void _syncAvailability() {
    final chapter = currentChapter.value;
    if (chapter == null) {
      canGoPrev.value = false;
      canGoNext.value = false;
      return;
    }

    final index = chapterList.indexOf(chapter);
    canGoPrev.value = index > 0;
    canGoNext.value = index < chapterList.length - 1;
  }

  Future<void> fetchImages(String url) async {
    _isNavigating = true;
    _resetOverscroll();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initTracking());
    currentPageIndex.value = 1;
    _syncAvailability();

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
        _safelyUpdateTotalPages(pageList.length);

        final saved = savedChapter.value;
        if (saved != null &&
            saved.pageNumber != null &&
            _isValidPageNumber(saved.pageNumber!)) {
          _safelyUpdateTotalPages(pageList.length);

          if (saved.pageNumber! > 1) {
            currentPageIndex.value = saved.pageNumber!;
            await Future.delayed(const Duration(milliseconds: 100));
            navigateToPage(saved.pageNumber! - 1);
          }
        }
      } else {
        throw Exception('No pages found for this chapter');
      }
    } catch (e) {
      Logger.i('Error fetching images: ${e.toString()}');
      loadingState.value = LoadingState.error;
      errorMessage.value = e.toString();
    } finally {
      _isNavigating = false;
      _syncAvailability();
    }
  }

  void retryFetchImages() {
    final chapter = currentChapter.value;
    if (chapter?.link != null) {
      fetchImages(chapter!.link!);
    }
  }

  void changeReadingLayout(MangaPageViewMode mode) async {
    readingLayout.value = mode;

    await Future.delayed(const Duration(milliseconds: 300), () {
      navigateToPage(currentPageIndex.value - 1);
    });
    savePreferences();
  }

  void changeReadingDirection(MangaPageViewDirection direction) async {
    readingDirection.value = direction;
    savePreferences();
  }

  void savePreferences() => _savePreferences();
}
