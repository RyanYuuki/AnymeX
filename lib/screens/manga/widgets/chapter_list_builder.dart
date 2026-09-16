import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/database/isar_models/chapter.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/manga/reading_page.dart';
import 'package:anymex/screens/manga/widgets/chapter_ranges.dart';
import 'package:anymex/screens/manga/widgets/scanlators_ranges.dart';
import 'package:anymex/screens/novel/reader/novel_reader.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/animation/animations.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_button.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_progress.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/screens/downloads/controller/download_controller.dart';
import 'package:anymex/screens/downloads/model/download_models.dart';
import 'package:anymex/screens/downloads/widgets/manga_chapter_download_confirm.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/controllers/track/track_binding_controller.dart';
import 'package:anymex/screens/manga/widgets/track_dialog.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_bottomsheet.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile_builder.dart';
import 'package:anymex/widgets/common/anymex_pills.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

typedef _BatchOption = ({
  String title,
  String subtitle,
  IconData icon,
  bool enabled,
  VoidCallback onTap,
});


class _ChapterTileData {
  final double progressValue;
  final int progressPercentage;
  final bool isRead;
  final bool isSelected;

  const _ChapterTileData({
    required this.progressValue,
    required this.progressPercentage,
    required this.isRead,
    required this.isSelected,
  });
}

_ChapterTileData _computeTileData({
  required Chapter chapter,
  required List<Chapter> allChapters,
  required OfflineMedia? savedMedia,
  required int onlineProgress,
  required bool isLoggedInOnline,
}) {
  final readChaptersList = savedMedia?.readChapters ?? <Chapter>[];
  Chapter? savedChap;
  if (chapter.link != null && chapter.link!.isNotEmpty) {
    savedChap = readChaptersList.firstWhereOrNull((c) => c.link == chapter.link);
  }
  savedChap ??= readChaptersList.firstWhereOrNull((c) => c.number == chapter.number) ?? chapter;

  final totalPages = savedChap.totalPages ?? 0;
  final currentPage = savedChap.pageNumber ?? 0;
  final progressValue =
      totalPages > 0 ? (currentPage / totalPages).clamp(0.0, 1.0) : 0.0;
  final progressPercentage = (progressValue * 100).toInt();

  final savedPage = savedChap.pageNumber;
  final savedTotal = savedChap.totalPages;
  final isPageComplete = savedPage != null &&
      savedTotal != null &&
      savedTotal > 0 &&
      (savedPage >= savedTotal ||
          savedPage >= savedTotal - 1 ||
          (savedPage / savedTotal) >= 0.95);

  final bool isRead;
  if (isLoggedInOnline) {
    isRead =
        (chapter.number != null && chapter.number! <= onlineProgress) ||
            isPageComplete;
  } else {
    isRead = isPageComplete;
  }

  final lastRead = savedMedia?.currentChapter;
  Chapter? continueChapter;
  if (lastRead != null) {
    if (lastRead.link != null && lastRead.link!.isNotEmpty) {
      continueChapter = allChapters.firstWhereOrNull((c) => c.link == lastRead.link);
    }
    continueChapter ??= allChapters.firstWhereOrNull((c) => c.number == lastRead.number);
  }
  continueChapter ??= allChapters.isNotEmpty ? allChapters.first : null;

  final isSelected = (continueChapter != null &&
          chapter.link != null &&
          chapter.link!.isNotEmpty &&
          continueChapter.link != null &&
          continueChapter.link!.isNotEmpty)
      ? chapter.link == continueChapter.link
      : (chapter.number == continueChapter?.number &&
          chapter.scanlator == continueChapter?.scanlator);

  return _ChapterTileData(
    progressValue: progressValue,
    progressPercentage: progressPercentage,
    isRead: isRead,
    isSelected: isSelected,
  );
}

class ChapterListBuilder extends StatefulWidget {
  final List<Chapter> chapterList;
  final Media? anilistData;
  final RxInt? selectedScanlatorIndex;
  final VoidCallback? onSettingsTap;

  const ChapterListBuilder({
    super.key,
    required this.chapterList,
    required this.anilistData,
    this.selectedScanlatorIndex,
    this.onSettingsTap,
  });

  @override
  State<ChapterListBuilder> createState() => _ChapterListBuilderState();
}

