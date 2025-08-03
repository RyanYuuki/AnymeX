import 'package:anymex/widgets/custom_widgets/anymex_chip.dart';
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Obx(() => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: AnymexChip(
                  label: ('All'),
                  isSelected: selectedScanIndex.value == 0,
                  onSelected: (bool selected) {
                    if (selected) {
                      selectedScanIndex.value = 0;
                      onScanIndexChanged?.call();
                    }
                  },
                ),
              )),
          ...List.generate(scanlators.length, (index) {
            final uiIndex = index + 1;
            final scanlator = scanlators[index];

            return Obx(() => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AnymexChip(
                    label: (scanlator),
                    isSelected: selectedScanIndex.value == uiIndex,
                    onSelected: (bool selected) {
                      if (selected) {
                        selectedScanIndex.value = uiIndex;
                      }
                    },
                  ),
                ));
          }),
        ],
      ),
    );
  }
}
