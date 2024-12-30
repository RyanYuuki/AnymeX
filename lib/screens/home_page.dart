// ignore_for_file: invalid_use_of_protected_member

import 'package:anymex/controllers/Settings/methods.dart';
import 'package:anymex/controllers/anilist/anilist_auth.dart';
import 'package:anymex/utils/fallback/fallback_anime.dart';
import 'package:anymex/utils/fallback/fallback_manga.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/anilist_media_carousel.dart';
import 'package:anymex/widgets/common/reusable_carousel.dart';
import 'package:anymex/widgets/header.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final anilistAuth = Get.find<AnilistAuth>();
    final isDesktop = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.symmetric(vertical: isDesktop ? 40 : 30),
        physics: const BouncingScrollPhysics(),
        children: [
          const Header(isHomePage: true),
          const SizedBox(height: 30),
          if (!isDesktop) ...[
            Obx(
              () => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  'Hey ${anilistAuth.isLoggedIn.value ? anilistAuth.profileData.value!.name : 'Guest'}, What are we doing today?',
                  style:
                      const TextStyle(fontSize: 30, fontFamily: 'Poppins-Bold'),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Find your favourite anime or manga, manhwa or whatever you like!',
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .inverseSurface
                      .withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 30),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ImageButton(
                width: isDesktop
                    ? 300
                    : MediaQuery.of(context).size.width / 2 - 40,
                height: !isDesktop ? 60 : 90,
                buttonText: "ANIME LIST",
                backgroundImage: trendingAnimes[0].cover ?? '',
                onPressed: () {},
              ),
              const SizedBox(width: 15),
              ImageButton(
                width: isDesktop
                    ? 300
                    : MediaQuery.of(context).size.width / 2 - 40,
                height: !isDesktop ? 60 : 90,
                buttonText: "MANGA LIST",
                backgroundImage: trendingMangas[0].cover ?? '',
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 30),
          Obx(() => ReusableCarousel(
                data: anilistAuth.currentlyWatching.value,
                title: "Currently Watching",
                variant: DataVariant.anilist,
              )),
          Obx(() => ReusableCarousel(
                data: anilistAuth.currentlyReading.value,
                title: "Currently Reading",
                isManga: true,
                variant: DataVariant.anilist,
              )),
          ReusableCarousel(
            title: "Recommended Animes",
            data: popularAnimes + trendingAnimes,
          ),
          ReusableCarousel(
            title: "Recommended Mangas",
            data: popularMangas + trendingMangas,
          )
        ],
      ),
    );
  }
}

class ImageButton extends StatelessWidget {
  final String buttonText;
  final VoidCallback onPressed;
  final String backgroundImage;
  final double width;
  final double height;
  final double borderRadius;
  final Color textColor;
  final TextStyle? textStyle;

  const ImageButton({
    super.key,
    required this.buttonText,
    required this.onPressed,
    required this.backgroundImage,
    this.width = 160,
    this.height = 60,
    this.borderRadius = 18,
    this.textColor = Colors.white,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius.multiplyRadius()),
        border: Border.all(
            width: 1,
            color:
                Theme.of(context).colorScheme.inverseSurface.withOpacity(0.3)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
              child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius.multiplyRadius()),
            child: CachedNetworkImage(
              height: height,
              width: width,
              imageUrl: backgroundImage,
              fit: BoxFit.cover,
            ),
          )),
          Positioned.fill(
            child: Container(
              width: width,
              height: height,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.black.withOpacity(0.5),
                  Colors.black.withOpacity(0.5),
                ]),
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
          ),
          // Elevated Button
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              fixedSize: Size(width, height),
              backgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              elevation: 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  buttonText.toUpperCase(),
                  style: textStyle ??
                      TextStyle(
                          color: textColor, fontFamily: 'Poppins-SemiBold'),
                ),
                const SizedBox(height: 3),
                Container(
                  color: Theme.of(context).colorScheme.primary,
                  height: 2,
                  width: 50,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
