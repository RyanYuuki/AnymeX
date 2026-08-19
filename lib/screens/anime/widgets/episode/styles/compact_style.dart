import 'dart:ui';
import 'package:anymex/database/isar_models/episode.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/utils/string_extensions.dart';
import 'package:anymex/widgets/animation/animations.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:flutter/material.dart';

class CompactEpisodeWidget extends StatelessWidget {
  final Episode episode;
  final bool isSelected;
  final bool isWatched;
  final double progress;
  final Media? media;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const CompactEpisodeWidget({
    super.key,
    required this.episode,
    required this.isSelected,
    required this.isWatched,
    required this.progress,
    this.media,
    this.onTap,
    this.onLongPress,
  });

  String get episodeNumber =>
      episode.number.contains('.0') ? episode.number.toInt().toString() : episode.number.toString();

  String get episodeTitle {
    final raw = episode.title?.trim();
    final isGeneric = raw == null ||
        raw.isEmpty ||
        raw.toLowerCase() == 'movie' ||
        raw.toLowerCase() == 'full movie';
    if (isGeneric && media?.title != null && media!.title.trim().isNotEmpty) {
      return media!.title.trim();
    }
    return (raw != null && raw.isNotEmpty) ? raw : 'Episode $episodeNumber';
  }

  String get _imageUrl {
    final fallback = media != null ? ((media!.cover?.isNotEmpty ?? false) ? media!.cover! : media!.poster) : '';
    return (episode.thumbnail?.isNotEmpty ?? false) ? episode.thumbnail! : fallback;
  }

  Color _getBackgroundColor(BuildContext context, bool isFiller) {
    final theme = Theme.of(context);
    if (isSelected) {
      return theme.colorScheme.primary.opaque(0.4, iReallyMeanIt: true);
    } else if (isFiller) {
      return Colors.orange.withOpacity(0.15);
    } else {
      return theme.colorScheme.secondaryContainer.opaque(0.4);
    }
  }

  Widget _buildImageSection(
    BuildContext context,
    String episodeNumber,
    String imageUrl,
    String? fallbackUrl,
  ) {
    final theme = Theme.of(context);
    const imageWidth = 170.0;
    final hasProgress = progress > 0.0 && progress <= 1.0;

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AnymeXImage(
            imageUrl: imageUrl,
            width: imageWidth,
            height: double.infinity,
            radius: 0,
            errorImage: fallbackUrl,
          ),
        ),
        if (hasProgress) ...[
          Positioned(
            bottom: 0,
            left: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              height: 4,
              width: imageWidth * progress,
            ),
          ),
          Positioned(
            top: 5,
            right: 5,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: theme.colorScheme.primary,
              ),
              child: Icon(
                Icons.remove_red_eye,
                color: theme.colorScheme.onPrimary,
                size: 16,
              ),
            ),
          ),
        ],
        Positioned(
          bottom: 8,
          left: 8,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.black.opaque(0.2),
                  border: Border.all(
                    width: 2,
                    color: theme.colorScheme.primary,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.opaque(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: AnymeXText(
                  "EP $episodeNumber",
                  variant: TextVariant.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFiller = episode.filler ?? false;
    final fallbackUrl = media != null ? ((media!.cover?.isNotEmpty ?? false) ? media!.cover! : media!.poster) : '';

    return StaggeredAnimatedItemWrapper(
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Opacity(
          opacity: isWatched ? 0.5 : 1.0,
          child: Container(
            clipBehavior: Clip.antiAlias,
            height: 100,
            decoration: BoxDecoration(
              color: _getBackgroundColor(context, isFiller),
              borderRadius: BorderRadius.circular(12),
              border: isFiller ? Border.all(color: Colors.orange.withOpacity(0.3)) : null,
            ),
            child: Row(
              children: [
                _buildImageSection(context, episodeNumber, _imageUrl, fallbackUrl),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isFiller)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 2.0),
                          child: AnymeXText(
                            "[Filler]",
                            size: 10,
                            color: Colors.orange,
                            variant: TextVariant.bold,
                          ),
                        ),
                      AnymeXText(
                        episodeTitle,
                        variant: TextVariant.bold,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        isMarquee: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget buildCompactEpisodeStyle(
  BuildContext context,
  Episode episode,
  bool isSelected,
  bool isWatched,
  double progress,
  Media? media,
  VoidCallback? onTap,
  VoidCallback? onLongPress,
) {
  return CompactEpisodeWidget(
    episode: episode,
    isSelected: isSelected,
    isWatched: isWatched,
    progress: progress,
    media: media,
    onTap: onTap,
    onLongPress: onLongPress,
  );
}
