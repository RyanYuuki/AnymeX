import 'dart:io';
import 'dart:ui';

import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:anymex/screens/manga/widgets/reader/settings_view.dart';
import 'package:anymex/screens/manga/widgets/reader/themes/setup/reader_control_theme.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/slider_semantics.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AnimeReaderControlTheme extends ReaderControlTheme {
  @override
  String get id => 'anime';

  @override
  String get name => 'Anime';

  @override
  Widget buildTopControls(BuildContext context, ReaderController controller) {
    return _AnimeTopBar(controller: controller);
  }

  @override
  Widget buildBottomControls(
      BuildContext context, ReaderController controller) {
    return _AnimeBottomBar(controller: controller);
  }
}

class _AnimeTopBar extends StatelessWidget {
  const _AnimeTopBar({required this.controller});
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
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            top: show ? topInset + 8 : -(topInset + 80),
            left: 12,
            right: 12,
            child: _buildAnimeTopContent(context, controller),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            top: show ? topInset + 68 : topInset + 8,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedOpacity(
                opacity: pageVisible ? 1 : 0,
                duration: const Duration(milliseconds: 300),
                child: _AnimePageChip(controller: controller),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildAnimeTopContent(BuildContext context, ReaderController controller) {
    return Obx(() {
      final chapter = controller.currentChapter.value;
      final progress = controller.pageList.length > 0
          ? controller.currentPageIndex.value / controller.pageList.length
          : 0.0;

      return Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              context.colors.primary,
              context.colors.tertiary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: context.colors.primary.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22),
              style: IconButton.styleFrom(
                foregroundColor: Colors.white,
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => _showChapterSheet(context),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.menu_book_rounded,
                          color: Colors.white, size: 18),
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
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  'Ch. ${chapter?.number ?? 0}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '• ${controller.chapterList.length} total',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.expand_more_rounded,
                          color: Colors.white70, size: 20),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () => ReaderSettings(controller: controller).showSettings(context),
              icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
              style: IconButton.styleFrom(
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _AnimePageChip({required ReaderController controller}) {
    return Obx(() {
      final label = switch (controller.loadingState.value) {
        LoadingState.loading => '読込中...',
        LoadingState.error => 'エラー',
        LoadingState.loaded =>
          'ページ ${controller.currentPageIndex.value} / ${controller.pageList.length}',
      };

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
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

class _AnimeBottomBar extends StatelessWidget {
  const _AnimeBottomBar({required this.controller});
  final ReaderController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isOverscrolling.value) {
        return _AnimeOverscroll(controller: controller);
      }

      final show = controller.showControls.value;

      return AnimatedPositioned(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        bottom: show ? 12 : -120,
        left: 12,
        right: 12,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.95),
                Colors.black.withOpacity(0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: context.colors.primary.withOpacity(0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              _AnimeNavButton(
                icon: Icons.skip_previous_rounded,
                onTap: () => controller.chapterNavigator(false),
                isFirst: true,
              ),
              const SizedBox(width: 12),
              Expanded(child: _AnimeSlider(controller: controller)),
              const SizedBox(width: 12),
              _AnimeNavButton(
                icon: Icons.skip_next_rounded,
                onTap: () => controller.chapterNavigator(true),
                isLast: true,
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _AnimeNavButton extends StatelessWidget {
  const _AnimeNavButton({
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
        width: 52,
        height: 52,
        child: Container(
          decoration: BoxDecoration(
            gradient: isFirst
                ? LinearGradient(
                    colors: [
                      context.colors.primary,
                      context.colors.primary.withOpacity(0.8),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : (isLast
                    ? LinearGradient(
                        colors: [
                          context.colors.primary.withOpacity(0.8),
                          context.colors.primary,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )
                    : null),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: onTap,
            icon: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      );
    });
  }
}

class _AnimeSlider extends StatelessWidget {
  const _AnimeSlider({required this.controller});
  final ReaderController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loaded = controller.loadingState.value == LoadingState.loaded &&
          controller.pageList.isNotEmpty;

      if (!loaded) {
        return const SizedBox(
          height: 52,
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation(context.colors.primary),
              ),
            ),
          ),
        );
      }

      final pageCount = controller.pageList.length.toDouble();
      final current = controller.currentPageIndex.value.toDouble();
      final value = current.clamp(1.0, pageCount);

      return SizedBox(
        height: 52,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${controller.currentPageIndex.value} / ${controller.pageList.length}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 6,
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 6,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  activeTrackColor: context.colors.primary,
                  inactiveTrackColor: Colors.white.withOpacity(0.2),
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

class _AnimeOverscroll extends StatelessWidget {
  const _AnimeOverscroll({required this.controller});
  final ReaderController controller;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 12,
      left: 12,
      right: 12,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.colors.primary.withOpacity(0.9),
                  context.colors.tertiary.withOpacity(0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: SafeArea(
              top: false,
              child: Obx(() {
                final progress = controller.overscrollProgress.value;
                final isNext = controller.isOverscrollingNext.value;

                return Row(
                  children: [
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: 1,
                            strokeWidth: 5,
                            backgroundColor: Colors.white.withOpacity(0.2),
                          ),
                          CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 5,
                            backgroundColor: Colors.transparent,
                            valueColor: const AlwaysStoppedAnimation(Colors.white),
                          ),
                          Icon(
                            isNext ? Icons.arrow_downward : Icons.arrow_upward,
                            color: Colors.white,
                            size: 26,
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
                            isNext ? 'NEXT' : 'PREVIOUS',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            progress < 1.0
                                ? 'Loading...'
                                : (isNext ? 'Reached End' : 'Reached Start'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
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
