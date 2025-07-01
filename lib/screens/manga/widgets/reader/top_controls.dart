import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:anymex/screens/manga/widgets/reader/settings_view.dart';
import 'package:anymex/widgets/common/animated_app_bar.dart';
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
    return Obx(() => AnimatedAppBar(
          bottomPadding: 5,
          animationDuration: const Duration(milliseconds: 300),
          height: 120,
          isVisible: controller.showControls.value,
          content: Container(
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
                      _buildBackButton(context),
                      const SizedBox(width: 6),
                      _buildChapterInfo(context),
                      const SizedBox(width: 6),
                      _buildSettingsButton(context),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildPageInfo(context),
                ],
              ),
            ),
          ),
        ));
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
                    'Ch ${controller.currentChapter.value!.number}/${controller.chapterList.last.number}',
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
    return Container(
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
    );
  }

  void _showSettings(BuildContext context) {
    ReaderSettings(controller: controller).showSettings(context);
  }
}
