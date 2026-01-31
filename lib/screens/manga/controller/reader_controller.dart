import 'dart:async';
import 'dart:math' as math;
import 'package:anymex/controllers/discord/discord_rpc.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/service_handler/params.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Offline/Hive/chapter.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:anymex/services/volume_key_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter/material.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:vibration/vibration.dart';

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
  ScrollOffsetListener? scrollOffsetListener;

  PreloadPageController? pageController;
  final RxBool spacedPages = false.obs;
  final RxBool overscrollToChapter = true.obs;

  final defaultWidth = 400.obs;
  final defaultSpeed = 300.obs;
  RxInt preloadPages = 5.obs;
  RxBool showPageIndicator = false.obs;
  final RxBool cropImages = false.obs;

  final Rx<MangaPageViewMode> readingLayout = MangaPageViewMode.continuous.obs;
  final Rx<MangaPageViewDirection> readingDirection =
      MangaPageViewDirection.down.obs;
  final Rx<DualPageMode> dualPageMode = DualPageMode.off.obs;

  final RxBool showControls = true.obs;
  final RxBool volumeKeysEnabled = false.obs;
  final RxBool invertVolumeKeys = false.obs;

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
     if (readingLayout.value == MangaPageViewMode.paged && pageController != null && pageController!.hasClients) {
       
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

    _rpcWorker = ever(currentPageIndex, (e) {
      DiscordRPCController.instance.updateMangaPresence(
          manga: media,
          chapter: currentChapter.value!,
          totalChapters: chapterList.length.toString(),
          currentPage: e);
    });

  
    ever(readingLayout, (_) => _computeSpreads());
    
  }

  void _enableVolumeKeys() {
     _volumeKeyHandler.enableInterception();
     _volumeSubscription?.cancel();
     _volumeSubscription = _volumeKeyHandler.volumeEvents.listen((event) {
       _handleVolumeEvent(event);
     });
  }

  void _handleVolumeEvent(String event) {
   
   
    if (Get.isBottomSheetOpen == true || Get.isDialogOpen == true || Get.isOverlaysOpen == true) {
      return;
    }

   
    if (showControls.value) {
      toggleControls();
      return;
    }

   
    if (event == 'up') {
      if (invertVolumeKeys.value) {
        _navigateForward();
      } else {
        _navigateBackward();
      }
    } else if (event == 'down') {
      if (invertVolumeKeys.value) {
        _navigateBackward();
      } else {
        _navigateForward();
      }
    }
  }

  void _disableVolumeKeys() {
     _volumeKeyHandler.disableInterception();
     _volumeSubscription?.cancel();
     _volumeSubscription = null;
  }

  void _navigateForward() {
    if (readingLayout.value == MangaPageViewMode.continuous) {
       final double offset = (Get.height * 0.7) * scrollSpeedMultiplier.value;
       scrollOffsetController?.animateScroll(
          offset: offset,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut);
    } else {
       pageController?.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  void _navigateBackward() {
     if (readingLayout.value == MangaPageViewMode.continuous) {
       final double offset = (Get.height * 0.7) * scrollSpeedMultiplier.value;
       scrollOffsetController?.animateScroll(
          offset: -offset,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut);
    } else {
       pageController?.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
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
      if (!_canSaveProgress(manualChapter: manualChapter, manualPage: manualPage)) {
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

  bool _canSaveProgress({Chapter? manualChapter, int? manualPage}) {
    final chapter = manualChapter ?? currentChapter.value;
    final page = manualPage ?? currentPageIndex.value;
    return chapter != null &&
        _isValidPageNumber(page) &&
        pageList.isNotEmpty;
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
        _performSave(reason: 'Chapter navigation', manualChapter: oldChapter, manualPage: oldPage);
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
    // Both features: crop images AND volume keys
    cropImages.value =
        settingsController.preferences.get('crop_images', defaultValue: false);
    volumeKeysEnabled.value =
        settingsController.preferences.get('volume_keys_enabled', defaultValue: false);
    invertVolumeKeys.value =
        settingsController.preferences.get('invert_volume_keys', defaultValue: false);
    
    final dualPageVal = settingsController.preferences.get('dual_page_mode');
    if (dualPageVal != null) {
      dualPageMode.value = DualPageMode.values[dualPageVal];
    }

    final modeIndex = settingsController.preferences.get('reading_layout');
    if (modeIndex != null) {
      readingLayout.value = MangaPageViewMode.values[modeIndex];
    }
    
    
    if (volumeKeysEnabled.value) {
      _enableVolumeKeys();
    }
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
    // Both features: crop images AND volume keys
    settingsController.preferences.put('crop_images', cropImages.value);
    
    
    settingsController.preferences.put('volume_keys_enabled', volumeKeysEnabled.value);
    settingsController.preferences.put('invert_volume_keys', invertVolumeKeys.value);
    settingsController.preferences.put('dual_page_mode', dualPageMode.value.index);
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
    if (!overscrollToChapter.value ||
        _isNavigating) {
      return false;
    }

    final metrics = notification.metrics;
    const maxDistance = 120.0;



    
    if (metrics.pixels > metrics.maxScrollExtent) {
      final delta = metrics.pixels - metrics.maxScrollExtent;
      final progress = (delta / maxDistance).clamp(0.0, 1.0);
      _handleOverscrollUpdate(progress, true);
    } else if (metrics.pixels < metrics.minScrollExtent) {
      final delta = (metrics.pixels - metrics.minScrollExtent).abs();
      final progress = (delta / maxDistance).clamp(0.0, 1.0);
      _handleOverscrollUpdate(progress, false);
    } else if (notification is OverscrollNotification && notification.overscroll != 0) {
        final ovs = notification.overscroll;
        final isNext = ovs > 0;
        
        double current = isOverscrollingNext.value == isNext ? overscrollProgress.value : 0.0;
        double add = (ovs.abs() / maxDistance); 
        
        double newProgress = (current + add).clamp(0.0, 1.0);
        _handleOverscrollUpdate(newProgress, isNext);
    }

    return false;
  }

  void onPointerDown(PointerDownEvent event) {
    isOverscrolling.value = false;
    overscrollProgress.value = 0.0;
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

  void _onScrollChanged(double offset) {
   
  }



  Timer? _mouseResetTimer;

  void handleMouseScroll(double delta, {bool isTrackpad = false}) {
    if (!overscrollToChapter.value || _isNavigating) return;

    final isNext = delta > 0;
    
    bool atEdge = false;
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

    if (!atEdge) return;

    _mouseResetTimer?.cancel();
    
    if (!isOverscrolling.value) {
        isOverscrolling.value = true;
        isOverscrollingNext.value = isNext;
        if (showControls.value) showControls.value = false;
        HapticFeedback.selectionClick();
    }
    
    final sensitivity = isTrackpad ? 0.005 : 0.03;
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
          if (canGoNext.value) chapterNavigator(true);
       } else {
          if (canGoPrev.value) chapterNavigator(false);
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
    DiscordRPCController.instance.updateMangaPresence(
        manga: media,
        chapter: currentChapter.value!,
        totalChapters: chapterList.length.toString());

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

    if (!shouldTrack) return;

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
            if (spreads[i].page1 == pageList[index] || spreads[i].page2 == pageList[index]) {
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
}