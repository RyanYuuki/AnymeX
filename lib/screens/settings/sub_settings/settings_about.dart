import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/screens/settings/sub_settings/widgets/about_deps.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/anymex_animated_logo.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconsax/iconsax.dart';
import 'package:package_info_plus/package_info_plus.dart' show PackageInfo;
import 'package:url_launcher/url_launcher.dart';
import 'package:super_sliver_list/super_sliver_list.dart';
import 'package:http/http.dart' as http;

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

  Future<void> _fetchAndShowCommentPolicy(BuildContext context) async {
    snackBar('Fetching policy...');
    try {
      final response = await http.get(Uri.parse(
          'https://raw.githubusercontent.com/RyanYuuki/AnymeX/master/TOS.md'));

      if (response.statusCode == 200) {
        final text = response.body;
        const startMarker = '## Comments System & Comment Policy';
        final startIndex = text.indexOf(startMarker);

        if (startIndex != -1) {
          // Find the next header (##) to end the selection
          // Start searching after the start marker length
          final nextHeaderIndex = text.indexOf('## ', startIndex + startMarker.length);
          
          String policyText;
          if (nextHeaderIndex != -1) {
            policyText = text.substring(startIndex, nextHeaderIndex).trim();
          } else {
            policyText = text.substring(startIndex).trim();
          }

          // Show the modal 
          if (context.mounted) {
            _showPolicyModal(context, "Comment Policy", policyText);
          }
        } else {
          snackBar("Could not find policy section.", duration: 2000);
        }
      } else {
        snackBar("Failed to fetch policy.", duration: 2000);
      }
    } catch (e) {
      snackBar("Error fetching policy: $e", duration: 2000);
    }
  }

  void _showPolicyModal(BuildContext context, String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.12),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withOpacity(0.15),
                blurRadius: 32,
                offset: const Offset(0, -8),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 16, bottom: 8),
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.08),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close_rounded,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                        size: 20,
                      ),
                      splashRadius: 20,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: Scrollbar(
                    controller: scrollController,
                    thumbVisibility: true,
                    radius: const Radius.circular(8),
                    thickness: 6,
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                      child: Text(
                        content,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              height: 1.6,
                              letterSpacing: 0.2,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.85),
                              fontWeight: FontWeight.w400,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                        child: AnymeXAnimatedLogo(
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
                      await launchUrlHelper(
                          'https://github.com/itsmechinmoy/AnymeX/blob/master/TOS.md');
                    },
                    leading: const Icon(HugeIcons.strokeRoundedPolicy),
                    title: "Terms of Service/Privacy Policy",
                  ),
                  CustomListTile(
                    onTap: () async {
                      await _fetchAndShowCommentPolicy(context);
                    },
                    leading: const Icon(HugeIcons.strokeRoundedAlertSquare),
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
