import 'dart:io';

import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:anymex/utils/image_cropper.dart';
import 'package:anymex/utils/lanczos_image.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:anymex_extension_runtime_bridge/Models/Page.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ContinuousReaderView extends StatefulWidget {
  final ReaderController controller;

  const ContinuousReaderView({super.key, required this.controller});

  @override
  State<ContinuousReaderView> createState() => ContinuousReaderViewState();
}

class ContinuousReaderViewState extends State<ContinuousReaderView> {
  late List<ReaderPage> _spreads;
  late Axis _scrollDirection;
  late bool _reverse;

  @override
  void initState() {
    super.initState();
    _spreads = widget.controller.spreads;
    _scrollDirection = widget.controller.readingDirection.value.axis;
    _reverse = widget.controller.readingDirection.value.reversed;
  }

  @override
  void didUpdateWidget(ContinuousReaderView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newDirection = widget.controller.readingDirection.value.axis;
    final newReverse = widget.controller.readingDirection.value.reversed;
    if (!identical(_spreads, widget.controller.spreads) ||
        _scrollDirection != newDirection ||
        _reverse != newReverse) {
      setState(() {
        _spreads = widget.controller.spreads;
        _scrollDirection = newDirection;
        _reverse = newReverse;
      });
    }
  }

  Widget _buildSpread(BuildContext context, ReaderPage spread, int index) {
    if (!spread.isSpread) {
      return _buildImage(context, spread.page1!, index);
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(child: _buildImage(context, spread.page1!, index)),
        Expanded(child: _buildImage(context, spread.page2!, index)),
      ],
    );
  }

  Widget _buildImage(BuildContext context, PageUrl page, int index) {
    return Obx(() {
      final ctrl = widget.controller;
      final filterQualityIndex = ctrl.imageFilterQuality.value;
      final isLanczos = filterQualityIndex == 4;
      final filterQuality = switch (filterQualityIndex) {
        0 => FilterQuality.none,
        1 => FilterQuality.low,
        3 => FilterQuality.high,
        _ => FilterQuality.medium,
      };

      final continuousConstraints = !ctrl.fitToScreen.value
          ? BoxConstraints(maxWidth: 500 * ctrl.pageWidthMultiplier.value)
          : null;

      final sourceController = Get.find<SourceController>();

      return Padding(
        padding:
            EdgeInsets.symmetric(vertical: ctrl.spacedPages.value ? 8.0 : 0),
        child: Center(
          child: ctrl.cropImages.value
              ? (page.url.startsWith('http')
                  ? CroppedNetworkImage(
                      url: page.url,
                      headers: (page.headers?.isEmpty ?? true)
                          ? {
                              'Referer': sourceController
                                      .activeMangaSource.value?.baseUrl ??
                                  ''
                            }
                          : page.headers,
                      fit: ctrl.fitToScreen.value
                          ? BoxFit.fitWidth
                          : BoxFit.contain,
                      alignment: Alignment.center,
                      cropThreshold: 30,
                      placeholder: _buildPlaceholder(context, index, page.url),
                    )
                  : Image.file(
                      File(page.url),
                      fit: ctrl.fitToScreen.value
                          ? BoxFit.fitWidth
                          : BoxFit.contain,
                      alignment: Alignment.center,
                    ))
              : isLanczos
                  ? (page.url.startsWith('http')
                      ? LanczosNetworkImage(
                          url: page.url,
                          headers: (page.headers?.isEmpty ?? true)
                              ? {
                                  'Referer': sourceController
                                          .activeMangaSource.value?.baseUrl ??
                                      ''
                                }
                              : page.headers,
                          fit: ctrl.fitToScreen.value
                              ? BoxFit.fitWidth
                              : BoxFit.contain,
                          alignment: Alignment.center,
                          constraints: continuousConstraints,
                          placeholder:
                              _buildPlaceholder(context, index, page.url),
                        )
                      : LanczosFileImage(
                          path: page.url,
                          fit: ctrl.fitToScreen.value
                              ? BoxFit.fitWidth
                              : BoxFit.contain,
                          alignment: Alignment.center,
                          constraints: continuousConstraints,
                          placeholder:
                              _buildPlaceholder(context, index, page.url),
                        ))
                  : (page.url.startsWith('http')
                      ? ExtendedImage.network(
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
                          fit: ctrl.fitToScreen.value
                              ? BoxFit.fitWidth
                              : BoxFit.contain,
                          constraints: continuousConstraints,
                          cache: true,
                          alignment: Alignment.center,
                          filterQuality: filterQuality,
                          enableLoadState: true,
                          loadStateChanged: (ExtendedImageState state) {
                            switch (state.extendedImageLoadState) {
                              case LoadState.loading:
                                return _buildPlaceholder(
                                  context,
                                  index,
                                  page.url,
                                  progress: state.loadingProgress
                                              ?.expectedTotalBytes !=
                                          null
                                      ? (state.loadingProgress!
                                                  .cumulativeBytesLoaded /
                                              state.loadingProgress!
                                                  .expectedTotalBytes!)
                                          .clamp(0.0, 1.0)
                                      : null,
                                );
                              case LoadState.failed:
                                return AspectRatio(
                                  aspectRatio:
                                      ctrl.pageAspectRatios[page.url] ?? 0.65,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Text('Failed to load image',
                                            style: TextStyle(
                                                fontFamily: 'Poppins-Bold')),
                                        const SizedBox(height: 8),
                                        ElevatedButton.icon(
                                          onPressed: () => state.reLoadImage(),
                                          icon: const Icon(Icons.refresh,
                                              size: 16),
                                          label: const Text('Retry'),
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            textStyle:
                                                const TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              case LoadState.completed:
                                final image = state.extendedImageInfo?.image;
                                if (image != null) {
                                  ctrl.pageAspectRatios[page.url] =
                                      image.width / image.height;
                                }
                                return state.completedWidget;
                            }
                          },
                        )
                      : ExtendedImage.file(
                          File(page.url),
                          fit: ctrl.fitToScreen.value
                              ? BoxFit.fitWidth
                              : BoxFit.contain,
                          constraints: continuousConstraints,
                          alignment: Alignment.center,
                          filterQuality: filterQuality,
                          enableLoadState: true,
                          loadStateChanged: (ExtendedImageState state) {
                            if (state.extendedImageLoadState ==
                                LoadState.completed) {
                              final image = state.extendedImageInfo?.image;
                              if (image != null) {
                                ctrl.pageAspectRatios[page.url] =
                                    image.width / image.height;
                              }
                            }
                            return state.completedWidget;
                          },
                        )),
        ),
      );
    });
  }

  Widget _buildPlaceholder(BuildContext context, int pageIndex, String pageUrl,
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
            Text('Loading page ${pageIndex + 1}$progressText...'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initialIndex = (widget.controller.currentPageIndex.value - 1)
        .clamp(0, _spreads.length - 1);

    return ScrollablePositionedList.builder(
      key: ValueKey(identityHashCode(_spreads)),
      itemCount: _spreads.length,
      itemScrollController: widget.controller.itemScrollController,
      scrollOffsetController: widget.controller.scrollOffsetController,
      itemPositionsListener: widget.controller.itemPositionsListener,
      scrollOffsetListener: widget.controller.scrollOffsetListener,
      initialScrollIndex: initialIndex,
      physics: const ClampingScrollPhysics(),
      scrollDirection: _scrollDirection,
      reverse: _reverse,
      itemBuilder: (context, index) {
        return _buildSpread(context, _spreads[index], index);
      },
    );
  }
}
