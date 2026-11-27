import 'package:anymex/l10n/l10n_extension.dart';
import 'dart:io';
import 'dart:ui';

import 'package:anymex/screens/anime/watch/controls/widgets/progress_slider.dart';
import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:anymex/screens/manga/widgets/reader/auto_scroll_menu.dart';
import 'package:anymex/screens/manga/widgets/reader/tabbed_reader_settings.dart';
import 'package:anymex/screens/manga/widgets/reader/themes/setup/reader_control_theme.dart';
import 'package:anymex/screens/manga/widgets/reader/top_controls.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_bottomsheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';

class IOSReaderControlTheme extends ReaderControlTheme {
  @override
  String get id => 'ios';

  @override
  String get name => 'iOS 26';

  @override
  Widget buildTopControls(BuildContext context, ReaderController controller) {
    return _buildLiquidTopBar(context, controller);
  }

  @override
  Widget buildBottomControls(
      BuildContext context, ReaderController controller) {
    return _buildLiquidBottomBar(context, controller);
  }

  @override
  Widget buildCenterControls(
      BuildContext context, ReaderController controller) {
    return const ReaderAutoScrollMenu();
  }
}

Widget _buildLiquidTopBar(BuildContext context, ReaderController controller) {
  final topInset = MediaQuery.paddingOf(context).top;
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
              _buildLiquidBubble(
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
                child: _buildChapterPill(context, controller),
              ),
              const SizedBox(width: 10),
              _buildLiquidBubble(
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
              child: _buildPagePill(context, controller),
            ),
          ),
        ),
      ],
    );
  });
}

String _formatChapterNumber(double? n) {
  if (n == null) return '—';
  return n % 1 == 0 ? n.toInt().toString() : n.toString();
}

Widget _buildChapterPill(BuildContext context, ReaderController controller) {
  return GestureDetector(
    onTap: () {
      AnymeXSheet.custom(
        const ChapterListSheet(),
        context,
        showDragHandle: true,
      );
    },
    child: _buildLiquidSurface(
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
                  AnymeXText(
                    chapter?.title ?? context.l10n.unknownChapter,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      letterSpacing: -0.1,
                    ),
                  ),
                  AnymeXText(
                    context.l10n.chTotalLabel(
                      _formatChapterNumber(chapter?.number),
                      '${controller.chapterList.length}',
                    ),
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

Widget _buildPagePill(BuildContext context, ReaderController controller) {
  return Obx(() {
    final label = switch (controller.loadingState.value) {
      LoadingState.loading => context.l10n.loadingEllipsisUnicode,
      LoadingState.error => 'Error',
      LoadingState.loaded =>
        '${controller.currentPageIndex.value} / ${controller.pageList.length}',
    };

    return _buildLiquidSurface(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: AnymeXText(
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

Widget _buildLiquidBottomBar(
    BuildContext context, ReaderController controller) {
  return Obx(() {
    final w = MediaQuery.sizeOf(context).width;
    final pillW = w > 900 ? w * 0.5 : double.infinity;
    final show = controller.showControls.value;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutExpo,
      bottom: show ? 0 : -160,
      left: 0,
      right: 0,
      child: _buildBottomGradientFade(
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Center(
              child: _buildLiquidSurface(
                width: pillW,
                radius: 26,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Row(
                  children: [
                    _buildNavBubble(
                      icon: CupertinoIcons.chevron_left,
                      canNav: controller.canGoPrev,
                      onTap: () => controller.chapterNavigator(false),
                    ),
                    const SizedBox(width: 6),
                    Expanded(child: _buildSliderSection(context, controller)),
                    const SizedBox(width: 6),
                    _buildNavBubble(
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

Widget _buildSliderSection(BuildContext context, ReaderController controller) {
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
                Obx(() => AnymeXText(
                      context.l10n.pageNumber(
                          (controller.currentPageIndex.value).toString()),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.1,
                      ),
                    )),
                AnymeXText(
                  context.l10n
                      .pages2((controller.pageList.length).toString()),
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

Widget _buildNavBubble({
  required IconData icon,
  required RxBool canNav,
  required VoidCallback onTap,
}) {
  return Obx(() {
    final enabled = canNav.value;
    return AnimatedOpacity(
      opacity: enabled ? 1.0 : 0.28,
      duration: const Duration(milliseconds: 180),
      child: _buildLiquidBubble(
        size: 40,
        onTap: enabled ? onTap : null,
        child: Icon(icon, color: Colors.white, size: 17),
      ),
    );
  });
}

Widget _buildLiquidSurface({
  required Widget child,
  double? width,
  double? height,
  EdgeInsetsGeometry? padding,
  double radius = 20,
}) {
  const double blurSigma = 24;
  const double tintAlpha = 0.28;
  const double edgeAlpha = 0.34;

  return ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
      child: Container(
        width: width,
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: const Color(0x66181818),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: tintAlpha + 0.08),
              Colors.white.withValues(alpha: tintAlpha),
            ],
          ),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: Colors.white.withValues(alpha: edgeAlpha),
            width: 0.75,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 25,
              spreadRadius: -4,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.08),
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

Widget _buildLiquidBubble({
  required Widget child,
  required double size,
  VoidCallback? onTap,
}) {
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

Widget _buildBottomGradientFade({required Widget child}) {
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
