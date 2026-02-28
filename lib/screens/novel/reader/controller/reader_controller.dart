import 'dart:async';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/database/isar_models/chapter.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:flutter/material.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';

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

  // UI Controls
  RxBool showControls = true.obs;
  RxBool showSettings = false.obs;

  // Text Settings
  RxDouble fontSize = 16.0.obs;
  RxDouble lineHeight = 1.6.obs;
  RxDouble letterSpacing = 0.0.obs;
  RxDouble wordSpacing = 0.0.obs;
  RxDouble paragraphSpacing = 16.0.obs;
  RxString fontFamily = 'System'.obs;
  RxInt textAlign = 0.obs;
  RxDouble paddingHorizontal = 16.0.obs;
  RxDouble paddingVertical = 8.0.obs;

  // Theme Settings
  RxInt themeMode = 0.obs;
  RxDouble backgroundOpacity = 1.0.obs;

  // Navigation
  RxBool canGoNext = true.obs;
  RxBool canGoPrevious = true.obs;

  // Auto-hide timer
  RxBool autoHideEnabled = true.obs;
  Timer? _hideTimer;

  // Page Indicators
  RxDouble progress = 0.0.obs;
  RxInt currentPage = 1.obs;
  RxInt totalPages = 1.obs;

  // Auto Scroll
  RxBool autoScrollEnabled = false.obs;
  RxDouble autoScrollSpeed = 3.0.obs;
  Timer? _autoScrollTimer;

  // Volume Button Scrolling
  RxBool volumeButtonScrolling = false.obs;
  RxDouble volumeScrollOffset = 0.0.obs;
  static const double volumeScrollAmount = 50.0;

  // Tap to Scroll
  RxBool tapToScroll = false.obs;
  RxDouble tapScrollAmount = 20.0.obs;

  // Keep Screen On
  RxBool keepScreenOn = true.obs;

  // Vertical Seekbar
  RxBool verticalSeekbar = true.obs;

  // Swipe Gestures
  RxBool swipeGestures = true.obs;

  // Page Reader Mode (vs continuous scroll)
  RxBool pageReaderMode = false.obs;

  // Remove Extra Spacing
  RxBool removeExtraSpacing = false.obs;

  // Bionic Reading
  RxBool bionicReading = false.obs;
  RxDouble bionicIntensity = 0.5.obs;

  // Reading Progress
  RxBool showReadingProgress = true.obs;

  // Battery & Time
  RxBool showBatteryAndTime = true.obs;

  // TTS
  late FlutterTts flutterTts;
  RxBool ttsEnabled = false.obs;
  RxBool ttsPlaying = false.obs;
  RxDouble ttsSpeed = 0.5.obs;
  RxDouble ttsPitch = 1.0.obs;
  RxString ttsVoice = ''.obs;
  RxBool ttsAutoAdvance = true.obs;
  RxInt ttsCurrentElement = 0.obs;
  List<String> _ttsElements = [];

  // Saved chapter for tracking
  Rx<Chapter> savedChapter = Chapter().obs;

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
    _saveTracking();
    scrollController.removeListener(_scrollListener);
    _stopAutoScroll();
    _hideTimer?.cancel();
    flutterTts.stop();
    super.onClose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    fontSize.value = prefs.getDouble('novel_font_size') ?? 16.0;
    lineHeight.value = prefs.getDouble('novel_line_height') ?? 1.6;
    letterSpacing.value = prefs.getDouble('novel_letter_spacing') ?? 0.0;
    wordSpacing.value = prefs.getDouble('novel_word_spacing') ?? 0.0;
    paragraphSpacing.value = prefs.getDouble('novel_paragraph_spacing') ?? 16.0;
    fontFamily.value = prefs.getString('novel_font_family') ?? 'System';
    textAlign.value = prefs.getInt('novel_text_align') ?? 0;
    paddingHorizontal.value = prefs.getDouble('novel_padding_horizontal') ?? 16.0;
    paddingVertical.value = prefs.getDouble('novel_padding_vertical') ?? 8.0;
    
    autoScrollEnabled.value = prefs.getBool('novel_auto_scroll') ?? false;
    autoScrollSpeed.value = prefs.getDouble('novel_auto_scroll_speed') ?? 3.0;
    volumeButtonScrolling.value = prefs.getBool('novel_volume_scrolling') ?? false;
    tapToScroll.value = prefs.getBool('novel_tap_to_scroll') ?? false;
    keepScreenOn.value = prefs.getBool('novel_keep_screen_on') ?? true;
    verticalSeekbar.value = prefs.getBool('novel_vertical_seekbar') ?? true;
    swipeGestures.value = prefs.getBool('novel_swipe_gestures') ?? true;
    pageReaderMode.value = prefs.getBool('novel_page_reader') ?? false;
    removeExtraSpacing.value = prefs.getBool('novel_remove_extra_spacing') ?? false;
    bionicReading.value = prefs.getBool('novel_bionic_reading') ?? false;
    bionicIntensity.value = prefs.getDouble('novel_bionic_intensity') ?? 0.5;
    showReadingProgress.value = prefs.getBool('novel_show_reading_progress') ?? true;
    showBatteryAndTime.value = prefs.getBool('novel_show_battery_time') ?? true;
    
    ttsSpeed.value = prefs.getDouble('novel_tts_speed') ?? 0.5;
    ttsPitch.value = prefs.getDouble('novel_tts_pitch') ?? 1.0;
    ttsVoice.value = prefs.getString('novel_tts_voice') ?? '';
    ttsAutoAdvance.value = prefs.getBool('novel_tts_auto_advance') ?? true;

    if (keepScreenOn.value) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setDouble('novel_font_size', fontSize.value);
    await prefs.setDouble('novel_line_height', lineHeight.value);
    await prefs.setDouble('novel_letter_spacing', letterSpacing.value);
    await prefs.setDouble('novel_word_spacing', wordSpacing.value);
    await prefs.setDouble('novel_paragraph_spacing', paragraphSpacing.value);
    await prefs.setString('novel_font_family', fontFamily.value);
    await prefs.setInt('novel_text_align', textAlign.value);
    await prefs.setDouble('novel_padding_horizontal', paddingHorizontal.value);
    await prefs.setDouble('novel_padding_vertical', paddingVertical.value);
    
    await prefs.setBool('novel_auto_scroll', autoScrollEnabled.value);
    await prefs.setDouble('novel_auto_scroll_speed', autoScrollSpeed.value);
    await prefs.setBool('novel_volume_scrolling', volumeButtonScrolling.value);
    await prefs.setBool('novel_tap_to_scroll', tapToScroll.value);
    await prefs.setBool('novel_keep_screen_on', keepScreenOn.value);
    await prefs.setBool('novel_vertical_seekbar', verticalSeekbar.value);
    await prefs.setBool('novel_swipe_gestures', swipeGestures.value);
    await prefs.setBool('novel_page_reader', pageReaderMode.value);
    await prefs.setBool('novel_remove_extra_spacing', removeExtraSpacing.value);
    await prefs.setBool('novel_bionic_reading', bionicReading.value);
    await prefs.setDouble('novel_bionic_intensity', bionicIntensity.value);
    await prefs.setBool('novel_show_reading_progress', showReadingProgress.value);
    await prefs.setBool('novel_show_battery_time', showBatteryAndTime.value);
    
    await prefs.setDouble('novel_tts_speed', ttsSpeed.value);
    await prefs.setDouble('novel_tts_pitch', ttsPitch.value);
    await prefs.setString('novel_tts_voice', ttsVoice.value);
    await prefs.setBool('novel_tts_auto_advance', ttsAutoAdvance.value);
  }

  void _scrollListener() {
    if (!scrollController.hasClients) return;
    if (loadingState.value == LoadingState.loading) return;

    double offset = scrollController.offset;
    double maxScrollExtent = scrollController.position.maxScrollExtent;

    if (offset < 0 || offset > maxScrollExtent) return;

    progress.value = maxScrollExtent > 0 ? offset / maxScrollExtent : 0.0;

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
        scrollController.animateTo(
          current,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        break;
      }
    }
  }

  Future<void> fetchData() async {
    try {
      loadingState.value = LoadingState.loading;
      _saveTracking();
      final data = await source.methods.getNovelContent(
        currentChapter.value.title!,
        currentChapter.value.link!,
      );
      
      if (data != null && data.isNotEmpty) {
        String processedContent = _buildHtml(data);
        if (removeExtraSpacing.value) {
          processedContent = _removeExtraSpacing(processedContent);
        }
        if (bionicReading.value) {
          processedContent = _applyBionicReading(processedContent);
        }
        novelContent.value = processedContent;
        _extractTtsElements(processedContent);
      }
      
      loadingState.value = LoadingState.loaded;
      await _waitForScrollAndJump();
    } catch (e) {
      Logger.i(e.toString());
      loadingState.value = LoadingState.error;
    }
  }

  String _removeExtraSpacing(String html) {
    // Remove multiple newlines and extra spaces
    return html.replaceAll(RegExp(r'\n\s*\n'), '\n\n')
               .replaceAll(RegExp(r' {2,}'), ' ');
  }

  String _applyBionicReading(String html) {
    // Apply bionic reading: bold first half of words
    RegExp wordRegex = RegExp(r'\b(\w+)\b');
    return html.replaceAllMapped(wordRegex, (match) {
      String word = match.group(1)!;
      int boldLength = (word.length * bionicIntensity.value).round();
      if (boldLength < 1) boldLength = 1;
      if (boldLength >= word.length) return '<b>$word</b>';
      
      String boldPart = word.substring(0, boldLength);
      String normalPart = word.substring(boldLength);
      return '<b>$boldPart</b>$normalPart';
    });
  }

  void _extractTtsElements(String html) {
    // Extract text elements for TTS
    RegExp tagRegex = RegExp(r'<[^>]*>');
    String plainText = html.replaceAll(tagRegex, ' ');
    _ttsElements = plainText.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  }

  void _initTts() {
    flutterTts = FlutterTts();
    
    flutterTts.setStartHandler(() {
      ttsPlaying.value = true;
    });

    flutterTts.setCompletionHandler(() {
      if (ttsAutoAdvance.value) {
        ttsCurrentElement.value++;
        if (ttsCurrentElement.value < _ttsElements.length) {
          _speakCurrentElement();
        } else {
          ttsPlaying.value = false;
        }
      } else {
        ttsPlaying.value = false;
      }
    });

    flutterTts.setErrorHandler((msg) {
      ttsPlaying.value = false;
    });

    _loadVoices();
  }

  Future<void> _loadVoices() async {
    var voices = await flutterTts.getVoices;
    // Store voices for selection
  }

  Future<void> toggleTts() async {
    if (ttsEnabled.value) {
      if (ttsPlaying.value) {
        await flutterTts.stop();
        ttsPlaying.value = false;
      } else {
        ttsCurrentElement.value = _getCurrentTextElement();
        await _speakCurrentElement();
      }
    } else {
      ttsEnabled.value = true;
      ttsCurrentElement.value = _getCurrentTextElement();
      await _speakCurrentElement();
    }
  }

  int _getCurrentTextElement() {
    if (!scrollController.hasClients) return 0;
    
    double scrollPosition = scrollController.offset;
    // Rough estimation: assume each element is about 50 pixels
    int elementIndex = (scrollPosition / 50).floor();
    return elementIndex.clamp(0, _ttsElements.length - 1);
  }

  Future<void> _speakCurrentElement() async {
    if (ttsCurrentElement.value < 0 || ttsCurrentElement.value >= _ttsElements.length) {
      return;
    }

    await flutterTts.setSpeechRate(ttsSpeed.value);
    await flutterTts.setPitch(ttsPitch.value);
    
    if (ttsVoice.value.isNotEmpty) {
      await flutterTts.setVoice({"name": ttsVoice.value});
    }

    String text = _ttsElements[ttsCurrentElement.value];
    await flutterTts.speak(text);
  }

  void ttsNext() {
    if (ttsCurrentElement.value < _ttsElements.length - 1) {
      ttsCurrentElement.value++;
      _speakCurrentElement();
    }
  }

  void ttsPrevious() {
    if (ttsCurrentElement.value > 0) {
      ttsCurrentElement.value--;
      _speakCurrentElement();
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
    
    _autoScrollTimer = Timer.periodic(
      const Duration(milliseconds: tickMs),
      (_) {
        if (!autoScrollEnabled.value || !scrollController.hasClients) {
          return;
        }
        
        final current = scrollController.offset;
        final max = scrollController.position.maxScrollExtent;
        
        if (current >= max) {
          _stopAutoScroll();
          autoScrollEnabled.value = false;
          return;
        }
        
        final newOffset = (current + pixelsPerSecond * tickMs / 1000).clamp(0.0, max);
        scrollController.jumpTo(newOffset);
      },
    );
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  void handleVolumeButton(bool isVolumeUp) {
    if (!volumeButtonScrolling.value || !scrollController.hasClients) return;

    double amount = isVolumeUp ? volumeScrollAmount : -volumeScrollAmount;
    double newOffset = scrollController.offset + amount;
    double maxOffset = scrollController.position.maxScrollExtent;
    
    newOffset = newOffset.clamp(0.0, maxOffset);
    scrollController.animateTo(
      newOffset,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void handleTap(Offset tapPosition) {
    if (!tapToScroll.value || !scrollController.hasClients) return;

    double screenHeight = Get.height;
    bool isTopHalf = tapPosition.dy < screenHeight / 2;
    
    double amount = isTopHalf ? -tapScrollAmount.value : tapScrollAmount.value;
    double newOffset = scrollController.offset + amount;
    double maxOffset = scrollController.position.maxScrollExtent;
    
    newOffset = newOffset.clamp(0.0, maxOffset);
    scrollController.animateTo(
      newOffset,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void handleSwipe(DragEndDetails details, bool isReversed) {
    if (!swipeGestures.value || !scrollController.hasClients) return;

    if (details.primaryVelocity != null) {
      bool isLeftSwipe = details.primaryVelocity! > 0;
      bool isRightSwipe = details.primaryVelocity! < 0;

      if ((isLeftSwipe && !isReversed) || (isRightSwipe && isReversed)) {
        // Next chapter
        if (canGoNext.value) goToNextChapter();
      } else if ((isRightSwipe && !isReversed) || (isLeftSwipe && isReversed)) {
        // Previous chapter
        if (canGoPrevious.value) goToPreviousChapter();
      }
    }
  }

  void _saveTracking() {
    savedChapter.value = offlineStorageController.getReadChapter(
          media.id,
          currentChapter.value.number!,
        ) ??
        currentChapter.value;

    Future.microtask(() {
      offlineStorageController.addOrUpdateNovel(
        media,
        chapters,
        currentChapter.value,
        source,
      );
      offlineStorageController.addOrUpdateReadChapter(
        media.id,
        currentChapter.value,
        source: source,
      );
    });
  }

  String _buildHtml(String input) {
    String processed = input
        .replaceAll("\\n", "")
        .replaceAll("\\t", "")
        .replaceAll("\\\"", "\"")
        .replaceAll('*"', '')
        .replaceAll('"*', '');

    return '''
      <div id="readerViewContent">
        <div style="
          padding: ${paddingVertical.value}px ${paddingHorizontal.value}px;
          max-width: 800px;
          margin: 0 auto;
        ">
          $processed
        </div>
      </div>
    ''';
  }

  void toggleControls() {
    showControls.value = !showControls.value;
    if (showControls.value) {
      _resetHideTimer();
    } else {
      _hideTimer?.cancel();
    }
  }

  void toggleSettings() {
    showSettings.value = !showSettings.value;
    if (showSettings.value) {
      showControls.value = true;
    }
  }

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
      
      currentChapter.value = chapters[currentIndex + 1];
      updateNavigationButtons();
      await fetchData();
      
      if (scrollController.hasClients) {
        scrollController.jumpTo(0);
      }
    }
  }

  Future<void> goToPreviousChapter() async {
    int currentIndex = chapters.indexWhere((ch) => ch.link == currentChapter.value.link);
    if (currentIndex > 0) {
      _stopAutoScroll();
      autoScrollEnabled.value = false;
      
      currentChapter.value = chapters[currentIndex - 1];
      updateNavigationButtons();
      await fetchData();
      
      if (scrollController.hasClients) {
        scrollController.jumpTo(0);
      }
    }
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

  void setFontSize(double value) {
    fontSize.value = value.clamp(12.0, 24.0);
    _saveSettings();
  }

  void setLineHeight(double value) {
    lineHeight.value = value.clamp(1.0, 3.0);
    _saveSettings();
  }

  void setParagraphSpacing(double value) {
    paragraphSpacing.value = value.clamp(8.0, 32.0);
    _saveSettings();
  }

  void setLetterSpacing(double value) {
    letterSpacing.value = value.clamp(-1.0, 2.0);
    _saveSettings();
  }

  void setWordSpacing(double value) {
    wordSpacing.value = value.clamp(0.0, 5.0);
    _saveSettings();
  }

  void setFontFamily(String value) {
    fontFamily.value = value;
    _saveSettings();
  }

  void setTextAlign(int value) {
    textAlign.value = value;
    _saveSettings();
  }

  void setPadding(double horizontal, double vertical) {
    paddingHorizontal.value = horizontal.clamp(8.0, 32.0);
    paddingVertical.value = vertical.clamp(4.0, 24.0);
    _saveSettings();
    // Refresh content with new padding
    if (novelContent.isNotEmpty) {
      novelContent.value = _buildHtml(novelContent.value.replaceAll(RegExp(r'<div id="readerViewContent">.*?</div>'), ''));
    }
  }

  void togglePageReaderMode() {
    pageReaderMode.value = !pageReaderMode.value;
    _saveSettings();
  }

  void toggleVerticalSeekbar() {
    verticalSeekbar.value = !verticalSeekbar.value;
    _saveSettings();
  }

  void toggleSwipeGestures() {
    swipeGestures.value = !swipeGestures.value;
    _saveSettings();
  }

  void toggleVolumeScrolling() {
    volumeButtonScrolling.value = !volumeButtonScrolling.value;
    _saveSettings();
  }

  void toggleTapToScroll() {
    tapToScroll.value = !tapToScroll.value;
    _saveSettings();
  }

  void setTapScrollAmount(double amount) {
    tapScrollAmount.value = amount.clamp(10.0, 50.0);
    _saveSettings();
  }

  void toggleKeepScreenOn() {
    keepScreenOn.value = !keepScreenOn.value;
    if (keepScreenOn.value) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    }
    _saveSettings();
  }

  void toggleRemoveExtraSpacing() {
    removeExtraSpacing.value = !removeExtraSpacing.value;
    if (novelContent.isNotEmpty) {
      fetchData(); // Refresh content with new spacing setting
    }
    _saveSettings();
  }

  void toggleBionicReading() {
    bionicReading.value = !bionicReading.value;
    if (novelContent.isNotEmpty) {
      fetchData(); // Refresh content with bionic reading
    }
    _saveSettings();
  }

  void setBionicIntensity(double value) {
    bionicIntensity.value = value.clamp(0.3, 0.7);
    if (bionicReading.value && novelContent.isNotEmpty) {
      fetchData(); // Refresh content with new intensity
    }
    _saveSettings();
  }

  void toggleShowReadingProgress() {
    showReadingProgress.value = !showReadingProgress.value;
    _saveSettings();
  }

  void toggleShowBatteryAndTime() {
    showBatteryAndTime.value = !showBatteryAndTime.value;
    _saveSettings();
  }

  void setTtsSpeed(double value) {
    ttsSpeed.value = value.clamp(0.1, 1.0);
    if (ttsPlaying.value) {
      flutterTts.setSpeechRate(ttsSpeed.value);
    }
    _saveSettings();
  }

  void setTtsPitch(double value) {
    ttsPitch.value = value.clamp(0.5, 2.0);
    if (ttsPlaying.value) {
      flutterTts.setPitch(ttsPitch.value);
    }
    _saveSettings();
  }

  void setTtsVoice(String value) {
    ttsVoice.value = value;
    _saveSettings();
  }

  void toggleTtsAutoAdvance() {
    ttsAutoAdvance.value = !ttsAutoAdvance.value;
    _saveSettings();
  }

  void resetSettings() {
    fontSize.value = 16.0;
    lineHeight.value = 1.6;
    letterSpacing.value = 0.0;
    wordSpacing.value = 0.0;
    paragraphSpacing.value = 16.0;
    fontFamily.value = 'System';
    textAlign.value = 0;
    paddingHorizontal.value = 16.0;
    paddingVertical.value = 8.0;
    
    autoScrollEnabled.value = false;
    autoScrollSpeed.value = 3.0;
    volumeButtonScrolling.value = false;
    tapToScroll.value = false;
    tapScrollAmount.value = 20.0;
    keepScreenOn.value = true;
    verticalSeekbar.value = true;
    swipeGestures.value = true;
    pageReaderMode.value = false;
    removeExtraSpacing.value = false;
    bionicReading.value = false;
    bionicIntensity.value = 0.5;
    showReadingProgress.value = true;
    showBatteryAndTime.value = true;
    
    ttsSpeed.value = 0.5;
    ttsPitch.value = 1.0;
    ttsAutoAdvance.value = true;
    
    _stopAutoScroll();
    if (novelContent.isNotEmpty) {
      novelContent.value = _buildHtml(novelContent.value.replaceAll(RegExp(r'<div id="readerViewContent">.*?</div>'), ''));
    }
    _saveSettings();
  }

  // Dictionary feature - get selected text
  String? getSelectedText() {
    // This method is kept for compatibility but we're handling selection
    // directly through SelectionArea in the UI
    return null;
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
