import 'dart:io';

import 'package:anymex/utils/logger.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/screens/manga/controller/reader_controller.dart';
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
  Alignment _scalePosition = Alignment.center;
  bool _isCtrlPressed = false;
  late AnimationController _scaleAnimationController;
  late Animation<double> _animation;
  final List<double> _doubleTapScales = [1.0, 2.0];

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
    ever(widget.controller.readingLayout, (_) => setState(() {}));
    ever(widget.controller.readingDirection, (_) => setState(() {}));
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyPress);
    _photoViewController.dispose();
    _photoViewScaleStateController.dispose();
    _scaleAnimationController.dispose();
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
    if (event is PointerScrollEvent && _isCtrlPressed) {
      final delta = event.scrollDelta.dy;
      final currentScale = _photoViewController.scale ?? 1.0;
      final newScale = (currentScale - (delta * 0.002)).clamp(1.0, 5.0);

      if (newScale != currentScale) {
        _photoViewController.scale = newScale;
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
          // Zoom in to 2x
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
          // Zoom out to 1x
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

        // Fallback reset
        _photoViewScaleStateController.reset();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: _handlePointerSignal,
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
              color: Colors.red.withOpacity(0.7),
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
    return PhotoViewGallery.builder(
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
          onTap: () => widget.controller.toggleControls(),
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
      backgroundDecoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
    );
  }

  Widget _buildContinuousView() {
    return ScrollablePositionedList.builder(
      itemCount: widget.controller.pageList.length,
      itemScrollController: widget.controller.itemScrollController,
      itemPositionsListener: widget.controller.itemPositionsListener,
      scrollOffsetListener: widget.controller.scrollOffsetListener,
      initialScrollIndex: (widget.controller.currentPageIndex.value - 1)
          .clamp(0, widget.controller.pageList.length - 1),
      physics: const ClampingScrollPhysics(),
      scrollDirection: widget.controller.readingDirection.value.axis,
      reverse: widget.controller.readingDirection.value.reversed,
      itemBuilder: (context, index) {
        if (!Platform.isAndroid && !Platform.isIOS) {
          return Column(
            children: [
              _buildImage(context, widget.controller.pageList[index], index),
            ],
          );
        }
        return _buildImage(context, widget.controller.pageList[index], index);
      },
    );
  }

  Widget _buildPagedView() {
    return PreloadPageView.builder(
      itemCount: widget.controller.pageList.length,
      controller: widget.controller.pageController,
      preloadPagesCount: widget.controller.preloadPages.value,
      physics: const ClampingScrollPhysics(),
      scrollDirection: widget.controller.readingDirection.value.axis,
      reverse: widget.controller.readingDirection.value.reversed,
      onPageChanged: widget.controller.onPageChanged,
      itemBuilder: (context, index) {
        return _buildImageForPaged(
            context, widget.controller.pageList[index], index);
      },
    );
  }

  Widget _buildImage(BuildContext context, PageUrl page, int index) {
    final size = MediaQuery.of(context).size;

    return Obx(() {
      return Container(
        padding: EdgeInsets.symmetric(
            vertical: widget.controller.spacedPages.value ? 8.0 : 0),
        child: ExtendedImage.network(
          page.url,
          cacheMaxAge: Duration(
              days: settingsController.preferences
                  .get('cache_days', defaultValue: 7)),
          mode: ExtendedImageMode.none,
          gaplessPlayback: true,
          cache: true,
          headers: (page.headers?.isEmpty ?? true)
              ? {
                  'Referer':
                      sourceController.activeMangaSource.value?.baseUrl ?? ''
                }
              : page.headers,
          fit: BoxFit.contain,
          alignment: Alignment.center,
          constraints: BoxConstraints(
            maxWidth: 500 * widget.controller.pageWidthMultiplier.value,
          ),
          filterQuality: FilterQuality.medium,
          enableLoadState: true,
          loadStateChanged: (ExtendedImageState state) {
            switch (state.extendedImageLoadState) {
              case LoadState.loading:
                final progress =
                    (state.loadingProgress?.cumulativeBytesLoaded ?? 0) /
                        (state.loadingProgress?.expectedTotalBytes ?? 1)
                            .toDouble();
                return SizedBox(
                  width: size.width,
                  height: 200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnymexProgressIndicator(
                          value: progress,
                        ),
                        const SizedBox(height: 8),
                        Text('Loading page ${index + 1}...'),
                      ],
                    ),
                  ),
                );

              case LoadState.failed:
                return Container(
                  width: size.width,
                  height: 200,
                  color: Colors.grey.withOpacity(0.1),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image_outlined,
                        size: 48,
                        color: Colors.grey.withOpacity(0.7),
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
                          Logger.i(state.completedWidget.toString());
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
                );

              case LoadState.completed:
                return state.completedWidget;
            }
          },
        ),
      );
    });
  }

  Widget _buildImageForPaged(BuildContext context, PageUrl page, int index) {
    final size = MediaQuery.of(context).size;

    return Obx(() {
      return Padding(
        padding: EdgeInsets.symmetric(
            vertical: widget.controller.spacedPages.value ? 8.0 : 0),
        child: Center(
          child: ExtendedImage.network(
            page.url,
            cacheMaxAge: Duration(
                days: settingsController.preferences
                    .get('cache_days', defaultValue: 7)),
            mode: ExtendedImageMode.none,
            gaplessPlayback: true,
            headers: (page.headers?.isEmpty ?? true)
                ? {
                    'Referer':
                        sourceController.activeMangaSource.value?.baseUrl ?? ''
                  }
                : page.headers,
            fit: BoxFit.contain,
            cache: true,
            alignment: Alignment.center,
            filterQuality: FilterQuality.medium,
            enableLoadState: true,
            loadStateChanged: (ExtendedImageState state) {
              switch (state.extendedImageLoadState) {
                case LoadState.loading:
                  final progress =
                      (state.loadingProgress?.cumulativeBytesLoaded ?? 0) /
                          (state.loadingProgress?.expectedTotalBytes ?? 1)
                              .toDouble();
                  return SizedBox.fromSize(
                    size: Size(size.width, size.height),
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
                  return SizedBox.fromSize(
                    size: Size(size.width, size.height),
                    child: Container(
                      color: Colors.grey.withOpacity(0.1),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image_outlined,
                            size: 48,
                            color: Colors.grey.withOpacity(0.7),
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
                              Logger.i(state.completedWidget.toString());
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
