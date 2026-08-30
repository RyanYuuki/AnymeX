import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/database/isar_models/episode.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/widgets/episode/episode_style_registry.dart';
import 'package:anymex/screens/anime/widgets/episode_list_builder.dart';
import 'package:anymex/screens/extensions/ExtensionSettings/ExtensionSettings.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_progress.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/common/no_source.dart';
import 'package:anymex_extension_runtime_bridge/Services/CloudStream/CloudStreamSourceMethods.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:anymex/screens/anime/details/controller/media_details_controller.dart';
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
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Obx(
          () => AnymeXDialog(
            title: 'Episode List Settings',
            onConfirm: () {},
            contentWidget: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showAnify.value && !disableAnifyForCurrentSource.value) ...[
                  _ProviderOptionTile(
                    title: 'Anify / Kitsu Artwork',
                    subtitle: 'Use enhanced episode metadata and covers',
                    isSelected: isAnify.value,
                    onTap: () {
                      isAnify.value = !isAnify.value;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                const AnymeXText('Layout Style',
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
              ],
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

      final activeSource = sourceController.activeSource.value ?? installed.first;
      final titleText = searchedTitle is RxString
          ? searchedTitle.value
          : (searchedTitle is Rx ? searchedTitle.value : searchedTitle.toString());

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
      final episodes =
          Get.find<MediaDetailsController>(tag: tag).episodeList;
      if (episodeError.value) {
        return const SliverToBoxAdapter(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: AnymeXText('Error loading episodes from source'),
            ),
          ),
        );
      } else if (episodes.isEmpty) {
        return const SliverToBoxAdapter(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: AnymeXProgressIndicator(),
            ),
          ),
        );
      } else {
        return EpisodeListBuilder(
          episodeList: episodes,
          anilistData: anilistData is Media ? anilistData : null,
          isSliverMode: true,
          onSettingsTap: () => _showEpisodeSettingsDialog(context),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isSliverMode) {
      return SliverMainAxisGroup(
        slivers: [
          SliverPadding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverToBoxAdapter(child: _buildHeader(context)),
          ),
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
  });

  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.primaryContainer.opaque(0.35, iReallyMeanIt: true)
                : colors.surfaceContainerHighest
                    .opaque(0.3, iReallyMeanIt: true),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? colors.primary.opaque(0.4, iReallyMeanIt: true)
                  : colors.onSurface.opaque(0.1, iReallyMeanIt: true),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnymeXText(title,
                      variant: TextVariant.semiBold,
                      size: 13,
                    ),
                    const SizedBox(height: 2),
                    AnymeXText(subtitle,
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
    );
  }
}
