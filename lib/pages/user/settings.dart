import 'package:anymex/components/android/common/custom_tile.dart';
import 'package:anymex/pages/user/settings/settings_about.dart';
import 'package:anymex/pages/user/settings/settings_download.dart';
import 'package:anymex/pages/user/settings/settings_layout.dart';
import 'package:anymex/pages/user/settings/settings_player.dart';
import 'package:anymex/pages/user/settings/settings_theme.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
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
      body: SingleChildScrollView(
        child: Column(
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
            //   icon: Icons.source_rounded,
            //   title: 'Source',
            //   description: 'Source related settings',
            //   onTap: () {
            //     Navigator.push(
            //         context, _createSlideRoute(const SettingsSources()));
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
              icon: Icons.download,
              title: 'Downloads',
              description: 'Tweak Download Settings',
              onTap: () {
                Navigator.push(
                    context, _createSlideRoute(const SettingsDownload()));
              },
            ),
            CustomTile(
              icon: Iconsax.play5,
              title: 'Player',
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
              icon: Iconsax.trash,
              title: 'Clear Cache',
              description: 'This will remove everything (Fav List)',
              onTap: () async {
                await Hive.box('app-data').clear();
              },
            ),
            CustomTile(
              icon: Iconsax.info_circle5,
              title: 'About',
              description: 'About this app',
              onTap: () {
                Navigator.push(context, _createSlideRoute(const AboutPage()));
              },
            ),
          ],
        ),
      ),
    );
  }
}
