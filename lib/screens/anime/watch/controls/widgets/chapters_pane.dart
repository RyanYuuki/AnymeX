import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/screens/anime/watch/controller/player_utils.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/episodes_pane.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/watch_settings_pane.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChaptersPane extends StatelessWidget {
  final PlayerController controller;

  const ChaptersPane({super.key, required this.controller});

  void _closePane() {
    controller.isChaptersPaneOpened.value = false;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Obx(() => EpisodeSidePane(
          isVisible: controller.isChaptersPaneOpened.value,
          onOverlayTap: _closePane,
          child: WatchSettingsPane(
            title: 'Chapters & Timestamps',
            onClose: _closePane,
            child: Obx(() {
              final chaptersList = controller.chapters.toList();
              final skipList = controller.skipSegments.toList();

              if (chaptersList.isEmpty && skipList.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: AnymeXText(
                      'No chapters or timestamps detected for this stream',
                      color: cs.onSurfaceVariant,
                      variant: TextVariant.regular,
                      size: 14,
                    ),
                  ),
                );
              }

              final currentMs = controller.currentPosition.value.inMilliseconds;

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  if (chaptersList.isNotEmpty) ...[
                    AnymeXSectionBuilder(
                      title: 'Container Chapters',
                      children: chaptersList.asMap().entries.map((entry) {
                        final ch = entry.value;
                        final startMs = (ch.startSeconds * 1000).round();
                        final isCurrent = currentMs >= startMs &&
                            (entry.key + 1 >= chaptersList.length ||
                                currentMs <
                                    (chaptersList[entry.key + 1].startSeconds *
                                            1000)
                                        .round());

                        return AnymeXTile(
                          icon: isCurrent
                              ? Icons.play_arrow_rounded
                              : Icons.bookmark_border_rounded,
                          iconColor:
                              isCurrent ? cs.primary : cs.onSurfaceVariant,
                          title: ch.title,
                          titleStyle: isCurrent
                              ? TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: cs.primary,
                                )
                              : null,
                          trailing: AnymeXText(
                            PlayerUtils.formatDuration(ch.startDuration),
                            color: isCurrent ? cs.primary : cs.onSurfaceVariant,
                            size: 12,
                          ),
                          showChevron: false,
                          onTap: () {
                            controller.seekTo(ch.startDuration);
                            _closePane();
                          },
                        );
                      }).toList(),
                    ),
                    if (skipList.isNotEmpty) const SizedBox(height: 16),
                  ],
                  if (skipList.isNotEmpty)
                    AnymeXSectionBuilder(
                      title: 'Skip Segments',
                      children: skipList.map((seg) {
                        final isCurrent = seg.covers(currentMs / 1000.0);
                        return AnymeXTile(
                          icon: Icons.fast_forward_rounded,
                          iconColor:
                              isCurrent ? cs.primary : cs.onSurfaceVariant,
                          title: seg.title,
                          subtitle: seg.source,
                          titleStyle: isCurrent
                              ? TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: cs.primary,
                                )
                              : null,
                          trailing: AnymeXText(
                            '${PlayerUtils.formatDuration(seg.startDuration)} - ${PlayerUtils.formatDuration(seg.endDuration)}',
                            color: isCurrent ? cs.primary : cs.onSurfaceVariant,
                            size: 12,
                          ),
                          showChevron: false,
                          onTap: () {
                            controller.seekTo(seg.startDuration);
                            _closePane();
                          },
                        );
                      }).toList(),
                    ),
                ],
              );
            }),
          ),
        ));
  }
}
