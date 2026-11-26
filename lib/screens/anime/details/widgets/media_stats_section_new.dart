import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/anilist/anilist_data.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/animethemes/anime_theme.dart';
import 'package:anymex/models/mangaupdates/anime_adaptation.dart';
import 'package:anymex/models/mangaupdates/next_release.dart';
import 'package:anymex/models/mangaupdates/news_item.dart';
import 'package:anymex/screens/anime/details/controller/media_details_controller.dart';
import 'package:anymex/screens/anime/details/media_details_page.dart';
import 'package:anymex/screens/anime/studio_details_page.dart';
import 'package:anymex/screens/anime/themes/anime_theme_dialog.dart';
import 'package:anymex/screens/anime/themes/anime_theme_view.dart';
import 'package:anymex/screens/anime/widgets/watch_order_page.dart';
import 'package:anymex/screens/anime/widgets/social_section.dart';
import 'package:anymex/screens/news/news_page.dart';
import 'package:anymex/screens/search/search_view.dart';
import 'package:anymex/utils/anime_adaptation_util.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_textspan.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_linear_indicator.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:anymex/l10n/l10n_extension.dart';
import 'package:anymex/l10n/ui_labels.dart';

Widget buildMediaStatsSection(
    BuildContext context, MediaDetailsController controller) {
  final media = controller.media.value;
  final isDesktop = MediaQuery.sizeOf(context).width > 700;

  final progressCard = buildProgressContainer(context, controller);
  final countdownCard = (controller.isAnime && media.nextAiringEpisode != null)
      ? buildAiringCountdownCard(context, controller)
      : null;
  final statsCard = buildStatsGrid(context, media, controller: controller);
  final synopsisCard = _cleanHtml(media.description).isNotEmpty
      ? buildSynopsisCard(context, media)
      : null;
  final genresTagsCard = (media.genres.isNotEmpty || media.tags.isNotEmpty)
      ? buildGenresAndTagsCard(context, media)
      : null;
  final studiosCard = buildStudiosCard(context, media);
  final altTitlesCard = buildAlternativeTitles(context, media);
  final friendsCard =
      (media.friendsWatching != null && media.friendsWatching!.isNotEmpty)
          ? SocialSection(
              friends: media.friendsWatching!,
              totalEpisodes: media.totalEpisodes.isNotEmpty
                  ? media.totalEpisodes
                  : media.totalChapters,
            )
          : null;
  final seasonsCard = buildSeasonsSection(context, media);
  final extrasCard = controller.isAnime
      ? buildExtrasSection(context, media, controller)
      : null;

  if (isDesktop) {
    final leftCards = <Widget>[];
    final rightCards = <Widget>[];
    double leftHeight = 0;
    double rightHeight = 0;

    leftCards.add(progressCard);
    leftHeight += _estimateProgressHeight();

    if (countdownCard != null) {
      rightCards.add(countdownCard);
      rightHeight += _estimateCountdownHeight();
    }
    rightCards.add(statsCard);
    rightHeight += _estimateStatsHeight(media, controller);

    final dynamicPool = <MapEntry<Widget, double>>[
      if (synopsisCard != null)
        MapEntry(synopsisCard, _estimateSynopsisHeight(media.description)),
      if (studiosCard != null)
        MapEntry(studiosCard, _estimateStudiosHeight(media)),
      if (genresTagsCard != null)
        MapEntry(genresTagsCard, _estimateGenresTagsHeight(media)),
      if (altTitlesCard != null)
        MapEntry(altTitlesCard, _estimateAltTitlesHeight(media)),
      if (friendsCard != null) MapEntry(friendsCard, _estimateFriendsHeight()),
      if (seasonsCard != null) MapEntry(seasonsCard, _estimateSeasonsHeight()),
      if (extrasCard != null) MapEntry(extrasCard, _estimateExtrasHeight()),
    ];

    for (final item in dynamicPool) {
      if (leftHeight <= rightHeight) {
        leftCards.add(item.key);
        leftHeight += item.value + 12;
      } else {
        rightCards.add(item.key);
        rightHeight += item.value + 12;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _withSpacers(leftCards, 12),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _withSpacers(rightCards, 12),
            ),
          ),
        ],
      ),
    );
  }

  final mobileCards = <Widget>[
    progressCard,
    if (countdownCard != null) countdownCard,
    statsCard,
    if (synopsisCard != null) synopsisCard,
    if (genresTagsCard != null) genresTagsCard,
    if (studiosCard != null) studiosCard,
    if (altTitlesCard != null) altTitlesCard,
    if (friendsCard != null) friendsCard,
    if (seasonsCard != null) seasonsCard,
    if (extrasCard != null) extrasCard,
  ];

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _withSpacers(mobileCards, 12),
    ),
  );
}

String _formatCountry(String? code) {
  if (code == null || code.trim().isEmpty || code == '?') return '';
  switch (code.trim().toUpperCase()) {
    case 'JP':
      return uiLabel(Get.context!.l10n, 'Japan');
    case 'KR':
      return uiLabel(Get.context!.l10n, 'South Korea');
    case 'CN':
      return uiLabel(Get.context!.l10n, 'China');
    case 'TW':
      return uiLabel(Get.context!.l10n, 'Taiwan');
    case 'US':
      return uiLabel(Get.context!.l10n, 'United States');
    case 'GB':
    case 'UK':
      return uiLabel(Get.context!.l10n, 'United Kingdom');
    default:
      return code.trim();
  }
}

double _estimateProgressHeight() => 120.0;

double _estimateCountdownHeight() => 125.0;

