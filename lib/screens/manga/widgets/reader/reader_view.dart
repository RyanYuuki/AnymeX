import 'dart:math' as math;
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:anymex/screens/manga/widgets/reader/continuous_reader.dart';
import 'package:anymex/screens/manga/widgets/reader/display_refresh_host.dart';
import 'package:anymex/screens/manga/widgets/reader/reader_chapter_transition.dart';
import 'package:anymex/screens/manga/widgets/reader/reader_color_overlay.dart';
import 'package:anymex/screens/manga/widgets/reader/reader_page_actions_dialog.dart';
import 'package:anymex/widgets/subsampling_scale_image_view/subsampling_image_provider.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_progress.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';

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
  final DisplayRefreshHost _displayRefreshHost = DisplayRefreshHost();

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyPress);

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
    _displayRefreshHost.dispose();
    super.dispose();
  }

  bool _handleKeyPress(KeyEvent event) {
    return false;
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      widget.controller.handleMouseScroll(event.scrollDelta.dy);
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
          AnymeXProgressIndicator(),
          SizedBox(height: 16),
          AnymeXText('Loading pages...'),
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
            AnymeXText(
              'Failed to load chapter',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            AnymeXText(
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
                  label: const AnymeXText('Retry'),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.arrow_back),
                  label: const AnymeXText('Go Back'),
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

      Widget readerContent = isContinuous
          ? ContinuousReaderView(controller: widget.controller)
          : _buildPagedView();

      if (widget.controller.grayscaleEnabled.value) {
        readerContent = ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0,      0,      0,      1, 0,
          ]),
          child: readerContent,
        );
      } else if (widget.controller.invertColorsEnabled.value) {
        readerContent = ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            -1,  0,  0, 0, 255,
             0, -1,  0, 0, 255,
             0,  0, -1, 0, 255,
             0,  0,  0, 1,   0,
          ]),
          child: readerContent,
        );
      }

      if (widget.controller.colorFilterEnabled.value) {
        final colorValue = widget.controller.colorFilterValue.value;
        final blendModeIndex = widget.controller.colorFilterMode.value;
        final blendMode = _blendModeFromIndex(blendModeIndex);
        readerContent = ColorFiltered(
          colorFilter: ColorFilter.mode(Color(colorValue), blendMode),
          child: readerContent,
        );
      }

      return Stack(
        children: [
          Container(color: bgColor),
          readerContent,
          
          
          
          if (isContinuous)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapUp: (details) {
                  widget.controller.handleTap(details.globalPosition);
                },
                onLongPressStart: (details) {
                  if (widget.controller.longPressPageActionsEnabled.value) {
                    showReaderPageActionsDialog(context, widget.controller);
                  }
                },
              ),
            ),
          ReaderContentOverlay(controller: widget.controller),
          DisplayRefreshOverlay(host: _displayRefreshHost),
        ],
      );
    });
  }

  static BlendMode _blendModeFromIndex(int index) {
    const modes = [
      BlendMode.srcOver,
      BlendMode.multiply,
      BlendMode.screen,
      BlendMode.overlay,
      BlendMode.darken,
      BlendMode.lighten,
      BlendMode.colorDodge,
      BlendMode.colorBurn,
      BlendMode.hardLight,
      BlendMode.softLight,
      BlendMode.difference,
      BlendMode.exclusion,
      BlendMode.hue,
      BlendMode.saturation,
      BlendMode.color,
      BlendMode.luminosity,
    ];
    if (index >= 0 && index < modes.length) return modes[index];
    return BlendMode.srcOver;
  }

  Widget _buildPagedView() {
    
    
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
            child: PagedItemView(
              controller: widget.controller,
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
      final targetIdx = spread.isNextTransition
          ? ctrl.getNextChapterIndex(curIdx)
          : ctrl.getPrevChapterIndex(curIdx);
      final targetChapter = (targetIdx != -1) ? ctrl.chapterList[targetIdx] : null;

      final isLoading = targetChapter != null &&
          ctrl.loadingChapterLinks.contains(targetChapter.link);

      return ReaderChapterTransition(
        isNext: spread.isNextTransition,
        currentChapter: chapter,
        targetChapter: targetChapter,
        posterUrl: ctrl.media.poster,
        isLoading: isLoading,
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
      final ctrl = widget.controller;
      final sourceController = Get.find<SourceController>();

      final screenWidth = MediaQuery.sizeOf(context).width;
      final multiplier = ctrl.pageWidthMultiplier.value;
      final isFitToScreen = ctrl.fitToScreen.value;
      final isDesktop = screenWidth > 600;

      final double? calculatedWidth;
      if (isFitToScreen) {
        calculatedWidth = screenWidth * multiplier;
      } else {
        if (isDesktop) {
          calculatedWidth = math.min(screenWidth, 700.0) * multiplier;
        } else {
          calculatedWidth = multiplier != 1.0 ? screenWidth * multiplier : null;
        }
      }
      final fitMode = isFitToScreen ? BoxFit.fitWidth : BoxFit.contain;

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
            width: calculatedWidth,
            fit: fitMode,
            alignment: Alignment.center,
            cropBorders: ctrl.cropImages.value,
            placeholder: _buildPageLoadingWidget(context,
                pageIndex: index, pageUrl: page.url),
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
            AnymeXProgressIndicator(value: progress),
            const SizedBox(height: 8),
            AnymeXText('Loading page ${pageIndex + 1}$progressText...'),
          ],
        ),
      ),
    );
  }
}

