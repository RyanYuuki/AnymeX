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
import 'package:anymex/widgets/anymex_widgets/anymex_container.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/common/baked_blur_image.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class MediaHeader extends StatelessWidget {
  const MediaHeader({
    super.key,
    required this.tag,
    required this.data,
    required this.posterUrl,
    this.onShare,
    this.userStatus,
    this.userProgress,
  });

  final Media? data;
  final String posterUrl;
  final String tag;
  final VoidCallback? onShare;
  final String? userStatus;
  final String? userProgress;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width > 700;
    final colors = context.colors;
    final headerHeight = isDesktop ? 440.0 : 360.0;
    final topPad = MediaQuery.paddingOf(context).top;

    final posterWidth = isDesktop ? 158.0 : 120.0;
    final posterHeight = isDesktop ? 236.0 : 178.0;
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
              final blurScope = settingsController.detailsBlurScope;
              if (blurScope != 0) {
                return const SizedBox.shrink();
              }
              final usePoster = settingsController.usePosterForBlur;
              final blurSourceUrl = usePoster
                  ? posterUrl
                  : (data?.cover?.isNotEmpty == true ? data!.cover! : '');
              final blurFallbackUrl = usePoster ? posterUrl : '';
              if (blurSourceUrl.isEmpty) {
                return const SizedBox.shrink();
              }
              final tintBlur = settingsController.tintBlur;
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
                  : ColorFiltered(
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
                    );

              return RepaintBoundary(
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.transparent, width: 2.0),
                    ),
                  ),
                  child: content,
                ),
              );
            }),
          ),
          Positioned.fill(
            child: Obx(() {
              final blurScope = settingsController.detailsBlurScope;
              if (blurScope != 0) {
                return const SizedBox.shrink();
              }
              return Container(
                decoration: BoxDecoration(
                  border: const Border(
                    bottom: BorderSide(color: Colors.transparent, width: 2.0),
                  ),
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
              );
            }),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () {
                    Get.to(
                      () => VisualsPopup(
                        animeTitle:
                            data?.displayTitle ?? data?.title ?? 'Unknown',
                        malId: data?.idMal.toString() ?? data?.id.toString(),
                        originalCover: posterUrl,
                        isAnime: data?.mediaType.name.toUpperCase() == 'ANIME',
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
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onLongPress: () {
                          final title =
                              data?.displayTitle ?? data?.title ?? 'Loading...';
                          Clipboard.setData(ClipboardData(text: title));
                          snackBar('Title copied');
                        },
                        child: AnymeXText(
                          data?.displayTitle ?? data?.title ?? 'Loading...',
                          variant: TextVariant.bold,
                          size: isDesktop ? 28 : 20,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          isMarquee: false,
                        ),
                      ),
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
                            final authorStaff = data?.staff?.firstWhereOrNull(
                                (s) =>
                                    s.role?.toLowerCase().contains('story') ==
                                        true ||
                                    s.role?.toLowerCase().contains('art') ==
                                        true ||
                                    s.role?.toLowerCase().contains('creator') ==
                                        true);
                            creator = authorStaff?.name;
                          }

                          final studioName = creator;
                          final canOpenStudio = isAnime &&
                              studioName != null &&
                              studioName != 'Unknown';

                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: _buildMetaData(
                                  context,
                                  studioName ?? 'Unknown',
                                  const BorderRadius.horizontal(
                                      right: Radius.circular(5),
                                      left: Radius.circular(10)),
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
                              ),
                              const SizedBox(width: 2),
                              _buildMetaData(
                                context,
                                status.isNotEmpty ? status : 'Unknown',
                                const BorderRadius.horizontal(
                                    right: Radius.circular(10),
                                    left: Radius.circular(5)),
                                icon: Icons.info_outline_rounded,
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
              top: topPad + 12,
              left: 16,
              child: AnymexOnTap(
                onTap: () {
                  Navigator.of(context, rootNavigator: true)
                      .popUntil((route) => route.isFirst);
                },
                margin: 0,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHigh
                        .opaque(0.2, iReallyMeanIt: true),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    Icons.home_rounded,
                    size: 20,
                    color: colors.onSurface,
                  ),
                ),
              )),
          Positioned(
            top: topPad + 12,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: colors.surfaceContainerHigh
                    .opaque(0.2, iReallyMeanIt: true),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onShare != null) ...[
                    AnymexOnTap(
                      onTap: onShare,
                      margin: 0,
                      child: SizedBox(
                        width: 44,
                        height: 40,
                        child: Icon(
                          Icons.share_rounded,
                          size: 20,
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 22,
                      color: colors.onSurface.opaque(0.12, iReallyMeanIt: true),
                    ),
                  ],
                  AnymexOnTap(
                    onTap: () => navigate(() => const SettingsUiDetails()),
                    margin: 0,
                    child: SizedBox(
                      width: 44,
                      height: 40,
                      child: Icon(
                        Icons.palette_rounded,
                        size: 20,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 22,
                    color: colors.onSurface.opaque(0.12, iReallyMeanIt: true),
                  ),
                  AnymexOnTap(
                    onTap: Get.back,
                    margin: 0,
                    child: SizedBox(
                      width: 44,
                      height: 40,
                      child: Icon(
                        Icons.close_rounded,
                        size: 20,
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

  Widget _buildMetaData(BuildContext context, String val, BorderRadius? radius,
      {VoidCallback? onTap, IconData? icon}) {
    final chip = AnymeXContainer(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer.opaque(0.3, iReallyMeanIt: true),
        borderRadius: radius,
        border: Border.all(
          color: context.colors.onSurface.opaque(0.1, iReallyMeanIt: true),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 12,
              color: context.colors.primary,
            ),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: AnymeXText(
              val,
              variant: TextVariant.semiBold,
              size: 11,
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
