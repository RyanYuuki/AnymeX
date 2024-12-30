// ignore_for_file: invalid_use_of_protected_member

import 'package:anymex/controllers/anilist/anilist_data.dart';
import 'package:anymex/widgets/common/reusable_carousel.dart';
import 'package:anymex/widgets/header.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MangaHomePage extends StatelessWidget {
  const MangaHomePage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AnilistData anilistData = Get.find<AnilistData>();
    final isDesktop = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.symmetric(vertical: isDesktop ? 40 : 20),
        physics: const BouncingScrollPhysics(),
        children: [
          const Header(),
          const SizedBox(height: 30),
          Obx(() {
            return Column(
              children: [
                ReusableCarousel(
                  title: "Trending Mangas",
                  isManga: true,
                  data: anilistData.trendingMangas.value,
                ),
                ReusableCarousel(
                  isManga: true,
                  title: "More Popular Mangas",
                  data: anilistData.morePopularMangas.value,
                ),
                ReusableCarousel(
                  title: "Popular Mangas",
                  data: anilistData.popularMangas.value,
                  isManga: true,
                ),
                ReusableCarousel(
                  title: "Latest Mangas",
                  data: anilistData.latestMangas.value,
                  isManga: true,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
