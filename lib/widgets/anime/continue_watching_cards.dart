import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/screens/library/widgets/history_model.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/custom_widgets/custom_expansion_tile.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/header.dart';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:flutter/material.dart';

class ContinueWatchingCard extends StatelessWidget {
  final HistoryModel media;

  const ContinueWatchingCard({super.key, required this.media});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;

    return AnymexCard(
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: colorScheme.outline.opaque(0.1, iReallyMeanIt: true),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12.multiplyRadius()),
      ),
      color: colorScheme.surfaceContainer.opaque(0.4),
      child: AnymexOnTap(
        onTap: media.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12.multiplyRadius()),
                      topRight: Radius.circular(12.multiplyRadius()),
                    ),
                    child: AnymeXImage(
                      imageUrl:
                          media.cover.isEmpty ? media.poster : media.cover,
                      width: double.infinity,
                      radius: 0,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12.multiplyRadius()),
                        topRight: Radius.circular(12.multiplyRadius()),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.opaque(0.2, iReallyMeanIt: true),
                          Colors.black.opaque(0.7, iReallyMeanIt: true),
                        ],
                        stops: const [0.6, 0.8, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.colors.primary
                          .opaque(0.8, iReallyMeanIt: true),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white12, width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timelapse_rounded,
                            size: 10, color: context.colors.onPrimary),
                        const SizedBox(width: 4),
                        AnymexText(
                            text: media.date ?? '',
                            size: 10,
                            variant: TextVariant.bold,
                            color: context.colors.onPrimary),
                      ],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.colors.primary
                            .opaque(0.8, iReallyMeanIt: true),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: context.colors.onPrimary,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 10,
                  right: 10,
                  child: Row(
                    children: [
                      Container(
                        constraints: const BoxConstraints(maxWidth: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.opaque(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: AnymexText(
                          text: media.formattedEpisodeTitle ?? '',
                          size: 11,
                          maxLines: 1,
                          variant: TextVariant.bold,
                          color: colorScheme.onPrimary,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    year2023: false,
                    value: media.calculatedProgress,
                    backgroundColor: Colors.white.opaque(0.2),
                    color: colorScheme.primary,
                    minHeight: 3,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnymexText(
                          text: media.progressTitle ?? media.title!,
                          size: 13,
                          maxLines: 1,
                          variant: TextVariant.bold,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (media.title != null &&
                            media.title != media.progressTitle)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: AnymexText(
                              text: media.title!,
                              size: 11,
                              maxLines: 1,
                              variant: TextVariant.regular,
                              color: colorScheme.onSurface.opaque(0.6),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: AnymexText(
                      text: media.progressText!,
                      size: 11,
                      color: colorScheme.primary,
                      variant: TextVariant.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
