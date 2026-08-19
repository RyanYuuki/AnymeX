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
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/screens/manga/widgets/track_dialog.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/controllers/track/track_binding_controller.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';


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
  final savedChap =
      readChaptersList.firstWhereOrNull((c) => c.number == chapter.number) ??
          chapter;

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
    continueChapter = allChapters.firstWhereOrNull(
      (c) =>
          (c.link != null && c.link == lastRead.link) ||
          c.number == lastRead.number,
    );
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

  const ChapterListBuilder({
    super.key,
    required this.chapterList,
    required this.anilistData,
  });

  @override
  State<ChapterListBuilder> createState() => _ChapterListBuilderState();
}

class _ChapterListBuilderState extends State<ChapterListBuilder> {
  final RxInt selectedChunkIndex = 0.obs;
  final RxInt selectedScanlatorIndex = 0.obs;
  final _offlineStorage = Get.find<OfflineStorageController>();
  final _auth = Get.find<ServiceHandler>();
  final _sourceController = Get.find<SourceController>();

  OfflineMedia? _savedMedia;
  int _onlineProgress = 0;
  bool _isLoggedInOnline = false;
  VoidCallback? _offlineStorageListener;

  @override
  void initState() {
    super.initState();
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

      await navigate(() => ReadingPage(
            anilistData: mediaData,
            chapterList: widget.chapterList,
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
          if (scanlatorsList.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ScanlatorsRanges(
                  scanlators: scanlatorsList,
                  selectedScanIndex: selectedScanlatorIndex,
                  onScanIndexChanged: () {
                    selectedChunkIndex.value = 0;
                  },
                ),
              ),
            ),
          if (chunks.length > 1)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ChapterRanges(
                  chunks: chunks,
                  selectedChunkIndex: selectedChunkIndex,
                  onChunkSelected: (index) =>
                      selectedChunkIndex.value = index,
                ),
              ),
            ),
          if (settings.chapterStyle == 'grid')
            SliverGrid.builder(
              gridDelegate:
                  const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 80,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                mainAxisExtent: 45,
              ),
              itemCount: currentChapters.length,
              itemBuilder: (context, index) {
                return _buildTile(context, currentChapters[index], settings);
              },
            )
          else
            SliverList.builder(
              itemCount: currentChapters.length,
              itemBuilder: (context, index) {
                return _buildTile(context, currentChapters[index], settings);
              },
            ),
        ],
      );
    });
  }

  Widget _buildTile(BuildContext context, Chapter chapter, Settings settings) {
    final colors = context.colors;

    final data = _computeTileData(
      chapter: chapter,
      allChapters: widget.chapterList,
      savedMedia: _savedMedia,
      onlineProgress: _onlineProgress,
      isLoggedInOnline: _isLoggedInOnline,
    );

    void onTap() => _onTap(chapter);

    if (settings.chapterStyle == 'compact') {
      return _buildCompactTile(context, chapter, data, colors, onTap);
    }
    if (settings.chapterStyle == 'grid') {
      return _buildGridTile(chapter, data, colors, onTap);
    }
    if (settings.chapterStyle == 'detailed') {
      return _buildDetailedTile(context, chapter, data, colors, onTap);
    }
    return _buildDefaultTile(chapter, data, colors, onTap);
  }

  Widget _buildCompactTile(
    BuildContext context,
    Chapter chapter,
    _ChapterTileData data,
    ColorScheme colors,
    VoidCallback onTap,
  ) {
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
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: data.isSelected
                        ? colors.primary
                        : colors.primaryContainer
                            .opaque(0.3, iReallyMeanIt: true),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: AnymeXText(chNum,
                    size: 13,
                    variant: TextVariant.bold,
                    color: data.isSelected
                        ? colors.onPrimary
                        : colors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnymeXText(chTitle,
                        size: 13,
                        variant: TextVariant.semiBold,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (chapter.scanlator?.isNotEmpty == true) ...[
                        const SizedBox(height: 2),
                        AnymeXText(chapter.scanlator!,
                          size: 10,
                          color: colors.onSurface
                              .opaque(0.6, iReallyMeanIt: true),
                        ),
                      ],
                    ],
                  ),
                ),
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
    VoidCallback onTap,
  ) {
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
          child: AnymeXText(chapter.formattedNumber,
            variant: TextVariant.bold,
            size: 13,
            color: data.isSelected ? colors.onPrimary : colors.onSurface,
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
    VoidCallback onTap,
  ) {
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
                        AnymeXText('${data.progressPercentage}%',
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
                    child: AnymeXText(chapter.formattedNumber,
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
                      AnymeXText('${chapter.title}$progressText',
                        variant: TextVariant.semiBold,
                        size: 13,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      AnymeXText(chapterMetaText,
                        size: 11,
                        color: colors.inverseSurface.opaque(0.7),
                        fontStyle: FontStyle.italic,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
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
                    child: AnymeXText('Read',
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
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: data.isRead
            ? colors.surfaceContainerHighest.opaque(0.2, iReallyMeanIt: true)
            : colors.surfaceContainerHighest
                .opaque(0.4, iReallyMeanIt: true),
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
                    AnymeXText('${data.progressPercentage}%',
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
        title: AnymeXText('Chapter ${chapter.formattedNumber}: ${chapter.title?.isNotEmpty == true ? chapter.title : "Chapter ${chapter.formattedNumber}"}',
          size: 13,
          variant: TextVariant.semiBold,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          color: data.isSelected ? colors.primary : null,
        ),
        subtitle: chapter.scanlator?.isNotEmpty == true
            ? AnymeXText(chapter.scanlator!,
                size: 11,
                color:
                    colors.onSurface.opaque(0.5, iReallyMeanIt: true),
              )
            : null,
        trailing: data.isRead
            ? Icon(Icons.check_circle_rounded,
                color: colors.primary, size: 20)
            : Icon(Icons.circle_outlined,
                color:
                    colors.onSurface.opaque(0.3, iReallyMeanIt: true),
                size: 20),
      ),
    );
  }
}
