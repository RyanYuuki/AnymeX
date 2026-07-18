import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:anymex/controllers/discord/discord_rpc.dart';
import 'package:anymex/controllers/services/storage/anymex_cache_manager.dart';
import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/service_handler/params.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/controllers/sync/gist_sync_controller.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/database/isar_models/chapter.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/services/volume_key_handler.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:photo_view/photo_view.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../models/reader/tap_zones.dart';
import '../../../repositories/tap_zone_repository.dart';

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

enum DualPageMode {
  off,
  auto,
  force;

  @override
  String toString() => switch (this) {
        DualPageMode.off => 'Off',
        DualPageMode.auto => 'Auto (Landscape)',
        DualPageMode.force => 'Force (Always)',
      };
}

class ReaderPage {
  final PageUrl? page1;
  final PageUrl? page2;
  final Chapter? chapter;
  final bool isTransition;
  final bool isNextTransition;

  bool get isSpread => page2 != null;
  int get pageCount => isTransition ? 0 : (isSpread ? 2 : 1);

  ReaderPage({
    this.page1,
    this.page2,
    this.chapter,
    this.isTransition = false,
    this.isNextTransition = true,
  });
}

class ReaderController extends GetxController with WidgetsBindingObserver {
  late Media media;
  late List<Chapter> chapterList;
  final Rxn<Chapter> currentChapter = Rxn();
  final Rxn<Chapter> savedChapter = Rxn();
  final RxList<PageUrl> pageList = RxList();
  final RxList<ReaderPage> spreads = RxList();
  late ServicesType serviceHandler;
  final bool shouldTrack;

  ReaderController({
    required this.shouldTrack,
  });

  final SourceController sourceController = Get.find<SourceController>();
  final OfflineStorageController offlineStorageController =
      Get.find<OfflineStorageController>();
  final RxInt currentPageIndex = 1.obs;
  final RxDouble pageWidthMultiplier = 1.0.obs;
  final RxDouble scrollSpeedMultiplier = 1.0.obs;
  final Map<String, double> pageAspectRatios = {};
  ItemScrollController? itemScrollController;
  ScrollOffsetController? scrollOffsetController;
  ItemPositionsListener? itemPositionsListener;
  final TapZoneRepository _tapRepo = TapZoneRepository();
  final Rx<TapZoneLayout> pagedProfile = TapZoneLayout.defaultPaged.obs;
  final Rx<TapZoneLayout> pagedVerticalProfile =
      TapZoneLayout.defaultPagedVertical.obs;
  final Rx<TapZoneLayout> webtoonHorizontalProfile =
      TapZoneLayout.defaultWebtoonHorizontal.obs;
  final Rx<TapZoneLayout> webtoonProfile = TapZoneLayout.defaultWebtoon.obs;
  final RxBool tapZonesEnabled = true.obs;
  final RxBool activeTapIsWebtoon = false.obs;
  final RxBool activeTapIsVertical = false.obs;
  ScrollOffsetListener? scrollOffsetListener;
  PhotoViewController? photoViewController;
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
  final Rx<DualPageMode> dualPageMode = DualPageMode.off.obs;
  final RxBool cropImages = false.obs;
  final RxBool fitToScreen = false.obs;
  final RxBool volumeKeysEnabled = false.obs;
  final RxBool invertVolumeKeys = false.obs;
  final RxBool autoScrollEnabled = false.obs;
  final RxDouble autoScrollSpeed = 3.0.obs;
  Timer? _autoScrollTimer;
  Timer? _autoScrollResumeTimer;
  static const Duration _autoScrollResumeDebounce = Duration(milliseconds: 300);
  final RxBool showControls = true.obs;
  final Rx<LoadingState> loadingState = LoadingState.loading.obs;
  final RxString errorMessage = ''.obs;
  final Map<int, double> imageHeights = {};
  final totalOffset = 0.0.obs;
  final RxBool customBrightnessEnabled = false.obs;
  final RxInt customBrightnessValue = 0.obs;
  final RxBool colorFilterEnabled = false.obs;
  final RxInt colorFilterValue = 0x00000000.obs;
  final RxInt colorFilterMode = 0.obs;
  final RxBool grayscaleEnabled = false.obs;
  final RxBool invertColorsEnabled = false.obs;
  final RxInt readerTheme = 1.obs;
  final RxBool keepScreenOn = true.obs;
  final RxBool alwaysShowChapterTransition = false.obs;
  final RxBool longPressPageActionsEnabled = true.obs;
  final RxBool autoWebtoonMode = false.obs;
  final RxBool navigateByNumber = false.obs;
  final RxBool displayRefreshEnabled = false.obs;
  final RxInt displayRefreshDurationMs = 200.obs;
  final RxInt displayRefreshInterval = 1.obs;
  final RxString displayRefreshColor = 'black'.obs;
  final RxInt imageFilterQuality = 2.obs;
  final RxBool showingTransition = false.obs;
  final RxBool transitionIsNext = true.obs;
  final Rx<Chapter?> transitionTargetChapter = Rx<Chapter?>(null);

  bool get isDualPage {
    switch (dualPageMode.value) {
      case DualPageMode.off:
        return false;
      case DualPageMode.force:
        return true;
      case DualPageMode.auto:
        if (readingLayout.value == MangaPageViewMode.continuous) return false;
        final size = MediaQuery.sizeOf(Get.context!);
        return size.width > 600;
    }
  }

  void toggleDualPageMode(DualPageMode mode) {
    dualPageMode.value = mode;
    savePreferences();
    _computeSpreads();
  }

  void _computeSpreads() {
    spreads.clear();
    if (pageList.isEmpty) return;

    final current = currentChapter.value;
    if (current == null) return;

    if (overscrollToChapter.value && canGoPrev.value) {
      spreads.add(ReaderPage(
        page1: null,
        isTransition: true,
        isNextTransition: false,
        chapter: current,
      ));
    }

    if (!isDualPage) {
      for (var page in pageList) {
        spreads.add(ReaderPage(page1: page, chapter: current));
      }
    } else {
      for (int i = 0; i < pageList.length; i += 2) {
        final page1 = pageList[i];
        final page2 = (i + 1 < pageList.length) ? pageList[i + 1] : null;
        spreads.add(ReaderPage(page1: page1, page2: page2, chapter: current));
      }
    }

    if (overscrollToChapter.value) {
      spreads.add(ReaderPage(
        page1: null,
        isTransition: true,
        isNextTransition: true,
        chapter: current,
      ));
    }

    _syncPageToSpread();
  }

