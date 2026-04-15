// ignore_for_file: invalid_use_of_protected_member

import 'dart:async';

import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/jikan.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/database/isar_models/episode.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/widgets/episode_list_builder.dart';
import 'package:anymex/screens/anime/widgets/wrongtitle_modal.dart';
import 'package:anymex/screens/extensions/ExtensionSettings/ExtensionSettings.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/language.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/no_source.dart';
import 'package:anymex/widgets/custom_widgets/anymex_dropdown.dart';
import 'package:anymex/widgets/custom_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/custom_widgets/custom_textspan.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex_extension_runtime_bridge/Services/Aniyomi/Models/Source.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EpisodeSection extends StatefulWidget {
  final dynamic searchedTitle;
  final dynamic anilistData;
  final RxList<Episode>? episodeList;
  final RxBool episodeError;
  final Rx<bool> isAnify;
  final Rx<bool> showAnify;
  final RxBool disableAnifyForCurrentSource;
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
    required this.isAnify,
    required this.showAnify,
    required this.disableAnifyForCurrentSource,
  });

  @override
  State<EpisodeSection> createState() => _EpisodeSectionState();
}

class _EpisodeSectionState extends State<EpisodeSection> {
  final RxInt _requestCounter = 0.obs;
  final Rx<Future<List<Episode>>?> _episodeFuture =
      Rx<Future<List<Episode>>?>(null);
  Worker? _episodeListListener;
  bool _fillerFetched = false;

  String _sourceDropdownValue(Source source) => source.id.toString();

  @override
  void initState() {
    super.initState();
    if (widget.episodeList != null && widget.episodeList!.isNotEmpty) {
      _episodeFuture.value = Future.value(widget.episodeList!);
      _fetchFillerInfo();
    }

    if (widget.episodeList != null) {
      _episodeListListener = ever(widget.episodeList!, (episodes) {
        if (episodes.isNotEmpty && !_fillerFetched) {
          _fetchFillerInfo();
        }
      });
    }
  }

  @override
  void dispose() {
    _episodeListListener?.dispose();
    super.dispose();
  }

  Future<void> _fetchFillerInfo() async {
    if (_fillerFetched) return;

    if (widget.episodeList != null && widget.episodeList!.isNotEmpty) {
      if (widget.episodeList!.any((ep) => ep.filler == true)) {
        _fillerFetched = true;
        return;
      }
    }

    final malId = widget.anilistData?.idMal;
    if (malId == null) return;

    _fillerFetched = true;

    try {
      final fillerMap = await JikanService.getFillerEpisodes(malId.toString());

      if (fillerMap.isNotEmpty && widget.episodeList != null) {
        bool updated = false;

        for (var ep in widget.episodeList!) {
          if (fillerMap.containsKey(ep.number)) {
            ep.filler = true;
            updated = true;
          }
        }

        if (updated && mounted) setState(() {});
      }
    } catch (_) {}
  }

  Future<List<Episode>> _fetchEpisodes(int requestId) async {
    try {
      await widget.mapToAnilist();

      if (_requestCounter.value != requestId) {
        throw Exception('Request cancelled');
      }

      final episodes = widget.episodeList?.value ?? [];
      if (episodes.isNotEmpty) {
        _fetchFillerInfo();
      }

      return episodes;
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
      sourceController.getExtensionByValue(value,
          mediaId: widget.anilistData?.id?.toString());

      _requestCounter.value++;
      int currentRequestId = _requestCounter.value;

      _episodeFuture.value = _fetchEpisodes(currentRequestId);
    } catch (e) {
      Logger.i(e.toString());
      widget.episodeError.value = true;
    }
  }

