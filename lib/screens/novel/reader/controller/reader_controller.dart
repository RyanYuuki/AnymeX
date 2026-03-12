import 'dart:async';
import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/sync/gist_sync_controller.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/database/isar_models/chapter.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/services/volume_key_handler.dart';
import 'package:anymex/utils/logger.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';

enum LoadingState { loading, loaded, error }

class NovelReaderController extends GetxController {
  Chapter initialChapter;
  List<Chapter> chapters;
  Media media;
  Source source;

  NovelReaderController({
    required this.initialChapter,
    required this.chapters,
    required this.media,
    required this.source,
  });

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
  RxDouble paddingHorizontal = 16.0.obs;
  RxDouble paddingVertical = 8.0.obs;

  RxInt themeMode = 0.obs;
  RxDouble backgroundOpacity = 1.0.obs;

  RxBool canGoNext = true.obs;
  RxBool canGoPrevious = true.obs;

  RxBool autoHideEnabled = true.obs;
  Timer? _hideTimer;

  RxDouble progress = 0.0.obs;
  RxInt currentPage = 1.obs;
  RxInt totalPages = 1.obs;

  RxBool autoScrollEnabled = false.obs;
  RxDouble autoScrollSpeed = 3.0.obs;
  Timer? _autoScrollTimer;

  RxBool volumeButtonScrolling = false.obs;
  RxDouble volumeScrollOffset = 0.0.obs;
  static const double volumeScrollAmount = 50.0;
  final VolumeKeyHandler _volumeKeyHandler = VolumeKeyHandler();
  StreamSubscription? _volumeSubscription;

  RxBool tapToScroll = false.obs;
  RxDouble tapScrollAmount = 20.0.obs;

  RxBool keepScreenOn = true.obs;
  RxBool verticalSeekbar = true.obs;
  RxBool swipeGestures = true.obs;
  RxBool pageReaderMode = false.obs;
  RxBool showReadingProgress = true.obs;
  RxBool showBatteryAndTime = true.obs;

  late FlutterTts flutterTts;
  RxBool ttsEnabled = false.obs;
  RxBool ttsPlaying = false.obs;
  RxDouble ttsSpeed = 0.5.obs;
  RxDouble ttsPitch = 1.0.obs;
  RxString ttsVoice = ''.obs;
  RxBool ttsAutoAdvance = true.obs;
  RxList<String> ttsVoices = <String>[].obs;
  RxList<String> ttsVoicesDevice = <String>[].obs;
  RxList<String> ttsVoicesOther = <String>[].obs;
  final Map<String, String> _ttsVoiceLocaleMap = {};
  RxInt ttsCurrentElement = 0.obs;
  List<String> ttsSegments = [];
  RxInt ttsHighlightedElement = (-1).obs;
  RxInt ttsCurrentWordStart = 0.obs;
  RxInt ttsCurrentWordEnd = 0.obs;
  bool _isChangingVoice = false;

  Rx<Chapter> savedChapter = Chapter().obs;
  RxInt consecutiveReads = 0.obs;

  @override
  void onInit() {
    super.onInit();
    currentChapter.value = initialChapter;
    updateNavigationButtons();
    _loadSettings();
    fetchData();
    scrollController.addListener(_scrollListener);
    _initTts();
  }

  @override
  void onClose() {
    _saveTracking(syncToCloud: false);
    unawaited(_syncCloudProgressOnExit());
    scrollController.removeListener(_scrollListener);
    _stopAutoScroll();
    _hideTimer?.cancel();
    _disableVolumeKeys();
    flutterTts.stop();
    super.onClose();
  }

