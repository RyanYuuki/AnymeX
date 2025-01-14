// ignore_for_file: invalid_use_of_protected_member

import 'package:anymex/controllers/anilist/anilist_data.dart';
import 'package:anymex/screens/anime/search_page.dart';
import 'package:anymex/widgets/common/big_carousel.dart';
import 'package:anymex/widgets/common/reusable_carousel.dart';
import 'package:anymex/widgets/common/search_bar.dart';
import 'package:anymex/widgets/header.dart';
import 'package:anymex/widgets/helper/scroll_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AnimeHomePage extends StatelessWidget {
  const AnimeHomePage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final anilistData = Get.find<AnilistData>();
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
                    Get.to(() => SearchPage(searchTerm: val));
                  },
                  hintText: "Search Anime...",
                ),
                BigCarousel(
                  data: anilistData.trendingAnimes.value,
                  carouselType: CarouselType.anime,
                  isManga: false,
                ),
                ReusableCarousel(
                  title: "Popular Animes",
                  data: anilistData.popularAnimes.value,
                ),
                ReusableCarousel(
                  title: "Latest Animes",
                  data: anilistData.latestAnimes.value,
                ),
                ReusableCarousel(
                  title: "Trending Animes",
                  data: anilistData.trendingAnimes.value,
                ),
                ReusableCarousel(
                  title: "Upcoming Animes",
                  data: anilistData.upcomingAnimes.value,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
