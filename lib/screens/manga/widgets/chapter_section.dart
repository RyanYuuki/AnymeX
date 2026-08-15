import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/database/isar_models/chapter.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details/controller/media_details_controller.dart';
import 'package:anymex/screens/extensions/ExtensionSettings/ExtensionSettings.dart';
import 'package:anymex/screens/manga/widgets/chapter_list_builder.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_progress.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/common/no_source.dart';
import 'package:anymex/widgets/common/unified_source_section.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:anymex_extension_runtime_bridge/Services/Aniyomi/Models/Source.dart';
import 'package:anymex_extension_runtime_bridge/Services/CloudStream/CloudStreamSourceMethods.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChapterSection extends StatelessWidget {
  final dynamic searchedTitle;
  final dynamic anilistData;
  final RxList<Chapter>? chapterList;
  final RxBool chapterError;
  final String tag;

  const ChapterSection({
    super.key,
    required this.searchedTitle,
    required this.anilistData,
    required this.chapterList,
    required this.chapterError,
    required this.tag,
  });

  void openSourcePreferences(BuildContext context, Source active) async {
    if (active is CloudStreamSource) {
      if (active.hasSettings) {
        await CloudStreamSourceMethods(active).openNativeSettings();
      }
      return;
    }
    navigate(() => SourcePreferenceScreen(source: active));
  }

  Future<void> handleLanguageChange(BuildContext context, String? value,
      MediaDetailsController controller) async {
    if (value == null) return;
    final activeSource = controller.activeSource.value as ASource?;
    if (activeSource == null || activeSource.langs == null) return;

    final newSubSource =
        activeSource.langs!.firstWhere((s) => s.id.toString() == value);
    controller.switchSource(newSubSource);
  }

  Widget _buildHeader(BuildContext context) {
    final sourceController = Get.find<SourceController>();
    final isNovel = anilistData is Media &&
        (anilistData as Media).mediaType == ItemType.novel;

    return Obx(() {
      final installed = isNovel
          ? sourceController.installedNovelExtensions
          : sourceController.installedMangaExtensions;

      if (installed.isEmpty) {
        return const NoSourceSelectedWidget();
      }

      final activeSource = (isNovel
              ? sourceController.activeNovelSource.value
              : sourceController.activeMangaSource.value) ??
          installed.first;

      final titleText = searchedTitle is RxString
          ? searchedTitle.value
          : searchedTitle.toString();
      final controller = Get.find<MediaDetailsController>(tag: tag);
      final colors = context.colors;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          UnifiedSourceSection(
            media: anilistData is Media
                ? anilistData
                : Media(serviceType: ServicesType.extensions),
            searchedTitle: titleText,
            activeSource: activeSource,
            installedSources: installed,
            onSourceSelected: (source) {
              controller.switchSource(source);
            },
            onSubSourceSelected: (sub) {
              handleLanguageChange(context, sub.id.toString(), controller);
            },
            onWrongTitleMapped: (manga) async {
              controller.chapterList.clear();
              await controller.fetchSourceDetailsFromMedia(
                Media.froDMedia(manga, (anilistData as Media).mediaType),
              );
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest
                  .opaque(0.2, iReallyMeanIt: true),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colors.onSurface.opaque(0.08, iReallyMeanIt: true),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: AnymeXText(
                    text: 'Chapters',
                    variant: TextVariant.bold,
                    size: 18,
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showChapterSettingsDialog(context),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest
                            .opaque(0.35, iReallyMeanIt: true),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color:
                              colors.outline.opaque(0.15, iReallyMeanIt: true),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.settings_outlined,
                            size: 16,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 8),
                          AnymeXText(
                            text: 'Settings',
                            size: 12,
                            color: colors.primary,
                            variant: TextVariant.bold,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      );
    });
  }

  Widget _buildChapterListSliver(BuildContext context) {
    return Obx(() {
      final chapters = chapterList ?? <Chapter>[];
      if (chapterError.value) {
        return const SliverToBoxAdapter(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: AnymeXText(text: 'Error loading chapters from source'),
            ),
          ),
        );
      } else if (chapters.isEmpty) {
        return const SliverToBoxAdapter(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: AnymeXProgressIndicator(),
            ),
          ),
        );
      } else {
        return ChapterListBuilder(
          chapterList: chapters,
          anilistData: anilistData is Media ? anilistData : null,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          sliver: SliverToBoxAdapter(child: _buildHeader(context)),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: _buildChapterListSliver(context),
        ),
      ],
    );
  }

  void _showChapterSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final settings = Get.find<Settings>();
        return Obx(
          () => AnymeXDialog(
            title: 'Chapter List Settings',
            onConfirm: () {},
            contentWidget: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AnymeXText(
                  text: 'Layout Style',
                  variant: TextVariant.bold,
                  size: 14,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ProviderOptionTile(
                    title: 'Compact',
                    subtitle: 'Simple compact list view',
                    isSelected: settings.chapterStyle == 'compact',
                    onTap: () {
                      settings.chapterStyle = 'compact';
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ProviderOptionTile(
                    title: 'Detailed (Classic)',
                    subtitle:
                        'Full-width detailed cards with progress and read button',
                    isSelected: settings.chapterStyle == 'detailed',
                    onTap: () {
                      settings.chapterStyle = 'detailed';
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ProviderOptionTile(
                    title: 'Grid',
                    subtitle: 'Compact grid of chapter numbers',
                    isSelected: settings.chapterStyle == 'grid',
                    onTap: () {
                      settings.chapterStyle = 'grid';
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
                    AnymeXText(
                      text: title,
                      variant: TextVariant.semiBold,
                      size: 13,
                    ),
                    const SizedBox(height: 2),
                    AnymeXText(
                      text: subtitle,
                      size: 11,
                      color: colors.onSurface.opaque(0.6, iReallyMeanIt: true),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: colors.primary,
                  size: 20,
                )
              else
                Icon(
                  Icons.circle_outlined,
                  color: colors.onSurface.opaque(0.4, iReallyMeanIt: true),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
