import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/screens/library/widgets/history_model.dart';
import 'package:anymex/screens/settings/widgets/history_card_gate.dart';
import 'package:anymex/widgets/common/dynamic_style_selector.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum HistoryCardStyle { regular, blurred, bootiful }

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
  );

  String _getStyleName(HistoryCardStyle style) {
    switch (style) {
      case HistoryCardStyle.regular:
        return 'Regular';
      case HistoryCardStyle.blurred:
        return 'Frosted Glass';
      case HistoryCardStyle.bootiful:
        return 'Bootiful';
    }
  }

  String _getStyleDescription(HistoryCardStyle style) {
    switch (style) {
      case HistoryCardStyle.regular:
        return 'Classic card layout showing media title, progress, and date details.';
      case HistoryCardStyle.blurred:
        return 'Frosted glass container overlay with soft background color elements.';
      case HistoryCardStyle.bootiful:
        return 'An immersive, premium poster-first card layout.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DynamicStyleSelector<HistoryCardStyle>(
      values: HistoryCardStyle.values,
      selectedValue: initialStyle,
      getTitle: _getStyleName,
      getDescription: _getStyleDescription,
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
