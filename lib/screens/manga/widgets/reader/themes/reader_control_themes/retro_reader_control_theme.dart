import 'dart:io';

import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:anymex/screens/manga/widgets/reader/settings_view.dart';
import 'package:anymex/screens/manga/widgets/reader/themes/setup/reader_control_theme.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/slider_semantics.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RetroReaderControlTheme extends ReaderControlTheme {
  @override
  String get id => 'retro';

  @override
  String get name => 'Retro';

  @override
  Widget buildTopControls(BuildContext context, ReaderController controller) {
    return _RetroTopBar(controller: controller);
  }

  @override
  Widget buildBottomControls(
      BuildContext context, ReaderController controller) {
    return _RetroBottomBar(controller: controller);
  }
}

class _RetroTopBar extends StatelessWidget {
  const _RetroTopBar({required this.controller});
  final ReaderController controller;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final topInset = mq.padding.top;

    return Obx(() {
      final show = controller.showControls.value;

      return AnimatedPositioned(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        top: show ? topInset + 4 : -(topInset + 60),
        left: 4,
        right: 4,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerHighest,
            border: Border.all(
              color: context.colors.outline.withOpacity(0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.opaque(0.4),
                offset: const Offset(4, 4),
                blurRadius: 0,
              ),
              BoxShadow(
                color: Colors.white.opaque(0.1),
                offset: const Offset(-2, -2),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              _RetroButton(
                icon: Icons.arrow_back,
                onTap: () => Get.back(),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showChapterSheet(context),
                  child: Obx(() {
                    final chapter = controller.currentChapter.value;
                    return Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ch. ${chapter?.number ?? 0}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            chapter?.title ?? 'Unknown',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              _RetroButton(
                icon: Icons.settings,
                onTap: () => ReaderSettings(controller: controller).showSettings(context),
              ),
            ],
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

class _RetroButton extends StatelessWidget {
  const _RetroButton({
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
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: context.colors.outline.withOpacity(0.5),
              width: 1,
            ),
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}

class _RetroBottomBar extends StatelessWidget {
  const _RetroBottomBar({required this.controller});
  final ReaderController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isOverscrolling.value) {
        return _RetroOverscroll(controller: controller);
      }

      final show = controller.showControls.value;

      return AnimatedPositioned(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        bottom: show ? 4 : -80,
        left: 4,
        right: 4,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerHighest,
            border: Border.all(
              color: context.colors.outline.withOpacity(0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.opaque(0.4),
                offset: const Offset(4, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              _RetroNavButton(
                icon: Icons.skip_previous,
                canNav: controller.canGoPrev,
                onTap: () => controller.chapterNavigator(false),
              ),
              Expanded(
                child: _RetroSlider(controller: controller),
              ),
              _RetroNavButton(
                icon: Icons.skip_next,
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

class _RetroNavButton extends StatelessWidget {
  const _RetroNavButton({
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
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: enabled
                ? context.colors.primary.withOpacity(0.8)
                : Colors.grey.withOpacity(0.3),
            border: Border(
              right: BorderSide(
                color: context.colors.outline.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          child: Icon(
            icon,
            color: enabled ? Colors.white : Colors.grey,
            size: 20,
          ),
        ),
      );
    });
  }
}

class _RetroSlider extends StatelessWidget {
  const _RetroSlider({required this.controller});
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
            child: Text(
              'LOADING',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
        );
      }

      final pageCount = controller.pageList.length.toDouble();
      final current = controller.currentPageIndex.value.toDouble();
      final value = current.clamp(1.0, pageCount);

      return Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${controller.currentPageIndex.value} / ${controller.pageList.length}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            SizedBox(
              height: 12,
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 6,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  overlayShape: NoOverlayShape(),
                  activeTrackColor: context.colors.primary,
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
        ),
      );
    });
  }
}

class _RetroOverscroll extends StatelessWidget {
  const _RetroOverscroll({required this.controller});
  final ReaderController controller;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 4,
      left: 4,
      right: 4,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: context.colors.primary,
          border: Border.all(
            color: Colors.white.withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.opaque(0.4),
              offset: const Offset(4, 4),
              blurRadius: 0,
            ),
          ],
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

            final text = target != null
                ? '${isNext ? "NEXT:" : "PREV:"} ${target.title ?? "Ch. ${target.number}"}'
                : (isNext ? 'END OF STORY' : 'START OF STORY');

            return Row(
              children: [
                SizedBox(
                  width: 48,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 4,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class NoOverlayShape extends SliderOverlayShape {
  const NoOverlayShape();
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => Size.zero;
  @override
  Widget build(BuildContext context, Offset center,
      {required Animation<double> activationAnimation,
      required Animation<double> enableAnimation,
      required bool isDiscrete,
      required TextDirection labelDirection,
      required SliderThemeData sliderTheme,
      required double value,
      required TextDirection textDirection,
      required double textScaleFactor,
      required Size sizeWithOverflow}) => const SizedBox.shrink();
}
