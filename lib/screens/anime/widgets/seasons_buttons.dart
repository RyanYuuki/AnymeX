import 'dart:ui';

import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Media/relation.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/home_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:blur/blur.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
                  spacing: 0,
                  mainAxisAlignment: getResponsiveValue(context,
                      mobileValue: MainAxisAlignment.spaceBetween,
                      desktopValue: MainAxisAlignment.center),
                  children: filteredRelations
                      .map((relation) => BlurredButton(
                            width: getResponsiveSize(context,
                                mobileSize:
                                    Get.width / filteredRelations.length - 30,
                                dektopSize: 300),
                            height: getResponsiveSize(context,
                                mobileSize: 60, dektopSize: 80),
                            buttonText: relation.relationType,
                            onPressed: () {
                              navigate(
                                () => AnimeDetailsPage(
                                    media: Media(
                                        id: relation.id.toString(),
                                        title: relation.title,
                                        poster: relation.poster),
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
    return GestureDetector(
      onTap: onPressed,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  Image.network(
                    backgroundImage,
                    width: width,
                    height: height,
                    fit: BoxFit.cover,
                  ),
                  Positioned.fill(
                    child: Blur(
                      blur: 5,
                      blurColor: Colors.black,
                      colorOpacity: 0.1,
                      child: Container(),
                    ),
                  ),
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
    );
  }
}
