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
  final double scrollThreshold;

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
    this.scrollThreshold = 10.0,
  });

  @override
  State<CustomAnimatedAppBar> createState() => _CustomAnimatedAppBarState();
}

class _CustomAnimatedAppBarState extends State<CustomAnimatedAppBar>
    with ScrollAwareAppBarMixin<CustomAnimatedAppBar> {
  // Add a ValueNotifier for tracking scroll position
  late ValueNotifier<bool> _isAtTopNotifier;

  @override
  ScrollController get scrollController {
    assert(widget.scrollController != null);
    return widget.scrollController!;
  }

  @override
  void initState() {
    super.initState();

    _isAtTopNotifier = ValueNotifier<bool>(
        (widget.scrollController?.offset ?? 0.0) <= widget.scrollThreshold);

    _getEffectiveIsVisibleNotifier().addListener(_updateSystemOverlayStyle);

    if (widget.scrollController != null) {
      widget.scrollController!.addListener(_onScrollChanged);
    }

    _updateSystemOverlayStyle();
  }

  @override
  void dispose() {
    _getEffectiveIsVisibleNotifier().removeListener(_updateSystemOverlayStyle);

    // Remove scroll listener
    if (widget.scrollController != null) {
      widget.scrollController!.removeListener(_onScrollChanged);
    }

    _isAtTopNotifier.dispose();
    super.dispose();
  }

  // Scroll listener that updates immediately
  void _onScrollChanged() {
    final bool isAtTop = scrollController.offset <= widget.scrollThreshold;
    if (_isAtTopNotifier.value != isAtTop) {
      _isAtTopNotifier.value = isAtTop;
    }
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _getEffectiveIsVisibleNotifier(),
      builder: (BuildContext context, bool isVisible, Widget? child) {
        return ValueListenableBuilder<bool>(
          valueListenable: _isAtTopNotifier,
          builder: (BuildContext context, bool isAtTop, Widget? child) {
            return AnimatedAppBar(
              isVisible: isVisible,
              animationDuration: widget.animationDuration,
              animationCurve: widget.animationCurve,
              offset: CustomAnimatedAppBar.kAppBarOffset,
              topPadding: 10,
              bottomPadding: 10,
              content: widget.headerContent,
              isAtTop: isAtTop,
            );
          },
        );
      },
    );
  }
}
