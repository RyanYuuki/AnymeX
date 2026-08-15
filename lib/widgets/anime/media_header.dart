import 'dart:ui';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anime/visuals/visuals_popup.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_container.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
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
    final coverUrl = data?.cover ?? posterUrl;
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
          // just so i remember this my cover
          Positioned.fill(
            child: Obx(() {
              final liquidMode = settingsController.liquidMode;
              return ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                child: AnymeXImage(
                  imageUrl: coverUrl,
                  errorImage: data?.poster,
                  radius: 0,
                  height: headerHeight,
                  width: double.infinity,
                  color: liquidMode ? colors.primary.opaque(0.4) : null,
                  fit: BoxFit.cover,
                ),
              );
            }),
          ),
          // this my gradient
          Positioned.fill(
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () {
                    Get.to(
                      () => VisualsPopup(
                        animeTitle: data?.title ?? 'Unknown',
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
                          final title = data?.title ?? 'Loading...';
                          Clipboard.setData(ClipboardData(text: title));
                          snackBar('Title copied');
                        },
                        child: AnymeXText(
                          text: data?.title ?? 'Loading...',
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

                          return Row(spacing: 1, children: [
                            _buildMetaData(
                                context,
                                creator ?? 'Unknown',
                                const BorderRadius.horizontal(
                                    right: Radius.circular(5),
                                    left: Radius.circular(10))),
                            _buildMetaData(
                                context,
                                status.isNotEmpty ? status : 'Unknown',
                                const BorderRadius.horizontal(
                                    right: Radius.circular(10),
                                    left: Radius.circular(5))),
                          ]);
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
              child: _HeaderButton(
                colors: colors,
                child: Icon(
                  Icons.home_rounded,
                  size: 20,
                  color: colors.onSurface,
                ),
              ),
            ),
          ),
          Positioned(
            top: topPad + 12,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest
                    .opaque(0.6, iReallyMeanIt: true),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colors.onSurface.opaque(0.1, iReallyMeanIt: true),
                ),
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

  Widget _buildMetaData(
      BuildContext context, String val, BorderRadius? radius) {
    return AnymeXContainer(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer.opaque(0.2, iReallyMeanIt: true),
        borderRadius: radius,
        border: Border.all(
          color: context.colors.onSurface.opaque(0.1, iReallyMeanIt: true),
        ),
      ),
      child: AnymeXText(
        text: val,
        variant: TextVariant.semiBold,
        size: 11,
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.colors, required this.child});

  final ColorScheme colors;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.opaque(0.6, iReallyMeanIt: true),
        shape: BoxShape.circle,
        border: Border.all(
          color: colors.onSurface.opaque(0.1, iReallyMeanIt: true),
        ),
      ),
      child: child,
    );
  }
}
