import 'dart:io';
import 'dart:ui';
import 'package:anymex/controllers/services/anilist/anilist_data.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/studio_details_page.dart';
import 'package:anymex/screens/settings/sub_settings/settings_ui_details.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anime/visuals/visuals_popup.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/common/baked_blur_image.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:anymex/l10n/l10n_extension.dart';

class MediaHeader extends StatelessWidget {
  const MediaHeader({
    super.key,
    required this.tag,
    required this.data,
    required this.posterUrl,
    this.onShare,
    this.userStatus,
    this.userProgress,
    this.extendBehindTitleBar = false,
    this.quickActions,
  });

  final Media? data;
  final String posterUrl;
  final String tag;
  final VoidCallback? onShare;
  final String? userStatus;
  final String? userProgress;
  final bool extendBehindTitleBar;
  final Widget? quickActions;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width > 700;
    final colors = context.colors;
    final desktopTopPad =
        (Platform.isWindows && extendBehindTitleBar) ? 40.0 : 0.0;
    final topPad = MediaQuery.paddingOf(context).top;
    final effectiveTopPad = topPad + desktopTopPad;
    final headerHeight = isDesktop
        ? (340.0 + desktopTopPad)
        : (effectiveTopPad + (quickActions != null ? 340.0 : 290.0));

    final posterWidth = isDesktop ? 158.0 : 122.0;
    final posterHeight = isDesktop ? 236.0 : 182.0;
    final posterRadius =
        isDesktop ? 24.multiplyRoundness() : 18.multiplyRoundness();

    final status = data?.status ?? '';

