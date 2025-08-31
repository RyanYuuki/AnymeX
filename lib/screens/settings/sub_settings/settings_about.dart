import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/screens/settings/sub_settings/widgets/about_deps.dart';
import 'package:anymex/utils/updater.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconsax/iconsax.dart';
import 'package:package_info_plus/package_info_plus.dart' show PackageInfo;
import 'package:url_launcher/url_launcher.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

Future<void> launchUrlHelper(String link) async {
  final url = Uri.parse(link);
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } else {
    throw 'Could not launch $link';
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Glow(
      child: Scaffold(
        body: SuperListView(
          padding: const EdgeInsets.fromLTRB(15.0, 50.0, 15.0, 20.0),
          children: [
            const HeaderSection(),
            const SizedBox(height: 16),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.surfaceContainer.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 50),
                          FutureBuilder<PackageInfo>(
                            future: PackageInfo.fromPlatform(),
                            builder: (context, snapshot) {
                              final version = snapshot.hasData
                                  ? snapshot.data!.version
                                  : '';
                              return ProfileInfo(
                                username: "AnymeX",
                                version: "v$version",
                                subtitle: "",
                              );
                            },
                          ),
                          InfoCard(
                            onTap: () async {
                              await launchUrlHelper(
                                  'https://github.com/RyanYuuki');
                            },
                            leading: const CircleAvatar(
                              backgroundImage: NetworkImage(
                                  'https://avatars.githubusercontent.com/u/108048963?s=400&u=7f67531c27c5ebbbcde943f9576a0bfdb98909c8&v=4'),
                            ),
                            title: "Developer",
                            subtitle: "RyanYuuki",
                            trailing: IconButton(
                              onPressed: () async {
                                await launchUrlHelper(
                                    'https://github.com/RyanYuuki');
                              },
                              icon: const Icon(Iconsax.code5),
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: -5,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.primary,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          backgroundColor: theme.colorScheme.surfaceContainer,
                          child: Image.asset(
                            'assets/images/logo_transparent.png',
                            fit: BoxFit.cover,
                          ),
                        )),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainer
                      .withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12)),
              child: CustomSection(
                icon: Iconsax.link_circle,
                title: "Social",
                subtitle: "Join us for dropping feedback or feature requests",
                items: [
                  CustomListTile(
                    onTap: () async {
                      await launchUrlHelper('https://t.me/AnymeX_Discussion');
                    },
                    leading: const Icon(HugeIcons.strokeRoundedTelegram),
                    title: "Telegram",
                  ),
                  CustomListTile(
                    onTap: () async {
                      await launchUrlHelper('https://discord.gg/5gAHhMvTcx');
                    },
                    leading: const Icon(HugeIcons.strokeRoundedDiscord),
                    title: "Discord",
                  ),
                  CustomListTile(
                    onTap: () async {
                      await launchUrlHelper(
                          'https://www.reddit.com/r/AnymeX_/');
                    },
                    leading: const Icon(HugeIcons.strokeRoundedReddit),
                    title: "Reddit",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: CustomSection(
                icon: Iconsax.code_circle,
                title: "Development",
                subtitle: "Explore the project and contribute",
                items: [
                  CustomListTile(
                    onTap: () async {
                      await launchUrlHelper(
                          'https://github.com/RyanYuuki/AnymeX');
                    },
                    leading: const Icon(HugeIcons.strokeRoundedGithub),
                    title: "GitHub",
                    subtitle: 'View Source code on github.',
                  ),
                  CustomListTile(
                    onTap: () async {
                      await launchUrlHelper('https://ko-fi.com/ryanyuuki7');
                    },
                    leading: const Icon(HugeIcons.strokeRoundedCoffee01),
                    title: "Ko-fi",
                    subtitle:
                        "Consider donating to support the maintainer of AnymeX",
                  ),
                  CustomListTile(
                    onTap: () async {
                      await launchUrlHelper(
                          'https://github.com/RyanYuuki/AnymeX/issues');
                    },
                    leading: const Icon(Icons.bug_report),
                    title: "Features/Issues",
                    subtitle:
                        'if you have an issue or any suggestion please make an issue at github.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: CustomSection(
                icon: Iconsax.info_circle,
                title: "Others",
                subtitle: "Other Stuffs",
                items: [
                  CustomListTile(
                    onTap: () async {
                      snackBar('Checking for updates!');
                      Get.find<Settings>().checkForUpdates(context);
                    },
                    leading: const Icon(Icons.system_update),
                    title: "Check for Updates",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
