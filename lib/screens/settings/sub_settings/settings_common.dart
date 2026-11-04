import 'dart:convert';

import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/community_service.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile_builder.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:anymex/l10n/locale_controller.dart';
import 'package:anymex/l10n/locale_keys.dart';

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
  late bool unifiedLibrary = General.unifiedLibrary.get<bool>(true);

  @override
  void initState() {
    super.initState();
    uniScrapper = General.universalScrapper.get<bool>(false);
  }

  @override
  Widget build(BuildContext context) {
    return AnymeXScaffold(
      showHeader: true,
      headerTitle: 'Common Settings'.tr,
      body: Builder(
          builder: (ctx) => SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    16.0, AnymeXHeaderScope.of(ctx), 16.0, 30.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnymeXSectionBuilder(
                      title: 'Universal'.tr,
                      children: [
                        Obx(() {
                          final localeController = Get.find<LocaleController>();
                          return AnymeXTile(
                            icon: Icons.language_rounded,
                            title: LocaleKeys.labelLanguage.tr,
                            subtitle:
                                '${localeController.currentLanguageNativeName} (${localeController.currentLanguageName})',
                            onTap: () => _showLanguageDialog(context),
                          );
                        }),
                        AnymeXTile.toggle(
                          icon: Icons.touch_app_rounded,
                          title: 'Ask for tracking permission'.tr,
                          subtitle:
                              'If enabled, Anymex will ask for tracking permission if not then it will track by default.'.tr,
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
                          title: 'Unified Library'.tr,
                          subtitle:
                              'If enabled, all library items will be shared across all tracking services.'.tr,
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
                          title: 'Hide Adult Content'.tr,
                          subtitle:
                              'If enabled, you will not get a prompt for enabling adult content on Anilist/MyAnimeList.'.tr,
                          value: hideAdultContent,
                          onChanged: (e) {
                            setState(() {
                              hideAdultContent = e;
                              General.hideAdultContent.set(e);
                            });
                          },
                        ),
                        Obx(() => AnymeXTile.toggle(
                              icon: Icons.play_circle_outline_rounded,
                              title: 'Show Continue Watching on Home'.tr,
                              subtitle:
                                  'If enabled, a continue watching bar will be shown above the bottom navigation bar on the home page.'.tr,
                              value: settings.showHomeContinueWatching.value,
                              onChanged: (e) {
                                settings.saveShowHomeContinueWatching(e);
                              },
                            )),
                      ],
                    ),
                    AnymeXSectionBuilder(
                      title: 'Community Recommendations'.tr,
                      children: [
                        AnymeXTile.toggle(
                          icon: Icons.people_rounded,
                          title: 'Show Community Recommendations'.tr,
                          subtitle:
                              'Display anime, manga, movies and shows recommended by the community on the home page.'.tr,
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
                            title: 'Hide NSFW Recommendations'.tr,
                            subtitle:
                                'Filter out adult/NSFW entries from community recommendations.'.tr,
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
                            title: 'Hide by List Status'.tr,
                            subtitle:
                                'Filter out entries already in your list based on watching/reading status.'.tr,
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
                                title: 'Hide Completed'.tr,
                                subtitle:
                                    'Hide entries that are marked as completed in your list.'.tr,
                                value: svc.filterCompleted.value,
                                onChanged: (v) {
                                  svc.filterCompleted.value = v;
                                  General.filterCompleted.set(v);
                                },
                              ),
                              AnymeXTile.toggle(
                                icon: Icons.remove_red_eye_outlined,
                                title: 'Hide Watching / Reading'.tr,
                                subtitle:
                                    'Hide entries that you are currently watching or reading.'.tr,
                                value: svc.filterWatching.value,
                                onChanged: (v) {
                                  svc.filterWatching.value = v;
                                  General.filterWatching.set(v);
                                },
                              ),
                              AnymeXTile.toggle(
                                icon: Icons.cancel_outlined,
                                title: 'Hide Dropped'.tr,
                                subtitle: 'Hide entries that you have dropped.'.tr,
                                value: svc.filterDropped.value,
                                onChanged: (v) {
                                  svc.filterDropped.value = v;
                                  General.filterDropped.set(v);
                                },
                              ),
                              AnymeXTile.toggle(
                                icon: Icons.event_note_outlined,
                                title: 'Hide Planning'.tr,
                                subtitle:
                                    'Hide entries that are in your plan list.'.tr,
                                value: svc.filterPlanning.value,
                                onChanged: (v) {
                                  svc.filterPlanning.value = v;
                                  General.filterPlanning.set(v);
                                },
                              ),
                              AnymeXTile.toggle(
                                icon: Icons.pause_circle_outline_rounded,
                                title: 'Hide On Hold / Paused'.tr,
                                subtitle:
                                    'Hide entries that you have put on hold.'.tr,
                                value: svc.filterPaused.value,
                                onChanged: (v) {
                                  svc.filterPaused.value = v;
                                  General.filterPaused.set(v);
                                },
                              ),
                              AnymeXTile.toggle(
                                icon: Icons.replay_rounded,
                                title: 'Hide Rewatching'.tr,
                                subtitle:
                                    'Hide entries that you are rewatching.'.tr,
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
                      title: 'Anilist'.tr,
                      children: [
                        AnymeXTile(
                          icon: Icons.format_list_bulleted_sharp,
                          title: 'Manage Anilist Lists'.tr,
                          subtitle: "Choose which list to show on home page".tr,
                          onTap: () =>
                              _showHomePageCardsDialog(ServicesType.anilist),
                        ),
                      ],
                    ),
                    AnymeXSectionBuilder(
                      title: 'MyAnimeList'.tr,
                      children: [
                        AnymeXTile(
                          icon: Icons.format_list_bulleted_sharp,
                          title: 'Manage MyAnimeList Lists'.tr,
                          subtitle: "Choose which list to show on home page".tr,
                          onTap: () =>
                              _showHomePageCardsDialog(ServicesType.mal),
                        ),
                      ],
                    ),
                    AnymeXSectionBuilder(
                      title: 'Simkl'.tr,
                      children: [
                        AnymeXTile(
                          icon: Icons.format_list_bulleted_sharp,
                          title: 'Manage Simkl Lists'.tr,
                          subtitle: "Choose which list to show on home page".tr,
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
            'Continue Watching',
            'Continue Reading',
            'Planning Animes',
            'Planning Manga',
            'Completed TV',
            'Completed Manga',
            'Paused Animes',
            'Paused Manga',
            'Dropped Animes',
            'Dropped Manga',
            'Recommended Animes',
            'Recommended Mangas',
          ]
        : type.isAL
            ? [
                'Continue Watching',
                'Continue Reading',
                'Planning Animes',
                'Planning Manga',
                'Completed TV',
                'Completed Manga',
                'Completed Movie',
                'Paused Animes',
                'Paused Manga',
                'Dropped Animes',
                'Dropped Manga',
                'Rewatching Animes',
                'Rewatching Manga',
                'Recommended Animes',
                'Recommended Mangas',
              ]
            : [
                'Continue Watching (Movies)',
                'Continue Watching (Shows)',
                'Planning Movies',
                'Planning Shows',
                'Completed Movies',
                'Completed Shows',
                'Paused Movies',
                'Paused Shows',
                'Dropped Movies',
                'Dropped Shows',
              ];

    final legacyMapping = type.isSimkl
        ? {
            'Watching Anime': 'Continue Watching (Shows)',
            'Continue Watching': 'Continue Watching (Shows)',
            'Reading Manga': 'Continue Watching (Shows)',
            'Plan to Watch Anime': 'Planning Shows',
            'Planning Animes': 'Planning Shows',
            'Plan to Read Manga': 'Planning Shows',
            'Planning Manga': 'Planning Shows',
            'Completed Anime': 'Completed Shows',
            'Completed TV': 'Completed Shows',
            'Completed Manga': 'Completed Shows',
            'On-Hold Anime': 'Paused Shows',
            'Hold Anime': 'Paused Shows',
            'Paused Anime': 'Paused Shows',
            'Paused Animes': 'Paused Shows',
            'On-Hold Manga': 'Paused Shows',
            'Hold Manga': 'Paused Shows',
            'Paused Manga': 'Paused Shows',
            'Dropped Anime': 'Dropped Shows',
            'Dropped Animes': 'Dropped Shows',
            'Dropped Manga': 'Dropped Shows',
          }
        : {
            'Watching Anime': 'Continue Watching',
            'Reading Manga': 'Continue Reading',
            'Plan to Watch Anime': 'Planning Animes',
            'Plan to Read Manga': 'Planning Manga',
            'Completed Anime': 'Completed TV',
            'On-Hold Anime': 'Paused Animes',
            'Hold Anime': 'Paused Animes',
            'Paused Anime': 'Paused Animes',
            'On-Hold Manga': 'Paused Manga',
            'Hold Manga': 'Paused Manga',
            'Dropped Anime': 'Dropped Animes',
          };

    final localState = <String, bool>{};
    for (final key in defaultKeys) {
      localState[key] = targetCards[key] ?? true;
    }
    for (final entry in legacyMapping.entries) {
      if (targetCards.containsKey(entry.key) && localState.containsKey(entry.value)) {
        localState[entry.value] = targetCards[entry.key] ?? localState[entry.value]!;
      }
    }

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

  void _showLanguageDialog(BuildContext context) {
    final localeController = Get.find<LocaleController>();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AnymeXDialog(
            title: LocaleKeys.labelLanguage.tr,
            showCancelButton: false,
            confirmText: LocaleKeys.actionClose.tr,
            onConfirm: () {},
            contentWidget: AnymeXTileBuilder<LanguageOption>(
              items: LocaleController.supportedLanguages,
              isSelected: (opt) =>
                  opt.locale.languageCode ==
                  localeController.currentLocale.value.languageCode,
              isRadio: true,
              getTitle: (opt) => opt.nativeName,
              getSubtitle: (opt) => opt.name,
              onItemPressed: (opt) {
                localeController.changeLocale(opt.locale);
                setDialogState(() {});
                Navigator.pop(context);
              },
            ),
          );
        },
      ),
    );
  }
}