  void _loadSettings() {
    themeMode.value = NovelReaderKeys.themeMode.get<int>(3);
    backgroundOpacity.value = NovelReaderKeys.backgroundOpacity.get<double>(1.0);
    fontSize.value = NovelReaderKeys.fontSize.get<double>(16.0);
    lineHeight.value = NovelReaderKeys.lineHeight.get<double>(1.6);
    letterSpacing.value = NovelReaderKeys.letterSpacing.get<double>(0.0);
    wordSpacing.value = NovelReaderKeys.wordSpacing.get<double>(0.0);
    paragraphSpacing.value = NovelReaderKeys.paragraphSpacing.get<double>(16.0);
    fontFamily.value = NovelReaderKeys.fontFamily.get<String>('System');
    textAlign.value = NovelReaderKeys.textAlign.get<int>(0);
    paddingHorizontal.value = NovelReaderKeys.paddingHorizontal.get<double>(16.0);
    paddingVertical.value = NovelReaderKeys.paddingVertical.get<double>(8.0);
    autoScrollEnabled.value = NovelReaderKeys.autoScroll.get<bool>(false);
    autoScrollSpeed.value = NovelReaderKeys.autoScrollSpeed.get<double>(3.0);
    volumeButtonScrolling.value = NovelReaderKeys.volumeScrolling.get<bool>(false);
    tapToScroll.value = NovelReaderKeys.tapToScroll.get<bool>(false);
    keepScreenOn.value = NovelReaderKeys.keepScreenOn.get<bool>(true);
    verticalSeekbar.value = NovelReaderKeys.verticalSeekbar.get<bool>(true);
    swipeGestures.value = NovelReaderKeys.swipeGestures.get<bool>(true);
    pageReaderMode.value = NovelReaderKeys.pageReader.get<bool>(false);
    showReadingProgress.value = NovelReaderKeys.showReadingProgress.get<bool>(true);
    showBatteryAndTime.value = NovelReaderKeys.showBatteryTime.get<bool>(true);
    ttsSpeed.value = NovelReaderKeys.ttsSpeed.get<double>(0.5);
    ttsPitch.value = NovelReaderKeys.ttsPitch.get<double>(1.0);
    ttsVoice.value = NovelReaderKeys.ttsVoice.get<String>('');
    ttsAutoAdvance.value = NovelReaderKeys.ttsAutoAdvance.get<bool>(true);
    ttsEnabled.value = NovelReaderKeys.ttsEnabled.get<bool>(false);

    if (keepScreenOn.value) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    if (volumeButtonScrolling.value) {
      _enableVolumeKeys();
    }
  }

  void _saveSettings() {
    NovelReaderKeys.themeMode.set(themeMode.value);
    NovelReaderKeys.backgroundOpacity.set(backgroundOpacity.value);
    NovelReaderKeys.fontSize.set(fontSize.value);
    NovelReaderKeys.lineHeight.set(lineHeight.value);
    NovelReaderKeys.letterSpacing.set(letterSpacing.value);
    NovelReaderKeys.wordSpacing.set(wordSpacing.value);
    NovelReaderKeys.paragraphSpacing.set(paragraphSpacing.value);
    NovelReaderKeys.fontFamily.set(fontFamily.value);
    NovelReaderKeys.textAlign.set(textAlign.value);
    NovelReaderKeys.paddingHorizontal.set(paddingHorizontal.value);
    NovelReaderKeys.paddingVertical.set(paddingVertical.value);
    NovelReaderKeys.autoScroll.set(autoScrollEnabled.value);
    NovelReaderKeys.autoScrollSpeed.set(autoScrollSpeed.value);
    NovelReaderKeys.volumeScrolling.set(volumeButtonScrolling.value);
    NovelReaderKeys.tapToScroll.set(tapToScroll.value);
    NovelReaderKeys.keepScreenOn.set(keepScreenOn.value);
    NovelReaderKeys.verticalSeekbar.set(verticalSeekbar.value);
    NovelReaderKeys.swipeGestures.set(swipeGestures.value);
    NovelReaderKeys.pageReader.set(pageReaderMode.value);
    NovelReaderKeys.showReadingProgress.set(showReadingProgress.value);
    NovelReaderKeys.showBatteryTime.set(showBatteryAndTime.value);
    NovelReaderKeys.ttsSpeed.set(ttsSpeed.value);
    NovelReaderKeys.ttsPitch.set(ttsPitch.value);
    NovelReaderKeys.ttsVoice.set(ttsVoice.value);
    NovelReaderKeys.ttsAutoAdvance.set(ttsAutoAdvance.value);
    NovelReaderKeys.ttsEnabled.set(ttsEnabled.value);
  }

