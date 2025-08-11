import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Offline/Hive/chapter.dart';
import 'package:anymex/screens/manga/reading_page.dart';
import 'package:anymex/screens/manga/widgets/chapter_ranges.dart';
import 'package:anymex/screens/manga/widgets/scanlators_ranges.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/string_extensions.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/anymex_button.dart';
import 'package:anymex/widgets/header.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:get/get.dart';

class ChapterState {
  final int? userProgress;
  final Chapter? readChapter;
  final Chapter? continueChapter;
  final List<String> scanlators;
  final List<List<Chapter>> chunkedChapters;

  const ChapterState({
    this.userProgress,
    this.readChapter,
    this.continueChapter,
    required this.scanlators,
    required this.chunkedChapters,
  });
}

class ChapterService {
  final ServiceHandler _auth = Get.find<ServiceHandler>();
  final OfflineStorageController _offlineStorage =
      Get.find<OfflineStorageController>();

  List<String> extractScanlators(List<Chapter> chapters) {
    final scanlators = <String>{};
    for (final chapter in chapters) {
      if (chapter.scanlator?.isNotEmpty ?? false) {
        scanlators.add(chapter.scanlator!);
      }
    }
    return scanlators.toList();
  }

  ChapterState buildChapterState(
    List<Chapter> chapters,
    Media anilistData, {
    List<String>? scanlators,
    int? selectedScanIndex,
  }) {
    final extractedScanlators = scanlators ?? extractScanlators(chapters);

    final chaptersForChunking =
        (selectedScanIndex != null && selectedScanIndex > 0)
            ? filterChaptersByScanlator(
                chapters, extractedScanlators, selectedScanIndex)
            : chapters;

    final chunkedChapters = chaptersForChunking.isNotEmpty
        ? chunkChapter(
            chaptersForChunking, calculateChapterChunkSize(chaptersForChunking))
        : <List<Chapter>>[];

    final userProgress = _getUserProgress(anilistData);
    final readChapter =
        _offlineStorage.getReadChapter(anilistData.id, userProgress.toDouble());
    final continueChapter =
        _findContinueChapter(chapters, userProgress, readChapter);

    return ChapterState(
      userProgress: userProgress,
      readChapter: readChapter,
      continueChapter: continueChapter,
      scanlators: extractedScanlators,
      chunkedChapters: chunkedChapters,
    );
  }

  int _getUserProgress(Media anilistData) {
    if (_auth.isLoggedIn.value &&
        _auth.serviceType.value != ServicesType.extensions) {
      final temp = _auth.onlineService.mangaList
          .firstWhereOrNull((e) => e.id == anilistData.id);
      return temp?.episodeCount?.toInt() ?? 1;
    } else {
      return _offlineStorage
              .getMangaById(anilistData.id)
              ?.currentChapter
              ?.number
              ?.toInt() ??
          1;
    }
  }

  List<List<Chapter>> buildFilteredChunks(
    List<Chapter> chapters,
    List<String> scanlators,
    int selectedScanIndex,
  ) {
    final filteredChapters = filterChaptersByScanlator(
      chapters,
      scanlators,
      selectedScanIndex,
    );

    if (filteredChapters.isEmpty) {
      return [];
    }

    return chunkChapter(
        filteredChapters, calculateChapterChunkSize(filteredChapters));
  }

  Chapter? _findContinueChapter(
      List<Chapter> chapters, int userProgress, Chapter? readChapter) {
    if (_auth.isLoggedIn.value &&
        _auth.serviceType.value != ServicesType.extensions) {
      final candidate =
          chapters.firstWhereOrNull((e) => e.number?.toInt() == userProgress);

      return candidate;
    } else {
      return chapters.firstWhere(
        (e) => e.number?.toInt() == userProgress,
        orElse: () => readChapter ?? chapters.first,
      );
    }
  }

  List<Chapter> filterChaptersByScanlator(
    List<Chapter> chapters,
    List<String> scanlators,
    int selectedScanIndex,
  ) {
    if (selectedScanIndex == 0 || scanlators.isEmpty) {
      return chapters;
    }
    return chapters
        .where(
            (chapter) => chapter.scanlator == scanlators[selectedScanIndex - 1])
        .toList();
  }

