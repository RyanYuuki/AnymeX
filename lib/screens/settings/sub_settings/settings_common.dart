import 'dart:convert';
import 'dart:io';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/community_service.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile_builder.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
  bool get isMal => serviceHandler.serviceType.value.isMal;
  late Map<String, bool> homePageCards;
  late bool unifiedLibrary = General.unifiedLibrary.get<bool>(true);

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
    return AnymeXScaffold(
      showHeader: true,
      headerTitle: 'Common Settings',
      body: Builder(
          builder: (ctx) => SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    16.0, AnymeXHeaderScope.of(ctx), 16.0, 30.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (Platform.isWindows || Platform.isLinux)
                      AnymeXSectionBuilder(
                        title: 'Bridge Settings (Desktop)',
                        children: [
                          Obx(() => AnymeXTile(
                                icon: Icons.settings_input_component_rounded,
                                title: 'Bridge Mode (Requires Restart)',
                                subtitle: settings.bridgeMode.value == 'jni'
                                    ? 'JNI Mode is on. Reliable performance.'
                                    : 'Sidecar Mode is on. Independent process.',
                                onTap: () => _showBridgeModeDialog(),
                              )),
                        ],
                      ),
                    AnymeXSectionBuilder(
                      title: 'Universal',
                      children: [
                        AnymeXTile.toggle(
                          icon: Icons.touch_app_rounded,
                          title: 'Ask for tracking permission',
                          subtitle:
                              'If enabled, Anymex will ask for tracking permission if not then it will track by default.',
                          value: shouldAskForPermission,
                          onChanged: (e) {
                            setState(() {
                              shouldAskForPermission = e;
                              General.shouldAskForTrack.set(e);
                            });
                          },
                        ),
                        AnymeXTile.toggle(
                          icon: Icons.collections_bookmark_rounded,
                          title: 'Unified Library',
                          subtitle:
                              'If enabled, all library items will be shared across all tracking services.',
                          value: unifiedLibrary,
                          onChanged: (e) {
                            setState(() {
                              unifiedLibrary = e;
                              General.unifiedLibrary.set(e);
                            });
                          },
                        ),
                        AnymeXTile.toggle(
                          icon: Icons.play_disabled_rounded,
                          title: 'Hide Adult Content',
                          subtitle:
                              'If enabled, you will not get a prompt for enabling adult content on Anilist/MyAnimeList.',
                          value: hideAdultContent,
                          onChanged: (e) {
                            setState(() {
                              hideAdultContent = e;
                              General.hideAdultContent.set(e);
                            });
                          },
                        ),
                      ],
                    ),
                    AnymeXSectionBuilder(
                      title: 'Community Recommendations',
                      children: [
                        AnymeXTile.toggle(
                          icon: Icons.people_rounded,
                          title: 'Show Community Recommendations',
                          subtitle:
                              'Display anime, manga, movies and shows recommended by the community on the home page.',
                          value: showCommunityRecs,
                          onChanged: (e) {
                            setState(() {
                              showCommunityRecs = e;
                              General.showCommunityRecommendations.set(e);
                              Get.find<CommunityService>()
                                  .communityEnabled
                                  .value = e;
                            });
                          },
                        ),
                        Obx(() {
                          final svc = Get.find<CommunityService>();
                          return AnymeXTile.toggle(
                            icon: Icons.no_adult_content_rounded,
                            title: 'Hide NSFW Recommendations',
                            subtitle:
                                'Filter out adult/NSFW entries from community recommendations.',
                            value: svc.hideNsfw.value,
                            onChanged: (v) {
                              svc.hideNsfw.value = v;
                              General.hideNsfwRecommendations.set(v);
                            },
                          );
                        }),
                        Obx(() {
                          final svc = Get.find<CommunityService>();
                          return AnymeXTile.toggle(
                            icon: Icons.filter_list_rounded,
                            title: 'Hide by List Status',
                            subtitle:
                                'Filter out entries already in your list based on watching/reading status.',
                            value: svc.filterByListEnabled.value,
                            onChanged: (v) {
                              svc.filterByListEnabled.value = v;
                              General.filterByListEnabled.set(v);
                            },
                          );
                        }),
                        Obx(() {
                          final svc = Get.find<CommunityService>();
                          if (!svc.filterByListEnabled.value) {
                            return const SizedBox.shrink();
                          }
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnymeXTile.toggle(
                                icon: Icons.check_circle_outline_rounded,
                                title: 'Hide Completed',
                                subtitle:
                                    'Hide entries that are marked as completed in your list.',
                                value: svc.filterCompleted.value,
                                onChanged: (v) {
                                  svc.filterCompleted.value = v;
                                  General.filterCompleted.set(v);
                                },
                              ),
                              AnymeXTile.toggle(
                                icon: Icons.remove_red_eye_outlined,
                                title: 'Hide Watching / Reading',
                                subtitle:
                                    'Hide entries that you are currently watching or reading.',
                                value: svc.filterWatching.value,
                                onChanged: (v) {
                                  svc.filterWatching.value = v;
                                  General.filterWatching.set(v);
                                },
                              ),
                              AnymeXTile.toggle(
                                icon: Icons.cancel_outlined,
                                title: 'Hide Dropped',
                                subtitle: 'Hide entries that you have dropped.',
                                value: svc.filterDropped.value,
                                onChanged: (v) {
                                  svc.filterDropped.value = v;
                                  General.filterDropped.set(v);
                                },
                              ),
                              AnymeXTile.toggle(
                                icon: Icons.event_note_outlined,
                                title: 'Hide Planning',
                                subtitle:
                                    'Hide entries that are in your plan list.',
                                value: svc.filterPlanning.value,
                                onChanged: (v) {
                                  svc.filterPlanning.value = v;
                                  General.filterPlanning.set(v);
                                },
                              ),
                              AnymeXTile.toggle(
                                icon: Icons.pause_circle_outline_rounded,
                                title: 'Hide On Hold / Paused',
                                subtitle:
                                    'Hide entries that you have put on hold.',
                                value: svc.filterPaused.value,
                                onChanged: (v) {
                                  svc.filterPaused.value = v;
                                  General.filterPaused.set(v);
                                },
                              ),
                              AnymeXTile.toggle(
                                icon: Icons.replay_rounded,
                                title: 'Hide Rewatching',
                                subtitle:
                                    'Hide entries that you are rewatching.',
                                value: svc.filterRepeating.value,
                                onChanged: (v) {
                                  svc.filterRepeating.value = v;
                                  General.filterRepeating.set(v);
                                },
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                    AnymeXSectionBuilder(
                      title: 'Anilist',
                      children: [
                        AnymeXTile(
                          icon: Icons.format_list_bulleted_sharp,
                          title: 'Manage Anilist Lists',
                          subtitle: "Choose which list to show on home page",
                          onTap: () =>
                              _showHomePageCardsDialog(ServicesType.anilist),
                        ),
                      ],
                    ),
                    AnymeXSectionBuilder(
                      title: 'MyAnimeList',
                      children: [
                        AnymeXTile(
                          icon: Icons.format_list_bulleted_sharp,
                          title: 'Manage MyAnimeList Lists',
                          subtitle: "Choose which list to show on home page",
                          onTap: () =>
                              _showHomePageCardsDialog(ServicesType.mal),
                        ),
                      ],
                    ),
                    AnymeXSectionBuilder(
                      title: 'Simkl',
                      children: [
                        AnymeXTile(
                          icon: Icons.format_list_bulleted_sharp,
                          title: 'Manage Simkl Lists',
                          subtitle: "Choose which list to show on home page",
                          onTap: () =>
                              _showHomePageCardsDialog(ServicesType.simkl),
                        ),
                      ],
                    ),
                  ],
                ),
              )),
    );
  }

  void _showHomePageCardsDialog([ServicesType? serviceType]) {
    final type = serviceType ?? serviceHandler.serviceType.value;
    final Map<String, bool> targetCards = type.isMal
        ? settings.homePageCardsMal
        : type.isAL
            ? settings.homePageCards
            : settings.homePageCardsSimkl;

    final defaultKeys = type.isMal
        ? [
            'Watching Anime',
            'Reading Manga',
            'Plan to Watch Anime',
            'Plan to Read Manga',
            'Completed Anime',
            'Completed Manga',
            'On-Hold Anime',
            'On-Hold Manga',
            'Dropped Anime',
            'Dropped Manga',
          ]
        : type.isAL
            ? [
                'Watching Anime',
                'Reading Manga',
                'Plan to Watch Anime',
                'Plan to Read Manga',
                'Completed Anime',
                'Completed Manga',
                'Paused Anime',
                'Paused Manga',
                'Dropped Anime',
                'Dropped Manga',
              ]
            : [
                'Watching Anime',
                'Reading Manga',
                'Plan to Watch Anime',
                'Plan to Read Manga',
                'Completed Anime',
                'Completed Manga',
                'Hold Anime',
                'Hold Manga',
                'Dropped Anime',
                'Dropped Manga',
              ];

    for (var key in defaultKeys) {
      targetCards.putIfAbsent(key, () => true);
    }

    final localState = Map<String, bool>.from(targetCards);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AnymeXDialog(
            title: 'Home Page Cards (${type.name.toUpperCase()})',
            contentWidget: AnymeXTileBuilder<String>(
              items: localState.keys.toList(),
              isSelected: (key) => localState[key] ?? true,
              isRadio: false,
              getTitle: (key) => key,
              onItemPressed: (key) {
                setDialogState(() {
                  localState[key] = !(localState[key] ?? true);
                });
              },
            ),
            onConfirm: () {
              targetCards.clear();
              targetCards.addAll(localState);
              if (type.isMal) {
                settings.uiSettings.update((s) =>
                    s?.homePageCardsMal = Map<String, bool>.from(localState));
                UISettingsKeys.homePageCardsMal.set(jsonEncode(localState));
              } else if (type.isAL) {
                settings.uiSettings.update((s) =>
                    s?.homePageCards = Map<String, bool>.from(localState));
                UISettingsKeys.homePageCards.set(jsonEncode(localState));
              } else {
                settings.uiSettings.update((s) =>
                    s?.homePageCardsSimkl = Map<String, bool>.from(localState));
                UISettingsKeys.homePageCardsSimkl.set(jsonEncode(localState));
              }
            },
          );
        },
      ),
    );
  }

  void _showBridgeModeDialog() {
    showDialog(
      context: context,
      builder: (context) => AnymeXDialog(
        title: 'Select Bridge Mode',
        showCancelButton: false,
        confirmText: 'Dismiss',
        onConfirm: () {},
        contentWidget: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnymeXTile.radio(
              title: 'JNI Mode (Recommended)',
              subtitle: 'Faster performance and direct integration.',
              selected: settings.bridgeMode.value == 'jni',
              onTap: () {
                settings.saveBridgeMode('jni');
                Navigator.pop(context);
                snackBar('Bridge Mode set to JNI. Restart required.');
              },
            ),
            const SizedBox(height: 8),
            AnymeXTile.radio(
              title: 'Sidecar Mode',
              subtitle: 'Separate process, higher stability.',
              selected: settings.bridgeMode.value == 'sidecar',
              onTap: () {
                settings.saveBridgeMode('sidecar');
                Navigator.pop(context);
                snackBar('Bridge Mode set to Sidecar. Restart required.');
              },
            ),
          ],
        ),
      ),
    );
  }
}
