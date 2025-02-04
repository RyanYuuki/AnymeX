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
import 'package:anymex/widgets/helper/platform_builder.dart';
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
  });

  @override
  Widget build(BuildContext context) {
    final serviceHandler = Get.find<ServiceHandler>();
    final sourceController = Get.find<ServiceHandler>().extensionService;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (serviceHandler.serviceType.value != ServicesType.extensions) ...[
            _TitleSection(
              searchedTitle: searchedTitle,
              anilistData: anilistData,
              episodeList: episodeList,
              getDetailsFromSource: getDetailsFromSource,
            ),
            const SizedBox(height: 20),
            _SourceSelector(
              mapToAnilist: mapToAnilist,
              sourceController: sourceController,
              episodeList: episodeList,
              getSourcePreference: getSourcePreference,
            ),
          ],
          const SizedBox(height: 20),
          _EpisodeList(
            sourceController: sourceController,
            episodeList: episodeList,
            episodeError: episodeError,
            anilistData: anilistData,
          ),
        ],
      ),
    );
  }
}

class _TitleSection extends StatelessWidget {
  final Rx<String> searchedTitle;
  final Media anilistData;
  final RxList<dynamic>? episodeList;
  final Function(Media) getDetailsFromSource;

  const _TitleSection({
    required this.searchedTitle,
    required this.anilistData,
    required this.episodeList,
    required this.getDetailsFromSource,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
                ))),
        GestureDetector(
          onTap: () {
            showWrongTitleModal(
              context,
              anilistData.title,
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
    );
  }
}

class _SourceSelector extends StatelessWidget {
  final dynamic sourceController;
  final RxList<dynamic>? episodeList;
  final List<SourcePreference> Function({required Source source})
      getSourcePreference;
  final Function() mapToAnilist;

  const _SourceSelector({
    required this.sourceController,
    required this.episodeList,
    required this.getSourcePreference,
    required this.mapToAnilist,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() => Row(
          children: [
            Expanded(
              child: _buildSourceDropdown(context),
            ),
            const SizedBox(width: 10),
            _buildSettingsButton(context),
          ],
        ));
  }

  Widget _buildSourceDropdown(BuildContext context) {
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
      items: _buildDropdownItems(),
      onChanged: _handleSourceChange,
      dropdownColor: Theme.of(context).colorScheme.secondaryContainer,
      icon: Icon(Icons.arrow_drop_down,
          color: Theme.of(context).colorScheme.primary),
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 16,
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildDropdownItems() {
    if (sourceController.installedExtensions.value.isEmpty) {
      return [
        const DropdownMenuItem<String>(
          value: "No Sources Installed",
          child: Text(
            "No Sources Installed",
            style: TextStyle(fontFamily: 'Poppins-SemiBold'),
          ),
        ),
      ];
    }

    return sourceController.installedExtensions.value
        .map<DropdownMenuItem<String>>((source) {
      return DropdownMenuItem<String>(
        value: '${source.name} (${source.lang?.toUpperCase()})',
        child: Text(
          '${source.name?.toUpperCase()} (${source.lang?.toUpperCase()})',
          style: const TextStyle(fontFamily: 'Poppins-SemiBold'),
        ),
      );
    }).toList();
  }

  void _handleSourceChange(String? value) async {
    episodeList?.clear();
    try {
      sourceController.getExtensionByName(value!);
      await mapToAnilist();
    } catch (e) {
      log(e.toString());
    }
  }

  Widget _buildSettingsButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Theme.of(context).colorScheme.secondaryContainer,
      ),
      child: IconButton(
        onPressed: () => _openSourcePreferences(context),
        icon: const Icon(Iconsax.setting),
      ),
    );
  }

  void _openSourcePreferences(BuildContext context) {
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
}

class _EpisodeList extends StatelessWidget {
  final dynamic sourceController;
  final RxList<Episode>? episodeList;
  final RxBool episodeError;
  final dynamic anilistData;

  const _EpisodeList({
    required this.sourceController,
    required this.episodeList,
    required this.episodeError,
    required this.anilistData,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            AnymexText(
              text: "Episodes",
              variant: TextVariant.bold,
              size: 18,
            ),
          ],
        ),
        _buildEpisodeContent(),
      ],
    );
  }

  Widget _buildEpisodeContent() {
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

      if (episodeList!.value.isEmpty || episodeList == null) {
        return const SizedBox(
          height: 500,
          child: Center(child: CircularProgressIndicator()),
        );
      }

      return PlatformBuilder(
        androidBuilder: EpisodeListBuilder(
          episodeList: episodeList ?? [],
          anilistData: anilistData,
          isDesktop: false,
        ),
        desktopBuilder: EpisodeListBuilder(
          episodeList: episodeList ?? [],
          anilistData: anilistData,
          isDesktop: true,
        ),
      );
    });
  }
}
