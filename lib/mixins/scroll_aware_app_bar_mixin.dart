import 'package:flutter/material.dart';

mixin ScrollAwareAppBarMixin<T extends StatefulWidget> on State<T> {
  ScrollController get scrollController;

  final ValueNotifier<bool> isAppBarVisible = ValueNotifier<bool>(true);

  double _previousScrollOffset = 0;
  final double _scrollThreshold = 50.0;
  @override
  void initState() {
    super.initState();
    scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    scrollController.removeListener(_handleScroll);
    isAppBarVisible.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!scrollController.hasClients) return;
    final currentOffset = scrollController.offset;
    final maxScroll = scrollController.position.maxScrollExtent;

    if (currentOffset <= 0) {
      isAppBarVisible.value = true;
      _previousScrollOffset = currentOffset;
      return;
    }
    if (currentOffset >= maxScroll) {
      return;
    }

    if ((currentOffset - _previousScrollOffset).abs() > _scrollThreshold) {
      if (currentOffset > _previousScrollOffset) {
        isAppBarVisible.value = false;
      } else {
        isAppBarVisible.value = true;
      }
      _previousScrollOffset = currentOffset;
    }
  }

  void toggleAppBar() {
    isAppBarVisible.value = !isAppBarVisible.value;
  }
}
