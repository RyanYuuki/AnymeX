import 'package:anymex/api/Mangayomi/Eval/dart/model/m_chapter.dart';
import 'package:anymex/api/Mangayomi/Model/Source.dart';
import 'package:anymex/pages/Manga/read_page.dart';
import 'package:anymex/utils/methods.dart';
import 'package:flutter/material.dart';
import 'package:text_scroll/text_scroll.dart';

class ChapterList extends StatelessWidget {
  final List<MChapter> chaptersData;
  final String? id;
  final String? posterUrl;
  final String anilistId;
  final Source currentSource;
  final dynamic rawChapters;
  final String description;
  final String mangaTitle;
  const ChapterList(
      {super.key,
      required this.chaptersData,
      required this.id,
      required this.posterUrl,
      required this.currentSource,
      required this.anilistId,
      required this.rawChapters,
      required this.description,
      required this.mangaTitle});

  @override
  Widget build(BuildContext context) {
    if (chaptersData == null) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return SizedBox(
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: chaptersData.length,
        shrinkWrap: true,
        itemBuilder: (context, index) {
          final manga = chaptersData[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            width: MediaQuery.of(context).size.width,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 140,
                      child: TextScroll(
                        manga.name ?? '?',
                        mode: TextScrollMode.endless,
                        velocity:
                            const Velocity(pixelsPerSecond: Offset(30, 0)),
                        delayBefore: const Duration(milliseconds: 500),
                        pauseBetween: const Duration(milliseconds: 1000),
                        textAlign: TextAlign.center,
                        selectable: true,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      manga.scanlator ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ReadingPage(
                                  id: manga,
                                  mangaId: id ?? '',
                                  posterUrl: posterUrl!,
                                  currentSource: currentSource,
                                  anilistId: anilistId,
                                  chapterList: rawChapters,
                                  description: description,
                                  mangaTitle: mangaTitle,
                                )));
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    backgroundColor:
                        Theme.of(context).colorScheme.secondaryContainer,
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Read',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.inverseSurface ==
                              Theme.of(context)
                                  .colorScheme
                                  .onPrimaryFixedVariant
                          ? Colors.black
                          : Theme.of(context)
                                      .colorScheme
                                      .onPrimaryFixedVariant ==
                                  const Color(0xffe2e2e2)
                              ? Colors.black
                              : Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
