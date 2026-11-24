import 'package:anymex/screens/anime/watch/controller/player_utils.dart';
import 'package:anymex/screens/anime/watch/preview/seek_preview_engine.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_kit_video/media_kit_video.dart';

class SeekPreviewCard extends StatelessWidget {
  final SeekPreviewEngine engine;
  final Duration position;
  final String? chapterTitle;

  const SeekPreviewCard({
    super.key,
    required this.engine,
    required this.position,
    this.chapterTitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final cs = theme.colorScheme;
    const cardWidth = 160.0;
    const videoHeight = 90.0;

    return Container(
      width: cardWidth,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: cardWidth,
            height: videoHeight,
            child: Obx(() {
              final ready = engine.hasThumbnail.value;
              final controller = engine.controller;

              if (ready && controller != null) {
                return Video(
                  controller: controller,
                  controls: NoVideoControls,
                  fit: BoxFit.cover,
                );
              }

              return Container(
                color: Colors.black,
                child: Center(
                  child: Icon(
                    Icons.play_circle_outline_rounded,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                    size: 32,
                  ),
                ),
              );
            }),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnymeXText(
                  PlayerUtils.formatDuration(position),
                  variant: TextVariant.bold,
                  size: 13,
                  color: cs.onSurface,
                ),
                if (chapterTitle != null && chapterTitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  AnymeXText(
                    chapterTitle!,
                    variant: TextVariant.regular,
                    size: 11,
                    color: cs.primary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
