import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/database/isar_models/chapter.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/extensions/ExtensionSettings/ExtensionSettings.dart';
import 'package:anymex/screens/manga/widgets/chapter_list_builder.dart';
import 'package:anymex/utils/function.dart';

import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/no_source.dart';
import 'package:anymex/widgets/common/cloudflare_webview.dart';
import 'package:anymex/widgets/common/source_selector.dart';

import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/custom_widgets/custom_textspan.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex_extension_runtime_bridge/Services/Aniyomi/Models/Source.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChapterSection extends StatelessWidget {
  final RxString searchedTitle;
  final Media anilistData;
  final RxList<Chapter> chapterList;
  final SourceController sourceController;
  final Future<void> Function() mapToAnilist;
  final Future<void> Function(Media media) getDetailsFromSource;
  final void Function(
    BuildContext context,
    String title,
    Function(dynamic manga) onMangaSelected, {
    required bool isManga,
    String? mediaId,
  }) showWrongTitleModal;

  const ChapterSection({
    super.key,
    required this.searchedTitle,
    required this.anilistData,
    required this.chapterList,
    required this.sourceController,
    required this.mapToAnilist,
    required this.getDetailsFromSource,
    required this.showWrongTitleModal,
  });



  Widget _buildListShell({
    required BuildContext context,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer.opaque(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.colors.outline.opaque(0.2, iReallyMeanIt: true),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context)
                .colorScheme
                .shadow
                .opaque(0.08, iReallyMeanIt: true),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildSliverContent(context);
  }

  Widget _buildSliverContent(BuildContext context) {
    return Obx(() => SliverMainAxisGroup(
          slivers: [
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
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: context.colors.outline
                          .opaque(0.2, iReallyMeanIt: true),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .shadow
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
                              text: searchedTitle.value,
                              variant: TextVariant.semiBold,
                              size: 14,
                              color:
                                  searchedTitle.value.contains('No Match Found')
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
                            anilistData.title,
                            (manga) async {
                              chapterList.value = [];
                              await getDetailsFromSource(
                                  Media.froDMedia(manga, ItemType.manga));
                              final key =
                                  '${sourceController.activeMangaSource.value?.id}-${anilistData.id}-${anilistData.serviceType.index}';
                              DynamicKeys.mappedMediaTitle.set(key, manga.title);
                            },
                            isManga: true,
                            mediaId: anilistData.id.toString(),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .opaque(0.4),
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
                child: SourceSelectorWidget(
                  activeSource: sourceController.activeMangaSource.value,
                  installedSources: sourceController.installedMangaExtensions,
                  isManga: true,
                  onSourceSelected: (source) async {
                    chapterList.value = [];
                    try {
                      sourceController.getMangaExtensionByName(
                        source.id.toString(),
                        mediaId: anilistData.id.toString(),
                      );
                      await mapToAnilist();
                    } catch (e) {
                      Logger.i(e.toString());
                    }
                  },
                  onSubSourceSelected: (sub) {
                    handleLanguageChange(sub.id.toString());
                  },
                  onCloudflareBypass:
                      sourceController.activeMangaSource.value?.baseUrl != null
                          ? () => Get.context!.openCloudflareBypass(
                              sourceController.activeMangaSource.value!.baseUrl!)
                          : null,
                  onPreferencesTap:
                      sourceController.activeMangaSource.value != null
                          ? () => openSourcePreferences(Get.context!)
                          : null,
                ),
              ),
            ),
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
                      color: Theme.of(context)
                          .colorScheme
                          .shadow
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
                      const SliverToBoxAdapter(
                        child: Row(
                          children: [
                            AnymexText(
                              text: "Chapters",
                              variant: TextVariant.bold,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 16)),
                      if (sourceController.activeMangaSource.value == null)
                        const SliverToBoxAdapter(
                          child: SizedBox(
                            height: 320,
                            child: NoSourceSelectedWidget(),
                          ),
                        )
                      else if (chapterList.value.isEmpty)
                        const SliverToBoxAdapter(
                          child: SizedBox(
                            height: 500,
                            child: Center(child: AnymexProgressIndicator()),
                          ),
                        )
                      else if (searchedTitle.value.toLowerCase() !=
                          "no match found")
                        ChapterListBuilder(
                          chapters: chapterList,
                          anilistData: anilistData,
                          isSliverMode: true,
                        )
                      else
                        const SliverToBoxAdapter(
                          child: Center(
                              child: AnymexText(text: "No Match Found")),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 10)),
          ],
        ));
  }

  void openSourcePreferences(BuildContext context) {
    navigate(
      () => SourcePreferenceScreen(
        source: sourceController.activeMangaSource.value!,
      ),
    );
  }

  Future<void> handleLanguageChange(String? value) async {
    if (value == null) return;

    final activeSource = sourceController.activeMangaSource.value as ASource?;
    if (activeSource == null || activeSource.langs == null) return;

    final newSubSource =
        activeSource.langs!.firstWhere((s) => s.id.toString() == value);
    sourceController.setActiveSource(newSubSource,
        mediaId: anilistData.id.toString());

    chapterList.value = [];
    try {
      await mapToAnilist();
    } catch (e) {
      Logger.i(e.toString());
    }
  }
}
