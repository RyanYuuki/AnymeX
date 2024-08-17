import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

typedef ButtonTapCallback = void Function(String? index);

class ToggleBar extends StatefulWidget {
  final Widget child;
  final String? title;
  final String? chapter;
  final int? totalImages;
  final ScrollController scrollController;
  final ButtonTapCallback handleChapter;
  const ToggleBar({
    super.key,
    required this.child,
    required this.title,
    required this.chapter,
    required this.totalImages,
    required this.scrollController,
    required this.handleChapter,
  });

  @override
  State<ToggleBar> createState() => _ToggleBarState();
}

class _ToggleBarState extends State<ToggleBar> {
  bool _areBarsVisible = false;
  double _scrollProgress = 0.0;
  int _currentPage = 1;

  void _toggleBarsVisibility() {
    setState(() {
      _areBarsVisible = !_areBarsVisible;
    });
  }

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_updateScrollProgress);
  }

  void _updateScrollProgress() {
    if (widget.scrollController.hasClients && widget.totalImages! > 0) {
      final maxScrollExtent = widget.scrollController.position.maxScrollExtent;
      final currentScroll = widget.scrollController.position.pixels;
      final progress = currentScroll / maxScrollExtent;

      setState(() {
        _scrollProgress = progress.clamp(0.0, 1.0);
        _currentPage = ((progress * (widget.totalImages! - 1)) + 1).round();
      });
    }
  }

  void _onProgressBarTap(TapUpDetails details) {
    if (widget.scrollController.hasClients) {
      final box = context.findRenderObject() as RenderBox;
      final localPosition = box.globalToLocal(details.globalPosition);
      final progress = (localPosition.dx / box.size.width).clamp(0.0, 1.0);
      final targetPage = (progress * (widget.totalImages! - 1)).round();

      widget.scrollController.jumpTo(
        targetPage *
            (widget.scrollController.position.maxScrollExtent /
                (widget.totalImages! - 1)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            GestureDetector(
              onTap: _toggleBarsVisibility,
              child: widget.child,
            ),

            // Top Bar
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              top: _areBarsVisible ? 0 : -80,
              left: 0,
              right: 0,
              child: Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.tertiary.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        IconlyBold.arrow_left,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title!,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 3),
                        Text(widget.chapter!,
                            style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Bar with Progress Bar and Page Numbers
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              bottom: _areBarsVisible ? 0 : -80,
              left: 0,
              right: 0,
              child: Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.tertiary.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous),
                      onPressed: () {
                        widget.handleChapter('left');
                      },
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            '$_currentPage',
                            style: const TextStyle(fontSize: 16),
                          ),
                          Expanded(
                            child: Slider(
                              value: _scrollProgress,
                              onChanged: (value) {
                                _onProgressBarTap(
                                  TapUpDetails(
                                    kind: PointerDeviceKind.touch,
                                    globalPosition: Offset(
                                      value * MediaQuery.of(context).size.width,
                                      0,
                                    ),
                                  ),
                                );
                              },
                              activeColor: Colors.indigo.shade400,
                              inactiveColor: Theme.of(context)
                                  .colorScheme
                                  .surface
                                  .withOpacity(0.7),
                            ),
                          ),
                          Text('${widget.totalImages}',
                              style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next),
                      onPressed: () {
                        widget.handleChapter('right');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_updateScrollProgress);
    super.dispose();
  }
}
