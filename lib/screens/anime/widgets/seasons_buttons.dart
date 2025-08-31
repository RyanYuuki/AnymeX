import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Media/relation.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:blur/blur.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SeasonsGrid extends StatelessWidget {
  final List<Relation> relations;
  const SeasonsGrid({super.key, required this.relations});

  @override
  Widget build(BuildContext context) {
    final filteredRelations = relations
        .where((element) =>
            element.relationType == 'SEQUEL' ||
            element.relationType == 'PREQUEL')
        .take(2)
        .toList();

    return filteredRelations.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AnymexText(
                  text: "Seasons",
                  size: 18,
                  variant: TextVariant.bold,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: getResponsiveValue(context,
                      mobileValue: MainAxisAlignment.spaceBetween,
                      desktopValue: MainAxisAlignment.center),
                  children: filteredRelations
                      .map((relation) => BlurredButton(
                            width: getResponsiveSize(context,
                                mobileSize:
                                    Get.width / filteredRelations.length - 30,
                                desktopSize: 300),
                            height: getResponsiveSize(context,
                                mobileSize: 60, desktopSize: 80),
                            buttonText: relation.relationType,
                            onPressed: () {
                              navigate(
                                () => AnimeDetailsPage(
                                    media: Media(
                                        id: relation.id.toString(),
                                        title: relation.title,
                                        poster: relation.poster,
                                        serviceType: ServicesType.anilist),
                                    tag: relation.id.toString()),
                              );
                            },
                            backgroundImage: relation.cover.isNotEmpty
                                ? relation.cover
                                : relation.poster,
                          ))
                      .toList(),
                ),
              ],
            ),
          );
  }
}

class BlurredButton extends StatelessWidget {
  final double width;
  final double height;
  final String buttonText;
  final VoidCallback onPressed;
  final String backgroundImage;

  const BlurredButton({
    super.key,
    required this.width,
    required this.height,
    required this.buttonText,
    required this.onPressed,
    required this.backgroundImage,
  });

  @override
  Widget build(BuildContext context) {
    final isHovering = false.obs;
    return GestureDetector(
      onTap: onPressed,
      child: MouseRegion(
        onEnter: (e) => isHovering.value = true,
        onHover: (e) => isHovering.value = true,
        onExit: (e) => isHovering.value = false,
        child: Container(
          width: width,
          height: height,
          margin: EdgeInsets.symmetric(
              horizontal:
                  getResponsiveSize(context, mobileSize: 0, desktopSize: 20)),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).colorScheme.primary)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Stack(
                  children: [
                    Image.network(
                      backgroundImage,
                      width: width,
                      height: height,
                      fit: BoxFit.cover,
                    ),
                    Positioned.fill(child: Obx(() {
                      return TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 200),
                        tween: Tween<double>(
                            begin: 3, end: isHovering.value ? 0 : 3),
                        builder: (context, blurValue, child) {
                          return Blur(
                            blur: blurValue,
                            blurColor: Colors.black,
                            colorOpacity: 0.1,
                            child: Container(),
                          );
                        },
                      );
                    })),
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/dot_pattern.png',
                        color: Colors.white.withOpacity(0.1),
                        fit: BoxFit.fitWidth,
                        colorBlendMode: BlendMode.overlay,
                      ),
                    ),
                  ],
                ),
                Positioned.fill(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          buttonText.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Poppins-SemiBold',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 3),
                        Container(
                          color: Theme.of(context).colorScheme.primary,
                          height: 2,
                          width: 6 * buttonText.length.toDouble(),
                        )
                      ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
