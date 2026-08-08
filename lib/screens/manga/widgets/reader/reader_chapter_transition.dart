import 'package:anymex/database/isar_models/chapter.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:flutter/material.dart';

class ReaderChapterTransition extends StatelessWidget {
  const ReaderChapterTransition({
    super.key,
    required this.isNext,
    required this.currentChapter,
    required this.targetChapter,
    required this.posterUrl,
    this.isLoading = false,
  });

  final bool isNext;
  final Chapter currentChapter;
  final Chapter? targetChapter;
  final String posterUrl;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final topChapter = isNext ? currentChapter : targetChapter;
    final bottomChapter = isNext ? targetChapter : currentChapter;
    final topLabel = isNext ? 'Finished' : 'Previous Chapter';
    final bottomLabel = isNext ? 'Next Chapter' : 'Current Chapter';
    final fallback = isNext ? 'No next chapter' : 'No previous chapter';
    final gap = _calculateGap(currentChapter, targetChapter, isNext);
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(0),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (posterUrl.isNotEmpty && posterUrl != '?')
            AnymeXImage(
              imageUrl: posterUrl,
              width: double.infinity,
              height: double.infinity,
              radius: 0,
              fit: BoxFit.cover,
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.78),
                  scheme.surface.withOpacity(0.86),
                  Colors.black.withOpacity(0.82),
                ],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.08),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: scheme.surface.withOpacity(0.72),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.14),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 26,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [

                        topChapter != null
                            ? _buildChapterCard(
                                context,
                                label: topLabel,
                                chapter: topChapter,
                                isTarget: !isNext,
                                icon: !isNext
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.check_rounded,
                              )
                            : _buildNoChapterCard(context, fallback),
                        const SizedBox(height: 12),
                        _buildDirectionDivider(context),
                        const SizedBox(height: 12),
                        if (gap > 0) ...[
                          _buildGapWarning(context, gap),
                          const SizedBox(height: 12),
                        ],
                        bottomChapter != null
                            ? _buildChapterCard(
                                context,
                                label: bottomLabel,
                                chapter: bottomChapter,
                                isTarget: isNext,
                                icon: isNext
                                    ? Icons.keyboard_arrow_down_rounded
                                    : Icons.play_arrow_rounded,
                              )
                            : _buildNoChapterCard(context, fallback),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterCard(
    BuildContext context, {
    required String label,
    required Chapter chapter,
    required bool isTarget,
    required IconData icon,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final title = chapter.title?.trim().isNotEmpty == true
        ? chapter.title!.trim()
        : 'Chapter ${chapter.number ?? '?'}';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isTarget
            ? scheme.primary.withOpacity(0.16)
            : scheme.onSurface.withOpacity(0.06),
        border: Border.all(
          color: isTarget
              ? scheme.primary.withOpacity(0.5)
              : Colors.white.withOpacity(0.12),
          width: isTarget ? 1.3 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isTarget
                  ? scheme.primary.withOpacity(0.14)
                  : scheme.onSurface.withOpacity(0.06),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isTarget ? scheme.primary : scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnymexText.semiBold(
                  text: label.toUpperCase(),
                  size: 11,
                  color: isTarget ? scheme.primary : scheme.onSurfaceVariant,
                  maxLines: 1,
                ),
                const SizedBox(height: 6),
                AnymexText.bold(
                  text: title,
                  size: 18,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (chapter.scanlator?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 4),
                  AnymexText(
                    text: chapter.scanlator!,
                    size: 12,
                    color: scheme.onSurface.withOpacity(0.58),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (isTarget && isLoading) ...[
            const SizedBox(width: 14),
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: scheme.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoChapterCard(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: context.colors.outline.withOpacity(0.08),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: context.colors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AnymexText(
              text: text,
              color: context.colors.onSurface.withOpacity(0.82),
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGapWarning(BuildContext context, int gap) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: context.colors.error.withOpacity(0.08),
        border: Border.all(color: context.colors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: context.colors.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AnymexText.semiBold(
              text: '$gap missing chapter${gap == 1 ? '' : 's'} between these',
              color: context.colors.error,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionDivider(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Icon(
        isNext
            ? Icons.keyboard_double_arrow_down_rounded
            : Icons.keyboard_double_arrow_up_rounded,
        size: 22,
        color: scheme.onSurface.withOpacity(0.25),
      ),
    );
  }

  static int _calculateGap(Chapter from, Chapter? to, bool isNext) {
    if (to == null) return 0;
    final fromNum = from.number;
    final toNum = to.number;
    if (fromNum == null || toNum == null) return 0;
    final gap =
        isNext ? (toNum - fromNum - 1).toInt() : (fromNum - toNum - 1).toInt();
    return gap > 0 ? gap : 0;
  }
}
