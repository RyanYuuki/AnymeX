// ignore_for_file: invalid_use_of_protected_member
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/controllers/anilist/anilist_auth.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/screens/library/online/anime_list.dart';
import 'package:anymex/screens/library/online/manga_list.dart';
import 'package:anymex/utils/fallback/fallback_anime.dart';
import 'package:anymex/utils/fallback/fallback_manga.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/reusable_carousel.dart';
import 'package:anymex/widgets/header.dart';
import 'package:anymex/widgets/helper/scroll_wrapper.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
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
    final settings = Get.find<Settings>();
    final isDesktop = MediaQuery.of(context).size.width > 600;
    final acceptedLists = settings.homePageCards.entries
        .where((entry) => entry.value)
        .map<String>((entry) => entry.key)
        .toList();

    return RefreshIndicator(
      onRefresh: () {
        if (!anilistAuth.isLoggedIn.value) {
          snackBar("Bruhh, Login before you do that :>", duration: 1200);
        }
        return Future.wait([
          anilistAuth.fetchUserAnimeList(),
          anilistAuth.fetchUserMangaList()
        ]);
      },
      child: Scaffold(
        body: ScrollWrapper(
          children: [
            const Header(isHomePage: true),
            const SizedBox(height: 30),
            if (!isDesktop) ...[
              Obx(
                () => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    'Hey ${anilistAuth.isLoggedIn.value ? anilistAuth.profileData.value!.name : 'Guest'}, What are we doing today?',
                    style: const TextStyle(
                        fontSize: 30, fontFamily: 'Poppins-Bold'),
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
            Obx(() {
              if (anilistAuth.isLoggedIn.value) {
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ImageButton(
                          width: isDesktop
                              ? 300
                              : MediaQuery.of(context).size.width / 2 - 40,
                          height: !isDesktop ? 70 : 90,
                          buttonText: "ANIME LIST",
                          backgroundImage: trendingAnimes[0].cover ?? '',
                          borderRadius: 16.multiplyRadius(),
                          onPressed: () {
                            Get.to(() => const AnimeList());
                          },
                        ),
                        const SizedBox(width: 15),
                        ImageButton(
                          width: isDesktop
                              ? 300
                              : MediaQuery.of(context).size.width / 2 - 40,
                          height: !isDesktop ? 70 : 90,
                          buttonText: "MANGA LIST",
                          borderRadius: 16.multiplyRadius(),
                          backgroundImage: trendingMangas[0].cover ?? '',
                          onPressed: () {
                            Get.to(() => const AnilistMangaList());
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Obx(() => Column(
                          children: acceptedLists.map((e) {
                            return ReusableCarousel(
                              data: filterListByLabel(
                                  e.contains("Manga") || e.contains("Reading")
                                      ? anilistAuth.mangaList
                                      : anilistAuth.animeList,
                                  e),
                              title: e,
                              variant: DataVariant.anilist,
                              isManga: e.contains("Manga"),
                            );
                          }).toList(),
                        ))
                  ],
                );
              } else {
                return const SizedBox.shrink();
              }
            }),
            ReusableCarousel(
              title: "Recommended Animes",
              data: popularAnimes + trendingAnimes,
            ),
            ReusableCarousel(
              title: "Recommended Mangas",
              data: popularMangas + trendingMangas,
              isManga: true,
            )
          ],
        ),
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
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius.multiplyRadius()),
        border: Border.all(
          width: 1,
          color: Theme.of(context).colorScheme.inverseSurface.withOpacity(0.3),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(borderRadius.multiplyRadius()),
              child: CachedNetworkImage(
                height: height,
                width: width,
                imageUrl: backgroundImage,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
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
          Positioned.fill(
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: Colors.transparent,
                elevation: 8,
                shadowColor: Colors.black.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.7)),
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    buttonText.toUpperCase(),
                    style: textStyle ??
                        TextStyle(
                          color: textColor,
                          fontFamily: 'Poppins-SemiBold',
                        ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    color: Theme.of(context).colorScheme.primary,
                    height: 2,
                    width: 6 * buttonText.length.toDouble(),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
