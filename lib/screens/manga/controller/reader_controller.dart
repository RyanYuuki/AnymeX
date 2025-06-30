// ignore_for_file: deprecated_member_use

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
import 'package:anymex/screens/manga/reading_page.dart';
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

  final Rx<ReadingMode> activeMode = ReadingMode.webtoon.obs;
  final RxInt currentPageIndex = 1.obs;
  final RxDouble pageWidthMultiplier = 1.0.obs;
  final RxDouble scrollSpeedMultiplier = 1.0.obs;
  final RxBool spacedPages = false.obs;

  final defaultWidth = 400.obs;
  final defaultSpeed = 300.obs;

  final RxBool showControls = true.obs;
  final Rx<LoadingState> loadingState = LoadingState.loading.obs;
  final RxString errorMessage = ''.obs;

  MangaPageViewController? pageViewController;

  void _initializeControllers() {
    pageViewController = MangaPageViewController();
    pageViewController?.addPageChangeListener(onPageChanged);
  }

  void _getPreferences() {
    activeMode.value = ReadingMode.values[
        settingsController.preferences.get('reading_mode', defaultValue: 0)];
    pageWidthMultiplier.value =
        settingsController.preferences.get('image_width') ?? 1;
    scrollSpeedMultiplier.value =
        settingsController.preferences.get('scroll_speed') ?? 1;
    spacedPages.value =
        settingsController.preferences.get('spaced_pages', defaultValue: false);
  }

  void _savePreferences() {
    settingsController.preferences.put('reading_mode', activeMode.value.index);
    settingsController.preferences
        .put('image_width', pageWidthMultiplier.value);
    settingsController.preferences
        .put('scroll_speed', scrollSpeedMultiplier.value);
    settingsController.preferences.put('spaced_pages', spacedPages.value);
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

    log('Saved chapter: ${savedChapter.value?.pageNumber} & current chapter: ${currentChapter.value?.number}');

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

  void toggleSpacedPages() {
    spacedPages.value = !spacedPages.value;
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
    final index = chapterList.indexOf(currentChapter.value!);
    if (index == -1) return;

    final newIndex = next ? index + 1 : index - 1;
    if (newIndex >= 0 && newIndex < chapterList.length) {
      navigateToChapter(newIndex);
    }
  }

  Future<void> fetchImages(String url) async {
    _initTracking();
    try {
      loadingState.value = LoadingState.loading;
      pageList.clear();
      errorMessage.value = '';

      final data = await getPagesList(
          source: sourceController.activeMangaSource.value!, mangaId: url);

      if (data != null && data.isNotEmpty) {
        pageList.value = data;
        currentPageIndex.value = savedChapter.value?.pageNumber ?? 1;

        currentChapter.value?.totalPages = pageList.length;
        loadingState.value = LoadingState.loaded;

        if (savedChapter.value?.pageNumber != null &&
            savedChapter.value!.pageNumber! > 1) {
          await Future.delayed(const Duration(milliseconds: 100));
          navigateToPage(savedChapter.value!.pageNumber! - 1);
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

  void changeActiveMode(ReadingMode readingMode) async {
    activeMode.value = readingMode;
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
