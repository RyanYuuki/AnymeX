// ignore_for_file: invalid_use_of_protected_member

import 'dart:async';
import 'package:anymex/controllers/cacher/cache_controller.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Offline/Hive/episode.dart';
import 'package:anymex/screens/anime/widgets/episode_list_builder.dart';
import 'package:anymex/screens/anime/widgets/wrongtitle_modal.dart';
import 'package:anymex/widgets/common/no_source.dart';
import 'package:anymex/widgets/custom_widgets/anymex_dropdown.dart';
import 'package:anymex/widgets/header.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/custom_widgets/custom_textspan.dart';
import 'package:dartotsu_extension_bridge/ExtensionManager.dart';
import 'package:flutter/material.dart';
import 'package:dartotsu_extension_bridge/Models/Source.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:get/get.dart';

class EpisodeSection extends StatefulWidget {
  final dynamic searchedTitle;
  final dynamic anilistData;
  final RxList<Episode>? episodeList;
  final RxBool episodeError;
  final Rx<bool> isAnify;
  final Rx<bool> showAnify;
  final Future<void> Function() mapToAnilist;
  final Future<void> Function(Media) getDetailsFromSource;
  // final List<SourcePreference> Function({required Source source})
  //     getSourcePreference;

  const EpisodeSection({
    super.key,
    required this.searchedTitle,
    required this.anilistData,
    required this.episodeList,
    required this.episodeError,
    required this.mapToAnilist,
    required this.getDetailsFromSource,
    // required this.getSourcePreference,
    required this.isAnify,
    required this.showAnify,
  });

  @override
  State<EpisodeSection> createState() => _EpisodeSectionState();
}

class _EpisodeSectionState extends State<EpisodeSection> {
  final RxInt _requestCounter = 0.obs;
  final Rx<Future<List<Episode>>?> _episodeFuture =
      Rx<Future<List<Episode>>?>(null);

  @override
  void initState() {
    super.initState();
    if (widget.episodeList != null && widget.episodeList!.isNotEmpty) {
      _episodeFuture.value = Future.value(widget.episodeList!);
    }
  }

  Future<List<Episode>> _fetchEpisodes(int requestId) async {
    try {
      await widget.mapToAnilist();

      if (_requestCounter.value != requestId) {
        throw Exception('Request cancelled');
      }

      return widget.episodeList?.value ?? [];
    } catch (e) {
      if (_requestCounter.value == requestId) {
        widget.episodeError.value = true;
      }
      rethrow;
    }
  }

  void handleSourceChange(String? value) {
    if (value == null) return;

    widget.episodeError.value = false;
    widget.episodeList?.value = [];

    try {
      final sourceController = Get.find<ServiceHandler>().extensionService;
      sourceController.getExtensionByName(value);

      _requestCounter.value++;
      int currentRequestId = _requestCounter.value;

      _episodeFuture.value = _fetchEpisodes(currentRequestId);
    } catch (e) {
      Logger.i(e.toString());
      widget.episodeError.value = true;
    }
  }

  void openSourcePreferences(BuildContext context) {
    // final sourceController = Get.find<ServiceHandler>().extensionService;
    // List<SourcePreference> sourcePreference = widget
    //     .getSourcePreference(source: sourceController.activeSource.value!)
    //     .map((e) => getSourcePreferenceEntry(
    //         e.key!, sourceController.activeSource.value!.id!))
    //     .toList();

    // navigate(
    //   () => SourcePreferenceWidget(
    //     source: sourceController.activeSource.value!,
    //     sourcePreference: sourcePreference,
    //   ),
    // );
  }

  Widget buildSourceDropdown() {
    List<DropdownItem> items = sourceController.installedExtensions.isEmpty
        ? [
            const DropdownItem(
              value: "No Sources Installed",
              text: "No Sources Available",
              subtitle: "Install extensions to get started",
              leadingIcon: Icon(
                Icons.extension_off,
                size: 24,
                color: Colors.grey,
              ),
            ),
          ]
        : sourceController.installedExtensions.map<DropdownItem>((source) {
            final isMangayomi = source.extensionType == ExtensionType.mangayomi;

            return DropdownItem(
              value: '${source.name} (${source.lang?.toUpperCase()})',
              text: source.name?.toUpperCase() ?? 'Unknown Source',
              subtitle: source.lang?.toUpperCase() ?? 'Unknown',
              leadingIcon: NetworkSizedImage(
                radius: 16,
                imageUrl: isMangayomi
                    ? "https://raw.githubusercontent.com/kodjodevf/mangayomi/main/assets/app_icons/icon-red.png"
                    : 'https://aniyomi.org/img/logo-128px.png',
                height: 24,
                width: 24,
              ),
            );
          }).toList();

    DropdownItem? selectedItem;
    if (sourceController.installedExtensions.isEmpty) {
      selectedItem = items.first;
    } else {
      final activeSource = sourceController.activeSource.value;
      if (activeSource != null) {
        final isMangayomi =
            activeSource.extensionType == ExtensionType.mangayomi;

        selectedItem = DropdownItem(
          value: '${activeSource.name} (${activeSource.lang?.toUpperCase()})',
          text: activeSource.name?.toUpperCase() ?? 'Unknown Source',
          subtitle: activeSource.lang?.toUpperCase() ?? 'Unknown',
          leadingIcon: NetworkSizedImage(
            radius: 12,
            imageUrl: isMangayomi
                ? "https://raw.githubusercontent.com/kodjodevf/mangayomi/main/assets/app_icons/icon-red.png"
                : 'https://aniyomi.org/img/logo-128px.png',
            height: 20,
            width: 20,
          ),
        );
      }
    }

    return AnymexDropdown(
      items: items,
      selectedItem: selectedItem,
      label: "SELECT SOURCE",
      icon: Icons.extension_rounded,
      onChanged: (DropdownItem item) => handleSourceChange(item.value),
      actionIcon: Icons.settings_outlined,
      onActionPressed: () => openSourcePreferences(context),
    );
  }