  void navigateToReading(
      Media anilistData, List<Chapter> chapterList, Chapter currentChapter) {
    navigate(() => ReadingPage(
          anilistData: anilistData,
          chapterList: chapterList,
          currentChapter: currentChapter,
        ));
  }
}

class ChapterListBuilder extends StatefulWidget {
  final List<Chapter>? chapters;
  final Media anilistData;

  const ChapterListBuilder({
    super.key,
    required this.chapters,
    required this.anilistData,
  });

  @override
  State<ChapterListBuilder> createState() => _ChapterListBuilderState();
}

class _ChapterListBuilderState extends State<ChapterListBuilder> {
  final _selectedChunkIndex = 1.obs;
  final _selectedScanIndex = 0.obs;
  final _chapterService = ChapterService();

  final _isInitialized = false.obs;

  late final ServiceHandler _auth;
  late final OfflineStorageController _offlineStorage;

  @override
  void initState() {
    super.initState();
    _auth = Get.find<ServiceHandler>();
    _offlineStorage = Get.find<OfflineStorageController>();
    _initializeChapterState();
  }

  void _initializeChapterState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && (widget.chapters?.isNotEmpty ?? false)) {
        setState(() {
          _isInitialized.value = true;
          _setInitialSelectedIndices();
        });
      }
    });
  }

  void _onScanIndex() {
    _selectedChunkIndex.value = 1;

    if (mounted) {
      setState(() {});
    }
  }

  void _setInitialSelectedIndices() {
    final chapterState = _chapterService.buildChapterState(
      widget.chapters!,
      widget.anilistData,
      selectedScanIndex: _selectedScanIndex.value,
    );

    final progress = chapterState.continueChapter?.number;
    if (progress != null && chapterState.chunkedChapters.isNotEmpty) {
      List<List<int>> ranges = [];
      final newList =
          chapterState.chunkedChapters.map((e) => e.toList()).toList();
      if (newList.isNotEmpty) {
        newList.removeAt(0);
      }

      for (var e in newList) {
        if (e.isNotEmpty && e.first.number != null && e.last.number != null) {
          ranges.add([e.first.number!.toInt(), e.last.number!.toInt()]);
        }
      }

      final chunkIndex =
          ranges.indexWhere((e) => progress >= e[0] && progress <= e[1]) + 1;
      if (chunkIndex > 0) {
        _selectedChunkIndex.value = chunkIndex;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if ((widget.chapters?.isEmpty ?? true) || !_isInitialized.value) {
      return const SizedBox(
        height: 500,
        child: Center(child: AnymexProgressIndicator()),
      );
    }

    return Obx(() {
      _auth.currentMedia.value;
      _offlineStorage.mangaLibrary.value;

      return _buildChapterList();
    });
  }

  Widget _buildChapterList() {
    final chapterState = _chapterService.buildChapterState(
      widget.chapters!,
      widget.anilistData,
      selectedScanIndex: _selectedScanIndex.value,
    );

    final selectedChapters = _getSelectedChapters(chapterState);
    final filteredFullChapters = _chapterService.filterChaptersByScanlator(
      widget.chapters!,
      chapterState.scanlators,
      _selectedScanIndex.value,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildContinueButton(filteredFullChapters, chapterState),
        _buildScanlatorsFilter(chapterState),
        _buildChapterRanges(chapterState),
        _buildChapterGrid(selectedChapters, filteredFullChapters, chapterState),
      ],
    );
  }

  Widget _buildScanlatorsFilter(ChapterState chapterState) {
    if (chapterState.scanlators.isEmpty) {
      return const SizedBox.shrink();
    }

    return ScanlatorsRanges(
      selectedScanIndex: _selectedScanIndex,
      scanlators: chapterState.scanlators,
      onScanIndexChanged: _onScanIndex,
    );
  }

  List<Chapter> _getSelectedChapters(ChapterState chapterState) {
    if (chapterState.chunkedChapters.isEmpty) return [];

    final index = _selectedChunkIndex.value
        .clamp(0, chapterState.chunkedChapters.length - 1);

    if (index >= chapterState.chunkedChapters.length) {
      _selectedChunkIndex.value = 1;
      return chapterState.chunkedChapters.isNotEmpty
          ? chapterState.chunkedChapters[0]
          : [];
    }

    return chapterState.chunkedChapters[index];
  }

  Widget _buildContinueButton(
      List<Chapter> filteredFullChapters, ChapterState chapterState) {
    final continueChapter =
        chapterState.readChapter ?? chapterState.continueChapter;
    if (continueChapter == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: ContinueChapterButton(
        onPressed: () => _chapterService.navigateToReading(
          widget.anilistData,
          widget.chapters!,
          continueChapter,
        ),
        height: getResponsiveSize(context, mobileSize: 80, desktopSize: 100),
        backgroundImage: widget.anilistData.cover ?? widget.anilistData.poster,
        chapter: continueChapter,
      ),
    );
  }

  Widget _buildChapterRanges(ChapterState chapterState) {
    return ChapterRanges(
      selectedChunkIndex: _selectedChunkIndex,
      onChunkSelected: (val) => _selectedChunkIndex.value = val,
      chunks: chapterState.chunkedChapters,
    );
  }

  Widget _buildChapterGrid(List<Chapter> filteredChapters,
      List<Chapter> filteredFullChapters, ChapterState chapterState) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredChapters.length,
      padding: const EdgeInsets.only(top: 10),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: getResponsiveCrossAxisCount(
          context,
          baseColumns: 1,
          maxColumns: 3,
          mobileItemWidth: 400,
          tabletItemWidth: 500,
          desktopItemWidth: 500,
        ),
        mainAxisExtent: 100,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
      ),
      itemBuilder: (context, index) => _buildChapterItem(
        filteredChapters[index],
        filteredFullChapters,
        chapterState,
      ),
    );
  }

  Widget _buildChapterItem(Chapter chapter, List<Chapter> filteredFullChapters,
      ChapterState chapterState) {
    return ChapterListItem(
      chapter: chapter,
      anilistData: widget.anilistData,
      readChapter: chapterState.readChapter,
      continueChapter: chapterState.continueChapter,
      onTap: () => _chapterService.navigateToReading(
        widget.anilistData,
        filteredFullChapters,
        chapter,
      ),
    );
  }
}

