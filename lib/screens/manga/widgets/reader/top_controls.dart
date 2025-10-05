import 'dart:io';

import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:anymex/screens/manga/widgets/reader/settings_view.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ReaderTopControls extends StatelessWidget {
  final ReaderController controller;

  const ReaderTopControls({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDesktop =
          Platform.isWindows || Platform.isLinux || Platform.isMacOS;
      final mediaQuery = MediaQuery.of(context);
      final statusBarHeight = mediaQuery.padding.top;
      const topControlsHeight = 50.0;
      const gapBetweenControls = 8.0;

      final topControlsVisiblePosition =
          statusBarHeight + 8 + (isDesktop ? 40 : 0);
      final topControlsHiddenPosition =
          -(statusBarHeight + topControlsHeight + gapBetweenControls + 20);

      final pageInfoVisiblePosition =
          topControlsVisiblePosition + topControlsHeight + gapBetweenControls;
      final pageInfoHiddenPosition = statusBarHeight + 8;

      return Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            top: controller.showControls.value
                ? topControlsVisiblePosition
                : topControlsHiddenPosition,
            left: 10,
            right: 10,
            child: SizedBox(
              height: topControlsHeight,
              child: Row(
                children: [
                  _buildBackButton(context),
                  const SizedBox(width: 6),
                  _buildChapterInfo(context),
                  const SizedBox(width: 6),
                  _buildSettingsButton(context),
                ],
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            top: controller.showControls.value
                ? pageInfoVisiblePosition
                : pageInfoHiddenPosition,
            left: 0,
            right: 0,
            child: Center(
              child: _buildPageInfo(context),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildBackButton(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: IconButton(
        onPressed: () => Get.back(),
        icon:
            const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildChapterInfo(BuildContext context) {
    return Expanded(
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              height: 30,
              child: AnymexProgressIndicator(
                value: controller.pageList.isEmpty
                    ? 0
                    : (controller.currentPageIndex.value /
                        controller.pageList.length),
                strokeWidth: 2,
                backgroundColor: Colors.white.withOpacity(0.2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.currentChapter.value?.title ?? 'Unknown Chapter',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Chapter ${controller.currentChapter.value?.number?.round() ?? '-'} of ${controller.chapterList.last.number?.round() ?? '-'}',
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
    );
  }

  Widget _buildSettingsButton(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: IconButton(
        onPressed: () => _showSettings(context),
        icon: const Icon(Icons.settings_rounded, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildPageInfo(BuildContext context) {
    return AnimatedOpacity(
      opacity: controller.showPageIndicator.value
          ? 1
          : controller.showControls.value
              ? 1
              : 0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Text(
          controller.loadingState.value == LoadingState.loading
              ? 'Loading...'
              : controller.loadingState.value == LoadingState.error
                  ? 'Error loading pages'
                  : 'Page ${controller.currentPageIndex.value} of ${controller.pageList.length}',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _showSettings(BuildContext context) {
    ReaderSettings(controller: controller).showSettings(context);
  }
}
