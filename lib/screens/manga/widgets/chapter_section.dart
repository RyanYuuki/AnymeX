import 'dart:developer';

import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Offline/Hive/chapter.dart';
import 'package:anymex/screens/manga/widgets/chapter_list_builder.dart';
import 'package:anymex/widgets/common/no_source.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/minor_widgets/custom_text.dart';
import 'package:anymex/widgets/minor_widgets/custom_textspan.dart';
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
                  TVWrapper(
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
              Obx(() => DropdownButtonFormField<String>(
                    value: sourceController.installedMangaExtensions.isEmpty
                        ? "No Sources Installed"
                        : '${sourceController.activeMangaSource.value?.name} (${sourceController.activeMangaSource.value?.lang?.toUpperCase()})',
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
                      fillColor:
                          Theme.of(context).colorScheme.secondaryContainer,
                      labelStyle: TextStyle(
                          color: Theme.of(context).colorScheme.inverseSurface),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryFixedVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    isExpanded: true,
                    items: [
                      if (sourceController.installedMangaExtensions.isEmpty)
                        const DropdownMenuItem<String>(
                          value: "No Sources Installed",
                          child: Text(
                            "No Sources Installed",
                            style: TextStyle(fontFamily: 'Poppins-SemiBold'),
                          ),
                        ),
                      ...sourceController.installedMangaExtensions
                          .map<DropdownMenuItem<String>>((source) {
                        return DropdownMenuItem<String>(
                          value:
                              '${source.name} (${source.lang?.toUpperCase()})',
                          child: Text(
                            '${source.name?.toUpperCase()} (${source.lang?.toUpperCase()})',
                            style:
                                const TextStyle(fontFamily: 'Poppins-SemiBold'),
                          ),
                        );
                      }),
                    ],
                    onChanged: (value) async {
                      chapterList.value = [];
                      try {
                        sourceController.getMangaExtensionByName(value!);
                        await mapToAnilist();
                      } catch (e) {
                        log(e.toString());
                      }
                    },
                    dropdownColor:
                        Theme.of(context).colorScheme.secondaryContainer,
                    icon: Icon(Icons.arrow_drop_down,
                        color: Theme.of(context).colorScheme.primary),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                    ),
                  )),
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
}
