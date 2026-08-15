import 'package:anymex/database/isar_models/episode.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:flutter/material.dart';

Widget buildMinimalEpisodeStyle(
  BuildContext context,
  Episode episode,
  bool isSelected,
  bool isWatched,
  double progress,
  String? mediaTitle,
  List<Episode>? offlineEpisodes,
  VoidCallback? onTap,
  VoidCallback? onLongPress,
) {
  final colors = context.colors;
  final isFiller = episode.filler ?? false;
  final epNum = episode.number.contains('.0') ? episode.number.split('.').first : episode.number;
  final epTitle = (episode.title?.trim().isNotEmpty ?? false) ? episode.title!.trim() : 'Episode $epNum';

  return GestureDetector(
    onTap: onTap,
    onLongPress: onLongPress,
    child: Opacity(
      opacity: isWatched ? 0.5 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primaryContainer.opaque(0.4, iReallyMeanIt: true)
              : (isFiller
                  ? Colors.orange.withOpacity(0.12)
                  : colors.surfaceContainerHighest.opaque(0.35, iReallyMeanIt: true)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colors.primary.opaque(0.5, iReallyMeanIt: true)
                : (isFiller
                    ? Colors.orange.withOpacity(0.3)
                    : colors.onSurface.opaque(0.08, iReallyMeanIt: true)),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.primary
                    : colors.primaryContainer.opaque(0.3, iReallyMeanIt: true),
                borderRadius: BorderRadius.circular(8),
              ),
              child: AnymeXText(
                text: epNum,
                size: 13,
                variant: TextVariant.bold,
                color: isSelected ? colors.onPrimary : colors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnymeXText(
                    text: epTitle,
                    size: 13,
                    variant: TextVariant.semiBold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isFiller) ...[
                    const SizedBox(height: 2),
                    const AnymeXText(
                      text: 'FILLER',
                      size: 10,
                      variant: TextVariant.bold,
                      color: Colors.orange,
                    ),
                  ],
                ],
              ),
            ),
            if (progress > 0 && progress < 0.9) ...[
              const SizedBox(width: 10),
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 2.0,
                  backgroundColor: colors.primary.withOpacity(0.15),
                  color: colors.primary,
                ),
              ),
            ] else if (isWatched || progress >= 0.9) ...[
              const SizedBox(width: 10),
              Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: colors.primary.opaque(0.7, iReallyMeanIt: true),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
