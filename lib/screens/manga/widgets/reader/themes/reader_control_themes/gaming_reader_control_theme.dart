import 'dart:io';

import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:anymex/screens/manga/widgets/reader/settings_view.dart';
import 'package:anymex/screens/manga/widgets/reader/themes/setup/reader_control_theme.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/slider_semantics.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GamingReaderControlTheme extends ReaderControlTheme {
  @override
  String get id => 'gaming';

  @override
  String get name => 'Gaming';

  @override
  Widget buildTopControls(BuildContext context, ReaderController controller) {
    return _GamingTopBar(controller: controller);
  }

  @override
  Widget buildBottomControls(
      BuildContext context, ReaderController controller) {
    return _GamingBottomBar(controller: controller);
  }
}

class _GamingTopBar extends StatelessWidget {
  const _GamingTopBar({required this.controller});
  final ReaderController controller;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final topInset = mq.padding.top;

    return Obx(() {
      final show = controller.showControls.value;

      return AnimatedPositioned(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        top: show ? topInset + 8 : -(topInset + 70),
        left: 8,
        right: 8,
        child: _buildGamingTopContent(context, controller),
      );
    });
  }

  Widget _buildGamingTopContent(BuildContext context, ReaderController controller) {
    return Obx(() {
      final chapter = controller.currentChapter.value;

      return Container(
        height: 52,
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHighest,
          border: Border.all(
            color: context.colors.outline.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              decoration: BoxDecoration(
                color: context.colors.primary,
              ),
              child: IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => _showChapterSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: context.colors.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'CH.${chapter?.number ?? 0}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              chapter?.title ?? 'UNKNOWN',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'OF ${controller.chapterList.length}',
                        style: TextStyle(
                          color: context.colors.onSurface.withOpacity(0.5),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              width: 52,
              decoration: BoxDecoration(
                color: context.colors.primary,
              ),
              child: IconButton(
                onPressed: () => ReaderSettings(controller: controller).showSettings(context),
                icon: const Icon(Icons.settings, color: Colors.white, size: 24),
              ),
            ),
          ],
        ),
      );
    });
  }

  void _showChapterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        snap: true,
        snapSizes: const [0.5],
        expand: false,
        builder: (ctx, sc) => ChapterListSheet(scrollController: sc),
      ),
    );
  }
}

class _GamingBottomBar extends StatelessWidget {
  const _GamingBottomBar({required this.controller});
  final ReaderController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isOverscrolling.value) {
        return _GamingOverscroll(controller: controller);
      }

      final show = controller.showControls.value;

      return AnimatedPositioned(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        bottom: show ? 8 : -100,
        left: 8,
        right: 8,
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerHighest,
            border: Border.all(
              color: context.colors.outline.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                _GamingButton(
                  icon: Icons.chevron_left,
                  onTap: () => controller.chapterNavigator(false),
                  isFirst: true,
                ),
                Expanded(child: _GamingSlider(controller: controller)),
                _GamingButton(
                  icon: Icons.chevron_right,
                  onTap: () => controller.chapterNavigator(true),
                  isLast: true,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _GamingButton extends StatelessWidget {
  const _GamingButton({
    required this.icon,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return SizedBox(
        width: 64,
        height: double.infinity,
        child: Container(
          decoration: BoxDecoration(
            color: context.colors.primary,
            borderRadius: isFirst
                ? const BorderRadius.only(topLeft: Radius.circular(8))
                : (isLast
                    ? const BorderRadius.only(topRight: Radius.circular(8))
                    : null),
          ),
          child: IconButton(
            onPressed: onTap,
            icon: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
      );
    });
  }
}

class _GamingSlider extends StatelessWidget {
  const _GamingSlider({required this.controller});
  final ReaderController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loaded = controller.loadingState.value == LoadingState.loaded &&
          controller.pageList.isNotEmpty;

      if (!loaded) {
        return const SizedBox(
          height: 72,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      final pageCount = controller.pageList.length.toDouble();
      final current = controller.currentPageIndex.value.toDouble();
      final value = current.clamp(1.0, pageCount);

      return SizedBox(
        height: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'PAGE ${controller.currentPageIndex.value} / ${controller.pageList.length}',
              style: TextStyle(
                color: context.colors.onSurface.withOpacity(0.6),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 8,
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 8,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                  activeTrackColor: context.colors.primary,
                  inactiveTrackColor: context.colors.outline.withOpacity(0.3),
                  overlayColor: Colors.transparent,
                ),
                child: Slider(
                  value: value,
                  min: 1,
                  max: pageCount,
                  onChanged: (v) {
                    final idx = v.toInt();
                    controller.currentPageIndex.value = idx;
                    controller.navigateToPage(idx - 1);
                  },
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _GamingOverscroll extends StatelessWidget {
  const _GamingOverscroll({required this.controller});
  final ReaderController controller;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 8,
      left: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHighest,
          border: Border.all(
            color: context.colors.primary,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: context.colors.primary.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Obx(() {
            final progress = controller.overscrollProgress.value;
            final isNext = controller.isOverscrollingNext.value;

            return Row(
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: 1,
                        strokeWidth: 8,
                        backgroundColor: context.colors.outline.withOpacity(0.2),
                        color: context.colors.primary.withOpacity(0.3),
                      ),
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 8,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation(context.colors.primary),
                      ),
                      Icon(
                        isNext ? Icons.arrow_downward : Icons.arrow_upward,
                        color: context.colors.primary,
                        size: 28,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isNext ? 'NEXT LEVEL' : 'PREV LEVEL',
                        style: TextStyle(
                          color: context.colors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        progress < 1.0
                            ? 'LOADING...'
                            : (isNext ? 'BOSS DEFEATED' : 'START AREA'),
                        style: TextStyle(
                          color: context.colors.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
