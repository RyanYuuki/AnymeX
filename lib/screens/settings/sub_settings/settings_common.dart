import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/underrated_service.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/custom_expansion_tile.dart';
import 'package:anymex/widgets/custom_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:super_sliver_list/super_sliver_list.dart';
import 'package:anymex/screens/other_features.dart';
import 'dart:io';

class SettingsCommon extends StatefulWidget {
  const SettingsCommon({super.key});

  @override
  State<SettingsCommon> createState() => _SettingsCommonState();
}

class _SettingsCommonState extends State<SettingsCommon> {
  final settings = Get.find<Settings>();
  late bool uniScrapper;
  late bool shouldAskForPermission = General.shouldAskForTrack.get<bool>(true);
  late bool hideAdultContent = General.hideAdultContent.get<bool>(true);
  late bool showCommunityRecs =
      General.showCommunityRecommendations.get<bool>(true);
  late bool hideNsfwRecs = General.hideNsfwRecommendations.get<bool>(true);
  bool get isMal => serviceHandler.serviceType.value.isMal;
  late Map<String, bool> homePageCards;

  @override
  void initState() {
    super.initState();
    uniScrapper = General.universalScrapper.get<bool>(false);
    homePageCards = isMal ? settings.homePageCardsMal : settings.homePageCards;
    homePageCards.putIfAbsent('Recommended Animes', () => true);
    homePageCards.putIfAbsent('Recommended Mangas', () => true);
  }