double _estimateStatsHeight(Media media, MediaDetailsController? controller) {
  final isAnime = media.mediaType == ItemType.anime;
  final yearStr = media.seasonYear?.toString() ?? '';
  final seasonText = [
    if (media.season.isNotEmpty && media.season != '?')
      uiLabel(Get.context!.l10n, media.season),
    if (yearStr.isNotEmpty) yearStr,
  ].join(' ');
  final totalChaptersStr = (media.totalChapters ?? '').isNotEmpty &&
          media.totalChapters != '0' &&
          media.totalChapters != '?'
      ? media.totalChapters!
      : ((controller != null && controller.chapterList.isNotEmpty)
          ? controller.chapterList.length.toString()
          : '');
  final durationVal =
      (isAnime && media.duration.isNotEmpty && media.duration != '?')
          ? media.duration
          : '';
  final formatVal =
      media.format.isNotEmpty && media.format != '?' ? media.format : '';
  final sourceVal = media.sourceMaterial != null &&
          media.sourceMaterial!.isNotEmpty &&
          media.sourceMaterial != '?'
      ? media.sourceMaterial!
      : '';
  final epVal = (isAnime &&
          media.totalEpisodes.isNotEmpty &&
          media.totalEpisodes != '0' &&
          media.totalEpisodes != '?')
      ? media.totalEpisodes
      : '';
  final countryVal = _formatCountry(media.countryOfOrigin);

  int statCount = 0;
  if (durationVal.isNotEmpty) statCount++;
  if (seasonText.trim().isNotEmpty) statCount++;
  if (countryVal.isNotEmpty) statCount++;
  if (formatVal.isNotEmpty) statCount++;
  if (sourceVal.isNotEmpty) statCount++;
  if (epVal.isNotEmpty) statCount++;
  if (!isAnime && totalChaptersStr.isNotEmpty) statCount++;

  final statRows = (statCount + 1) ~/ 2;
  final validRankings = media.rankings.where((r) => r.rank > 0).toList();
  final rankRows = (validRankings.length + 1) ~/ 2;
  double height = 190.0 + (statRows * 66.0);
  if (validRankings.isNotEmpty) {
    height += 24.0 + (rankRows * 80.0);
  }
  return height;
}

double _estimateSynopsisHeight(String desc) {
  final clean = _cleanHtml(desc);
  if (clean.isEmpty) return 0.0;
  final lines = (clean.length / 55.0).clamp(3.0, 5.0);
  return 75.0 + (lines * 19.0);
}

double _estimateGenresTagsHeight(Media media) {
  if (media.genres.isEmpty && media.tags.isEmpty) return 0.0;
  double h = 32.0;
  if (media.genres.isNotEmpty) {
    final genreLines = (media.genres.length / 4.0).ceil();
    h += 24.0 + (genreLines * 36.0);
  }
  if (media.tags.isNotEmpty) {
    final tagLines = (media.tags.length / 5.0).ceil();
    h += 32.0 + (tagLines * 30.0);
  }
  return h;
}

double _estimateStudiosHeight(Media media) {
  final count = media.studios?.length ?? 0;
  if (count == 0) return 0.0;
  final lines = (count / 3.0).ceil();
  return 55.0 + (lines * 36.0);
}

double _estimateAltTitlesHeight(Media media) {
  int items = 0;
  if (media.romajiTitle.isNotEmpty && media.romajiTitle != '?') items++;
  if (media.englishTitle?.isNotEmpty == true || media.title.isNotEmpty) items++;
  if (media.nativeTitle?.isNotEmpty == true) items++;
  final synCount = media.synonyms.length;
  if (items == 0 && synCount == 0) return 0.0;

  double h = 55.0 + (items * 26.0);
  if (synCount > 0) {
    final synLines = (synCount / 3.0).ceil();
    h += 20.0 + (synLines * 28.0);
  }
  return h;
}

double _estimateFriendsHeight() => 185.0;

double _estimateSeasonsHeight() => 270.0;

double _estimateExtrasHeight() => 185.0;

List<Widget> _withSpacers(List<Widget> widgets, double spacing) {
  final visible = widgets.where((w) {
    if (w is SizedBox &&
        w.child == null &&
        (w.width ?? 0) == 0 &&
        (w.height ?? 0) == 0) {
      return false;
    }
    return true;
  }).toList();

  final result = <Widget>[];
  for (int i = 0; i < visible.length; i++) {
    result.add(visible[i]);
    if (i < visible.length - 1) {
      result.add(SizedBox(height: spacing));
    }
  }
  return result;
}

BoxDecoration _cardDecoration(ColorScheme colors) {
  return BoxDecoration(
    color: colors.surfaceContainerHighest.opaque(0.4, iReallyMeanIt: true),
    borderRadius: BorderRadius.circular(28),
    border: Border.all(
      color: colors.onSurface.opaque(0.07, iReallyMeanIt: true),
      width: 1,
    ),
  );
}

Widget _cardTitle(ColorScheme colors, String text) {
  return AnymeXText(
    uiLabel(Get.context!.l10n, text),
    size: 18,
    variant: TextVariant.bold,
    color: colors.onSurface,
  );
}

Widget _chipShell(ColorScheme colors, Widget child, {Color? fill}) {
  return Container(
    height: 34,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: fill ?? colors.onSurface.opaque(0.08, iReallyMeanIt: true),
      borderRadius: BorderRadius.circular(17),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [child],
    ),
  );
}

Widget _moreChip(ColorScheme colors, String label, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: _chipShell(
      colors,
      AnymeXText(
        label,
        size: 13,
        variant: TextVariant.semiBold,
        color: colors.primary,
      ),
      fill: colors.primary.opaque(0.16, iReallyMeanIt: true),
    ),
  );
}

