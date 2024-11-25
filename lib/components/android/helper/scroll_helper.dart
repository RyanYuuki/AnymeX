import 'package:flutter/material.dart';

class ScrollDirectionHelper {
  Offset? previousOffset;

  bool isScrollingRight(Offset currentOffset) {
    if (previousOffset == null) {
      previousOffset = currentOffset;
      return true; 
    }

    bool scrollingRight = currentOffset.dx > previousOffset!.dx;
    previousOffset = currentOffset;
    return scrollingRight;
  }
}
