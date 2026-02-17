import 'dart:io';

import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:anymex/screens/manga/widgets/reader/settings_view.dart';
import 'package:anymex/screens/manga/widgets/reader/themes/setup/reader_control_theme.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/slider_semantics.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CinemaReaderControlTheme extends ReaderControlTheme {
  @override
  String get id => 'cinema';

  @override
  String get name => 'Cinema';

  @override
  Widget buildTopControls(BuildContext context, ReaderController controller) {
    return _CinemaTopBar(controller: controller);
  }

  @override
  Widget buildBottomControls(
      BuildContext context, ReaderController controller) {
    return _CinemaBottomBar(controller: controller);
  }
}

class _CinemaTopBar extends StatelessWidget {
  const _CinemaTopBar({required this.controller});
  final ReaderController controller;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final topInset = mq.padding.top;

    return Obx(() {
      final show = controller.showControls.value;

      return AnimatedPositioned(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        top: show ? topInset + 12 : -(topInset + 80),
        left: 0,
        right: 0,
        child: Center(
          child: GestureDetector(
            onTap: () => _showChapterSheet(context),
            child: Obx(() {
              final chapter = controller.currentChapter.value;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.menu_book_rounded,
                        color: Colors.white70, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Chapter ${chapter?.number ?? 0}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      chapter?.title ?? 'Unknown',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.arrow_drop_down,
                        color: Colors.white70, size: 18),
                  ],
                ),
              );
            }),
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

class _CinemaBottomBar extends StatelessWidget {
  const _CinemaBottomBar({required this.controller});
  final ReaderController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isOverscrolling.value) {
        return _CinemaOverscroll(controller: controller);
      }

      final show = controller.showControls.value;

      return AnimatedPositioned(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        bottom: show ? 20 : -140,
        left: 0,
        right: 0,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.9),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _CinemaButton(
                    icon: Icons.skip_previous_rounded,
                    onTap: () => controller.chapterNavigator(false),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: _CinemaSlider(controller: controller)),
                  const SizedBox(width: 16),
                  _CinemaButton(
                    icon: Icons.skip_next_rounded,
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

class _CinemaButton extends StatelessWidget {
  const _CinemaButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: IconButton(
          onPressed: onTap,
          icon: Icon(icon, color: Colors.white, size: 26),
        ),
      );
    });
  }
}

class _CinemaSlider extends StatelessWidget {
  const _CinemaSlider({required this.controller});
  final ReaderController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loaded = controller.loadingState.value == LoadingState.loaded &&
          controller.pageList.isNotEmpty;

      if (!loaded) {
        return const SizedBox(
          height: 56,
          child: Center(
            child: Text(
              'LOADING',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 3,
              ),
            ),
          ),
        );
      }

      final pageCount = controller.pageList.length.toDouble();
      final current = controller.currentPageIndex.value.toDouble();
      final value = current.clamp(1.0, pageCount);

      return SizedBox(
        height: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
              height: 6,
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 6,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                  activeTrackColor: Colors.white,
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

class _CinemaOverscroll extends StatelessWidget {
  const _CinemaOverscroll({required this.controller});
  final ReaderController controller;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.95),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.15), width: 1),
            ),
          ),
          child: Center(
            child: Obx(() {
              final progress = controller.overscrollProgress.value;
              final isNext = controller.isOverscrollingNext.value;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: 1,
                          strokeWidth: 8,
                          backgroundColor: Colors.white.withOpacity(0.1),
                        ),
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 8,
                          backgroundColor: Colors.transparent,
                          valueColor: const AlwaysStoppedAnimation(Colors.white),
                        ),
                        Icon(
                          isNext ? Icons.arrow_downward : Icons.arrow_upward,
                          color: Colors.white,
                          size: 36,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    progress < 1.0
                        ? (isNext ? 'Loading Next' : 'Loading Previous')
                        : (isNext ? 'End of Series' : 'Beginning of Series'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
