import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

void showCharacterStaffSheet(BuildContext context, {required dynamic item, bool isCharacter = true}) {
  final theme = context.colors;
  final anilistAuth = Get.find<AnilistAuth>();

  // Reactive favorite state
  final isFav = (item.isFavourite ?? false).obs;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: theme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.onSurface.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Hero(
                            tag: item.id.toString(),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: AnymeXImage(
                                imageUrl: item.image ?? '',
                                width: 120,
                                height: 180,
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AnymexText(
                                  text: item.name ?? 'Unknown',
                                  variant: TextVariant.bold,
                                  size: 20,
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 10),
                                Obx(() => Row(
                                      children: [
                                        IconButton(
                                          onPressed: () async {
                                            if (!anilistAuth.isLoggedIn.value) {
                                              Get.snackbar("Error", "Please login to heart characters");
                                              return;
                                            }
                                            // Toggle Logic
                                            bool success = await anilistAuth.toggleFavorite(
                                              id: item.id,
                                              type: isCharacter ? "CHARACTER" : "STAFF",
                                            );
                                            if (success) {
                                              isFav.value = !isFav.value;
                                            }
                                          },
                                          icon: Icon(
                                            isFav.value ? Icons.favorite : Icons.favorite_border,
                                            color: isFav.value ? Colors.red : theme.onSurface,
                                          ),
                                        ),
                                        AnymexText(
                                          text: "${item.favourites ?? 0} Likes",
                                          size: 14,
                                          color: theme.onSurface.withOpacity(0.7),
                                        ),
                                      ],
                                    )),
                                if (!isCharacter && item.primaryOccupations != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: AnymexText(
                                      text: (item.primaryOccupations as List).join(", "),
                                      size: 12,
                                      color: theme.primary,
                                      maxLines: 2,
                                    ),
                                  ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    const Divider(height: 1, indent: 20, endIndent: 20),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnymexText(
                            text: isCharacter ? "Description" : "Biography",
                            variant: TextVariant.bold,
                            size: 16,
                          ),
                          const SizedBox(height: 8),
                          AnymexText(
                            text: item.description ?? 'No information available.',
                            size: 14,
                            maxLines: 100,
                            color: theme.onSurface.withOpacity(0.8),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: AnymexText(
                        text: isCharacter ? "Appears In" : "Works",
                        variant: TextVariant.bold,
                        size: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildRelatedMediaGrid(context, item.media ?? []),
                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}

Widget _buildRelatedMediaGrid(BuildContext context, List<Media> mediaList) {
  if (mediaList.isEmpty) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: AnymexText(text: "No related media found.", size: 12),
    );
  }

  return GridView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: mediaList.length,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      childAspectRatio: 0.6,
    ),
    itemBuilder: (context, index) {
      final media = mediaList[index];
      return GestureDetector(
        onTap: () {
          Get.to(() => AnimeDetailsPage(media: media, tag: "sheet-${media.id}"));
        },
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AnymeXImage(
                  imageUrl: media.poster,
                  width: double.infinity,
                ),
              ),
            ),
            const SizedBox(height: 5),
            AnymexText(
              text: media.title,
              size: 10,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    },
  );
}
