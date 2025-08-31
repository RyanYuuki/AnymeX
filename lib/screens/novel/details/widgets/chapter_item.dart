import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/models/Offline/Hive/chapter.dart';
import 'package:anymex/screens/novel/details/controller/details_controller.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/anymex_button.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChapterListItem extends StatelessWidget {
  final NovelDetailsController controller;
  final VoidCallback onTap;
  final Chapter chapter;

  const ChapterListItem({
    super.key,
    required this.onTap,
    required this.controller,
    required this.chapter,
  });

  @override
  Widget build(BuildContext context) {
    final anilistData = controller.media.value;
    final readChapter = controller.offlineMedia.value?.currentChapter;
    final offlineStorage = Get.find<OfflineStorageController>();

    final savedChaps =
        offlineStorage.getReadChapter(anilistData.id, chapter.number!);
    final currentChapterLink = readChapter?.link ?? '';
    final isSelected = chapter.link == currentChapterLink;
    final alreadyRead = chapter.number! < (readChapter?.number ?? 1) ||
        ((savedChaps?.pageNumber ?? 1) == (savedChaps?.totalPages ?? 100));

    return AnymexOnTap(
      onTap: onTap,
      child: Opacity(
        opacity: alreadyRead ? 0.5 : 1,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.secondary.withAlpha(100)
                : Theme.of(context)
                    .colorScheme
                    .secondaryContainer
                    .withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildChapterProgress(context, savedChaps ?? Chapter()),
              const SizedBox(width: 15),
              _buildChapterInfo(context, savedChaps),
              const Spacer(),
              _buildReadButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChapterProgress(BuildContext context, Chapter savedChap) {
    final totalPages = savedChap.totalPages ?? 1;
    final currentPage = savedChap.pageNumber ?? 0;
    final progress =
        totalPages > 0 ? (currentPage / totalPages).clamp(0.0, 1.0) : 0.0;
    final progressPercentage = (progress * 100).toInt();

    if (progressPercentage > 0) {
      return _buildReadChapter(context, savedChap);
    }

    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(16.multiplyRadius()),
        boxShadow: [glowingShadow(context)],
      ),
      child: AnymexText(
        text: chapter.number?.toStringAsFixed(0) ?? '',
        variant: TextVariant.bold,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildReadChapter(BuildContext context, Chapter chapter) {
    final totalPages = chapter.totalPages ?? 1;
    final currentPage = chapter.pageNumber ?? 0;
    final progress =
        totalPages > 0 ? (currentPage / totalPages).clamp(0.0, 1.0) : 0.0;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.multiplyRadius()),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
          SizedBox(
            width: 40,
            height: 40,
            child: AnymexProgressIndicator(
              value: progress,
              strokeWidth: 4,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterInfo(BuildContext context, Chapter? savedChaps) {
    final progressText = savedChaps?.pageNumber != null
        ? ' (${savedChaps?.pageNumber}/${savedChaps?.totalPages})'
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: getResponsiveSize(context,
              mobileSize: Get.width * 0.4, desktopSize: 200),
          child: AnymexText(
            text: '${chapter.title}$progressText',
            variant: TextVariant.semiBold,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 5),
        SizedBox(
          width: getResponsiveSize(context,
              mobileSize: Get.width * 0.4, desktopSize: 200),
          child: AnymexText(
            text: calcTime(chapter.releaseDate ?? '0'),
            color:
                Theme.of(context).colorScheme.inverseSurface.withOpacity(0.9),
            fontStyle: FontStyle.italic,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildReadButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(boxShadow: [glowingShadow(context)]),
      child: AnymexButton(
        onTap: onTap,
        radius: 12,
        width: 100,
        height: 40,
        color: Theme.of(context).colorScheme.primary,
        child: AnymexText(
          text: "Read",
          variant: TextVariant.semiBold,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }
}
