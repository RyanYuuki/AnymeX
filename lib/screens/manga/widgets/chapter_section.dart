import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/database/isar_models/chapter.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/extensions/ExtensionSettings/ExtensionSettings.dart';
import 'package:anymex/screens/manga/widgets/chapter_list_builder.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/language.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/no_source.dart';
import 'package:anymex/widgets/custom_widgets/anymex_dropdown.dart';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';
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

  String _sourceDropdownValue(Source source) => source.id.toString();

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
    return Obx(() => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              const SizedBox(height: 20),
              Obx(() => buildMangaSourceDropdown()),
              Obx(() => buildLanguageDropdown()),
              const SizedBox(height: 20),
              _buildListShell(
                context: context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const AnymexText(
                          text: "Chapters",
                          variant: TextVariant.bold,
                          size: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (sourceController.activeMangaSource.value == null)
                      const SizedBox(
                        height: 320,
                        child: NoSourceSelectedWidget(),
                      )
                    else if (chapterList.value.isEmpty)
                      const SizedBox(
                        height: 500,
                        child: Center(child: AnymexProgressIndicator()),
                      )
                    else if (searchedTitle.value.toLowerCase() !=
                        "no match found")
                      ChapterListBuilder(
                        chapters: chapterList,
                        anilistData: anilistData,
                      )
                    else
                      const Center(child: AnymexText(text: "No Match Found")),
                  ],
                ),
              ),
            ],
          ),
        ));
  }

  void openSourcePreferences(BuildContext context) {
    navigate(
      () => SourcePreferenceScreen(
        source: sourceController.activeMangaSource.value!,
      ),
    );
  }

  Widget buildMangaSourceDropdown() {
    List<DropdownItem> items = sourceController.installedMangaExtensions.isEmpty
        ? [
            const DropdownItem(
              value: "No Sources Installed",
              text: "No Manga Sources Available",
              subtitle: "Install manga extensions to get started",
              leadingIcon: Icon(
                Icons.menu_book_outlined,
                size: 24,
                color: Colors.grey,
              ),
            ),
          ]
        : sourceController.installedMangaExtensions.map<DropdownItem>((source) {
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
    if (sourceController.installedMangaExtensions.isEmpty) {
      selectedItem = items.first;
    } else {
      final activeSource = sourceController.activeMangaSource.value;
      if (activeSource != null) {
        selectedItem = DropdownItem(
          value: _sourceDropdownValue(activeSource),
          text: activeSource.name?.toUpperCase() ?? 'Unknown Source',
          subtitle: 'Manga • ${activeSource.lang?.toUpperCase() ?? 'Unknown'}',
          leadingIcon: AnymeXImage(
            radius: 12,
            imageUrl: activeSource.managerIcon,
            height: 20,
            width: 20,
          ),
        );
      } else if (items.isNotEmpty) {
        selectedItem = null;
      }
    }

    return AnymexDropdown(
      items: items,
      selectedItem: selectedItem,
      label: "SELECT SOURCE",
      icon: Icons.extension_rounded,
      actionIcon: Icons.settings_outlined,
      onActionPressed: () => openSourcePreferences(Get.context!),
      onChanged: (DropdownItem item) async {
        chapterList.value = [];
        try {
          sourceController.getMangaExtensionByName(item.value,
              mediaId: anilistData.id.toString());
          await mapToAnilist();
        } catch (e) {
          Logger.i(e.toString());
        }
      },
    );
  }

  void handleLanguageChange(String? value) async {
    if (value == null) return;

    final activeSource = sourceController.activeMangaSource.value as ASource?;
    if (activeSource == null || activeSource.langs == null) return;

    final newSubSource =
        activeSource.langs!.firstWhere((s) => s.id.toString() == value);
    sourceController.setActiveSource(newSubSource);

    chapterList.value = [];
    try {
      await mapToAnilist();
    } catch (e) {
      Logger.i(e.toString());
    }
  }

  Widget buildLanguageDropdown() {
    final activeSource = sourceController.activeMangaSource.value;
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
}