class _ChapterListBuilderState extends State<ChapterListBuilder> {
  final RxInt selectedChunkIndex = 0.obs;
  final RxInt selectedViewTab = 0.obs;
  late final RxInt selectedScanlatorIndex;
  final _offlineStorage = Get.find<OfflineStorageController>();
  final _auth = Get.find<ServiceHandler>();
  final _sourceController = Get.find<SourceController>();
  late final DownloadController _downloadController;

  OfflineMedia? _savedMedia;
  int _onlineProgress = 0;
  bool _isLoggedInOnline = false;
  VoidCallback? _offlineStorageListener;

  @override
  void initState() {
    super.initState();
    selectedScanlatorIndex = widget.selectedScanlatorIndex ?? 0.obs;
    _downloadController = Get.isRegistered<DownloadController>()
        ? Get.find<DownloadController>()
        : Get.put(DownloadController());
    final mediaTitle = widget.anilistData?.title ?? '';
    final isNovel = widget.anilistData?.mediaType == ItemType.novel;
    final extName = (isNovel
            ? _sourceController.activeNovelSource.value?.name
            : _sourceController.activeMangaSource.value?.name) ??
        '';
    if (extName.isNotEmpty && mediaTitle.isNotEmpty) {
      _downloadController.ensureMangaMetaLoaded(extName, mediaTitle);
    }
    _resolveComputedState();
    _offlineStorageListener = () {
      _resolveComputedState();
      if (mounted) setState(() {});
    };
    _offlineStorage.addListener(_offlineStorageListener!);
  }

  @override
  void dispose() {
    if (_offlineStorageListener != null) {
      _offlineStorage.removeListener(_offlineStorageListener!);
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(ChapterListBuilder old) {
    super.didUpdateWidget(old);
    if (old.chapterList != widget.chapterList ||
        old.anilistData != widget.anilistData) {
      _resolveComputedState();
    }
  }

  void _resolveComputedState() {
    final id = widget.anilistData?.id ?? '';
    _savedMedia =
        _offlineStorage.getMangaById(id) ?? _offlineStorage.getNovelById(id);

    _isLoggedInOnline = _auth.isLoggedIn.value &&
        _auth.serviceType.value != ServicesType.extensions;

    if (_isLoggedInOnline && widget.anilistData != null) {
      final item = _auth.onlineService.mangaList
          .firstWhereOrNull((e) => e.id == widget.anilistData!.id);
      _onlineProgress =
          double.tryParse(item?.episodeCount ?? '')?.toInt() ?? 0;
    } else {
      _onlineProgress = 0;
    }
  }

  void _onTap(Chapter chapter) async {
    final isNovel = widget.anilistData?.mediaType == ItemType.novel;
    final activeSource = isNovel
        ? _sourceController.activeNovelSource.value
        : _sourceController.activeMangaSource.value;

    if (activeSource == null || widget.anilistData == null) return;

    if (isNovel) {
      await navigate(() => NovelReader(
            chapter: chapter,
            media: widget.anilistData!,
            chapters: widget.chapterList,
            source: activeSource,
          ));
      _resolveComputedState();
      if (mounted) setState(() {});
    } else {
      final mediaData = widget.anilistData!;
      final dbId = '${mediaData.id}_${mediaData.serviceType.name}_${mediaData.type}';
      
      bool shouldTrackValue = false;
      final isLoggedInOnline = _auth.isLoggedIn.value &&
          _auth.serviceType.value != ServicesType.extensions;

      if (isLoggedInOnline) {
        final savedTracking = DynamicKeys.trackingPermission.get<bool?>(dbId);
        if (savedTracking != null) {
          shouldTrackValue = savedTracking;
        } else if (General.shouldAskForTrack.get(true) == false) {
          shouldTrackValue = true;
        } else {
          final isExtension = mediaData.serviceType == ServicesType.extensions;
          final hasTrackBinding = Get.isRegistered<TrackBindingController>() &&
              Get.find<TrackBindingController>().hasAnyBinding(mediaData.id);

          if (isExtension) {
            shouldTrackValue = hasTrackBinding;
          } else {
            final result = await showTrackingDialog(context, dbId: dbId);
            shouldTrackValue = result ?? false;
          }
        }
      }

      final Set<String> scanlatorsSet = {};
      for (final ch in widget.chapterList) {
        if (ch.scanlator?.isNotEmpty == true) {
          scanlatorsSet.add(ch.scanlator!);
        }
      }
      final scanlatorsList = scanlatorsSet.toList();
      final scanIndex = selectedScanlatorIndex.value;
      final filteredChapters = (scanIndex == 0 || scanlatorsList.isEmpty)
          ? widget.chapterList
          : widget.chapterList
              .where((c) => c.scanlator == scanlatorsList[scanIndex - 1])
              .toList();

      await navigate(() => ReadingPage(
            anilistData: mediaData,
            chapterList: filteredChapters,
            currentChapter: chapter,
            shouldTrack: shouldTrackValue,
          ));
      _resolveComputedState();
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.chapterList.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: AnymeXText('No chapters found'),
          ),
        ),
      );
    }

