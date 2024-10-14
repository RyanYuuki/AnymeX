import 'package:aurora/components/anilistCarousels/animeListCarousels.dart';
import 'package:aurora/components/common/image_button.dart';
import 'package:aurora/pages/user/anilist_pages/anime_list.dart';
import 'package:aurora/pages/user/anilist_pages/manga_list.dart';
import 'package:aurora/theme/theme_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:custom_sliding_segmented_control/custom_sliding_segmented_control.dart';
import 'package:flutter/material.dart';
import 'package:aurora/auth/auth_provider.dart';
import 'package:aurora/components/SettingsModal.dart';
import 'package:aurora/components/homepage/homepage_carousel.dart';
import 'package:aurora/components/reusable_carousel.dart';
import 'package:aurora/components/MangaExclusive/reusable_carousel.dart'
    as MangaCarousel;
import 'package:aurora/components/homepage/manga_homepage_carousel.dart';
import 'package:aurora/fallbackData/anime_data.dart';
import 'package:aurora/fallbackData/manga_data.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/arcticons.dart';
import 'package:iconify_flutter/icons/ph.dart';
import 'package:iconify_flutter/icons/simple_icons.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 1;
  late bool _isFirstTime;

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  void _checkFirstTime() {
    final loginBox = Hive.box('login-data');
    _isFirstTime = loginBox.get('isFirstTime', defaultValue: true);

    if (_isFirstTime) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showWelcomeDialog(context);
      });
    }
  }

  dynamic filterData(dynamic animeList) {
    return animeList.where((anime) => anime['status'] == 'CURRENT').toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AniListProvider>(
      builder: (context, anilistProvider, _) {
        final userName = anilistProvider.userData['name'] ?? 'Guest';
        final avatarImagePath = anilistProvider.userData?['avatar']?['large'];
        final isLoggedIn = anilistProvider.userData.isNotEmpty;
        final rawData = isLoggedIn &&
                anilistProvider.userData != null &&
                anilistProvider.userData.containsKey('animeList')
            ? (anilistProvider.userData['animeList'] ?? [])
            : [];

        final animeList = isLoggedIn &&
                anilistProvider.userData != null &&
                anilistProvider.userData.containsKey('animeList')
            ? filterData(anilistProvider.userData['animeList'] ?? [])
            : [];
        return ValueListenableBuilder(
          valueListenable: Hive.box('app-data').listenable(),
          builder: (context, Box appBox, _) {
            // final rawDataManga = anilistProvider.userData['mangaList'];
            // final mangaList = filterData(anilistProvider.userData['mangaList']);
            final dynamic readingMangaList = appBox.get('currently-reading');

            return Scaffold(
              backgroundColor: Theme.of(context).colorScheme.surface,
              body: ListView(
                children: [
                  Container(
                    constraints: const BoxConstraints(
                      minHeight: 300,
                      maxHeight: 450,
                    ),
                    padding:
                        const EdgeInsets.only(top: 20.0, left: 20, right: 20),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(
                                width: 50,
                                height: 70,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(30),
                                  child: Image.asset(
                                    'assets/images/logo_transparent.png',
                                    fit: BoxFit.cover,
                                    alignment: Alignment.center,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .inverseSurface,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(20),
                                      ),
                                    ),
                                    builder: (context) {
                                      return const SettingsModal();
                                    },
                                  );
                                },
                                child: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainer,
                                  child: isLoggedIn
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(50),
                                          child: CachedNetworkImage(
                                              fit: BoxFit.cover,
                                              imageUrl: avatarImagePath),
                                        )
                                      : Icon(
                                          Icons.person,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .inverseSurface,
                                        ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 60),
                          Text(
                            'Hey ${isLoggedIn ? userName : 'Guest'}, What are we doing today?',
                            style: const TextStyle(
                                fontSize: 30, fontFamily: 'Poppins-Bold'),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'Find your favorite anime or manga, manhwa or whatever you like!',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .inverseSurface
                                    .withOpacity(0.8),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      if (isLoggedIn)
                        Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ImageButton(
                                width:
                                    MediaQuery.of(context).size.width / 2 - 40,
                                buttonText: 'ANIME LIST',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AnimeList(),
                                    ),
                                  );
                                  Provider.of<AniListProvider>(context,
                                          listen: false)
                                      .fetchUserAnimeList();
                                },
                                backgroundImage:
                                    'https://s4.anilist.co/file/anilistcdn/media/anime/banner/110277-iuGn6F5bK1U1.jpg',
                              ),
                              ImageButton(
                                width:
                                    MediaQuery.of(context).size.width / 2 - 40,
                                buttonText: 'MANGA LIST',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AnilistMangaList(),
                                    ),
                                  );
                                  Provider.of<AniListProvider>(context,
                                          listen: false)
                                      .fetchUserMangaList();
                                },
                                backgroundImage:
                                    'https://s4.anilist.co/file/anilistcdn/media/manga/banner/30002-3TuoSMl20fUX.jpg',
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),
                      anilistCarousel(
                        title: 'Currently Watching',
                        carouselData: animeList,
                        tag: 'currently-watching',
                        rawData: rawData,
                      ),
                      // anilistCarousel(
                      //   title: 'Currently Reading',
                      //   carouselData: mangaList,
                      //   tag: 'currently-reading',
                      //   rawData: rawDataManga,
                      //   isManga: true,
                      // ),
                      MangaHomepageCarousel(
                        title: 'Currently Reading',
                        carouselData: readingMangaList,
                        tag: 'home-page',
                      ),
                      ReusableCarousel(
                        title: 'Recommended',
                        carouselData: animeData['topAiringAnimes'],
                        tag: 'home-page-recommended',
                        secondary: true,
                      ),
                      MangaCarousel.ReusableCarousel(
                        title: 'Recommended',
                        carouselData: mangaData['mangaList'],
                        tag: 'home-page-recommended',
                        secondary: true,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showWelcomeDialog(BuildContext context) {
    bool usingSaikouLayout = false;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Welcome To AnymeX",
      pageBuilder: (context, animation1, animation2) {
        return StatefulBuilder(
          builder: (context, setState) {
            final sunIconColor = selectedIndex == 0
                ? Theme.of(context).colorScheme.inverseSurface
                : Theme.of(context).colorScheme.surface;

            final moonIconColor = selectedIndex == 1
                ? Theme.of(context).colorScheme.inverseSurface
                : Theme.of(context).colorScheme.surface;

            final autoBrightnessIconColor = selectedIndex == 2
                ? Theme.of(context).colorScheme.inverseSurface
                : Theme.of(context).colorScheme.surface;

            return Material(
              color: Theme.of(context).colorScheme.surface,
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width - 20,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dialogBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 50,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24)),
                          color: Theme.of(context).colorScheme.surfaceContainer,
                        ),
                        child: const Center(
                          child: Text(
                            'Welcome To AnymeX',
                            style: TextStyle(fontFamily: 'Poppins-SemiBold'),
                          ),
                        ),
                      ),
                      ListTile(
                        title: const Text('Theme'),
                        leading: Iconify(
                          Arcticons.theme_store,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        trailing: CustomSlidingSegmentedControl<int>(
                          onValueChanged: (value) {
                            setState(() {
                              selectedIndex = value;
                            });
                            switch (value) {
                              case 0:
                                Provider.of<ThemeProvider>(context,
                                        listen: false)
                                    .setLightMode();
                                break;
                              case 1:
                                Provider.of<ThemeProvider>(context,
                                        listen: false)
                                    .setDarkMode();
                                break;
                              case 2:
                                Provider.of<ThemeProvider>(context,
                                        listen: false)
                                    .setDarkMode();
                                break;
                            }
                          },
                          initialValue: selectedIndex,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.inverseSurface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          thumbDecoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color:
                                Theme.of(context).colorScheme.surfaceContainer,
                          ),
                          children: {
                            0: Iconify(
                              Ph.sun,
                              color: sunIconColor,
                            ),
                            1: Iconify(
                              Ph.moon,
                              color: moonIconColor,
                            ),
                            2: Icon(
                              Iconsax.autobrightness,
                              color: autoBrightnessIconColor,
                            ),
                          },
                        ),
                      ),
                      ListTile(
                        leading: Iconify(
                          Ph.layout_light,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: const Text('Saikou Layout'),
                        onTap: () {},
                        trailing: Switch(
                            value: usingSaikouLayout,
                            onChanged: (value) {
                              setState(() {
                                usingSaikouLayout = !usingSaikouLayout;
                                Hive.box('app-data').put(
                                    'usingSaikouLayout', usingSaikouLayout);
                              });
                            }),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Column(
                          children: [
                            Container(
                              height: 50,
                              padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                              decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerLowest,
                                  borderRadius: BorderRadius.circular(12)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(context)
                                              .colorScheme
                                              .surfaceContainer,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12))),
                                      onPressed: () {
                                        Hive.box('login-data')
                                            .put('isFirstTime', false);
                                        Provider.of<AniListProvider>(context,
                                                listen: false)
                                            .login(context);
                                        Navigator.of(context).pop();
                                      },
                                      label: Text(
                                        'Login via AniList',
                                        style: TextStyle(
                                            fontFamily: 'Poppins-SemiBold',
                                            color: Theme.of(context)
                                                .colorScheme
                                                .inverseSurface),
                                      ),
                                      icon: Iconify(
                                        SimpleIcons.anilist,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .inverseSurface,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainer,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12))),
                                    onPressed: () {
                                      Hive.box('login-data')
                                          .put('isFirstTime', false);
                                      Navigator.of(context).pop();
                                    },
                                    label: Text(
                                      'Skip',
                                      style: TextStyle(
                                          fontFamily: 'Poppins-SemiBold',
                                          color: Theme.of(context)
                                              .colorScheme
                                              .inverseSurface),
                                    ),
                                    icon: Icon(IconlyBold.arrow_right,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .inverseSurface),
                                    iconAlignment: IconAlignment.end,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
