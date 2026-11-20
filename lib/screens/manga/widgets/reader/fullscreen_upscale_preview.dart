import 'dart:io';
import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:anymex/services/upscale/mode_chains.dart';
import 'package:anymex/services/upscale/page_upscale_service.dart';
import 'package:anymex/utils/extension_utils.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_progress.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/common/anymex_slider_m3.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RightSplitClipper extends CustomClipper<Rect> {
  final double splitRatio;

  const RightSplitClipper(this.splitRatio);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(
      size.width * splitRatio,
      0,
      size.width * (1.0 - splitRatio),
      size.height,
    );
  }

  @override
  bool shouldReclip(covariant RightSplitClipper oldClipper) =>
      oldClipper.splitRatio != splitRatio;
}

class FullscreenUpscalePreview extends StatefulWidget {
  final ReaderController controller;
  final int initialPageIndex;

  const FullscreenUpscalePreview({
    super.key,
    required this.controller,
    this.initialPageIndex = 0,
  });

  @override
  State<FullscreenUpscalePreview> createState() =>
      _FullscreenUpscalePreviewState();
}

class _FullscreenUpscalePreviewState extends State<FullscreenUpscalePreview> {
  double _splitRatio = 0.5;
  late int _previewPageIndex;
  Future<File?>? _previewFuture;
  int _lastPreviewPage = -1;
  String _lastFingerprint = '';

  @override
  void initState() {
    super.initState();
    final pagesCount = widget.controller.pageList.length;
    _previewPageIndex =
        pagesCount > 0 ? widget.initialPageIndex.clamp(0, pagesCount - 1) : 0;
    _triggerPreview();
  }