class ChapterListItem extends StatelessWidget {
  final Chapter chapter;
  final Media anilistData;
  final Chapter? readChapter;
  final Chapter? continueChapter;
  final VoidCallback onTap;

  const ChapterListItem({
    super.key,
    required this.chapter,
    required this.anilistData,
    this.readChapter,
    this.continueChapter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final offlineStorage = Get.find<OfflineStorageController>();
    final savedChaps =
        offlineStorage.getReadChapter(anilistData.id, chapter.number!);
    final currentChapterLink = readChapter?.link ?? continueChapter?.link ?? '';
    final isSelected = chapter.link == currentChapterLink;
    final alreadyRead = chapter.number! < (readChapter?.number ?? 1) ||
        ((savedChaps?.pageNumber ?? 1) == (savedChaps?.totalPages ?? 100));

    return AnymexOnTap(
      onTap: onTap,
      child: Opacity(
        opacity: alreadyRead ? 0.5 : 1,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.secondary.withAlpha(100)
                : Theme.of(context)
                    .colorScheme
                    .secondaryContainer
                    .withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildChapterProgress(context, savedChaps ?? Chapter()),
              const SizedBox(width: 15),
              _buildChapterInfo(context, savedChaps),
              const Spacer(),
              _buildReadButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChapterProgress(BuildContext context, Chapter savedChap) {
    final totalPages = savedChap.totalPages ?? 1;
    final currentPage = savedChap.pageNumber ?? 0;
    final progress =
        totalPages > 0 ? (currentPage / totalPages).clamp(0.0, 1.0) : 0.0;
    final progressPercentage = (progress * 100).toInt();

    if (progressPercentage > 0) {
      return _buildReadChapter(context, savedChap);
    }

    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(16.multiplyRadius()),
        boxShadow: [glowingShadow(context)],
      ),
      child: AnymexText(
        text: chapter.number?.toStringAsFixed(0) ?? '',
        variant: TextVariant.bold,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildReadChapter(BuildContext context, Chapter chapter) {
    final totalPages = chapter.totalPages ?? 1;
    final currentPage = chapter.pageNumber ?? 0;
    final progress =
        totalPages > 0 ? (currentPage / totalPages).clamp(0.0, 1.0) : 0.0;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.multiplyRadius()),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
          SizedBox(
            width: 40,
            height: 40,
            child: AnymexProgressIndicator(
              value: progress,
              strokeWidth: 4,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterInfo(BuildContext context, Chapter? savedChaps) {
    final progressText = savedChaps?.pageNumber != null
        ? ' (${savedChaps?.pageNumber}/${savedChaps?.totalPages})'
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: getResponsiveSize(context,
              mobileSize: Get.width * 0.4, desktopSize: 200),
          child: AnymexText(
            text: '${chapter.title}$progressText',
            variant: TextVariant.semiBold,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 5),
        SizedBox(
          width: getResponsiveSize(context,
              mobileSize: Get.width * 0.4, desktopSize: 200),
          child: AnymexText(
            text:
                '${chapter.releaseDate} • ${Get.find<SourceController>().activeMangaSource.value!.name}',
            color:
                Theme.of(context).colorScheme.inverseSurface.withOpacity(0.9),
            fontStyle: FontStyle.italic,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildReadButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(boxShadow: [glowingShadow(context)]),
      child: AnymexButton(
        onTap: onTap,
        radius: 12,
        width: 100,
        height: 40,
        color: Theme.of(context).colorScheme.primary,
        child: AnymexText(
          text: "Read",
          variant: TextVariant.semiBold,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }
}

class ContinueChapterButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String backgroundImage;
  final double height;
  final double borderRadius;
  final Color textColor;
  final TextStyle? textStyle;
  final Chapter chapter;

  const ContinueChapterButton({
    super.key,
    required this.onPressed,
    required this.backgroundImage,
    this.height = 60,
    this.borderRadius = 18,
    this.textColor = Colors.white,
    this.textStyle,
    required this.chapter,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final progressPercentage = _calculateProgressPercentage();

        return Container(
          width: double.infinity,
          height: height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              width: 1,
              color:
                  Theme.of(context).colorScheme.inverseSurface.withOpacity(0.3),
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              _buildBackgroundImage(),
              _buildOverlay(context),
              _buildContent(context),
              if (progressPercentage > 0)
                _buildProgressBar(context, constraints, progressPercentage),
            ],
          ),
        );
      },
    );
  }

  double _calculateProgressPercentage() {
    if (chapter.pageNumber == null ||
        chapter.totalPages == null ||
        chapter.totalPages! <= 0 ||
        chapter.pageNumber! <= 0) {
      return 0.0;
    }
    return (chapter.pageNumber! / chapter.totalPages!).clamp(0.0, 0.99);
  }

  Widget _buildBackgroundImage() {
    return Positioned.fill(
      child: NetworkSizedImage(
        radius: borderRadius,
        height: height,
        width: double.infinity,
        imageUrl: backgroundImage,
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    return Positioned.fill(
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black.withOpacity(0.5),
              Colors.black.withOpacity(0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Positioned.fill(
      child: AnymexButton(
        onTap: onPressed,
        padding: EdgeInsets.zero,
        width: Get.width * 0.8,
        height: height,
        color: Colors.transparent,
        radius: borderRadius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Continue: ${chapter.title}'.toUpperCase(),
              style: textStyle ??
                  TextStyle(
                    color: textColor,
                    fontFamily: 'Poppins-SemiBold',
                  ),
            ),
            const SizedBox(height: 3),
            Container(
              color: Theme.of(context).colorScheme.primary,
              height: 2,
              width: 6 *
                  'Chapter ${chapter.number}: ${chapter.title}'
                      .length
                      .toDouble(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, BoxConstraints constraints,
      double progressPercentage) {
    return Positioned(
      height: 2,
      bottom: 0,
      left: 0,
      child: Container(
        height: 4,
        width: constraints.maxWidth * progressPercentage,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }
}
