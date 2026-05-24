import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/database/isar_models/chapter.dart';
import 'package:anymex/screens/manga/widgets/chapter_ranges.dart';
import 'package:anymex/screens/novel/details/controller/details_controller.dart';
import 'package:anymex/screens/novel/details/widgets/chapter_item.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex_extension_runtime_bridge/Models/DEpisode.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

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
  bool _initializedChunk = false;
  Worker? _selectedChunkWorker;
  Worker? _chaptersWorker;

  @override
  void initState() {
    super.initState();
    _initializeChapterChunking();
  }

  void _initializeChapterChunking() {
    _chunkChapters();

    _selectedChunkWorker = ever(selectedChunkIndex, (_) {
      _updateFilteredChapters();
    });

    _chaptersWorker = ever(widget.controller.chapters, (_) {
      _chunkChapters();
    });
  }

  void _chunkChapters() {
    final chaptersForChunking =
        widget.controller.chapters.where((e) => e.number != null).toList();

    if (chaptersForChunking.isEmpty) {
      chunkedChapters.clear();
      filteredChapters.clear();
      _initializedChunk = false;
      return;
    }

    chunkedChapters.value = chunkChapter(
      chaptersForChunking,
      calculateChapterChunkSize(chaptersForChunking),
    );

    if (chunkedChapters.isNotEmpty && !_initializedChunk) {
      final auth = Get.find<ServiceHandler>();
      final userProgress = _getUserProgress(
        auth,
        widget.controller.media.value.id,
      );

      final chunkIndex = findChapterChunkIndexFromProgress(
        userProgress,
        chunkedChapters.toList(growable: false),
      );
      final maxIndex = chunkedChapters.length - 1;
      selectedChunkIndex.value =
          maxIndex < 1 ? 0 : chunkIndex.clamp(1, maxIndex);
      _initializedChunk = true;
    }

    _updateFilteredChapters();
  }

  void _updateFilteredChapters() {
    if (chunkedChapters.isEmpty) {
      filteredChapters.clear();
      return;
    }

    final safeIndex =
        selectedChunkIndex.value.clamp(0, chunkedChapters.length - 1);
    if (selectedChunkIndex.value != safeIndex) {
      selectedChunkIndex.value = safeIndex;
      return;
    }
    filteredChapters.value = chunkedChapters[safeIndex];
  }

  int _getUserProgress(ServiceHandler auth, String mediaId) {
    if (auth.isLoggedIn.value &&
        auth.serviceType.value != ServicesType.extensions) {
      final tracked =
          auth.onlineService.mangaList.firstWhereOrNull((e) => e.id == mediaId);
      return int.tryParse(tracked?.chapterCount.toString() ?? '') ?? 1;
    }

    final offlineStorage = Get.find<OfflineStorageController>();
    final saved = offlineStorage.getMangaById(mediaId);
    return saved?.currentChapter?.number?.toInt() ?? 1;
  }

  void sortToggle() {
    filteredChapters.value = filteredChapters.reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoading = widget.controller.isLoading.value;

      return CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            sliver: DecoratedSliver(
              decoration: BoxDecoration(
                color:
                    Theme.of(context).colorScheme.surfaceContainer.opaque(0.3),
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
                    SliverToBoxAdapter(child: _buildHeader(context)),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    if (isLoading)
                      const SliverToBoxAdapter(
                        child: SizedBox(
                          height: 500,
                          child: Center(child: AnymexProgressIndicator()),
                        ),
                      )
                    else if (chunkedChapters.isEmpty)
                      const SliverToBoxAdapter(
                        child: SizedBox(
                          height: 240,
                          child: Center(
                            child: AnymexText(text: "No Chapters Found"),
                          ),
                        ),
                      )
                    else ...[
                      SliverToBoxAdapter(child: _buildChapterRanges()),
                      const SliverToBoxAdapter(child: SizedBox(height: 10)),
                      _buildChapterGrid(context),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      );
    });
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const AnymexText(
          text: "Chapters",
          variant: TextVariant.bold,
          size: 18,
        ),
        const Spacer(),
        IconButton(
          onPressed: sortToggle,
          icon: const Icon(Icons.sort_rounded),
        ),
      ],
    );
  }

  Widget _buildChapterRanges() {
    return ChapterRanges(
      selectedChunkIndex: selectedChunkIndex,
      onChunkSelected: (v) => selectedChunkIndex.value = v,
      chunks: chunkedChapters.toList(growable: false),
    );
  }

  Widget _buildChapterGrid(BuildContext context) {
    return SuperSliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final chapter = filteredChapters[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ChapterListItem(
              controller: widget.controller,
              onTap: () {
                widget.controller.goToReader(
                  chapter,
                  filteredChapters: filteredChapters,
                );
              },
              chapter: chapter,
            ),
          );
        },
        childCount: filteredChapters.length,
      ),
    );
  }

  @override
  void dispose() {
    _selectedChunkWorker?.dispose();
    _chaptersWorker?.dispose();
    super.dispose();
  }
}

extension ChapterMapper on DEpisode {
  Chapter toChapter() {
    final chapterNumber = double.tryParse(episodeNumber) ?? 0;

    return Chapter(
      title: name,
      link: url,
      number: chapterNumber,
      releaseDate: dateUpload,
      scanlator: scanlator,
    );
  }
}
