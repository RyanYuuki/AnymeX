import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/anymex_slider_m3.dart';
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
    return Obx(() {
      return AnimatedPositioned(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        bottom: controller.showControls.value ? 0 : -200,
        left: 0,
        right: 0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.opaque(0.95, iReallyMeanIt: true),
                Colors.black.opaque(0.0, iReallyMeanIt: true),
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
                  color: context.colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: context.colors.outline.opaque(0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.shadow.opaque(0.05),
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
        ),
      );
    });
  }

  Widget _buildPreviousButton(BuildContext context) {
    return Obx(() {
      return IconButton(
        onPressed: controller.canGoPrev.value
            ? () => controller.chapterNavigator(false)
            : null,
        icon: const Icon(Icons.skip_previous_rounded),
        style: IconButton.styleFrom(
          padding: const EdgeInsets.all(12),
          minimumSize: const Size(48, 48),
          backgroundColor: context.colors.surface.opaque(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    });
  }

  Widget _buildSliderSection() {
    return Obx(() => controller.loadingState.value != LoadingState.loaded ||
            controller.pageList.isEmpty
        ? const SizedBox(height: 32, child: Center(child: Text('Loading...')))
        : Expanded(
            child: AnymeXSliderM3(
              value: controller.currentPageIndex.value.toDouble(),
              label: controller.currentPageIndex.value.toString(),
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
          ));
  }

  Widget _buildNextButton(BuildContext context) {
    return Obx(() {
      return IconButton(
        onPressed: controller.canGoNext.value
            ? () => controller.chapterNavigator(true)
            : null,
        icon: const Icon(Icons.skip_next_rounded),
        style: IconButton.styleFrom(
          padding: const EdgeInsets.all(12),
          minimumSize: const Size(48, 48),
          backgroundColor: context.colors.surface.opaque(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    });
  }
}
