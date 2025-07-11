import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/screens/home_page.dart';
import 'package:anymex/screens/search/search_view.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void searchTypeSheet(BuildContext context) {
  showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        final serviceHanlder = Get.find<ServiceHandler>();
        final isSimkl = serviceHanlder.serviceType.value == ServicesType.simkl;
        final button1Cover = (isSimkl
                    ? serviceHanlder.simklService.trendingMovies
                    : serviceHanlder.anilistService.trendingAnimes)
                .firstWhere((e) => e.cover != null)
                .cover ??
            '';
        final button2Cover = (isSimkl
                    ? serviceHanlder.simklService.trendingSeries
                    : serviceHanlder.anilistService.trendingMangas)
                .firstWhere((e) => e.cover != null)
                .cover ??
            '';
        return Container(
          padding: const EdgeInsets.all(10),
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.multiplyRadius()),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const AnymexText(
                text: "SEARCH",
                size: 20,
                variant: TextVariant.semiBold,
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSearchTile(context, isSimkl ? "MOVIES" : "ANIME",
                      button1Cover, false),
                  _buildSearchTile(context, isSimkl ? "SERIES" : "MANGA",
                      button2Cover, isSimkl ? false : true),
                ],
              ),
              20.height()
            ],
          ),
        );
      });
}

ImageButton _buildSearchTile(
    BuildContext context, String buttonText, String imageUrl, bool isManga) {
  final isDesktop = MediaQuery.of(context).size.width > 600;

  return ImageButton(
    width: isDesktop ? 300 : MediaQuery.of(context).size.width / 2 - 40,
    height: !isDesktop ? 70 : 90,
    buttonText: buttonText,
    backgroundImage: imageUrl,
    borderRadius: 16.multiplyRadius(),
    onPressed: () {
      Get.back();

      navigate(() => SearchPage(
            searchTerm: '',
            isManga: isManga,
          ));
    },
  );
}
