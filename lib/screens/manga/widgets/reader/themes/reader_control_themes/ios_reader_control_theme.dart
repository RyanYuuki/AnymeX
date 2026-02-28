import 'dart:io';
import 'dart:ui';

import 'package:anymex/screens/anime/watch/controls/widgets/progress_slider.dart';
import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:anymex/screens/manga/widgets/reader/auto_scroll_menu.dart';
import 'package:anymex/screens/manga/widgets/reader/tabbed_reader_settings.dart';
import 'package:anymex/screens/manga/widgets/reader/themes/setup/reader_control_theme.dart';
import 'package:anymex/screens/manga/widgets/reader/top_controls.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class IOSReaderControlTheme extends ReaderControlTheme {
  @override
  String get id => 'ios';

  @override
  String get name => 'iOS 26';

  @override
  Widget buildTopControls(BuildContext context, ReaderController controller) {
    return _LiquidTopBar(controller: controller);
  }

  @override
  Widget buildBottomControls(
      BuildContext context, ReaderController controller) {
    return _LiquidBottomBar(controller: controller);
  }

  @override
  Widget buildCenterControls(
      BuildContext context, ReaderController controller) {
    return const ReaderAutoScrollMenu();
  }
}

class _LiquidTopBar extends StatelessWidget {
  const _LiquidTopBar({required this.controller});
  final ReaderController controller;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final topInset = mq.padding.top;
    final isDesktop =
        Platform.isWindows || Platform.isLinux || Platform.isMacOS;
    final extraTop = isDesktop ? 12.0 : 0.0;
    final visY = topInset + extraTop + 10;
    final hidY = -(topInset + 100);

