// ignore_for_file: deprecated_member_use

import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/screens/library/widgets/history_model.dart';
import 'package:anymex/widgets/custom_widgets/custom_expansion_tile.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/header.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:blur/blur.dart';
import 'package:flutter/material.dart';

class UnifiedHistoryCard extends StatelessWidget {
  final HistoryModel media;

  const UnifiedHistoryCard({super.key, required this.media});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final gradientColors = [
      Theme.of(context).colorScheme.surface.withOpacity(0.3),
      Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      Theme.of(context).colorScheme.primaryContainer.withOpacity(0.8),
    ];

    return AnymexCard(
      shape: RoundedRectangleBorder(
          side: BorderSide(
            color: colorScheme.primary.withOpacity(0.3),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16)),
      color: Theme.of(context).colorScheme.secondaryContainer.withAlpha(120),
      child: AnymexOnTap(
        onTap: media.onTap,
        child: SizedBox(
          height: getResponsiveSize(context, mobileSize: 140, desktopSize: 180),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(children: [
              Positioned.fill(
                child: NetworkSizedImage(
                  imageUrl: media.cover,
                  radius: 0,
                  width: double.infinity,
                ),
              ),
              Positioned.fill(
                child: Blur(
                  blur: 4,
                  blurColor: Colors.transparent,
                  child: Container(),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: gradientColors)),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: getResponsiveSize(context,
                        mobileSize: 100, desktopSize: 130),
                    height: double.infinity,
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16.multiplyRadius()),
                        bottomLeft: Radius.circular(16.multiplyRadius()),
                      ),
                      child: NetworkSizedImage(
                        imageUrl: media.poster,
                        width: double.infinity,
                        height: double.infinity,
                        radius: 0,
                      ),
                    ),
                  ),
                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(8.multiplyRadius()),
                              color: colorScheme.primary,
                            ),
                            child: AnymexText(
                              text: media.formattedEpisodeTitle.toString(),
                              size: 12,
                              variant: TextVariant.bold,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Episode title
                          AnymexText(
                            text: media.progressTitle ?? media.title!,
                            size: 15,
                            maxLines: getResponsiveValue(context,
                                mobileValue: 1, desktopValue: 2),
                            variant: TextVariant.bold,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          if (media.title != null &&
                              media.title != media.progressTitle)
                            AnymexText(
                              text: media.title!,
                              size: 14,
                              maxLines: 1,
                              variant: TextVariant.regular,
                              color: colorScheme.onSurface.withOpacity(0.7),
                              overflow: TextOverflow.ellipsis,
                            ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  AnymexText(
                                    text: media.date!,
                                    size: 12,
                                    color:
                                        colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                  AnymexText(
                                    text: media.progressText ?? '??',
                                    size: 12,
                                    color: colorScheme.primary,
                                    variant: TextVariant.bold,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: media.calculatedProgress,
                                  backgroundColor: colorScheme.surfaceVariant,
                                  color: colorScheme.primary,
                                  minHeight: 5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class UnifiedHistoryCardV3 extends StatelessWidget {
  final HistoryModel media;

  const UnifiedHistoryCardV3({super.key, required this.media});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnymexCard(
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: colorScheme.primary.withOpacity(0.3),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(16.multiplyRadius()),
      ),
      color: colorScheme.secondaryContainer.withAlpha(120),
      child: AnymexOnTap(
        onTap: media.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.multiplyRadius()),
                topRight: Radius.circular(16.multiplyRadius()),
              ),
              child: NetworkSizedImage(
                imageUrl: media.cover.isEmpty ? media.poster : media.cover,
                width: double.infinity,
                height: 130,
                radius: 0,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(8.multiplyRadius()),
                          color: colorScheme.primary,
                        ),
                        child: AnymexText(
                          text: media.formattedEpisodeTitle ?? '',
                          size: 12,
                          variant: TextVariant.bold,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(8.multiplyRadius()),
                          color: colorScheme.surfaceVariant,
                        ),
                        child: AnymexText(
                          text: media.date!,
                          size: 12,
                          variant: TextVariant.regular,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AnymexText(
                    text: media.progressTitle ?? media.title!,
                    size: 15,
                    maxLines: 1,
                    variant: TextVariant.bold,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (media.title != null && media.title != media.progressTitle)
                    AnymexText(
                      text: media.title!,
                      size: 13,
                      maxLines: 1,
                      variant: TextVariant.regular,
                      color: colorScheme.onSurface.withOpacity(0.7),
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 3,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: media.calculatedProgress,
                            backgroundColor: colorScheme.surfaceVariant,
                            color: colorScheme.primary,
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnymexText(
                        text: media.progressText!,
                        size: 12,
                        color: colorScheme.primary,
                        variant: TextVariant.bold,
                      ),
                    ],
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

class UnifiedHistoryCardV2 extends StatelessWidget {
  final HistoryModel media;

  const UnifiedHistoryCardV2({super.key, required this.media});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnymexCard(
      shape: RoundedRectangleBorder(
          side: BorderSide(
            color: colorScheme.primary.withOpacity(0.3),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16)),
      color: Theme.of(context).colorScheme.secondaryContainer.withAlpha(120),
      child: AnymexOnTap(
        onTap: media.onTap,
        child: SizedBox(
          height: getResponsiveSize(context, mobileSize: 140, desktopSize: 180),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: getResponsiveSize(context,
                    mobileSize: 100, desktopSize: 130),
                height: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.multiplyRadius()),
                    bottomLeft: Radius.circular(16.multiplyRadius()),
                  ),
                  child: NetworkSizedImage(
                    imageUrl: media.poster,
                    width: double.infinity,
                    height: double.infinity,
                    radius: 0,
                  ),
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(8.multiplyRadius()),
                          color: colorScheme.primary,
                        ),
                        child: AnymexText(
                          text: media.formattedEpisodeTitle ?? 'Episode ??',
                          size: 12,
                          variant: TextVariant.bold,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AnymexText(
                        text: media.progressTitle ?? media.title!,
                        size: 15,
                        maxLines: getResponsiveValue(context,
                            mobileValue: 1, desktopValue: 2),
                        variant: TextVariant.bold,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (media.title != null &&
                          media.title != media.progressTitle)
                        AnymexText(
                          text: media.title!,
                          size: 14,
                          maxLines: 1,
                          variant: TextVariant.regular,
                          color: colorScheme.onSurface.withOpacity(0.7),
                          overflow: TextOverflow.ellipsis,
                        ),
                      const Spacer(),
                      // Progress indicator
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              AnymexText(
                                text: media.date!,
                                size: 12,
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                              AnymexText(
                                text: media.progressText!,
                                size: 12,
                                color: colorScheme.primary,
                                variant: TextVariant.bold,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: media.calculatedProgress,
                              backgroundColor: colorScheme.surfaceVariant,
                              color: colorScheme.primary,
                              minHeight: 5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
