import 'package:flutter/material.dart';

class ExpandablePageView extends StatefulWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final PageController? controller;
  final ValueChanged<int>? onPageChanged;
  final bool reverse;
  final double defaultHeight;

  const ExpandablePageView({
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.onPageChanged,
    this.reverse = false,
    this.defaultHeight = 1750,
    super.key,
  });

  @override
  _ExpandablePageViewState createState() => _ExpandablePageViewState();
}

class _ExpandablePageViewState extends State<ExpandablePageView> {
  PageController? _pageController;
  late List<double> _heights;
  int _currentPage = 0;

  double get _currentHeight => _heights[_currentPage];

  @override
  void initState() {
    super.initState();
    _heights =
        List.filled(widget.itemCount, widget.defaultHeight, growable: true);
    _pageController = widget.controller ?? PageController();
    _pageController?.addListener(_updatePage);
  }

  @override
  void dispose() {
    _pageController?.removeListener(_updatePage);
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      curve: Curves.easeInOutCubic,
      tween: Tween<double>(begin: _heights.first, end: _currentHeight),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) => SizedBox(height: value, child: child),
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.itemCount,
        physics: const BouncingScrollPhysics(),
        itemBuilder: _itemBuilder,
        onPageChanged: widget.onPageChanged,
        reverse: widget.reverse,
      ),
    );
  }

  Widget _itemBuilder(BuildContext context, int index) {
    if (mounted) {
      final item = widget.itemBuilder(context, index);
      return OverflowBox(
        minHeight: 0,
        maxHeight: double.infinity,
        alignment: Alignment.topCenter,
        child: SizeReportingWidget(
          onSizeChange: (size) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  if ((size.height - widget.defaultHeight).abs() > 10) {
                    _heights[index] = size.height;
                  }
                });
              }
            });
          },
          child: item,
        ),
      );
    } else {
      return const SizedBox(
        height: 500,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
  }

  void _updatePage() {
    final newPage = _pageController?.page?.round();
    if (_currentPage != newPage) {
      // Use post-frame callback to defer state update
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _currentPage = newPage ?? _currentPage;
          });
        }
      });
    }
  }
}

class SizeReportingWidget extends StatefulWidget {
  final Widget child;
  final ValueChanged<Size> onSizeChange;

  const SizeReportingWidget({
    required this.child,
    required this.onSizeChange,
    super.key,
  });

  @override
  _SizeReportingWidgetState createState() => _SizeReportingWidgetState();
}

class _SizeReportingWidgetState extends State<SizeReportingWidget> {
  Size? _oldSize;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifySize();
    });
    return widget.child;
  }

  void _notifySize() {
    if (mounted) {
      final size = context.size;
      if (_oldSize != size) {
        _oldSize = size;
        if (size != null) widget.onSizeChange(size);
      }
    }
  }
}
