import 'package:anymex/models/Offline/Hive/episode.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/header.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

enum EpisodeLayoutType {
  compact,
  detailed,
}

class BetterEpisode extends StatelessWidget {
  final Episode episode;
  final bool isSelected;
  final EpisodeLayoutType layoutType;
  final String? fallbackImageUrl;
  final List<Episode>? offlineEpisodes;
  final VoidCallback? onTap;

  const BetterEpisode({
    super.key,
    required this.episode,
    this.isSelected = false,
    this.layoutType = EpisodeLayoutType.compact,
    this.fallbackImageUrl,
    this.offlineEpisodes,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final episodeProgress = _calculateProgress();
    final isFiller = episode.filler ?? false;
    final hasProgress = episodeProgress > 0.0 && episodeProgress <= 1.0;

    return GestureDetector(
      onTap: onTap,
      child: layoutType == EpisodeLayoutType.compact
          ? _buildCompactLayout(context, episodeProgress, isFiller, hasProgress)
          : _buildDetailedLayout(
              context, episodeProgress, isFiller, hasProgress),
    );
  }

  double _calculateProgress() {
    if (offlineEpisodes == null) return 0.0;

    final savedEP = offlineEpisodes!.cast<Episode?>().firstWhere(
          (e) => e?.number == episode.number,
          orElse: () => null,
        );

    if (savedEP?.timeStampInMilliseconds != null &&
        savedEP?.durationInMilliseconds != null &&
        savedEP!.durationInMilliseconds! > 0) {
      return savedEP.timeStampInMilliseconds! / savedEP.durationInMilliseconds!;
    }

    return 0.0;
  }

  Color _getBackgroundColor(BuildContext context, bool isFiller) {
    final theme = Theme.of(context);

    if (isSelected) {
      return theme.colorScheme.primary.withOpacity(0.4);
    } else if (isFiller) {
      return layoutType == EpisodeLayoutType.compact
          ? Colors.orange
          : Colors.orangeAccent.withAlpha(120);
    } else {
      return theme.colorScheme.secondaryContainer.withOpacity(
        layoutType == EpisodeLayoutType.compact ? 0.4 : 0.5,
      );
    }
  }

  String get _imageUrl {
    return episode.thumbnail ?? fallbackImageUrl ?? '';
  }

  Widget _buildCompactLayout(
    BuildContext context,
    double progress,
    bool isFiller,
    bool hasProgress,
  ) {
    return Container(
      clipBehavior: Clip.antiAlias,
      height: 100,
      decoration: BoxDecoration(
        color: _getBackgroundColor(context, isFiller),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildImageSection(context, progress, hasProgress, isCompact: true),
          const SizedBox(width: 10),
          Expanded(
            child: AnymexText(
              text: episode.title ?? '?',
              variant: TextVariant.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedLayout(
    BuildContext context,
    double progress,
    bool isFiller,
    bool hasProgress,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _getBackgroundColor(context, isFiller),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 170,
                height: 100,
                child: _buildImageSection(context, progress, hasProgress),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnymexText(
                  text: episode.title ?? 'Unknown Title',
                  variant: TextVariant.bold,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildDescription(context),
        ],
      ),
    );
  }

  Widget _buildImageSection(
    BuildContext context,
    double progress,
    bool hasProgress, {
    bool isCompact = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const imageWidth = 170.0;

        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(isCompact ? 12 : 12),
              child: _OptimizedNetworkImage(
                imageUrl: _imageUrl,
                width: imageWidth,
                height: isCompact ? double.infinity : 100,
                fallbackUrl: fallbackImageUrl,
              ),
            ),
            if (hasProgress) ...[
              _buildProgressIndicator(context, progress, imageWidth, isCompact),
              _buildWatchedIcon(context),
            ],
            _buildEpisodeNumberBadge(context),
          ],
        );
      },
    );
  }

  Widget _buildProgressIndicator(
    BuildContext context,
    double progress,
    double imageWidth,
    bool isCompact,
  ) {
    return Positioned(
      bottom: 0,
      left: 0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        height: isCompact ? 4 : 2,
        width: imageWidth * progress,
      ),
    );
  }

  Widget _buildWatchedIcon(BuildContext context) {
    return Positioned(
      top: 5,
      right: 5,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.primary,
        ),
        child: Icon(
          Icons.remove_red_eye,
          color: Theme.of(context).colorScheme.onPrimary,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildEpisodeNumberBadge(BuildContext context) {
    return Positioned(
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
              color: Colors.black.withOpacity(0.2),
              border: Border.all(
                width: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: AnymexText(
              text: "EP ${episode.number}",
              variant: TextVariant.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDescription(BuildContext context) {
    final description = episode.desc;
    final displayText = (description?.isEmpty ?? true)
        ? 'No Description Available'
        : description!;

    return AnymexText(
      text: displayText,
      variant: TextVariant.regular,
      maxLines: 3,
      fontStyle: FontStyle.italic,
      color: Theme.of(context).colorScheme.inverseSurface.withOpacity(0.90),
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _OptimizedNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;
  final String? fallbackUrl;

  const _OptimizedNetworkImage({
    required this.imageUrl,
    required this.width,
    required this.height,
    this.fallbackUrl,
  });

  @override
  Widget build(BuildContext context) {
    return NetworkSizedImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      radius: 0,
      errorImage: fallbackUrl,
    );
  }
}
