import 'package:anymex/models/Offline/Hive/chapter.dart';
import 'package:anymex/screens/manga/widgets/chapter_ranges.dart';
import 'package:anymex/screens/novel/details/controller/details_controller.dart';
import 'package:anymex/screens/novel/details/widgets/chapter_item.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/animation/animations.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:dartotsu_extension_bridge/Mangayomi/string_extensions.dart';
import 'package:dartotsu_extension_bridge/Models/DEpisode.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChapterSliverSection extends StatefulWidget {
  final NovelDetailsController controller;

  const ChapterSliverSection({
    super.key,
    required this.controller,
  });

  @override
  State<ChapterSliverSection> createState() => _ChapterSliverSectionState();
}

class _ChapterSliverSectionState extends State<ChapterSliverSection> {
  final chunkedChapters = <List<Chapter>>[].obs;
  final filteredChapters = <Chapter>[].obs;
  final selectedChunkIndex = 0.obs;

  @override
  void initState() {
    super.initState();
    _initializeChapterChunking();
  }

  void _initializeChapterChunking() {
    _chunkChapters();

    ever(selectedChunkIndex, (_) {
      if (chunkedChapters.isNotEmpty &&
          selectedChunkIndex.value < chunkedChapters.length) {
        filteredChapters.value = chunkedChapters[selectedChunkIndex.value];
      }
    });

    ever(widget.controller.chapters, (_) {
      _chunkChapters();
    });
  }

  void _chunkChapters() {
    final chaptersForChunking =
        widget.controller.chapters.where((e) => e.number != null).toList();

    if (chaptersForChunking.isNotEmpty) {
      chunkedChapters.value = chunkChapter(
          chaptersForChunking, calculateChapterChunkSize(chaptersForChunking));

      if (chunkedChapters.isNotEmpty) {
        filteredChapters.value = chunkedChapters[selectedChunkIndex.value];
      }
    }
  }

  void sortToggle() {
    filteredChapters.value = filteredChapters.value.reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: 20.height(),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                const AnymexText(
                  text: "Chapters",
                  variant: TextVariant.bold,
                  size: 18,
                ),
                const Spacer(),
                IconButton(
                    onPressed: sortToggle, icon: const Icon(Icons.sort_rounded))
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: 5.height(),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(left: 20.0),
            child: Obx(() {
              selectedChunkIndex.value;
              if (chunkedChapters.isEmpty) return const SizedBox.shrink();

              return ChapterRanges(
                selectedChunkIndex: selectedChunkIndex,
                onChunkSelected: (v) {},
                chunks: chunkedChapters.value,
              );
            }),
          ),
        ),
        SliverToBoxAdapter(
          child: 20.height(),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          sliver: Obx(() {
            if (filteredChapters.isEmpty) {
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            }

            return SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final chapter = filteredChapters[index];
                  return AnimatedItemWrapper(
                    child: ChapterListItem(
                      controller: widget.controller,
                      onTap: () {
                        widget.controller.goToReader(chapter,
                            filteredChapters: filteredChapters);
                      },
                      chapter: chapter,
                    ),
                  );
                },
                childCount: filteredChapters.length,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: getResponsiveCrossAxisCount(
                  context,
                  baseColumns: 1,
                  maxColumns: 3,
                  mobileItemWidth: 400,
                  tabletItemWidth: 500,
                  desktopItemWidth: 500,
                ),
                mainAxisExtent: 80,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
            );
          }),
        ),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

extension ChapterMapper on DEpisode {
  Chapter toChapter() {
    return Chapter(
        title: name,
        link: url,
        number: (episodeNumber).toDouble(),
        releaseDate: dateUpload,
        scanlator: scanlator);
  }
}