  Widget buildEpisodeContent() {
    final sourceController = Get.find<ServiceHandler>().extensionService;

    if (sourceController.activeSource.value == null) {
      return const NoSourceSelectedWidget();
    }

    return Obx(() {
      return FutureBuilder<List<Episode>>(
        future: _episodeFuture.value,
        builder: (context, snapshot) {
          if (widget.episodeError.value &&
              (widget.episodeList?.value.isEmpty ?? true)) {
            return const SizedBox(
              height: 300,
              child: Center(
                child: AnymexText(
                  text:
                      "Looks like even the episodes are avoiding your taste in shows\n:(",
                  size: 20,
                  textAlign: TextAlign.center,
                  variant: TextVariant.semiBold,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 500,
              child: Center(child: AnymexProgressIndicator()),
            );
          }

          if (!snapshot.hasData || (snapshot.data?.isEmpty ?? true)) {
            if (widget.episodeList?.isEmpty ?? true) {
              return const SizedBox(
                height: 500,
                child: Center(child: AnymexProgressIndicator()),
              );
            }
          }

          return EpisodeListBuilder(
            episodeList: snapshot.data ?? widget.episodeList?.value ?? [],
            anilistData: widget.anilistData,
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final serviceHandler = Get.find<ServiceHandler>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (serviceHandler.serviceType.value != ServicesType.extensions) ...[
            // Title Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        Theme.of(context).colorScheme.shadow.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AnymexTextSpans(
                      spans: [
                        if (!widget.searchedTitle.value.contains('Searching') &&
                            !widget.searchedTitle.value
                                .contains('No Match Found'))
                          AnymexTextSpan(
                            text: "Found: ",
                            size: 14,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                        AnymexTextSpan(
                          text: widget.searchedTitle.value,
                          variant: TextVariant.semiBold,
                          size: 14,
                          color: widget.searchedTitle.value
                                  .contains('No Match Found')
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.primary,
                        )
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  AnymexOnTap(
                    onTap: () {
                      showWrongTitleModal(
                        context,
                        widget.anilistData.title,
                        (manga) async {
                          widget.episodeList?.clear();
                          _requestCounter.value++;
                          int currentRequestId = _requestCounter.value;
                          _episodeFuture.value = Future(() async {
                            await widget.getDetailsFromSource(
                                Media.froDMedia(manga, ItemType.anime));
                            if (_requestCounter.value != currentRequestId) {
                              throw Exception('Request cancelled');
                            }
                            return widget.episodeList?.value ?? [];
                          });
                          final key =
                              '${sourceController.activeSource.value?.id}-${widget.anilistData.id}-${widget.anilistData.serviceType.index}';
                          settingsController.preferences.put(key, manga.title);
                        },
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.swap_horiz_rounded,
                            size: 14,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          AnymexText(
                            text: "Wrong Title?",
                            size: 12,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Source Selector
            Obx(() => Row(
                  children: [
                    Expanded(child: buildSourceDropdown()),
                  ],
                )),
          ],
          const SizedBox(height: 20),
          // Episode List
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const AnymexText(
                    text: "Episodes",
                    variant: TextVariant.bold,
                    size: 18,
                  ),
                  Obx(() {
                    if (widget.showAnify.value) {
                      return Row(
                        children: [
                          const AnymexText(
                            text: "Anify / Kitsu",
                            variant: TextVariant.semiBold,
                            size: 16,
                          ),
                          Switch(
                              value: widget.isAnify.value,
                              onChanged: (v) {
                                widget.isAnify.value = v;
                              }),
                        ],
                      );
                    } else {
                      return const SizedBox.shrink();
                    }
                  }),
                ],
              ),
              buildEpisodeContent(),
            ],
          ),
        ],
      ),
    );
  }
}
