import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Media/relation.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/home_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/minor_widgets/custom_text.dart';
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: filteredRelations
                      .map((relation) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: ImageButton(
                              width: getResponsiveSize(context,
                                  mobileSize: 150, dektopSize: 300),
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
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          );
  }
}
