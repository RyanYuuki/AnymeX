import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:anymex/widgets/subsampling_scale_image_view/subsampling_image_provider.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:anymex_extension_runtime_bridge/Models/Page.dart';
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
      final sourceController = Get.find<SourceController>();

      return Padding(
        padding:
            EdgeInsets.symmetric(vertical: ctrl.spacedPages.value ? 8.0 : 0),
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
            fit: ctrl.fitToScreen.value ? BoxFit.fitWidth : BoxFit.contain,
            alignment: Alignment.center,
            cropBorders: ctrl.cropImages.value,
            placeholder: _buildPlaceholder(context, index, page.url),
          ),
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
