import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/core/Eval/dart/model/page.dart';
import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manga_page_view/manga_page_view.dart';

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
    return Obx(() {
      final size = MediaQuery.of(context).size;
      final initialPageSize = Size(size.width, size.height);
      final hasPreviousChapter = controller.canGoPrev.value;
      final hasNextChapter = controller.canGoNext.value;
      final isLoaded = controller.loadingState.value == LoadingState.loaded;
      final currentLayout = controller.readingLayout.value;
      final canOverscroll = controller.overscrollToChapter.value;

      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => controller.toggleControls(),
        onDoubleTap: () {},
        child: MangaPageView(
          mode: controller.readingLayout.value,
          direction: controller.readingDirection.value,
          controller: controller.pageViewController,
          options: MangaPageViewOptions(
            padding: MediaQuery.paddingOf(context),
            mainAxisOverscroll: false,
            crossAxisOverscroll: false,
            minZoomLevel: switch (currentLayout) {
              MangaPageViewMode.continuous => 0.75,
              MangaPageViewMode.paged => 1.0
            },
            maxZoomLevel: 8.0,
            spacing: controller.spacedPages.value ? 20 : 0,
            pageWidthLimit: getResponsiveSize(context,
                mobileSize: double.infinity,
                desktopSize: controller.defaultWidth.value *
                    controller.pageWidthMultiplier.value),
            edgeIndicatorContainerSize: 240,
            initialPageSize: initialPageSize,
            precacheAhead: currentLayout == MangaPageViewMode.paged
                ? 2
                : controller.preloadPages.value,
            precacheBehind: currentLayout == MangaPageViewMode.paged ? 2 : 0,
          ),
          pageCount: controller.pageList.length,
          pageBuilder: (context, index) {
            return _buildImage(context, controller.pageList[index], index);
          },
          onPageChange: (index) => controller.onPageChanged(index),
          startEdgeDragIndicatorBuilder: (context, info) {
            return Column(
              spacing: 16,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: info.isTriggered ? 1.6 : 1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.elasticOut,
                  child: Icon(
                    hasPreviousChapter
                        ? Icons.skip_previous_rounded
                        : Icons.block_rounded,
                    color: info.isTriggered ? Colors.white : Colors.white54,
                    size: 36,
                  ),
                ),
                Text(
                  hasPreviousChapter
                      ? 'Previous chapter'
                      : "No previous chapter",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: info.isTriggered ? Colors.white : Colors.white54),
                )
              ],
            );
          },
          endEdgeDragIndicatorBuilder: (context, info) {
            return Column(
              spacing: 16,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: info.isTriggered ? 1.6 : 1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.elasticOut,
                  child: Icon(
                    hasNextChapter
                        ? Icons.skip_next_rounded
                        : Icons.block_rounded,
                    color: info.isTriggered ? Colors.white : Colors.white54,
                    size: 36,
                  ),
                ),
                Text(
                  hasNextChapter ? 'Next chapter' : "No next chapter",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: info.isTriggered ? Colors.white : Colors.white54),
                )
              ],
            );
          },
          onStartEdgeDrag: hasPreviousChapter && canOverscroll && isLoaded
              ? () => controller.chapterNavigator(false)
              : null,
          onEndEdgeDrag: hasNextChapter && canOverscroll && isLoaded
              ? () => controller.chapterNavigator(true)
              : null,
        ),
      );
    });
  }

  Widget _buildImage(BuildContext context, PageUrl page, int index) {
    final size = MediaQuery.of(context).size;
    final initialPageSize = Size(size.width, size.height);
    return StatefulBuilder(
      builder: (context, setState) {
        return CachedNetworkImage(
          filterQuality: FilterQuality.high,
          imageUrl: page.url,
          httpHeaders: (page.headers?.isEmpty ?? true)
              ? {'Referer': sourceController.activeMangaSource.value!.baseUrl!}
              : page.headers,
          fit: BoxFit.contain,
          progressIndicatorBuilder: (context, url, progress) {
            return SizedBox.fromSize(
              size: initialPageSize,
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
            );
          },
          errorWidget: (context, url, error) {
            return SizedBox.fromSize(
              size: initialPageSize,
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
                      onPressed: () async {
                        final imageProvider = CachedNetworkImageProvider(
                          page.url,
                          headers: page.headers,
                        );
                        await imageProvider.evict();
                        setState(() {});
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
          },
        );
      },
    );
  }
}
