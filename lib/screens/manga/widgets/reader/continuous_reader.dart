import 'dart:math' as math;

import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/database/isar_models/chapter.dart';
import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:anymex/widgets/subsampling_scale_image_view/subsampling_image_provider.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:anymex_extension_runtime_bridge/Models/Page.dart';
import 'package:anymex/screens/manga/widgets/reader/reader_chapter_transition.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ContinuousReaderView extends StatefulWidget {
  final ReaderController controller;

  const ContinuousReaderView({super.key, required this.controller});

  @override
  State<ContinuousReaderView> createState() => _ContinuousReaderViewState();
}

class _ContinuousReaderViewState extends State<ContinuousReaderView>
    with TickerProviderStateMixin {
  late Axis _scrollDirection;
  late bool _reverse;

  double _scale = 1.0;
  double _baseScale = 1.0;
  Offset _offset = Offset.zero;
  Offset _baseOffset = Offset.zero;
  Offset _pinchStartFocalPoint = Offset.zero;
  Offset _doubleTapPosition = Offset.zero;

  late final AnimationController _zoomAnimController;
  double _animStartScale = 1.0;
  double _animTargetScale = 1.0;
  double _animFocalPointX = 0.0;
  double _animFocalPointY = 0.0;
  double _animStartOffsetDx = 0.0;
  double _animStartOffsetDy = 0.0;

  int _spreadCount = 0;
  int _initialIndex = 0;

  late Worker _spreadsWorker;

  @override
  void initState() {
    super.initState();
    _scrollDirection = widget.controller.readingDirection.value.axis;
    _reverse = widget.controller.readingDirection.value.reversed;
    _spreadCount = widget.controller.spreads.length;
    _initialIndex = _computeInitialIndex();

    _zoomAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..addListener(_onZoomTick);

    widget.controller.itemPositionsListener?.itemPositions.addListener(_updateVisibleIndices);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateVisibleIndices();
    });

    _spreadsWorker = ever(widget.controller.spreads, (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final newCount = widget.controller.spreads.length;
        if (newCount != _spreadCount) {
          setState(() {
            _spreadCount = newCount;
          });
        }
      });
    });
  }

  Set<int> _visibleIndices = {};

  void _updateVisibleIndices() {
    final positions = widget.controller.itemPositionsListener?.itemPositions.value;
    if (positions == null || positions.isEmpty) return;

    final newVisible = positions.map((p) => p.index).toSet();
    if (!setEquals(_visibleIndices, newVisible)) {
      setState(() {
        _visibleIndices = newVisible;
      });
    }
  }

  @override
  void didUpdateWidget(ContinuousReaderView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newAxis = widget.controller.readingDirection.value.axis;
    final newReverse = widget.controller.readingDirection.value.reversed;
    if (_scrollDirection != newAxis || _reverse != newReverse) {
      setState(() {
        _scrollDirection = newAxis;
        _reverse = newReverse;
        _scale = 1.0;
        _offset = Offset.zero;
        _initialIndex = _computeInitialIndex();
        _spreadCount = widget.controller.spreads.length;
      });
    }
  }

  @override
  void dispose() {
    widget.controller.itemPositionsListener?.itemPositions.removeListener(_updateVisibleIndices);
    _zoomAnimController.dispose();
    _spreadsWorker.dispose();
    super.dispose();
  }

  void _onZoomTick() {
    final t = _zoomAnimController.value;
    final curveVal = Curves.easeOutCubic.transform(t);
    final currentScale =
        _animStartScale + (_animTargetScale - _animStartScale) * curveVal;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;

    final targetDx = _animFocalPointX -
        (_animFocalPointX - _animStartOffsetDx) *
            (currentScale / _animStartScale);
    final targetDy = _animFocalPointY -
        (_animFocalPointY - _animStartOffsetDy) *
            (currentScale / _animStartScale);

    final maxDx = (screenWidth * (currentScale - 1)) / 2;
    final maxDy = (screenHeight * (currentScale - 1)) / 2;

    setState(() {
      _scale = currentScale;
      _offset = Offset(
        currentScale > 1.0 ? targetDx.clamp(-maxDx, maxDx) : 0.0,
        currentScale > 1.0 ? targetDy.clamp(-maxDy, maxDy) : 0.0,
      );
    });
  }

  void _animateZoom(double targetScale, Offset localFocalPoint) {
    if (_zoomAnimController.isAnimating) {
      _zoomAnimController.stop();
    }
    _animStartScale = _scale;
    _animTargetScale = targetScale;

    final sw = MediaQuery.sizeOf(context).width;
    final sh = MediaQuery.sizeOf(context).height;

    _animFocalPointX = localFocalPoint.dx - sw / 2;
    _animFocalPointY = localFocalPoint.dy - sh / 2;
    _animStartOffsetDx = _offset.dx;
    _animStartOffsetDy = _offset.dy;

    _zoomAnimController
      ..duration = const Duration(milliseconds: 350)
      ..forward(from: 0.0);
  }

  void _toggleScale(Offset localFocalPoint) {
    if (!mounted) return;
    if (_zoomAnimController.isAnimating) return;
    if (_scale == 1.0) {
      _animateZoom(2.0, localFocalPoint);
    } else {
      _animateZoom(1.0, localFocalPoint);
    }
  }

  int _lastPointerCount = 0;

  void _handleScaleStart(ScaleStartDetails details) {
    if (_zoomAnimController.isAnimating) _zoomAnimController.stop();
    _baseScale = _scale;
    _baseOffset = _offset;
    _pinchStartFocalPoint = details.localFocalPoint;
    _lastPointerCount = details.pointerCount;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (_zoomAnimController.isAnimating) return;

    if (details.pointerCount > 1 && _lastPointerCount <= 1) {
      _baseScale = _scale;
      _baseOffset = _offset;
    }
    _lastPointerCount = details.pointerCount;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final isVertical = _scrollDirection == Axis.vertical;

    if (details.pointerCount == 1) {
      
      
      if (_scale <= 1.0) return;

      final maxDx = (screenWidth * (_scale - 1)) / 2;
      final maxDy = (screenHeight * (_scale - 1)) / 2;

      final dragDx = details.localFocalPoint.dx - _pinchStartFocalPoint.dx;
      final dragDy = details.localFocalPoint.dy - _pinchStartFocalPoint.dy;

      final tempDx = _baseOffset.dx + dragDx;
      final tempDy = _baseOffset.dy + dragDy;

      double newDx;
      double newDy;

      if (isVertical) {
        newDx = tempDx.clamp(-maxDx, maxDx);
        if (tempDy > maxDy) {
          newDy = maxDy;
          final overflowY = tempDy - maxDy;
          try {
            widget.controller.scrollOffsetController?.animateScroll(
              offset: -overflowY,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
            );
          } catch (_) {}
        } else if (tempDy < -maxDy) {
          newDy = -maxDy;
          final overflowY = tempDy - (-maxDy);
          try {
            widget.controller.scrollOffsetController?.animateScroll(
              offset: -overflowY,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
            );
          } catch (_) {}
        } else {
          newDy = tempDy;
        }
      } else {
        newDy = tempDy.clamp(-maxDx, maxDx);
        if (tempDx > maxDx) {
          newDx = maxDx;
          final overflowX = tempDx - maxDx;
          try {
            widget.controller.scrollOffsetController?.animateScroll(
              offset: -overflowX,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
            );
          } catch (_) {}
        } else if (tempDx < -maxDx) {
          newDx = -maxDx;
          final overflowX = tempDx - (-maxDx);
          try {
            widget.controller.scrollOffsetController?.animateScroll(
              offset: -overflowX,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
            );
          } catch (_) {}
        } else {
          newDx = tempDx;
        }
      }

      setState(() {
        _offset = Offset(newDx, newDy);
      });
    } else {
      
      final newScale = (_baseScale * details.scale).clamp(0.5, 5.0);
      final maxDx = (screenWidth * (newScale - 1)) / 2;
      final maxDy = (screenHeight * (newScale - 1)) / 2;

      final focalX = details.localFocalPoint.dx - screenWidth / 2;
      final focalY = details.localFocalPoint.dy - screenHeight / 2;
      final newDx = focalX - (focalX - _baseOffset.dx) * (newScale / _baseScale);
      final newDy = focalY - (focalY - _baseOffset.dy) * (newScale / _baseScale);

      final clampedDx = newScale > 1.0 ? newDx.clamp(-maxDx, maxDx) : 0.0;
      final clampedDy = newScale > 1.0 ? newDy.clamp(-maxDy, maxDy) : 0.0;

      setState(() {
        _scale = newScale;
        _offset = Offset(clampedDx, clampedDy);
      });
    }
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    if (_scale < 1.0) {
      _animateZoom(
        1.0,
        Offset(
          MediaQuery.sizeOf(context).width / 2,
          MediaQuery.sizeOf(context).height / 2,
        ),
      );
    }
  }

  Widget _buildItemAt(BuildContext context, int index) {
    return Obx(() {
      final spreads = widget.controller.spreads;
      if (index >= spreads.length) return const SizedBox.shrink();
      final spread = spreads[index];
      final uniqueKey = ValueKey(
        '${spread.chapter?.link ?? spread.chapter?.number ?? "trans"}-$index',
      );
      return KeyedSubtree(
        key: uniqueKey,
        child: _buildSpread(context, spread, index),
      );
    });
  }

  Widget _buildSpread(BuildContext context, ReaderPage spread, int index) {
    if (spread.isTransition) return _buildTransition(spread);
    if (!spread.isSpread) return _buildImage(context, spread.page1!, index, spread.chapter);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(child: _buildImage(context, spread.page1!, index, spread.chapter)),
        Expanded(child: _buildImage(context, spread.page2!, index, spread.chapter)),
      ],
    );
  }

  Widget _buildTransition(ReaderPage spread) {
    final ctrl = widget.controller;
    final chapter = spread.chapter ?? ctrl.currentChapter.value!;
    final curIdx = ctrl.chapterList.indexOf(chapter);
    final targetIdx = spread.isNextTransition ? curIdx + 1 : curIdx - 1;
    final targetChapter =
        (targetIdx >= 0 && targetIdx < ctrl.chapterList.length)
            ? ctrl.chapterList[targetIdx]
            : null;

    return Obx(() {
      ctrl.currentPageIndex.value;
      final loadingSet = ctrl.loadingChapterLinks;
      final isLoading = targetChapter != null &&
          loadingSet.contains(targetChapter.link);
      return SizedBox(
        height: 500,
        child: ReaderChapterTransition(
          isNext: spread.isNextTransition,
          currentChapter: chapter,
          targetChapter: targetChapter,
          posterUrl: ctrl.media.poster,
          isLoading: isLoading,
        ),
      );
    });
  }

  Widget _buildImage(BuildContext context, PageUrl page, int index, Chapter? chapter) {
    return Obx(() {
      final ctrl = widget.controller;
      final sourceController = Get.find<SourceController>();

      int relativePageNum = index + 1;
      if (chapter != null && chapter.link != null) {
        final pages = ctrl.loadedChapterPages[chapter.link!] ?? ctrl.pageList;
        final pageIdx = pages.indexWhere((p) => p.url == page.url);
        if (pageIdx != -1) {
          relativePageNum = pageIdx + 1;
        }
      }

      return Padding(
        padding: EdgeInsets.symmetric(
            vertical: ctrl.spacedPages.value ? 8.0 : 0),
        child: Center(
          child: SubsamplingImageProvider(
            page: PageUrl(
              page.url,
              headers: (page.headers?.isEmpty ?? true)
                  ? {
                      'Referer':
                          sourceController.activeMangaSource.value?.baseUrl ??
                              ''
                    }
                  : page.headers,
            ),
            fit: ctrl.fitToScreen.value ? BoxFit.fitWidth : BoxFit.contain,
            alignment: Alignment.center,
            cropBorders: ctrl.cropImages.value,
            isContinuousMode: true,
            onImageLoaded: (w, h) {
              ctrl.updatePageAspectRatio(page.url, w, h);
            },
            placeholder: _buildPlaceholder(context, relativePageNum, page.url),
          ),
        ),
      );
    });
  }

  Widget _buildPlaceholder(BuildContext context, int pageNumber, String pageUrl,
      {double? progress}) {
    final progressText = progress != null
        ? ' (${(progress * 100).clamp(0, 100).toStringAsFixed(0)}%)'
        : '';
    final aspect = widget.controller.pageAspectRatios[pageUrl] ?? 0.65;
    return AspectRatio(
      aspectRatio: aspect,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnymexProgressIndicator(value: progress),
            const SizedBox(height: 8),
            Text('Loading page $pageNumber$progressText...'),
          ],
        ),
      ),
    );
  }

  int _computeInitialIndex() {
    final spreads = widget.controller.spreads;
    int initialIndex = 0;
    int acc = 0;
    for (int i = 0; i < spreads.length; i++) {
      if (spreads[i].isTransition) continue;
      acc += spreads[i].pageCount;
      if (acc >= widget.controller.currentPageIndex.value) {
        initialIndex = i;
        break;
      }
    }
    return initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onScaleStart: _handleScaleStart,
      onScaleUpdate: _handleScaleUpdate,
      onScaleEnd: _handleScaleEnd,
      onDoubleTapDown: _scale > 1.0 ? (d) => _doubleTapPosition = d.localPosition : null,
      onDoubleTap: _scale > 1.0 ? () => _toggleScale(_doubleTapPosition) : null,
      child: Transform(
        transform: Matrix4.diagonal3Values(_scale, _scale, 1.0)
          ..setTranslationRaw(_offset.dx, _offset.dy, 0.0),
        alignment: Alignment.center,
        child: ScrollablePositionedList.separated(
          key: ValueKey('$_scrollDirection-$_reverse'),
          itemCount: math.max(_spreadCount, 1),
          itemScrollController: widget.controller.itemScrollController,
          scrollOffsetController: widget.controller.scrollOffsetController,
          itemPositionsListener: widget.controller.itemPositionsListener,
          scrollOffsetListener: widget.controller.scrollOffsetListener,
          initialScrollIndex: _initialIndex,
          physics: _scale > 1.0
              ? const NeverScrollableScrollPhysics()
              : const ClampingScrollPhysics(),
          scrollDirection: _scrollDirection,
          reverse: _reverse,
          itemBuilder: _buildItemAt,
          separatorBuilder: _buildSeparator,
        ),
      ),
    );
  }

  Widget _buildSeparator(BuildContext context, int index) {
    if (!widget.controller.spacedPages.value) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: _scrollDirection == Axis.vertical ? 8.0 : 0.0,
      width: _scrollDirection == Axis.horizontal ? 8.0 : 0.0,
    );
  }
}