Widget buildProgressContainer(
    BuildContext context, MediaDetailsController controller) {
  return Obx(() {
    final colors = context.colors;
    final media = controller.media.value;

    final totalFromMedia = controller.isAnime
        ? (int.tryParse(media.totalEpisodes) ?? 0)
        : (int.tryParse(media.totalChapters ?? '') ?? 0);

    final int totalCount;
    if (totalFromMedia > 0) {
      totalCount = totalFromMedia;
    } else if (controller.isAnime) {
      if (media.nextAiringEpisode != null &&
          media.nextAiringEpisode!.episode > 1) {
        totalCount = media.nextAiringEpisode!.episode - 1;
      } else {
        final released = int.tryParse(
                controller.trackedMedia.value?.releasedEpisodes ?? '') ??
            0;
        totalCount = released > 0
            ? released
            : (controller.episodeList.isNotEmpty
                ? controller.episodeList.length
                : 0);
      }
    } else {
      totalCount =
          controller.chapterList.isNotEmpty ? controller.chapterList.length : 0;
    }

    final currentProgress = controller.mediaProgress.value;
    final pct =
        totalCount > 0 ? (currentProgress / totalCount).clamp(0.0, 1.0) : 0.0;

    final relEp = controller.isAnime
        ? (media.nextAiringEpisode != null
            ? media.nextAiringEpisode!.episode - 1
            : (int.tryParse(
                    controller.trackedMedia.value?.releasedEpisodes ?? '') ??
                totalCount))
        : 0;

    final nextNumber = currentProgress + 1;
    final behind = (relEp > currentProgress) ? relEp - currentProgress : 0;
    final String statusSubtitle;
    if (currentProgress == 0) {
      statusSubtitle = controller.isAnime
          ? Get.context!.l10n.startWatchingEpisode
          : Get.context!.l10n.startReadingChapter;
    } else if (totalFromMedia > 0 && currentProgress >= totalFromMedia) {
      statusSubtitle = uiLabel(Get.context!.l10n, 'Completed');
    } else {
      final behindText = behind > 0
          ? ' • ${controller.isAnime ? Get.context!.l10n.episodesBehind('$behind') : Get.context!.l10n.chaptersBehind('$behind')}'
          : '';
      statusSubtitle = (controller.isAnime
              ? Get.context!.l10n.nextUpEpisode('$nextNumber')
              : Get.context!.l10n.nextUpChapter('$nextNumber')) +
          behindText;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(colors),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              _cardTitle(
                colors,
                uiLabel(Get.context!.l10n, controller.isAnime ? 'Watching progress' : 'Reading progress'),
              ),
              AnymeXTextSpans(
                spans: [
                  AnymeXTextSpan(
                    text: '$currentProgress',
                    variant: TextVariant.bold,
                    color: colors.onSurface,
                    size: 22,
                  ),
                  AnymeXTextSpan(
                    text: ' / ${totalCount > 0 ? totalCount : "?"}',
                    variant: TextVariant.regular,
                    color: colors.onSurface.opaque(0.5, iReallyMeanIt: true),
                    size: 14,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnymeXLinearIndicator(
            value: pct,
            color: colors.primary,
            backgroundColor: colors.onSurface.opaque(0.08, iReallyMeanIt: true),
            minHeight: 4.5,
          ),
          const SizedBox(height: 12),
          AnymeXText(
            statusSubtitle,
            size: 11.5,
            color: colors.onSurface.opaque(0.6, iReallyMeanIt: true),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  });
}

Widget buildAiringCountdownCard(
    BuildContext context, MediaDetailsController controller) {
  final colors = context.colors;
  final airing = controller.media.value.nextAiringEpisode;
  if (airing == null) return const SizedBox.shrink();

  return Obx(() {
    final seconds = controller.timeLeft.value;
    final days = seconds ~/ 86400;
    final hours = (seconds % 86400) ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(colors),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.timer_outlined,
                color: colors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              _cardTitle(colors, Get.context!.l10n.episodeAiringIn(airing.episode.toString())),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTimeSegment(
                  context,
                  days.toString().padLeft(2, '0'),
                  'days',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTimeSegment(
                  context,
                  hours.toString().padLeft(2, '0'),
                  'hours',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTimeSegment(
                  context,
                  minutes.toString().padLeft(2, '0'),
                  'minutes',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  });
}

Widget _buildTimeSegment(BuildContext context, String value, String unit) {
  final colors = context.colors;
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 14),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: colors.onSurface.opaque(0.05, iReallyMeanIt: true),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnymeXText(
          value,
          size: 22,
          variant: TextVariant.bold,
          color: colors.onSurface,
        ),
        const SizedBox(height: 2),
        AnymeXText(
          unit,
          size: 10,
          color: colors.onSurface.opaque(0.5, iReallyMeanIt: true),
        ),
      ],
    ),
  );
}

Widget buildStatsGrid(BuildContext context, Media media,
    {MediaDetailsController? controller}) {
  final colors = context.colors;
  final isAnime = media.mediaType == ItemType.anime;
  final yearStr = media.seasonYear?.toString() ?? '';

  final seasonText = [
    if (media.season.isNotEmpty && media.season != '?')
      uiLabel(Get.context!.l10n, media.season),
    if (yearStr.isNotEmpty) yearStr,
  ].join(' ');

  final totalChaptersStr = (media.totalChapters ?? '').isNotEmpty &&
          media.totalChapters != '0' &&
          media.totalChapters != '?'
      ? media.totalChapters!
      : ((controller != null && controller.chapterList.isNotEmpty)
          ? controller.chapterList.length.toString()
          : '');

  final scoreVal =
      (media.rating.isNotEmpty && media.rating != '?') ? media.rating : '0.0';
  final scoreDouble = double.tryParse(scoreVal) ?? 0.0;
  final scoreProgress =
      (scoreDouble > 10 ? scoreDouble / 100.0 : scoreDouble / 10.0)
          .clamp(0.0, 1.0);
  final ratingAdjective = scoreDouble >= 8.5
      ? uiLabel(Get.context!.l10n, 'Masterpiece')
      : (scoreDouble >= 8.0
          ? uiLabel(Get.context!.l10n, 'Excellent')
          : (scoreDouble >= 7.0
              ? uiLabel(Get.context!.l10n, 'Very Good')
              : (scoreDouble >= 6.0
                  ? uiLabel(Get.context!.l10n, 'Good')
                  : (scoreDouble > 0 ? uiLabel(Get.context!.l10n, 'Average') : uiLabel(Get.context!.l10n, 'Unrated')))));

  String formatPop(String pop) {
    final clean = pop.replaceAll(RegExp(r'[^0-9]'), '');
    final numVal = int.tryParse(clean);
    if (numVal == null) return pop.isNotEmpty ? pop : '0';
    if (numVal >= 1000000) {
      return '${(numVal / 1000000).toStringAsFixed(1)}M';
    }
    if (numVal >= 1000) {
      return '${(numVal / 1000).toStringAsFixed(0)}K';
    }
    return '$numVal';
  }

  final popFormatted = media.popularity.isNotEmpty && media.popularity != '?'
      ? Get.context!.l10n.popularityCount(formatPop(media.popularity))
      : uiLabel(Get.context!.l10n, 'Popular');

  final durationVal =
      (isAnime && media.duration.isNotEmpty && media.duration != '?')
          ? media.duration
          : '';
  final formatVal = media.format.isNotEmpty && media.format != '?'
      ? uiLabel(Get.context!.l10n, media.format)
      : (media.type.isNotEmpty && media.type != '?'
          ? media.type
          : media.mediaType.name.toUpperCase());
  final sourceVal = media.sourceMaterial != null &&
          media.sourceMaterial!.isNotEmpty &&
          media.sourceMaterial != '?'
      ? uiLabel(Get.context!.l10n, formatSourceMaterial(media.sourceMaterial))
      : '';

  final epVal = (isAnime &&
          media.totalEpisodes.isNotEmpty &&
          media.totalEpisodes != '0' &&
          media.totalEpisodes != '?')
      ? media.totalEpisodes
      : '';
  final countryVal = _formatCountry(media.countryOfOrigin);

  final stats = <MapEntry<String, String>>[
    if (durationVal.isNotEmpty) MapEntry(uiLabel(Get.context!.l10n, 'DURATION'), durationVal),
    if (seasonText.trim().isNotEmpty) MapEntry(uiLabel(Get.context!.l10n, 'SEASON'), seasonText.trim()),
    if (countryVal.isNotEmpty) MapEntry(uiLabel(Get.context!.l10n, 'ORIGIN'), countryVal),
    if (formatVal.isNotEmpty) MapEntry(uiLabel(Get.context!.l10n, 'FORMAT'), formatVal),
    if (sourceVal.isNotEmpty) MapEntry(uiLabel(Get.context!.l10n, 'SOURCE'), sourceVal),
    if (epVal.isNotEmpty) MapEntry(uiLabel(Get.context!.l10n, 'EPISODES'), epVal),
    if (!isAnime && totalChaptersStr.isNotEmpty)
      MapEntry(uiLabel(Get.context!.l10n, 'CHAPTERS'), totalChaptersStr),
  ];

  final statRows = <Widget>[];
  for (int i = 0; i < stats.length; i += 2) {
    final left = stats[i];
    final right = (i + 1 < stats.length) ? stats[i + 1] : null;

    statRows.add(
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildStatItem(colors, left.key, left.value),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: right != null
                ? _buildStatItem(colors, right.key, right.value)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );

    if (i + 2 < stats.length) {
      statRows.add(const SizedBox(height: 8));
    }
  }

  final validRankings = media.rankings.where((r) => r.rank > 0).toList();
  final rankingRows = <Widget>[];
  for (int i = 0; i < validRankings.length; i += 2) {
    final left = validRankings[i];
    final right = (i + 1 < validRankings.length) ? validRankings[i + 1] : null;

    rankingRows.add(
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildRankingItem(colors, left),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: right != null
                ? _buildRankingItem(colors, right)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );

    if (i + 2 < validRankings.length) {
      rankingRows.add(const SizedBox(height: 8));
    }
  }

  final statusLower = media.status.toLowerCase();
  final Color statusDotColor;
  if (statusLower.contains('cancel') || statusLower.contains('hiatus')) {
    statusDotColor = colors.tertiary;
  } else if (statusLower.contains('releas') ||
      statusLower.contains('ongoing')) {
    statusDotColor = colors.primary;
  } else {
    statusDotColor = colors.secondary;
  }
  final statusLabel = media.status.isNotEmpty && media.status != '?'
      ? uiLabel(
          Get.context!.l10n,
          media.status[0].toUpperCase() +
              media.status.substring(1).toLowerCase())
      : uiLabel(Get.context!.l10n, 'Unknown');

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: _cardDecoration(colors),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  M3EProgressIndicator.circularWavy(
                    value: scoreProgress,
                    size: 72,
                    color: colors.primary,
                    trackColor:
                        colors.primary.opaque(0.15, iReallyMeanIt: true),
                    strokeWidth: 5,
                    trackStrokeWidth: 5,
                  ),
                  AnymeXText(
                    scoreVal,
                    size: 22,
                    variant: TextVariant.bold,
                    color: colors.onSurface,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnymeXText(
                    context.l10n.detailsScore,
                    size: 11,
                    variant: TextVariant.bold,
                    color: colors.onSurface.opaque(0.5, iReallyMeanIt: true),
                  ),
                  const SizedBox(height: 2),
                  AnymeXText(
                    ratingAdjective,
                    size: 24,
                    variant: TextVariant.bold,
                    color: colors.onSurface,
                  ),
                  const SizedBox(height: 2),
                  AnymeXText(
                    popFormatted,
                    size: 13,
                    color: colors.onSurface.opaque(0.5, iReallyMeanIt: true),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (validRankings.isNotEmpty) ...[
          const SizedBox(height: 20),
          ...rankingRows,
        ],
        if (stats.isNotEmpty) ...[
          const SizedBox(height: 10),
          ...statRows,
        ],
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: colors.onSurface.opaque(0.05, iReallyMeanIt: true),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AnymeXText(
                context.l10n.detailsStatus,
                size: 11,
                variant: TextVariant.bold,
                color: colors.onSurface.opaque(0.5, iReallyMeanIt: true),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: statusDotColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: statusDotColor.withValues(alpha: 0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnymeXText(
                    statusLabel,
                    size: 14,
                    variant: TextVariant.bold,
                    color: statusDotColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildRankingItem(ColorScheme colors, Ranking ranking) {
  final rank = ranking.rank;
  final isRated = ranking.type.toUpperCase() == 'RATED';
  final isRankOne = rank == 1;

  final Color rankColor;
  if (isRankOne) {
    rankColor = const Color(0xFFE5A93C);
  } else if (isRated) {
    rankColor = colors.primary;
  } else {
    rankColor = colors.secondary;
  }

  final String typeLabel =
      uiLabel(Get.context!.l10n, isRated ? 'HIGHEST RATED' : 'MOST POPULAR');
  final String title = ranking.year != null && ranking.year! > 0
      ? '${ranking.year}'
      : uiLabel(Get.context!.l10n, 'All Time');
  final String subtitle = ranking.context != null && ranking.context!.isNotEmpty
      ? ranking.context!
      : (ranking.year != null && ranking.year! > 0
          ? '#$rank in ${ranking.year}'
          : '#$rank All Time');

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    decoration: BoxDecoration(
      color: colors.onSurface.opaque(0.05, iReallyMeanIt: true),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      children: [
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: rankColor, width: 2),
          ),
          child: AnymeXText(
            '#$rank',
            size: rank > 999 ? 10 : (rank > 99 ? 12 : 14),
            variant: TextVariant.bold,
            color: rankColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnymeXText(
                typeLabel,
                size: 10.5,
                variant: TextVariant.bold,
                color: colors.onSurface.opaque(0.5, iReallyMeanIt: true),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              AnymeXText(
                title,
                size: 16,
                variant: TextVariant.bold,
                color: colors.onSurface,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              AnymeXText(
                subtitle,
                size: 11,
                color: colors.onSurface.opaque(0.5, iReallyMeanIt: true),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildStatItem(ColorScheme colors, String label, String value) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    decoration: BoxDecoration(
      color: colors.onSurface.opaque(0.05, iReallyMeanIt: true),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnymeXText(
          uiLabel(Get.context!.l10n, label),
          size: 11,
          variant: TextVariant.bold,
          color: colors.onSurface.opaque(0.5, iReallyMeanIt: true),
        ),
        const SizedBox(height: 2),
        AnymeXText(
          value,
          size: 16,
          variant: TextVariant.bold,
          color: colors.onSurface,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}

Widget buildSynopsisCard(BuildContext context, Media media) {
  final colors = context.colors;
  final rawDesc = media.description;
  final cleanDesc = _cleanHtml(rawDesc);
  if (cleanDesc.isEmpty) return const SizedBox.shrink();

  final ValueNotifier<bool> isExpanded = ValueNotifier(false);

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: _cardDecoration(colors),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _cardTitle(colors, 'Synopsis'),
        const SizedBox(height: 12),
        ValueListenableBuilder<bool>(
          valueListenable: isExpanded,
          builder: (context, expanded, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnymeXText(
                  cleanDesc,
                  size: 14,
                  maxLines: expanded ? 9999 : 5,
                  overflow: TextOverflow.ellipsis,
                  isMarquee: false,
                  style: TextStyle(
                    height: 1.6,
                    color: colors.onSurface.opaque(0.85, iReallyMeanIt: true),
                  ),
                ),
                if (cleanDesc.length > 200) ...[
                  const SizedBox(height: 14),
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => isExpanded.value = !expanded,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 11),
                      decoration: BoxDecoration(
                        color: colors.primary.opaque(0.16, iReallyMeanIt: true),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: AnymeXText(
                        expanded ? uiLabel(Get.context!.l10n, 'Show less') : uiLabel(Get.context!.l10n, 'Read more'),
                        size: 14,
                        variant: TextVariant.bold,
                        color: colors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    ),
  );
}

Widget buildGenresAndTagsCard(BuildContext context, Media media) {
  final colors = context.colors;
  final hasGenres = media.genres.isNotEmpty;
  final hasTags = media.tags.isNotEmpty;
  final ValueNotifier<bool> isTagsExpanded = ValueNotifier(false);

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: _cardDecoration(colors),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasGenres) ...[
          _cardTitle(colors, 'Genres'),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: media.genres
                .map((genre) => buildGenreChip(context, genre, media.mediaType))
                .toList(),
          ),
        ],
        if (hasGenres && hasTags) const SizedBox(height: 24),
        if (hasTags) ...[
          _cardTitle(colors, 'Tags'),
          const SizedBox(height: 14),
          if (media.tags.length <= 10)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: media.tags
                  .map((tag) => buildTagChip(context, tag, media.mediaType))
                  .toList(),
            )
          else
            ValueListenableBuilder<bool>(
              valueListenable: isTagsExpanded,
              builder: (context, expanded, _) {
                final visibleTags =
                    expanded ? media.tags : media.tags.take(10).toList();
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...visibleTags.map(
                        (tag) => buildTagChip(context, tag, media.mediaType)),
                    _moreChip(
                      colors,
                      expanded
                          ? uiLabel(Get.context!.l10n, 'Less')
                          : Get.context!.l10n.moreCount('${media.tags.length - 10}'),
                      () => isTagsExpanded.value = !expanded,
                    ),
                  ],
                );
              },
            ),
        ],
      ],
    ),
  );
}

Widget? buildStudiosCard(BuildContext context, Media media) {
  final studios = media.studios ?? [];
  if (studios.isEmpty) return null;
  final colors = context.colors;
  final ValueNotifier<bool> isStudiosExpanded = ValueNotifier(false);

  Widget buildStudioChip(int index, String studioName) {
    final isMainStudio = index == 0;
    final textColor = isMainStudio ? colors.primary : colors.onSurface;

    return GestureDetector(
      onTap: () async {
        final studioId = await AnilistData.fetchStudioIdByName(studioName);
        if (studioId != null && context.mounted) {
          showStudioDetailsSheet(
            context,
            studioId,
            studioName,
          );
        }
      },
      child: _chipShell(
        colors,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isMainStudio) ...[
              Icon(
                Icons.movie_creation_rounded,
                size: 15,
                color: colors.primary,
              ),
              const SizedBox(width: 6),
            ],
            AnymeXText(
              studioName,
              size: 13,
              variant: TextVariant.semiBold,
              color: textColor,
            ),
          ],
        ),
        fill: isMainStudio
            ? colors.primary.opaque(0.2, iReallyMeanIt: true)
            : null,
      ),
    );
  }

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: _cardDecoration(colors),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _cardTitle(colors, 'Studios'),
        const SizedBox(height: 14),
        if (studios.length <= 4)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: studios
                .asMap()
                .entries
                .map((entry) => buildStudioChip(entry.key, entry.value))
                .toList(),
          )
        else
          ValueListenableBuilder<bool>(
            valueListenable: isStudiosExpanded,
            builder: (context, expanded, _) {
              final visibleStudios =
                  expanded ? studios : studios.take(4).toList();
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...visibleStudios
                      .asMap()
                      .entries
                      .map((entry) => buildStudioChip(entry.key, entry.value)),
                  _moreChip(
                    colors,
                    expanded
                        ? uiLabel(Get.context!.l10n, 'Less')
                        : Get.context!.l10n.moreCount('${studios.length - 4}'),
                    () => isStudiosExpanded.value = !expanded,
                  ),
                ],
              );
            },
          ),
      ],
    ),
  );
}

Widget? buildAlternativeTitles(BuildContext context, Media media) {
  final colors = context.colors;
  final titles = [
    if (media.romajiTitle.isNotEmpty && media.romajiTitle != '?')
      MapEntry(uiLabel(Get.context!.l10n, 'Romaji'), media.romajiTitle),
    if (media.englishTitle != null &&
        media.englishTitle!.isNotEmpty &&
        media.englishTitle != '?')
      MapEntry(uiLabel(Get.context!.l10n, 'English'), media.englishTitle!)
    else if (media.title.isNotEmpty && media.title != media.romajiTitle)
      MapEntry(uiLabel(Get.context!.l10n, 'English'), media.title),
    if (media.nativeTitle != null &&
        media.nativeTitle!.isNotEmpty &&
        media.nativeTitle != '?')
      MapEntry(uiLabel(Get.context!.l10n, 'Native'), media.nativeTitle!),
  ];

  final hasSynonyms = media.synonyms.isNotEmpty;
  if (titles.isEmpty && !hasSynonyms) return null;
  final ValueNotifier<bool> isSynonymsExpanded = ValueNotifier(false);

  Widget buildSynonymChip(String syn) {
    return _chipShell(
      colors,
      AnymeXText(
        syn,
        size: 13,
        variant: TextVariant.semiBold,
        color: colors.onSurface,
      ),
    );
  }

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: _cardDecoration(colors),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _cardTitle(colors, 'Alternative titles'),
        const SizedBox(height: 14),
        ...titles.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 76,
                    child: AnymeXText(
                      entry.key,
                      size: 13,
                      color: colors.onSurface.opaque(0.5, iReallyMeanIt: true),
                    ),
                  ),
                  Expanded(
                    child: AnymeXText(
                      entry.value,
                      size: 14,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      variant: TextVariant.semiBold,
                    ),
                  ),
                ],
              ),
            )),
        if (hasSynonyms) ...[
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 76,
                  child: AnymeXText(
                    context.l10n.synonyms,
                    size: 13,
                    color: colors.onSurface.opaque(0.5, iReallyMeanIt: true),
                  ),
                ),
                Expanded(
                  child: media.synonyms.length <= 5
                      ? Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              media.synonyms.map(buildSynonymChip).toList(),
                        )
                      : ValueListenableBuilder<bool>(
                          valueListenable: isSynonymsExpanded,
                          builder: (context, expanded, _) {
                            final visibleSynonyms = expanded
                                ? media.synonyms
                                : media.synonyms.take(5).toList();
                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ...visibleSynonyms.map(buildSynonymChip),
                                _moreChip(
                                  colors,
                                  expanded
                                      ? uiLabel(Get.context!.l10n, 'Less')
                                      : Get.context!.l10n.moreCount('${media.synonyms.length - 5}'),
                                  () => isSynonymsExpanded.value = !expanded,
                                ),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}

Widget _buildSection(String title, List<Widget> children, ColorScheme colors) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: _cardDecoration(colors),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _cardTitle(colors, title),
        const SizedBox(height: 14),
        ...children,
      ],
    ),
  );
}

