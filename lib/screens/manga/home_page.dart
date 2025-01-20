// ignore_for_file: invalid_use_of_protected_member

import 'dart:developer';

import 'package:anymex/controllers/services/anilist/anilist_data.dart';
import 'package:anymex/screens/manga/widgets/search_selector.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/big_carousel.dart';
import 'package:anymex/widgets/common/reusable_carousel.dart';
import 'package:anymex/widgets/common/search_bar.dart';
import 'package:anymex/widgets/header.dart';
import 'package:anymex/widgets/helper/scroll_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MangaHomePage extends StatelessWidget {
  const MangaHomePage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AnilistData anilistData = Get.find<AnilistData>();

    return Scaffold(
      body: ScrollWrapper(
        children: [
          const Header(),
          const SizedBox(height: 10),
          Obx(() {
            return Column(
              children: [
                CustomSearchBar(
                  onSubmitted: (val) {
                    searchTypeSheet(context, val);
                  },
                  hintText: "Search...",
                ),
                BigCarousel(
                  isManga: true,
                  data: anilistData.trendingMangas.value,
                  carouselType: CarouselType.manga,
                ),
                ReusableCarousel(
                  title: "Trending Mangas",
                  isManga: true,
                  data: anilistData.trendingMangas.value,
                ),
                ReusableCarousel(
                  title: "Popular Mangas",
                  data: anilistData.popularMangas.value,
                  isManga: true,
                ),
                ReusableCarousel(
                  isManga: true,
                  title: "More Popular Mangas",
                  data: anilistData.morePopularMangas.value,
                ),
                ReusableCarousel(
                  title: "Latest Mangas",
                  data: anilistData.latestMangas.value,
                  isManga: true,
                ),
                ...anilistData.novelData.entries.map<Widget>((entry) {
                  final key = entry.key;
                  final val = entry.value;

                  return ReusableCarousel(
                    data: val!,
                    title: key.name!,
                    variant: DataVariant.extension,
                  );
                })
              ],
            );
          }),
        ],
      ),
    );
  }
}
