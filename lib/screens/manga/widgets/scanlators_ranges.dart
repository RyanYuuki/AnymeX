import 'package:anymex/widgets/common/anymex_pills.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ScanlatorsRanges extends StatelessWidget {
  final List<String> scanlators;
  final RxInt selectedScanIndex;
  final VoidCallback? onScanIndexChanged;

  const ScanlatorsRanges({
    super.key,
    required this.scanlators,
    required this.selectedScanIndex,
    required this.onScanIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = selectedScanIndex.value;
      return AnymeXPills(
        scrollPadding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
        items: [
          PillItem(
            label: 'All',
            isSelected: selected == 0,
            onTap: () {
              selectedScanIndex.value = 0;
              onScanIndexChanged?.call();
            },
          ),
          ...List.generate(scanlators.length, (index) {
            final uiIndex = index + 1;
            return PillItem(
              label: scanlators[index],
              isSelected: selected == uiIndex,
              onTap: () {
                selectedScanIndex.value = uiIndex;
                onScanIndexChanged?.call();
              },
            );
          }),
        ],
      );
    });
  }
}
