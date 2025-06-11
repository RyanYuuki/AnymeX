import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:anymex/mixins/scroll_aware_app_bar_mixin.dart';
import 'package:anymex/widgets/common/animated_app_bar.dart';

class CustomAnimatedAppBar extends StatefulWidget {
  final ValueNotifier<bool> isVisible;
  final Duration animationDuration;
  final Curve animationCurve;
  final ScrollController? scrollController;
  final Widget headerContent;
  final Color? backgroundColor;
  final SystemUiOverlayStyle? visibleStatusBarStyle;
  final SystemUiOverlayStyle? hiddenStatusBarStyle;
  static const double kAppBarOffset = 20.0;

  const CustomAnimatedAppBar({
    super.key,
    required this.isVisible,
    this.animationDuration = const Duration(milliseconds: 450),
    this.animationCurve = Curves.easeInOut,
    this.scrollController,
    required this.headerContent,
    this.backgroundColor,
    this.visibleStatusBarStyle = SystemUiOverlayStyle.dark,
    this.hiddenStatusBarStyle = SystemUiOverlayStyle.light,
  });

  @override
  State<CustomAnimatedAppBar> createState() => _CustomAnimatedAppBarState();
}

class _CustomAnimatedAppBarState extends State<CustomAnimatedAppBar>
    with ScrollAwareAppBarMixin<CustomAnimatedAppBar> {
  @override
  ScrollController get scrollController {
    assert(widget.scrollController != null);
    return widget.scrollController!;
  }

  @override
  void initState() {
    super.initState();
    _getEffectiveIsVisibleNotifier().addListener(_updateSystemOverlayStyle);
    _updateSystemOverlayStyle();
  }

  @override
  void dispose() {
    _getEffectiveIsVisibleNotifier().removeListener(_updateSystemOverlayStyle);
    super.dispose();
  }

  ValueNotifier<bool> _getEffectiveIsVisibleNotifier() {
    return widget.scrollController != null ? isAppBarVisible : widget.isVisible;
  }

  void _updateSystemOverlayStyle() {
    final bool isVisible = _getEffectiveIsVisibleNotifier().value;

    if (isVisible) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
      );

      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          statusBarColor: Colors.transparent,
        ),
      );
    } else {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersive,
        overlays: [],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _getEffectiveIsVisibleNotifier(),
      builder: (BuildContext context, bool isVisible, Widget? child) {
        return AnimatedAppBar.animatedAppBar(
          isVisible: isVisible,
          animationDuration: widget.animationDuration,
          animationCurve: widget.animationCurve,
          offset: CustomAnimatedAppBar.kAppBarOffset,
          topPadding: 10,
          bottomPadding: 10,
          content: widget.headerContent,
          backgroundColor: widget.backgroundColor,
        );
      },
    );
  }
}
