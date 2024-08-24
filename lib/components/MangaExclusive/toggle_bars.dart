import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';

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
  bool _isSliderBeingUsed = false;

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

        if (!_isSliderBeingUsed && _areBarsVisible) {
          _areBarsVisible = false;
        }
      });
    }
  }

  void _onProgressBarTap(double progress) {
    if (widget.scrollController.hasClients) {
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
    return Scaffold(
      body: Stack(
        children: [
          GestureDetector(
            onTap: _toggleBarsVisibility,
            child: widget.child,
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            top: _areBarsVisible ? 0 : -120,
            left: 0,
            right: 0,
            child: Container(
              height: 120,
              padding: const EdgeInsets.only(left: 5, right: 5, top: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.5),
                    Colors.transparent,
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon:
                        const Icon(IconlyBold.arrow_left, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          widget.chapter!.length > 30
                              ? widget.chapter!.substring(0, 30) + "..."
                              : widget.chapter!,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 16, color: Colors.white)),
                      const SizedBox(height: 3),
                      Text(widget.title!,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            bottom: _areBarsVisible ? 0 : -150,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.5),
                    Colors.transparent,
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width - 30,
                    decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20)),
                    child: Slider(
                      divisions: widget.totalImages ?? 0,
                      value: _scrollProgress,
                      onChangeStart: (_) {
                        setState(() {
                          _isSliderBeingUsed = true;
                        });
                      },
                      onChanged: (value) {
                        setState(() {
                          _scrollProgress = value;
                        });
                        _onProgressBarTap(value);
                      },
                      onChangeEnd: (_) {
                        setState(() {
                          _isSliderBeingUsed = false;
                        });
                      },
                      activeColor: Theme.of(context).colorScheme.primary,
                      inactiveColor: Theme.of(context)
                          .colorScheme
                          .inverseSurface
                          .withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Iconsax.previous5,
                            color: Colors.white, size: 35),
                        onPressed: () {
                          widget.handleChapter('left');
                        },
                      ),
                      IconButton(
                        icon: const Icon(Iconsax.next5,
                            size: 35, color: Colors.white),
                        onPressed: () {
                          widget.handleChapter('right');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Absolute Positioned Page Number
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '$_currentPage / ${widget.totalImages}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_updateScrollProgress);
    super.dispose();
  }
}