    return SizedBox(
      height: headerHeight,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned.fill(
            child: Obx(() {
              if (settingsController.detailsOledMode) {
                return Container(color: Colors.black);
              }
              return const SizedBox.shrink();
            }),
          ),
          Positioned.fill(
            child: Obx(() {
              final isOled = settingsController.detailsOledMode;
              final blurScope = settingsController.detailsBlurScope;
              if (blurScope != 0 && !isOled) {
                return const SizedBox.shrink();
              }
              final usePoster = settingsController.usePosterForBlur;
              final effectiveCover =
                  (data?.cover?.isNotEmpty == true ? data!.cover! : posterUrl);
              final blurSourceUrl = isOled
                  ? effectiveCover
                  : (usePoster ? posterUrl : effectiveCover);
              final blurFallbackUrl =
                  isOled ? posterUrl : (usePoster ? effectiveCover : posterUrl);
              if (blurSourceUrl.isEmpty) {
                return const SizedBox.shrink();
              }
              final tintBlur = isOled ? false : settingsController.tintBlur;
              final blurColor = tintBlur ? colors.primary.opaque(0.4) : null;
              final isMesh = settingsController.detailsBlurStyle == 1;
              final isBaked = isMesh || settingsController.useComputedBlur;
              final blurAmount =
                  UISettingsKeys.detailsBlurAmount.get<double>(20.0);
              final brightness =
                  UISettingsKeys.detailsBackdropBrightness.get<double>(1.0);

              Widget content = isBaked
                  ? BakedBlurImage(
                      url: blurSourceUrl,
                      fallback: blurFallbackUrl,
                      saturation: 1.0,
                      blurAmount: blurAmount,
                      brightness: brightness,
                      color: blurColor,
                      fit: BoxFit.cover,
                      height: headerHeight,
                      width: double.infinity,
                      fadeBottom: true,
                      isMesh: isMesh,
                    )
                  : ShaderMask(
                      shaderCallback: (bounds) {
                        return const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0.0, 0.60, 1.0],
                          colors: [
                            Colors.black,
                            Colors.black,
                            Colors.transparent,
                          ],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: ColorFiltered(
                        colorFilter: ColorFilter.matrix([
                          brightness,
                          0,
                          0,
                          0,
                          0,
                          0,
                          brightness,
                          0,
                          0,
                          0,
                          0,
                          0,
                          brightness,
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
                              sigmaX: blurAmount, sigmaY: blurAmount),
                          child: AnymeXImage(
                            imageUrl: blurSourceUrl,
                            errorImage: blurFallbackUrl,
                            radius: 0,
                            height: headerHeight,
                            width: double.infinity,
                            color: blurColor,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );

              return RepaintBoundary(
                child: content,
              );
            }),
          ),
          Positioned.fill(
            child: Obx(() {
              final isOled = settingsController.detailsOledMode;
              final blurScope = settingsController.detailsBlurScope;
              if (blurScope != 0 && !isOled) {
                return const SizedBox.shrink();
              }
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isOled
                        ? [
                            Colors.black.withValues(alpha: 0.50),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.70),
                            Colors.black,
                          ]
                        : [
                            colors.surface.opaque(0.60, iReallyMeanIt: true),
                            colors.surface.opaque(0.25, iReallyMeanIt: true),
                            colors.surface.opaque(0, iReallyMeanIt: true),
                          ],
                    stops: isOled
                        ? const [0.0, 0.35, 0.75, 1.0]
                        : const [0.0, 0.50, 1.0],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              );
            }),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, isDesktop ? 20 : 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Get.to(
                          () => VisualsPopup(
                            animeTitle:
                                data?.displayTitle ?? data?.title ?? 'Unknown',
                            malId:
                                data?.idMal.toString() ?? data?.id.toString(),
                            originalCover: posterUrl,
                            isAnime:
                                data?.mediaType.name.toUpperCase() == 'ANIME',
                          ),
                          transition: Transition.fadeIn,
                          duration: const Duration(milliseconds: 300),
                        );
                      },
                      child: Container(
                        width: posterWidth,
                        height: posterHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(posterRadius),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Hero(
                          tag: tag,
                          transitionOnUserGestures: true,
                          flightShuttleBuilder:
                              AnymeXImage.heroFlightShuttleBuilder,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(posterRadius),
                            child: AnymeXImage(
                              imageUrl: posterUrl,
                              radius: posterRadius,
                              width: posterWidth,
                              height: posterHeight,
                              fadeInDuration: Duration.zero,
                              fadeOutDuration: Duration.zero,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Builder(
                            builder: (context) {
                              final isAnime = data?.mediaType == ItemType.anime;
                              String? creator;
                              if (isAnime) {
                                creator = (data?.studios != null &&
                                        data!.studios!.isNotEmpty)
                                    ? data!.studios!.first
                                    : null;
                              } else {
                                final authorStaff = data?.staff
                                    ?.firstWhereOrNull((s) =>
                                        s
                                                .role
                                                ?.toLowerCase()
                                                .contains('story') ==
                                            true ||
                                        s.role?.toLowerCase().contains('art') ==
                                            true ||
                                        s.role
                                                ?.toLowerCase()
                                                .contains('creator') ==
                                            true);
                                creator = authorStaff?.name;
                              }

                              final studioName = creator;
                              final canOpenStudio = isAnime &&
                                  studioName != null &&
                                  studioName != 'Unknown';

                              final statusLower = status.toLowerCase();
                              final Color statusDotColor;
                              if (statusLower.contains('cancel') ||
                                  statusLower.contains('hiatus')) {
                                statusDotColor = colors.tertiary;
                              } else if (statusLower.contains('releas') ||
                                  statusLower.contains('ongoing')) {
                                statusDotColor = colors.primary;
                              } else {
                                statusDotColor = colors.secondary;
                              }
                              final statusLabel = status.isNotEmpty
                                  ? (status[0].toUpperCase() +
                                      status.substring(1).toLowerCase())
                                  : 'Unknown';

                              final pills = <Widget>[
                                _buildMetaPill(
                                  context,
                                  studioName ?? 'Unknown',
                                  icon: isAnime
                                      ? Icons.movie_creation_outlined
                                      : Icons.brush_outlined,
                                  onTap: canOpenStudio
                                      ? () async {
                                          final studioId = await AnilistData
                                              .fetchStudioIdByName(studioName);
                                          if (studioId != null &&
                                              context.mounted) {
                                            showStudioDetailsSheet(
                                              context,
                                              studioId,
                                              studioName,
                                            );
                                          }
                                        }
                                      : null,
                                ),
                                _buildMetaPill(
                                  context,
                                  statusLabel,
                                  dotColor: statusDotColor,
                                ),
                              ];

                              if (isDesktop) {
                                return SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      for (int i = 0;
                                          i < pills.length;
                                          i++) ...[
                                        if (i > 0) const SizedBox(width: 6),
                                        pills[i],
                                      ],
                                    ],
                                  ),
                                );
                              }

                              return Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: pills,
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onLongPress: () {
                              final title = data?.displayTitle ??
                                  data?.title ??
                                  'Loading...';
                              Clipboard.setData(ClipboardData(text: title));
                              snackBar(context.l10n.titleCopied);
                            },
                            child: AnymeXText(
                              data?.displayTitle ?? data?.title ?? 'Loading...',
                              variant: TextVariant.bold,
                              size: isDesktop ? 30 : 21,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              isMarquee: false,
                            ),
                          ),
                          if (isDesktop && quickActions != null) ...[
                            const SizedBox(height: 10),
                            quickActions!,
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (!isDesktop && quickActions != null) ...[
                  const SizedBox(height: 12),
                  quickActions!,
                ],
              ],
            ),
          ),
          Positioned(
            top: effectiveTopPad + 12,
            left: 16,
            child: AnymexOnTap(
              onTap: () {
                Navigator.of(context, rootNavigator: true)
                    .popUntil((route) => route.isFirst);
              },
              margin: 0,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest
                      .opaque(0.4, iReallyMeanIt: true),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: colors.onSurface.opaque(0.08, iReallyMeanIt: true),
                    width: 0.8,
                  ),
                ),
                child: Icon(
                  Iconsax.home_2,
                  size: 16,
                  color: colors.onSurface,
                ),
              ),
            ),
          ),
          Positioned(
            top: effectiveTopPad + 12,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest
                    .opaque(0.4, iReallyMeanIt: true),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: colors.onSurface.opaque(0.08, iReallyMeanIt: true),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onShare != null)
                    AnymexOnTap(
                      onTap: onShare,
                      margin: 0,
                      child: SizedBox(
                        width: 34,
                        height: 32,
                        child: Icon(
                          Icons.ios_share_rounded,
                          size: 17,
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                  AnymexOnTap(
                    onTap: () => navigateWithAnimation(
                        () => SettingsUiDetails(media: data)),
                    margin: 0,
                    child: SizedBox(
                      width: 34,
                      height: 32,
                      child: Icon(
                        Iconsax.brush_4,
                        size: 16,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                  AnymexOnTap(
                    onTap: Get.back,
                    margin: 0,
                    child: SizedBox(
                      width: 34,
                      height: 32,
                      child: Icon(
                        Icons.close_rounded,
                        size: 17,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaPill(
    BuildContext context,
    String val, {
    VoidCallback? onTap,
    IconData? icon,
    Color? dotColor,
    bool highlighted = false,
  }) {
    final colors = context.colors;
    final isDesktop = MediaQuery.sizeOf(context).width > 700;
    final height = isDesktop ? 36.0 : 32.0;
    final chip = Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 16 : 13),
      decoration: BoxDecoration(
        color: highlighted
            ? colors.primary.opaque(0.2, iReallyMeanIt: true)
            : colors.onSurface.opaque(0.08, iReallyMeanIt: true),
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
          ] else if (icon != null) ...[
            Icon(
              icon,
              size: isDesktop ? 16 : 14,
              color: colors.primary,
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: AnymeXText(
              val,
              variant: TextVariant.semiBold,
              size: isDesktop ? 14 : 12.5,
              color: highlighted ? colors.primary : colors.onSurface,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return AnymexOnTap(
        onTap: onTap,
        margin: 0,
        child: chip,
      );
    }
    return chip;
  }
}
