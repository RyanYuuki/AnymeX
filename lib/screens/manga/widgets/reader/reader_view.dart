import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:anymex/screens/manga/widgets/reader/continuous_reader.dart';
import 'package:anymex/screens/manga/widgets/reader/display_refresh_host.dart';
import 'package:anymex/screens/manga/widgets/reader/reader_chapter_transition.dart';
import 'package:anymex/screens/manga/widgets/reader/reader_color_overlay.dart';
import 'package:anymex/screens/manga/widgets/reader/reader_page_actions_dialog.dart';
import 'package:anymex/widgets/subsampling_scale_image_view/subsampling_image_provider.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class ReaderView extends StatefulWidget {
  final ReaderController controller;

  const ReaderView({
    super.key,
    required this.controller,
  });

  @override
  State<ReaderView> createState() => _ReaderViewState();
}

class _ReaderViewState extends State<ReaderView> with TickerProviderStateMixin {
  final PhotoViewController _photoViewController = PhotoViewController();
  final PhotoViewScaleStateController _photoViewScaleStateController =
      PhotoViewScaleStateController();
  final DisplayRefreshHost _displayRefreshHost = DisplayRefreshHost();
  Alignment _scalePosition = Alignment.center;
  bool _isCtrlPressed = false;
  late AnimationController _scaleAnimationController;
  late Animation<double> _animation;
  final List<double> _doubleTapScales = [1.0, 2.0];
  Offset? _lastTapPosition;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyPress);
    _scaleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = Tween(begin: 1.0, end: 2.0).animate(
      CurvedAnimation(curve: Curves.ease, parent: _scaleAnimationController),
    );
    _animation.addListener(() => _photoViewController.scale = _animation.value);
    widget.controller.photoViewController = _photoViewController;

    ever(widget.controller.displayRefreshInterval,
        (v) => _displayRefreshHost.flashInterval.value = v);
    ever(widget.controller.displayRefreshColor,
        (v) => _displayRefreshHost.flashColor.value = v);
    ever(widget.controller.displayRefreshDurationMs,
        (v) => _displayRefreshHost.flashDurationMs.value = v);

    ever(widget.controller.readingLayout, (_) => setState(() {}));
    ever(widget.controller.readingDirection, (_) => setState(() {}));
    ever(widget.controller.dualPageMode, (_) => setState(() {}));
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyPress);
    _photoViewController.dispose();
    _photoViewScaleStateController.dispose();
    _scaleAnimationController.dispose();
    _displayRefreshHost.dispose();
    super.dispose();
  }

  bool _handleKeyPress(KeyEvent event) {
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      if (event.logicalKey == LogicalKeyboardKey.controlLeft ||
          event.logicalKey == LogicalKeyboardKey.controlRight ||
          event.logicalKey == LogicalKeyboardKey.metaLeft ||
          event.logicalKey == LogicalKeyboardKey.metaRight) {
        setState(() => _isCtrlPressed = true);
      }
    } else if (event is KeyUpEvent) {
      if (event.logicalKey == LogicalKeyboardKey.controlLeft ||
          event.logicalKey == LogicalKeyboardKey.controlRight ||
          event.logicalKey == LogicalKeyboardKey.metaLeft ||
          event.logicalKey == LogicalKeyboardKey.metaRight) {
        setState(() => _isCtrlPressed = false);
      }
    }
    return false;
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      if (_isCtrlPressed) {
        final delta = event.scrollDelta.dy;
        final currentScale = _photoViewController.scale ?? 1.0;
        final newScale = (currentScale - (delta * 0.002)).clamp(1.0, 5.0);

        if (newScale != currentScale) {
          _photoViewController.scale = newScale;
        }
      } else {
        widget.controller.handleMouseScroll(event.scrollDelta.dy);
      }
    }
  }

  void _onScaleEnd(
    BuildContext context,
    ScaleEndDetails details,
    PhotoViewControllerValue controllerValue,
  ) {
    if (controllerValue.scale! < 1) {
      _photoViewScaleStateController.reset();
    }
  }

  double get pixelRatio => View.of(context).devicePixelRatio;
  Size get size => View.of(context).physicalSize / pixelRatio;

  Alignment _computeAlignmentByTapOffset(Offset offset) {
    return Alignment(
      (offset.dx - size.width / 2) / (size.width / 2),
      (offset.dy - size.height / 2) / (size.height / 2),
    );
  }

  void _toggleScale(Offset tapPosition) {
    if (mounted) {
      setState(() {
        if (_scaleAnimationController.isAnimating) {
          return;
        }

        final currentScale = _photoViewController.scale ?? 1.0;

        if (currentScale == _doubleTapScales[0]) {
          _scalePosition = _computeAlignmentByTapOffset(tapPosition);

          if (_scaleAnimationController.isCompleted) {
            _scaleAnimationController.reset();
          }

          _animation =
              Tween(begin: _doubleTapScales[0], end: _doubleTapScales[1])
                  .animate(
            CurvedAnimation(
                curve: Curves.ease, parent: _scaleAnimationController),
          );
          _animation
              .addListener(() => _photoViewController.scale = _animation.value);

          _scaleAnimationController.forward();
          return;
        }

        if (currentScale >= _doubleTapScales[1]) {
          _animation =
              Tween(begin: currentScale, end: _doubleTapScales[0]).animate(
            CurvedAnimation(
                curve: Curves.ease, parent: _scaleAnimationController),
          );
          _animation
              .addListener(() => _photoViewController.scale = _animation.value);

          if (_scaleAnimationController.isCompleted) {
            _scaleAnimationController.reset();
          }

          _scaleAnimationController.forward();
          return;
        }

        _photoViewScaleStateController.reset();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: _handlePointerSignal,
      onPointerPanZoomUpdate: (event) {
        widget.controller
            .handleMouseScroll(-event.panDelta.dy * 4, isTrackpad: true);
      },
      onPointerPanZoomEnd: (event) {
        widget.controller.handleOverscrollEnd();
      },
      onPointerUp: widget.controller.onPointerUp,
      onPointerDown: widget.controller.onPointerDown,
      onPointerCancel: widget.controller.onPointerCancel,
      child: NotificationListener<ScrollNotification>(
        onNotification: widget.controller.onScrollNotification,
        child: NotificationListener<ScrollNotification>(
          onNotification: widget.controller.onScrollNotification,
          child: Obx(() {
            switch (widget.controller.loadingState.value) {
              case LoadingState.loading:
                return _buildLoadingView(context);
              case LoadingState.error:
                return _buildErrorView(context);
              case LoadingState.loaded:
                return _buildContentView(context);
            }
          }),
        ),
      ),
    );
  }

  Widget _buildLoadingView(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnymexProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading pages...'),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.opaque(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load chapter',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.controller.errorMessage.value.isNotEmpty
                  ? widget.controller.errorMessage.value
                  : 'Something went wrong while loading the pages',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: widget.controller.retryFetchImages,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

   Widget _buildContentView(BuildContext context) {
    return Obx(() {
      final Color bgColor = switch (widget.controller.readerTheme.value) {
        0 => Colors.white,
        2 => const Color(0xFF303030),
        3 => Theme.of(context).scaffoldBackgroundColor,
        _ => Colors.black,
      };

      final isContinuous =
          widget.controller.readingLayout.value == MangaPageViewMode.continuous;

      return Stack(
        children: [
          Container(color: bgColor),
          if (isContinuous)
            PhotoView.customChild(
              controller: _photoViewController,
              scaleStateController: _photoViewScaleStateController,
              basePosition: _scalePosition,
              minScale: PhotoViewComputedScale.contained * 1.0,
              maxScale: PhotoViewComputedScale.covered * 5.0,
              onScaleEnd: _onScaleEnd,
              gestureDetectorBehavior: HitTestBehavior.translucent,
              backgroundDecoration: const BoxDecoration(color: Colors.transparent),
              child: GestureDetector(
                onTapDown: (details) =>
                    _lastTapPosition = details.globalPosition,
                onTap: () {
                  if (_lastTapPosition != null) {
                    widget.controller.handleTap(_lastTapPosition!);
                  }
                },
                onLongPressStart: (details) {
                  if (widget.controller.longPressPageActionsEnabled.value) {
                    showReaderPageActionsDialog(context, widget.controller);
                  }
                },
                onDoubleTapDown: (details) {
                  _toggleScale(details.globalPosition);
                },
                onDoubleTap: () {},
                child: ContinuousReaderView(controller: widget.controller),
              ),
            )
          else
            _buildPagedView(),
          ReaderContentOverlay(controller: widget.controller),
          if (widget.controller.grayscaleEnabled.value ||
              widget.controller.invertColorsEnabled.value)
            IgnorePointer(
              child: ColorFiltered(
                colorFilter: ColorFilter.matrix(
                  widget.controller.grayscaleEnabled.value
                      ? [
                          0.2126,
                          0.7152,
                          0.0722,
                          0,
                          0,
                          0.2126,
                          0.7152,
                          0.0722,
                          0,
                          0,
                          0.2126,
                          0.7152,
                          0.0722,
                          0,
                          0,
                          0,
                          0,
                          0,
                          1,
                          0,
                        ]
                      : [
                          -1,
                          0,
                          0,
                          0,
                          255,
                          0,
                          -1,
                          0,
                          0,
                          255,
                          0,
                          0,
                          -1,
                          0,
                          255,
                          0,
                          0,
                          0,
                          1,
                          0,
                        ],
                ),
                child: Container(color: Colors.transparent),
              ),
            ),
          DisplayRefreshOverlay(host: _displayRefreshHost),
        ],
      );
    });
  }


  Widget _buildPagedView() {
    // Reading spreads inside Obx so PhotoViewGallery rebuilds when new
    // chapters are appended inline (spreads is an RxList).
    return Obx(() {
      final spreads = widget.controller.spreads;
      return PhotoViewGallery.builder(
        itemCount: spreads.length,
        pageController: widget.controller.pageController,
        scrollPhysics: const ClampingScrollPhysics(),
        scrollDirection: widget.controller.readingDirection.value.axis,
        reverse: widget.controller.readingDirection.value.reversed,
        onPageChanged: (index) {
          widget.controller.onPageChanged(index);
          if (widget.controller.displayRefreshEnabled.value) {
            _displayRefreshHost.flash();
          }
        },
        backgroundDecoration: const BoxDecoration(color: Colors.transparent),
        builder: (context, index) {
          return PhotoViewGalleryPageOptions.customChild(
            minScale: PhotoViewComputedScale.contained * 1.0,
            maxScale: PhotoViewComputedScale.covered * 4.0,
            child: GestureDetector(
              onTapDown: (details) => _lastTapPosition = details.globalPosition,
              onTap: () {
                if (_lastTapPosition != null) {
                  widget.controller.handleTap(_lastTapPosition!);
                }
              },
              onLongPressStart: (details) {
                if (widget.controller.longPressPageActionsEnabled.value) {
                  showReaderPageActionsDialog(context, widget.controller);
                }
              },
              child: _buildSpread(context, spreads[index], index),
            ),
          );
        },
      );
    });
  }
  Widget _buildSpread(BuildContext context, ReaderPage spread, int index) {
    if (spread.isTransition) {
      final ctrl = widget.controller;
      final chapter = spread.chapter ?? ctrl.currentChapter.value!;
      final curIdx = ctrl.chapterList.indexOf(chapter);
      final targetIdx = spread.isNextTransition ? curIdx + 1 : curIdx - 1;
      final targetChapter = (targetIdx >= 0 && targetIdx < ctrl.chapterList.length)
          ? ctrl.chapterList[targetIdx]
          : null;

      return ReaderChapterTransition(
        isNext: spread.isNextTransition,
        currentChapter: chapter,
        targetChapter: targetChapter,
      );
    }
    if (!spread.isSpread) {
      return _buildImageForPaged(context, spread.page1!, index);
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(child: _buildImageForPaged(context, spread.page1!, index)),
        Expanded(child: _buildImageForPaged(context, spread.page2!, index)),
      ],
    );
  }

  Widget _buildImageForPaged(BuildContext context, PageUrl page, int index) {
    return Obx(() {
      final sourceController = Get.find<SourceController>();

      return Padding(
        padding: EdgeInsets.symmetric(
            vertical: widget.controller.spacedPages.value ? 8.0 : 0),
        child: Center(
          child: SubsamplingImageProvider(
            page: PageUrl(
              page.url,
              headers: (page.headers?.isEmpty ?? true)
                  ? {
                      'Referer': sourceController
                              .activeMangaSource.value?.baseUrl ??
                          ''
                    }
                  : page.headers,
            ),
            fit: widget.controller.fitToScreen.value
                ? BoxFit.fitWidth
                : BoxFit.contain,
            alignment: Alignment.center,
            cropBorders: widget.controller.cropImages.value,
            placeholder: _buildPageLoadingWidget(context, pageIndex: index, pageUrl: page.url),
          ),
        ),
      );
    });
  }


  Widget _buildPageLoadingWidget(
    BuildContext context, {
    required int pageIndex,
    required String pageUrl,
    double? progress,
  }) {
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
            Text('Loading page ${pageIndex + 1}$progressText...'),
          ],
        ),
      ),
    );
  }
}