Widget buildThemesSection(
    BuildContext context, MediaDetailsController controller) {
  final colors = context.colors;
  final media = controller.media.value;

  return Obx(() {
    if (controller.isThemesLoading.value) {
      return _buildSection(
        uiLabel(Get.context!.l10n, 'Openings & Endings'),
        [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.primary,
                ),
              ),
            ),
          ),
        ],
        colors,
      );
    }

    final themes = controller.animeThemes;
    if (themes.isEmpty) return const SizedBox.shrink();

    final ops =
        themes.where((t) => t.type.toUpperCase().startsWith('OP')).toList();
    final eds =
        themes.where((t) => t.type.toUpperCase().startsWith('ED')).toList();
    final other =
        themes.where((t) => !ops.contains(t) && !eds.contains(t)).toList();

    Widget buildThemeTile(AnimeTheme theme, int globalIndex) {
      final isOP = theme.type.toUpperCase().startsWith('OP');
      final badgeText =
          '${theme.type}${theme.sequence != null ? ' ${theme.sequence}' : ''}';

      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            AnimeThemePlayerDialog.show(
              context,
              themes: themes.toList(),
              initialIndex: globalIndex,
              animeDetails: media,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isOP ? colors.primary : colors.secondary)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: (isOP ? colors.primary : colors.secondary)
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: AnymeXText(
                    badgeText,
                    size: 11,
                    variant: TextVariant.bold,
                    color: isOP ? colors.primary : colors.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnymeXText(
                        theme.title,
                        size: 13,
                        variant: TextVariant.semiBold,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (theme.artist.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        AnymeXText(
                          theme.artist,
                          size: 11,
                          color: colors.onSurfaceVariant,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.play_circle_filled_rounded,
                  color: colors.primary,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final List<Widget> items = [];

    if (ops.isNotEmpty) {
      items.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4, top: 2),
          child: AnymeXText(
            context.l10n.openings,
            size: 12.5,
            variant: TextVariant.bold,
            color: colors.primary,
          ),
        ),
      );
      for (final op in ops) {
        final globalIndex = themes.indexOf(op);
        items.add(buildThemeTile(op, globalIndex));
      }
    }

    if (eds.isNotEmpty) {
      if (ops.isNotEmpty) items.add(const SizedBox(height: 8));
      items.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4, top: 4),
          child: AnymeXText(
            context.l10n.endings,
            size: 12.5,
            variant: TextVariant.bold,
            color: colors.secondary,
          ),
        ),
      );
      for (final ed in eds) {
        final globalIndex = themes.indexOf(ed);
        items.add(buildThemeTile(ed, globalIndex));
      }
    }

    if (other.isNotEmpty) {
      if (ops.isNotEmpty || eds.isNotEmpty) {
        items.add(const SizedBox(height: 8));
      }
      for (final oth in other) {
        final globalIndex = themes.indexOf(oth);
        items.add(buildThemeTile(oth, globalIndex));
      }
    }

    return _buildSection(uiLabel(Get.context!.l10n, 'Openings & Endings'), items, colors);
  });
}

