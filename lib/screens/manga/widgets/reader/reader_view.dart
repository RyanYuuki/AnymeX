import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/core/Eval/dart/model/page.dart';
import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:anymex/screens/manga/reading_page.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
              controller.errorMessage.value.isNotEmpty
                  ? controller.errorMessage.value
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

  Widget _buildContentView() {
    if (controller.activeMode.value == ReadingMode.webtoon) {
      return ScrollablePositionedList.builder(
        itemCount: controller.pageList.length,
        itemScrollController: controller.itemScrollController,
        itemPositionsListener: controller.itemPositionsListener,
        scrollOffsetListener: controller.scrollOffsetListener,
        initialScrollIndex: (controller.currentPageIndex.value - 1)
            .clamp(0, controller.pageList.length - 1),
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          return _buildImage(context, controller.pageList[index], index);
        },
      );
    } else {
      return PageView.builder(
        itemCount: controller.pageList.length,
        controller: controller.pageController,
        reverse: controller.activeMode.value == ReadingMode.rtl,
        onPageChanged: (index) => controller.onPageChanged(index),
        itemBuilder: (context, index) {
          return _buildImage(context, controller.pageList[index], index);
        },
      );
    }
  }

  Widget _buildImage(BuildContext context, PageUrl page, int index) {
    return Obx(() {
      return Center(
        child: SizedBox(
          width: getResponsiveSize(context,
              mobileSize: double.infinity,
              desktopSize: controller.defaultWidth.value *
                  controller.pageWidthMultiplier.value),
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
                      controller.update();
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
          ),
        ),
      );
    });
  }
}
