import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
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
    return Obx(() {
      if (controller.isOverscrolling.value) {
        return _buildOverscrollIndicator(context);
      }

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

  Widget _buildOverscrollIndicator(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              context.colors.surface.opaque(0.95),
              context.colors.surface.opaque(0.0),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(() {
                final progress = controller.overscrollProgress.value;

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 8,
                        backgroundColor: context.colors.surfaceContainer,
                        color: context.colors.outline.opaque(0.2),
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 8,
                        backgroundColor: Colors.transparent,
                        color: _getProgressColor(context, progress),
                      ),
                    ),
                    Icon(
                      _getOverscrollIcon(),
                      size: 26,
                      color: _getProgressColor(context, progress),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 16),
              Obx(() {
                final isNext = controller.isOverscrollingNext.value;
                final currentIndex = controller.chapterList
                    .indexOf(controller.currentChapter.value!);
                final targetIndex =
                    isNext ? currentIndex + 1 : currentIndex - 1;



                final targetChapter = (targetIndex >= 0 && targetIndex < controller.chapterList.length)
                    ? controller.chapterList[targetIndex]
                    : null;
                
                String titleText;
                if (targetChapter != null) {
                   titleText = targetChapter.title ?? 'Chapter ${targetChapter.number}';
                } else if (targetIndex < 0) {
                   titleText = "This is the First Chapter"; 
                } else {
                   titleText = "This is the Last Chapter";
                }

                String subtitleText;
                if (targetIndex < 0) {
                  subtitleText = 'Reached Top';
                } else if (targetIndex >= controller.chapterList.length) {
                  subtitleText = 'Reached End';
                } else {
                  subtitleText = isNext ? 'Next Chapter' : 'Previous Chapter';
                }

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _getProgressColor(
                        context,
                        controller.overscrollProgress.value,
                      ).opaque(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        subtitleText,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .opaque(0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        titleText,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.colors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Color _getProgressColor(BuildContext context, double progress) {
    if (progress < 0.5) {
      return Color.lerp(
        context.colors.primary.opaque(0.5),
        context.colors.primary,
        progress * 2,
      )!;
    } else if (progress < 0.8) {
      return context.colors.primary;
    } else {
      return Color.lerp(
        context.colors.primary,
        Colors.green,
        (progress - 0.8) * 5,
      )!;
    }
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
            child: CustomSlider(
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

  IconData _getOverscrollIcon() {
    final dir = controller.readingDirection.value;
    final isNext = controller.isOverscrollingNext.value;

    if (dir.axis == Axis.vertical) {

      return isNext ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
    } else {
    
      final isRTL = dir.reversed; 
      if (isRTL) {
          return isNext ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded;
      } else {
          return isNext ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded;
      }
    }
  }
}
