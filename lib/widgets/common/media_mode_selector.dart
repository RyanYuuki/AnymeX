import 'package:anymex/controllers/media_mode_controller.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:anymex/database/isar_models/episode.dart';
import 'package:anymex/models/Media/media.dart' as app_media;
import 'package:anymex/screens/anime/widgets/episode_list_builder.dart';
import 'package:anymex/screens/manga/reading_page.dart';
import 'package:anymex/screens/novel/reader/novel_reader.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MediaModeSelector extends StatelessWidget {
  final bool isVertical;
  final bool showPlayButton;
  final bool isLibraryOrHistory;

  const MediaModeSelector({
    super.key,
    this.isVertical = false,
    this.showPlayButton = false,
    this.isLibraryOrHistory = false,
  });

  static double getBottomOffset(BuildContext context) {
    final settings = Get.find<Settings>();
    final height = settings.bottomNavBarMargin;
    return height - 30;
  }

  IconData _getIconForMode(ItemType mode) {
    switch (mode) {
      case ItemType.anime:
        return Icons.play_arrow_rounded;
      case ItemType.manga:
        return Icons.menu_book_rounded;
      case ItemType.novel:
        return Icons.auto_stories_rounded;
    }
  }

  void _autoPlayLastMedia(
      BuildContext context, ItemType mode, List<OfflineMedia> items) async {
    if (items.isEmpty) return;
    final item = items.first;
    if (mode == ItemType.anime) {
      if (item.currentEpisode != null) {
        final epList = item.episodes ?? <Episode>[];
        final activeEpList =
            epList.isNotEmpty ? epList : [item.currentEpisode!];
        await EpisodeListBuilder.showServerSheet(
          context,
          episode: item.currentEpisode!,
          episodeList: activeEpList,
          anilistData: app_media.Media.fromOfflineMedia(item, ItemType.anime),
        );
      }
    } else if (mode == ItemType.manga) {
      if (item.currentChapter != null) {
        final targetScanlator = item.currentChapter!.scanlator;
        final allChapters = item.chapters ?? [item.currentChapter!];
        final filteredChapters = (targetScanlator != null &&
                targetScanlator.isNotEmpty)
            ? allChapters.where((c) => c.scanlator == targetScanlator).toList()
            : allChapters;

        navigate(() => ReadingPage(
              anilistData:
                  app_media.Media.fromOfflineMedia(item, ItemType.manga),
              chapterList: filteredChapters,
              currentChapter: item.currentChapter!,
              shouldTrack: false,
            ));
      }
    } else {
      if (item.currentChapter != null) {
        final sourceController = Get.find<SourceController>();
        final sourceName = item.currentChapter?.sourceName ?? '';
        final extensions = sourceController.installedNovelExtensions;
        if (extensions.isNotEmpty) {
          final activeSource = extensions.firstWhere(
            (s) => s.name == sourceName,
            orElse: () => extensions.first,
          );
          navigate(() => NovelReader(
                chapter: item.currentChapter!,
                media: app_media.Media.fromOfflineMedia(item, ItemType.novel),
                chapters: item.chapters ?? [item.currentChapter!],
                source: activeSource,
              ));
        } else {
          snackBar('No novel extensions installed to read this novel.');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.put(MediaModeController());
    final isSimkl =
        Get.find<ServiceHandler>().serviceType.value == ServicesType.simkl;

    if (isSimkl && isLibraryOrHistory) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (controller.mode != ItemType.anime) {
          controller.mode = ItemType.anime;
        }
      });
      return const SizedBox.shrink();
    }

    return SafeArea(
      child: Obx(() {
        final activeMode = controller.mode;
        final items = controller.currentHistory;
        final hasItems = items.isNotEmpty;

        final containerDecoration = BoxDecoration(
          color: theme.colorScheme.surfaceContainer.opaque(0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.onSurface.opaque(0.12, iReallyMeanIt: true),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.opaque(0.12, iReallyMeanIt: true),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 6),
            ),
          ],
        );

        final showContinue = showPlayButton && hasItems;

        if (isSimkl) {
          const options = [
            MapEntry('Movie', ItemType.anime),
            MapEntry('Series', ItemType.manga),
          ];
          final int itemCount = options.length;

          if (isVertical) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: 86,
              decoration: containerDecoration.copyWith(
                  borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showContinue) ...[
                      _buildContinueButtonVertical(
                          context, controller, activeMode, items),
                      const SizedBox(height: 6),
                    ],
                    ...options.map((opt) {
                      final isSelected = activeMode == opt.value;
                      return GestureDetector(
                        onTap: () => controller.mode = opt.value,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          curve: const Cubic(0.34, 1.56, 0.64, 1.0),
                          height: 34.0,
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _buildPillItemContent(theme, opt.key, opt.value, isSelected),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          }

          const double selectedFlex = 2.4;
          const double unselectedFlex = 1.0;
          final double totalFlex = selectedFlex + unselectedFlex * (itemCount - 1);

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: 260,
            decoration: containerDecoration,
            padding: const EdgeInsets.all(4),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showContinue) ...[
                    _buildContinueButton(context, controller, activeMode, items),
                    const SizedBox(height: 4),
                  ],
                  SizedBox(
                    height: 36,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final totalWidth = constraints.maxWidth;
                        return Row(
                          children: options.map((opt) {
                            final isSelected = activeMode == opt.value;
                            final flex = isSelected ? selectedFlex : unselectedFlex;
                            final targetWidth = totalWidth * flex / totalFlex;

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 350),
                              curve: const Cubic(0.34, 1.56, 0.64, 1.0),
                              width: targetWidth,
                              height: double.infinity,
                              decoration: BoxDecoration(
                                color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: GestureDetector(
                                onTap: () => controller.mode = opt.value,
                                behavior: HitTestBehavior.opaque,
                                child: _buildPillItemContent(theme, opt.key, opt.value, isSelected),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        const options = [
          MapEntry('Anime', ItemType.anime),
          MapEntry('Manga', ItemType.manga),
          MapEntry('Novel', ItemType.novel),
        ];
        final int itemCount = options.length;

        if (isVertical) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: 86,
            decoration: containerDecoration.copyWith(
                borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showContinue) ...[
                    _buildContinueButtonVertical(
                        context, controller, activeMode, items),
                    const SizedBox(height: 6),
                  ],
                  ...options.map((opt) {
                    final isSelected = activeMode == opt.value;
                    return GestureDetector(
                      onTap: () => controller.mode = opt.value,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: const Cubic(0.34, 1.56, 0.64, 1.0),
                        height: 34.0,
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _buildPillItemContent(theme, opt.key, opt.value, isSelected),
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        }

        const double selectedFlex = 2.4;
        const double unselectedFlex = 1.0;
        final double totalFlex = selectedFlex + unselectedFlex * (itemCount - 1);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: 260,
          decoration: containerDecoration,
          padding: const EdgeInsets.all(4),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showContinue) ...[
                  _buildContinueButton(context, controller, activeMode, items),
                  const SizedBox(height: 4),
                ],
                SizedBox(
                  height: 36,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final totalWidth = constraints.maxWidth;
                      return Row(
                        children: options.map((opt) {
                          final isSelected = activeMode == opt.value;
                          final flex = isSelected ? selectedFlex : unselectedFlex;
                          final targetWidth = totalWidth * flex / totalFlex;

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            curve: const Cubic(0.34, 1.56, 0.64, 1.0),
                            width: targetWidth,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: GestureDetector(
                              onTap: () => controller.mode = opt.value,
                              behavior: HitTestBehavior.opaque,
                              child: _buildPillItemContent(theme, opt.key, opt.value, isSelected),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPillItemContent(ThemeData theme, String label, ItemType type, bool isSelected) {
    IconData icon;
    switch (type) {
      case ItemType.anime:
        icon = Icons.play_arrow_rounded;
        break;
      case ItemType.manga:
        icon = Icons.menu_book_rounded;
        break;
      case ItemType.novel:
        icon = Icons.auto_stories_rounded;
        break;
    }

    final iconColor = isSelected
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface.withOpacity(0.6);

    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 16,
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 350),
            curve: const Cubic(0.34, 1.56, 0.64, 1.0),
            child: isSelected
                ? Row(
                    children: [
                      const SizedBox(width: 4),
                      Text(
                        label,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton(
      BuildContext context,
      MediaModeController controller,
      ItemType activeMode,
      List<OfflineMedia> items) {
    final theme = Theme.of(context);
    final icon = _getIconForMode(activeMode);
    final String text =
        activeMode == ItemType.anime ? 'Continue Watching' : 'Continue Reading';

    return GestureDetector(
      onTap: () => _autoPlayLastMedia(context, activeMode, items),
      child: Container(
        height: 34,
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: theme.colorScheme.onPrimary,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButtonVertical(
      BuildContext context,
      MediaModeController controller,
      ItemType activeMode,
      List<OfflineMedia> items) {
    final theme = Theme.of(context);
    final icon = _getIconForMode(activeMode);

    return GestureDetector(
      onTap: () => _autoPlayLastMedia(context, activeMode, items),
      child: Container(
        height: 34,
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: theme.colorScheme.onPrimary,
          size: 16,
        ),
      ),
    );
  }
}