  void openSourcePreferences(BuildContext context) {
    navigate(
      () => SourcePreferenceScreen(
        source: sourceController.activeSource.value!,
      ),
    );
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
            return DropdownItem(
              value: _sourceDropdownValue(source),
              text: source.name?.toUpperCase() ?? 'Unknown Source',
              subtitle: source.lang?.toUpperCase() ?? 'Unknown',
              leadingIcon: AnymeXImage(
                radius: 16,
                imageUrl: source.managerIcon,
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
        selectedItem = DropdownItem(
          value: _sourceDropdownValue(activeSource),
          text: activeSource.name?.toUpperCase() ?? 'Unknown Source',
          subtitle: activeSource.lang?.toUpperCase() ?? 'Unknown',
          leadingIcon: AnymeXImage(
            radius: 12,
            imageUrl: activeSource.managerIcon,
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

  void handleLanguageChange(String? value) {
    if (value == null) return;

    final activeSource = sourceController.activeSource.value as ASource?;
    if (activeSource == null || activeSource.langs == null) return;

    final newSubSource =
        activeSource.langs!.firstWhere((s) => s.id.toString() == value);
    sourceController.setActiveSource(newSubSource);

    widget.episodeError.value = false;
    widget.episodeList?.value = [];
    _requestCounter.value++;
    int currentRequestId = _requestCounter.value;
    _episodeFuture.value = _fetchEpisodes(currentRequestId);

    setState(() {});
  }

  Widget buildLanguageDropdown() {
    final activeSource = sourceController.activeSource.value;
    if (activeSource is! ASource ||
        activeSource.langs == null ||
        activeSource.langs!.isEmpty) {
      return const SizedBox.shrink();
    }

    List<DropdownItem> items = activeSource.langs!.map<DropdownItem>((source) {
      return DropdownItem(
        value: source.id.toString(),
        text: extensionLanguageName(source.lang),
        subtitle: source.name ?? 'Unknown Source',
        leadingIcon: AnymeXImage(
          radius: 0,
          imageUrl: extensionLanguageFlagUrl(source.lang),
          height: 20,
          width: 20,
        ),
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: AnymexDropdown(
        items: items,
        selectedItem: items.firstWhere(
            (item) => item.value == activeSource.id.toString(),
            orElse: () => items.first),
        label: "SELECT SUB-LANGUAGE",
        icon: Icons.language_rounded,
        onChanged: (DropdownItem item) => handleLanguageChange(item.value),
      ),
    );
  }

  Widget buildEpisodeContent() {
    final sourceController = Get.find<ServiceHandler>().extensionService;
    return Obx(() {
      if (sourceController.activeSource.value == null) {
        return const Padding(
          padding: EdgeInsets.only(top: 20),
          child: SizedBox(
            height: 320,
            child: NoSourceSelectedWidget(),
          ),
        );
      }

      return FutureBuilder<List<Episode>>(
        future: _episodeFuture.value,
        builder: (context, snapshot) {
          if (widget.episodeError.value &&
              (widget.episodeList?.value.isEmpty ?? true)) {
            return SizedBox(
              height: 300,
              child: Center(
                child: AnymexText(
                  text: snapshot.error.toString().contains('lateinit')
                      ? "Restart the App Gang"
                      : "Looks like even the episodes are avoiding your taste in shows\n:(",
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
            episodeList: widget.episodeList?.value ?? snapshot.data ?? [],
            anilistData: widget.anilistData,
          );
        },
      );
    });
  }

  bool get _hasEpisodeSettingsOption =>
      widget.showAnify.value && !widget.disableAnifyForCurrentSource.value;

  void _showEpisodeSettingsDialog(BuildContext context) {
    final tempUseAnify = widget.isAnify.value.obs;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Obx(
          () => AnymexDialog(
            title: 'Episode List Settings',
            onConfirm: () {
              widget.isAnify.value = tempUseAnify.value;
            },
            contentWidget: _ProviderOptionTile(
              title: 'Anify / Kitsu',
              subtitle: 'Use enhanced episode metadata and artwork.',
              isSelected: tempUseAnify.value,
              onTap: () => tempUseAnify.value = !tempUseAnify.value,
            ),
          ),
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return _buildSliverContent(context);
  }

  Widget _buildSliverContent(BuildContext context) {
    final serviceHandler = Get.find<ServiceHandler>();
    return Obx(() {
      return SliverMainAxisGroup(
        slivers: [
          if (serviceHandler.serviceType.value != ServicesType.extensions) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainer
                        .opaque(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: context.colors.outline
                          .opaque(0.2, iReallyMeanIt: true),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: context.colors.shadow
                            .opaque(0.08, iReallyMeanIt: true),
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
                            AnymexTextSpan(
                              text: widget.searchedTitle.value,
                              variant: TextVariant.semiBold,
                              size: 14,
                              color: widget.searchedTitle.value
                                      .contains('No Match Found')
                                  ? context.colors.error
                                  : context.colors.primary,
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
                              DynamicKeys.mappedMediaTitle
                                  .set(key, manga.title);
                            },
                            mediaId: widget.anilistData.id.toString(),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color:
                                context.colors.primaryContainer.opaque(0.4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .opaque(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.swap_horiz_rounded,
                                size: 14,
                                color: context.colors.primary,
                              ),
                              const SizedBox(width: 6),
                              AnymexText(
                                text: "Wrong Title?",
                                size: 12,
                                color: context.colors.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [Expanded(child: buildSourceDropdown())],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: buildLanguageDropdown(),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            sliver: DecoratedSliver(
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainer
                    .opaque(0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      context.colors.outline.opaque(0.2, iReallyMeanIt: true),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.colors.shadow
                        .opaque(0.08, iReallyMeanIt: true),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              sliver: SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverMainAxisGroup(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Obx(
                        () => Row(
                          children: [
                            const Expanded(
                              child: AnymexText(
                                text: "Episodes",
                                variant: TextVariant.bold,
                                size: 18,
                              ),
                            ),
                            if (_hasEpisodeSettingsOption) ...[
                              AnymexOnTap(
                                onTap: () =>
                                    _showEpisodeSettingsDialog(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.colors.primaryContainer
                                        .opaque(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color:
                                          context.colors.outline.opaque(0.2),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.settings_outlined,
                                        size: 16,
                                        color: context.colors.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      AnymexText(
                                        text: widget.isAnify.value
                                            ? 'Anify / Kitsu'
                                            : 'Default',
                                        size: 13,
                                        variant: TextVariant.semiBold,
                                        color: context.colors.primary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    _buildEpisodeContentSliver(context),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 10)),
        ],
      );
    });
  }

  Widget _buildEpisodeContentSliver(BuildContext context) {
    final sc = Get.find<ServiceHandler>().extensionService;
    return Obx(() {
      if (sc.activeSource.value == null) {
        return const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: 20),
            child: SizedBox(
              height: 320,
              child: NoSourceSelectedWidget(),
            ),
          ),
        );
      }

      if (widget.episodeError.value &&
          (widget.episodeList?.isEmpty ?? true)) {
        return SliverToBoxAdapter(
          child: SizedBox(
            height: 300,
            child: Center(
              child: AnymexText(
                text: "Looks like even the episodes are avoiding your taste in shows\n:(",
                size: 20,
                textAlign: TextAlign.center,
                variant: TextVariant.semiBold,
              ),
            ),
          ),
        );
      }

      if (widget.episodeList?.isEmpty ?? true) {
        return const SliverToBoxAdapter(
          child: SizedBox(
            height: 500,
            child: Center(child: AnymexProgressIndicator()),
          ),
        );
      }

      return EpisodeListBuilder(
        episodeList: widget.episodeList!.value,
        anilistData: widget.anilistData,
        isSliverMode: true,
      );
    });
  }
}

class _ProviderOptionTile extends StatelessWidget {
  const _ProviderOptionTile({
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
