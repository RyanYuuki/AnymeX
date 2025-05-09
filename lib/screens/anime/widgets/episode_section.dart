// ignore_for_file: invalid_use_of_protected_member

import 'dart:async';
import 'dart:developer';
import 'package:anymex/core/Eval/dart/model/source_preference.dart';
import 'package:anymex/core/Model/Source.dart';
import 'package:anymex/core/extension_preferences_providers.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Offline/Hive/episode.dart';
import 'package:anymex/screens/anime/widgets/episode_list_builder.dart';
import 'package:anymex/screens/anime/widgets/wrongtitle_modal.dart';
import 'package:anymex/screens/extensions/ExtensionSettings/ExtensionSettings.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/no_source.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/custom_widgets/custom_textspan.dart';
import 'package:flutter/material.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class EpisodeSection extends StatefulWidget {
  final dynamic searchedTitle;
  final dynamic anilistData;
  final RxList<Episode>? episodeList;
  final RxBool episodeError;
  final Rx<bool> isAnify;
  final Rx<bool> showAnify;
  final Future<void> Function() mapToAnilist;
  final Future<void> Function(Media) getDetailsFromSource;
  final List<SourcePreference> Function({required Source source})
      getSourcePreference;

  const EpisodeSection({
    super.key,
    required this.searchedTitle,
    required this.anilistData,
    required this.episodeList,
    required this.episodeError,
    required this.mapToAnilist,
    required this.getDetailsFromSource,
    required this.getSourcePreference,
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
      log(e.toString());
      widget.episodeError.value = true;
    }
  }

  void openSourcePreferences(BuildContext context) {
    final sourceController = Get.find<ServiceHandler>().extensionService;
    List<SourcePreference> sourcePreference = widget
        .getSourcePreference(source: sourceController.activeSource.value!)
        .map((e) => getSourcePreferenceEntry(
            e.key!, sourceController.activeSource.value!.id!))
        .toList();

    navigate(
      () => SourcePreferenceWidget(
        source: sourceController.activeSource.value!,
        sourcePreference: sourcePreference,
      ),
    );
  }

  Widget buildSourceDropdown() {
    final sourceController = Get.find<ServiceHandler>().extensionService;

    List<DropdownMenuItem<String>> items =
        sourceController.installedExtensions.isEmpty
            ? [
                const DropdownMenuItem<String>(
                  value: "No Sources Installed",
                  child: Text(
                    "No Sources Installed",
                    style: TextStyle(fontFamily: 'Poppins-SemiBold'),
                  ),
                ),
              ]
            : sourceController.installedExtensions
                .map<DropdownMenuItem<String>>((source) {
                return DropdownMenuItem<String>(
                  value: '${source.name} (${source.lang?.toUpperCase()})',
                  child: Text(
                    '${source.name?.toUpperCase()} (${source.lang?.toUpperCase()})',
                    style: const TextStyle(fontFamily: 'Poppins-SemiBold'),
                  ),
                );
              }).toList();

    return DropdownButtonFormField<String>(
      value: sourceController.installedExtensions.isEmpty
          ? "No Sources Installed"
          : '${sourceController.activeSource.value?.name} (${sourceController.activeSource.value?.lang?.toUpperCase()})',
      decoration: InputDecoration(
        label: TextButton.icon(
          onPressed: () {},
          label: const AnymexText(
            text: "Select Source",
            variant: TextVariant.bold,
          ),
          icon: const Icon(Iconsax.folder5),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.secondaryContainer,
        labelStyle:
            TextStyle(color: Theme.of(context).colorScheme.inverseSurface),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
              color: Theme.of(context).colorScheme.onPrimaryFixedVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
      ),
      isExpanded: true,
      items: items,
      onChanged: handleSourceChange,
      dropdownColor: Theme.of(context).colorScheme.secondaryContainer,
      icon: Icon(Icons.arrow_drop_down,
          color: Theme.of(context).colorScheme.primary),
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 16,
      ),
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
          // Case 1: Error occurred
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.only(left: 2),
                  width: Get.width * 0.6,
                  child: Obx(() => AnymexTextSpans(
                        spans: [
                          if (!widget.searchedTitle.value.contains('Searching'))
                            const AnymexTextSpan(
                              text: "Found: ",
                              variant: TextVariant.semiBold,
                              size: 16,
                            ),
                          AnymexTextSpan(
                            text: widget.searchedTitle.value,
                            variant: TextVariant.semiBold,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        ],
                      )),
                ),
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
                              Media.fromManga(manga, MediaType.anime));
                          if (_requestCounter.value != currentRequestId) {
                            throw Exception('Request cancelled');
                          }
                          return widget.episodeList?.value ?? [];
                        });
                      },
                    );
                  },
                  child: AnymexText(
                    text: "Wrong Title?",
                    variant: TextVariant.semiBold,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Source Selector
            Obx(() => Row(
                  children: [
                    Expanded(child: buildSourceDropdown()),
                    const SizedBox(width: 10),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: Theme.of(context).colorScheme.secondaryContainer,
                      ),
                      child: IconButton(
                        onPressed: () => openSourcePreferences(context),
                        icon: const Icon(Iconsax.setting),
                      ),
                    ),
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
