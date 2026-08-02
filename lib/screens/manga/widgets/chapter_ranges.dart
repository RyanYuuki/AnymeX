import 'package:anymex/database/isar_models/chapter.dart';
import 'package:anymex/widgets/common/anymex_pills.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChapterRanges extends StatelessWidget {
  final RxInt selectedChunkIndex;
  final ValueChanged<int> onChunkSelected;
  final List<List<Chapter>> chunks;

  const ChapterRanges({
    super.key,
    required this.selectedChunkIndex,
    required this.onChunkSelected,
    required this.chunks,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = selectedChunkIndex.value;
      return AnymeXPills(
        scrollPadding: const EdgeInsets.fromLTRB(0, 10, 0, 5),
        items: List.generate(chunks.length, (index) {
          final label = index == 0
              ? 'All'
              : '${chunks[index].first.formattedNumber} - ${chunks[index].last.formattedNumber}';
          return PillItem(
            label: label,
            isSelected: selected == index,
            onTap: () {
              selectedChunkIndex.value = index;
              onChunkSelected(index);
            },
          );
        }),
      );
    });
  }
}
