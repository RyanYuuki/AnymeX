// ignore_for_file: prefer_const_constructors

import 'package:custom_sliding_segmented_control/custom_sliding_segmented_control.dart';
import 'package:flutter/material.dart';

typedef ButtonTapCallback = void Function(int? index);

class AnimeTable extends StatefulWidget {
  final ButtonTapCallback onTap;
  final int? currentIndex;
  final bool isManga;
  const AnimeTable(
      {super.key,
      required this.onTap,
      required this.currentIndex,
      this.isManga = false});

  @override
  State<AnimeTable> createState() => _AnimeTableState();
}

class _AnimeTableState extends State<AnimeTable> {
  @override
  Widget build(BuildContext context) {
    final ColorScheme = Theme.of(context).colorScheme;
    return Center(
      child: CustomSlidingSegmentedControl<int>(
        innerPadding: EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: ColorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        thumbDecoration: BoxDecoration(
          color: ColorScheme.onPrimaryFixedVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        fixedWidth: MediaQuery.of(context).size.width / 3 - 10,
        initialValue: widget.currentIndex,
        children: {
          0: Text(
            widget.isManga ? 'Rated' : 'Day',
            style: TextStyle(
                fontFamily: 'Poppins-SemiBold',
                color: widget.currentIndex == 0
                    ? Theme.of(context).colorScheme.inverseSurface ==
                            Theme.of(context).colorScheme.onPrimaryFixedVariant
                        ? Colors.black
                        : Theme.of(context).colorScheme.onPrimaryFixedVariant ==
                                Color(0xffe2e2e2)
                            ? Colors.black
                            : Colors.white
                    : null),
          ),
          1: Text(
            widget.isManga ? 'Ongoing' : 'Week',
            style: TextStyle(
                fontFamily: 'Poppins-SemiBold',
                color: widget.currentIndex == 1
                    ? Theme.of(context).colorScheme.inverseSurface ==
                            Theme.of(context).colorScheme.onPrimaryFixedVariant
                        ? Colors.black
                        : Theme.of(context).colorScheme.onPrimaryFixedVariant ==
                                Color(0xffe2e2e2)
                            ? Colors.black
                            : Colors.white
                    : null),
          ),
          2: Text(
            widget.isManga ? 'Updated' : 'Month',
            style: TextStyle(
                fontFamily: 'Poppins-SemiBold',
                color: widget.currentIndex == 2
                    ? Theme.of(context).colorScheme.inverseSurface ==
                            Theme.of(context).colorScheme.onPrimaryFixedVariant
                        ? Colors.black
                        : Theme.of(context).colorScheme.onPrimaryFixedVariant ==
                                Color(0xffe2e2e2)
                            ? Colors.black
                            : Colors.white
                    : null),
          ),
        },
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInToLinear,
        onValueChanged: (v) => {widget.onTap(v)},
      ),
    );
  }
}
