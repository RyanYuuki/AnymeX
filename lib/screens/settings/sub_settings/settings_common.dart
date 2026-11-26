import 'package:anymex/l10n/l10n_extension.dart';
import 'dart:convert';

import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/community_service.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_badge.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile_builder.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:anymex/l10n/locale_controller.dart';
import 'package:anymex/screens/settings/sub_settings/settings_episode_metadata.dart';
import 'package:anymex/utils/function.dart';

class SettingsCommon extends StatefulWidget {
  const SettingsCommon({super.key});

  @override
  State<SettingsCommon> createState() => _SettingsCommonState();
}

class _SettingsCommonState extends State<SettingsCommon> {
  final settings = Get.find<Settings>();

  late bool uniScrapper;
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
      headerTitle: context.l10n.contentPreferences,
      body: Builder(
          builder: (ctx) => SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    16.0, AnymeXHeaderScope.of(ctx), 16.0, 30.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnymeXSectionBuilder(
                      title: context.l10n.libraryContentSafety,
                      children: [
                        Obx(() {
                          final localeController = Get.find<LocaleController>();
                          return AnymeXTile(
                            icon: Icons.language_rounded,
                            title: context.l10n.labelLanguage,
                            badge: AnymeXBadge.newBadge(context),
                            subtitle:
                                '${localeController.currentLanguageNativeName} (${localeController.currentLanguageName})',
                            onTap: () => _showLanguageDialog(context),
                          );
                        }),
                        AnymeXTile(
                          icon: Icons.subtitles_outlined,
                          title: context.l10n.episodeMetadata,
                          badge: AnymeXBadge.newBadge(context),
                          subtitle:
                              context.l10n.configureAnizipKitsuSimklAnilist,
                          onTap: () =>
                              navigate(() => const SettingsEpisodeMetadata()),
                        ),
                        AnymeXTile.toggle(
                          icon: Icons.collections_bookmark_rounded,
                          title: context.l10n.unifiedLibrary,
                          subtitle:
                              context.l10n.ifEnabledAllLibraryItemsWill,
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
                          title: context.l10n.hideAdultContent,
                          subtitle:
                              context.l10n.ifEnabledYouWillNotGet,
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
                    Obx(() {
                      final svc = Get.find<CommunityService>();
                      return AnymeXSectionBuilder(
                        title: context.l10n.communityRecommendations,
                        children: [
                          AnymeXTile.toggle(
                            icon: Icons.people_rounded,
                            title: context.l10n.showCommunityRecommendations,
                            subtitle:
                                context.l10n.displayAnimeMangaMoviesAndShows,
                            value: showCommunityRecs,
                            onChanged: (e) {
                              setState(() {
                                showCommunityRecs = e;
                                General.showCommunityRecommendations.set(e);
                                svc.communityEnabled.value = e;
                              });
                            },
                          ),
                          AnymeXTile.toggle(
                            icon: Icons.no_adult_content_rounded,
                            title: context.l10n.hideNsfwRecommendations,
                            subtitle:
                                context.l10n.filterOutAdultNsfwEntriesFrom,
                            value: svc.hideNsfw.value,
                            onChanged: (v) {
                              svc.hideNsfw.value = v;
                              General.hideNsfwRecommendations.set(v);
                            },
                          ),
                          AnymeXTile.toggle(
                            icon: Icons.filter_list_rounded,
                            title: context.l10n.hideByListStatus,
                            subtitle:
                                context.l10n.filterOutEntriesAlreadyInYourList,
                            value: svc.filterByListEnabled.value,
                            onChanged: (v) {
                              svc.filterByListEnabled.value = v;
                              General.filterByListEnabled.set(v);
                            },
                          ),
                          if (svc.filterByListEnabled.value) ...[
                            AnymeXTile.toggle(
                              icon: Icons.check_circle_outline_rounded,
                              title: context.l10n.hideCompleted,
                              subtitle:
                                  context.l10n.hideEntriesThatAreMarkedAs,
                              value: svc.filterCompleted.value,
                              onChanged: (v) {
                                svc.filterCompleted.value = v;
                                General.filterCompleted.set(v);
                              },
                            ),
                            AnymeXTile.toggle(
                              icon: Icons.remove_red_eye_outlined,
                              title: context.l10n.hideWatchingReading,
                              subtitle:
                                  context.l10n.hideEntriesThatYouAreCurrently,
                              value: svc.filterWatching.value,
                              onChanged: (v) {
                                svc.filterWatching.value = v;
                                General.filterWatching.set(v);
                              },
                            ),
                            AnymeXTile.toggle(
                              icon: Icons.cancel_outlined,
                              title: context.l10n.hideDropped,
                              subtitle: context.l10n.hideEntriesThatYouHaveDropped,
                              value: svc.filterDropped.value,
                              onChanged: (v) {
                                svc.filterDropped.value = v;
                                General.filterDropped.set(v);
                              },
                            ),
                            AnymeXTile.toggle(
                              icon: Icons.event_note_outlined,
                              title: context.l10n.hidePlanning,
                              subtitle:
                                  context.l10n.hideEntriesThatAreInYour,
                              value: svc.filterPlanning.value,
                              onChanged: (v) {
                                svc.filterPlanning.value = v;
                                General.filterPlanning.set(v);
                              },
                            ),
                            AnymeXTile.toggle(
                              icon: Icons.pause_circle_outline_rounded,
                              title: context.l10n.hideOnHoldPaused,
                              subtitle:
                                  context.l10n.hideEntriesThatYouHavePut,
                              value: svc.filterPaused.value,
                              onChanged: (v) {
                                svc.filterPaused.value = v;
                                General.filterPaused.set(v);
                              },
                            ),
                            AnymeXTile.toggle(
                              icon: Icons.replay_rounded,
                              title: context.l10n.hideRewatching,
                              subtitle:
                                  context.l10n.hideEntriesThatYouAreRewatching,
                              value: svc.filterRepeating.value,
                              onChanged: (v) {
                                svc.filterRepeating.value = v;
                                General.filterRepeating.set(v);
                              },
                            ),
                          ],
                        ],
                      );
                    }),
                    AnymeXSectionBuilder(
                      title: context.l10n.homePageLists,
                      children: [
                        AnymeXTile(
                          icon: Icons.format_list_bulleted_sharp,
                          title: context.l10n.manageAnilistLists,
                          subtitle: context.l10n.chooseWhichListsToShowOn,
                          onTap: () =>
                              _showHomePageCardsDialog(ServicesType.anilist),
                        ),
                        AnymeXTile(
                          icon: Icons.format_list_bulleted_sharp,
                          title: context.l10n.manageMyanimelistLists,
                          subtitle: context.l10n.chooseWhichListsToShowOn,
                          onTap: () =>
                              _showHomePageCardsDialog(ServicesType.mal),
                        ),
                        AnymeXTile(
                          icon: Icons.format_list_bulleted_sharp,
                          title: context.l10n.manageSimklLists,
                          subtitle: context.l10n.chooseWhichListsToShowOn,
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
            title: context.l10n.homePageCards((type.name.toUpperCase()).toString()),
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
            title: context.l10n.labelLanguage,
            showCancelButton: false,
            confirmText: context.l10n.actionClose,
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
