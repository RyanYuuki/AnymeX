import 'package:anymex/database/isar_models/chapter.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/novel/reader/controller/reader_controller.dart';
import 'package:anymex/screens/novel/reader/widgets/bottom_controls.dart';
import 'package:anymex/screens/novel/reader/widgets/novel_content.dart';
import 'package:anymex/screens/novel/reader/widgets/settings_view.dart';
import 'package:anymex/screens/novel/reader/widgets/top_controls.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:ui';

class NovelReader extends StatefulWidget {
  final Chapter chapter;
  final Media media;
  final List<Chapter> chapters;
  final Source source;

  const NovelReader({
    super.key,
    required this.chapter,
    required this.media,
    required this.chapters,
    required this.source,
  });

  @override
  State<NovelReader> createState() => _NovelReaderState();
}

class _NovelReaderState extends State<NovelReader>
    with TickerProviderStateMixin {
  late NovelReaderController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(NovelReaderController(
      initialChapter: widget.chapter,
      chapters: widget.chapters,
      media: widget.media,
      source: widget.source,
    ));
  }

  @override
  void dispose() {
    Get.delete<NovelReaderController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      Widget content = Scaffold(
        backgroundColor: controller.useSystemReaderTheme
            ? Colors.transparent
            : controller.readerBackgroundColor,
        body: Stack(
          children: [
            NovelContentWidget(controller: controller),
            NovelTopControls(controller: controller),
            NovelBottomControls(controller: controller),
            NovelSettingsPanel(controller: controller),
            _buildOverscrollIndicator(context),
            _buildTtsFloater(context),
          ],
        ),
      );
      if (!controller.useSystemReaderTheme) {
        final baseTheme = Theme.of(context);
        content = Theme(
          data: baseTheme.copyWith(
            colorScheme: controller.readerColorScheme,
            scaffoldBackgroundColor: controller.readerBackgroundColor,
          ),
          child: content,
        );
      }
      if (controller.useSystemReaderTheme) {
        return Glow(child: content);
      }
      return content;
    });
  }

  Widget _buildTtsFloater(BuildContext context) {
    return Obx(() {
      if (!controller.ttsEnabled.value) return const SizedBox.shrink();

      final rightInset = MediaQuery.of(context).padding.right + 10;

      return Positioned(
        top: 0,
        bottom: 0,
        right: rightInset,
        child: IgnorePointer(
          ignoring: !controller.showControls.value,
          child: Center(
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeInOut,
              offset: controller.showControls.value
                  ? Offset.zero
                  : const Offset(1.2, 0),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: controller.showControls.value ? 1 : 0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 6),
                      decoration: BoxDecoration(
                        color: context.colors.surface.opaque(0.7),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                            color: context.colors.onSurface.opaque(0.18)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.opaque(0.15),
                            blurRadius: 14,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ttsMenuButton(
                            context: context,
                            icon: Icons.skip_previous_rounded,
                            tooltip: 'Previous Paragraph',
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              controller.ttsPrevious();
                            },
                          ),
                          const SizedBox(height: 4),
                          _ttsMenuButton(
                            context: context,
                            icon: controller.ttsPlaying.value
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            tooltip: controller.ttsPlaying.value
                                ? 'Pause TTS'
                                : 'Play TTS',
                            isActive: controller.ttsPlaying.value,
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              controller.toggleTtsPlayback();
                            },
                          ),
                          const SizedBox(height: 4),
                          _ttsMenuButton(
                            context: context,
                            icon: Icons.skip_next_rounded,
                            tooltip: 'Next Paragraph',
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              controller.ttsNext();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _ttsMenuButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        minimumSize: const Size(44, 44),
        maximumSize: const Size(44, 44),
        padding: EdgeInsets.zero,
        backgroundColor: isActive
            ? context.colors.primary.opaque(0.2)
            : context.colors.surface.opaque(0.55),
        foregroundColor:
            isActive ? context.colors.primary : context.colors.onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      icon: Icon(icon, size: 20),
    );
  }

  Widget _buildOverscrollIndicator(BuildContext context) {
    return Obx(() {
      if (!controller.isOverscrolling.value) return const SizedBox.shrink();

      final progress = controller.overscrollProgress.value;
      final isNext = controller.isOverscrollingNext.value;
      final currentIndex = controller.chapters
          .indexWhere((ch) => ch.link == controller.currentChapter.value.link);
      final targetIndex = isNext ? currentIndex + 1 : currentIndex - 1;
      final targetChapter =
          (targetIndex >= 0 && targetIndex < controller.chapters.length)
              ? controller.chapters[targetIndex]
              : null;

      final subtitleText = isNext ? 'Next Chapter' : 'Previous Chapter';
      final titleText = targetChapter?.title ??
          'Chapter ${targetChapter?.number ?? '?'}';

  
      final String displaySubtitle;
      final String displayTitle;
      if (targetChapter != null) {
        displaySubtitle = subtitleText;
        displayTitle = titleText;
      } else if (targetIndex < 0) {
        displaySubtitle = 'Reached Top';
        displayTitle = 'This is the First Chapter';
      } else {
        displaySubtitle = 'Reached End';
        displayTitle = 'This is the Last Chapter';
      }

      Color progressColor;
      if (progress < 0.5) {
        progressColor = Color.lerp(
          context.colors.primary.opaque(0.5),
          context.colors.primary,
          progress * 2,
        )!;
      } else if (progress < 0.8) {
        progressColor = context.colors.primary;
      } else {
        progressColor = Color.lerp(
          context.colors.primary,
          Colors.green,
          (progress - 0.8) * 5,
        )!;
      }

      return Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                context.colors.surface.opaque(0.95),
                context.colors.surface.opaque(0.0),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 8,
                        backgroundColor: context.colors.surfaceContainer,
                        color: context.colors.outline.opaque(0.2),
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 8,
                        backgroundColor: Colors.transparent,
                        color: progressColor,
                      ),
                    ),
                    Icon(
                      isNext
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      size: 26,
                      color: progressColor,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: progressColor.opaque(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        displaySubtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.colors.onSurface.opaque(0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnymexText(
                        text: displayTitle,
                        size: 14,
                        variant: TextVariant.semiBold,
                        color: context.colors.onSurface,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        isMarquee: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
