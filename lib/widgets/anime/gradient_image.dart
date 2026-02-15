import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anime/visuals/visuals_popup.dart';
import 'package:anymex/widgets/header.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:blur/blur.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kenburns_nullsafety/kenburns_nullsafety.dart';

class GradientPoster extends StatelessWidget {
  const GradientPoster({
    super.key,
    required this.tag,
    required this.data,
    required this.posterUrl,
  });

  final Media? data;
  final String posterUrl;
  final String tag;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        SizedBox(
          height: isDesktop ? 460 : 400,
          child: Obx(() {
            final image = AnymeXImage(
              imageUrl: data?.cover ?? posterUrl,
              errorImage: data?.poster,
              radius: 0,
              height: 300,
              width: double.infinity,
              color: settingsController.liquidMode
                  ? context.colors.primary.opaque(0.8)
                  : null,
            );

            return settingsController.enablePosterKenBurns
                ? KenBurns(
                    maxScale: 1.5,
                    minAnimationDuration: const Duration(milliseconds: 6000),
                    maxAnimationDuration: const Duration(milliseconds: 10000),
                    child: image,
                  )
                : image;
          }),
        ),
        Container(
          height: isDesktop ? 460 : 400,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                context.colors.surface,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        SizedBox(
          height: isDesktop ? 460 : 400,
          child: Obx(
            () => settingsController.enablePosterKenBurns
                ? Blur(
                    colorOpacity: 0.0,
                    blur: 5,
                    blurColor: Colors.transparent,
                    child: Container(),
                  )
                : Container(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20.0, bottom: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {
                  snackBar("come-on man, long press it !!!");
                },
                onLongPress: () {
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
                child: Stack(children: [
                  Hero(
                    tag: tag,
                    child: AnymeXImage(
                        imageUrl: posterUrl,
                        radius: 16.multiplyRoundness(),
                        width: isDesktop ? 150 : 120,
                        height: isDesktop ? 200 : 180),
                  ),
                  if (data?.isAdult ?? false)
                    Positioned(
                      bottom: 7,
                      right: 7,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.opaque(0.9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.red, width: 1),
                        ),
                        child: const Text(
                          '18+',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: "Poppins-Bold",
                          ),
                        ),
                      ),
                    ),
                ]),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 2,
                    child: Text(data?.title ?? 'Loading...',
                        style: const TextStyle(
                            fontFamily: "Poppins-Bold", fontSize: 16)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Text(data?.status ?? "Ongoing? Idk",
                        style: TextStyle(
                            fontFamily: "Poppins-Bold",
                            fontSize: 16,
                            color: context.colors.primary)),
                  )
                ],
              )
            ],
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 20,
          child: AnymexOnTap(
            onTap: Get.back,
            margin: 0,
            child: IconButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.surfaceContainer,
              ),
              onPressed: Get.back,
              icon: const Icon(Icons.close),
            ),
          ),
        ),
      ],
    );
  }
}
