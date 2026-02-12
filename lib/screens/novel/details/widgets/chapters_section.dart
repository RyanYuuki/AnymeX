import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Offline/Hive/chapter.dart';
import 'package:anymex/screens/manga/widgets/chapter_ranges.dart';
import 'package:anymex/screens/novel/details/controller/details_controller.dart';
import 'package:anymex/screens/novel/details/widgets/chapter_item.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/string_extensions.dart';
import 'package:anymex/widgets/animation/animations.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
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
  final selectedChunkIndex = 1.obs;
  bool _initializedChunk = false; // Add this flag

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

      if (chunkedChapters.isNotEmpty && !_initializedChunk) {
        // Get user progress from tracking service
        final auth = Get.find<ServiceHandler>();
        final userProgress = _getUserProgress(auth, widget.controller.media.id);
        
        // Set chunk index based on progress
        final chunkIndex = findChapterChunkIndexFromProgress(
          userProgress,
          chunkedChapters.value,
        );
        selectedChunkIndex.value = chunkIndex.clamp(
          1,
          chunkedChapters.value.length - 1
        );
        _initializedChunk = true;
      }

      if (chunkedChapters.isNotEmpty) {
        filteredChapters.value = chunkedChapters[selectedChunkIndex.value];
      }
    }
  }

  // Helper method to get user progress
  int _getUserProgress(ServiceHandler auth, String mediaId) {
    if (auth.isLoggedIn.value && 
        auth.serviceType.value != ServicesType.extensions) {
      final tracked = auth.onlineService.mangaList
          .firstWhereOrNull((e) => e.id == mediaId);
      return tracked?.chapterCount?.toInt() ?? 1;
    } else {
      final offlineStorage = Get.find<OfflineStorageController>();
      final saved = offlineStorage.getMangaById(mediaId);
      return saved?.currentChapter?.number?.toInt() ?? 1;
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
                onChunkSelected: (v) {
                  selectedChunkIndex.value = v;
                },
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
