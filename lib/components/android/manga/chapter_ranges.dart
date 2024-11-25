import 'package:flutter/material.dart';

class ChapterRanges extends StatefulWidget {
  final List<List<double>> chapterRanges;
  final Function(List<double>) onRangeSelected;

  const ChapterRanges({
    super.key,
    required this.chapterRanges,
    required this.onRangeSelected,
  });

  @override
  _ChapterRangesState createState() => _ChapterRangesState();
}

class _ChapterRangesState extends State<ChapterRanges> {
  List<double>? activeRange;
  int index = -1;
  @override
  Widget build(BuildContext context) {
    return ListView(
      scrollDirection: Axis.horizontal,
      children: widget.chapterRanges.map((range) {
        index++;
        return Row(
          children: [
            RangeButton(
              range: range,
              isActive: activeRange == range || index == 0,
              onRangeSelected: (selectedRange) {
                setState(() {
                  activeRange = selectedRange;
                });
                widget.onRangeSelected(selectedRange);
              },
            ),
            const SizedBox(width: 10),
          ],
        );
      }).toList(),
    );
  }
}

class RangeButton extends StatelessWidget {
  final List<double> range;
  final bool isActive;
  final Function(List<double>) onRangeSelected;

  const RangeButton({
    super.key,
    required this.range,
    required this.isActive,
    required this.onRangeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1,
            color: isActive
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).colorScheme.primary,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: () => onRangeSelected(range),
      child: Text(
        '${range[0].toStringAsFixed(1)}-${range[1].toStringAsFixed(1)}',
        style: TextStyle(
          color: isActive
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
