// ignore_for_file: invalid_use_of_protected_member

import 'dart:developer';

import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Offline/Hive/chapter.dart';
import 'package:anymex/screens/manga/widgets/chapter_list_builder.dart';
import 'package:anymex/widgets/common/no_source.dart';
import 'package:anymex/widgets/custom_widgets/anymex_dropdown.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/custom_widgets/custom_textspan.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.only(left: 2),
                    width: Get.width * 0.6,
                    child: AnymexTextSpans(
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
                    ),
                  ),
                  AnymexOnTap(
                    onTap: () {
                      showWrongTitleModal(
                        context,
                        anilistData.title,
                        (manga) async {
                          chapterList.value = [];
                          await getDetailsFromSource(
                              Media.fromManga(manga, MediaType.manga));
                        },
                        isManga: true,
                      );
                    },
                    child: AnymexText(
                      text: "Wrong Title?",
                      variant: TextVariant.semiBold,
                      size: 16,
                      maxLines: 1,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
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
              text: "No Sources Installed",
            ),
          ]
        : sourceController.installedMangaExtensions.map<DropdownItem>((source) {
            return DropdownItem(
              value: '${source.name} (${source.lang?.toUpperCase()})',
              text:
                  '${source.name?.toUpperCase()} (${source.lang?.toUpperCase()})',
            );
          }).toList();

    DropdownItem? selectedItem;
    if (sourceController.installedMangaExtensions.isEmpty) {
      selectedItem = items.first;
    } else {
      final activeSource = sourceController.activeMangaSource.value;
      if (activeSource != null) {
        selectedItem = DropdownItem(
          value: '${activeSource.name} (${activeSource.lang?.toUpperCase()})',
          text:
              '${activeSource.name?.toUpperCase()} (${activeSource.lang?.toUpperCase()})',
        );
      } else if (items.isNotEmpty) {
        selectedItem = null;
      }
    }

    return AnymexDropdown(
      items: items,
      selectedItem: selectedItem,
      label: "SELECT SOURCE",
      icon: Iconsax.folder5,
      onChanged: (DropdownItem item) async {
        chapterList.value = [];
        try {
          sourceController.getMangaExtensionByName(item.value);
          await mapToAnilist();
        } catch (e) {
          log(e.toString());
        }
      },
    );
  }
}
