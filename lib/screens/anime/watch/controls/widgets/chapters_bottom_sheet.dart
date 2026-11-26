import 'package:anymex/l10n/l10n_extension.dart';
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/screens/anime/watch/controller/player_utils.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChaptersBottomSheet extends StatelessWidget {
  const ChaptersBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PlayerController>();
    final theme = context.theme;
    final cs = theme.colorScheme;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AnymeXText(
                  context.l10n.chaptersTimestamps,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: Obx(() {
              final chaptersList = controller.chapters.toList();
              final skipList = controller.skipSegments.toList();

              if (chaptersList.isEmpty && skipList.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: AnymeXText(
                      context.l10n.noChaptersOrTimestampsDetected,
                      color: cs.onSurfaceVariant,
                      variant: TextVariant.regular,
                      size: 14,
                    ),
                  ),
                );
              }

              final currentMs = controller.currentPosition.value.inMilliseconds;

              return ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  if (chaptersList.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: AnymeXText(
                        context.l10n.containerChapters,
                        color: cs.primary,
                        variant: TextVariant.bold,
                        size: 12,
                      ),
                    ),
                    ...chaptersList.asMap().entries.map((entry) {
                      final ch = entry.value;
                      final startMs = (ch.startSeconds * 1000).round();
                      final isCurrent = currentMs >= startMs &&
                          (entry.key + 1 >= chaptersList.length ||
                              currentMs < (chaptersList[entry.key + 1].startSeconds * 1000).round());

                      return ListTile(
                        leading: Icon(
                          isCurrent ? Icons.play_arrow_rounded : Icons.bookmark_border_rounded,
                          color: isCurrent ? cs.primary : cs.onSurfaceVariant,
                        ),
                        title: AnymeXText(
                          ch.title,
                          variant: isCurrent ? TextVariant.bold : TextVariant.regular,
                          color: isCurrent ? cs.primary : cs.onSurface,
                        ),
                        trailing: AnymeXText(
                          PlayerUtils.formatDuration(ch.startDuration),
                          color: cs.onSurfaceVariant,
                          size: 13,
                        ),
                        onTap: () {
                          controller.seekTo(ch.startDuration);
                          Navigator.pop(context);
                        },
                      );
                    }),
                  ],
                  if (skipList.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: AnymeXText(
                        context.l10n.skipSegments,
                        color: cs.primary,
                        variant: TextVariant.bold,
                        size: 12,
                      ),
                    ),
                    ...skipList.map((seg) {
                      final isCurrent = seg.covers(currentMs / 1000.0);
                      return ListTile(
                        leading: Icon(
                          Icons.fast_forward_rounded,
                          color: isCurrent ? cs.primary : cs.onSurfaceVariant,
                        ),
                        title: AnymeXText(
                          seg.title,
                          variant: isCurrent ? TextVariant.bold : TextVariant.regular,
                          color: isCurrent ? cs.primary : cs.onSurface,
                        ),
                        subtitle: seg.source != null
                            ? AnymeXText(
                                seg.source!,
                                color: cs.onSurfaceVariant,
                                size: 11,
                              )
                            : null,
                        trailing: AnymeXText(
                          '${PlayerUtils.formatDuration(seg.startDuration)} - ${PlayerUtils.formatDuration(seg.endDuration)}',
                          color: cs.onSurfaceVariant,
                          size: 13,
                        ),
                        onTap: () {
                          controller.seekTo(seg.startDuration);
                          Navigator.pop(context);
                        },
                      );
                    }),
                  ],
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
