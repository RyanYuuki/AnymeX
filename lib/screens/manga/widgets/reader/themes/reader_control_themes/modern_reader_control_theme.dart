import 'dart:io';

import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:anymex/screens/manga/widgets/reader/settings_view.dart';
import 'package:anymex/screens/manga/widgets/reader/themes/setup/reader_control_theme.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/slider_semantics.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ModernReaderControlTheme extends ReaderControlTheme {
  @override
  String get id => 'modern';

  @override
  String get name => 'Modern';

  @override
  Widget buildTopControls(BuildContext context, ReaderController controller) {
    return _ModernTopBar(controller: controller);
  }

  @override
  Widget buildBottomControls(
      BuildContext context, ReaderController controller) {
    return _ModernBottomBar(controller: controller);
  }
}

class _ModernTopBar extends StatelessWidget {
  const _ModernTopBar({required this.controller});
  final ReaderController controller;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final topInset = mq.padding.top;
    const topBarHeight = 56.0;

    return Obx(() {
      final show = controller.showControls.value;
      final pageVisible =
          controller.showPageIndicator.value || controller.showControls.value;

      return Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            top: show ? topInset + 8 : -(topInset + 80),
            left: 16,
            right: 16,
            child: _buildTopBarContent(context, controller),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            top: show ? topInset + 72 : topInset + 8,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedOpacity(
                opacity: pageVisible ? 1 : 0,
                duration: const Duration(milliseconds: 250),
                child: _PageChip(controller: controller),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildTopBarContent(BuildContext context, ReaderController controller) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest.opaque(0.85),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.opaque(0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _ModernIconButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => Get.back(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ChapterCard(controller: controller),
          ),
          const SizedBox(width: 8),
          _ModernIconButton(
            icon: Icons.tune_rounded,
            onTap: () => ReaderSettings(controller: controller).showSettings(context),
          ),
        ],
      ),
    );
  }
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({required this.controller});
  final ReaderController controller;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showChapterSheet(context),
      child: Obx(() {
        final chapter = controller.currentChapter.value;
        final progress = controller.pageList.length > 0
            ? controller.currentPageIndex.value / controller.pageList.length
            : 0.0;

        return Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: context.colors.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(
                Icons.menu_book_rounded,
                size: 18,
                color: context.colors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chapter?.title ?? 'Unknown Chapter',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.colors.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${chapter?.number ?? 0} / ${controller.chapterList.length}',
                      style: TextStyle(
                        color: context.colors.onSurface.opaque(0.6),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  strokeWidth: 2,
                  backgroundColor: context.colors.outline.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation(context.colors.primary),
                ),
              ),
            ],
          ),
        );
      }),
    );
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

class _PageChip extends StatelessWidget {
  const _PageChip({required this.controller});
  final ReaderController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final label = switch (controller.loadingState.value) {
        LoadingState.loading => 'Loading...',
        LoadingState.error => 'Error',
        LoadingState.loaded =>
          'Page ${controller.currentPageIndex.value} / ${controller.pageList.length}',
      };

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHighest.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.opaque(0.12),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: context.colors.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      );
    });
  }
}

class _ModernBottomBar extends StatelessWidget {
  const _ModernBottomBar({required this.controller});
  final ReaderController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isOverscrolling.value) {
        return _OverscrollPanel(controller: controller);
      }

      final show = controller.showControls.value;

      return AnimatedPositioned(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        bottom: show ? 0 : -180,
        left: 0,
        right: 0,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.colors.surfaceContainerHighest.opaque(0.9),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.opaque(0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                _NavButton(
                  icon: Icons.skip_previous_rounded,
                  canNav: controller.canGoPrev,
                  onTap: () => controller.chapterNavigator(false),
                ),
                const SizedBox(width: 12),
                Expanded(child: _SliderControl(controller: controller)),
                const SizedBox(width: 12),
                _NavButton(
                  icon: Icons.skip_next_rounded,
                  canNav: controller.canGoNext,
                  onTap: () => controller.chapterNavigator(true),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: enabled
                ? context.colors.primary
                : context.colors.outline.withOpacity(0.2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: enabled ? Colors.white : context.colors.outline,
            size: 24,
          ),
        ),
      );
    });
  }
}

class _SliderControl extends StatelessWidget {
  const _SliderControl({required this.controller});
  final ReaderController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loaded = controller.loadingState.value == LoadingState.loaded &&
          controller.pageList.isNotEmpty;

      if (!loaded) {
        return const SizedBox(
          height: 48,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      final pageCount = controller.pageList.length.toDouble();
      final current = controller.currentPageIndex.value.toDouble();
      final value = current.clamp(1.0, pageCount);

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${controller.currentPageIndex.value} / ${controller.pageList.length}',
            style: TextStyle(
              color: context.colors.onSurface.withOpacity(0.6),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 4,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                thumbShape: SliderComponentShape.noThumb,
                overlayColor: Colors.transparent,
                activeTrackColor: context.colors.primary,
                inactiveTrackColor: context.colors.outline.withOpacity(0.2),
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
      );
    });
  }
}

class _OverscrollPanel extends StatelessWidget {
  const _OverscrollPanel({required this.controller});
  final ReaderController controller;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Obx(() {
            final progress = controller.overscrollProgress.value;
            final isNext = controller.isOverscrollingNext.value;
            final list = controller.chapterList;
            final curIdx = list.indexOf(controller.currentChapter.value!);
            final targetIdx = isNext ? curIdx + 1 : curIdx - 1;

            final atEdge = targetIdx < 0 || targetIdx >= list.length;
            final target = atEdge ? null : list[targetIdx];

            final heading = atEdge
                ? (targetIdx < 0 ? 'First Chapter' : 'Last Chapter')
                : (isNext ? 'Next' : 'Previous');

            final subtext = target != null
                ? target.title ?? 'Chapter ${target.number}'
                : (isNext ? 'You\'ve reached the end' : 'You\'re at the beginning');

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHighest.opaque(0.95),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.opaque(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: 1,
                          strokeWidth: 4,
                          backgroundColor: context.colors.outline.withOpacity(0.2),
                        ),
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 4,
                          valueColor: AlwaysStoppedAnimation(context.colors.primary),
                        ),
                        Icon(
                          isNext ? Icons.arrow_downward : Icons.arrow_upward,
                          size: 24,
                          color: context.colors.primary,
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
                          heading,
                          style: TextStyle(
                            color: context.colors.onSurface.withOpacity(0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtext,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.colors.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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

class _ModernIconButton extends StatelessWidget {
  const _ModernIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: context.colors.outline.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: context.colors.onSurface,
          size: 20,
        ),
      ),
    );
  }
}
