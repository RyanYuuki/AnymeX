import 'package:anymex/database/isar_models/chapter.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:flutter/material.dart';

class ReaderChapterTransition extends StatelessWidget {
  const ReaderChapterTransition({
    super.key,
    required this.isNext,
    required this.currentChapter,
    required this.targetChapter,
  });

  final bool isNext;
  final Chapter currentChapter;
  final Chapter? targetChapter;

  @override
  Widget build(BuildContext context) {
    final topChapter = isNext ? currentChapter : targetChapter;
    final bottomChapter = isNext ? targetChapter : currentChapter;
    final topLabel = isNext ? 'Finished' : 'Previous Chapter';
    final bottomLabel = isNext ? 'Next Chapter' : 'Current Chapter';
    final fallback =
        isNext ? 'No next chapter' : 'No previous chapter';

    final gap = _calculateGap(currentChapter, targetChapter, isNext);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (topChapter != null)
                _ChapterEntry(label: topLabel, chapter: topChapter)
              else
                _NoChapterCard(text: fallback),

              const SizedBox(height: 24),
              
              if (gap > 0) ...[
                _GapWarningCard(gap: gap),
                const SizedBox(height: 24),
              ],
              
              if (bottomChapter != null)
                _ChapterEntry(label: bottomLabel, chapter: bottomChapter)
              else
                _NoChapterCard(text: fallback),
            ],
          ),
        ),
      ),
    );
  }
  
  static int _calculateGap(
      Chapter from, Chapter? to, bool isNext) {
    if (to == null) return 0;
    final fromNum = from.number;
    final toNum = to.number;
    if (fromNum == null || toNum == null) return 0;
    final gap = isNext
        ? (toNum - fromNum - 1).toInt()
        : (fromNum - toNum - 1).toInt();
    return gap > 0 ? gap : 0;
  }
}

class _ChapterEntry extends StatelessWidget {
  const _ChapterEntry({required this.label, required this.chapter});

  final String label;
  final Chapter chapter;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          chapter.title ?? 'Chapter ${chapter.number}',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 20,
              ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        if (chapter.scanlator?.isNotEmpty ?? false) ...[
          const SizedBox(height: 2),
          Text(
            chapter.scanlator!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.colors.onSurface.withOpacity(0.6),
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

class _NoChapterCard extends StatelessWidget {
  const _NoChapterCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.colors.outline.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded,
                color: context.colors.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}

class _GapWarningCard extends StatelessWidget {
  const _GapWarningCard({required this.gap});

  final int gap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.colors.outline.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: context.colors.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$gap missing chapter${gap == 1 ? '' : 's'} between these chapters',
                style: TextStyle(color: context.colors.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
