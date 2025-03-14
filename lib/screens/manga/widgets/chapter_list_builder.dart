import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Offline/Hive/chapter.dart';
import 'package:anymex/screens/manga/reading_page.dart';
import 'package:anymex/screens/manga/widgets/chapter_ranges.dart';
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

class ChapterListBuilder extends StatefulWidget {
  final List<Chapter>? chapters;
  final Media anilistData;
  const ChapterListBuilder(
      {super.key, required this.chapters, required this.anilistData});

  @override
  State<ChapterListBuilder> createState() => _ChapterListBuilderState();
}

class _ChapterListBuilderState extends State<ChapterListBuilder> {
  final selectedChunkIndex = 1.obs;
  final auth = Get.find<ServiceHandler>();
  final offlineStorage = Get.find<OfflineStorageController>();
  int? userProgress;
  Chapter? readChap;
  Chapter? continueChapter;

  @override
  Widget build(BuildContext context) {
    if (widget.chapters == null || widget.chapters!.isEmpty) {
      return const SizedBox(
          height: 500, child: Center(child: AnymexProgressIndicator()));
    }
    return Obx(() {
      final chunkedChapters = chunkChapter(
          widget.chapters!, calculateChapterChunkSize(widget.chapters!));
      final selectedChapters = chunkedChapters.isNotEmpty
          ? chunkedChapters[selectedChunkIndex.value].obs
          : [].obs;

      if (auth.isLoggedIn.value &&
          auth.serviceType.value != ServicesType.extensions) {
        final temp = auth.onlineService.mangaList
            .firstWhereOrNull((e) => e.id == widget.anilistData.id);
        userProgress = temp?.episodeCount?.toInt() ?? 0;
        readChap = offlineStorage.getReadChapter(
            widget.anilistData.id, userProgress?.toDouble() ?? 1);
        continueChapter = widget.chapters?.firstWhereOrNull(
          (e) => e.number?.toInt() == userProgress,
        );
      } else {
        userProgress = offlineStorage
                .getMangaById(widget.anilistData.id)
                ?.currentChapter
                ?.number
                ?.toInt() ??
            1;
        readChap = offlineStorage.getReadChapter(
            widget.anilistData.id, userProgress!.toDouble());
        continueChapter = widget.chapters?.firstWhere(
            (e) => e.number?.toInt() == userProgress,
            orElse: () => readChap ?? widget.chapters![0]);
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((readChap ?? continueChapter) != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: ContinueChapterButton(
                  onPressed: () {
                    navigate(() => ReadingPage(
                          anilistData: widget.anilistData,
                          chapterList: widget.chapters!,
                          currentChapter: continueChapter!,
                        ));
                  },
                  height: getResponsiveSize(context,
                      mobileSize: 80, dektopSize: 100),
                  backgroundImage:
                      widget.anilistData.cover ?? widget.anilistData.poster,
                  chapter: readChap ?? continueChapter!),
            ),
          ChapterRanges(
              selectedChunkIndex: selectedChunkIndex,
              onChunkSelected: (val) {
                selectedChunkIndex.value = val;
              },
              chunks: chunkedChapters),
          GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: selectedChapters.length,
              padding: const EdgeInsets.only(top: 10),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: getResponsiveCrossAxisCount(context,
                      baseColumns: 1,
                      maxColumns: 3,
                      mobileItemWidth: 400,
                      tabletItemWidth: 500,
                      desktopItemWidth: 500),
                  mainAxisExtent: 100,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15),
              itemBuilder: (context, index) {
                final chapter = selectedChapters[index] as Chapter;
                final savedChaps = offlineStorage.getReadChapter(
                    widget.anilistData.id, chapter.number!);
                final isSelected = chapter.number ==
                    (readChap?.number ?? continueChapter?.number);
                final alreadyRead = chapter.number! <
                    (readChap?.number ?? continueChapter?.number ?? 0);
                return TVWrapper(
                  onTap: () {
                    navigate(() => ReadingPage(
                          anilistData: widget.anilistData,
                          chapterList: widget.chapters!,
                          currentChapter: chapter,
                        ));
                  },
                  child: Opacity(
                    opacity: alreadyRead ? 0.5 : 1,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context)
                                .colorScheme
                                .secondary
                                .withAlpha(100)
                            : Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius:
                                    BorderRadius.circular(16.multiplyRadius()),
                                boxShadow: [glowingShadow(context)]),
                            child: AnymexText(
                              text: chapter.number?.toStringAsFixed(0) ?? '',
                              variant: TextVariant.bold,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: getResponsiveSize(context,
                                    mobileSize: Get.width * 0.4,
                                    dektopSize: 200),
                                child: AnymexText(
                                  text:
                                      '${chapter.title} ${savedChaps?.pageNumber != null ? '(${savedChaps?.pageNumber}/${savedChaps?.totalPages})' : ''}',
                                  variant: TextVariant.semiBold,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 5),
                              SizedBox(
                                width: getResponsiveSize(context,
                                    mobileSize: Get.width * 0.4,
                                    dektopSize: 200),
                                child: AnymexText(
                                  text:
                                      '${chapter.releaseDate} • ${Get.find<SourceController>().activeMangaSource.value!.name}',
                                  color: Theme.of(context)
                                      .colorScheme
                                      .inverseSurface
                                      .withOpacity(0.9),
                                  fontStyle: FontStyle.italic,
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            decoration: BoxDecoration(
                                boxShadow: [glowingShadow(context)]),
                            child: AnymexButton(
                              onTap: () {
                                navigate(() => ReadingPage(
                                      anilistData: widget.anilistData,
                                      chapterList: widget.chapters!,
                                      currentChapter: chapter,
                                    ));
                              },
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
                          )
                        ],
                      ),
                    ),
                  ),
                );
              }),
        ],
      );
    });
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
        final double progressPercentage;
        if (chapter.pageNumber == null ||
            chapter.totalPages == null ||
            chapter.totalPages! <= 0 ||
            chapter.pageNumber! <= 0) {
          progressPercentage = 0.0;
        } else {
          progressPercentage =
              (chapter.pageNumber! / chapter.totalPages!).clamp(0.0, 0.99);
        }

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
              Positioned.fill(
                child: NetworkSizedImage(
                  radius: borderRadius,
                  height: height,
                  width: double.infinity,
                  imageUrl: backgroundImage,
                ),
              ),
              Positioned.fill(
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Colors.black.withOpacity(0.5),
                      Colors.black.withOpacity(0.5),
                    ]),
                    borderRadius: BorderRadius.circular(borderRadius),
                  ),
                ),
              ),
              Positioned.fill(
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
                      )
                    ],
                  ),
                ),
              ),
              if (progressPercentage > 0)
                Positioned(
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
                ),
            ],
          ),
        );
      },
    );
  }
}