  void _triggerPreview() {
    final pages = widget.controller.pageList;
    if (pages.isEmpty || _previewPageIndex >= pages.length) {
      _previewFuture = null;
      return;
    }
    final page = pages[_previewPageIndex];
    final config = widget.controller.currentUpscaleConfig;
    if (_lastPreviewPage == _previewPageIndex &&
        _lastFingerprint == config.fingerprint) {
      return;
    }
    _lastPreviewPage = _previewPageIndex;
    _lastFingerprint = config.fingerprint;
    _previewFuture = PageUpscaleService.instance.upscaled(
      page,
      config,
      priority: 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pages = widget.controller.pageList;
    final hasPages = pages.isNotEmpty;
    final page = (hasPages && _previewPageIndex < pages.length)
        ? pages[_previewPageIndex]
        : null;
    final imageUrl = page?.url ?? widget.controller.media.poster;
    final headers = page != null ? getPageImageHeaders(page.headers) : null;

    _triggerPreview();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(colors, pages.length),
            Expanded(
              child: _buildComparisonArea(colors, imageUrl, headers),
            ),
            _buildBottomControls(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(ColorScheme colors, int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: Colors.black.withOpacity(0.8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: AnymeXText(
              'Upscale Comparison',
              size: 16,
              variant: TextVariant.bold,
              color: Colors.white,
            ),
          ),
          if (totalPages > 1) ...[
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded,
                  color: Colors.white, size: 24),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: _previewPageIndex > 0
                  ? () {
                      setState(() {
                        _previewPageIndex--;
                        _triggerPreview();
                      });
                    }
                  : null,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: AnymeXText(
                '${_previewPageIndex + 1} / $totalPages',
                size: 12,
                variant: TextVariant.semiBold,
                color: Colors.white,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded,
                  color: Colors.white, size: 24),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: _previewPageIndex < totalPages - 1
                  ? () {
                      setState(() {
                        _previewPageIndex++;
                        _triggerPreview();
                      });
                    }
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildComparisonArea(
    ColorScheme colors,
    String imageUrl,
    Map<String, String>? headers,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final splitX = w * _splitRatio;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (details) {
            setState(() {
              _splitRatio = (details.localPosition.dx / w).clamp(0.02, 0.98);
            });
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl.isNotEmpty)
                AnymeXImage(
                  imageUrl: imageUrl,
                  headers: headers,
                  fit: BoxFit.contain,
                  width: w,
                  height: h,
                  radius: 0,
                )
              else
                Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: 64,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              if (imageUrl.isNotEmpty)
                ClipRect(
                  clipper: RightSplitClipper(_splitRatio),
                  child: FutureBuilder<File?>(
                    future: _previewFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done &&
                          snapshot.data != null) {
                        return Image.file(
                          snapshot.data!,
                          fit: BoxFit.contain,
                          width: w,
                          height: h,
                        );
                      }
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          AnymeXImage(
                            imageUrl: imageUrl,
                            headers: headers,
                            fit: BoxFit.contain,
                            width: w,
                            height: h,
                            radius: 0,
                          ),
                          if (snapshot.connectionState ==
                              ConnectionState.waiting)
                            const Center(
                              child: AnymeXProgressIndicator(),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              Positioned(
                left: splitX - 1.0,
                top: 0,
                bottom: 0,
                width: 2.0,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: splitX - 16,
                top: (h / 2) - 16,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.swap_horiz_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              Positioned(
                left: 12,
                top: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: const AnymeXText(
                    'Original',
                    size: 11,
                    variant: TextVariant.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Obx(() {
                  final activeMode =
                      widget.controller.selectedUpscalerShader.value;
                  final preset = superResolutionPresets.firstWhere(
                    (p) => p.id == activeMode,
                    orElse: () => superResolutionPresets.first,
                  );
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black45,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: AnymeXText(
                      'Super Res • ${preset.title}',
                      size: 11,
                      variant: TextVariant.bold,
                      color: Colors.white,
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomControls(ColorScheme colors) {
    return Container(
      color: Colors.black.withOpacity(0.85),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Obx(() {
                  final sharpness = widget.controller.upscalerSharpness.value;
                  return Row(
                    children: [
                      const Icon(
                        Icons.tune_rounded,
                        size: 18,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 8),
                      AnymeXText(
                        '${(sharpness * 100).toInt()}%',
                        size: 12,
                        variant: TextVariant.bold,
                        color: Colors.white,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: AnymeXSliderM3(
                            value: sharpness,
                            min: 0.5,
                            max: 2.0,
                            divisions: 15,
                            onChanged: (v) {
                              widget.controller.setUpscalerSharpness(v);
                              setState(() => _triggerPreview());
                            },
                            theme: AnymeXSliderM3Theme(
                              activeColor: colors.primary,
                              inactiveColor: Colors.white24,
                              trackHeight: 24,
                              thumbHeight: 30,
                              thumbWidth: 4,
                              outerRadius: 8,
                              innerRadius: 2,
                              thumbCornerRadius: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
              const SizedBox(width: 8),
              Obx(() {
                final denoise = widget.controller.upscalerDenoise.value;
                return InkWell(
                  onTap: () {
                    widget.controller.toggleUpscalerDenoise();
                    setState(() => _triggerPreview());
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: denoise
                          ? colors.primary.withOpacity(0.2)
                          : Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: denoise ? colors.primary : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.cleaning_services_rounded,
                          size: 15,
                          color: denoise ? colors.primary : Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        AnymeXText(
                          'Artifact Suppression',
                          size: 11,
                          variant: TextVariant.semiBold,
                          color: denoise ? colors.primary : Colors.white70,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 10),
          Obx(() {
            final currentShader =
                widget.controller.selectedUpscalerShader.value;

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: superResolutionPresets.map((preset) {
                  final isSelected = currentShader == preset.id;
                  final IconData icon = switch (preset.id) {
                    'Manga: Crisp Lines' => Icons.auto_stories_rounded,
                    'Webtoon: Clean & Vibrant' => Icons.palette_rounded,
                    _ => Icons.flash_on_rounded,
                  };

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () {
                        widget.controller.setUpscalerShader(preset.id);
                        setState(() => _triggerPreview());
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colors.primary
                              : Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? colors.primary
                                : Colors.white.withOpacity(0.12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              icon,
                              size: 14,
                              color: isSelected ? Colors.white : Colors.white70,
                            ),
                            const SizedBox(width: 6),
                            AnymeXText(
                              preset.title,
                              size: 12,
                              variant: TextVariant.bold,
                              color: isSelected ? Colors.white : Colors.white70,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }),
        ],
      ),
    );
  }
}