Widget? buildSeasonsSection(BuildContext context, Media mediaData) {
  final prequels = mediaData.relations
          ?.where((element) => element.relationType == 'PREQUEL')
          .toList() ??
      [];
  final sequels = mediaData.relations
          ?.where((element) => element.relationType == 'SEQUEL')
          .toList() ??
      [];
  final filteredRelations = [
    if (prequels.isNotEmpty) prequels.first,
    if (sequels.isNotEmpty) sequels.first,
  ];

  if (filteredRelations.isEmpty) return null;

  final colors = context.colors;
  final isPair = filteredRelations.length == 2;

  Widget buildRelationCard(dynamic relation, BorderRadius radius) {
    final isMangaRelation = relation.type == 'MANGA';
    final isPrequel = relation.relationType == 'PREQUEL';
    final media = Media(
      id: relation.id.toString(),
      title: relation.title,
      poster: relation.poster,
      cover: relation.cover,
      type: relation.type,
      mediaType: isMangaRelation ? ItemType.manga : ItemType.anime,
      serviceType: ServicesType.anilist,
    );
    final imageUrl =
        relation.cover.isNotEmpty ? relation.cover : relation.poster;
    final rawLabel = relation.relationType.toString();
    final label = rawLabel.isEmpty
        ? rawLabel
        : uiLabel(
            Get.context!.l10n,
            '${rawLabel[0]}${rawLabel.substring(1).toLowerCase()}');
    final hint = isPrequel
        ? (isMangaRelation
            ? uiLabel(Get.context!.l10n, 'Read before')
            : uiLabel(Get.context!.l10n, 'Watch before'))
        : (isMangaRelation
            ? uiLabel(Get.context!.l10n, 'Read next')
            : uiLabel(Get.context!.l10n, 'Up next'));

    return GestureDetector(
      onTap: () {
        navigate(() => MediaDetailsPage(
              media: media,
              tag: relation.id.toString(),
            ));
      },
      child: ClipRRect(
        borderRadius: radius,
        child: SizedBox(
          height: 190,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnymeXImage(
                imageUrl: imageUrl,
                radius: 0,
                width: double.infinity,
                height: 190,
                fit: BoxFit.cover,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.3, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.9),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 12,
                top: 12,
                child: Container(
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnymeXText(
                        uiLabel(Get.context!.l10n, label),
                        size: 13,
                        variant: TextVariant.semiBold,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 12,
                top: 10,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPrequel
                        ? Icons.arrow_back_rounded
                        : Icons.arrow_forward_rounded,
                    size: 18,
                    color: colors.onPrimary,
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnymeXText(
                      relation.title,
                      size: 14,
                      variant: TextVariant.bold,
                      color: Colors.white,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      isMarquee: false,
                    ),
                    const SizedBox(height: 4),
                    AnymeXText(
                      hint,
                      size: 12,
                      variant: TextVariant.bold,
                      color: colors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  final Widget cards;
  if (isPair) {
    cards = Stack(
      alignment: Alignment.center,
      children: [
        Row(
          children: [
            Expanded(
              child: buildRelationCard(
                filteredRelations[0],
                const BorderRadius.horizontal(
                  left: Radius.circular(28),
                  right: Radius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: buildRelationCard(
                filteredRelations[1],
                const BorderRadius.horizontal(
                  left: Radius.circular(12),
                  right: Radius.circular(28),
                ),
              ),
            ),
          ],
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            shape: BoxShape.circle,
            border: Border.all(color: colors.surfaceContainer, width: 4),
          ),
          child: Icon(
            Icons.link_rounded,
            size: 17,
            color: colors.primary,
          ),
        ),
      ],
    );
  } else {
    cards = buildRelationCard(
      filteredRelations.first,
      BorderRadius.circular(28),
    );
  }

  return _buildSection(uiLabel(Get.context!.l10n, 'Seasons'), [cards], colors);
}

Widget buildExtrasSection(
    BuildContext context, Media mediaData, MediaDetailsController controller) {
  final isAnime = mediaData.mediaType == ItemType.anime;

  return _buildSection(
      uiLabel(Get.context!.l10n, 'Extras'),
      [
        AnymeXSectionBuilder(
          margin: EdgeInsets.zero,
          children: [
            if (isAnime) ...[
              AnymeXTile(
                icon: Icons.music_note_rounded,
                title: context.l10n.openingsEndings,
                subtitle: context.l10n.viewOpeningAndEndingThemes,
                onTap: () {
                  if (controller.animeThemes.isNotEmpty) {
                    AnimeThemePlayerDialog.show(
                      context,
                      themes: controller.animeThemes.toList(),
                      initialIndex: 0,
                      animeDetails: mediaData,
                    );
                  } else {
                    navigate(
                        () => AnimeThemePlayerPage(animeDetails: mediaData));
                  }
                },
              ),
              AnymeXTile(
                icon: Icons.playlist_play_rounded,
                title: context.l10n.watchOrder,
                subtitle: context.l10n.viewTheChronologicalWatchOrderOf,
                onTap: () {
                  navigate(() => WatchOrderPage(title: mediaData.title));
                },
              ),
              FutureBuilder<List<NewsItem>>(
                future: MangaAnimeUtil.getAnimeNews(mediaData),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return AnymeXTile(
                    icon: Icons.newspaper_rounded,
                    title: context.l10n.recentNews,
                    subtitle: context.l10n.readLatestUpdatesAboutThisAnime,
                    onTap: () {
                      navigate(() =>
                          NewsPage(media: mediaData, news: snapshot.data!));
                    },
                  );
                },
              ),
            ] else ...[
              FutureBuilder<List<NewsItem>>(
                future: MangaAnimeUtil.getMangaNovelNews(mediaData),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return AnymeXTile(
                    icon: Icons.newspaper_rounded,
                    title: context.l10n.recentNews,
                    subtitle: context.l10n.readLatestUpdatesAboutThisManga,
                    onTap: () {
                      navigate(() =>
                          NewsPage(media: mediaData, news: snapshot.data!));
                    },
                  );
                },
              ),
              FutureBuilder<AnimeAdaptation>(
                future: MangaAnimeUtil.getAnimeAdaptation(mediaData),
                builder: (context, snapshot) {
                  if (!snapshot.hasData ||
                      snapshot.data!.error != null ||
                      !snapshot.data!.hasAdaptation) {
                    return const SizedBox.shrink();
                  }
                  final start = snapshot.data!.animeStart ?? uiLabel(Get.context!.l10n, 'Unknown');
                  final end = snapshot.data!.animeEnd ?? uiLabel(Get.context!.l10n, 'Unknown');
                  return AnymeXTile(
                    icon: Icons.tv_rounded,
                    title: context.l10n.animeAdaptation,
                    subtitle: context.l10n.adaptedFromChapterTo(start.toString(), end.toString()),
                    onTap: () {},
                    showChevron: false,
                  );
                },
              ),
              FutureBuilder<NextRelease>(
                future: MangaAnimeUtil.getNextChapterPrediction(mediaData),
                builder: (context, snapshot) {
                  if (!snapshot.hasData ||
                      snapshot.data!.error != null ||
                      snapshot.data!.nextChapter == null) {
                    return const SizedBox.shrink();
                  }
                  final nextCh = snapshot.data!.nextChapter!;
                  final releaseDate = snapshot.data!.nextReleaseDate != null
                      ? snapshot.data!.nextReleaseDate!
                          .toString()
                          .split(' ')
                          .first
                      : uiLabel(Get.context!.l10n, 'Unknown');
                  return AnymeXTile(
                    icon: Icons.calendar_month_rounded,
                    title: context.l10n.nextReleasePrediction,
                    subtitle: context.l10n.predictedOn(nextCh.toString(), releaseDate.toString()),
                    onTap: () {},
                    showChevron: false,
                  );
                },
              ),
            ],
          ],
        )
      ],
      context.colors);
}

String _cleanHtml(String? text) {
  if (text == null || text.isEmpty) return '';
  return text.replaceAll(RegExp(r'<[^>]*>'), '').trim();
}

Widget buildGenreChip(BuildContext context, String genre, ItemType type) {
  final colors = context.colors;

  return GestureDetector(
    onTap: () {
      navigate(() => SearchPage(
            searchTerm: '',
            type: type,
            initialFilters: {
              'genres': [genre]
            },
          ));
    },
    child: _chipShell(
      colors,
      AnymeXText(
        genre,
        size: 13,
        variant: TextVariant.semiBold,
        color: colors.primary,
      ),
      fill: colors.primary.opaque(0.14, iReallyMeanIt: true),
    ),
  );
}

Widget buildTagChip(BuildContext context, MediaTag tag, ItemType type) {
  final colors = context.colors;

  return GestureDetector(
    onTap: () {
      navigate(() => SearchPage(
            searchTerm: '',
            type: type,
            initialFilters: {
              'tags': [tag.name]
            },
          ));
    },
    child: _chipShell(
      colors,
      AnymeXTextSpans(
        spans: [
          AnymeXTextSpan(
            text: tag.name,
            variant: TextVariant.semiBold,
            color: colors.onSurface,
            size: 13,
          ),
          if (tag.rank > 0)
            AnymeXTextSpan(
              text: ' ${tag.rank}%',
              variant: TextVariant.regular,
              color: colors.onSurface.opaque(0.55, iReallyMeanIt: true),
              size: 11.5,
            ),
        ],
      ),
    ),
  );
}
