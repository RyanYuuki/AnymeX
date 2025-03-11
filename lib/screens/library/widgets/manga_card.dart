import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/models/Offline/Hive/offline_media.dart';
import 'package:anymex/screens/manga/reading_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/header.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:blur/blur.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MangaHistoryCard extends StatelessWidget {
  final OfflineMedia data;

  const MangaHistoryCard({super.key, required this.data});

  String _formatEpisodeNumber() {
    final episode = data.currentChapter;
    if (episode == null) return 'Chapter ??';
    return 'Chapter ${episode.number}';
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = [
      Theme.of(context).colorScheme.surface.withOpacity(0.3),
      Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      Theme.of(context).colorScheme.primaryContainer.withOpacity(0.8),
    ];

    return Container(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border(
            right: BorderSide(
                width: 2, color: Theme.of(context).colorScheme.primary)),
        borderRadius: BorderRadius.circular(12.multiplyRadius()),
        color: Theme.of(context).colorScheme.surface.withAlpha(144),
      ),
      child: TVWrapper(
        onTap: () {
          if (data.currentChapter == null) {
            snackBar(
                "Error: Missing required data. It seems you closed the app directly after reading the chapter!",
                maxLines: 3);
          } else {
            if (data.currentChapter?.sourceName == null) {
              snackBar("Cant Play since user closed the app abruptly");
            }
            final source = Get.find<SourceController>()
                .getMangaExtensionByName(data.currentChapter!.sourceName!);
            if (source == null) {
              snackBar(
                  "Install ${data.currentChapter?.sourceName} First, Then Click");
            } else {
              navigate(() => ReadingPage(
                    anilistData: convertOfflineToMedia(data),
                    chapterList: data.chapters!,
                    currentChapter: data.currentChapter!,
                  ));
            }
          }
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.multiplyRadius()),
          child: Stack(children: [
            // Background image
            Positioned.fill(
              child: NetworkSizedImage(
                imageUrl: data.cover ?? data.poster!,
                radius: 0,
                width: double.infinity,
              ),
            ),
            Positioned.fill(
              child: Blur(
                blur: 4,
                blurColor: Colors.transparent,
                child: Container(),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: gradientColors)),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NetworkSizedImage(
                  width: getResponsiveSize(context,
                      mobileSize: 100, dektopSize: 130),
                  height: getResponsiveSize(context,
                      mobileSize: 130, dektopSize: 180),
                  radius: 0,
                  imageUrl: data.poster!,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                            height: getResponsiveSize(context,
                                mobileSize: 05, dektopSize: 30)),
                        AnymexText(
                          text: _formatEpisodeNumber().toUpperCase(),
                          size: getResponsiveSize(context,
                              mobileSize: 18, dektopSize: 20),
                          variant: TextVariant.bold,
                          maxLines: 1,
                          color: Theme.of(context).colorScheme.primary,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        AnymexText(
                          text: data.currentChapter?.title ?? '??',
                          size: 14,
                          maxLines: 2,
                          variant: TextVariant.bold,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              right: 10,
              bottom: 10,
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular((8.multiplyRadius())),
                      color: Theme.of(context).colorScheme.primaryContainer,
                    ),
                    child: AnymexText(
                      text:
                          formatTimeAgo(data.currentChapter?.lastReadTime ?? 0),
                      size: 12,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      variant: TextVariant.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular((8.multiplyRadius())),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    child: AnymexText(
                      text:
                          'PAGE ${data.currentChapter?.pageNumber} / ${data.currentChapter?.totalPages}',
                      size: 12,
                      color: Theme.of(context).colorScheme.onPrimary,
                      variant: TextVariant.bold,
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