  Future<List<PageUrl>> _fetchChapterPages(Chapter chapter) async {
    if (chapter.localPath != null && Directory(chapter.localPath!).existsSync()) {
      final dir = Directory(chapter.localPath!);
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) =>
              f.path.endsWith('.jpg') ||
              f.path.endsWith('.jpeg') ||
              f.path.endsWith('.png') ||
              f.path.endsWith('.webp'))
          .toList();
      files.sort((a, b) => a.path.compareTo(b.path));
      return files.map((f) => PageUrl(f.path)).toList();
    } else if (chapter.link != null) {
      return await sourceController.activeMangaSource.value!.methods
          .getPageList(DEpisode(episodeNumber: '1', url: chapter.link!));
    }
    return [];
  }

  final Set<String> _loadingChapterLinks = {};

  Future<void> loadNextChapterInline() async {
    if (!overscrollToChapter.value || _isNavigating) return;

    final lastLoaded = loadedChapters.isNotEmpty ? loadedChapters.last : currentChapter.value;
    if (lastLoaded == null) return;

    final curIdx = chapterList.indexOf(lastLoaded);
    if (curIdx == -1 || curIdx >= chapterList.length - 1) return;

    final nextChapterObj = chapterList[curIdx + 1];
    if (loadedChapters.contains(nextChapterObj) ||
        _loadingChapterLinks.contains(nextChapterObj.link)) {
      return;
    }

    _loadingChapterLinks.add(nextChapterObj.link ?? '');

    try {
      final nextPages = await _fetchChapterPages(nextChapterObj);
      if (nextPages.isEmpty) {
        _loadingChapterLinks.remove(nextChapterObj.link);
        return;
      }

      loadedChapterPages[nextChapterObj.link!] = nextPages;

      final List<ReaderPage> newSpreads = [];
      if (!isDualPage) {
        for (var page in nextPages) {
          newSpreads.add(ReaderPage(page1: page, chapter: nextChapterObj));
        }
      } else {
        for (int i = 0; i < nextPages.length; i += 2) {
          final page1 = nextPages[i];
          final page2 = (i + 1 < nextPages.length) ? nextPages[i + 1] : null;
          newSpreads.add(ReaderPage(page1: page1, page2: page2, chapter: nextChapterObj));
        }
      }

      newSpreads.add(ReaderPage(
        page1: null,
        isTransition: true,
        isNextTransition: true,
        chapter: nextChapterObj,
      ));

      spreads.addAll(newSpreads);
      loadedChapters.add(nextChapterObj);
    } catch (e) {
      if (kDebugMode) {
        print("Error loading next chapter inline: $e");
      }
    } finally {
      _loadingChapterLinks.remove(nextChapterObj.link);
    }
  }

  Future<void> loadPreviousChapterInline() async {
    if (!overscrollToChapter.value || _isNavigating) return;

    final firstLoaded = loadedChapters.isNotEmpty ? loadedChapters.first : currentChapter.value;
    if (firstLoaded == null) return;

    final curIdx = chapterList.indexOf(firstLoaded);
    if (curIdx <= 0) return;

    final prevChapterObj = chapterList[curIdx - 1];
    if (loadedChapters.contains(prevChapterObj) ||
        _loadingChapterLinks.contains(prevChapterObj.link)) {
      return;
    }

    _loadingChapterLinks.add(prevChapterObj.link ?? '');

    try {
      final prevPages = await _fetchChapterPages(prevChapterObj);
      if (prevPages.isEmpty) {
        _loadingChapterLinks.remove(prevChapterObj.link);
        return;
      }

      loadedChapterPages[prevChapterObj.link!] = prevPages;

      final List<ReaderPage> newSpreads = [];

      final prevIdx = chapterList.indexOf(prevChapterObj);
      if (prevIdx > 0) {
        newSpreads.add(ReaderPage(
          page1: null,
          isTransition: true,
          isNextTransition: false,
          chapter: prevChapterObj,
        ));
      }

      if (!isDualPage) {
        for (var page in prevPages) {
          newSpreads.add(ReaderPage(page1: page, chapter: prevChapterObj));
        }
      } else {
        for (int i = 0; i < prevPages.length; i += 2) {
          final page1 = prevPages[i];
          final page2 = (i + 1 < prevPages.length) ? prevPages[i + 1] : null;
          newSpreads.add(ReaderPage(page1: page1, page2: page2, chapter: prevChapterObj));
        }
      }

      _isNavigating = true;
      spreads.insertAll(0, newSpreads);
      loadedChapters.insert(0, prevChapterObj);

      final prevPageCount = newSpreads.length;
      if (readingLayout.value == MangaPageViewMode.continuous) {
        final positions = itemPositionsListener?.itemPositions.value;
        if (positions != null && positions.isNotEmpty) {
          final firstVisible = positions.first;
          itemScrollController?.jumpTo(
            index: firstVisible.index + prevPageCount,
            alignment: firstVisible.itemLeadingEdge,
          );
        }
      } else {
        pageController?.jumpToPage(pageController!.page!.toInt() + prevPageCount);
      }
      _isNavigating = false;
    } catch (e) {
      if (kDebugMode) {
        print("Error loading previous chapter inline: $e");
      }
    } finally {
      _loadingChapterLinks.remove(prevChapterObj.link);
    }
  }

  void _syncPageToSpread() {
    if (readingLayout.value == MangaPageViewMode.paged &&
        pageController != null &&
        pageController!.hasClients) {
      int spreadIndex = 0;
      int accumulatedPages = 0;

      for (int i = 0; i < spreads.length; i++) {
        if (spreads[i].isTransition) continue;
        accumulatedPages += spreads[i].pageCount;
        if (accumulatedPages >= currentPageIndex.value) {
          spreadIndex = i;
          break;
        }
      }

      pageController!.jumpToPage(spreadIndex);
    }
  }

  RxBool canGoNext = false.obs;
  RxBool canGoPrev = false.obs;
  final RxBool isOverscrolling = false.obs;
  final RxDouble overscrollProgress = 0.0.obs;
  final RxBool isOverscrollingNext = true.obs;
  bool _isNavigating = false;
  final RxList<Chapter> loadedChapters = RxList();
  final Map<String, List<PageUrl>> loadedChapterPages = {};

  late Worker _rpcWorker;
  final VolumeKeyHandler _volumeKeyHandler = VolumeKeyHandler();
  StreamSubscription? _volumeSubscription;

  @override
  void onInit() {
    super.onInit();
    WakelockPlus.enable();
    WidgetsBinding.instance.addObserver(this);
    _performSave(reason: 'Page opened');

    _rpcWorker = ever(currentChapter, (_) {
      DiscordRPCController.instance.updateMangaPresence(
          manga: media,
          chapter: currentChapter.value!,
          totalChapters: chapterList.length.toString(),
          currentPage: 1);
    });

    ever(readingLayout, (_) => _computeSpreads());
    _loadTapZones();
  }

  void _loadTapZones() {
    pagedProfile.value = _tapRepo.getPagedLayout();
    pagedVerticalProfile.value = _tapRepo.getPagedVerticalLayout();
    webtoonProfile.value = _tapRepo.getWebtoonLayout();
    webtoonHorizontalProfile.value = _tapRepo.getWebtoonHorizontalLayout();
    tapZonesEnabled.value = _tapRepo.getTapZonesEnabled();
    activeTapIsWebtoon.value = _tapRepo.getActiveIsWebtoon();
    activeTapIsVertical.value = _tapRepo.getActiveIsVertical();
  }

  void _enableVolumeKeys() {
    _volumeKeyHandler.enableInterception();
    _volumeSubscription?.cancel();
    _volumeSubscription = _volumeKeyHandler.volumeEvents.listen((event) {
      _handleVolumeEvent(event);
    });
  }

  void _handleVolumeEvent(String event) {
    if (Get.isBottomSheetOpen == true ||
        Get.isDialogOpen == true ||
        Get.isOverlaysOpen == true) {
      return;
    }

    if (showControls.value) {
      toggleControls();
      return;
    }

    if (event == 'up') {
      if (invertVolumeKeys.value) {
        navigateForward();
      } else {
        navigateBackward();
      }
    } else if (event == 'down') {
      if (invertVolumeKeys.value) {
        navigateBackward();
      } else {
        navigateForward();
      }
    }
  }

  void _disableVolumeKeys() {
    _volumeKeyHandler.disableInterception();
    _volumeSubscription?.cancel();
    _volumeSubscription = null;
  }

  void navigateForward() {
    final isReversed = readingDirection.value.reversed;

    if (readingLayout.value == MangaPageViewMode.continuous) {
      final double offset = (Get.height * 0.7) * scrollSpeedMultiplier.value;

      scrollOffsetController?.animateScroll(
        offset: isReversed ? -offset : offset,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      if (isReversed) {
        pageController?.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        pageController?.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void navigateBackward() {
    final isReversed = readingDirection.value.reversed;

    if (readingLayout.value == MangaPageViewMode.continuous) {
      final double offset = (Get.height * 0.7) * scrollSpeedMultiplier.value;

      scrollOffsetController?.animateScroll(
        offset: isReversed ? offset : -offset,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      if (isReversed) {
        pageController?.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        pageController?.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void toggleVolumeKeys() {
    volumeKeysEnabled.value = !volumeKeysEnabled.value;
    if (volumeKeysEnabled.value) {
      _enableVolumeKeys();
    } else {
      _disableVolumeKeys();
    }
    savePreferences();
  }

  void pauseVolumeKeys() {
    _disableVolumeKeys();
  }

  void resumeVolumeKeys() {
    if (volumeKeysEnabled.value) {
      _enableVolumeKeys();
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);

    Future.microtask(() {
      _performFinalSave();
    });

    DiscordRPCController.instance.updateMediaPresence(
      media: media,
    );

    _rpcWorker.dispose();
    WakelockPlus.disable();
    _disableVolumeKeys();

    pageController?.dispose();
    _autoScrollResumeTimer?.cancel();
    _stopAutoScroll();
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
        if (volumeKeysEnabled.value) {
          _enableVolumeKeys();
        }
        break;
      case AppLifecycleState.inactive:
        _performSave(reason: "App inactive");
        Logger.i('App inactive');
        break;
      case AppLifecycleState.hidden:
        Logger.i('App hidden - saving progress');
        _performSave(reason: 'App hidden');
        _disableVolumeKeys();
        break;
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();

    if (dualPageMode.value == DualPageMode.auto) {
      Future.delayed(const Duration(milliseconds: 200), () {
        _computeSpreads();
      });
    }
  }

  void _performSave(
      {required String reason, Chapter? manualChapter, int? manualPage}) {
    try {
      if (!_canSaveProgress(
          manualChapter: manualChapter, manualPage: manualPage)) {
        Logger.i('Cannot save progress - invalid state ($reason)');
        return;
      }

      Logger.i('Saving reading progress - reason: $reason');
      _saveTracking(manualChapter: manualChapter, manualPage: manualPage);
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
      _saveTracking(syncToCloud: false);
      final chapter = currentChapter.value;
      if (chapter == null) return;

      unawaited(_syncCloudProgressOnExit(chapter));

      if (!shouldTrack) return;
      if (chapter.pageNumber != null &&
          chapter.totalPages != null &&
          chapter.number != null &&
          chapter.totalPages! > 0) {
        final pageNum = chapter.pageNumber!;
        final totalPgs = chapter.totalPages!;
        final isChapterComplete = pageNum >= totalPgs ||
            pageNum >= totalPgs - 1 ||
            (pageNum / totalPgs) >= 0.95;
        if (isChapterComplete) {
          final int currentOnlineProgress = int.tryParse(
                  serviceHandler.onlineService.currentMedia.value.episodeCount ??
                      '0') ??
              0;

          final int newProgress = chapter.number!.toInt();

          if (newProgress > currentOnlineProgress) {
            serviceHandler.onlineService.updateListEntry(UpdateListEntryParams(
                listId: media.id,
                status: "CURRENT",
                progress: newProgress,
                syncIds: [media.idMal],
                isAnime: false));
          }
        }
      }
    } catch (e) {
      Logger.i('Error during final save: ${e.toString()}');
    }
  }

  Future<void> _syncCloudProgressOnExit(Chapter chapter) async {
    final syncCtrl = Get.isRegistered<GistSyncController>()
        ? Get.find<GistSyncController>()
        : null;
    if (syncCtrl == null) {
      return;
    }

    final shouldRemove = syncCtrl.autoDeleteCompletedOnExit.value &&
        _hasFinishedCurrentMedia(chapter);

    await syncCtrl.syncChapterProgressOnExit(
      mediaId: media.id,
      malId: media.idMal,
      mediaType: media.mediaType == ItemType.novel ? 'novel' : 'manga',
      chapter: chapter,
      isCompleted: shouldRemove,
    );
  }

  bool _hasFinishedCurrentMedia(Chapter chapter) {
    final chapterNumber = chapter.number;
    final pageNumber = chapter.pageNumber;
    final totalPages = chapter.totalPages;

    if (chapterNumber == null ||
        pageNumber == null ||
        totalPages == null ||
        totalPages <= 0) {
      return false;
    }

    final isChapterComplete = pageNumber >= totalPages ||
        pageNumber >= totalPages - 1 ||
        (pageNumber / totalPages) >= 0.95;

    if (!isChapterComplete) return false;

    final totalChapters = double.tryParse(media.totalChapters ?? '');
    if (totalChapters != null && totalChapters > 0) {
      return chapterNumber >= totalChapters;
    }

    for (final item in chapterList) {
      final itemNumber = item.number;
      if (itemNumber != null && itemNumber > chapterNumber) {
        return false;
      }
    }
    return chapterList.isNotEmpty;
  }

  bool _canSaveProgress({Chapter? manualChapter, int? manualPage}) {
    final chapter = manualChapter ?? currentChapter.value;
    final page = manualPage ?? currentPageIndex.value;
    return chapter != null && _isValidPageNumber(page) && pageList.isNotEmpty;
  }

  void _saveTracking({
    Chapter? manualChapter,
    int? manualPage,
    bool syncToCloud = true,
  }) {
    final chapter = manualChapter ?? currentChapter.value;
    if (chapter == null) return;

    final page = manualPage ?? currentPageIndex.value;

    if (_isValidPageNumber(page)) {
      chapter.pageNumber = page;
    }

    offlineStorageController.addOrUpdateManga(media, chapterList, chapter);
    offlineStorageController.addOrUpdateReadChapter(
      media.id,
      chapter,
      syncToCloud: syncToCloud,
    );
  }

  void toggleAutoScroll() {
    autoScrollEnabled.value = !autoScrollEnabled.value;
    if (autoScrollEnabled.value) {
      _startAutoScroll();
    } else {
      _stopAutoScroll();
    }
    savePreferences();
  }

  void setAutoScrollSpeed(double speed) {
    autoScrollSpeed.value = speed;
    if (autoScrollEnabled.value) {
      _stopAutoScroll();
      _startAutoScroll();
    }
    savePreferences();
  }

  void _startAutoScroll() {
    _stopAutoScroll();
    if (readingLayout.value == MangaPageViewMode.continuous) {
      final pixelsPerSecond = Get.height / autoScrollSpeed.value;
      const double maxOffset = 500000.0;
      final durationMs = (maxOffset / pixelsPerSecond * 1000).toInt();

      final isReversed = readingDirection.value.reversed;
      scrollOffsetController?.animateScroll(
        offset: isReversed ? -maxOffset : maxOffset,
        duration: Duration(milliseconds: durationMs),
        curve: Curves.linear,
      );
      
      _autoScrollTimer = Timer(Duration(milliseconds: durationMs), () {
        if (autoScrollEnabled.value) {
          _startAutoScroll();
        }
      });
    } else {
      _autoScrollTimer = Timer.periodic(
        Duration(milliseconds: (autoScrollSpeed.value * 1000).toInt()),
        (_) {
          if (!autoScrollEnabled.value) {
            _stopAutoScroll();
            return;
          }
          navigateForward();
        },
      );
    }
  }

  void _stopAutoScroll() {
    if (_autoScrollTimer != null) {
      _autoScrollTimer!.cancel();
      _autoScrollTimer = null;
      if (readingLayout.value == MangaPageViewMode.continuous) {
        try {
          scrollOffsetController?.animateScroll(
            offset: 0,
            duration: const Duration(milliseconds: 10),
            curve: Curves.linear,
          );
        } catch (_) {}
      }
    }
  }

  void navigateToChapter(int index) async {
    if (index < 0 || index >= chapterList.length) return;

    final oldChapter = currentChapter.value;
    final oldPage = currentPageIndex.value;

    Future.microtask(() {
      _performSave(
          reason: 'Chapter navigation',
          manualChapter: oldChapter,
          manualPage: oldPage);
    });

    currentChapter.value = chapterList[index];
    currentPageIndex.value = 1;

    final chapter = currentChapter.value;
    if (chapter?.link != null) {
      await fetchImages(chapter!.link!);
    } else {
      _isNavigating = false;
    }
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
    pageController = PageController(initialPage: 0);
    _setupPositionListener();
    _setupScrollListener();
  }

  void _getPreferences() {
    readingLayout.value =
        MangaPageViewMode.values[ReaderKeys.readingLayout.get<int>(0)];
    readingDirection.value =
        MangaPageViewDirection.values[ReaderKeys.readingDirection.get<int>(1)];
    pageWidthMultiplier.value = ReaderKeys.imageWidth.get<double>(1);
    scrollSpeedMultiplier.value = ReaderKeys.scrollSpeed.get<double>(1);
    spacedPages.value = ReaderKeys.spacedPages.get<bool>(false);
    overscrollToChapter.value = ReaderKeys.overscrollToChapter.get<bool>(true);
    preloadPages.value = ReaderKeys.preloadPages.get<int>(3);
    showPageIndicator.value = ReaderKeys.showPageIndicator.get<bool>(false);
    autoScrollEnabled.value = ReaderKeys.autoScrollEnabled.get<bool>(false);
    autoScrollSpeed.value = ReaderKeys.autoScrollSpeed.get<double>(3.0);
    cropImages.value = ReaderKeys.cropImages.get<bool>(false);
    fitToScreen.value = ReaderKeys.fitToScreen.get<bool>(false);
    volumeKeysEnabled.value = ReaderKeys.volumeKeysEnabled.get<bool>(false);
    invertVolumeKeys.value = ReaderKeys.invertVolumeKeys.get<bool>(false);

    final dualPageVal = ReaderKeys.dualPageMode.get<int?>();
    if (dualPageVal != null) {
      dualPageMode.value = DualPageMode.values[dualPageVal];
    }

    final modeIndex = ReaderKeys.readingLayout.get<int?>();
    if (modeIndex != null) {
      readingLayout.value = MangaPageViewMode.values[modeIndex];
    }

    customBrightnessEnabled.value =
        ReaderKeys.customBrightnessEnabled.get<bool>(false);
    customBrightnessValue.value = ReaderKeys.customBrightnessValue.get<int>(0);
    colorFilterEnabled.value = ReaderKeys.colorFilterEnabled.get<bool>(false);
    colorFilterValue.value = ReaderKeys.colorFilterValue.get<int>(0);
    colorFilterMode.value = ReaderKeys.colorFilterMode.get<int>(0);
    grayscaleEnabled.value = ReaderKeys.grayscaleEnabled.get<bool>(false);
    invertColorsEnabled.value = ReaderKeys.invertColorsEnabled.get<bool>(false);
    readerTheme.value = ReaderKeys.readerTheme.get<int>(1);
    keepScreenOn.value = ReaderKeys.keepScreenOn.get<bool>(true);
    alwaysShowChapterTransition.value =
        ReaderKeys.alwaysShowChapterTransition.get<bool>(false);
    longPressPageActionsEnabled.value =
        ReaderKeys.longPressPageActionsEnabled.get<bool>(true);
    autoWebtoonMode.value = ReaderKeys.autoWebtoonMode.get<bool>(false);
    navigateByNumber.value = ReaderKeys.navigateByNumber.get<bool>(false);
    displayRefreshEnabled.value =
        ReaderKeys.displayRefreshEnabled.get<bool>(false);
    displayRefreshDurationMs.value =
        ReaderKeys.displayRefreshDurationMs.get<int>(200);
    displayRefreshInterval.value =
        ReaderKeys.displayRefreshInterval.get<int>(1);
    displayRefreshColor.value =
        ReaderKeys.displayRefreshColor.get<String>('black');
    imageFilterQuality.value =
        ReaderKeys.imageFilterQuality.get<int>(2);

    if (!keepScreenOn.value) WakelockPlus.disable();

    if (volumeKeysEnabled.value) {
      _enableVolumeKeys();
    }
  }

  void _savePreferences() {
    ReaderKeys.readingLayout.set(readingLayout.value.index);
    ReaderKeys.readingDirection.set(readingDirection.value.index);
    ReaderKeys.imageWidth.set(pageWidthMultiplier.value);
    ReaderKeys.scrollSpeed.set(scrollSpeedMultiplier.value);
    ReaderKeys.spacedPages.set(spacedPages.value);
    ReaderKeys.overscrollToChapter.set(overscrollToChapter.value);
    ReaderKeys.preloadPages.set(preloadPages.value);
    ReaderKeys.showPageIndicator.set(showPageIndicator.value);
    ReaderKeys.autoScrollEnabled.set(autoScrollEnabled.value);
    ReaderKeys.autoScrollSpeed.set(autoScrollSpeed.value);
    ReaderKeys.cropImages.set(cropImages.value);
    ReaderKeys.fitToScreen.set(fitToScreen.value);
    ReaderKeys.volumeKeysEnabled.set(volumeKeysEnabled.value);
    ReaderKeys.invertVolumeKeys.set(invertVolumeKeys.value);
    ReaderKeys.dualPageMode.set(dualPageMode.value.index);
    ReaderKeys.customBrightnessEnabled.set(customBrightnessEnabled.value);
    ReaderKeys.customBrightnessValue.set(customBrightnessValue.value);
    ReaderKeys.colorFilterEnabled.set(colorFilterEnabled.value);
    ReaderKeys.colorFilterValue.set(colorFilterValue.value);
    ReaderKeys.colorFilterMode.set(colorFilterMode.value);
    ReaderKeys.grayscaleEnabled.set(grayscaleEnabled.value);
    ReaderKeys.invertColorsEnabled.set(invertColorsEnabled.value);
    ReaderKeys.readerTheme.set(readerTheme.value);
    ReaderKeys.keepScreenOn.set(keepScreenOn.value);
    ReaderKeys.alwaysShowChapterTransition
        .set(alwaysShowChapterTransition.value);
    ReaderKeys.longPressPageActionsEnabled
        .set(longPressPageActionsEnabled.value);
    ReaderKeys.autoWebtoonMode.set(autoWebtoonMode.value);
    ReaderKeys.navigateByNumber.set(navigateByNumber.value);
    ReaderKeys.displayRefreshEnabled.set(displayRefreshEnabled.value);
    ReaderKeys.displayRefreshDurationMs.set(displayRefreshDurationMs.value);
    ReaderKeys.displayRefreshInterval.set(displayRefreshInterval.value);
    ReaderKeys.displayRefreshColor.set(displayRefreshColor.value);
    ReaderKeys.imageFilterQuality.set(imageFilterQuality.value);
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
  bool onScrollNotification(ScrollNotification notification) {
    if (!overscrollToChapter.value || _isNavigating) {
      return false;
    }

    final metrics = notification.metrics;

    if (metrics.pixels > metrics.maxScrollExtent) {
      final delta = metrics.pixels - metrics.maxScrollExtent;
      if (delta > 40) {
        final lastLoaded = loadedChapters.isNotEmpty ? loadedChapters.last : currentChapter.value;
        if (lastLoaded != null) {
          final curIdx = chapterList.indexOf(lastLoaded);
          if (curIdx == chapterList.length - 1) {
            _isNavigating = true;
            snackBar(
              title: "Last Chapter",
              "There are no more chapters.",
            );
            Future.delayed(const Duration(seconds: 2), () => _isNavigating = false);
          }
        }
      }
      return false;
    } else if (metrics.pixels < metrics.minScrollExtent) {
      final delta = (metrics.pixels - metrics.minScrollExtent).abs();
      if (delta > 40) {
        final firstLoaded = loadedChapters.isNotEmpty ? loadedChapters.first : currentChapter.value;
        if (firstLoaded != null) {
          final curIdx = chapterList.indexOf(firstLoaded);
          if (curIdx == 0) {
            _isNavigating = true;
            snackBar(
              title: "First Chapter",
              "This is the first chapter.",
            );
            Future.delayed(const Duration(seconds: 2), () => _isNavigating = false);
          }
        }
      }
      return false;
    }

    return false;
  }
  void onPointerDown(PointerDownEvent event) {
    _resetOverscroll();
    if (autoScrollEnabled.value) {
      _autoScrollResumeTimer?.cancel();
      _stopAutoScroll();
    }
  }

  void onPointerUp(PointerUpEvent event) {
    _resetOverscroll();
    if (autoScrollEnabled.value) {
      _scheduleAutoScrollResume();
    }
  }

  void onPointerCancel(PointerCancelEvent event) {
    _resetOverscroll();
    if (autoScrollEnabled.value) {
      _scheduleAutoScrollResume();
    }
  }

  void _scheduleAutoScrollResume() {
    _autoScrollResumeTimer?.cancel();
    _autoScrollResumeTimer = Timer(_autoScrollResumeDebounce, () {
      if (autoScrollEnabled.value) {
        _startAutoScroll();
      }
    });
  }



  void _onScrollChanged(double offset) {}

  Timer? _mouseResetTimer;
  double _mouseWheelAccumulator = 0.0;
  int _lastMouseTurnTime = 0;

  void handleMouseScroll(double delta, {bool isTrackpad = false}) {
    if (!overscrollToChapter.value || _isNavigating) return;

    final isNext = delta > 0;

    bool atEdge = false;
    if (readingLayout.value == MangaPageViewMode.continuous) {
      final positions = itemPositionsListener?.itemPositions.value;
      if (positions != null && positions.isNotEmpty) {
        if (isNext) {
          final last = positions
              .where((p) => p.index == spreads.length - 1)
              .fold<ItemPosition?>(null, (prev, curr) => curr);
          if (last != null && last.itemTrailingEdge <= 1.0) {
            atEdge = true;
          }
        } else {
          final first = positions
              .where((p) => p.index == 0)
              .fold<ItemPosition?>(null, (prev, curr) => curr);
          if (first != null && first.itemLeadingEdge >= 0.0) {
            atEdge = true;
          }
        }
      }
    } else {
      if (isNext) {
        if (pageController != null && pageController!.hasClients) {
          if (pageController!.page! >= spreads.length - 1) {
            atEdge = true;
          }
        }
      } else {
        if (pageController != null && pageController!.hasClients) {
          if (pageController!.page! <= 0) {
            atEdge = true;
          }
        }
      }
    }

    if (!atEdge) {
      if (readingLayout.value == MangaPageViewMode.continuous) {
        if (readingDirection.value.axis == Axis.horizontal) {
          scrollOffsetController?.animateScroll(
              offset: delta * scrollSpeedMultiplier.value * 2.2,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut);
        }
      } else {
        _mouseWheelAccumulator += delta;

        const double threshold = 40.0;

        if (_mouseWheelAccumulator.abs() > threshold) {
          final now = DateTime.now().millisecondsSinceEpoch;

          if (now - _lastMouseTurnTime > 100) {
            if (_mouseWheelAccumulator > 0) {
              navigateForward();
            } else {
              navigateBackward();
            }
            _lastMouseTurnTime = now;
          }
          _mouseWheelAccumulator = 0.0;
        }
      }
      return;
    }

    _mouseResetTimer?.cancel();

    if (!isOverscrolling.value) {
      isOverscrolling.value = true;
      isOverscrollingNext.value = isNext;
      if (showControls.value) showControls.value = false;
      HapticFeedback.selectionClick();
    }

    final sensitivity = isTrackpad ? 0.005 : 0.002;
    final add = (delta.abs() * sensitivity).clamp(0.0, 1.0);
    double newProgress = overscrollProgress.value + add;

    if (newProgress >= 1.0) {
      newProgress = 1.0;

      if (overscrollProgress.value < 1.0) {
        triggerHapticFeedback();
      }

      if (!isTrackpad) {
        if (isNext) {
          if (canGoNext.value) chapterNavigator(true);
        } else {
          if (canGoPrev.value) chapterNavigator(false);
        }
        _resetOverscroll();
      }
    }

    overscrollProgress.value = newProgress;

    if (!isTrackpad) {
      _mouseResetTimer = Timer(const Duration(milliseconds: 800), () {
        _resetOverscroll();
      });
    }
  }

  void handleOverscrollEnd() {
    if (overscrollProgress.value >= 1.0) {
      if (isOverscrollingNext.value) {
        chapterNavigator(true);
      } else {
        chapterNavigator(false);
      }
    }
    _resetOverscroll();
  }

  void _resetOverscroll() {
    isOverscrolling.value = false;
    overscrollProgress.value = 0.0;
    _mouseResetTimer?.cancel();
  }


  void _onPositionChanged() async {
    if (itemPositionsListener == null || spreads.isEmpty) return;

    final positions = itemPositionsListener!.itemPositions.value;
    if (positions.isEmpty || _isNavigating) return;

    ItemPosition? mostVisibleItem;
    double maxVisibleExtent = 0.0;

    final lastItemPosition = positions.firstWhere(
      (pos) => pos.index == spreads.length - 1,
      orElse: () => positions.first,
    );

    final isAtEnd = lastItemPosition.index == spreads.length - 1 &&
        lastItemPosition.itemTrailingEdge <= 1.0;

    for (final position in positions) {
      final leadingEdge = position.itemLeadingEdge;
      final trailingEdge = position.itemTrailingEdge;
      final visibleExtent =
          (math.min(1.0, trailingEdge) - math.max(0.0, leadingEdge))
              .clamp(0.0, 1.0);

      if (isAtEnd && position.index == spreads.length - 1) {
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

    final index = mostVisibleItem.index;
    if (index < 0 || index >= spreads.length) return;

    if (index >= spreads.length - 2) {
      loadNextChapterInline();
    } else if (index <= 1) {
      loadPreviousChapterInline();
    }

    final spread = spreads[index];
    if (spread.isTransition) return;

    final activeChapter = spread.chapter;
    if (activeChapter == null) return;

    _updatePageStateForSpread(index, activeChapter);
  }

  void _updatePageStateForSpread(int index, Chapter activeChapter) {
    final activeKey = activeChapter.link ?? activeChapter.localPath ?? '';
    final activePages = loadedChapterPages[activeKey] ?? [];
    final activeTotalPages = activePages.isEmpty ? pageList.length : activePages.length;

    // Count how many pages of this chapter have been shown up to this spread index
    int startIdx = spreads.indexWhere(
        (s) => s.chapter == activeChapter && !s.isTransition);
    int chapterPageIndex = 1;
    if (startIdx != -1 && index >= startIdx) {
      int acc = 0;
      for (int i = startIdx; i <= index; i++) {
        if (spreads[i].chapter == activeChapter && !spreads[i].isTransition) {
          acc += spreads[i].pageCount;
        }
      }
      chapterPageIndex = acc > 0 ? acc : 1;
    }

    if (currentChapter.value != activeChapter) {
      currentChapter.value = activeChapter;
      _syncAvailability();
      _initTracking();
      DiscordRPCController.instance.updateMangaPresence(
          manga: media,
          chapter: activeChapter,
          totalChapters: chapterList.length.toString());
    }

    // Sync pageList to the active chapter so the slider max/length is correct
    if (activePages.isNotEmpty &&
        (pageList.length != activePages.length ||
            (pageList.isNotEmpty && pageList.first.url != activePages.first.url))) {
      pageList.assignAll(activePages);
    }

    if (chapterPageIndex != currentPageIndex.value) {
      currentPageIndex.value = chapterPageIndex;
      _safelyUpdateChapterPageNumber(chapterPageIndex);
      _safelyUpdateTotalPages(activeTotalPages);
    }
  }

  void onPageChanged(int index) {
    if (index < 0 || index >= spreads.length) return;

    if (index >= spreads.length - 2) {
      loadNextChapterInline();
    } else if (index <= 1) {
      loadPreviousChapterInline();
    }

    final spread = spreads[index];
    if (spread.isTransition) return;

    final activeChapter = spread.chapter;
    if (activeChapter == null) return;

    _updatePageStateForSpread(index, activeChapter);
  }

  void preloadNextPages(int currentIndex) {
    final limit = preloadPages.value;
    if (limit <= 0 || pageList.isEmpty) return;

    final sourceController = Get.find<SourceController>();

    for (int i = 1; i <= limit; i++) {
      final nextIndex = currentIndex + i;
      if (nextIndex < 0 || nextIndex >= pageList.length) break;

      final page = pageList[nextIndex];
      final url = page.url;
      if (url.startsWith('http')) {
        final headers = (page.headers?.isEmpty ?? true)
            ? {
                'Referer': sourceController.activeMangaSource.value?.baseUrl ?? ''
              }
            : page.headers;

        AnymeXCacheManager.instance.getSingleFile(url, headers: headers).then((_) {}, onError: (_) {});
      }
    }
  }
  Future<void> init(Media data, List<Chapter> chList, Chapter curCh) async {
    media = data;
    chapterList = chList;
    currentChapter.value = curCh;
    serviceHandler = data.serviceType;
    _initializeControllers();
    _getPreferences();
    _applyAutoWebtoonMode();

    ever(currentPageIndex, (indexVal) {
      preloadNextPages(indexVal - 1);
    });

    pagedProfile.value = _tapRepo.getPagedLayout();
    pagedVerticalProfile.value = _tapRepo.getPagedVerticalLayout();
    webtoonHorizontalProfile.value = _tapRepo.getWebtoonHorizontalLayout();
    webtoonProfile.value = _tapRepo.getWebtoonLayout();
    tapZonesEnabled.value = _tapRepo.getTapZonesEnabled();
    activeTapIsWebtoon.value = _tapRepo.getActiveIsWebtoon();
    activeTapIsVertical.value = _tapRepo.getActiveIsVertical();

    DiscordRPCController.instance.updateMangaPresence(
        manga: media,
        chapter: currentChapter.value!,
        totalChapters: chapterList.length.toString());

    if (curCh.link != null) {
      fetchImages(curCh.link!);
    }
  }

  void _initTracking() async {
    final chapter = currentChapter.value;
    if (chapter == null || chapter.number == null) return;

    savedChapter.value =
        offlineStorageController.getReadChapter(media.id, chapter.number!);

    if (savedChapter.value == null) {
      offlineStorageController.addOrUpdateManga(media, chapterList, chapter);
    }

    _resumeFromCloudIfNewer();

    if (!shouldTrack) return;

    final chapterNumber = chapter.number?.toInt();
    if (chapterNumber != null) {
      final int currentOnlineProgress = int.tryParse(
              serviceHandler.onlineService.currentMedia.value.episodeCount ??
                  '0') ??
          0;

      final int newProgress = chapterNumber - 1;

      if (newProgress > currentOnlineProgress) {
        serviceHandler.onlineService.updateListEntry(UpdateListEntryParams(
            listId: media.id,
            status: "CURRENT",
            progress: newProgress,
            syncIds: [media.idMal],
            isAnime: false));
      }
    }
  }

  Future<void> _resumeFromCloudIfNewer() async {
    final ctrl = Get.isRegistered<GistSyncController>()
        ? Get.find<GistSyncController>()
        : null;
    if (ctrl == null || !ctrl.isLoggedIn.value || !ctrl.syncEnabled.value) {
      return;
    }
    try {
      final chapter = currentChapter.value;
      if (chapter == null || chapter.number == null) return;
      final localUpdated = chapter.lastReadTime ?? 0;

      final entry = await ctrl
          .fetchNewerChapterProgress(
            mediaId: media.id,
            malId: media.idMal.toString(),
            mediaType: 'manga',
            chapterNumber: chapter.number!,
            localUpdatedAt: localUpdated,
          )
          .timeout(const Duration(seconds: 4), onTimeout: () => null);

      if (entry != null && entry.pageNumber != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (entry.pageNumber! > 0 && entry.pageNumber! <= pageList.length) {
            navigateToPage(entry.pageNumber! - 1);
          }
        });
      }
    } catch (e) {
      Logger.i('[MangaReader] Failed to resume progress from cloud: $e');
    }
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

  void toggleCropImages() {
    cropImages.value = !cropImages.value;
    savePreferences();
  }

  void toggleFitToScreen() {
    fitToScreen.value = !fitToScreen.value;
    savePreferences();
  }

  void toggleCustomBrightness() {
    customBrightnessEnabled.value = !customBrightnessEnabled.value;
    savePreferences();
  }

  void toggleColorFilter() {
    colorFilterEnabled.value = !colorFilterEnabled.value;
    savePreferences();
  }

  void setColorFilterChannel(String channel, int value) {
    final cur = colorFilterValue.value;
    colorFilterValue.value = switch (channel) {
      'r' => (cur & 0xFF00FFFF) | ((value & 0xFF) << 16),
      'g' => (cur & 0xFFFF00FF) | ((value & 0xFF) << 8),
      'b' => (cur & 0xFFFFFF00) | (value & 0xFF),
      'a' => (cur & 0x00FFFFFF) | ((value & 0xFF) << 24),
      _ => cur,
    };
  }

  void toggleGrayscale() {
    grayscaleEnabled.value = !grayscaleEnabled.value;
    savePreferences();
  }

  void toggleInvertColors() {
    invertColorsEnabled.value = !invertColorsEnabled.value;
    savePreferences();
  }

  void toggleKeepScreenOn() {
    keepScreenOn.value = !keepScreenOn.value;
    if (keepScreenOn.value) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
    savePreferences();
  }

  void toggleAlwaysShowChapterTransition() {
    alwaysShowChapterTransition.value = !alwaysShowChapterTransition.value;
    savePreferences();
  }

  void toggleLongPressPageActions() {
    longPressPageActionsEnabled.value = !longPressPageActionsEnabled.value;
    savePreferences();
  }

  void toggleAutoWebtoonMode() {
    autoWebtoonMode.value = !autoWebtoonMode.value;
    if (autoWebtoonMode.value) {
      _applyAutoWebtoonMode();
    }
    savePreferences();
  }

  void toggleNavigateByNumber() {
    navigateByNumber.value = !navigateByNumber.value;
    savePreferences();
    _syncAvailability();
  }

  void toggleDisplayRefresh() {
    displayRefreshEnabled.value = !displayRefreshEnabled.value;
    savePreferences();
  }

  void setImageFilterQuality(int value) {
    imageFilterQuality.value = value;
    savePreferences();
  }

  void maybeShowChapterTransition(bool next) {
    final current = currentChapter.value;
    if (current == null) return;

    final curIdx = chapterList.indexWhere(
        (c) => c.number == current.number || c.link == current.link);
    if (curIdx == -1) return;

    final targetIdx = next ? curIdx + 1 : curIdx - 1;
    final target = (targetIdx >= 0 && targetIdx < chapterList.length)
        ? chapterList[targetIdx]
        : null;

    final gap = (target?.number != null && current.number != null)
        ? (next
                ? (target!.number! - current.number! - 1)
                : (current.number! - target!.number! - 1))
            .toInt()
        : 0;

    final shouldShow = alwaysShowChapterTransition.value || gap > 0;

    if (shouldShow) {
      transitionIsNext.value = next;
      transitionTargetChapter.value = target;
      showingTransition.value = true;
    } else {
      chapterNavigator(next);
    }
  }

  void dismissTransition() {
    showingTransition.value = false;
    chapterNavigator(transitionIsNext.value);
  }

  void navigateToPage(int index) async {
    final activeChapter = currentChapter.value;
    if (activeChapter == null) return;

    final activePages = loadedChapterPages[activeChapter.link] ?? [];
    if (index < 0 || index >= activePages.length) return;

    final pageNumber = index + 1;
    currentPageIndex.value = pageNumber;
    _safelyUpdateChapterPageNumber(pageNumber);

    int startIdx = spreads.indexWhere((s) => s.chapter == activeChapter && !s.isTransition);
    if (startIdx == -1) return;

    int spreadIndex = startIdx;
    int accumulatedPages = 0;
    for (int i = startIdx; i < spreads.length; i++) {
      if (spreads[i].chapter != activeChapter) break;
      if (spreads[i].isTransition) continue;
      accumulatedPages += spreads[i].pageCount;
      if (accumulatedPages >= pageNumber) {
        spreadIndex = i;
        break;
      }
    }

    if (readingLayout.value == MangaPageViewMode.continuous) {
      itemScrollController?.jumpTo(index: spreadIndex);
    } else {
      pageController?.jumpToPage(spreadIndex);
    }
  }

  void chapterNavigator(bool next) async {
    final current = currentChapter.value;
    if (current == null) return;

    _performSave(reason: "Saving before chapter is changed");

    final index = chapterList.indexWhere(
        (c) => c.number == current.number || c.link == current.link);
    if (index == -1) return;

    int newIndex = -1;
    if (navigateByNumber.value) {
      final currentNum = current.number;
      if (currentNum != null) {
        if (next) {
          for (int i = index + 1; i < chapterList.length; i++) {
            if (chapterList[i].number != currentNum) {
              newIndex = i;
              break;
            }
          }
        } else {
          for (int i = index - 1; i >= 0; i--) {
            if (chapterList[i].number != currentNum) {
              newIndex = i;
              break;
            }
          }
        }
      } else {
        newIndex = next ? index + 1 : index - 1;
      }
    } else {
      newIndex = next ? index + 1 : index - 1;
    }

    if (newIndex >= 0 && newIndex < chapterList.length) {
      navigateToChapter(newIndex);
    } else {
      if (next) {
        snackBar(
          title: "Last Chapter",
          "There are no more chapters.",
        );
      } else {
        snackBar(
          title: "First Chapter",
          "This is the first chapter.",
        );
      }
    }
  }

  void _syncAvailability() {
    final chapter = currentChapter.value;
    if (chapter == null) {
      canGoPrev.value = false;
      canGoNext.value = false;
      return;
    }

    final index = chapterList.indexWhere(
        (c) => c.number == chapter.number || c.link == chapter.link);
    if (index == -1) {
      canGoPrev.value = false;
      canGoNext.value = false;
      return;
    }

    if (navigateByNumber.value) {
      final currentNum = chapter.number;
      if (currentNum != null) {
        canGoPrev.value = chapterList.sublist(0, index).any((c) => c.number != currentNum);
        canGoNext.value = chapterList.sublist(index + 1).any((c) => c.number != currentNum);
      } else {
        canGoPrev.value = index > 0;
        canGoNext.value = index < chapterList.length - 1;
      }
    } else {
      canGoPrev.value = index > 0;
      canGoNext.value = index < chapterList.length - 1;
    }
  }

  Future<void> fetchImages(String url) async {
    final curChapter = currentChapter.value;
    _isNavigating = true;
    _resetOverscroll();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initTracking());
    currentPageIndex.value = 1;
    _syncAvailability();

    try {
      loadingState.value = LoadingState.loading;
      pageList.clear();
      errorMessage.value = '';

      List<PageUrl> data = [];

      if (curChapter?.localPath != null &&
          Directory(curChapter!.localPath!).existsSync()) {
        final dir = Directory(curChapter.localPath!);
        final files = dir
            .listSync()
            .whereType<File>()
            .where((f) =>
                f.path.endsWith('.jpg') ||
                f.path.endsWith('.jpeg') ||
                f.path.endsWith('.png') ||
                f.path.endsWith('.webp'))
            .toList();

        files.sort((a, b) => a.path.compareTo(b.path));

        data = files.map((f) => PageUrl(f.path)).toList();
      } else {
        data = await sourceController.activeMangaSource.value!.methods
            .getPageList(DEpisode(episodeNumber: '1', url: url));
      }
      if (data.isNotEmpty) {
        pageList.value = data;
        loadingState.value = LoadingState.loaded;

        loadedChapters.clear();
        loadedChapterPages.clear();
        if (currentChapter.value != null && currentChapter.value!.link != null) {
          loadedChapters.add(currentChapter.value!);
          loadedChapterPages[currentChapter.value!.link!] = data;
        }

        _computeSpreads();
        currentPageIndex.value = 1;
        _safelyUpdateTotalPages(pageList.length);

        _initTracking();
        preloadNextPages(currentPageIndex.value - 1);

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
    if (autoScrollEnabled.value) {
      autoScrollEnabled.value = false;
      _stopAutoScroll();
    }
    readingLayout.value = mode;

    await Future.delayed(const Duration(milliseconds: 300), () {
      navigateToPage(currentPageIndex.value - 1);
    });
    savePreferences();
  }

  void changeReadingDirection(MangaPageViewDirection direction) async {
    if (autoScrollEnabled.value) {
      autoScrollEnabled.value = false;
      _stopAutoScroll();
    }
    readingDirection.value = direction;
    savePreferences();
  }

  void savePreferences() => _savePreferences();

  Future<void> triggerHapticFeedback() async {
    try {
      await HapticFeedback.heavyImpact();

      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(duration: 50, amplitude: 128);
      }
    } catch (_) {}
  }

  void toggleTapZones(bool value) {
    tapZonesEnabled.value = value;
    _tapRepo.saveTapZonesEnabled(value);
  }

  void handleTap(Offset position) {
    if (showControls.value) {
      toggleControls();
      return;
    }

    if (!Platform.isAndroid && !Platform.isIOS) {
      toggleControls();
      return;
    }

    if (!tapZonesEnabled.value) {
      toggleControls();
      return;
    }

    final size = Get.size;
    if (size.isEmpty) return;

    final normalized = Offset((position.dx / size.width).clamp(0.0, 1.0),
        (position.dy / size.height).clamp(0.0, 1.0));

    TapZoneLayout layout;
    if (!activeTapIsWebtoon.value) {
      if (activeTapIsVertical.value) {
        layout = pagedVerticalProfile.value;
      } else {
        layout = pagedProfile.value;
      }
    } else {
      if (activeTapIsVertical.value) {
        layout = webtoonProfile.value;
      } else {
        layout = webtoonHorizontalProfile.value;
      }
    }

    final action = layout.getAction(normalized);
    executeAction(action);
  }

  void executeAction(ReaderAction action) {
    switch (action) {
      case ReaderAction.nextPage:
        _navNextPage();
        break;
      case ReaderAction.prevPage:
        _navPrevPage();
        break;
      case ReaderAction.toggleMenu:
        toggleControls();
        break;
      case ReaderAction.scrollUp:
        _scrollUp();
        break;
      case ReaderAction.scrollDown:
        _scrollDown();
        break;
      case ReaderAction.nextChapter:
        _navNextChapter();
        break;
      case ReaderAction.prevChapter:
        _navPrevChapter();
        break;
      case ReaderAction.none:
        break;
    }
  }

  void _navNextChapter() => chapterNavigator(true);
  void _navPrevChapter() => chapterNavigator(false);
  void _navNextPage() => navigateToPage(currentPageIndex.value);
  void _navPrevPage() => navigateToPage(currentPageIndex.value - 2);

  void _scrollUp() {
    final dist = readingDirection.value.axis == Axis.horizontal
        ? -Get.width * 0.75
        : -Get.height * 0.75;
    scrollOffsetController?.animateScroll(
      offset: dist,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    );
  }

  void _scrollDown() {
    final dist = readingDirection.value.axis == Axis.horizontal
        ? Get.width * 0.75
        : Get.height * 0.75;
    scrollOffsetController?.animateScroll(
      offset: dist,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    );
  }

  bool get _isWebtoon {
    final lowerFormat = media.format.toLowerCase();
    if (lowerFormat.contains('webtoon')) return true;
    
    for (final genre in media.genres) {
      final lg = genre.toLowerCase();
      if (lg.contains('webtoon') || lg.contains('manhwa') || lg.contains('long strip') || lg.contains('long-strip')) {
        return true;
      }
    }
    for (final tag in media.tags) {
      final lt = tag.name.toLowerCase();
      if (lt.contains('webtoon') || lt.contains('manhwa') || lt.contains('long strip') || lt.contains('long-strip')) {
        return true;
      }
    }
    return false;
  }

  void _applyAutoWebtoonMode() {
    if (autoWebtoonMode.value && _isWebtoon) {
      readingLayout.value = MangaPageViewMode.continuous;
      readingDirection.value = MangaPageViewDirection.down;
    }
  }
}
