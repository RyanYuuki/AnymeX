// ignore_for_file: prefer_const_constructors

import 'package:custom_sliding_segmented_control/custom_sliding_segmented_control.dart';
import 'package:flutter/material.dart';

typedef ButtonTapCallback = void Function(int? index);

class MyTabBar extends StatefulWidget {
  final ButtonTapCallback onTap;
  const MyTabBar({super.key, required this.onTap});

  @override
  State<MyTabBar> createState() => _MyTabBarState();
}

class _MyTabBarState extends State<MyTabBar> {
  int currentIndex = 1;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: CustomSlidingSegmentedControl<int>(
        fixedWidth: MediaQuery.of(context).size.width / 2 - 12,
        initialValue: 1,
        children: {
          1: Text('Sub', style: TextStyle(color: currentIndex == 1 ? Theme.of(context).colorScheme.inverseSurface == Theme.of(context).colorScheme.onPrimaryFixedVariant ? Colors.black : 
Theme.of(context).colorScheme.onPrimaryFixedVariant == Color(0xffe2e2e2) ? Colors.black : Colors.white : null), ),
          2: Text('Dub', style: TextStyle(color: currentIndex == 2 ? Theme.of(context).colorScheme.inverseSurface == Theme.of(context).colorScheme.onPrimaryFixedVariant ? Colors.black : 
Theme.of(context).colorScheme.onPrimaryFixedVariant == Color(0xffe2e2e2) ? Colors.black : Colors.white : null), ),
        },
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        thumbDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onPrimaryFixedVariant,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.3),
              blurRadius: 4.0,
              spreadRadius: 1.0,
              offset: const Offset(
                0.0,
                2.0,
              ),
            ),
          ],
        ),
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInToLinear,
        onValueChanged: (v) => {
          setState(() {
            currentIndex = v;
          }),
          widget.onTap(v)
        },
      ),
    );
  }
}
