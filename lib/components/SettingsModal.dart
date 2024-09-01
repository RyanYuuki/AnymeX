import 'dart:io';

import 'package:aurora/main.dart';
import 'package:aurora/pages/onboarding_screens/login_page.dart';
import 'package:aurora/pages/user/profile.dart';
import 'package:aurora/pages/user/settings.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:iconsax/iconsax.dart';

class SettingsModal extends StatelessWidget {
  const SettingsModal({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    var box = Hive.box('login-data');
    final userInfo =
        box.get('userInfo', defaultValue: ['Guest', 'Guest', 'null']);
    final userName = userInfo?[0] ?? 'Guest';
    final avatarImagePath = userInfo?[2] ?? 'null';
    final isLoggedIn = userName != 'Guest';
    final hasAvatarImage = avatarImagePath != 'null';
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
              backgroundImage:
                  hasAvatarImage ? FileImage(File(avatarImagePath)) : null,
              child: hasAvatarImage
                  ? null
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
                    box.put('userInfo', ['Guest', 'Guest', null]);
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
          // ListTile(
          //   leading: const Icon(Iconsax.user),
          //   title: const Text('Login (Not Completed)'),
          //   onTap: () {
          //     Navigator.pushReplacement(
          //       context,
          //       MaterialPageRoute(builder: (context) => const LoginPage()),
          //     );
          //   },
          // ),
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
          ListTile(
            leading: const Icon(Iconsax.logout),
            title: const Text('Logout'),
            onTap: () {
              box.put('userInfo', ['Guest', 'Guest', null]);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const MainApp()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
