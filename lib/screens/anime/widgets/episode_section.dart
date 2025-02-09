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
import 'package:anymex/widgets/common/no_source.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/minor_widgets/custom_text.dart';
import 'package:anymex/widgets/minor_widgets/custom_textspan.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class EpisodeSection extends StatelessWidget {
  final dynamic searchedTitle;
  final dynamic anilistData;
  final RxList<Episode>? episodeList;
  final RxBool episodeError;
  final RxBool isAnify;
  final Function() mapToAnilist;
  final Function(Media) getDetailsFromSource;
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
  });

  @override
  Widget build(BuildContext context) {
    final serviceHandler = Get.find<ServiceHandler>();
    final sourceController = Get.find<ServiceHandler>().extensionService;

    void handleSourceChange(String? value) async {
      episodeError.value = false;
      episodeList?.value = [];
      try {
        sourceController.getExtensionByName(value!);
        await mapToAnilist();
      } catch (e) {
        log(e.toString());
      }
    }

    void openSourcePreferences(BuildContext context) {
      List<SourcePreference> sourcePreference =
          getSourcePreference(source: sourceController.activeSource.value!)
              .map((e) => getSourcePreferenceEntry(
                  e.key!, sourceController.activeSource.value!.id!))
              .toList();

      Get.to(
        () => SourcePreferenceWidget(
          source: sourceController.activeSource.value!,
          sourcePreference: sourcePreference,
        ),
      );
    }

    Widget buildSourceDropdown() {
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
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.primary),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color: Theme.of(context).colorScheme.onPrimaryFixedVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.primary),
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
      if (sourceController.activeSource.value == null) {
        return const NoSourceSelectedWidget();
      }

      return Obx(() {
        if (episodeError.value) {
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

        if (episodeList!.isEmpty || episodeList == null) {
          return const SizedBox(
            height: 500,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return EpisodeListBuilder(
          episodeList: (episodeList) ?? [],
          anilistData: anilistData,
        );
      });
    }

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
                          if (!searchedTitle.value.contains('Searching'))
                            const AnymexTextSpan(
                              text: "Found: ",
                              variant: TextVariant.semiBold,
                              size: 16,
                            ),
                          AnymexTextSpan(
                            text: searchedTitle.value,
                            variant: TextVariant.semiBold,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        ],
                      )),
                ),
                TVWrapper(
                  onTap: () {
                    showWrongTitleModal(
                      context,
                      anilistData.romajiTitle,
                      (manga) async {
                        episodeList?.clear();
                        await getDetailsFromSource(
                            Media.fromManga(manga, MediaType.anime));
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
                  Row(
                    children: [
                      const AnymexText(
                        text: "Anify / Kitsu",
                        variant: TextVariant.semiBold,
                        size: 16,
                      ),
                      Switch(
                          value: isAnify.value,
                          onChanged: (v) {
                            isAnify.value = v;
                          })
                    ],
                  ),
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
