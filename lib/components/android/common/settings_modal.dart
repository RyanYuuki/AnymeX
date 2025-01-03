import 'dart:io';

import 'package:anymex/auth/auth_provider.dart';
import 'package:anymex/main.dart';
import 'package:anymex/pages/Downloads/download_page.dart';
import 'package:anymex/pages/Extensions/ExtensionScreen.dart';
import 'package:anymex/pages/Rescue/Anime/home_page.dart';
import 'package:anymex/pages/user/profile.dart';
import 'package:anymex/pages/user/settings.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class SettingsModal extends StatelessWidget {
  const SettingsModal({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final anilistProvider = Provider.of<AniListProvider>(context);
    final userName = anilistProvider.userData?['user']?['name'] ?? 'Guest';
    final avatarImagePath =
        anilistProvider.userData?['user']?['avatar']?['large'];
    final isLoggedIn = anilistProvider.userData?['user']?['name'] != null;
    bool isMobile = Platform.isAndroid || Platform.isIOS;

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            const SizedBox(width: 5),
            CircleAvatar(
              radius: 24,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
              child: isLoggedIn
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.network(fit: BoxFit.cover, avatarImagePath),
                    )
                  : Icon(
                      Icons.person,
                      color: Theme.of(context).colorScheme.inverseSurface,
                    ),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userName),
                GestureDetector(
                  onTap: () {
                    if (isLoggedIn) {
                      Provider.of<AniListProvider>(context, listen: false)
                          .logout();
                    } else {
                      Provider.of<AniListProvider>(context, listen: false)
                          .login();
                    }
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const MainApp()),
                      (route) => false,
                    );
                  },
                  child: Text(
                    isLoggedIn ? 'Logout' : 'Login',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Expanded(
              child: SizedBox.shrink(),
            ),
            IconButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20))),
                icon: const Icon(Iconsax.notification))
          ]),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Iconsax.user),
            title: const Text('View Profile'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
          if (isMobile)
            ListTile(
              leading: const Icon(Icons.extension),
              title: const Text('Extensions'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ExtensionScreen()),
                );
              },
            ),
          ListTile(
            leading: const Icon(Iconsax.toggle_off_circle),
            title: const Text('Rescue Mode'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const RescueAnimeHome()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Iconsax.document_download),
            title: const Text('Downloads'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const DownloadPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Iconsax.setting),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
