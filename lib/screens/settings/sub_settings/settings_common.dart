import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/custom_expansion_tile.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsCommon extends StatefulWidget {
  const SettingsCommon({super.key});

  @override
  State<SettingsCommon> createState() => _SettingsCommonState();
}

class _SettingsCommonState extends State<SettingsCommon> {
  final settings = Get.find<Settings>();

  @override
  Widget build(BuildContext context) {
    return Glow(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: getResponsiveValue(context,
                mobileValue: const EdgeInsets.fromLTRB(10.0, 50.0, 10.0, 20.0),
                desktopValue:
                    const EdgeInsets.fromLTRB(25.0, 50.0, 25.0, 20.0)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.surfaceContainer,
                      ),
                      onPressed: () {
                        Get.back();
                      },
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                    const SizedBox(width: 10),
                    const Text("Common ",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20)),
                  ],
                ),
                const SizedBox(height: 30),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnymexExpansionTile(
                        initialExpanded: true,
                        title: 'Anilist',
                        content: CustomTile(
                          icon: Icons.format_list_bulleted_sharp,
                          title: 'Manage Anilist Lists',
                          description: "Choose which list to show on home page",
                          onTap: () => _showHomePageCardsDialog(context, false),
                        )),
                    AnymexExpansionTile(
                        initialExpanded: true,
                        title: 'MyAnimeList',
                        content: CustomTile(
                          icon: Icons.format_list_bulleted_sharp,
                          title: 'Manage MyAnimeList Lists',
                          description: "Choose which list to show on home page",
                          onTap: () => _showHomePageCardsDialog(context, true),
                        )),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showHomePageCardsDialog(BuildContext context, bool isMal) {
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
              return ListView.builder(
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
