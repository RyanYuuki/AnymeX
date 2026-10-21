import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/screens/library/widgets/history_model.dart';
import 'package:anymex/screens/settings/widgets/history_card_gate.dart';
import 'package:anymex/widgets/common/dynamic_style_selector.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum HistoryCardStyle {
  regular(
    'Regular',
    'Classic card layout showing media title, progress, and date details.',
  ),
  blurred(
    'Frosted Glass',
    'Frosted glass container overlay with soft background color elements.',
  ),
  bootiful(
    'Bootiful',
    'An immersive, premium poster-first card layout.',
  );

  final String displayName;
  final String description;

  const HistoryCardStyle(this.displayName, this.description);
}

double getHistoryCardHeight(HistoryCardStyle style, BuildContext context) {
  switch (style) {
    case HistoryCardStyle.bootiful:
      return 300;
    default:
      return getResponsiveSize(context, mobileSize: 150, desktopSize: 190);
  }
}

void showHistoryCardStyleSelector(BuildContext context) {
  final selectedStyle =
      HistoryCardStyle.values[settingsController.historyCardStyle].obs;

  showDialog(
    context: context,
    builder: (dialogContext) {
      return Obx(
        () {
          return AnymeXDialog(
            padding: const EdgeInsets.all(10),
            title: 'Card Style',
            onConfirm: () {
              settingsController.historyCardStyle = selectedStyle.value.index;
            },
            contentWidget: HistoryCardSelector(
              onStyleChanged: (e) {
                selectedStyle.value = e;
              },
              initialStyle: selectedStyle.value,
            ),
          );
        },
      );
    },
  );
}

class HistoryCardSelector extends StatelessWidget {
  final Function(HistoryCardStyle) onStyleChanged;
  final HistoryCardStyle initialStyle;

  const HistoryCardSelector({
    super.key,
    required this.onStyleChanged,
    required this.initialStyle,
  });

  static final dummyData = HistoryModel(
    title: 'Demon Slayer: Kimetsu no Yaiba',
    cover: 'https://image.tmdb.org/t/p/w500/m9sWQLtoU1G5jdHOYUnykin0xxw.jpg',
    poster:
        'https://s4.anilist.co/file/anilistcdn/media/anime/cover/medium/bx101922-WBsBl0ClmgYL.jpg',
    sourceName: 'Vumeto',
    formattedEpisodeTitle: 'Episode 3',
    progress: 243034,
    totalProgress: 1420061,
    progressTitle: 'Sabito and Makomo',
    isManga: false,
    calculatedProgress: 0.1711433522926128,
    progressText: '19:37 left',
    date: '2025-03-13',
    onTap: () {},
  );

  static final sampleDataList = [
    dummyData,
    HistoryModel(
      title: 'Jujutsu Kaisen',
      cover: 'https://image.tmdb.org/t/p/w500/gmU3rV6x0K5B63yv7N7N90m9p3k.jpg',
      poster:
          'https://s4.anilist.co/file/anilistcdn/media/anime/cover/medium/bx113415-bbBWj4pEFseh.jpg',
      sourceName: 'Hianime',
      formattedEpisodeTitle: 'Episode 12',
      progress: 1100000,
      totalProgress: 1420000,
      progressTitle: 'To You, Someday',
      isManga: false,
      calculatedProgress: 0.77,
      progressText: '05:20 left',
      date: '2025-03-12',
      onTap: () {},
    ),
    HistoryModel(
      title: 'Attack on Titan',
      cover: 'https://image.tmdb.org/t/p/w500/27UrwQ4VlK2hM4b6lA5mRz2X6Y7.jpg',
      poster:
          'https://s4.anilist.co/file/anilistcdn/media/anime/cover/medium/bx16498-73IhOXpJZiDY.png',
      sourceName: 'AnimePahe',
      formattedEpisodeTitle: 'Episode 75',
      progress: 640000,
      totalProgress: 1420000,
      progressTitle: 'Judgment',
      isManga: false,
      calculatedProgress: 0.45,
      progressText: '12:45 left',
      date: '2025-03-11',
      onTap: () {},
    ),
    HistoryModel(
      title: 'Solo Leveling',
      cover: 'https://image.tmdb.org/t/p/w500/geCRueV3ElhRTr03BPJuVq0fk35.jpg',
      poster:
          'https://s4.anilist.co/file/anilistcdn/media/anime/cover/medium/bx151807-m1gmSHZvlUR4.jpg',
      sourceName: 'Gogoanime',
      formattedEpisodeTitle: 'Episode 8',
      progress: 1280000,
      totalProgress: 1420000,
      progressTitle: 'This Is Frustrating',
      isManga: false,
      calculatedProgress: 0.90,
      progressText: '02:10 left',
      date: '2025-03-10',
      onTap: () {},
    ),
    HistoryModel(
      title: 'Frieren: Beyond Journey\'s End',
      cover: 'https://image.tmdb.org/t/p/w500/cuV2O53rOT2wb8GFUmp8G7vRgtm.jpg',
      poster:
          'https://s4.anilist.co/file/anilistcdn/media/anime/cover/medium/bx154587-n2222m.jpg',
      sourceName: 'Vumeto',
      formattedEpisodeTitle: 'Episode 20',
      progress: 70000,
      totalProgress: 1420000,
      progressTitle: 'Necessary Murder',
      isManga: false,
      calculatedProgress: 0.05,
      progressText: '22:15 left',
      date: '2025-03-09',
      onTap: () {},
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DynamicStyleSelector<HistoryCardStyle>(
      values: HistoryCardStyle.values,
      selectedValue: initialStyle,
      getTitle: (style) => style.displayName,
      getDescription: (style) => style.description,
      buildPreview: (style) => SizedBox(
        height: getHistoryCardHeight(style, context),
        child: HistoryCardGate(
          data: dummyData,
          cardStyle: style,
        ),
      ),
      onValueChanged: onStyleChanged,
    );
  }
}
