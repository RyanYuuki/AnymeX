import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/database/data_keys/general.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/custom_expansion_tile.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:flutter/material.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:get/get.dart';
import 'package:super_sliver_list/super_sliver_list.dart';
import 'package:anymex/screens/other_features.dart';

class SettingsCommon extends StatefulWidget {
  const SettingsCommon({super.key});

  @override
  State<SettingsCommon> createState() => _SettingsCommonState();
}

class _SettingsCommonState extends State<SettingsCommon> {
  final settings = Get.find<Settings>();
  late bool uniScrapper;
  late bool shouldAskForPermission = General.shouldAskForTrack.get(true);
  late bool hideAdultContent = General.hideAdultContent.get(true);
  bool get isMal => serviceHandler.serviceType.value.isMal;
  late Map<String, bool> homePageCards;

  @override
  void initState() {
    super.initState();
    uniScrapper = settingsController.preferences
        .get('universal_scrapper', defaultValue: false);
    homePageCards = isMal ? settings.homePageCardsMal : settings.homePageCards;
    homePageCards.putIfAbsent('Recommended Anime', () => true);
    homePageCards.putIfAbsent('Recommended Manga', () => true);
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
}
