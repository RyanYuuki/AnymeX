import 'package:flutter/material.dart';

class EpisodeButtons extends StatefulWidget {
  final List<List<int>> episodeRanges;
  final Function(List<int>) onRangeSelected;

  const EpisodeButtons(
      {super.key, required this.episodeRanges, required this.onRangeSelected});

  @override
  _EpisodeButtonsState createState() => _EpisodeButtonsState();
}

class _EpisodeButtonsState extends State<EpisodeButtons> {
  List<int>? activeRange;

  @override
  Widget build(BuildContext context) {
    return ListView(
      scrollDirection: Axis.horizontal,
      children: widget.episodeRanges.map((range) {
        return Row(
          children: [
            RangeButton(
              range: range,
              isActive: activeRange == range,
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
  final List<int> range;
  final bool isActive;
  final Function(List<int>) onRangeSelected;

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
        '${range[0]}-${range[1]}',
        style: TextStyle(
          color: isActive
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
