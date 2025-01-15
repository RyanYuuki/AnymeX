import 'package:anymex/controllers/settingss/methods.dart';
import 'package:anymex/screens/home_page.dart';
import 'package:anymex/screens/manga/search_page.dart';
import 'package:anymex/screens/novel/search_page.dart';
import 'package:anymex/widgets/minor_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void searchTypeSheet(BuildContext context, String searchTerm) {
  showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        final isDesktop = MediaQuery.of(context).size.width > 600;
        return Container(
          padding: const EdgeInsets.all(10),
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.multiplyRadius()),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const AnymexText(
                text: "SEARCH",
                size: 20,
                variant: TextVariant.semiBold,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ImageButton(
                    width: isDesktop
                        ? 300
                        : MediaQuery.of(context).size.width / 2 - 40,
                    height: !isDesktop ? 70 : 90,
                    buttonText: "MANGA",
                    backgroundImage:
                        'https://raw.githubusercontent.com/dharmx/walls/main/manga/a_black_and_white_image_of_a_room.jpeg',
                    borderRadius: 16.multiplyRadius(),
                    onPressed: () {
                      Get.back();

                      Get.to(() => MangaSearchPage(searchTerm: searchTerm));
                    },
                  ),
                  ImageButton(
                    width: isDesktop
                        ? 300
                        : MediaQuery.of(context).size.width / 2 - 40,
                    height: !isDesktop ? 70 : 90,
                    buttonText: "NOVEL",
                    backgroundImage:
                        'https://images8.alphacoders.com/136/1362712.jpeg',
                    borderRadius: 16.multiplyRadius(),
                    onPressed: () {
                      Get.back();
                      Get.to(() => NovelSearchPage(searchTerm: searchTerm));
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      });
}
