import 'dart:io';

import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:anymex/screens/manga/widgets/reader/settings_view.dart';
import 'package:anymex/screens/manga/widgets/reader/themes/setup/reader_control_theme.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/slider_semantics.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MinimalReaderControlTheme extends ReaderControlTheme {
  @override
  String get id => 'minimal';

  @override
  String get name => 'Minimal';

  @override
  Widget buildTopControls(BuildContext context, ReaderController controller) {
    return _MinimalTopBar(controller: controller);
  }

  @override
  Widget buildBottomControls(
      BuildContext context, ReaderController controller) {
    return _MinimalBottomBar(controller: controller);
  }
}

class _MinimalTopBar extends StatelessWidget {
  const _MinimalTopBar({required this.controller});
  final ReaderController controller;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final topInset = mq.padding.top;

    return Obx(() {
      final show = controller.showControls.value;

      return AnimatedPositioned(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        top: show ? topInset + 12 : -(topInset + 60),
        left: 0,
        right: 0,
        child: Center(
          child: GestureDetector(
            onTap: () => _showChapterSheet(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.opaque(0.6),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.opaque(0.1),
                  width: 0.5,
                ),
              ),
              child: Obx(() {
                final chapter = controller.currentChapter.value;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${chapter?.number ?? 0}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.expand_more,
                      color: Colors.white.opaque(0.8),
                      size: 16,
                    ),
                  ],
                );
              }),
            ),
          ),
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

class _MinimalBottomBar extends StatelessWidget {
  const _MinimalBottomBar({required this.controller});
  final ReaderController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isOverscrolling.value) {
        return _MinimalOverscroll(controller: controller);
      }

      final show = controller.showControls.value;

      return AnimatedPositioned(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        bottom: show ? 16 : -120,
        left: 0,
        right: 0,
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _MinimalIcon(
                icon: Icons.skip_previous_rounded,
                canNav: controller.canGoPrev,
                onTap: () => controller.chapterNavigator(false),
              ),
              _MinimalPageNumber(controller: controller),
              _MinimalIcon(
                icon: Icons.tune_rounded,
                canNav: true.obs,
                onTap: () => ReaderSettings(controller: controller).showSettings(context),
              ),
              _MinimalIcon(
                icon: Icons.skip_next_rounded,
                canNav: controller.canGoNext,
                onTap: () => controller.chapterNavigator(true),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _MinimalIcon extends StatelessWidget {
  const _MinimalIcon({
    required this.icon,
    required this.canNav,
    required this.onTap,
  });

  final IconData icon;
  final RxBool canNav;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final enabled = canNav.value;
      return GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: enabled ? 1.0 : 0.3,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.opaque(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      );
    });
  }
}

class _MinimalPageNumber extends StatelessWidget {
  const _MinimalPageNumber({required this.controller});
  final ReaderController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final label = switch (controller.loadingState.value) {
        LoadingState.loading => '...',
        LoadingState.error => '!',
        LoadingState.loaded =>
          '${controller.currentPageIndex.value} / ${controller.pageList.length}',
      };

      return GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity!.dx > 0) {
            if (controller.canGoPrev.value) {
              controller.chapterNavigator(false);
            }
          } else {
            if (controller.canGoNext.value) {
              controller.chapterNavigator(true);
            }
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.opaque(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
    });
  }
}

class _MinimalOverscroll extends StatelessWidget {
  const _MinimalOverscroll({required this.controller});
  final ReaderController controller;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: SafeArea(
        top: false,
        child: Center(
          child: Obx(() {
            final progress = controller.overscrollProgress.value;
            final isNext = controller.isOverscrollingNext.value;
            final list = controller.chapterList;
            final curIdx = list.indexOf(controller.currentChapter.value!);
            final targetIdx = isNext ? curIdx + 1 : curIdx - 1;

            final atEdge = targetIdx < 0 || targetIdx >= list.length;
            final target = atEdge ? null : list[targetIdx];

            final text = target != null
                ? (target.title ?? 'Chapter ${target.number}')
                : (isNext ? 'Last Chapter' : 'First Chapter');

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.black.opaque(0.8),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isNext ? Icons.arrow_downward : Icons.arrow_upward,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 100,
                    height: 3,
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white.opaque(0.2),
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
