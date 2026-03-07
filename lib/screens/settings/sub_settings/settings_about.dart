import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/screens/other_features.dart';
import 'package:anymex/screens/settings/sub_settings/widgets/about_deps.dart';
import 'package:anymex/screens/settings/sub_settings/contributors.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/common/policy_sheet.dart';
import 'package:anymex/widgets/custom_widgets/anymex_animated_logo.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconsax/iconsax.dart';
import 'package:package_info_plus/package_info_plus.dart' show PackageInfo;
import 'package:super_sliver_list/super_sliver_list.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> launchUrlHelper(String link) async {
  final url = Uri.parse(link);
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } else {
    throw 'Could not launch $link';
  }
}

class _EndorsedFork {
  final String name;
  final String description;
  final String repoUrl;
  final String devName;
  final String devAvatarUrl;
  final String devProfileUrl;
  final String? discordUrl;

  const _EndorsedFork({
    required this.name,
    required this.description,
    required this.repoUrl,
    required this.devName,
    required this.devAvatarUrl,
    required this.devProfileUrl,
    this.discordUrl,
  });
}

const List<_EndorsedFork> _endorsedForks = [
  _EndorsedFork(
    name: 'NyanTV',
    description: 'AnymeX fork optimised for TV',
    repoUrl: 'https://github.com/NyanTV/NyanTV',
    devName: 'hoemotion',
    devAvatarUrl: 'https://avatars.githubusercontent.com/u/86238378?v=4',
    devProfileUrl: 'https://github.com/hoemotion',
    discordUrl: 'https://discord.gg/WWCdh2NpUv',
  ),
];

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Glow(
      child: Scaffold(
        body: Column(
          children: [
            const NestedHeader(title: 'About'),
            Expanded(
              child: SuperListView(
                padding: const EdgeInsets.fromLTRB(15.0, 20.0, 15.0, 20.0),
                children: [
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
                              color: theme.colorScheme.surfaceContainer
                                  .opaque(0.5),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .opaque(0.1, iReallyMeanIt: true),
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
                                    color: Colors.black
                                        .opaque(0.2, iReallyMeanIt: true),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const AnymeXAnimatedLogo(
                                size: 70,
                                autoPlay: true,
                              )),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                        color: context.colors.surfaceContainer.opaque(0.5),
                        borderRadius: BorderRadius.circular(12)),
                    child: CustomSection(
                      icon: Iconsax.link_circle,
                      title: "Social",
                      subtitle:
                          "Join us for dropping feedback or feature requests",
                      items: [
                        CustomListTile(
                          onTap: () async {
                            await launchUrlHelper(
                                'https://t.me/AnymeX_Discussion');
                          },
                          leading: const Icon(HugeIcons.strokeRoundedTelegram),
                          title: "Telegram",
                        ),
                        CustomListTile(
                          onTap: () async {
                            await launchUrlHelper(
                                'https://discord.gg/5gAHhMvTcx');
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
                      color: theme.colorScheme.surfaceContainer.opaque(0.5),
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
                            await launchUrlHelper(
                                'https://ko-fi.com/ryanyuuki7');
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
                        CustomListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ContributorsPage(),
                              ),
                            );
                          },
                          leading: const Icon(Icons.group),
                          title: "Contributors",
                          subtitle: 'Meet the people who helped build AnymeX.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer.opaque(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CustomSection(
                      icon: Iconsax.copy,
                      title: "Endorsed Forks",
                      subtitle: "Community forks officially endorsed by AnymeX",
                      items: [
                        for (final fork in _endorsedForks)
                          _EndorsedForkTile(fork: fork),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer.opaque(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CustomSection(
                      icon: Iconsax.info_circle,
                      title: "Others",
                      subtitle: "Other Stuffs",
                      items: [
                        CustomListTile(
                          onTap: () async {
                            await showPolicySheet(context, PolicyType.tos);
                          },
                          leading: const Icon(HugeIcons.strokeRoundedPolicy),
                          title: "Terms of Service/Privacy Policy",
                        ),
                        CustomListTile(
                          onTap: () async {
                            await showPolicySheet(
                                context, PolicyType.commentPolicy);
                          },
                          leading:
                              const Icon(HugeIcons.strokeRoundedAlertSquare),
                          title: "Comment Policy",
                        ),
                        CustomListTile(
                          onTap: () async {
                            snackBar('Checking for updates!');
                            Get.find<Settings>().checkForUpdates(context);
                          },
                          leading: const Icon(Icons.system_update),
                          title: "Check for Updates",
                        ),
                        // Enable Beta Updates (Toggle)
                        CustomListTile(
                          leading: const Icon(Iconsax.toggle_on),
                          title: "Enable Beta Updates",
                          subtitle: "Check updates from beta channel",
                          trailing: Obx(
                            () => Switch(
                              value: Get.find<Settings>().enableBetaUpdates.value,
                              onChanged: (value) {
                                Get.find<Settings>().saveBetaUpdateToggle(value);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EndorsedForkTile extends StatelessWidget {
  const _EndorsedForkTile({required this.fork});

  final _EndorsedFork fork;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: () async => launchUrlHelper(fork.repoUrl),
      leading: CircleAvatar(
        backgroundImage: NetworkImage(fork.devAvatarUrl),
        backgroundColor: Colors.transparent,
      ),
      title: Text(
        fork.name,
        style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fork.description,
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
          ),
          Text(
            'by ${fork.devName}',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'GitHub',
            icon: const Icon(HugeIcons.strokeRoundedGithub),
            onPressed: () async => launchUrlHelper(fork.repoUrl),
          ),
          if (fork.discordUrl != null)
            IconButton(
              tooltip: 'Discord',
              icon: const Icon(HugeIcons.strokeRoundedDiscord),
              onPressed: () async => launchUrlHelper(fork.discordUrl!),
            ),
        ],
      ),
    );
  }
}

class ContributorsPage extends StatelessWidget {
  const ContributorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Glow(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Contributors',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Contributors.getContributorsWidget(context),
        ),
      ),
    );
  }
}
