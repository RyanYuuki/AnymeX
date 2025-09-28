// ignore_for_file: invalid_use_of_protected_member

import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/utils/logger.dart';

import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Offline/Hive/chapter.dart';
import 'package:anymex/screens/manga/widgets/chapter_list_builder.dart';
import 'package:anymex/widgets/common/no_source.dart';
import 'package:anymex/widgets/custom_widgets/anymex_dropdown.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:anymex/widgets/header.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/custom_widgets/custom_textspan.dart';
import 'package:dartotsu_extension_bridge/ExtensionManager.dart';
import 'package:dartotsu_extension_bridge/Models/Source.dart';
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

  @override
  Widget build(BuildContext context) {
    return Obx(() => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .shadow
                          .withOpacity(0.08),
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
                          if (!searchedTitle.value.contains('Searching') &&
                              !searchedTitle.value.contains('No Match Found'))
                            AnymexTextSpan(
                              text: "Found: ",
                              size: 14,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                          AnymexTextSpan(
                            text: searchedTitle.value,
                            variant: TextVariant.semiBold,
                            size: 14,
                            color:
                                searchedTitle.value.contains('No Match Found')
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
                          anilistData.title,
                          (manga) async {
                            chapterList.value = [];
                            await getDetailsFromSource(
                                Media.froDMedia(manga, ItemType.manga));
                            final key =
                                '${sourceController.activeMangaSource.value?.id}-${anilistData.id}-${anilistData.serviceType.index}';
                            settingsController.preferences
                                .put(key, manga.title);
                          },
                          isManga: true,
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
              Obx(() => buildMangaSourceDropdown()),
              const SizedBox(height: 20),
              const Row(
                children: [
                  AnymexText(
                    text: "Chapters",
                    variant: TextVariant.bold,
                    size: 18,
                  ),
                ],
              ),
              if (sourceController.activeMangaSource.value == null)
                const NoSourceSelectedWidget()
              else if (chapterList.value.isEmpty)
                const SizedBox(
                  height: 500,
                  child: Center(child: AnymexProgressIndicator()),
                )
              else
                searchedTitle.value != "No match found"
                    ? ChapterListBuilder(
                        chapters: chapterList,
                        anilistData: anilistData,
                      )
                    : const Center(child: AnymexText(text: "No Match Found"))
            ],
          ),
        ));
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
    if (sourceController.installedMangaExtensions.isEmpty) {
      selectedItem = items.first;
    } else {
      final activeSource = sourceController.activeMangaSource.value;
      if (activeSource != null) {
        final isMangayomi =
            activeSource.extensionType == ExtensionType.mangayomi;

        selectedItem = DropdownItem(
          value: '${activeSource.name} (${activeSource.lang?.toUpperCase()})',
          text: activeSource.name?.toUpperCase() ?? 'Unknown Source',
          subtitle: 'Manga • ${activeSource.lang?.toUpperCase() ?? 'Unknown'}',
          leadingIcon: NetworkSizedImage(
            radius: 12,
            imageUrl: isMangayomi
                ? "https://raw.githubusercontent.com/kodjodevf/mangayomi/main/assets/app_icons/icon-red.png"
                : 'https://aniyomi.org/img/logo-128px.png',
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
      onChanged: (DropdownItem item) async {
        chapterList.value = [];
        try {
          sourceController.getMangaExtensionByName(item.value);
          await mapToAnilist();
        } catch (e) {
          Logger.i(e.toString());
        }
      },
    );
  }
}
