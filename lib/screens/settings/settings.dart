import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/theme.dart';
import 'package:anymex/screens/settings/sub_settings/settings_about.dart';
import 'package:anymex/screens/settings/sub_settings/settings_accounts.dart';
import 'package:anymex/screens/settings/sub_settings/settings_common.dart';
import 'package:anymex/screens/settings/sub_settings/settings_player.dart';
import 'package:anymex/screens/settings/sub_settings/settings_theme.dart';
import 'package:anymex/screens/settings/sub_settings/settings_ui.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool test = false;
  @override
  Widget build(BuildContext context) {
    return Glow(
      child: Scaffold(
          body: ListView(
        padding: getResponsiveValue(context,
            mobileValue: const EdgeInsets.fromLTRB(10.0, 50.0, 15.0, 20.0),
            desktopValue: const EdgeInsets.fromLTRB(20.0, 50.0, 25.0, 20.0)),
        children: [
          const Row(
            children: [
              CustomBackButton(),
              SizedBox(width: 10),
              Text("Settings",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            ],
          ),
          const SizedBox(height: 30),
          CustomTile(
              icon: IconlyLight.profile,
              title: "Accounts",
              description: "Manage your MyAnimeList, Anilist, Simkl Accounts!",
              onTap: () {
                navigate(() => const SettingsAccounts());
              }),
          CustomTile(
              icon: HugeIcons.strokeRoundedBulb,
              title: "Common",
              description: "Tweak Settings",
              onTap: () {
                navigate(() => const SettingsCommon());
              }),
          CustomTile(
              icon: HugeIcons.strokeRoundedPaintBoard,
              title: "UI",
              description: "Play around with App UI",
              onTap: () {
                navigate(() => const SettingsUi());
              }),
          CustomTile(
              icon: HugeIcons.strokeRoundedPlay,
              title: "Player",
              description: "Play around with Player",
              onTap: () {
                navigate(() => const SettingsPlayer());
              }),
          CustomTile(
              icon: HugeIcons.strokeRoundedPaintBrush01,
              title: "Theme",
              description: "Play around with App theme",
              onTap: () {
                navigate(() => const SettingsTheme());
              }),
          CustomTile(
              icon: Iconsax.trash,
              title: "Clear Cache",
              description: "Clear all the settings.",
              onTap: () {
                showClearCacheDialog(context);
              }),
          const SizedBox(height: 10),
          CustomTile(
            icon: HugeIcons.strokeRoundedInformationCircle,
            title: "About",
            description: "About the App",
            onTap: () async {
              navigate(() => const AboutPage());
            },
          ),
        ],
      )),
    );
  }
}

class CustomBackButton extends StatelessWidget {
  const CustomBackButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.surfaceContainer),
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(Icons.arrow_back_ios_new_rounded));
  }
}

Future<void> showClearCacheDialog(BuildContext context) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        content: const Text(
            'Are you sure you want to clear the cache? (You gon lose your settings and library)'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                backgroundColor: Theme.of(context).colorScheme.primaryFixed),
            onPressed: () async {
              Get.find<OfflineStorageController>().clearCache();
              Provider.of<ThemeProvider>(context, listen: false).clearCache();
              Navigator.of(context).pop();
            },
            child: const Text(
              'Confirm',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      );
    },
  );
}
