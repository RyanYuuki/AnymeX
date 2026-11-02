import 'dart:ui';

import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/utils/fallback/fallback_anime.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anime/media_header.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/common/baked_blur_image.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class SettingsUiDetails extends StatefulWidget {
  const SettingsUiDetails({super.key});

  @override
  State<SettingsUiDetails> createState() => _SettingsUiDetailsState();
}

class _SettingsUiDetailsState extends State<SettingsUiDetails> {
  final settings = Get.find<Settings>();

  final blurAmount = UISettingsKeys.detailsBlurAmount.get<double>(20.0).obs;
  final backdropBrightness =
      UISettingsKeys.detailsBackdropBrightness.get<double>(1.0).obs;

  Media get _sampleMedia {
    final base = trendingAnimes.firstWhereOrNull(
            (m) => m.cover != null && m.cover!.isNotEmpty) ??
        popularAnimes.first;
    base.studios = (base.studios != null && base.studios!.isNotEmpty)
        ? base.studios
        : ['Science SARU'];
    base.status = (base.status.isNotEmpty) ? base.status : 'RELEASING';
    return base;
  }

  @override
  Widget build(BuildContext context) {
    return AnymeXScaffold(
      showHeader: true,
      headerTitle: 'Details Page',
      body: Builder(
        builder: (ctx) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              16.0, AnymeXHeaderScope.of(ctx), 16.0, 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPreviewHeader(context),
              const SizedBox(height: 10),
              _buildLivePreviewCard(context),
              const SizedBox(height: 24),
              AnymeXSectionBuilder(
                title: 'Backdrop & Scope',
                children: [
                  Obx(
                    () => AnymeXTile.pills<int>(
                      icon: Icons.blur_on_rounded,
                      title: 'Blur Style',
                      value: settings.detailsBlurStyle,
                      options: const [0, 1],
                      optionLabelTransformer: (val) =>
                          val == 1 ? 'Fluid Mesh' : 'Gaussian',
                      optionDescriptionTransformer: (val) => val == 1
                          ? 'BitChord-style fluid ambient mesh with organic color blooming.'
                          : 'Standard smooth frosted blur.',
                      onChanged: (val) {
                        settings.detailsBlurStyle = val;
                      },
                    ),
                  ),
                  Obx(() {
                    final isMesh = settings.detailsBlurStyle == 1;
                    return AnymeXTile.pills<bool>(
                      icon: Icons.blur_linear_rounded,
                      title: 'Blur Mechanism',
                      value: isMesh ? true : settings.useComputedBlur,
                      options: const [false, true],
                      optionLabelTransformer: (val) =>
                          val ? 'Baked Blur' : 'Live Blur',
                      optionDescriptionTransformer: (val) {
                        if (isMesh) {
                          return val
                              ? 'Fluid Mesh is computed off-thread for smooth performance.'
                              : 'Live blur is unavailable for Fluid Mesh.';
                        }
                        return val
                            ? 'Smooth off-thread Gaussian blur with zero stutter.'
                            : 'Live real-time blur, but may lag on some phones.';
                      },
                      onChanged: (val) {
                        if (isMesh) {
                          if (!val) {
                            snackBar(
                                'Live blur is unavailable when using Fluid Mesh.');
                          }
                          return;
                        }
                        settings.useComputedBlur = val;
                      },
                    );
                  }),
                  Obx(
                    () => AnymeXTile.pills<int>(
                      icon: Icons.fullscreen_rounded,
                      title: 'Poster Blur Scope',
                      value: settings.detailsBlurScope,
                      options: const [0, 1, 2],
                      optionLabelTransformer: (val) {
                        switch (val) {
                          case 1:
                            return 'Full Screen';
                          case 2:
                            return 'Gradient';
                          default:
                            return 'Header Only';
                        }
                      },
                      optionDescriptionTransformer: (val) {
                        switch (val) {
                          case 1:
                            return 'Blurs the entire page background behind details.';
                          case 2:
                            return 'Blurs top banner and seamlessly dissolves into the artwork color below.';
                          default:
                            return 'Blurs only the top banner and fades smoothly into the page.';
                        }
                      },
                      onChanged: (val) {
                        settings.detailsBlurScope = val;
                      },
                    ),
                  ),
                  Obx(
                    () => AnymeXTile.pills<bool>(
                      icon: Icons.photo_library_outlined,
                      title: 'Backdrop Source',
                      value: settings.usePosterForBlur,
                      options: const [false, true],
                      optionLabelTransformer: (val) =>
                          val ? 'Poster' : 'Cover',
                      optionDescriptionTransformer: (val) => val
                          ? 'Uses the portrait poster cover for the blurred backdrop.'
                          : 'Uses the landscape banner for a cinematic wide backdrop.',
                      onChanged: (val) {
                        settings.usePosterForBlur = val;
                      },
                    ),
                  ),
                  Obx(
                    () => AnymeXTile.pills<bool>(
                      icon: Icons.palette_outlined,
                      title: 'Blur Color Tint',
                      value: settings.tintBlur,
                      options: const [false, true],
                      optionLabelTransformer: (val) =>
                          val ? 'Tinted' : 'Natural',
                      optionDescriptionTransformer: (val) => val
                          ? 'Blends your active theme accent color into the blur.'
                          : 'Keeps the original, authentic colors of the artwork.',
                      onChanged: (val) {
                        settings.tintBlur = val;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AnymeXSectionBuilder(
                title: 'Blur & Backdrop Tuning',
                children: [
                  Obx(
                    () => AnymeXTile.slider(
                      icon: Icons.blur_linear_rounded,
                      title: 'Blur Amount',
                      subtitle: 'Adjust frosted blur intensity',
                      value: blurAmount.value,
                      min: 2.0,
                      max: 50.0,
                      divisions: 48,
                      valueTransformer: (val) => '${val.toInt()} px',
                      onChanged: (val) {
                        blurAmount.value = val;
                        UISettingsKeys.detailsBlurAmount.set(val);
                        settings.uiSettings.refresh();
                      },
                    ),
                  ),
                  Obx(
                    () => AnymeXTile.slider(
                      icon: Icons.brightness_6_outlined,
                      title: 'Backdrop Brightness',
                      subtitle: 'Adjust media backdrop exposure',
                      value: backdropBrightness.value,
                      min: 0.5,
                      max: 1.5,
                      divisions: 20,
                      valueTransformer: (val) => '${(val * 100).toInt()}%',
                      onChanged: (val) {
                        backdropBrightness.value = val;
                        UISettingsKeys.detailsBackdropBrightness.set(val);
                        settings.uiSettings.refresh();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewHeader(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Icon(
          Iconsax.eye,
          size: 13,
          color: colors.onSurface.opaque(0.5, iReallyMeanIt: true),
        ),
        const SizedBox(width: 6),
        AnymeXText(
          'LIVE PREVIEW',
          size: 11,
          variant: TextVariant.bold,
          color: colors.onSurface.opaque(0.5, iReallyMeanIt: true),
        ),
      ],
    );
  }

  Widget _buildLivePreviewCard(BuildContext context) {
    final colors = context.colors;
    final media = _sampleMedia;
    final posterUrl = media.poster;
    final coverUrl =
        (media.cover?.isNotEmpty == true ? media.cover! : posterUrl);
    final previewHeight =
        MediaQuery.sizeOf(context).width > 700 ? 440.0 : 360.0;

    return Container(
      height: previewHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Obx(() {
        final blurScope = settings.detailsBlurScope;
        final isMesh = settings.detailsBlurStyle == 1;
        final isBaked = isMesh || settings.useComputedBlur;
        final usePoster = settings.usePosterForBlur;
        final tintBlur = settings.tintBlur;
        final blurColor = tintBlur ? colors.primary.opaque(0.4) : null;
        final currentBlur = blurAmount.value;
        final currentBrightness = backdropBrightness.value;

        final blurUrl = usePoster ? posterUrl : coverUrl;
        final blurFallback = usePoster ? coverUrl : posterUrl;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final sampleColor =
            AnymeXScaffold.parseColor(media.color) ?? colors.primary;
        final baseArtworkColor = tintBlur ? colors.primary : sampleColor;
        final gradientBgColor = Color.alphaBlend(
          baseArtworkColor.withValues(alpha: isDark ? 0.22 : 0.12),
          colors.surface,
        );

        Widget buildBlurredImage({double? height, bool fadeBottom = false}) {
          return isBaked
              ? BakedBlurImage(
                  url: blurUrl,
                  fallback: blurFallback,
                  saturation: 1.0,
                  blurAmount: currentBlur,
                  brightness: currentBrightness,
                  color: blurColor,
                  fit: BoxFit.cover,
                  height: height,
                  width: double.infinity,
                  fadeBottom: fadeBottom,
                  isMesh: isMesh,
                )
              : ColorFiltered(
                  colorFilter: ColorFilter.matrix([
                    currentBrightness, 0, 0, 0, 0,
                    0, currentBrightness, 0, 0, 0,
                    0, 0, currentBrightness, 0, 0,
                    0, 0, 0, 1, 0,
                  ]),
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(
                        sigmaX: currentBlur, sigmaY: currentBlur),
                    child: AnymeXImage(
                      imageUrl: blurUrl,
                      errorImage: blurFallback,
                      radius: 0,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: height ?? double.infinity,
                      color: blurColor,
                    ),
                  ),
                );
        }

        final headerWidget = MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: EdgeInsets.zero,
            viewPadding: EdgeInsets.zero,
          ),
          child: IgnorePointer(
            child: MediaHeader(
              tag: 'settings_preview_header',
              data: media,
              posterUrl: posterUrl,
              onShare: () {},
            ),
          ),
        );

        if (blurScope == 0) {
          return headerWidget;
        }

        final washHeight = previewHeight * 0.72;

        return Stack(
          fit: StackFit.expand,
          children: [
            if (blurScope == 1) ...[
              Positioned.fill(
                child: RepaintBoundary(
                  child: buildBlurredImage(),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        colors.surface.withValues(alpha: 0.40),
                        colors.surface.withValues(alpha: 0.65),
                        colors.surface.withValues(alpha: 0.90),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
            ] else if (blurScope == 2) ...[
              Positioned.fill(
                child: Container(
                  color: gradientBgColor,
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: washHeight,
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                          color: Colors.transparent, width: 2.0),
                    ),
                  ),
                  child: RepaintBoundary(
                    child: buildBlurredImage(height: washHeight),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: washHeight + 1.0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: const Border(
                      bottom: BorderSide(
                          color: Colors.transparent, width: 2.0),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.30, 0.60, 0.85, 1.0],
                      colors: [
                        gradientBgColor.withValues(
                            alpha: isDark ? 0.30 : 0.10),
                        gradientBgColor.withValues(
                            alpha: isDark ? 0.55 : 0.25),
                        gradientBgColor.withValues(
                            alpha: isDark ? 0.85 : 0.65),
                        gradientBgColor,
                        gradientBgColor,
                      ],
                    ),
                  ),
                ),
              ),
            ],
            headerWidget,
          ],
        );
      }),
    );
  }
}
