import 'package:anymex/screens/settings/sub_settings/settings_about.dart';
import 'package:anymex/screens/settings/sub_settings/settings_accounts.dart';
import 'package:anymex/screens/settings/sub_settings/settings_common.dart';
import 'package:anymex/screens/settings/sub_settings/settings_experimental.dart';
import 'package:anymex/screens/settings/sub_settings/settings_extensions.dart';
import 'package:anymex/screens/settings/sub_settings/settings_player.dart';
import 'package:anymex/screens/settings/sub_settings/settings_theme.dart';
import 'package:anymex/screens/settings/sub_settings/settings_ui.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    return Glow(
      child: Scaffold(
          body: SuperListView(
        padding: getResponsiveValue(context,
            mobileValue: const EdgeInsets.fromLTRB(10.0, 50.0, 10.0, 20.0),
            desktopValue: const EdgeInsets.fromLTRB(20.0, 50.0, 25.0, 20.0)),
        children: [
          const Row(
            children: [
              CustomBackButton(),
              SizedBox(width: 10),
              Text(l10n?.settings ?? "Settings",
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
                    title: l10n?.accounts ?? "Accounts",
                    description:
                        l10n?.accountsDescription ?? "Manage your MyAnimeList, Anilist, Simkl Accounts!",
                    onTap: () {
                      navigate(() => const SettingsAccounts());
                    }),
                CustomTile(
                    icon: HugeIcons.strokeRoundedBulb,
                    title: l10n?.common ?? "Common",
                    description: l10n?.commonDescription ?? "Tweak Settings",
                    onTap: () {
                      navigate(() => const SettingsCommon());
                    }),
                CustomTile(
                    icon: HugeIcons.strokeRoundedPaintBoard,
                    title: l10n?.ui ?? "UI",
                    description: l10n?.uiDescription ?? "Play around with App UI",
                    onTap: () {
                      navigate(() => const SettingsUi());
                    }),
                CustomTile(
                    icon: HugeIcons.strokeRoundedPlay,
                    title: l10n?.player ?? "Player",
                    description: l10n?.playerDescription ?? "Play around with Player",
                    onTap: () {
                      navigate(() => const SettingsPlayer());
                    }),
                CustomTile(
                    icon: HugeIcons.strokeRoundedPaintBrush01,
                    title: l10n?.theme ?? "Theme",
                    description: l10n?.themeDescription ?? "Play around with App theme",
                    onTap: () {
                      navigate(() => const SettingsTheme());
                    }),
                const SizedBox(height: 10),
                CustomTile(
                    icon: Icons.extension_rounded,
                    title: l10n?.extensions ?? "Extensions",
                    description: l10n?.extensionsDescription ?? "Extensions that tends to your needs",
                    onTap: () {
                      navigate(() => const SettingsExtensions());
                    }),
                const SizedBox(height: 10),
                CustomTile(
                  icon: HugeIcons.strokeRoundedInformationCircle,
                  title: l10n?.experimental ?? "Experimental",
                  description:
                      l10n?.experimentalDescription ?? "Experimental Settings that are still being tested.",
                  onTap: () async {
                    navigate(() => const SettingsExperimental());
                  },
                ),
                const SizedBox(height: 10),
                CustomTile(
                  icon: HugeIcons.strokeRoundedFile01,
                  title: l10n?.shareLogs ?? "Share Logs",
                  description: l10n?.shareLogsDescription ?? "Share Logs of the App",
                  onTap: () async => await Logger.share(),
                ),
                const SizedBox(height: 10),
                CustomTile(
                  icon: HugeIcons.strokeRoundedInformationCircle,
                  title: l10n?.about ?? "About",
                  description: l10n?.aboutDescription ?? "About the App",
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
