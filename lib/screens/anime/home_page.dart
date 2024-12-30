// ignore_for_file: invalid_use_of_protected_member

import 'package:anymex/controllers/anilist/anilist_data.dart';
import 'package:anymex/widgets/common/reusable_carousel.dart';
import 'package:anymex/widgets/header.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AnimeHomePage extends StatelessWidget {
  const AnimeHomePage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final anilistData = Get.find<AnilistData>();
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
