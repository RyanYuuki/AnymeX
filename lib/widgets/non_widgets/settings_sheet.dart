import 'package:anymex/controllers/anilist/anilist_auth.dart';
import 'package:anymex/screens/extemsions/ExtensionScreen.dart';
import 'package:anymex/screens/settings/settings.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class SettingsSheet extends StatelessWidget {
  SettingsSheet({super.key});

  final anilistAuth = Get.find<AnilistAuth>();

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => SettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
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
              child: anilistAuth.isLoggedIn.value
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.network(
                          fit: BoxFit.cover,
                          anilistAuth.profileData.value!.avatar!),
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
                Text(anilistAuth.profileData.value?.name ?? 'Guest'),
                GestureDetector(
                  onTap: () {
                    if (anilistAuth.isLoggedIn.value) {
                      anilistAuth.logout();
                    } else {
                      anilistAuth.login();
                    }
                    Get.back();
                  },
                  child: Text(
                    anilistAuth.isLoggedIn.value ? 'Logout' : 'Login',
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
            onTap: () {},
          ),
          if (isMobile)
            ListTile(
              leading: const Icon(Icons.extension),
              title: const Text('Extensions'),
              onTap: () {
                Get.to(() => const ExtensionScreen());
              },
            ),
          ListTile(
            leading: const Icon(Iconsax.toggle_off_circle),
            title: const Text('Rescue Mode'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Iconsax.document_download),
            title: const Text('Downloads'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Iconsax.setting),
            title: const Text('Settings'),
            onTap: () {
              Get.to(() => const SettingsPage());
            },
          ),
        ],
      ),
    );
  }
}
