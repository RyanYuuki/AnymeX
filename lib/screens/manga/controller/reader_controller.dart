import 'dart:async';
import 'dart:developer';
import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/service_handler/params.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/core/Eval/dart/model/page.dart';
import 'package:anymex/core/Search/get_pages.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Offline/Hive/chapter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manga_page_view/manga_page_view.dart';

enum LoadingState { loading, loaded, error }

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

  final Rx<MangaPageViewMode> readingLayout = MangaPageViewMode.continuous.obs;
  final Rx<MangaPageViewDirection> readingDirection =
      MangaPageViewDirection.down.obs;
  final RxBool spacedPages = false.obs;
  final RxBool overscrollToChapter = true.obs;

  final defaultWidth = 400.obs;
  final defaultSpeed = 300.obs;
  RxInt preloadPages = 5.obs;
  RxBool showPageIndicator = false.obs;

  final RxBool showControls = true.obs;
  final Rx<LoadingState> loadingState = LoadingState.loading.obs;
  final RxString errorMessage = ''.obs;

  final Map<int, double> imageHeights = {};
  final totalOffset = 0.0.obs;

  RxBool canGoNext = false.obs;
  RxBool canGoPrev = false.obs;

  MangaPageViewController? pageViewController;

  void _initializeControllers() {
    pageViewController = MangaPageViewController();
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

  void onPageChanged(int index) async {
    final number = index + 1;
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
    log(showControls.value.toString());
    showControls.value = !showControls.value;
    log(showControls.value.toString());
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
    currentPageIndex.value = index + 1;
    pageViewController?.moveToPage(index);
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _initTracking());
    currentPageIndex.value = 1;
    try {
      loadingState.value = LoadingState.loading;
      pageList.clear();
      errorMessage.value = '';

      final data = await getPagesList(
          source: sourceController.activeMangaSource.value!, mangaId: url);

      if (data != null && data.isNotEmpty) {
        pageList.value = data;
        loadingState.value = LoadingState.loaded;

        if (savedChapter.value?.pageNumber != null &&
            savedChapter.value!.pageNumber! <= pageList.length) {
          currentPageIndex.value = savedChapter.value?.pageNumber ?? 1;
          currentChapter.value?.totalPages = pageList.length;
          _syncAvailability();

          if (savedChapter.value?.pageNumber != null &&
              savedChapter.value!.pageNumber! > 1) {
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

    pageViewController?.dispose();
    super.onClose();
  }
}