  void _enableVolumeKeys() {
    _volumeKeyHandler.enableInterception();
    _volumeSubscription?.cancel();
    _volumeSubscription = _volumeKeyHandler.volumeEvents.listen((event) {
      _handleVolumeEvent(event);
    });
  }

  void _disableVolumeKeys() {
    _volumeKeyHandler.disableInterception();
    _volumeSubscription?.cancel();
    _volumeSubscription = null;
  }

  void _handleVolumeEvent(String event) {
    if (Get.isBottomSheetOpen == true || Get.isDialogOpen == true || Get.isOverlaysOpen == true) return;
    if (showControls.value) {
      toggleControls();
      return;
    }
    if (event == 'up') {
      handleVolumeButton(true);
    } else if (event == 'down') {
      handleVolumeButton(false);
    }
  }

  void _scrollListener() {
    if (!scrollController.hasClients) return;
    if (loadingState.value == LoadingState.loading) return;

    double offset = scrollController.offset;
    double maxScrollExtent = scrollController.position.maxScrollExtent;

    progress.value = maxScrollExtent > 0 ? (offset / maxScrollExtent).clamp(0.0, 1.0) : 0.0;

    if (pageReaderMode.value) {
      double pageHeight = Get.height - MediaQuery.of(Get.context!).padding.top - MediaQuery.of(Get.context!).padding.bottom;
      totalPages.value = (maxScrollExtent / pageHeight).ceil() + 1;
      currentPage.value = (offset / pageHeight).floor() + 1;
    }

    currentChapter.value.currentOffset = offset;
    currentChapter.value.maxOffset = maxScrollExtent;
    currentChapter.value.lastReadTime = DateTime.now().millisecondsSinceEpoch;

    if (pageReaderMode.value) {
      currentChapter.value.pageNumber = currentPage.value;
      currentChapter.value.totalPages = totalPages.value;
    }
    _resetHideTimer();
  }

