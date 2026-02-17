import 'dart:io';
import 'dart:ui';

import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:anymex/screens/manga/widgets/reader/settings_view.dart';
import 'package:anymex/screens/manga/widgets/reader/themes/setup/reader_control_theme.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/slider_semantics.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GlassReaderControlTheme extends ReaderControlTheme {
  @override
  String get id => 'glass';

  @override
  String get name => 'Glass';

  @override
  Widget buildTopControls(BuildContext context, ReaderController controller) {
    return _GlassTopBar(controller: controller);
  }

  @override
  Widget buildBottomControls(
      BuildContext context, ReaderController controller) {
    return _GlassBottomBar(controller: controller);
  }
}

class _GlassTopBar extends StatelessWidget {
  const _GlassTopBar({required this.controller});
  final ReaderController controller;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final topInset = mq.padding.top;

    return Obx(() {
      final show = controller.showControls.value;
      final pageVisible =
          controller.showPageIndicator.value || controller.showControls.value;

      return Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
            top: show ? topInset + 8 : -(topInset + 80),
            left: 20,
            right: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.opaque(0.1),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      _GlassIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Get.back(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _GlassChapterCard(controller: controller),
                      ),
                      const SizedBox(width: 8),
                      _GlassIconButton(
                        icon: Icons.tune_rounded,
                        onTap: () => ReaderSettings(controller: controller).showSettings(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            top: show ? topInset + 72 : topInset + 8,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedOpacity(
                opacity: pageVisible ? 1 : 0,
                duration: const Duration(milliseconds: 300),
                child: _PageBubble(controller: controller),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _GlassChapterCard extends StatelessWidget {
  const _GlassChapterCard({required this.controller});
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
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  strokeWidth: 2.5,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chapter?.title ?? 'Unknown',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Chapter ${chapter?.number ?? 0}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_drop_down_rounded,
                  color: Colors.white.withOpacity(0.6), size: 16),
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

class _PageBubble extends StatelessWidget {
  const _PageBubble({required this.controller});
  final ReaderController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final label = switch (controller.loadingState.value) {
        LoadingState.loading => 'Loading...',
        LoadingState.error => 'Error',
        LoadingState.loaded =>
          '${controller.currentPageIndex.value} / ${controller.pageList.length}',
      };

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    });
  }
}

class _GlassBottomBar extends StatelessWidget {
  const _GlassBottomBar({required this.controller});
  final ReaderController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isOverscrolling.value) {
        return _GlassOverscroll(controller: controller);
      }

      final show = controller.showControls.value;

      return AnimatedPositioned(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
        bottom: show ? 16 : -160,
        left: 16,
        right: 16,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.opaque(0.12),
                    Colors.white.withOpacity(0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  _GlassNavButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: () => controller.chapterNavigator(false),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _GlassSlider(controller: controller)),
                  const SizedBox(width: 12),
                  _GlassNavButton(
                    icon: Icons.chevron_right_rounded,
                    onTap: () => controller.chapterNavigator(true),
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

class _GlassNavButton extends StatelessWidget {
  const _GlassNavButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

class _GlassSlider extends StatelessWidget {
  const _GlassSlider({required this.controller});
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
            child: CircularProgressIndicator(color: Colors.white),
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
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
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
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white.withOpacity(0.2),
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

class _GlassOverscroll extends StatelessWidget {
  const _GlassOverscroll({required this.controller});
  final ReaderController controller;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.opaque(0.12),
                  Colors.white.withOpacity(0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: SafeArea(
              top: false,
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
                    : (isNext ? 'Reached end' : 'At beginning');

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
                            strokeWidth: 6,
                            backgroundColor: Colors.white.withOpacity(0.1),
                          ),
                          CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 6,
                            backgroundColor: Colors.transparent,
                            valueColor: const AlwaysStoppedAnimation(Colors.white),
                          ),
                          Icon(
                            isNext ? Icons.arrow_downward : Icons.arrow_upward,
                            color: Colors.white,
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
                            heading,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subtext,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
