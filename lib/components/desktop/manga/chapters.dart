import 'package:anymex/pages/Android/user/anilist_pages/manga_list.dart';
import 'package:flutter/material.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:anymex/pages/Android/Manga/read_page.dart';

class DesktopChapterList extends StatelessWidget {
  final List<dynamic> chaptersData;
  final String? id;
  final String? posterUrl;
  final String anilistId;
  final String currentSource;
  final dynamic rawChapters;
  final String description;

  const DesktopChapterList({
    super.key,
    required this.chaptersData,
    required this.id,
    required this.posterUrl,
    required this.currentSource,
    required this.anilistId,
    required this.rawChapters,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    if (chaptersData.isEmpty) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    int getResponsiveCrossAxisCount(double screenWidth, {int itemWidth = 300}) {
      return (screenWidth / itemWidth).floor().clamp(1, 3);
    }

    return SizedBox(
      height: 500,
      child: GridView.builder(
        itemCount: chaptersData.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: getResponsiveCrossAxisCount(
              MediaQuery.of(context).size.width,
            ),
            mainAxisExtent: 90,
            crossAxisSpacing: 10),
        shrinkWrap: true,
        itemBuilder: (BuildContext context, int index) {
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 140,
                      child: TextScroll(
                        manga['title'] ?? '?',
                        mode: TextScrollMode.endless,
                        velocity:
                            const Velocity(pixelsPerSecond: Offset(30, 0)),
                        delayBefore: const Duration(milliseconds: 500),
                        pauseBetween: const Duration(milliseconds: 1000),
                        textAlign: TextAlign.start,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      manga['date']?.toString() ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.whatshot,
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      manga['views']?.toString() ?? '??',
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 15),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReadingPage(
                              id: manga['id'],
                              mangaId: id!,
                              posterUrl: posterUrl!,
                              currentSource: currentSource,
                              anilistId: anilistId,
                              chapterList: rawChapters,
                              description: description,
                            ),
                          ),
                        );
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
                      child: const Text(
                        'Read',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
