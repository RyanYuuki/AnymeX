import 'package:anymex/screens/settings/sub_settings/settings_about.dart';
import 'package:anymex/screens/settings/sub_settings/settings_accounts.dart';
import 'package:anymex/screens/settings/sub_settings/settings_common.dart';
import 'package:anymex/screens/settings/sub_settings/settings_experimental.dart';
import 'package:anymex/screens/settings/sub_settings/settings_extensions.dart';
import 'package:anymex/screens/settings/sub_settings/settings_player.dart';
import 'package:anymex/screens/settings/sub_settings/settings_theme.dart';
import 'package:anymex/screens/settings/sub_settings/settings_ui.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/get_string.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconly/iconly.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    GetString.init(context);
    return Glow(
      child: Scaffold(
          body: SuperListView(
        padding: getResponsiveValue(context,
            mobileValue: const EdgeInsets.fromLTRB(10.0, 50.0, 10.0, 20.0),
            desktopValue: const EdgeInsets.fromLTRB(20.0, 50.0, 25.0, 20.0)),
        children: [
          Row(
            children: [
              const CustomBackButton(),
              const SizedBox(width: 10),
              Text(GetString.settings,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            ],
          ),
          const SizedBox(height: 30),
          Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainer
                    .withOpacity(0.3)),
            child: Column(
              children: [
                CustomTile(
                    icon: IconlyLight.profile,
                    title: GetString.accounts,
                    description: GetString.accountsDescription,
                    onTap: () {
                      navigate(() => const SettingsAccounts());
                    }),
                CustomTile(
                    icon: HugeIcons.strokeRoundedBulb,
                    title: GetString.common,
                    description: GetString.commonDescription,
                    onTap: () {
                      navigate(() => const SettingsCommon());
                    }),
                CustomTile(
                    icon: HugeIcons.strokeRoundedPaintBoard,
                    title: GetString.ui,
                    description: GetString.uiDescription,
                    onTap: () {
                      navigate(() => const SettingsUi());
                    }),
                CustomTile(
                    icon: HugeIcons.strokeRoundedPlay,
                    title: GetString.player,
                    description: GetString.playerDescription,
                    onTap: () {
                      navigate(() => const SettingsPlayer());
                    }),
                CustomTile(
                    icon: HugeIcons.strokeRoundedPaintBrush01,
                    title: GetString.theme,
                    description: GetString.themeDescription,
                    onTap: () {
                      navigate(() => const SettingsTheme());
                    }),
                const SizedBox(height: 10),
                CustomTile(
                    icon: Icons.extension_rounded,
                    title: GetString.extensions,
                    description: GetString.extensionsDescription,
                    onTap: () {
                      navigate(() => const SettingsExtensions());
                    }),
                const SizedBox(height: 10),
                CustomTile(
                  icon: HugeIcons.strokeRoundedInformationCircle,
                  title: GetString.experimental,
                  description: GetString.experimentalDescription,
                  onTap: () async {
                    navigate(() => const SettingsExperimental());
                  },
                ),
                const SizedBox(height: 10),
                CustomTile(
                  icon: HugeIcons.strokeRoundedFile01,
                  title: GetString.shareLogs,
                  description: GetString.shareLogsDescription,
                  onTap: () async => await Logger.share(),
                ),
                const SizedBox(height: 10),
                CustomTile(
                  icon: HugeIcons.strokeRoundedInformationCircle,
                  title: GetString.about,
                  description: GetString.aboutDescription,
                  onTap: () async {
                    navigate(() => const AboutPage());
                  },
                ),
                // const SizedBox(height: 10),
                // CustomTile(
                //   icon: HugeIcons.strokeRoundedInformationCircle,
                //   title: "Stats",
                //   description: "Stats of Lists",
                //   onTap: () async {
                //     navigate(() => const StatisticsPage());
                //   },
                // ),
              ],
            ),
          ),
          30.height(),
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
            backgroundColor: Theme.of(context)
                .colorScheme
                .surfaceContainer
                .withOpacity(0.5)),
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(Icons.arrow_back_ios_new_rounded));
  }
}