    return Obx(() {
      final show = controller.showControls.value;
      final pageVisible =
          controller.showPageIndicator.value || controller.showControls.value;

      return Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutExpo,
            top: show ? visY : hidY,
            left: 14,
            right: 14,
            child: Row(
              children: [
                _LiquidBubble(
                  size: 44,
                  onTap: Get.back,
                  child: const Icon(
                    CupertinoIcons.arrow_left,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ChapterPill(controller: controller),
                ),
                const SizedBox(width: 10),
                _LiquidBubble(
                  size: 44,
                  onTap: () => TabbedReaderSettings(controller: controller)
                      .showSettings(context),
                  child: const Icon(
                    CupertinoIcons.slider_horizontal_3,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            top: show ? visY + 54 : visY,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedOpacity(
                opacity: pageVisible ? 1 : 0,
                duration: const Duration(milliseconds: 220),
                child: _PagePill(controller: controller),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _ChapterPill extends StatelessWidget {
  const _ChapterPill({required this.controller});
  final ReaderController controller;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showChapterSheet(context),
      child: _LiquidSurface(
        height: 44,
        radius: 22,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Obx(() {
          final chapter = controller.currentChapter.value;
          final total = controller.pageList.length;
          final progress =
              total <= 0 ? 0.0 : controller.currentPageIndex.value / total;

          return Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  strokeWidth: 2.2,
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  color: Colors.white.withValues(alpha: 0.92),
                  strokeCap: StrokeCap.round,
                ),
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        letterSpacing: -0.1,
                      ),
                    ),
                    Text(
                      'Ch. ${_fmt(chapter?.number)} · ${controller.chapterList.length} total',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_up_chevron_down,
                size: 13,
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ],
          );
        }),
      ),
    );
  }

  String _fmt(double? n) {
    if (n == null) return '—';
    return n % 1 == 0 ? n.toInt().toString() : n.toString();
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

class _PagePill extends StatelessWidget {
  const _PagePill({required this.controller});
  final ReaderController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final label = switch (controller.loadingState.value) {
        LoadingState.loading => 'Loading…',
        LoadingState.error => 'Error',
        LoadingState.loaded =>
          '${controller.currentPageIndex.value} / ${controller.pageList.length}',
      };

      return _LiquidSurface(
        radius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      );
    });
  }
}

class _LiquidBottomBar extends StatelessWidget {
  const _LiquidBottomBar({required this.controller});
  final ReaderController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isOverscrolling.value) {
        return _OverscrollBubble(controller: controller);
      }

      final w = MediaQuery.of(context).size.width;
      final pillW = w > 900 ? w * 0.5 : double.infinity;
      final show = controller.showControls.value;

      return AnimatedPositioned(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutExpo,
        bottom: show ? 0 : -160,
        left: 0,
        right: 0,
        child: _BottomGradientFade(
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Center(
                child: _LiquidSurface(
                  width: pillW,
                  radius: 26,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  child: Row(
                    children: [
                      _NavBubble(
                        icon: CupertinoIcons.chevron_left,
                        canNav: controller.canGoPrev,
                        onTap: () => controller.chapterNavigator(false),
                      ),
                      const SizedBox(width: 6),
                      Expanded(child: _SliderSection(controller: controller)),
                      const SizedBox(width: 6),
                      _NavBubble(
                        icon: CupertinoIcons.chevron_right,
                        canNav: controller.canGoNext,
                        onTap: () => controller.chapterNavigator(true),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _SliderSection extends StatelessWidget {
  const _SliderSection({required this.controller});
  final ReaderController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loaded = controller.loadingState.value == LoadingState.loaded &&
          controller.pageList.isNotEmpty;

      if (!loaded) {
        return const SizedBox(
          height: 44,
          child: Center(
            child: CupertinoActivityIndicator(color: Colors.white),
          ),
        );
      }

      final pageCount = controller.pageList.length.toDouble();
      final current = controller.currentPageIndex.value.toDouble();
      final value = current.clamp(1.0, pageCount);

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Obx(() => Text(
                        'Page ${controller.currentPageIndex.value}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.1,
                        ),
                      )),
                  Text(
                    '${controller.pageList.length} pages',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 10,
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  thumbShape: SliderComponentShape.noThumb,
                  trackShape: const IOSSliderTrackShape(),
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

class _NavBubble extends StatelessWidget {
  const _NavBubble({
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
      return AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.28,
        duration: const Duration(milliseconds: 180),
        child: _LiquidBubble(
          size: 40,
          onTap: enabled ? onTap : null,
          child: Icon(icon, color: Colors.white, size: 17),
        ),
      );
    });
  }
}

class _OverscrollBubble extends StatelessWidget {
  const _OverscrollBubble({required this.controller});
  final ReaderController controller;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: _BottomGradientFade(
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Center(
              child: Obx(() {
                final progress = controller.overscrollProgress.value;
                final isNext = controller.isOverscrollingNext.value;
                final list = controller.chapterList;
                final curIdx =
                    list.indexOf(controller.currentChapter.value!);
                final targetIdx = isNext ? curIdx + 1 : curIdx - 1;

                final atEdge =
                    targetIdx < 0 || targetIdx >= list.length;
                final target = atEdge ? null : list[targetIdx];

                final heading = atEdge
                    ? (targetIdx < 0 ? 'First Chapter' : 'Last Chapter')
                    : (isNext ? 'Next' : 'Previous');

                final subtext = target != null
                    ? (target.title ?? 'Chapter ${target.number}')
                    : (isNext
                        ? 'You\'ve reached the end'
                        : 'You\'re at the beginning');

                return _LiquidSurface(
                  width: w > 900 ? w * 0.46 : double.infinity,
                  radius: 22,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 42,
                        height: 42,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: 1,
                              strokeWidth: 3.5,
                              color: Colors.white.withValues(alpha: 0.15),
                              strokeCap: StrokeCap.round,
                            ),
                            CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 3.5,
                              color: _ringColor(progress),
                              strokeCap: StrokeCap.round,
                            ),
                            Icon(
                              _arrowIcon(isNext),
                              size: 16,
                              color: _ringColor(progress),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              heading,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              subtext,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
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
        ),
      ),
    );
  }

  Color _ringColor(double p) {
    if (p < 0.6) {
      return Color.lerp(
          Colors.white.withOpacity(0.4), Colors.white, p / 0.6)!;
    }
    return Color.lerp(
        Colors.white, const Color(0xFF5AC8FA), (p - 0.6) / 0.4)!;
  }

  IconData _arrowIcon(bool isNext) {
    final dir = controller.readingDirection.value;
    if (dir.axis == Axis.vertical) {
      return isNext ? CupertinoIcons.arrow_down : CupertinoIcons.arrow_up;
    }
    if (dir.reversed) {
      return isNext ? CupertinoIcons.arrow_left : CupertinoIcons.arrow_right;
    }
    return isNext ? CupertinoIcons.arrow_right : CupertinoIcons.arrow_left;
  }
}

class _LiquidSurface extends StatelessWidget {
  const _LiquidSurface({
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.radius = 20,
    this.blurSigma = 28,
    this.tintAlpha = 0.18,
    this.edgeAlpha = 0.32,
  });

  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final double blurSigma;
  final double tintAlpha;
  final double edgeAlpha;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.compose(
          outer: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          inner: ImageFilter.matrix(
            Matrix4.identity().storage,
          ),
        ),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: tintAlpha + 0.06),
                Colors.white.withValues(alpha: tintAlpha - 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withValues(alpha: edgeAlpha),
              width: 0.75,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 30,
                spreadRadius: -4,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.06),
                blurRadius: 1,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _LiquidBubble extends StatelessWidget {
  const _LiquidBubble({
    required this.child,
    required this.size,
    this.onTap,
  });

  final Widget child;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.4),
                radius: 1.1,
                colors: [
                  Colors.white.withValues(alpha: 0.28),
                  Colors.white.withValues(alpha: 0.12),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.34),
                width: 0.75,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 20,
                  spreadRadius: -2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _BottomGradientFade extends StatelessWidget {
  const _BottomGradientFade({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          stops: const [0.0, 0.55, 1.0],
          colors: [
            Colors.black.withValues(alpha: 0.65),
            Colors.black.withValues(alpha: 0.2),
            Colors.black.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: child,
    );
  }
}
