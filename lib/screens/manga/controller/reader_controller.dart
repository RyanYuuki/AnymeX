import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:anymex/controllers/discord/discord_rpc.dart';
import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/service_handler/params.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/database/isar_models/chapter.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/services/volume_key_handler.dart';
import 'package:anymex/utils/logger.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:preload_page_view/preload_page_view.dart';
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

  bool get isSpread => page2 != null;
  int get pageCount => isSpread ? 2 : 1;

  ReaderPage({required this.page1, this.page2});
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

  ItemScrollController? itemScrollController;
  ScrollOffsetController? scrollOffsetController;
  ItemPositionsListener? itemPositionsListener;

  // Tap Zones
  final TapZoneRepository _tapRepo = TapZoneRepository();
  final Rx<TapZoneLayout> pagedProfile = TapZoneLayout.defaultPaged.obs;
  final Rx<TapZoneLayout> pagedVerticalProfile =
      TapZoneLayout.defaultPagedVertical.obs;
  final Rx<TapZoneLayout> webtoonHorizontalProfile =
      TapZoneLayout.defaultWebtoonHorizontal.obs;

  final Rx<TapZoneLayout> webtoonProfile = TapZoneLayout.defaultWebtoon.obs;
  final RxBool tapZonesEnabled = true.obs;
  ScrollOffsetListener? scrollOffsetListener;
  PhotoViewController? photoViewController;

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
  final Rx<DualPageMode> dualPageMode = DualPageMode.off.obs;

  final RxBool cropImages = false.obs;

  final RxBool volumeKeysEnabled = false.obs;
  final RxBool invertVolumeKeys = false.obs;

  final RxBool showControls = true.obs;

  final Rx<LoadingState> loadingState = LoadingState.loading.obs;
  final RxString errorMessage = ''.obs;

  final Map<int, double> imageHeights = {};
  final totalOffset = 0.0.obs;

  bool get isDualPage {
    switch (dualPageMode.value) {
      case DualPageMode.off:
        return false;
      case DualPageMode.force:
        return true;
      case DualPageMode.auto:
        if (readingLayout.value == MangaPageViewMode.continuous) return false;

        return Get.width > 600;
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

    if (!isDualPage) {
      for (var page in pageList) {
        spreads.add(ReaderPage(page1: page));
      }
    } else {
      for (int i = 0; i < pageList.length; i += 2) {
        final page1 = pageList[i];
        final page2 = (i + 1 < pageList.length) ? pageList[i + 1] : null;
        spreads.add(ReaderPage(page1: page1, page2: page2));
      }
    }

    _syncPageToSpread();
  }

  void _syncPageToSpread() {
    if (readingLayout.value == MangaPageViewMode.paged &&
        pageController != null &&
        pageController!.hasClients) {
      int spreadIndex = 0;
      int accumulatedPages = 0;

      for (int i = 0; i < spreads.length; i++) {
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
  static const double _dragRate = 0.5;
  static const int _dragDivider = 5;

  double get _maxDistance => Get.height / _dragDivider;

  bool _isNavigating = false;

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
    final double offset =
        (Get.height * 0.7) * scrollSpeedMultiplier.value;

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
    final double offset =
        (Get.height * 0.7) * scrollSpeedMultiplier.value;

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
      _saveTracking();
      if (!shouldTrack) return;
      final chapter = currentChapter.value;
      if (chapter != null &&
          chapter.pageNumber != null &&
          chapter.totalPages != null &&
          chapter.number != null &&
          chapter.pageNumber == chapter.totalPages) {
        
        final int currentOnlineProgress = int.tryParse(serviceHandler.onlineService.currentMedia.value.episodeCount ?? '0') ?? 0;
        
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
    } catch (e) {
      Logger.i('Error during final save: ${e.toString()}');
    }
  }

  bool _canSaveProgress({Chapter? manualChapter, int? manualPage}) {
    final chapter = manualChapter ?? currentChapter.value;
    final page = manualPage ?? currentPageIndex.value;
    return chapter != null && _isValidPageNumber(page) && pageList.isNotEmpty;
  }

  void _saveTracking({Chapter? manualChapter, int? manualPage}) {
    final chapter = manualChapter ?? currentChapter.value;
    if (chapter == null) return;

    final page = manualPage ?? currentPageIndex.value;

    if (_isValidPageNumber(page)) {
      chapter.pageNumber = page;
    }

    offlineStorageController.addOrUpdateManga(media, chapterList, chapter);
    offlineStorageController.addOrUpdateReadChapter(media.id, chapter);
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
    pageController = PreloadPageController(initialPage: 0);
    _setupPositionListener();
    _setupScrollListener();
  }

  void _getPreferences() {
    readingLayout.value = MangaPageViewMode.values[
        ReaderKeys.readingLayout.get<int>(0)];
    readingDirection.value = MangaPageViewDirection.values[
        ReaderKeys.readingDirection.get<int>(1)];
    pageWidthMultiplier.value = ReaderKeys.imageWidth.get<double>(1);
    scrollSpeedMultiplier.value =
        ReaderKeys.scrollSpeed.get<double>(1);
    spacedPages.value = ReaderKeys.spacedPages.get<bool>(false);
    overscrollToChapter.value =
        ReaderKeys.overscrollToChapter.get<bool>(true);
    preloadPages.value = ReaderKeys.preloadPages.get<int>(3);
    showPageIndicator.value =
        ReaderKeys.showPageIndicator.get<bool>(false);
    // Both features: crop images AND volume keys
    cropImages.value = ReaderKeys.cropImages.get<bool>(false);
    volumeKeysEnabled.value =
        ReaderKeys.volumeKeysEnabled.get<bool>(false);
    invertVolumeKeys.value =
        ReaderKeys.invertVolumeKeys.get<bool>(false);

    final dualPageVal = ReaderKeys.dualPageMode.get<int?>();
    if (dualPageVal != null) {
      dualPageMode.value = DualPageMode.values[dualPageVal];
    }

    final modeIndex = ReaderKeys.readingLayout.get<int?>();
    if (modeIndex != null) {
      readingLayout.value = MangaPageViewMode.values[modeIndex];
    }

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
    // Both features: crop images AND volume keys
    ReaderKeys.cropImages.set(cropImages.value);
    ReaderKeys.volumeKeysEnabled.set(volumeKeysEnabled.value);
    ReaderKeys.invertVolumeKeys.set(invertVolumeKeys.value);
    ReaderKeys.dualPageMode.set(dualPageMode.value.index);
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

  double _virtualOverscrollPixels = 0.0;

  bool onScrollNotification(ScrollNotification notification) {
    if (!overscrollToChapter.value || _isNavigating) {
      return false;
    }

    if (!isOverscrolling.value) {
      bool isUserDrag = false;
      if (notification is ScrollUpdateNotification &&
          notification.dragDetails != null) {
        isUserDrag = true;
      } else if (notification is OverscrollNotification &&
          notification.dragDetails != null) {
        isUserDrag = true;
      }

      if (!isUserDrag) return false;
    }

    final metrics = notification.metrics;

    if (metrics.pixels > metrics.maxScrollExtent) {
      // Bo
      final delta = metrics.pixels - metrics.maxScrollExtent;
      _virtualOverscrollPixels = delta * _dragRate;
      _updateOverscrollProgress(true);
      return false;
    } else if (metrics.pixels < metrics.minScrollExtent) {
      // Top
      final delta = (metrics.pixels - metrics.minScrollExtent).abs();
      _virtualOverscrollPixels = delta * _dragRate;
      _updateOverscrollProgress(false);
      return false;
    }

    if (notification is OverscrollNotification &&
        notification.overscroll != 0) {
      final ovs = notification.overscroll;
      final isNext = ovs > 0;

      if (isOverscrolling.value && isOverscrollingNext.value != isNext) {
        _resetOverscroll();
        return false;
      }

      _virtualOverscrollPixels += ovs.abs() * _dragRate;
      _updateOverscrollProgress(isNext);
    } else if (notification is ScrollUpdateNotification &&
        notification.scrollDelta != null &&
        isOverscrolling.value) {
      final delta = notification.scrollDelta!;

      if (isOverscrollingNext.value) {
        _virtualOverscrollPixels += delta * _dragRate;
      } else {
        _virtualOverscrollPixels -= delta * _dragRate;
      }

      if (_virtualOverscrollPixels < 0) _virtualOverscrollPixels = 0;
      _updateOverscrollProgress(isOverscrollingNext.value);
    }

    if (isOverscrolling.value &&
        _virtualOverscrollPixels <= 0.1 &&
        metrics.pixels >= metrics.minScrollExtent &&
        metrics.pixels <= metrics.maxScrollExtent) {
      _resetOverscroll();
    }

    return false;
  }

  void _updateOverscrollProgress(bool isNext) {
    final progress = (_virtualOverscrollPixels / _maxDistance).clamp(0.0, 1.0);
    _handleOverscrollUpdate(progress, isNext);
  }

  void onPointerDown(PointerDownEvent event) {
    isOverscrolling.value = false;
    overscrollProgress.value = 0.0;
    _virtualOverscrollPixels = 0.0;
  }

  void onPointerUp(PointerUpEvent event) {
    if (isOverscrolling.value && overscrollProgress.value >= 1.0) {
      if (isOverscrollingNext.value) {
        if (canGoNext.value) {
          chapterNavigator(true);
        }
      } else {
        if (canGoPrev.value) {
          chapterNavigator(false);
        }
      }
    }
    _resetOverscroll();
  }

  void _handleOverscrollUpdate(double progress, bool isNext) {
    if (!isOverscrolling.value) {
      if (progress <= 0.05) return;

      isOverscrolling.value = true;
      isOverscrollingNext.value = isNext;
      if (showControls.value) showControls.value = false;

      HapticFeedback.selectionClick();
    }

    if ((progress - overscrollProgress.value).abs() > 0.01 ||
        progress <= 0.0 ||
        progress >= 1.0) {
      if (overscrollProgress.value < 1.0 && progress >= 1.0) {
        triggerHapticFeedback();
      }

      overscrollProgress.value = progress;
    }
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
    _virtualOverscrollPixels = 0.0;
    _mouseResetTimer?.cancel();
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

    pagedProfile.value = _tapRepo.getPagedLayout();
    pagedVerticalProfile.value = _tapRepo.getPagedVerticalLayout();
    webtoonHorizontalProfile.value = _tapRepo.getWebtoonHorizontalLayout();

    webtoonProfile.value = _tapRepo.getWebtoonLayout();
    tapZonesEnabled.value = _tapRepo.getTapZonesEnabled();

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

    if (!shouldTrack) return;

    final chapterNumber = chapter.number?.toInt();
    if (chapterNumber != null) {
      final int currentOnlineProgress = int.tryParse(serviceHandler.onlineService.currentMedia.value.episodeCount ?? '0') ?? 0;
      
      if (chapterNumber > currentOnlineProgress) {
        serviceHandler.onlineService.updateListEntry(UpdateListEntryParams(
            listId: media.id,
            status: "CURRENT",
            progress: chapterNumber,
            syncIds: [media.idMal],
            isAnime: false));
      }
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

  void navigateToPage(int index) async {
    if (index < 0 || index >= pageList.length) return;

    final pageNumber = index + 1;
    if (!_isValidPageNumber(pageNumber)) return;

    currentPageIndex.value = pageNumber;

    if (readingLayout.value == MangaPageViewMode.continuous) {
      itemScrollController?.jumpTo(index: index);
    } else {
      if (!isDualPage) {
        pageController?.jumpToPage(index);
      } else {
        int spreadIndex = 0;

        for (int i = 0; i < spreads.length; i++) {
          if (spreads[i].page1 == pageList[index] ||
              spreads[i].page2 == pageList[index]) {
            spreadIndex = i;
            break;
          }
        }
        pageController?.jumpToPage(spreadIndex);
      }
    }
  }

  void chapterNavigator(bool next) async {
    final current = currentChapter.value;
    if (current == null || current.number == null) return;

    final index = chapterList.indexWhere(
        (c) => c.number == current.number || c.link == current.link);
    if (index == -1) return;

    final newIndex = next ? index + 1 : index - 1;
    if (newIndex >= 0 && newIndex < chapterList.length) {
      navigateToChapter(newIndex);
    } else {
      if (next) {
        Get.snackbar(
          "Last Chapter",
          "There are no more chapters.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.black.withOpacity(0.8),
          colorText: Colors.white,
          margin: const EdgeInsets.all(20),
          duration: const Duration(seconds: 2),
          isDismissible: true,
        );
      } else {
        Get.snackbar(
          "First Chapter",
          "This is the first chapter.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.black.withOpacity(0.8),
          colorText: Colors.white,
          margin: const EdgeInsets.all(20),
          duration: const Duration(seconds: 2),
          isDismissible: true,
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

        _computeSpreads();

        currentPageIndex.value = 1;
        _safelyUpdateTotalPages(pageList.length);

        _initTracking();

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
        print("INTIAL CHAPTER ${currentChapter.value?.toJson()}");
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
    if (readingLayout.value == MangaPageViewMode.continuous) {
      if (readingDirection.value.axis == Axis.horizontal) {
        layout = webtoonHorizontalProfile.value;
      } else {
        layout = webtoonProfile.value;
      }
    } else {
      if (readingDirection.value.axis == Axis.vertical) {
        layout = pagedVerticalProfile.value;
      } else {
        layout = pagedProfile.value;
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

  void _navNextChapter() {
    chapterNavigator(true);
  }

  void _navPrevChapter() {
    chapterNavigator(false);
  }

  void _navNextPage() {
    navigateToPage(currentPageIndex.value);
  }

  void _navPrevPage() {
    navigateToPage(currentPageIndex.value - 2);
  }

  void _scrollUp() {
    if (scrollOffsetController != null) {
      scrollOffsetController!.animateScroll(
        offset: -Get.height * 0.75,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _scrollDown() {
    if (scrollOffsetController != null) {
      scrollOffsetController!.animateScroll(
        offset: Get.height * 0.75,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }
}
