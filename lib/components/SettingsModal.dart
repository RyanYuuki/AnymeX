import 'package:aurora/pages/home_page.dart';
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
    final box = Hive.box('login-data');
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
    );
  }
}