  @override
  Widget build(BuildContext context) {
    return Glow(
      child: Scaffold(
        body: Column(
          children: [
            const NestedHeader(title: 'Common'),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: getResponsiveValue(context,
                      mobileValue:
                          const EdgeInsets.fromLTRB(10.0, 20.0, 10.0, 20.0),
                      desktopValue:
                          const EdgeInsets.fromLTRB(25.0, 20.0, 25.0, 20.0)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (Platform.isWindows || Platform.isLinux)
                        AnymexExpansionTile(
                          initialExpanded: true,
                          title: 'Bridge Settings (Desktop)',
                          content: Column(
                            children: [
                              Obx(() => CustomTile(
                                    icon: Icons.settings_input_component_rounded,
                                    title: 'Bridge Mode (Requires Restart)',
                                    description: settings.bridgeMode.value == 'jni'
                                        ? 'JNI Mode is on. its okay ig might crash here & there.'
                                        : 'Sidecar Mode is on. might be a lil slow than Jni but its reliable.',
                                    onTap: () => _showBridgeModeDialog(),
                                  )),
                            ],
                          ),
                        ),
                      AnymexExpansionTile(
                        initialExpanded: true,
                        title: 'Universal',
                        content: Column(
                          children: [
                            CustomSwitchTile(
                                icon: Icons.touch_app_rounded,
                                title: 'Ask for tracking permission',
                                description:
                                    'If enabled, Anymex will ask for tracking permission if not then it will track by default.',
                                switchValue: shouldAskForPermission,
                                onChanged: (e) {
                                  setState(() {
                                    shouldAskForPermission = e;
                                    General.shouldAskForTrack.set(e);
                                  });
                                }),
                            CustomSwitchTile(
                                icon: Icons.play_disabled_rounded,
                                title: 'Hide Adult Content',
                                description:
                                    'If enabled, you will not get a prompt for enabling adult content on Anilist/MyAnimeList.',
                                switchValue: hideAdultContent,
                                onChanged: (e) {
                                  setState(() {
                                    hideAdultContent = e;
                                    General.hideAdultContent.set(e);
                                  });
                                }),
                            Obx(
                              () => CustomSwitchTile(
                                icon: Icons.play_circle_fill_rounded,
                                title: 'Show Continue Watching Card',
                                description:
                                    'Display Continue Watching cards on home page from offline progress.',
                                switchValue: settings.showContinueWatchingCard,
                                onChanged: (e) =>
                                    settings.showContinueWatchingCard = e,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnymexExpansionTile(
                        initialExpanded: true,
                        title: 'Community Recommendations',
                        content: Column(
                          children: [
                            CustomSwitchTile(
                              icon: Icons.people_rounded,
                              title: 'Show Community Recommendations',
                              description:
                                  'Display anime, manga, movies and shows recommended by the community on the home page.',
                              switchValue: showCommunityRecs,
                              onChanged: (e) {
                                setState(() {
                                  showCommunityRecs = e;
                                  General.showCommunityRecommendations.set(e);
                                  Get.find<UnderratedService>().communityEnabled.value = e;
                                });
                              },
                            ),
                            CustomSwitchTile(
                              icon: Icons.no_adult_content_rounded,
                              title: 'Hide NSFW Recommendations',
                              description:
                                  'Filter out adult/NSFW entries from community recommendations. Enabled by default.',
                              switchValue: hideNsfwRecs,
                              onChanged: (e) {
                                setState(() {
                                  hideNsfwRecs = e;
                                  General.hideNsfwRecommendations.set(e);
                                  Get.find<UnderratedService>().hideNsfw.value = e;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      AnymexExpansionTile(
                          initialExpanded: true,
                          title: 'Anilist',
                          content: CustomTile(
                            icon: Icons.format_list_bulleted_sharp,
                            title: 'Manage Anilist Lists',
                            description:
                                "Choose which list to show on home page",
                            onTap: () => _showHomePageCardsDialog(),
                          )),
                      AnymexExpansionTile(
                          initialExpanded: true,
                          title: 'MyAnimeList',
                          content: CustomTile(
                            icon: Icons.format_list_bulleted_sharp,
                            title: 'Manage MyAnimeList Lists',
                            description:
                                "Choose which list to show on home page",
                            onTap: () => _showHomePageCardsDialog(),
                          )),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHomePageCardsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Manage Home Page Cards"),
          content: SizedBox(
            width: double.maxFinite,
            child: Obx(() {
              final homePageCards =
                  isMal ? settings.homePageCardsMal : settings.homePageCards;
              return SuperListView.builder(
                shrinkWrap: true,
                itemCount: homePageCards.length,
                itemBuilder: (context, index) {
                  final key = homePageCards.keys.elementAt(index);
                  final value = homePageCards[key]!;

                  return CheckboxListTile(
                    title: Text(key),
                    value: value,
                    onChanged: (bool? newValue) {
                      if (newValue != null) {
                        isMal
                            ? settings.updateHomePageCardMal(key, newValue)
                            : settings.updateHomePageCard(key, newValue);
                      }
                    },
                  );
                },
              );
            }),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  void _showBridgeModeDialog() {
    final tempBridgeMode = settings.bridgeMode.value.obs;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Obx(
          () => AnymexDialog(
            title: 'Bridge Mode (If selecting one, dont forget to restart gang)',
            onConfirm: () => settings.saveBridgeMode(tempBridgeMode.value),
            contentWidget: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _BridgeModeOptionTile(
                  title: 'JNI Mode',
                  subtitle:
                      'Runs Java in the same process as the app.',
                  isSelected: tempBridgeMode.value == 'jni',
                  onTap: () => tempBridgeMode.value = 'jni',
                ),
                const SizedBox(height: 12),
                _BridgeModeOptionTile(
                  title: 'Sidecar Mode',
                  subtitle:
                      'Runs Java in a separate process, this one is more chill.',
                  isSelected: tempBridgeMode.value == 'sidecar',
                  onTap: () => tempBridgeMode.value = 'sidecar',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BridgeModeOptionTile extends StatelessWidget {
  const _BridgeModeOptionTile({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? context.colors.primaryContainer.opaque(0.35)
                : context.colors.surfaceContainerHighest.opaque(0.35),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? context.colors.primary.opaque(0.4)
                  : context.colors.outline.opaque(0.2),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnymexText(
                      text: title,
                      variant: TextVariant.semiBold,
                    ),
                    const SizedBox(height: 4),
                    AnymexText(
                      text: subtitle,
                      size: 12,
                      color: context.colors.onSurface.opaque(0.7),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: isSelected
                    ? context.colors.primary
                    : context.colors.onSurface.opaque(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
