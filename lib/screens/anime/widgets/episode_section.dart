import 'package:anymex/l10n/l10n_extension.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/database/isar_models/episode.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/widgets/episode/episode_style_registry.dart';
import 'package:anymex/screens/anime/widgets/episode_list_builder.dart';
import 'package:anymex/screens/extensions/ExtensionSettings/ExtensionSettings.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_button.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_progress.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/common/no_source.dart';
import 'package:anymex_extension_runtime_bridge/Services/CloudStream/CloudStreamSourceMethods.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:anymex/screens/anime/details/controller/media_details_controller.dart';
import 'package:anymex/screens/settings/sub_settings/settings_episode_metadata.dart';
import 'package:anymex/core/metadata/episode_metadata_service.dart';
import 'package:anymex/core/metadata/models/episode_metadata.dart';
import 'package:anymex/screens/anime/widgets/wrongtitle_modal.dart';
import 'package:anymex/widgets/common/content_error_widget.dart';
import 'package:anymex/widgets/common/unified_source_section.dart';

class EpisodeSection extends StatelessWidget {
  final dynamic searchedTitle;
  final dynamic anilistData;
  final RxList<Episode>? episodeList;
  final RxBool episodeError;
  final Rx<bool> isAnify;
  final Rx<bool> showAnify;
  final RxBool disableAnifyForCurrentSource;
  final Future<void> Function() mapToAnilist;
  final Future<void> Function(Media) getDetailsFromSource;
  final bool isSliverMode;
  final String tag;

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
    this.isSliverMode = false,
    required this.tag,
  });

  void openSourcePreferences(BuildContext context) async {
    final sourceController = Get.find<SourceController>();
    final active = sourceController.activeSource.value;
    if (active == null) return;

    if (active is CloudStreamSource) {
      if (active.hasSettings) {
        await CloudStreamSourceMethods(active).openNativeSettings();
      }
      return;
    }

    navigate(() => SourcePreferenceScreen(source: active));
  }

  void _showEpisodeSettingsDialog(BuildContext context) {
    final metaService = EpisodeMetadataService.instance;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Obx(
          () => AnymeXDialog(
            title: context.l10n.episodeListSettings,
            onConfirm: () {},
            contentWidget: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnymeXText(
                      context.l10n.layoutStyle,
                      variant: TextVariant.bold,
                      size: 14,
                    ),
                    const SizedBox(height: 8),
                    ...EpisodeStyleRegistry.styles.map((style) {
                      final isSelected =
                          EpisodeStyleRegistry.currentStyleId.value == style.id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _ProviderOptionTile(
                          title: style.name,
                          subtitle: style.description,
                          isSelected: isSelected,
                          onTap: () {
                            EpisodeStyleRegistry.setStyle(style.id);
                          },
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AnymeXText(context.l10n.episodeMetadata,
                          variant: TextVariant.bold,
                          size: 14,
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (kDebugMode)
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon:
                                    const Icon(Icons.science_rounded, size: 20),
                                tooltip: 'Test All Metadata APIs',
                                onPressed: () async {
                                  final media = anilistData is Media
                                      ? anilistData as Media
                                      : (Get.isRegistered<
                                              MediaDetailsController>(tag: tag)
                                          ? Get.find<MediaDetailsController>(
                                                  tag: tag)
                                              .media
                                              .value
                                          : Media(
                                              serviceType:
                                                  ServicesType.anilist));
                                  snackBar('Testing all metadata APIs...',
                                      duration: 1500);
                                  await metaService.testAllProvidersRaw(
                                    MetadataTargetIds.fromMedia(media),
                                  );
                                  snackBar('Metadata API responses logged',
                                      duration: 1500);
                                },
                              ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.tune_rounded, size: 20),
                              tooltip: context.l10n.configureProvidersAndOrder,
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                navigate(() => const SettingsEpisodeMetadata());
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    () {
                      final isOnlineSelected = isAnify.value &&
                          metaService.selectedSource.value != 'none';
                      final controller =
                          Get.isRegistered<MediaDetailsController>(tag: tag)
                              ? Get.find<MediaDetailsController>(tag: tag)
                              : null;
                      final isRefreshing =
                          controller?.isRefreshingMetadata.value ?? false;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ProviderOptionTile(
                            title: 'Online Metadata',
                            subtitle:
                                'As per the episode metadata priority list and settings',
                            isSelected: isOnlineSelected,
                            onTap: () {
                              final wasAuto = isAnify.value &&
                                  metaService.selectedSource.value == 'auto';
                              metaService.setSelectedSource('auto');
                              isAnify.value = true;
                              if (!wasAuto) {
                                controller?.refreshEpisodeMetadata();
                              }
                            },
                            footer: isOnlineSelected
                                ? AnymeXButton(
                                    width: double.infinity,
                                    height: 40,
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      if (!isRefreshing) {
                                        controller?.refreshEpisodeMetadata();
                                      }
                                    },
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isRefreshing)
                                          SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: context.colors.onPrimary,
                                            ),
                                          )
                                        else
                                          Icon(
                                            Icons.refresh_rounded,
                                            size: 18,
                                            color: context.colors.onPrimary,
                                          ),
                                        const SizedBox(width: 8),
                                        AnymeXText(
                                          isRefreshing
                                              ? 'Refreshing...'
                                              : 'Refresh',
                                          variant: TextVariant.bold,
                                          size: 13,
                                          color: context.colors.onPrimary,
                                        ),
                                      ],
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 8),
                          _ProviderOptionTile(
                            title: context.l10n.labelOff,
                            subtitle:
                                'Pull raw data from source (might not contain thumbnail or extra info)',
                            isSelected: !isOnlineSelected,
                            onTap: () {
                              isAnify.value = false;
                              metaService.setSelectedSource('none');
                            },
                          ),
                        ],
                      );
                    }(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final sourceController = Get.find<SourceController>();
    return Obx(() {
      final installed = sourceController.installedExtensions;
      if (installed.isEmpty) {
        return const NoSourceSelectedWidget();
      }

      final activeSource =
          sourceController.activeSource.value ?? installed.first;
      final titleText = searchedTitle is RxString
          ? searchedTitle.value
          : (searchedTitle is Rx
              ? searchedTitle.value
              : searchedTitle.toString());

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          UnifiedSourceSection(
            media: anilistData is Media
                ? anilistData
                : Media(serviceType: ServicesType.extensions),
            searchedTitle: titleText.toString(),
            activeSource: activeSource,
            installedSources: installed,
            onSourceSelected: (source) {
              Get.find<MediaDetailsController>(tag: tag).switchSource(source);
            },
            onWrongTitleMapped: (manga) async {
              final controller = Get.find<MediaDetailsController>(tag: tag);
              controller.episodeList.clear();
              await controller.fetchSourceDetailsFromMedia(
                  Media.froDMedia(manga, controller.media.value.mediaType));
            },
          ),
          const SizedBox(height: 12),
        ],
      );
    });
  }

  Widget _buildEpisodeListSliver(BuildContext context) {
    return Obx(() {
      final controller = Get.find<MediaDetailsController>(tag: tag);
      final episodes = controller.episodeList;
      final isLoading = controller.isLoading.value;
      final hasError = episodeError.value || controller.episodeError.value;

      if (isLoading) {
        return const SliverToBoxAdapter(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: AnymeXProgressIndicator(),
            ),
          ),
        );
      }

      if (hasError || episodes.isEmpty) {
        return SliverToBoxAdapter(
          child: ContentErrorWidget(
            errorType: controller.errorType.value,
            errorMessage: controller.errorMessage.value,
            isManga: false,
            onRetry: () => controller.retryFetch(),
            onWrongTitle: () {
              final media = anilistData is Media
                  ? anilistData as Media
                  : controller.media.value;
              showWrongTitleModal(
                context,
                media.title,
                (manga) async {
                  controller.episodeList.clear();
                  await controller.fetchSourceDetailsFromMedia(
                    Media.froDMedia(manga, controller.media.value.mediaType),
                  );
                },
                isManga: false,
                isNovel: false,
                mediaId: media.id.toString(),
              );
            },
          ),
        );
      }

      return EpisodeListBuilder(
        episodeList: episodes.toList(),
        anilistData: anilistData is Media ? anilistData : null,
        isSliverMode: true,
        onSettingsTap: () => _showEpisodeSettingsDialog(context),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final installed = sourceController.installedExtensions.isNotEmpty;

    if (isSliverMode) {
      return SliverMainAxisGroup(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverToBoxAdapter(child: _buildHeader(context)),
          ),
          if (installed)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: _buildEpisodeListSliver(context),
            ),
        ],
      );
    }

    return CustomScrollView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildHeader(context),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: _buildEpisodeListSliver(context),
        ),
      ],
    );
  }
}

class _ProviderOptionTile extends StatelessWidget {
  const _ProviderOptionTile({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    this.footer,
  });

  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isSelected
            ? colors.primaryContainer.opaque(0.35, iReallyMeanIt: true)
            : colors.surfaceContainerHighest.opaque(0.3, iReallyMeanIt: true),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? colors.primary.opaque(0.4, iReallyMeanIt: true)
              : colors.onSurface.opaque(0.1, iReallyMeanIt: true),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: footer != null
                  ? const BorderRadius.vertical(top: Radius.circular(14))
                  : BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnymeXText(
                            title,
                            variant: TextVariant.semiBold,
                            size: 13,
                          ),
                          const SizedBox(height: 2),
                          AnymeXText(
                            subtitle,
                            size: 11,
                            color: colors.onSurface
                                .opaque(0.6, iReallyMeanIt: true),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: isSelected
                          ? colors.primary
                          : colors.onSurface.opaque(0.4, iReallyMeanIt: true),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: footer!,
            ),
        ],
      ),
    );
  }
}
