import 'package:anymex/utils/logger.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ReaderView extends StatelessWidget {
  final ReaderController controller;

  const ReaderView({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      switch (controller.loadingState.value) {
        case LoadingState.loading:
          return _buildLoadingView(context);
        case LoadingState.error:
          return _buildErrorView(context);
        case LoadingState.loaded:
          return _buildContentView(context);
      }
    });
  }

  Widget _buildLoadingView(BuildContext context) {
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

  Widget _buildErrorView(BuildContext context) {
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
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              controller.errorMessage.value.isNotEmpty
                  ? controller.errorMessage.value
                  : 'Something went wrong while loading the pages',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: controller.retryFetchImages,
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

  Widget _buildContentView(BuildContext context) {
    if (controller.readingLayout.value == MangaPageViewMode.continuous) {
      return ScrollablePositionedList.builder(
        itemCount: controller.pageList.length,
        itemScrollController: controller.itemScrollController,
        itemPositionsListener: controller.itemPositionsListener,
        scrollOffsetListener: controller.scrollOffsetListener,
        initialScrollIndex: (controller.currentPageIndex.value - 1)
            .clamp(0, controller.pageList.length - 1),
        physics: const BouncingScrollPhysics(),
        scrollDirection: controller.readingDirection.value.axis,
        reverse: controller.readingDirection.value.reversed,
        itemBuilder: (context, index) {
          return _buildNewImage(context, controller.pageList[index], index);
        },
      );
    } else {
      return PreloadPageView.builder(
        itemCount: controller.pageList.length,
        controller: controller.pageController,
        preloadPagesCount: controller.preloadPages.value,
        physics: const BouncingScrollPhysics(),
        scrollDirection: controller.readingDirection.value.axis,
        reverse: controller.readingDirection.value.reversed,
        onPageChanged: controller.onPageChanged,
        itemBuilder: (context, index) {
          return _buildNewImageForPaged(
              context, controller.pageList[index], index);
        },
      );
    }
  }

  Widget _buildNewImage(BuildContext context, PageUrl page, int index) {
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: controller.enableZoom.value ? null : () => controller.toggleControls(),
      child: Obx(() {
        return Container(
          padding: EdgeInsets.symmetric(
              vertical: controller.spacedPages.value ? 8.0 : 0),
          child: Column(
            children: [
              ExtendedImage.network(
                page.url,
                cacheMaxAge: Duration(
                    days: settingsController.preferences
                        .get('cache_days', defaultValue: 7)),
                mode: controller.enableZoom.value 
                    ? ExtendedImageMode.gesture 
                    : ExtendedImageMode.none,
                gaplessPlayback: true,
                cache: true,
                headers: (page.headers?.isEmpty ?? true)
                    ? {
                        'Referer':
                            sourceController.activeMangaSource.value?.baseUrl ??
                                ''
                      }
                    : page.headers,
                fit: BoxFit.contain,
                alignment: Alignment.center,
                constraints: BoxConstraints(
                  maxWidth: 500 * controller.pageWidthMultiplier.value,
                ),
                filterQuality: FilterQuality.medium,
                enableLoadState: true,
                initGestureConfigHandler: controller.enableZoom.value 
                    ? (ExtendedImageState state) {
                        return GestureConfig(
                          minScale: 0.8,
                          animationMinScale: 0.7,
                          maxScale: 5.0,
                          animationMaxScale: 5.5,
                          speed: 1.0,
                          inertialSpeed: 100.0,
                          initialScale: 1.0,
                          inPageView: false,
                          initialAlignment: InitialAlignment.center,
                        );
                      }
                    : null,
                onDoubleTap: controller.enableZoom.value 
                    ? (ExtendedImageGestureState state) {
                        controller.toggleControls();
                      }
                    : null,
                loadStateChanged: (ExtendedImageState state) {
                  switch (state.extendedImageLoadState) {
                    case LoadState.loading:
                      final progress =
                          (state.loadingProgress?.cumulativeBytesLoaded ?? 0) /
                              (state.loadingProgress?.expectedTotalBytes ?? 1)
                                  .toDouble();
                      return SizedBox(
                        width: size.width,
                        height: 200,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnymexProgressIndicator(
                                value: progress,
                              ),
                              const SizedBox(height: 8),
                              Text('Loading page ${index + 1}...'),
                            ],
                          ),
                        ),
                      );

                    case LoadState.failed:
                      return Container(
                        width: size.width,
                        height: 200,
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
                                state.reLoadImage();
                                Logger.i(state.completedWidget.toString());
                              },
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      );

                    case LoadState.completed:
                      return state.completedWidget;
                  }
                },
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildNewImageForPaged(BuildContext context, PageUrl page, int index) {
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: controller.enableZoom.value ? null : () => controller.toggleControls(),
      child: Obx(() {
        return Padding(
          padding: EdgeInsets.symmetric(
              vertical: controller.spacedPages.value ? 8.0 : 0),
          child: Center(
            // Center the image in the page
            child: ExtendedImage.network(
              page.url,
              cacheMaxAge: Duration(
                  days: settingsController.preferences
                      .get('cache_days', defaultValue: 7)),
              mode: controller.enableZoom.value 
                  ? ExtendedImageMode.gesture 
                  : ExtendedImageMode.none,
              gaplessPlayback: true,
              headers: (page.headers?.isEmpty ?? true)
                  ? {
                      'Referer':
                          sourceController.activeMangaSource.value?.baseUrl ??
                              ''
                    }
                  : page.headers,
              fit: BoxFit.contain,
              cache: true,
              alignment: Alignment.center,
              filterQuality: FilterQuality.medium,
              enableLoadState: true,
              initGestureConfigHandler: controller.enableZoom.value 
                  ? (ExtendedImageState state) {
                      return GestureConfig(
                        minScale: 0.8,
                        animationMinScale: 0.7,
                        maxScale: 5.0,
                        animationMaxScale: 5.5,
                        speed: 1.0,
                        inertialSpeed: 100.0,
                        initialScale: 1.0,
                        inPageView: true, // This is in PageView
                        initialAlignment: InitialAlignment.center,
                      );
                    }
                  : null,
              onDoubleTap: controller.enableZoom.value 
                  ? (ExtendedImageGestureState state) {
                      controller.toggleControls();
                    }
                  : null,
              loadStateChanged: (ExtendedImageState state) {
                switch (state.extendedImageLoadState) {
                  case LoadState.loading:
                    final progress =
                        (state.loadingProgress?.cumulativeBytesLoaded ?? 0) /
                            (state.loadingProgress?.expectedTotalBytes ?? 1)
                                .toDouble();
                    return SizedBox.fromSize(
                      size: Size(size.width, size.height),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnymexProgressIndicator(value: progress),
                            const SizedBox(height: 8),
                            Text('Loading page ${index + 1}...'),
                          ],
                        ),
                      ),
                    );

                  case LoadState.failed:
                    return SizedBox.fromSize(
                      size: Size(size.width, size.height),
                      child: Container(
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
                                state.reLoadImage();
                                Logger.i(state.completedWidget.toString());
                              },
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );

                  case LoadState.completed:
                    return state.completedWidget;
                }
              },
            ),
          ),
        );
      }),
    );
  }
}
