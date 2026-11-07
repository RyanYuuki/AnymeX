import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details/widgets/media_stats_section.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anime/media_header.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_titlebar.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/common/baked_blur_image.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class SettingsUiDetails extends StatefulWidget {
  final Media? media;

  const SettingsUiDetails({super.key, this.media});

  @override
  State<SettingsUiDetails> createState() => _SettingsUiDetailsState();
}

class _SettingsUiDetailsState extends State<SettingsUiDetails> {
  final settings = Get.find<Settings>();

  final blurAmount = UISettingsKeys.detailsBlurAmount.get<double>(20.0).obs;
  final appliedBlurAmount =
      UISettingsKeys.detailsBlurAmount.get<double>(20.0).obs;
  final backdropBrightness =
      UISettingsKeys.detailsBackdropBrightness.get<double>(1.0).obs;
  final appliedBackdropBrightness =
      UISettingsKeys.detailsBackdropBrightness.get<double>(1.0).obs;

  bool _isTransitionReady = false;
  Timer? _blurDebounceTimer;
  Timer? _brightnessDebounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Platform.isWindows) {
        AnymeXTitleBar.isTransparent.value = false;
      }
      final route = ModalRoute.of(context);
      if (route != null && route.animation != null) {
        if (route.animation!.isCompleted) {
          if (mounted) setState(() => _isTransitionReady = true);
        } else {
          route.animation!.addStatusListener((status) {
            if (status == AnimationStatus.completed && mounted) {
              setState(() => _isTransitionReady = true);
            }
          });
        }
      } else {
        if (mounted) setState(() => _isTransitionReady = true);
      }
    });
  }

  @override
  void dispose() {
    if (Platform.isWindows && widget.media != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AnymeXTitleBar.isTransparent.value = true;
      });
    }
    _blurDebounceTimer?.cancel();
    _brightnessDebounceTimer?.cancel();
    super.dispose();
  }

  static final Media _fallbackAttackOnTitan = Media(
    id: '16498',
    idMal: '16498',
    title: 'Attack on Titan',
    romajiTitle: 'Shingeki no Kyojin',
    englishTitle: 'Attack on Titan',
    nativeTitle: '進撃の巨人',
    color: '#f1a143',
    cover:
        'https://s4.anilist.co/file/anilistcdn/media/anime/banner/16498-8jpFCOcDmneX.jpg',
    poster:
        'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx16498-buvcRTBx4NSm.jpg',
    largePoster:
        'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx16498-buvcRTBx4NSm.jpg',
    description:
        'Several hundred years ago, humans were nearly exterminated by titans. Titans are typically several stories tall, seem to have no intelligence, devour human beings and, worst of all, seem to do it for the pleasure rather than as a food source. A small percentage of humanity survived by walling themselves in a city protected by extremely high walls, even taller than the biggest of titans.<br><br>\r\nFlash forward to the present and the city has not seen a titan in over 100 years. Teenage boy Eren and his foster sister Mikasa witness something horrific as the city walls are destroyed by a colossal titan that appears out of thin air. As the smaller titans flood the city, the two kids watch in horror as their mother is eaten alive. Eren vows that he will murder every single titan and take revenge for all of mankind.',
    totalEpisodes: '25',
    duration: '24m',
    status: 'FINISHED',
    season: 'SPRING',
    seasonYear: 2013,
    rating: '8.5',
    popularity: '1,076,213',
    format: 'TV',
    sourceMaterial: 'MANGA',
    genres: const ['Action', 'Drama', 'Fantasy', 'Mystery'],
    studios: const ['WIT STUDIO'],
    serviceType: ServicesType.anilist,
    mediaType: ItemType.anime,
  );

  Media get _sampleMedia {
    if (widget.media != null) {
      return widget.media!;
    }
    return _fallbackAttackOnTitan;
  }

  @override
  Widget build(BuildContext context) {
    return AnymeXScaffold(
      showHeader: true,
      headerTitle: 'Details Page',
      body: Builder(
        builder: (ctx) => SingleChildScrollView(
          padding:
              EdgeInsets.fromLTRB(16.0, AnymeXHeaderScope.of(ctx), 16.0, 30.0),
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
                      optionLabelTransformer: (val) => val ? 'Poster' : 'Cover',
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
                        _blurDebounceTimer?.cancel();
                        _blurDebounceTimer =
                            Timer(const Duration(seconds: 1), () {
                          appliedBlurAmount.value = val;
                          UISettingsKeys.detailsBlurAmount.set(val);
                          settings.uiSettings.refresh();
                        });
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
                        _brightnessDebounceTimer?.cancel();
                        _brightnessDebounceTimer =
                            Timer(const Duration(seconds: 1), () {
                          appliedBackdropBrightness.value = val;
                          UISettingsKeys.detailsBackdropBrightness.set(val);
                          settings.uiSettings.refresh();
                        });
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
    final isDesktop = MediaQuery.sizeOf(context).width > 700;
    final cardRadius = isDesktop ? 20.0 : 28.0;

    if (!_isTransitionReady) {
      return Container(
        width: double.infinity,
        height: 380,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 28,
            offset: const Offset(0, 10),
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
        final currentBlur = appliedBlurAmount.value;
        final currentBrightness = appliedBackdropBrightness.value;

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
          if (!_isTransitionReady) {
            return Container(
              color: gradientBgColor,
              width: double.infinity,
              height: height ?? double.infinity,
            );
          }
          final blurWidget = isBaked
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
                    currentBrightness,
                    0,
                    0,
                    0,
                    0,
                    0,
                    currentBrightness,
                    0,
                    0,
                    0,
                    0,
                    0,
                    currentBrightness,
                    0,
                    0,
                    0,
                    0,
                    0,
                    1,
                    0,
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

          if (fadeBottom && !isBaked) {
            return ShaderMask(
              shaderCallback: (bounds) {
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.70, 1.0],
                  colors: [
                    Colors.black,
                    Colors.black,
                    Colors.transparent,
                  ],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: blurWidget,
            );
          }
          return blurWidget;
        }

              final cleanDesc =
                  media.description.replaceAll(RegExp(r'<[^>]*>'), '').trim();

              final fullMockContent = MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  padding: EdgeInsets.zero,
                  viewPadding: EdgeInsets.zero,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MediaHeader(
                      tag: 'settings_preview_header',
                      data: media,
                      posterUrl: posterUrl,
                      userStatus: 'PLANNING',
                      userProgress: '3',
                      onShare: () {},
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 50,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: colors.primary
                                    .opaque(0.12, iReallyMeanIt: true),
                                borderRadius: const BorderRadius.horizontal(
                                  left: Radius.circular(16),
                                  right: Radius.circular(5),
                                ),
                                border: Border.all(
                                  color: colors.primary
                                      .opaque(0.25, iReallyMeanIt: true),
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_rounded,
                                    size: 18,
                                    color: colors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: AnymeXText(
                                      'ADD TO LIST',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: colors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.5,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Container(
                              height: 50,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: colors.surfaceContainerHighest
                                    .opaque(0.4, iReallyMeanIt: true),
                                borderRadius: const BorderRadius.horizontal(
                                  left: Radius.circular(5),
                                  right: Radius.circular(16),
                                ),
                                border: Border.all(
                                  color: colors.onSurface
                                      .opaque(0.08, iReallyMeanIt: true),
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.bookmark_add_outlined,
                                    size: 18,
                                    color: colors.onSurface,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: AnymeXText(
                                      'CUSTOM LIST',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: colors.onSurface,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.5,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (cleanDesc.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHighest
                                .opaque(0.3, iReallyMeanIt: true),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: colors.onSurface
                                  .opaque(0.08, iReallyMeanIt: true),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const AnymeXText(
                                'Synopsis',
                                size: 15,
                                variant: TextVariant.bold,
                                isMarquee: true,
                              ),
                              const SizedBox(height: 8),
                              AnymeXText(
                                cleanDesc,
                                size: 12,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                variant: TextVariant.regular,
                                color: colors.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: buildStatsGrid(context, media),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              );

        if (blurScope == 0) {
          return fullMockContent;
        }

        final washHeight = isDesktop ? 460.0 : 380.0;

        return Stack(
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
                        colors.surface.withValues(alpha: 0.35),
                        colors.surface.withValues(alpha: 0.60),
                        colors.surface.withValues(alpha: 0.88),
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
                child: RepaintBoundary(
                  child: buildBlurredImage(
                      height: washHeight, fadeBottom: true),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: washHeight + 1.0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
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
            fullMockContent,
          ],
        );
      }),
    );
  }
}