  void _resetHideTimer() {
    if (!autoHideEnabled.value) return;
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (showControls.value) {
        showControls.value = false;
      }
    });
  }

  Future<void> _waitForScrollAndJump() async {
    final current = savedChapter.value.currentOffset;
    final max = savedChapter.value.maxOffset;
    if (current == null || max == null || current < 0 || current > max) return;
    while (true) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (!scrollController.hasClients) continue;
      if (scrollController.position.maxScrollExtent >= current) {
        scrollController.animateTo(current, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        break;
      }
    }
  }

  Future<void> fetchData() async {
    try {
      loadingState.value = LoadingState.loading;
      _saveTracking();
      final data = await source.methods.getNovelContent(currentChapter.value.title!, currentChapter.value.link!);
      if (data != null && data.isNotEmpty) {
        final processedContent = _buildHtml(data);
        novelContent.value = processedContent;
        _extractTtsSegments(processedContent);
      }
      loadingState.value = LoadingState.loaded;
      await _waitForScrollAndJump();
      _resumeFromCloudIfNewer();
    } catch (e) {
      Logger.i(e.toString());
      loadingState.value = LoadingState.error;
    }
  }

  void _extractTtsSegments(String html) {
    final normalized = html
        .replaceAll(RegExp(r'<\s*br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</(p|div|li|h[1-6]|blockquote)>', caseSensitive: false), '\n');
    final tagRegex = RegExp(r'<[^>]*>');
    final plainText = normalized.replaceAll(tagRegex, ' ');
    ttsSegments = plainText
        .split(RegExp(r'[\n\r]+'))
        .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  void _initTts() {
    flutterTts = FlutterTts();

    flutterTts.setStartHandler(() {
      ttsPlaying.value = true;
      _scrollToTtsElement();
    });

    flutterTts.setCompletionHandler(() {
      ttsHighlightedElement.value = -1;
      ttsCurrentWordStart.value = 0;
      ttsCurrentWordEnd.value = 0;
      if (ttsAutoAdvance.value) {
        ttsCurrentElement.value++;
        if (ttsCurrentElement.value < ttsSegments.length) {
          unawaited(_speakCurrentElement());
        } else {
          ttsPlaying.value = false;
        }
      } else {
        ttsPlaying.value = false;
      }
    });

    flutterTts.setErrorHandler((msg) {
      ttsPlaying.value = false;
      ttsHighlightedElement.value = -1;
      ttsCurrentWordStart.value = 0;
      ttsCurrentWordEnd.value = 0;
    });

    flutterTts.setProgressHandler((String text, int startOffset, int endOffset, String word) {
      ttsHighlightedElement.value = ttsCurrentElement.value;
      ttsCurrentWordStart.value = startOffset;
      ttsCurrentWordEnd.value = endOffset;
    });

    unawaited(_loadVoices());
  }

  void _scrollToTtsElement() {
    if (ttsSegments.isEmpty || !scrollController.hasClients) return;
    
    final double targetRatio = ttsCurrentElement.value / ttsSegments.length;
    final double targetOffset = targetRatio * scrollController.position.maxScrollExtent;
    
    final double viewportHeight = scrollController.position.viewportDimension;
    final double currentScroll = scrollController.offset;

    if (targetOffset < currentScroll || targetOffset > (currentScroll + viewportHeight - 100)) {
      scrollController.animateTo(
        (targetOffset - 100).clamp(0.0, scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _loadVoices() async {
    try {
      final voices = await flutterTts.getVoices;
      if (voices is! List) return;
      _ttsVoiceLocaleMap.clear();
      final deviceLocale = Get.deviceLocale?.toString() ?? 'en';
      final deviceLang = deviceLocale.split(RegExp(r'[_-]')).first.toLowerCase();
      final deviceVoices = <String>[];
      final otherVoices = <String>[];
      for (final voice in voices) {
        String name = '';
        String locale = '';
        if (voice is Map) {
          name = voice['name']?.toString() ?? '';
          locale = voice['locale']?.toString() ?? '';
        } else {
          name = voice.toString();
        }
        if (name.isEmpty) continue;
        if (_ttsVoiceLocaleMap.containsKey(name)) continue;
        _ttsVoiceLocaleMap[name] = locale;
        final voiceLang = locale.split(RegExp(r'[_-]')).first.toLowerCase();
        if (voiceLang == deviceLang || locale.isEmpty) {
          deviceVoices.add(name);
        } else {
          otherVoices.add(name);
        }
      }
      ttsVoicesDevice.value = deviceVoices;
      ttsVoicesOther.value = otherVoices;
      ttsVoices.value = [...deviceVoices, ...otherVoices];
    } catch (e) {
      Logger.i('[NovelReader] Failed to load TTS voices: $e');
    }
  }

  Future<void> setTtsEnabled(bool enabled) async {
    ttsEnabled.value = enabled;
    if (!enabled && ttsPlaying.value) {
      await flutterTts.stop();
      ttsPlaying.value = false;
      ttsHighlightedElement.value = -1;
      ttsCurrentWordStart.value = 0;
      ttsCurrentWordEnd.value = 0;
    }
    _saveSettings();
  }

  Future<void> toggleTtsPlayback() async {
    if (!ttsEnabled.value) return;
    if (ttsPlaying.value) {
      await flutterTts.stop();
      ttsPlaying.value = false;
      ttsHighlightedElement.value = -1;
      ttsCurrentWordStart.value = 0;
      ttsCurrentWordEnd.value = 0;
      return;
    }
    ttsCurrentElement.value = _getCurrentTextSegment();
    await _speakCurrentElement();
  }

  int _getCurrentTextSegment() {
    if (ttsSegments.isEmpty) return 0;
    if (!scrollController.hasClients) return 0;
    final scrollPosition = scrollController.offset;
    final maxScroll = scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return 0;
    final ratio = (scrollPosition / maxScroll).clamp(0.0, 1.0);
    final index = (ratio * (ttsSegments.length - 1)).round();
    return index.clamp(0, ttsSegments.length - 1);
  }

  Future<void> _speakCurrentElement() async {
    if (ttsSegments.isEmpty || ttsCurrentElement.value < 0 || ttsCurrentElement.value >= ttsSegments.length) {
      ttsPlaying.value = false;
      ttsHighlightedElement.value = -1;
      ttsCurrentWordStart.value = 0;
      ttsCurrentWordEnd.value = 0;
      return;
    }
    await flutterTts.setSpeechRate(ttsSpeed.value);
    await flutterTts.setPitch(ttsPitch.value);
    if (ttsVoice.value.isNotEmpty) {
      try {
        final locale = _ttsVoiceLocaleMap[ttsVoice.value] ?? '';
        await flutterTts.setVoice({"name": ttsVoice.value, "locale": locale});
      } catch (e) {
        Logger.i('[NovelReader] Failed to set TTS voice: $e');
      }
    }
    ttsHighlightedElement.value = ttsCurrentElement.value;
    final text = ttsSegments[ttsCurrentElement.value];
    await flutterTts.speak(text);
    _scrollToTtsElement();
  }

  void ttsNext() {
    if (ttsPlaying.value) flutterTts.stop();
    if (ttsCurrentElement.value < ttsSegments.length - 1) {
      ttsCurrentElement.value++;
      unawaited(_speakCurrentElement());
    }
  }

  void ttsPrevious() {
    if (ttsPlaying.value) flutterTts.stop();
    if (ttsCurrentElement.value > 0) {
      ttsCurrentElement.value--;
      unawaited(_speakCurrentElement());
    }
  }

  Future<void> _resumeFromCloudIfNewer() async {
    final ctrl = Get.isRegistered<GistSyncController>() ? Get.find<GistSyncController>() : null;
    if (ctrl == null || !ctrl.isLoggedIn.value || !ctrl.syncEnabled.value) return;
    try {
      final chapter = currentChapter.value;
      if (chapter.number == null) return;
      final localUpdated = chapter.lastReadTime ?? 0;
      final entry = await ctrl.fetchNewerChapterProgress(
        mediaId: media.id,
        mediaType: 'novel',
        chapterNumber: chapter.number!,
        localUpdatedAt: localUpdated,
      ).timeout(const Duration(seconds: 4), onTimeout: () => null);
      if (entry?.scrollOffset != null) {
        final offset = entry!.scrollOffset!;
        await Future.delayed(const Duration(milliseconds: 200));
        if (scrollController.hasClients && offset <= scrollController.position.maxScrollExtent) {
          scrollController.animateTo(offset, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
        }
      }
    } catch (e) {
      Logger.i('[GistSync] _resumeFromCloudIfNewer: $e');
    }
  }

  void toggleAutoScroll() {
    autoScrollEnabled.value = !autoScrollEnabled.value;
    if (autoScrollEnabled.value) {
      _startAutoScroll();
    } else {
      _stopAutoScroll();
    }
    _saveSettings();
  }

  void setAutoScrollSpeed(double speed) {
    autoScrollSpeed.value = speed;
    if (autoScrollEnabled.value) {
      _stopAutoScroll();
      _startAutoScroll();
    }
    _saveSettings();
  }

  void _startAutoScroll() {
    _stopAutoScroll();
    final pixelsPerSecond = Get.height / autoScrollSpeed.value;
    const tickMs = 50;
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: tickMs), (_) {
      if (!autoScrollEnabled.value || !scrollController.hasClients) return;
      final current = scrollController.offset;
      final max = scrollController.position.maxScrollExtent;
      if (current >= max) {
        _stopAutoScroll();
        autoScrollEnabled.value = false;
        return;
      }
      final newOffset = (current + pixelsPerSecond * tickMs / 1000).clamp(0.0, max);
      scrollController.jumpTo(newOffset);
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }
  
  void handleVolumeButton(bool isVolumeUp) {
    if (!volumeButtonScrolling.value || !scrollController.hasClients) return;
    final double amount = isVolumeUp ? -volumeScrollAmount : volumeScrollAmount;
    final double minOffset = scrollController.position.minScrollExtent;
    final double maxOffset = scrollController.position.maxScrollExtent;
    final double newOffset = (scrollController.offset + amount).clamp(minOffset, maxOffset);
    scrollController.animateTo(newOffset, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
  }

  void handleTap(Offset tapPosition, {double? viewportHeight}) {
    if (!tapToScroll.value || !scrollController.hasClients) return;
    final screenHeight = viewportHeight ?? Get.height;
    bool isTopHalf = tapPosition.dy < screenHeight / 2;
    double amount = isTopHalf ? -tapScrollAmount.value : tapScrollAmount.value;
    double newOffset = scrollController.offset + amount;
    double maxOffset = scrollController.position.maxScrollExtent;
    newOffset = newOffset.clamp(0.0, maxOffset);
    scrollController.animateTo(newOffset, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
  }

  void handleSwipe(DragEndDetails details, bool isReversed) {
    if (!swipeGestures.value) return;
    if (details.primaryVelocity != null) {
      bool isLeftSwipe = details.primaryVelocity! > 0;
      bool isRightSwipe = details.primaryVelocity! < 0;
      if ((isLeftSwipe && !isReversed) || (isRightSwipe && isReversed)) {
        if (canGoNext.value) goToNextChapter();
      } else if ((isRightSwipe && !isReversed) || (isLeftSwipe && isReversed)) {
        if (canGoPrevious.value) goToPreviousChapter();
      }
    }
  }

  void _saveTracking({bool syncToCloud = true}) {
    consecutiveReads.value++;
    savedChapter.value = offlineStorageController.getReadChapter(media.id, currentChapter.value.number!) ?? currentChapter.value;
    if (consecutiveReads.value > 1) {
      Future.microtask(() {
        offlineStorageController.addOrUpdateNovel(media, chapters, currentChapter.value, source);
        offlineStorageController.addOrUpdateReadChapter(media.id, currentChapter.value, source: source, syncToCloud: syncToCloud);
      });
    }
  }

  Future<void> _syncCloudProgressOnExit() async {
    final syncCtrl = Get.isRegistered<GistSyncController>() ? Get.find<GistSyncController>() : null;
    if (syncCtrl == null) return;
    final shouldRemove = syncCtrl.autoDeleteCompletedOnExit.value && _hasFinishedCurrentMedia();
    await syncCtrl.syncChapterProgressOnExit(
      mediaId: media.id,
      malId: media.idMal,
      mediaType: 'novel',
      chapter: currentChapter.value,
      isCompleted: shouldRemove,
    );
  }

  bool _hasFinishedCurrentMedia() {
    final chapter = currentChapter.value;
    final chapterNumber = chapter.number;
    if (chapterNumber == null || chapter.pageNumber == null || chapter.totalPages == null || chapter.totalPages! <= 0 || chapter.pageNumber! < chapter.totalPages!) return false;
    final totalChapters = double.tryParse(media.totalChapters ?? '');
    if (totalChapters != null && totalChapters > 0) return chapterNumber >= totalChapters;
    for (final item in chapters) {
      if (item.number != null && item.number! > chapterNumber) return false;
    }
    return chapters.isNotEmpty;
  }

  String _buildHtml(String input) {
    final processed = input.replaceAll("\\n", "").replaceAll("\\t", "").replaceAll("\\\"", "\"").replaceAll('*"', '').replaceAll('"*', '');
    return '<div id="readerViewContent"><div style="max-width: 800px; margin: 0 auto;">$processed</div></div>';
  }

  void toggleControls() {
    showControls.value = !showControls.value;
    if (showControls.value) {
      _resetHideTimer();
    } else {
      _hideTimer?.cancel();
    }
  }

  void toggleSettings() => (showSettings.value = !showSettings.value) ? showControls.value = true : null;

  void updateNavigationButtons() {
    int currentIndex = chapters.indexWhere((ch) => ch.link == currentChapter.value.link);
    canGoPrevious.value = currentIndex > 0;
    canGoNext.value = currentIndex < chapters.length - 1;
  }

  Future<void> goToNextChapter() async {
    int currentIndex = chapters.indexWhere((ch) => ch.link == currentChapter.value.link);
    if (currentIndex < chapters.length - 1) {
      _stopAutoScroll();
      autoScrollEnabled.value = false;
      if (ttsPlaying.value) {
        await flutterTts.stop();
        ttsPlaying.value = false;
        ttsHighlightedElement.value = -1;
        ttsCurrentWordStart.value = 0;
        ttsCurrentWordEnd.value = 0;
        ttsCurrentElement.value = 0;
      }
      currentChapter.value = chapters[currentIndex + 1];
      updateNavigationButtons();
      await fetchData();
      if (scrollController.hasClients) scrollController.jumpTo(0);
    }
  }

  Future<void> goToPreviousChapter() async {
    int currentIndex = chapters.indexWhere((ch) => ch.link == currentChapter.value.link);
    if (currentIndex > 0) {
      _stopAutoScroll();
      autoScrollEnabled.value = false;
      if (ttsPlaying.value) {
        await flutterTts.stop();
        ttsPlaying.value = false;
        ttsHighlightedElement.value = -1;
        ttsCurrentWordStart.value = 0;
        ttsCurrentWordEnd.value = 0;
        ttsCurrentElement.value = 0;
      }
      currentChapter.value = chapters[currentIndex - 1];
      updateNavigationButtons();
      await fetchData();
      if (scrollController.hasClients) scrollController.jumpTo(0);
    }
  }

  Future<void> navigateToChapter(int index) async {
    if (index < 0 || index >= chapters.length) return;
    _saveTracking(syncToCloud: false);
    if (ttsPlaying.value) {
      await flutterTts.stop();
      ttsPlaying.value = false;
      ttsHighlightedElement.value = -1;
      ttsCurrentWordStart.value = 0;
      ttsCurrentWordEnd.value = 0;
      ttsCurrentElement.value = 0;
    }
    currentChapter.value = chapters[index];
    updateNavigationButtons();
    await fetchData();
    if (scrollController.hasClients) scrollController.jumpTo(0);
  }

  void increaseFontSize() {
    if (fontSize.value < 24) {
      fontSize.value += 1;
      _saveSettings();
    }
  }

  void decreaseFontSize() {
    if (fontSize.value > 12) {
      fontSize.value -= 1;
      _saveSettings();
    }
  }

  void setFontSize(double value) { fontSize.value = value.clamp(12.0, 24.0); _saveSettings(); }
  void setLineHeight(double value) { lineHeight.value = value.clamp(1.0, 3.0); _saveSettings(); }
  void setParagraphSpacing(double value) { paragraphSpacing.value = value.clamp(8.0, 32.0); _saveSettings(); }
  void setLetterSpacing(double value) { letterSpacing.value = value.clamp(-1.0, 2.0); _saveSettings(); }
  void setWordSpacing(double value) { wordSpacing.value = value.clamp(0.0, 5.0); _saveSettings(); }
  void setFontFamily(String value) { fontFamily.value = value; _saveSettings(); }
  void setTextAlign(int value) { textAlign.value = value; _saveSettings(); }
  void setHorizontalPadding(double value) { paddingHorizontal.value = value.clamp(8.0, 32.0); _saveSettings(); }
  void setVerticalPadding(double value) { paddingVertical.value = value.clamp(4.0, 24.0); _saveSettings(); }
  void setThemeMode(int value) { themeMode.value = value.clamp(0, 3); _saveSettings(); }
  void setBackgroundOpacity(double value) { backgroundOpacity.value = value.clamp(0.3, 1.0); _saveSettings(); }
  void togglePageReaderMode() { pageReaderMode.value = !pageReaderMode.value; _saveSettings(); }
  void toggleVerticalSeekbar() { verticalSeekbar.value = !verticalSeekbar.value; _saveSettings(); }
  void toggleSwipeGestures() { swipeGestures.value = !swipeGestures.value; _saveSettings(); }
  void toggleVolumeScrolling() {
    volumeButtonScrolling.value = !volumeButtonScrolling.value;
    volumeButtonScrolling.value ? _enableVolumeKeys() : _disableVolumeKeys();
    _saveSettings();
  }
  void toggleTapToScroll() { tapToScroll.value = !tapToScroll.value; _saveSettings(); }
  void setTapScrollAmount(double amount) { tapScrollAmount.value = amount.clamp(10.0, 200.0); _saveSettings(); }
  void toggleKeepScreenOn() {
    keepScreenOn.value = !keepScreenOn.value;
    SystemChrome.setEnabledSystemUIMode(keepScreenOn.value ? SystemUiMode.edgeToEdge : SystemUiMode.manual, overlays: SystemUiOverlay.values);
    _saveSettings();
  }
  void toggleShowReadingProgress() { showReadingProgress.value = !showReadingProgress.value; _saveSettings(); }
  void toggleShowBatteryAndTime() { showBatteryAndTime.value = !showBatteryAndTime.value; _saveSettings(); }
  void setTtsSpeed(double value) { ttsSpeed.value = value.clamp(0.1, 1.0); if (ttsPlaying.value) flutterTts.setSpeechRate(ttsSpeed.value); _saveSettings(); }
  void setTtsPitch(double value) { ttsPitch.value = value.clamp(0.5, 2.0); if (ttsPlaying.value) flutterTts.setPitch(ttsPitch.value); _saveSettings(); }
  void setTtsVoice(String value) {
    if (_isChangingVoice) return;
    _isChangingVoice = true;
    bool wasPlaying = ttsPlaying.value;
    int currentElement = ttsCurrentElement.value;
    if (wasPlaying) flutterTts.stop();
    ttsVoice.value = value;
    if (wasPlaying && ttsSegments.isNotEmpty && currentElement < ttsSegments.length) {
      Future.delayed(const Duration(milliseconds: 100), () { _speakCurrentElement(); _isChangingVoice = false; });
    } else {
      _isChangingVoice = false;
    }
    _saveSettings();
  }
  void toggleTtsAutoAdvance() { ttsAutoAdvance.value = !ttsAutoAdvance.value; _saveSettings(); }

  void resetSettings() {
    fontSize.value = 16.0; lineHeight.value = 1.6; letterSpacing.value = 0.0; wordSpacing.value = 0.0;
    paragraphSpacing.value = 16.0; fontFamily.value = 'System'; textAlign.value = 0; paddingHorizontal.value = 16.0;
    paddingVertical.value = 8.0; autoScrollEnabled.value = false; autoScrollSpeed.value = 3.0;
    volumeButtonScrolling.value = false; tapToScroll.value = false; tapScrollAmount.value = 20.0;
    keepScreenOn.value = true; verticalSeekbar.value = true; swipeGestures.value = true;
    pageReaderMode.value = false; themeMode.value = 3; backgroundOpacity.value = 1.0;
    showReadingProgress.value = true; showBatteryAndTime.value = true;
    ttsEnabled.value = false; ttsSpeed.value = 0.5; ttsPitch.value = 1.0; ttsVoice.value = '';
    ttsAutoAdvance.value = true; ttsCurrentElement.value = 0; ttsHighlightedElement.value = -1;
    _stopAutoScroll(); _disableVolumeKeys(); _ttsVoiceLocaleMap.clear(); ttsVoicesDevice.value = [];
    ttsVoicesOther.value = []; unawaited(flutterTts.stop()); ttsPlaying.value = false; _saveSettings();
  }

  bool get useSystemReaderTheme => themeMode.value == 3;

  Color get readerBackgroundColor {
    switch (themeMode.value) {
      case 0: return const Color(0xFFF7F7F7).withValues(alpha: backgroundOpacity.value);
      case 1: return const Color(0xFF111318).withValues(alpha: backgroundOpacity.value);
      case 2: return const Color(0xFFF1E7D0).withValues(alpha: backgroundOpacity.value);
      default: return Colors.transparent;
    }
  }

  Color get readerTextColor {
    switch (themeMode.value) {
      case 1: return const Color(0xFFE6E6E6);
      case 2: return const Color(0xFF4A3B2A);
      default: return const Color(0xFF1A1A1A);
    }
  }

  ColorScheme get readerColorScheme {
    switch (themeMode.value) {
      case 0:
        return ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A6FA5),
          brightness: Brightness.light,
        );
      case 1:
        return ColorScheme.fromSeed(
          seedColor: const Color(0xFF7AA2F7),
          brightness: Brightness.dark,
        );
      case 2:
        return ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B6B3F),
          brightness: Brightness.light,
        );
      default:
        return Get.theme.colorScheme;
    }
  }

  TextAlign get textAlignment {
    switch (textAlign.value) {
      case 1: return TextAlign.center;
      case 2: return TextAlign.justify;
      default: return TextAlign.left;
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
      case 'Serif': return 'serif';
      case 'Roboto': return 'Roboto';
      case 'Open Sans': return 'OpenSans';
      case 'Lato': return 'Lato';
      case 'Merriweather': return 'Merriweather';
      case 'Crimson Text': return 'CrimsonText';
      case 'Libre Baskerville': return 'LibreBaskerville';
      default: return '';
    }
  }
}
