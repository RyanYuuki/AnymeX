import 'dart:developer';

import 'package:aurora/components/common/custom_tile.dart';
import 'package:aurora/pages/user/settings/settings_about.dart';
import 'package:aurora/pages/user/settings/settings_layout.dart';
import 'package:aurora/pages/user/settings/settings_player.dart';
import 'package:aurora/pages/user/settings/settings_theme.dart';
import 'package:aurora/utils/downloader/downloader.dart';
import 'package:aurora/utils/sources/anime/extensions/aniwatch/aniwatch.dart';
import 'package:aurora/utils/sources/anime/extensions/gogoanime/gogoanime.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Route _createSlideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end)
            .chain(CurveTween(curve: Curves.easeInOut));
        final offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              IconlyBroken.arrow_left_2,
              size: 30,
            ),
          ),
          const SizedBox(height: 30),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Settings',
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 30),
          // CustomTile(
          //   icon: Icons.source,
          //   title: 'Sources',
          //   description: 'Switch Sources for Animes and Manga',
          //   onTap: () {
          //     Navigator.push(
          //         context, _createSlideRoute(const SourcesSettingPage()));
          //   },
          // ),
          CustomTile(
            icon: HugeIcons.strokeRoundedPaintBrush02,
            title: 'UI',
            description: 'Play Around with UI Tweaks',
            onTap: () {
              Navigator.push(context, _createSlideRoute(const LayoutPage()));
            },
          ),
          CustomTile(
            icon: Iconsax.play5,
            title: 'Player (Soon)',
            description: 'Change Video Player Settings',
            onTap: () {
              Navigator.push(
                  context, _createSlideRoute(const VideoPlayerSettings()));
            },
          ),
          CustomTile(
            icon: Iconsax.paintbucket5,
            title: 'Theme',
            description: 'Change the app theme',
            onTap: () {
              Navigator.push(context, _createSlideRoute(const ThemePage()));
            },
          ),
          CustomTile(
            icon: Icons.language,
            title: 'Language (Soon)',
            description: 'Change the app language',
            onTap: () {},
          ),
          CustomTile(
            icon: Iconsax.info_circle5,
            title: 'About',
            description: 'About this app',
            onTap: () {
              Navigator.push(context, _createSlideRoute(const AboutPage()));
            },
          ),
          CustomTile(
            icon: Iconsax.info_circle5,
            title: 'Fetch Data',
            description: 'Test',
            onTap: () async {
              Downloader downloader = Downloader();
              downloader.download(
                'https://fds.biananset.net/_v7/417ddd84ea05034a8fb6d188381db81f00fe0570cfbebe412cc503746b8daa957900444662ad1e19b6551715fad254cf614103c5d6e118894d1eeb47f4a17bec16e500f04e84e18ff053b54584f5c4ca235bb3bae7ea4b758f3cf234afe2b446ab0d13720c2b206b36f092502aa3997fd9fdaecbdad5dca986b65c2c85652260/index-f3-v1-a1.m3u8',
                "Dandadan",
              );
              // await GogoAnime().scrapeEpisodesSrcs('https://www16.gogoanimes.fi/naruto-shippuden-episode-500');
            },
          ),
        ],
      ),
    );
  }
}
