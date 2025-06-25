import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/slider_semantics.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ReaderBottomControls extends StatelessWidget {
  final ReaderController controller;

  const ReaderBottomControls({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
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
                    _buildPreviousButton(context),
                    10.width(),
                    _buildSliderSection(),
                    10.width(),
                    _buildNextButton(context),
                  ],
                ),
              ),
            ),
          ),
        ));
  }

  Widget _buildPreviousButton(BuildContext context) {
    return IconButton(
      onPressed:
          controller.chapterList.indexOf(controller.currentChapter.value!) >
                      0 &&
                  controller.loadingState.value == LoadingState.loaded
              ? () => controller.chapterNavigator(false)
              : null,
      icon: const Icon(Icons.skip_previous_rounded),
      style: IconButton.styleFrom(
        padding: const EdgeInsets.all(12),
        minimumSize: const Size(48, 48),
        backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildSliderSection() {
    return controller.loadingState.value != LoadingState.loaded ||
            controller.pageList.isEmpty
        ? const SizedBox(height: 32, child: Center(child: Text('Loading...')))
        : Expanded(
            child: CustomSlider(
              value: controller.currentPageIndex.value.toDouble(),
              min: 1,
              max: controller.pageList.length.toDouble(),
              divisions: controller.pageList.length > 1
                  ? controller.pageList.length - 1
                  : 1,
              onChanged: (value) {
                controller.currentPageIndex.value = value.toInt();
                controller.navigateToPage(value.toInt() - 1);
              },
            ),
          );
  }

  Widget _buildNextButton(BuildContext context) {
    return IconButton(
      onPressed:
          controller.chapterList.indexOf(controller.currentChapter.value!) <
                      controller.chapterList.length - 1 &&
                  controller.loadingState.value == LoadingState.loaded
              ? () => controller.chapterNavigator(true)
              : null,
      icon: const Icon(Icons.skip_next_rounded),
      style: IconButton.styleFrom(
        padding: const EdgeInsets.all(12),
        minimumSize: const Size(48, 48),
        backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
