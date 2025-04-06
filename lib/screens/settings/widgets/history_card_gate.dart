import 'package:anymex/screens/library/widgets/history_model.dart';
import 'package:anymex/screens/library/widgets/unified_history_card.dart';
import 'package:anymex/screens/settings/widgets/history_card_selector.dart';
import 'package:flutter/material.dart';

class HistoryCardGate extends StatelessWidget {
  final HistoryModel data;
  final HistoryCardStyle cardStyle;

  const HistoryCardGate(
      {super.key, required this.data, required this.cardStyle});

  @override
  Widget build(BuildContext context) {
    switch (cardStyle) {
      case HistoryCardStyle.regular:
        return UnifiedHistoryCardV2(media: data);

      case HistoryCardStyle.blurred:
        return UnifiedHistoryCard(media: data);

      case HistoryCardStyle.bootiful:
        return UnifiedHistoryCardV3(media: data);
    }
  }
}
