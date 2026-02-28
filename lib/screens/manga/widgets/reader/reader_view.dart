import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:anymex/screens/manga/widgets/reader/display_refresh_host.dart';
import 'package:anymex/screens/manga/widgets/reader/reader_color_overlay.dart';
import 'package:anymex/screens/manga/widgets/reader/reader_page_actions_dialog.dart';
import 'package:anymex/utils/image_cropper.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

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

        if (currentScale == _doubleTapScales) {
          _scalePosition = _computeAlignmentByTapOffset(tapPosition);

          if (_scaleAnimationController.isCompleted) {
            _scaleAnimationController.reset();
          }

          _animation =
              Tween(begin: _doubleTapScales, end: _doubleTapScales)
                  .animate(
            CurvedAnimation(
                curve: Curves.ease, parent: _scaleAnimationController),
          );
          _animation
              .addListener(() => _photoViewController.scale = _animation.value);

          _scaleAnimationController.forward();
          return;
        }

        if (currentScale >= _doubleTapScales) {
          _animation =
              Tween(begin: currentScale, end: _doubleTapScales).animate(
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
    return Stack(
      children: [
        Container(color: widget.controller.readerTheme.value.backgroundColor),
        PhotoViewGallery.builder(
          itemCount: 1,
          builder: (_, e) => PhotoViewGalleryPageOptions.customChild(
            controller: _photoViewController,
            scaleStateController: _photoViewScaleStateController,
            basePosition: _scalePosition,
            minScale: PhotoViewComputedScale.contained * 1.0,
            maxScale: PhotoViewComputedScale.covered * 5.0,
            onScaleEnd: _onScaleEnd,
            gestureDetectorBehavior: HitTestBehavior.translucent,
            child: GestureDetector(
              onTapDown: (details) => _lastTapPosition = details.globalPosition,
              onTap: () {
                if (_lastTapPosition != null) {
                  widget.controller.handleTap(_lastTapPosition!);
                }
              },
              onLongPressStart: (details) {
                showReaderPageActionsDialog(context, widget.controller);
              },
              onDoubleTapDown: (details) {
                _toggleScale(details.globalPosition);
              },
              onDoubleTap: () {},
              child: widget.controller.readingLayout.value ==
                      MangaPageViewMode.continuous
                  ? _buildContinuousView()
                  : _buildPagedView(),
            ),
          ),
          scrollPhysics: const NeverScrollableScrollPhysics(),
          enableRotation: false,
          backgroundDecoration: const BoxDecoration(color: Colors.transparent),
        ),
        ReaderContentOverlay(controller: widget.controller),
        Obx(() {
          final isGrayscale = widget.controller.grayscale.value;
          final isInverted = widget.controller.inverted.value;
          if (!isGrayscale && !isInverted) return const SizedBox.shrink();

          return IgnorePointer(
            child: ColorFiltered(
              colorFilter: ColorFilter.matrix([
                if (isGrayscale) ...[
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0, 0, 0, 1, 0,
                ] else if (isInverted) ...[
                  -1, 0, 0, 0, 255,
                  0, -1, 0, 0, 255,
                  0, 0, -1, 0, 255,
                  0, 0, 0, 1, 0,
                ]
              ]),
              child: Container(color: Colors.transparent),
            ),
          );
        }),
        DisplayRefreshOverlay(host: _displayRefreshHost),
      ],
    );
  }

  Widget _buildContinuousView() {
    return ScrollablePositionedList.builder(
      itemCount: widget.controller.spreads.length,
      itemScrollController: widget.controller.itemScrollController,
      scrollOffsetController: widget.controller.scrollOffsetController,
      itemPositionsListener: widget.controller.itemPositionsListener,
      scrollOffsetListener: widget.controller.scrollOffsetListener,
      initialScrollIndex: (widget.controller.currentPageIndex.value - 1)
          .clamp(0, widget.controller.spreads.length - 1),
      physics: const ClampingScrollPhysics(),
      scrollDirection: widget.controller.readingDirection.value.axis,
      reverse: widget.controller.readingDirection.value.reversed,
      itemBuilder: (context, index) {
        return _buildSpread(context, widget.controller.spreads[index], index);
      },
    );
  }

  Widget _buildPagedView() {
    return PreloadPageView.builder(
      itemCount: widget.controller.spreads.length,
      controller: widget.controller.pageController,
      preloadPagesCount: widget.controller.preloadPages.value,
      physics: const ClampingScrollPhysics(),
      scrollDirection: widget.controller.readingDirection.value.axis,
      reverse: widget.controller.readingDirection.value.reversed,
      onPageChanged: (index) {
        widget.controller.onPageChanged(index);
        if (widget.controller.displayRefreshEnabled.value) {
          _displayRefreshHost.flash();
        }
      },
      itemBuilder: (context, index) {
        return _buildSpread(context, widget.controller.spreads[index], index);
      },
    );
  }

  Widget _buildSpread(BuildContext context, ReaderPage spread, int index) {
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
    final size = MediaQuery.of(context).size;
    final isContinuous =
        widget.controller.readingLayout.value == MangaPageViewMode.continuous;

    return Obx(() {
      return Padding(
        padding: EdgeInsets.symmetric(
            vertical: widget.controller.spacedPages.value ? 8.0 : 0),
        child: Center(
          child: widget.controller.cropImages.value
              ? CroppedNetworkImage(
                  url: page.url,
                  headers: (page.headers?.isEmpty ?? true)
                      ? {
                          'Referer': sourceController
                                  .activeMangaSource.value?.baseUrl ??
                              ''
                        }
                      : page.headers,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  cropThreshold: 30,
                )
              : ExtendedImage.network(
                  page.url,
                  cacheMaxAge: Duration(
                      days: PlayerUiKeys.cacheDays.get<int>(7)),
                  mode: ExtendedImageMode.none,
                  gaplessPlayback: true,
                  headers: (page.headers?.isEmpty ?? true)
                      ? {
                          'Referer': sourceController
                                  .activeMangaSource.value?.baseUrl ??
                              ''
                        }
                      : page.headers,
                  fit: BoxFit.contain,
                  constraints: isContinuous
                      ? BoxConstraints(
                          maxWidth:
                              500 * widget.controller.pageWidthMultiplier.value)
                      : null,
                  cache: true,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.medium,
                  enableLoadState: true,
                  loadStateChanged: (ExtendedImageState state) {
                    switch (state.extendedImageLoadState) {
                      case LoadState.loading:
                        final progress = (state.loadingProgress
                                    ?.cumulativeBytesLoaded ??
                                0) /
                            (state.loadingProgress?.expectedTotalBytes ?? 1)
                                .toDouble();
                        return SizedBox(
                          height: size.height,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnymexProgressIndicator(value: progress),
                                const SizedBox(height: 8),
                                Text('Loading page ${index + 1}...'),
                              ],
                            ),
                          ),
                        );

                      case LoadState.failed:
                        return SizedBox(
                          height: size.height,
                          child: Container(
                            color: Colors.grey.opaque(0.1),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image_outlined,
                                  size: 48,
                                  color: Colors.grey.opaque(0.7),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Failed to load page ${index + 1}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    state.reLoadImage();
                                  },
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: const Text('Retry'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    textStyle: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );

                      case LoadState.completed:
                        return state.completedWidget;
                    }
                  },
                ),
        ),
      );
    });
  }
}
