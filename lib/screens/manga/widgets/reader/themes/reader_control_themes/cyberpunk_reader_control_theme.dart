import 'dart:io';
import 'dart:ui';

import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:anymex/screens/manga/widgets/reader/settings_view.dart';
import 'package:anymex/screens/manga/widgets/reader/themes/setup/reader_control_theme.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/slider_semantics.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CyberpunkReaderControlTheme extends ReaderControlTheme {
  @override
  String get id => 'cyberpunk';

  @override
  String get name => 'Cyberpunk';

  @override
  Widget buildTopControls(BuildContext context, ReaderController controller) {
    return _CyberTopBar(controller: controller);
  }

  @override
  Widget buildBottomControls(
      BuildContext context, ReaderController controller) {
    return _CyberBottomBar(controller: controller);
  }
}

class _CyberTopBar extends StatelessWidget {
  const _CyberTopBar({required this.controller});
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
        top: show ? topInset + 8 : -(topInset + 70),
        left: 8,
        right: 8,
        child: _buildTopContent(context, controller),
      );
    });
  }

  Widget _buildTopContent(BuildContext context, ReaderController controller) {
    return Obx(() {
      final chapter = controller.currentChapter.value;

      return Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.black87,
          border: Border.all(
            color: context.colors.primary,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: context.colors.primary.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              decoration: BoxDecoration(
                color: context.colors.primary,
                border: const Border(
                  right: BorderSide(color: Colors.white24, width: 2),
                ),
              ),
              child: IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => _showChapterSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.colors.primary.withOpacity(0.2),
                          border: Border.all(color: context.colors.primary, width: 1),
                        ),
                        child: Text(
                          'CH.${chapter?.number ?? 0}',
                          style: TextStyle(
                            color: context.colors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          chapter?.title ?? 'UNKNOWN',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_drop_down,
                          color: context.colors.primary, size: 18),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              width: 50,
              decoration: BoxDecoration(
                color: context.colors.primary,
                border: const Border(
                  left: BorderSide(color: Colors.white24, width: 2),
                ),
              ),
              child: IconButton(
                onPressed: () => ReaderSettings(controller: controller).showSettings(context),
                icon: const Icon(Icons.settings, color: Colors.white, size: 22),
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

class _CyberBottomBar extends StatelessWidget {
  const _CyberBottomBar({required this.controller});
  final ReaderController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isOverscrolling.value) {
        return _CyberOverscroll(controller: controller);
      }

      final show = controller.showControls.value;

      return AnimatedPositioned(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        bottom: show ? 8 : -120,
        left: 8,
        right: 8,
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: Colors.black87,
            border: Border.all(color: context.colors.primary, width: 2),
            boxShadow: [
              BoxShadow(
                color: context.colors.primary.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: -2,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                _CyberButton(
                  icon: Icons.chevron_left,
                  onTap: () => controller.chapterNavigator(false),
                ),
                Expanded(child: _CyberSlider(controller: controller)),
                _CyberButton(
                  icon: Icons.chevron_right,
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

class _CyberButton extends StatelessWidget {
  const _CyberButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Container(
        width: 64,
        height: double.infinity,
        decoration: BoxDecoration(
          color: context.colors.primary.withOpacity(0.2),
          border: const Border(
            left: BorderSide(color: Colors.white24, width: 1),
            right: BorderSide(color: Colors.white24, width: 1),
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

class _CyberSlider extends StatelessWidget {
  const _CyberSlider({required this.controller});
  final ReaderController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loaded = controller.loadingState.value == LoadingState.loaded &&
          controller.pageList.isNotEmpty;

      if (!loaded) {
        return const SizedBox(
          height: 64,
          child: Center(
            child: Text(
              'LOADING',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
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

      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${controller.currentPageIndex.value} / ${controller.pageList.length}',
            style: TextStyle(
              color: context.colors.primary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 20,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 6,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                activeTrackColor: context.colors.primary,
                inactiveTrackColor: Colors.white24,
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
      );
    });
  }
}

class _CyberOverscroll extends StatelessWidget {
  const _CyberOverscroll({required this.controller});
  final ReaderController controller;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 8,
      left: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black87,
          border: Border.all(color: context.colors.primary, width: 2),
          boxShadow: [
            BoxShadow(
              color: context.colors.primary.withOpacity(0.5),
              blurRadius: 20,
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
                  width: 50,
                  height: 50,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: 1,
                        strokeWidth: 6,
                        backgroundColor: Colors.white24,
                        color: context.colors.primary.withOpacity(0.3),
                      ),
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 6,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation(context.colors.primary),
                      ),
                      Icon(
                        isNext ? Icons.arrow_downward : Icons.arrow_upward,
                        color: Colors.white,
                        size: 24,
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
                        isNext ? 'NEXT SECTOR' : 'PREV SECTOR',
                        style: TextStyle(
                          color: context.colors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        progress < 1.0
                            ? 'Loading...'
                            : (isNext ? 'Reached End' : 'At Start'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
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
