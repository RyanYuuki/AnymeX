import 'dart:io';
import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:anymex/services/upscale/mode_chains.dart';
import 'package:anymex/services/upscale/page_upscale_service.dart';
import 'package:anymex/screens/manga/widgets/reader/fullscreen_upscale_preview.dart';
import 'package:anymex/utils/extension_utils.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_progress.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:anymex/l10n/l10n_extension.dart';

class _RightSplitClipper extends CustomClipper<Rect> {
  final double splitRatio;

  const _RightSplitClipper(this.splitRatio);

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
  bool shouldReclip(covariant _RightSplitClipper oldClipper) =>
      oldClipper.splitRatio != splitRatio;
}

class UpscaleSettingsPage extends StatefulWidget {
  final ReaderController controller;

  const UpscaleSettingsPage({super.key, required this.controller});

  @override
  State<UpscaleSettingsPage> createState() => _UpscaleSettingsPageState();
}

class _UpscaleSettingsPageState extends State<UpscaleSettingsPage> {
  double _splitRatio = 0.5;
  int _previewPageIndex = 0;
  Future<File?>? _previewFuture;
  int _lastPreviewPage = -1;
  String _lastFingerprint = '';

  @override
  void initState() {
    super.initState();
    final pagesCount = widget.controller.pageList.length;
    final current = widget.controller.currentPageIndex.value - 1;
    _previewPageIndex = pagesCount > 0 ? current.clamp(0, pagesCount - 1) : 0;
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

  void _openFullscreenPreview(BuildContext context) {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => FullscreenUpscalePreview(
          controller: widget.controller,
          initialPageIndex: _previewPageIndex,
        ),
      ),
    )
        .then((_) {
      if (mounted) {
        setState(() => _triggerPreview());
      }
    });
  }

  Widget _buildPreview(BuildContext context) {
    final colors = context.colors;
    final pages = widget.controller.pageList;
    final hasPages = pages.isNotEmpty;
    final page = (hasPages && _previewPageIndex < pages.length)
        ? pages[_previewPageIndex]
        : null;
    final imageUrl = page?.url ?? widget.controller.media.poster;
    final headers = page != null ? getPageImageHeaders(page.headers) : null;

    _triggerPreview();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AnymeXText(
                context.l10n.interactivePreview,
                size: 14,
                variant: TextVariant.bold,
                color: colors.onSurface,
              ),
              if (hasPages)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: AnymeXText(
                        context.l10n.page2((_previewPageIndex + 1).toString(), (pages.length).toString()),
                        size: 11,
                        variant: TextVariant.semiBold,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      onPressed: _previewPageIndex < pages.length - 1
                          ? () {
                              setState(() {
                                _previewPageIndex++;
                                _triggerPreview();
                              });
                            }
                          : null,
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Iconsax.maximize_4, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      tooltip: context.l10n.fullscreenPreview,
                      onPressed: () => _openFullscreenPreview(context),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              const h = 240.0;
              final splitX = w * _splitRatio;

              return ClipRRect(
                borderRadius: BorderRadius.circular(20),
                clipBehavior: Clip.antiAliasWithSaveLayer,
                child: Container(
                  height: h,
                  width: w,
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colors.outline.withOpacity(0.12),
                    ),
                  ),
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
                            size: 48,
                            color: colors.onSurface.withOpacity(0.3),
                          ),
                        ),
                      if (imageUrl.isNotEmpty)
                        ClipRect(
                          clipper: _RightSplitClipper(_splitRatio),
                          child: FutureBuilder<File?>(
                            future: _previewFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                      ConnectionState.done &&
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
                                color: Colors.black45,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: splitX - 17.0,
                        top: (h / 2) - 17.0,
                        width: 34.0,
                        height: 34.0,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onHorizontalDragUpdate: (details) {
                            setState(() {
                              _splitRatio = (_splitRatio + (details.delta.dx / w))
                                  .clamp(0.05, 0.95);
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.35),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.compare_arrows_rounded,
                              size: 20,
                              color: Colors.grey.shade900,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: AnymeXText(context.l10n.original,
                            size: 10,
                            variant: TextVariant.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primary.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Obx(() {
                            final shader =
                                widget.controller.selectedUpscalerShader.value;
                            final preset = superResolutionPresets.firstWhere(
                              (p) => p.id == shader,
                              orElse: () => superResolutionPresets.first,
                            );
                            return AnymeXText(
                              context.l10n.superRes(preset.title),
                              size: 10,
                              variant: TextVariant.bold,
                              color: colors.onPrimary,
                            );
                          }),
                        ),
                      ),
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onHorizontalDragUpdate: (details) {
                            setState(() {
                              _splitRatio = (_splitRatio + (details.delta.dx / w))
                                  .clamp(0.05, 0.95);
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPresetsSection(BuildContext context) {
    return Obx(() {
      final currentShader = widget.controller.selectedUpscalerShader.value;

      return AnymeXSectionBuilder(
        title: context.l10n.enhancementPreset,
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
        children: superResolutionPresets.map((preset) {
          final isSelected = currentShader == preset.id;
          final IconData icon = switch (preset.id) {
            'Manga: Crisp Lines' => Icons.auto_stories_rounded,
            'Webtoon: Clean & Vibrant' => Icons.palette_rounded,
            _ => Icons.flash_on_rounded,
          };

          return AnymeXTile.radio(
            icon: icon,
            title: preset.title,
            subtitle: preset.description,
            selected: isSelected,
            onTap: () {
              widget.controller.setUpscalerShader(preset.id);
              setState(() => _triggerPreview());
            },
          );
        }).toList(),
      );
    });
  }

  Widget _buildTuningSection(BuildContext context) {
    return Obx(() {
      final sharpness = widget.controller.upscalerSharpness.value;
      final denoise = widget.controller.upscalerDenoise.value;

      return AnymeXSectionBuilder(
        title: context.l10n.fineTuning,
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
        children: [
          AnymeXTile.slider(
            icon: Icons.tune_rounded,
            title: context.l10n.enhancementStrength,
            subtitle: context.l10n.strength(((sharpness * 100).toInt()).toString()),
            value: sharpness,
            min: 0.5,
            max: 2.0,
            divisions: 15,
            onChanged: (v) {
              widget.controller.setUpscalerSharpness(v);
              setState(() => _triggerPreview());
            },
          ),
          AnymeXTile.toggle(
            icon: Icons.cleaning_services_rounded,
            title: context.l10n.artifactSuppression,
            subtitle: context.l10n.cleanJpegCompressionRingingAroundLinework,
            value: denoise,
            onChanged: (_) {
              widget.controller.toggleUpscalerDenoise();
              setState(() => _triggerPreview());
            },
          ),
        ],
      );
    });
  }

  Widget _buildCacheSection(BuildContext context) {
    return AnymeXSectionBuilder(
      title: context.l10n.cache,
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      children: [
        FutureBuilder<int>(
          future: PageUpscaleService.instance.cacheBytes(),
          builder: (context, snapshot) {
            final bytes = snapshot.data ?? 0;
            final mb = (bytes / (1024 * 1024)).toStringAsFixed(1);
            return AnymeXTile(
              icon: Iconsax.folder,
              title: context.l10n.cacheSize,
              subtitle: context.l10n.mbStoredOnDisk(mb.toString()),
              trailing: IconButton(
                icon: const Icon(Iconsax.trash, size: 20),
                onPressed: () async {
                  await PageUpscaleService.instance.clearCache();
                  setState(() => _triggerPreview());
                },
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isEnabled = widget.controller.upscalingEnabled.value;

      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPreview(context),
            const SizedBox(height: 4),
            AnymeXSectionBuilder(
              margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
              children: [
                AnymeXTile.toggle(
                  icon: Icons.auto_awesome_rounded,
                  title: context.l10n.superResolution,
                  subtitle:
                      context.l10n.highDefinitionEdgeSharpeningDetail,
                  value: isEnabled,
                  onChanged: (_) {
                    widget.controller.toggleUpscaling();
                    setState(() => _triggerPreview());
                  },
                ),
              ],
            ),
            if (isEnabled) ...[
              _buildPresetsSection(context),
              _buildTuningSection(context),
              _buildCacheSection(context),
            ],
            const SizedBox(height: 16),
          ],
        ),
      );
    });
  }
}
