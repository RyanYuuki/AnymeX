import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/screens/library/widgets/history_model.dart';
import 'package:anymex/screens/settings/widgets/history_card_gate.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/custom_widgets/anymex_chip.dart';
import 'package:anymex/widgets/custom_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/custom_widgets/custom_expansion_tile.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:flutter/material.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

import 'package:get/get.dart';

enum HistoryCardStyle { regular, blurred, bootiful }

double getHistoryCardHeight(HistoryCardStyle style, BuildContext context) {
  switch (style) {
    case HistoryCardStyle.bootiful:
      return 270;
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
          return AnymexDialog(
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
              ));
        },
      );
    },
  );
}

class HistoryCardSelector extends StatefulWidget {
  final Function(HistoryCardStyle) onStyleChanged;
  final HistoryCardStyle initialStyle;

  const HistoryCardSelector({
    super.key,
    required this.onStyleChanged,
    required this.initialStyle,
  });

  @override
  State<HistoryCardSelector> createState() => _HistoryCardSelectorState();
}

class _HistoryCardSelectorState extends State<HistoryCardSelector> {
  late HistoryCardStyle _selectedStyle;
  final dummyData = HistoryModel(
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
      date: '2025-03-13');

  @override
  void initState() {
    super.initState();
    _selectedStyle = widget.initialStyle;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 50,
          child: SuperListView(
            scrollDirection: Axis.horizontal,
            children: HistoryCardStyle.values
                .map((style) => Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: _buildStyleChip(style),
                    ))
                .toList(),
          ),
        ),
        10.height(),
        AnymexCard(
          enableAnimation: true,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: getHistoryCardHeight(_selectedStyle, context),
              child: HistoryCardGate(
                data: dummyData,
                cardStyle: _selectedStyle,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStyleChip(HistoryCardStyle style) {
    final bool isSelected = style == _selectedStyle;

    return AnymexChip(
      isSelected: isSelected,
      label: style.name.capitalize!,
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _selectedStyle = style;
          });
          widget.onStyleChanged(style);
        }
      },
    );
  }
}
