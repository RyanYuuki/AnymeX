import 'dart:ui';

import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/utils/fallback/fallback_anime.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/common/baked_blur_image.dart';
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
    return trendingAnimes.firstWhereOrNull(
            (m) => m.cover != null && m.cover!.isNotEmpty) ??
        trendingAnimes.first;
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
                    () => AnymeXTile.pills<bool>(
                      icon: Icons.blur_on_rounded,
                      title: 'Poster Blur Mode',
                      value: settings.useComputedBlur,
                      options: const [false, true],
                      optionLabelTransformer: (val) =>
                          val ? 'Baked Blur' : 'Live Blur',
                      optionDescriptionTransformer: (val) => val
                          ? 'Smooth and lag-free with zero stutter while scrolling.'
                          : 'Live real-time blur, but may lag on some phones.',
                      onChanged: (val) {
                        settings.useComputedBlur = val;
                      },
                    ),
                  ),
                  Obx(
                    () => AnymeXTile.pills<bool>(
                      icon: Icons.fullscreen_rounded,
                      title: 'Poster Blur Scope',
                      value: settings.fullScreenBlur,
                      options: const [false, true],
                      optionLabelTransformer: (val) =>
                          val ? 'Full Screen' : 'Header Only',
                      optionDescriptionTransformer: (val) => val
                          ? 'Blurs the entire page background behind details.'
                          : 'Blurs only the top banner and fades smoothly into the page.',
                      onChanged: (val) {
                        settings.fullScreenBlur = val;
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

  String _cleanDescription(String? raw) {
    if (raw == null || raw.isEmpty) {
      return 'This is a story about Momo, a high school girl from a family of spirit mediums, and her classmate Okarun, an occult fanatic.';
    }
    return raw
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Widget _buildLivePreviewCard(BuildContext context) {
    final colors = context.colors;
    final media = _sampleMedia;
    final posterUrl = media.poster;
    final coverUrl =
        (media.cover?.isNotEmpty == true ? media.cover! : posterUrl);
    final synopsis = _cleanDescription(media.description);

    return Container(
      height: 365,
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
        final isFullScreen = settings.fullScreenBlur;
        final useComputedBlur = settings.useComputedBlur;
        final usePoster = settings.usePosterForBlur;
        final tintBlur = settings.tintBlur;
        final blurColor = tintBlur ? colors.primary.opaque(0.4) : null;
        final currentBlur = blurAmount.value;
        final currentBrightness = backdropBrightness.value;

        final blurUrl = usePoster ? posterUrl : coverUrl;
        final blurFallback = usePoster ? coverUrl : posterUrl;

        return Stack(
          fit: StackFit.expand,
          children: [
            if (isFullScreen) ...[
              Positioned.fill(
                child: RepaintBoundary(
                  child: useComputedBlur
                      ? BakedBlurImage(
                          url: blurUrl,
                          fallback: blurFallback,
                          saturation: 1.0,
                          blurAmount: currentBlur,
                          brightness: currentBrightness,
                          color: blurColor,
                          fit: BoxFit.cover,
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
                              height: double.infinity,
                              color: blurColor,
                            ),
                          ),
                        ),
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
            ] else ...[
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 235,
                child: RepaintBoundary(
                  child: useComputedBlur
                      ? BakedBlurImage(
                          url: blurUrl,
                          fallback: blurFallback,
                          saturation: 1.0,
                          blurAmount: currentBlur,
                          brightness: currentBrightness,
                          color: blurColor,
                          fit: BoxFit.cover,
                          height: 235,
                          width: double.infinity,
                          fadeBottom: true,
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
                              height: 235,
                              color: blurColor,
                            ),
                          ),
                        ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 235,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colors.surface.withValues(alpha: 0.60),
                        colors.surface.withValues(alpha: 0.25),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.50, 1.0],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            ],
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPreviewHomeButton(context),
                  _buildPreviewRightCapsule(context),
                ],
              ),
            ),
            Positioned(
              top: 54,
              left: 16,
              right: 16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 72,
                    height: 104,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.40),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: AnymeXImage(
                      imageUrl: posterUrl,
                      radius: 12,
                      width: 72,
                      height: 104,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnymeXText(
                          media.displayTitle,
                          variant: TextVariant.bold,
                          size: 14,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildPreviewBadge(
                              context,
                              'Mappa',
                              icon: Icons.movie_creation_outlined,
                            ),
                            const SizedBox(width: 4),
                            _buildPreviewBadge(
                              context,
                              'Releasing',
                              icon: Icons.info_outline_rounded,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 170,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  Expanded(
                    child: _buildQuickActionItem(
                      context,
                      icon: Icons.add_rounded,
                      label: 'ADD TO LIST',
                      isPrimary: true,
                      radius: const BorderRadius.horizontal(
                        left: Radius.circular(14),
                        right: Radius.circular(5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildQuickActionItem(
                      context,
                      icon: Icons.bookmark_add_outlined,
                      label: 'CUSTOM LIST',
                      isPrimary: false,
                      radius: const BorderRadius.horizontal(
                        left: Radius.circular(5),
                        right: Radius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 220,
              left: 16,
              right: 16,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnymeXText(
                    'Synopsis',
                    variant: TextVariant.bold,
                    size: 12,
                    color: colors.onSurface.opaque(0.85, iReallyMeanIt: true),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: AnymeXText(
                      synopsis,
                      size: 10.5,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      color: colors.onSurface.opaque(0.60, iReallyMeanIt: true),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildPreviewHomeButton(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.opaque(0.65, iReallyMeanIt: true),
        shape: BoxShape.circle,
        border: Border.all(
          color: colors.onSurface.opaque(0.12, iReallyMeanIt: true),
        ),
      ),
      child: Icon(
        Icons.home_rounded,
        size: 16,
        color: colors.onSurface,
      ),
    );
  }

  Widget _buildPreviewRightCapsule(BuildContext context) {
    final colors = context.colors;
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.opaque(0.65, iReallyMeanIt: true),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.onSurface.opaque(0.12, iReallyMeanIt: true),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Icon(
              Icons.share_rounded,
              size: 14,
              color: colors.onSurface,
            ),
          ),
          Container(
            width: 1,
            height: 16,
            color: colors.onSurface.opaque(0.15, iReallyMeanIt: true),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Icon(
              Icons.close_rounded,
              size: 14,
              color: colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isPrimary,
    required BorderRadius radius,
  }) {
    final colors = context.colors;
    final bgClr = isPrimary
        ? colors.primary.opaque(0.14, iReallyMeanIt: true)
        : colors.surfaceContainerHighest.opaque(0.45, iReallyMeanIt: true);
    final borderClr = isPrimary
        ? colors.primary.opaque(0.28, iReallyMeanIt: true)
        : colors.onSurface.opaque(0.08, iReallyMeanIt: true);
    final textClr = isPrimary ? colors.primary : colors.onSurface;

    return Container(
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgClr,
        borderRadius: radius,
        border: Border.all(color: borderClr, width: 1.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: textClr),
          const SizedBox(width: 6),
          Flexible(
            child: AnymeXText(
              label,
              size: 10.5,
              variant: TextVariant.bold,
              color: textClr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewBadge(
    BuildContext context,
    String label, {
    IconData? icon,
  }) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.opaque(0.50, iReallyMeanIt: true),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: colors.onSurface.opaque(0.10, iReallyMeanIt: true),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 10,
              color: colors.primary,
            ),
            const SizedBox(width: 3),
          ],
          AnymeXText(
            label,
            variant: TextVariant.semiBold,
            size: 9.5,
          ),
        ],
      ),
    );
  }
}
