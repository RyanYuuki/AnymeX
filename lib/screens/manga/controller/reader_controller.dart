// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/core/Eval/dart/model/page.dart';
import 'package:anymex/core/Search/get_pages.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Offline/Hive/chapter.dart';
import 'package:anymex/screens/manga/reading_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/widgets/common/slider_semantics.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

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
  final RxDouble sliderValue = 1.0.obs;
  final RxDouble pageWidthMultiplier = 1.0.obs;
  final RxDouble scrollSpeedMultiplier = 1.0.obs;

  final defaultWidth = 400.obs;
  final defaultSpeed = 300.obs;

  final RxBool showControls = true.obs;
  final Rx<LoadingState> loadingState = LoadingState.loading.obs;
  final RxString errorMessage = ''.obs;

  // Scroll Controllers
  ItemScrollController? itemScrollController;
  ScrollOffsetController? scrollOffsetController;
  ItemPositionsListener? itemPositionsListener;
  ScrollOffsetListener? scrollOffsetListener;

  PageController? pageController;

  Timer? sliderDebouncer;
  bool _isNavigating = false;

  @override
  void onInit() {
    super.onInit();
    _initializeControllers();
    _getPreferences();
  }

  void _initializeControllers() {
    itemScrollController = ItemScrollController();
    scrollOffsetController = ScrollOffsetController();
    itemPositionsListener = ItemPositionsListener.create();
    scrollOffsetListener = ScrollOffsetListener.create();
  }

  void _getPreferences() {
    activeMode.value = ReadingMode.values[
        settingsController.preferences.get('reading_mode', defaultValue: 0)];
    pageWidthMultiplier.value =
        settingsController.preferences.get('image_width') ?? 1;
    scrollSpeedMultiplier.value =
        settingsController.preferences.get('scroll_speed') ?? 1;
  }

  void _savePreferences() {
    settingsController.preferences.put('reading_mode', activeMode.value.index);
    settingsController.preferences
        .put('image_width', pageWidthMultiplier.value);
    settingsController.preferences
        .put('scroll_speed', scrollSpeedMultiplier.value);
  }

  void _setupPositionListener() {
    if (itemPositionsListener != null) {
      itemPositionsListener!.itemPositions.removeListener(_onPositionChanged);
      itemPositionsListener!.itemPositions.addListener(_onPositionChanged);
    }
  }

  void _onPositionChanged() {
    if (itemPositionsListener == null) return;

    final positions = itemPositionsListener!.itemPositions.value;
    if (positions.isEmpty || _isNavigating) return;

    final topItem = positions.first;
    final newPageIndex = topItem.index + 1;

    if (newPageIndex != currentPageIndex.value) {
      currentPageIndex.value = newPageIndex;

      sliderDebouncer?.cancel();
      sliderDebouncer = Timer(const Duration(milliseconds: 700), () {
        sliderValue.value = currentPageIndex.roundToDouble();
      });

      currentChapter.value?.pageNumber = newPageIndex;
    }
  }

  void init(Media data, List<Chapter> chList, Chapter curCh) {
    media = data;
    chapterList = chList;
    currentChapter.value = curCh;

    pageController = PageController(initialPage: curCh.pageNumber ?? 0);
    _setupPositionListener();

    // Fetch images + track
    fetchImages(currentChapter.value!.link!);
  }

  void _initTracking() {
    savedChapter.value = offlineStorageController.getReadChapter(
        media.id, currentChapter.value!.number!);
  }

  void toggleControls() {
    showControls.value = !showControls.value;
  }

  void navigateToChapter(int index) async {
    if (index < 0 || index >= chapterList.length) return;

    _isNavigating = true;
    currentChapter.value = chapterList[index];
    currentPageIndex.value = 1;
    sliderValue.value = 1.0;

    await fetchImages(currentChapter.value!.link!);
    _isNavigating = false;
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
        sliderValue.value = currentPageIndex.value.toDouble();
        currentChapter.value?.totalPages = pageList.length;
        loadingState.value = LoadingState.loaded;

        if (savedChapter.value?.pageNumber != null &&
            savedChapter.value!.pageNumber! > 1) {
          await Future.delayed(const Duration(milliseconds: 100));
          _navigateToPage(savedChapter.value!.pageNumber! - 1);
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

  // Head, Body, Footer (Start)

  // Header (Start)
  Widget buildTopControls(BuildContext context) {
    return Obx(() => Container(
          height: 100,
          padding:
              const EdgeInsets.only(left: 10, right: 10, top: 8, bottom: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.8),
                Colors.black.withOpacity(0.4),
                Colors.transparent,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: IconButton(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.15)),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: AnymexProgressIndicator(
                                value: pageList.isEmpty
                                    ? 0
                                    : (currentPageIndex.value /
                                        pageList.length),
                                strokeWidth: 2,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentChapter.value?.title ??
                                        'Unknown Chapter',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Ch ${currentChapter.value!.number}/${chapterList.last.number}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: IconButton(
                        onPressed: () => showSettings(context),
                        icon: const Icon(Icons.settings_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: Text(
                    loadingState.value == LoadingState.loading
                        ? 'Loading...'
                        : loadingState.value == LoadingState.error
                            ? 'Error loading pages'
                            : 'Page ${currentPageIndex.value} of ${pageList.length}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
  // Header (End)

  // Body (Start)
  Widget buildReaderView() {
    return Obx(() {
      switch (loadingState.value) {
        case LoadingState.loading:
          return _buildLoadingView();
        case LoadingState.error:
          return _buildErrorView();
        case LoadingState.loaded:
          return _buildContentView();
      }
    });
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnymexProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading pages...'),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load chapter',
              style: Theme.of(Get.context!).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage.value.isNotEmpty
                  ? errorMessage.value
                  : 'Something went wrong while loading the pages',
              style: Theme.of(Get.context!).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: retryFetchImages,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentView() {
    if (activeMode.value == ReadingMode.webtoon) {
      return ScrollablePositionedList.builder(
        itemCount: pageList.length,
        itemScrollController: itemScrollController,
        itemPositionsListener: itemPositionsListener,
        scrollOffsetListener: scrollOffsetListener,
        initialScrollIndex:
            (currentPageIndex.value - 1).clamp(0, pageList.length - 1),
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          return _buildImage(context, pageList[index], index);
        },
      );
    } else {
      return PageView.builder(
        itemCount: pageList.length,
        controller: pageController,
        reverse: activeMode.value == ReadingMode.rtl,
        onPageChanged: (index) {
          currentPageIndex.value = index + 1;
          sliderValue.value = (index + 1).toDouble();
          currentChapter.value?.pageNumber = index + 1;
        },
        itemBuilder: (context, index) {
          return _buildImage(context, pageList[index], index);
        },
      );
    }
  }

  Widget _buildImage(BuildContext context, PageUrl page, int index) {
    return Center(
      child: SizedBox(
        width: getResponsiveSize(context,
            mobileSize: double.infinity,
            desktopSize: defaultWidth.value * pageWidthMultiplier.value),
        child: CachedNetworkImage(
          imageUrl: page.url,
          httpHeaders: page.headers,
          fit: BoxFit.fitWidth,
          progressIndicatorBuilder: (context, url, progress) => SizedBox(
            height: Get.height / 2,
            width: double.infinity,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnymexProgressIndicator(
                    value: progress.progress,
                  ),
                  const SizedBox(height: 8),
                  Text('Loading page ${index + 1}...'),
                ],
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            height: Get.height / 2,
            width: double.infinity,
            color: Colors.grey.withOpacity(0.1),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image_outlined,
                  size: 48,
                  color: Colors.grey.withOpacity(0.7),
                ),
                const SizedBox(height: 8),
                Text(
                  'Failed to load page ${index + 1}',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    // Force refresh the specific image
                    final imageProvider = CachedNetworkImageProvider(
                      page.url,
                      headers: page.headers,
                    );
                    imageProvider.evict();
                    // Trigger rebuild
                    update();
                  },
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  // Body (End)

  // Footer (Start)
  Widget buildBottomControls(BuildContext context) {
    return Obx(() => Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Theme.of(context).colorScheme.surface.withOpacity(0.95),
                Theme.of(context).colorScheme.surface.withOpacity(0.0),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Container(
                width: getResponsiveSize(context,
                    mobileSize: double.infinity,
                    desktopSize: MediaQuery.of(context).size.width * 0.4),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color:
                        Theme.of(context).colorScheme.outline.withOpacity(0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .shadow
                          .withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed:
                          chapterList.indexOf(currentChapter.value!) > 0 &&
                                  loadingState.value == LoadingState.loaded
                              ? () => chapterNavigator(false)
                              : null,
                      icon: const Icon(Icons.skip_previous_rounded),
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(12),
                        minimumSize: const Size(48, 48),
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surface
                            .withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),

                    10.width(),

                    // Slider section
                    loadingState.value != LoadingState.loaded ||
                            pageList.isEmpty
                        ? const SizedBox(
                            height: 32,
                            child: Center(child: Text('Loading...')))
                        : Expanded(
                            child: CustomSlider(
                              value: sliderValue.value,
                              min: 1,
                              max: pageList.length.toDouble(),
                              divisions:
                                  pageList.length > 1 ? pageList.length - 1 : 1,
                              onChanged: (value) {
                                sliderValue.value = value;
                              },
                              onDragEnd: (value) {
                                currentPageIndex.value = value.toInt();
                                _navigateToPage(value.toInt() - 1);
                              },
                            ),
                          ),

                    10.width(),

                    IconButton(
                      onPressed: chapterList.indexOf(currentChapter.value!) <
                                  chapterList.length - 1 &&
                              loadingState.value == LoadingState.loaded
                          ? () => chapterNavigator(true)
                          : null,
                      icon: const Icon(Icons.skip_next_rounded),
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(12),
                        minimumSize: const Size(48, 48),
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surface
                            .withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));
  }

  Future<void> _navigateToPage(int pageIndex) async {
    if (pageIndex < 0 || pageIndex >= pageList.length) return;

    _isNavigating = true;

    try {
      if (activeMode.value == ReadingMode.webtoon) {
        if (itemScrollController != null && itemScrollController!.isAttached) {
          await itemScrollController!.scrollTo(
            index: pageIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      } else {
        if (pageController != null && pageController!.hasClients) {
          await pageController!.animateToPage(
            pageIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
    } catch (e) {
      log('Navigation error: ${e.toString()}');
    } finally {
      _isNavigating = false;
    }
  }

  void changeActiveMode(ReadingMode readingMode) async {
    final currentPage = currentPageIndex.value - 1;
    activeMode.value = readingMode;

    await Future.delayed(const Duration(milliseconds: 100));

    await _navigateToPage(currentPage);
  }

  @override
  void onClose() {
    sliderDebouncer?.cancel();
    itemPositionsListener?.itemPositions.removeListener(_onPositionChanged);
    pageController?.dispose();
    super.onClose();
  }
  // Footer (End)

  // Extra Settings
  void showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 10),
                  child: Center(
                    child: Text(
                      'Reader Settings',
                      style: TextStyle(
                          fontSize: 18, fontFamily: 'Poppins-SemiBold'),
                    ),
                  ),
                ),
                Obx(() {
                  return CustomTile(
                    title: 'Layout',
                    description:
                        'Currently: ${activeMode.value.name.toUpperCase()}',
                    icon: Iconsax.card,
                    postFix: 0.height(),
                  );
                }),
                Obx(() {
                  final selections = List<bool>.generate(
                    ReadingMode.values.length,
                    (index) =>
                        index == ReadingMode.values.indexOf(activeMode.value),
                  );
                  return Center(
                    child: ToggleButtons(
                      isSelected: selections,
                      onPressed: (int index) {
                        final pageIndex = currentPageIndex.value;
                        activeMode.value = ReadingMode.values[index];
                        _savePreferences();
                        Future.delayed(const Duration(milliseconds: 50), () {
                          _navigateToPage(pageIndex);
                        });
                      },
                      children: const [
                        Tooltip(
                          message: 'Webtoon',
                          child: Icon(Icons.view_day),
                        ),
                        Tooltip(
                          message: 'LTR',
                          child: Icon(Icons.format_textdirection_l_to_r),
                        ),
                        Tooltip(
                          message: 'RTL',
                          child: Icon(Icons.format_textdirection_r_to_l),
                        ),
                      ],
                    ),
                  );
                }),
                if (!Platform.isAndroid && !Platform.isIOS)
                  Obx(() {
                    return CustomSliderTile(
                      title: 'Image Width',
                      sliderValue: pageWidthMultiplier.value,
                      onChanged: (double value) {
                        pageWidthMultiplier.value = value;
                      },
                      onChangedEnd: (e) => _savePreferences(),
                      description: 'Only Works with webtoon mode',
                      icon: Icons.image_aspect_ratio_rounded,
                      min: 1.0,
                      max: 4.0,
                      divisions: 39,
                    );
                  }),
                if (!Platform.isAndroid && !Platform.isIOS)
                  Obx(() {
                    return CustomSliderTile(
                      title: 'Scroll Multiplier',
                      sliderValue: scrollSpeedMultiplier.value,
                      onChanged: (double value) {
                        scrollSpeedMultiplier.value = value;
                      },
                      onChangedEnd: (e) => _savePreferences(),
                      description:
                          'Adjust Key Scrolling Speed (Up, Down, Left, Right)',
                      icon: Icons.speed,
                      min: 1.0,
                      max: 5.0,
                      divisions: 9,
                    );
                  }),
                20.height()
              ],
            ),
          ),
        );
      },
    );
  }
}
