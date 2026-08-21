import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/screens/home_page.dart';
import 'package:anymex/screens/search/search_view.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:flutter/material.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:get/get.dart';

void searchTypeSheet(BuildContext context) {
  final isSimkl = serviceHandler.serviceType.value == ServicesType.simkl;
  if (isSimkl) {
    navigate(() => const SearchPage(
          searchTerm: '',
          isManga: false,
        ));
    return;
  }
  showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surface,
      builder: (context) {
        final button1Cover = (isSimkl
                    ? serviceHandler.simklService.trendingMovies
                    : serviceHandler.anilistService.trendingAnimes)
                .firstWhere((e) => e.cover != null)
                .cover ??
            '';
        final button2Cover = (isSimkl
                    ? serviceHandler.simklService.trendingSeries
                    : serviceHandler.anilistService.trendingMangas)
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
              const AnymeXText("SEARCH",
                size: 20,
                variant: TextVariant.semiBold,
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSearchTile(context, "MANGA", button1Cover, false),
                  _buildSearchTile(context, "NOVEL", button2Cover, true),
                ],
              ),
              20.height()
            ],
          ),
        );
      });
}

ImageButton _buildSearchTile(
    BuildContext context, String buttonText, String imageUrl, bool isNovel) {
  final isDesktop = MediaQuery.sizeOf(context).width > 600;

  return ImageButton(
    width: isDesktop ? 300 : MediaQuery.sizeOf(context).width / 2 - 40,
    height: !isDesktop ? 70 : 90,
    buttonText: buttonText,
    backgroundImage: imageUrl,
    borderRadius: 16.multiplyRadius(),
    onPressed: () {
      Get.back();
      if (isNovel) {
        navigate(() => const SearchPage(
              searchTerm: '',
              isManga: false,
              type: ItemType.novel,
            ));
      } else {
        navigate(() => const SearchPage(
              searchTerm: '',
              isManga: true,
            ));
      }
    },
  );
}