    final Set<String> scanlatorsSet = {};
    for (final ch in widget.chapterList) {
      if (ch.scanlator?.isNotEmpty == true) {
        scanlatorsSet.add(ch.scanlator!);
      }
    }
    final scanlatorsList = scanlatorsSet.toList();

    return Obx(() {
      final isNovel = widget.anilistData?.mediaType == ItemType.novel;
      final extName = (isNovel
              ? _sourceController.activeNovelSource.value?.name
              : _sourceController.activeMangaSource.value?.name) ??
          '';
      final mediaTitle = widget.anilistData?.title ?? '';
      final downloadedChapters =
          _downloadController.getDownloadedChapters(extName, mediaTitle);
      final isDownloadedTab = selectedViewTab.value == 1;

      final scanIndex = selectedScanlatorIndex.value;
      final filtered = (scanIndex == 0 || scanlatorsList.isEmpty)
          ? widget.chapterList
          : widget.chapterList
              .where((c) => c.scanlator == scanlatorsList[scanIndex - 1])
              .toList();

      final chunkSize = calculateChapterChunkSize(filtered);
      final chunks = chunkChapter(filtered, chunkSize);
      final validChunkIndex = selectedChunkIndex.value
          .clamp(0, chunks.isEmpty ? 0 : chunks.length - 1);
      final currentChapters =
          chunks.isNotEmpty ? chunks[validChunkIndex] : filtered;
      final settings = Get.find<Settings>();

      return SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHighest
                    .opaque(0.2, iReallyMeanIt: true),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.colors.onSurface
                      .opaque(0.08, iReallyMeanIt: true),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AnymeXPills(
                          scrollPadding: EdgeInsets.zero,
                          items: [
                            PillItem(
                              label: 'Online',
                              count: widget.chapterList.length,
                              isSelected: selectedViewTab.value == 0,
                              onTap: () => selectedViewTab.value = 0,
                            ),
                            PillItem(
                              label: 'Downloaded',
                              count: downloadedChapters.length,
                              isSelected: selectedViewTab.value == 1,
                              onTap: () => selectedViewTab.value = 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showBatchDownloadSheet(
                            context,
                            extName: extName,
                            mediaTitle: mediaTitle,
                            filteredChapters: filtered,
                            currentChunkChapters: currentChapters,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: context.colors.surfaceContainerHighest
                                  .opaque(0.35, iReallyMeanIt: true),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: context.colors.outline
                                    .opaque(0.15, iReallyMeanIt: true),
                              ),
                            ),
                            child: Icon(
                              Icons.file_download_outlined,
                              size: 16,
                              color: context.colors.primary,
                            ),
                          ),
                        ),
                      ),
                      if (widget.onSettingsTap != null) ...[
                        const SizedBox(width: 8),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: widget.onSettingsTap,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: context.colors.surfaceContainerHighest
                                    .opaque(0.35, iReallyMeanIt: true),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: context.colors.outline
                                      .opaque(0.15, iReallyMeanIt: true),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.settings_outlined,
                                    size: 16,
                                    color: context.colors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  AnymeXText(
                                    'Settings',
                                    size: 12,
                                    color: context.colors.primary,
                                    variant: TextVariant.bold,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (!isDownloadedTab) ...[
                    if (scanlatorsList.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: ScanlatorsRanges(
                          scanlators: scanlatorsList,
                          selectedScanIndex: selectedScanlatorIndex,
                          onScanIndexChanged: () {
                            selectedChunkIndex.value = 0;
                          },
                        ),
                      ),
                    if (chunks.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: ChapterRanges(
                          chunks: chunks,
                          selectedChunkIndex: selectedChunkIndex,
                          onChunkSelected: (index) =>
                              selectedChunkIndex.value = index,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          if (isDownloadedTab)
            if (downloadedChapters.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.cloud_download_outlined,
                          size: 48,
                          color: context.colors.onSurface.opaque(0.4),
                        ),
                        const SizedBox(height: 12),
                        AnymeXText(
                          'No downloaded chapters found for this manga',
                          size: 14,
                          variant: TextVariant.semiBold,
                          color: context.colors.onSurface.opaque(0.7),
                        ),
                        const SizedBox(height: 16),
                        AnymeXContainerButton(
                          onTap: () => selectedViewTab.value = 0,
                          radius: 12,
                          color: context.colors.primary,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: AnymeXText(
                              'Switch to Online',
                              color: context.colors.onPrimary,
                              variant: TextVariant.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (settings.chapterStyle == 'grid')
              SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 80,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  mainAxisExtent: 45,
                ),
                itemCount: downloadedChapters.length,
                itemBuilder: (context, index) {
                  final chMeta = downloadedChapters[index];
                  return _buildTile(
                    context,
                    chMeta.chapter,
                    settings,
                    customOnTap: () =>
                        _playDownloadedChapter(chMeta, downloadedChapters),
                    downloadButton: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: context.colors.error,
                        size: 14,
                      ),
                      onPressed: () => _confirmDeleteChapter(
                          context, chMeta, extName, mediaTitle),
                    ),
                  );
                },
              )
            else
              SliverList.builder(
                itemCount: downloadedChapters.length,
                itemBuilder: (context, index) {
                  final chMeta = downloadedChapters[index];
                  return _buildTile(
                    context,
                    chMeta.chapter,
                    settings,
                    customOnTap: () =>
                        _playDownloadedChapter(chMeta, downloadedChapters),
                    downloadButton: IconButton(
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: context.colors.error,
                        size: 20,
                      ),
                      onPressed: () => _confirmDeleteChapter(
                          context, chMeta, extName, mediaTitle),
                    ),
                  );
                },
              )
          else if (settings.chapterStyle == 'grid')
            SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 80,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                mainAxisExtent: 45,
              ),
              itemCount: currentChapters.length,
              itemBuilder: (context, index) {
                final chapter = currentChapters[index];
                return _buildTile(
                  context,
                  chapter,
                  settings,
                  downloadButton: _buildChapterDownloadButton(
                    context,
                    chapter,
                    extName,
                    mediaTitle,
                    isGrid: true,
                  ),
                );
              },
            )
          else
            SliverList.builder(
              itemCount: currentChapters.length,
              itemBuilder: (context, index) {
                final chapter = currentChapters[index];
                return _buildTile(
                  context,
                  chapter,
                  settings,
                  downloadButton: _buildChapterDownloadButton(
                    context,
                    chapter,
                    extName,
                    mediaTitle,
                  ),
                );
              },
            ),
        ],
      );
    });
  }

  Widget _buildTile(
    BuildContext context,
    Chapter chapter,
    Settings settings, {
    Widget? downloadButton,
    VoidCallback? customOnTap,
  }) {
    final colors = context.colors;

    final data = _computeTileData(
      chapter: chapter,
      allChapters: widget.chapterList,
      savedMedia: _savedMedia,
      onlineProgress: _onlineProgress,
      isLoggedInOnline: _isLoggedInOnline,
    );

    final onTap = customOnTap ?? () => _onTap(chapter);

    if (settings.chapterStyle == 'compact') {
      return _buildCompactTile(context, chapter, data, colors, onTap,
          downloadButton: downloadButton);
    }
    if (settings.chapterStyle == 'grid') {
      return _buildGridTile(chapter, data, colors, onTap,
          downloadButton: downloadButton);
    }
    if (settings.chapterStyle == 'detailed') {
      return _buildDetailedTile(context, chapter, data, colors, onTap,
          downloadButton: downloadButton);
    }
    return _buildDefaultTile(chapter, data, colors, onTap,
        downloadButton: downloadButton);
  }

  Widget _buildCompactTile(
    BuildContext context,
    Chapter chapter,
    _ChapterTileData data,
    ColorScheme colors,
    VoidCallback onTap, {
    Widget? downloadButton,
  }) {
    final chNum = chapter.formattedNumber;
    final chTitle = (chapter.title?.trim().isNotEmpty ?? false)
        ? chapter.title!.trim()
        : 'Chapter $chNum';

    return StaggeredAnimatedItemWrapper(
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: data.isRead ? 0.5 : 1.0,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: data.isSelected
                  ? colors.primaryContainer.opaque(0.4, iReallyMeanIt: true)
                  : colors.surfaceContainerHighest
                      .opaque(0.35, iReallyMeanIt: true),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: data.isSelected
                    ? colors.primary.opaque(0.5, iReallyMeanIt: true)
                    : colors.onSurface.opaque(0.08, iReallyMeanIt: true),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: data.isSelected
                        ? colors.primary
                        : colors.primaryContainer
                            .opaque(0.3, iReallyMeanIt: true),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: AnymeXText(
                    chNum,
                    size: 13,
                    variant: TextVariant.bold,
                    color: data.isSelected ? colors.onPrimary : colors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnymeXText(
                        chTitle,
                        size: 13,
                        variant: TextVariant.semiBold,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (chapter.scanlator?.isNotEmpty == true) ...[
                        const SizedBox(height: 2),
                        AnymeXText(
                          chapter.scanlator!,
                          size: 10,
                          color: colors.onSurface
                              .opaque(0.6, iReallyMeanIt: true),
                        ),
                      ],
                    ],
                  ),
                ),
                if (downloadButton != null) ...[
                  const SizedBox(width: 4),
                  downloadButton,
                ],
                if (data.progressValue > 0 && data.progressValue < 0.95) ...[
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      value: data.progressValue,
                      strokeWidth: 2.0,
                      backgroundColor: colors.primary.withOpacity(0.15),
                      color: colors.primary,
                    ),
                  ),
                ] else if (data.isRead || data.progressValue >= 0.95) ...[
                  const SizedBox(width: 10),
                  Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: colors.primary.opaque(0.7, iReallyMeanIt: true),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridTile(
    Chapter chapter,
    _ChapterTileData data,
    ColorScheme colors,
    VoidCallback onTap, {
    Widget? downloadButton,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: data.isRead ? 0.5 : 1.0,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: data.isSelected
                ? colors.primary
                : colors.surfaceContainerHighest.opaque(0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: data.isSelected
                  ? colors.primary
                  : colors.onSurface.opaque(0.08),
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnymeXText(
                chapter.formattedNumber,
                variant: TextVariant.bold,
                size: 13,
                color: data.isSelected ? colors.onPrimary : colors.onSurface,
              ),
              if (downloadButton != null)
                Positioned(
                  top: 2,
                  right: 2,
                  child: downloadButton,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedTile(
    BuildContext context,
    Chapter chapter,
    _ChapterTileData data,
    ColorScheme colors,
    VoidCallback onTap, {
    Widget? downloadButton,
  }) {
    final progressText = data.progressPercentage > 0
        ? ' (${(data.progressValue * 100).toInt()}%)'
        : '';
    final chapterMetaLabel = (chapter.scanlator?.isNotEmpty ?? false)
        ? chapter.scanlator!
        : (chapter.sourceName?.isNotEmpty ?? false)
            ? chapter.sourceName!
            : _sourceController.activeMangaSource.value?.name ?? '';
    final chapterMetaText = [
      if (chapter.releaseDate?.isNotEmpty ?? false) chapter.releaseDate!,
      if (chapterMetaLabel.isNotEmpty) chapterMetaLabel,
    ].join(' • ');

    return StaggeredAnimatedItemWrapper(
      child: AnymexOnTap(
        onTap: onTap,
        child: Opacity(
          opacity: data.isRead ? 0.5 : 1,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: data.isSelected
                  ? colors.secondary.withValues(alpha: 0.4)
                  : colors.surfaceContainerHighest.opaque(0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colors.onSurface.opaque(0.08),
              ),
            ),
            child: Row(
              children: [
                if (data.progressPercentage > 0)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(16.multiplyRadius()),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.surfaceContainerHighest,
                          ),
                        ),
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: AnymeXProgressIndicator(
                            value: data.progressValue,
                            strokeWidth: 4,
                            backgroundColor: colors.surfaceContainer,
                          ),
                        ),
                        AnymeXText(
                          '${data.progressPercentage}%',
                          size: 9,
                          variant: TextVariant.bold,
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius:
                          BorderRadius.circular(16.multiplyRadius()),
                      boxShadow: [glowingShadow(context)],
                    ),
                    child: AnymeXText(
                      chapter.formattedNumber,
                      variant: TextVariant.bold,
                      color: colors.onPrimary,
                    ),
                  ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnymeXText(
                        '${chapter.title}$progressText',
                        variant: TextVariant.semiBold,
                        size: 13,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      AnymeXText(
                        chapterMetaText,
                        size: 11,
                        color: colors.inverseSurface.opaque(0.7),
                        fontStyle: FontStyle.italic,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (downloadButton != null) ...[
                  const SizedBox(width: 8),
                  downloadButton,
                ],
                const SizedBox(width: 8),
                Container(
                  decoration:
                      BoxDecoration(boxShadow: [glowingShadow(context)]),
                  child: AnymeXContainerButton(
                    onTap: onTap,
                    radius: 12,
                    width: 90,
                    height: 38,
                    color: colors.primary,
                    child: AnymeXText(
                      'Read',
                      variant: TextVariant.semiBold,
                      color: colors.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultTile(
    Chapter chapter,
    _ChapterTileData data,
    ColorScheme colors,
    VoidCallback onTap, {
    Widget? downloadButton,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: data.isRead
            ? colors.surfaceContainerHighest.opaque(0.2, iReallyMeanIt: true)
            : colors.surfaceContainerHighest.opaque(0.4, iReallyMeanIt: true),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.onSurface.opaque(0.08, iReallyMeanIt: true),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: data.progressPercentage > 0
            ? SizedBox(
                width: 32,
                height: 32,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: data.progressValue,
                      strokeWidth: 3,
                      backgroundColor: colors.surfaceContainer,
                      color: colors.primary,
                    ),
                    AnymeXText(
                      '${data.progressPercentage}%',
                      size: 9,
                      variant: TextVariant.bold,
                    ),
                  ],
                ),
              )
            : Icon(
                HugeIcons.strokeRoundedBookOpen01,
                color: data.isRead
                    ? colors.onSurface.opaque(0.4, iReallyMeanIt: true)
                    : colors.primary,
                size: 20,
              ),
        title: AnymeXText(
          'Chapter ${chapter.formattedNumber}: ${chapter.title?.isNotEmpty == true ? chapter.title : "Chapter ${chapter.formattedNumber}"}',
          size: 13,
          variant: TextVariant.semiBold,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          color: data.isSelected ? colors.primary : null,
        ),
        subtitle: chapter.scanlator?.isNotEmpty == true
            ? AnymeXText(
                chapter.scanlator!,
                size: 11,
                color: colors.onSurface.opaque(0.5, iReallyMeanIt: true),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (downloadButton != null) ...[
              downloadButton,
              const SizedBox(width: 4),
            ],
            data.isRead
                ? Icon(Icons.check_circle_rounded,
                    color: colors.primary, size: 20)
                : Icon(Icons.circle_outlined,
                    color:
                        colors.onSurface.opaque(0.3, iReallyMeanIt: true),
                    size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildChapterDownloadButton(
    BuildContext context,
    Chapter chapter,
    String extName,
    String mediaTitle, {
    bool isGrid = false,
  }) {
    if (extName.isEmpty || mediaTitle.isEmpty) {
      return const SizedBox.shrink();
    }
    return Obx(() {
      final state = _downloadController.getChapterState(
        extName,
        mediaTitle,
        chapter.number,
      );
      final colors = context.colors;

      if (isGrid) {
        switch (state.status) {
          case DownloadItemStatus.downloaded:
            return Icon(
              Icons.check_circle_rounded,
              color: colors.primary,
              size: 12,
            );
          case DownloadItemStatus.downloading:
            return SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                value: state.progress > 0 ? state.progress : null,
                strokeWidth: 2,
                color: colors.primary,
              ),
            );
          case DownloadItemStatus.queued:
            return Icon(
              Icons.access_time_rounded,
              size: 12,
              color: colors.primary.opaque(0.7),
            );
          case DownloadItemStatus.failed:
            return GestureDetector(
              onTap: () {
                if (state.errorMessage != null &&
                    state.errorMessage!.isNotEmpty) {
                  snackBar('Download failed: ${state.errorMessage}');
                }
                _startMangaDownload(context, [chapter]);
              },
              child: Tooltip(
                message: state.errorMessage != null &&
                        state.errorMessage!.isNotEmpty
                    ? 'Download failed: ${state.errorMessage}. Tap to retry.'
                    : 'Download failed. Tap to retry.',
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 12,
                  color: colors.error,
                ),
              ),
            );
          case DownloadItemStatus.notDownloaded:
            return GestureDetector(
              onTap: () => _startMangaDownload(context, [chapter]),
              child: Icon(
                Icons.download_for_offline_outlined,
                size: 12,
                color: colors.onSurface.opaque(0.4),
              ),
            );
        }
      }

      switch (state.status) {
        case DownloadItemStatus.downloaded:
          return Tooltip(
            message: 'Downloaded',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  snackBar('Chapter ${chapter.formattedNumber} is downloaded');
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colors.primary.opaque(0.15, iReallyMeanIt: true),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colors.primary.opaque(0.35, iReallyMeanIt: true),
                      width: 0.8,
                    ),
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: colors.primary,
                    size: 16,
                  ),
                ),
              ),
            ),
          );
        case DownloadItemStatus.downloading:
          return Tooltip(
            message: 'Downloading (${(state.progress * 100).toInt()}%)',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  if (state.taskId != null) {
                    _downloadController.cancelMangaDownload(state.taskId!);
                  }
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colors.primary.opaque(0.1, iReallyMeanIt: true),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colors.primary.opaque(0.25, iReallyMeanIt: true),
                      width: 0.8,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          value: state.progress > 0 ? state.progress : null,
                          strokeWidth: 2,
                          color: colors.primary,
                        ),
                      ),
                      Icon(
                        Icons.pause_rounded,
                        size: 12,
                        color: colors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        case DownloadItemStatus.queued:
          return Tooltip(
            message: 'Queued for download',
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest
                    .opaque(0.3, iReallyMeanIt: true),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colors.outline.opaque(0.12, iReallyMeanIt: true),
                  width: 0.8,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.8,
                      color: colors.primary.opaque(0.6),
                    ),
                  ),
                  Icon(
                    Icons.access_time_rounded,
                    size: 11,
                    color: colors.primary.opaque(0.6),
                  ),
                ],
              ),
            ),
          );
        case DownloadItemStatus.failed:
          return Tooltip(
            message: state.errorMessage != null &&
                    state.errorMessage!.isNotEmpty
                ? 'Download failed: ${state.errorMessage}. Tap to retry.'
                : 'Download failed. Tap to retry.',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  if (state.errorMessage != null &&
                      state.errorMessage!.isNotEmpty) {
                    snackBar('Download failed: ${state.errorMessage}');
                  }
                  _startMangaDownload(context, [chapter]);
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colors.error.opaque(0.15, iReallyMeanIt: true),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colors.error.opaque(0.35, iReallyMeanIt: true),
                      width: 0.8,
                    ),
                  ),
                  child: Icon(
                    Icons.refresh_rounded,
                    color: colors.error,
                    size: 16,
                  ),
                ),
              ),
            ),
          );
        case DownloadItemStatus.notDownloaded:
          return Tooltip(
            message: 'Download Chapter',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  _startMangaDownload(context, [chapter]);
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest
                        .opaque(0.3, iReallyMeanIt: true),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colors.outline.opaque(0.12, iReallyMeanIt: true),
                      width: 0.8,
                    ),
                  ),
                  child: Icon(
                    Icons.download_rounded,
                    color: colors.onSurface.opaque(0.7),
                    size: 16,
                  ),
                ),
              ),
            ),
          );
      }
    });
  }

  void _startMangaDownload(BuildContext context, List<Chapter> chapters) {
    final isNovel = widget.anilistData?.mediaType == ItemType.novel;
    final activeSrc = isNovel
        ? _sourceController.activeNovelSource.value
        : _sourceController.activeMangaSource.value;
    if (activeSrc == null || widget.anilistData == null) {
      snackBar('No active source or media found');
      return;
    }
    MangaChapterDownloadConfirm.show(
      context,
      chapters: chapters,
      source: activeSrc,
      media: widget.anilistData!.toOfflineMedia(),
    );
  }

  Future<void> _playDownloadedChapter(
    DownloadedChapterMeta ch,
    List<DownloadedChapterMeta> allDownloaded,
  ) async {
    final chapterList = allDownloaded.map((meta) {
      final baseChapter = meta.chapter;
      baseChapter.localPath = meta.imageDir;
      if (baseChapter.link == null || baseChapter.link!.isEmpty) {
        baseChapter.link = meta.imageDir;
      }
      return baseChapter;
    }).toList();

    final currentChapter = ch.chapter;
    currentChapter.localPath = ch.imageDir;
    if (currentChapter.link == null || currentChapter.link!.isEmpty) {
      currentChapter.link = ch.imageDir;
    }

    await navigate(() => ReadingPage(
          anilistData: widget.anilistData!,
          chapterList: chapterList,
          currentChapter: currentChapter,
          shouldTrack: false,
        ));
    _resolveComputedState();
    if (mounted) setState(() {});
  }

  Future<void> _confirmDeleteChapter(
    BuildContext context,
    DownloadedChapterMeta chMeta,
    String extName,
    String mediaTitle,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const AnymeXText('Delete Chapter', variant: TextVariant.bold),
        content: AnymeXText(
            'Are you sure you want to delete Chapter ${chMeta.chapter.formattedNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const AnymeXText('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: AnymeXText('Delete', color: ctx.colors.error),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _downloadController.deleteChapter(
        extName,
        mediaTitle,
        chMeta.chapter.number,
      );
    }
  }

  void _showBatchDownloadSheet(
    BuildContext context, {
    required String extName,
    required String mediaTitle,
    required List<Chapter> filteredChapters,
    required List<Chapter> currentChunkChapters,
  }) {
    final isNovel = widget.anilistData?.mediaType == ItemType.novel;
    final activeSrc = isNovel
        ? _sourceController.activeNovelSource.value
        : _sourceController.activeMangaSource.value;
    if (activeSrc == null || widget.anilistData == null) {
      snackBar('No active source selected');
      return;
    }

    final unread = filteredChapters.where((c) {
      final tileData = _computeTileData(
        chapter: c,
        allChapters: widget.chapterList,
        savedMedia: _savedMedia,
        onlineProgress: _onlineProgress,
        isLoggedInOnline: _isLoggedInOnline,
      );
      final isDownloaded = _downloadController.isChapterDownloaded(
          extName, mediaTitle, c.number);
      return !tileData.isRead && !isDownloaded;
    }).toList();

    final chunkNotDownloaded = currentChunkChapters.where((c) {
      return !_downloadController.isChapterDownloaded(
          extName, mediaTitle, c.number);
    }).toList();

    final allNotDownloaded = filteredChapters.where((c) {
      return !_downloadController.isChapterDownloaded(
          extName, mediaTitle, c.number);
    }).toList();

    final options = <_BatchOption>[
      (
        title: 'Download Unread Chapters',
        subtitle: '${unread.length} chapters',
        icon: Icons.playlist_play_rounded,
        enabled: unread.isNotEmpty,
        onTap: () => _startMangaDownload(context, unread),
      ),
      (
        title: 'Download Current Section',
        subtitle: '${chunkNotDownloaded.length} chapters',
        icon: Icons.view_carousel_outlined,
        enabled: chunkNotDownloaded.isNotEmpty,
        onTap: () => _startMangaDownload(context, chunkNotDownloaded),
      ),
      (
        title: 'Download All Chapters',
        subtitle: '${allNotDownloaded.length} chapters',
        icon: Icons.file_download_outlined,
        enabled: allNotDownloaded.isNotEmpty,
        onTap: () => _startMangaDownload(context, allNotDownloaded),
      ),
    ];

    AnymeXSheet(
      title: 'Batch Download',
      message: mediaTitle,
      showDragHandle: true,
      contentWidget: AnymeXTileBuilder<_BatchOption>(
        items: options,
        isSelection: false,
        isEnabled: (item) => item.enabled,
        getTitle: (item) => item.title,
        getSubtitle: (item) => item.subtitle,
        getIcon: (item) => item.icon,
        showChevron: (item) => item.enabled,
        onItemPressed: (item) {
          if (item.enabled) {
            Navigator.pop(context);
            item.onTap();
          }
        },
      ),
    ).show(context);
  }
}
