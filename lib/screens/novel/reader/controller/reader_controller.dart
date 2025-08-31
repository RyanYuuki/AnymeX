import 'package:anymex/utils/logger.dart';

import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Offline/Hive/chapter.dart';
import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NovelReaderController extends GetxController {
  Chapter initialChapter;
  List<Chapter> chapters;
  Media media;
  Source source;

  NovelReaderController(
      {required this.initialChapter,
      required this.chapters,
      required this.media,
      required this.source});

  Rx<Chapter> currentChapter = Chapter().obs;
  RxString novelContent = ''.obs;
  Rx<LoadingState> loadingState = LoadingState.loading.obs;
  ScrollController scrollController = ScrollController();

  final offlineStorageController = Get.find<OfflineStorageController>();

  RxBool showControls = true.obs;
  RxBool showSettings = false.obs;

  RxDouble fontSize = 16.0.obs;
  RxDouble lineHeight = 1.6.obs;
  RxDouble letterSpacing = 0.0.obs;
  RxDouble wordSpacing = 0.0.obs;
  RxDouble paragraphSpacing = 16.0.obs;
  RxString fontFamily = 'System'.obs;
  RxInt textAlign = 0.obs;

  RxInt themeMode = 0.obs;
  RxDouble backgroundOpacity = 1.0.obs;

  // Navigation
  RxBool canGoNext = true.obs;
  RxBool canGoPrevious = true.obs;

  // Auto-hide timer
  RxBool autoHideEnabled = true.obs;

  // Page Indicatorssss
  RxDouble progress = 0.0.obs;
  RxInt consecutiveReads = 0.obs;

  Rx<Chapter> savedChapter = Chapter().obs;

  @override
  void onInit() {
    super.onInit();
    currentChapter.value = initialChapter;
    updateNavigationButtons();
    fetchData();
    scrollController.addListener(_scrollListener);
  }

  @override
  void onClose() {
    _saveTracking();
    scrollController.removeListener(_scrollListener);
    super.onClose();
  }

  void _scrollListener() {
    if (!scrollController.hasClients) return;
    if (loadingState.value == LoadingState.loading) return;

    double offset = scrollController.offset;
    double maxScrollExtent = scrollController.position.maxScrollExtent;

    if (scrollController.offset < 0) return;
    if (offset > maxScrollExtent) return;

    progress.value = offset / maxScrollExtent;

    int totalPages = (maxScrollExtent / Get.height).ceil() + 1;
    int currentPage = (offset / Get.height).floor() + 1;

    currentChapter.value.currentOffset = offset;
    currentChapter.value.maxOffset = maxScrollExtent;
    currentChapter.value.lastReadTime = DateTime.now().millisecondsSinceEpoch;
    currentChapter.value.pageNumber = currentPage;
    currentChapter.value.totalPages = totalPages;
  }

  Future<void> _waitForScrollAndJump() async {
    final current = savedChapter.value.currentOffset;
    final max = savedChapter.value.maxOffset;

    if (current == null || max == null) return;
    if (current < 0 || current > max) return;

    while (true) {
      await Future.delayed(const Duration(milliseconds: 50));

      if (!scrollController.hasClients) continue;
      if (scrollController.position.maxScrollExtent >= current) {
        scrollController.animateTo(current,
            duration: const Duration(
              milliseconds: 300,
            ),
            curve: Curves.easeInOut);
        break;
      }
    }
  }

  Future<void> fetchData() async {
    try {
      loadingState.value = LoadingState.loading;
      _saveTracking();
      final data = await source.methods.getNovelContent(
          currentChapter.value.title!, currentChapter.value.link!);
      if (data != null && data.isNotEmpty) {
        novelContent.value = _buildHtml(data);
      }
      loadingState.value = LoadingState.loaded;

      await _waitForScrollAndJump();
    } catch (e) {
      Logger.i(e.toString());
      loadingState.value = LoadingState.error;
    }
  }

  void _saveTracking() {
    consecutiveReads.value++;
    savedChapter.value = offlineStorageController.getReadChapter(
          media.id,
          currentChapter.value.number!,
        ) ??
        currentChapter.value;
    if (consecutiveReads.value > 1) {
      Future.microtask(() {
        offlineStorageController.addOrUpdateNovel(
            media, chapters, currentChapter.value, source);
        offlineStorageController.addOrUpdateReadChapter(
            media.id, currentChapter.value,
            source: source);
      });
    }
  }

  String _buildHtml(String input) {
    return '''<div id="readerViewContent"><div style="padding: 2em;">*$input*</div></div>'''
        .replaceAll("\\n", "")
        .replaceAll("\\t", "")
        .replaceAll("\\\"", "\"")
        .replaceAll('*"', '')
        .replaceAll('"*', '');
  }

  void toggleControls() {
    showControls.value = !showControls.value;
  }

  void toggleSettings() {
    showSettings.value = !showSettings.value;
  }

  void updateNavigationButtons() {
    int currentIndex =
        chapters.indexWhere((ch) => ch.link! == currentChapter.value.link);
    canGoPrevious.value = currentIndex > 0;
    canGoNext.value = currentIndex < chapters.length - 1;
  }

  Future<void> goToNextChapter() async {
    int currentIndex =
        chapters.indexWhere((ch) => ch.link! == currentChapter.value.link);
    if (currentIndex < chapters.length - 1) {
      currentChapter.value = chapters[currentIndex + 1];
      updateNavigationButtons();
      await fetchData();
    }
  }

  Future<void> goToPreviousChapter() async {
    int currentIndex =
        chapters.indexWhere((ch) => ch.link! == currentChapter.value.link);
    if (currentIndex > 0) {
      currentChapter.value = chapters[currentIndex - 1];
      updateNavigationButtons();
      await fetchData();
    }
  }

  void increaseFontSize() {
    if (fontSize.value < 24) {
      fontSize.value += 1;
    }
  }

  void decreaseFontSize() {
    if (fontSize.value > 12) {
      fontSize.value -= 1;
    }
  }

  void resetSettings() {
    fontSize.value = 16.0;
    lineHeight.value = 1.6;
    letterSpacing.value = 0.0;
    wordSpacing.value = 0.0;
    paragraphSpacing.value = 16.0;
    fontFamily.value = 'System';
    textAlign.value = 0;
    themeMode.value = 0;
    backgroundOpacity.value = 1.0;
  }

  TextAlign get textAlignment {
    switch (textAlign.value) {
      case 1:
        return TextAlign.center;
      case 2:
        return TextAlign.justify;
      default:
        return TextAlign.left;
    }
  }

  List<String> get availableFonts => [
        'System',
        'Serif',
        'Roboto',
        'Open Sans',
        'Lato',
        'Merriweather',
        'Crimson Text',
        'Libre Baskerville'
      ];

  String get fontFamilyName {
    switch (fontFamily.value) {
      case 'Serif':
        return 'serif';
      case 'Roboto':
        return 'Roboto';
      case 'Open Sans':
        return 'OpenSans';
      case 'Lato':
        return 'Lato';
      case 'Merriweather':
        return 'Merriweather';
      case 'Crimson Text':
        return 'CrimsonText';
      case 'Libre Baskerville':
        return 'LibreBaskerville';
      default:
        return '';
    }
  }
}