class PagedItemView extends StatefulWidget {
  final Widget child;
  final ReaderController controller;

  const PagedItemView({
    super.key,
    required this.child,
    required this.controller,
  });

  @override
  State<PagedItemView> createState() => _PagedItemViewState();
}

class _PagedItemViewState extends State<PagedItemView>
    with SingleTickerProviderStateMixin {
  late final PhotoViewController _photoViewController;
  late final PhotoViewScaleStateController _photoViewScaleStateController;
  late final AnimationController _scaleAnimationController;
  late final Animation<double> _animation;

  Offset? _lastTapPosition;
  Offset _doubleTapPosition = Offset.zero;
  Alignment _scalePosition = Alignment.center;

  @override
  void initState() {
    super.initState();
    _photoViewController = PhotoViewController();
    _photoViewScaleStateController = PhotoViewScaleStateController();

    _scaleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _animation = Tween<double>(begin: 1.0, end: 2.5).animate(
      CurvedAnimation(
        parent: _scaleAnimationController,
        curve: Curves.easeOutCubic,
      ),
    )..addListener(() {
        _photoViewController.scale = _animation.value;
      });
  }

  @override
  void dispose() {
    _scaleAnimationController.dispose();
    _photoViewController.dispose();
    _photoViewScaleStateController.dispose();
    super.dispose();
  }

  Alignment _computeAlignmentByTapOffset(Offset offset, Size size) {
    return Alignment(
      (offset.dx - size.width / 2) / (size.width / 2),
      (offset.dy - size.height / 2) / (size.height / 2),
    );
  }

  void _toggleScale(Offset tapPosition) {
    if (!mounted) return;
    if (_scaleAnimationController.isAnimating) return;

    final currentScale = _photoViewController.scale ?? 1.0;
    if (currentScale <= 1.01) {
      final size = MediaQuery.sizeOf(context);
      _scalePosition = _computeAlignmentByTapOffset(tapPosition, size);
      if (_scaleAnimationController.isCompleted) {
        _scaleAnimationController.reset();
      }
      _scaleAnimationController.forward();
    } else if (currentScale >= 2.49) {
      _scaleAnimationController.reverse();
    } else {
      _photoViewScaleStateController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PhotoViewGestureDetectorScope(
      axis: widget.controller.readingDirection.value.axis,
      child: PhotoView.customChild(
        controller: _photoViewController,
        scaleStateController: _photoViewScaleStateController,
        basePosition: _scalePosition,
        minScale: PhotoViewComputedScale.contained * 1.0,
        maxScale: PhotoViewComputedScale.covered * 4.0,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: (details) => _lastTapPosition = details.globalPosition,
          onTap: () {
            if (_lastTapPosition != null) {
              widget.controller.handleTap(_lastTapPosition!);
            }
          },
          onDoubleTapDown: (details) {
            _doubleTapPosition = details.globalPosition;
          },
          onDoubleTap: () => _toggleScale(_doubleTapPosition),
          onLongPressStart: (details) {
            if (widget.controller.longPressPageActionsEnabled.value) {
              showReaderPageActionsDialog(context, widget.controller);
            }
          },
          child: widget.child,
        ),
      ),
    );
  }
}
