import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/widgets/header_home.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AnimatedScrollAppBar extends StatefulWidget {
  final bool isHomePage;
  final ValueNotifier<bool> isVisible;
  final Duration animationDuration;
  final Curve animationCurve;

  const AnimatedScrollAppBar({
    super.key,
    this.isHomePage = false,
    required this.isVisible,
    this.animationDuration = const Duration(milliseconds: 450),
    this.animationCurve = Curves.easeInOut,
  });

  @override
  State<AnimatedScrollAppBar> createState() => _AnimatedScrollAppBarState();
}

class _AnimatedScrollAppBarState extends State<AnimatedScrollAppBar> {
  final profileData = Get.find<ServiceHandler>();

  @override
  Widget build(BuildContext context) {
    const int kAppBarOffset = 20;
    return ValueListenableBuilder<bool>(
      valueListenable: widget.isVisible,
      builder: (context, isVisible, child) {
        return AnimatedPositioned(
          duration: widget.animationDuration,
          curve: widget.animationCurve,
          top: isVisible
              ? 0
              : -(kToolbarHeight +
                  MediaQuery.of(context).padding.top +
                  kAppBarOffset),
          left: 0,
          right: 0,
          child: Container(
            color: Theme.of(context).appBarTheme.backgroundColor ??
                Theme.of(context).colorScheme.surface.withValues(alpha: 0.80),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top + 10),
                SizedBox(
                  height: kToolbarHeight,
                  child: Header(isHomePage: widget.isHomePage),
                ),
                const SizedBox(height: 10)
              ],
            ),
          ),
        );
      },
    );
  }
}

mixin ScrollAwareAppBarMixin<T extends StatefulWidget> on State<T> {
  ScrollController get scrollController;
  ValueNotifier<bool> isAppBarVisible = ValueNotifier<bool>(true);
  double _previousScrollOffset = 0;
  final double _scrollThreshold = 25.0;

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
    final currentOffset = scrollController.offset;

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
