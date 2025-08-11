import 'package:anymex/ai/animeo.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/animation/slide_scale.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/common/search_bar.dart';
import 'package:anymex/widgets/header.dart';
import 'package:anymex/widgets/media_items/media_item.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:get/get.dart';

class AIRecommendation extends StatefulWidget {
  const AIRecommendation({super.key, required this.isManga});
  final bool isManga;

  @override
  State<AIRecommendation> createState() => _AIRecommendationState();
}

class _AIRecommendationState extends State<AIRecommendation> {
  RxList<Media> recItems = <Media>[].obs;
  final ScrollController _scrollController = ScrollController();
  int currentPage = 1;
  RxBool isAdult = false.obs;
  TextEditingController textEditingController = TextEditingController();
  RxBool isLoading = false.obs;
  RxBool isGrid = false.obs;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    if (serviceHandler.isLoggedIn.value) {
      fetchAiRecommendations(currentPage);
    }
  }

  void _scrollListener() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !isLoading.value) {
      if (textEditingController.text.isEmpty) {
        fetchAiRecommendations(++currentPage);
      } else {
        fetchAiRecommendations(++currentPage,
            username: textEditingController.text);
      }
    }
  }

  Future<void> fetchAiRecommendations(int page, {String? username}) async {
    if (isLoading.value) return;
    isLoading.value = true;

    try {
      final listData = widget.isManga
          ? Get.find<ServiceHandler>().mangaList
          : Get.find<ServiceHandler>().animeList;
      final existingIds = listData.map((e) => e.id).toSet();
      final data = await getAiRecommendations(widget.isManga, page,
          username: username, isAdult: isAdult.value);

      recItems.addAll(data.where((e) => !existingIds.contains(e.id)));
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Glow(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back_ios_new),
          ),
          title: Obx(() {
            return AnymexText(
              text:
                  "AI Picks ${recItems.isNotEmpty ? '(${recItems.length})' : ''}",
              color: Theme.of(context).colorScheme.primary,
            );
          }),
          actions: [
            IconButton(
                onPressed: () {
                  showSettings();
                },
                icon: const Icon(Icons.settings))
          ],
        ),
        body: Obx(() => recItems.isEmpty
            ? !serviceHandler.isLoggedIn.value
                ? _buildInputBox(context)
                : const Center(child: AnymexProgressIndicator())
            : _buildRecommendations(context)),
      ),
    );
  }

  Column _buildInputBox(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(width: double.infinity),
        SizedBox(
            width: 300,
            child: CustomSearchBar(
              controller: textEditingController,
              onSubmitted: (v) {},
              disableIcons: true,
              hintText: "Enter Username",
            )),
        GestureDetector(
          onTap: () {
            if (textEditingController.text.isNotEmpty) {
              fetchAiRecommendations(1, username: textEditingController.text);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12.multiplyRadius())),
            child: AnymexText(
              text: "Search",
              variant: TextVariant.semiBold,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        )
      ],
    );
  }

  Column _buildRecommendations(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(10),
            controller: _scrollController,
            itemCount: recItems.length + 3,
            itemBuilder: (context, index) {
              final isLastRow = index >= recItems.length;
              final lastRowIndex = index - recItems.length;

              if (isLastRow) {
                if (lastRowIndex == 0 || lastRowIndex == 2) {
                  return const SizedBox.shrink();
                } else if (lastRowIndex == 1) {
                  return Obx(() => isLoading.value
                      ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center(child: AnymexProgressIndicator()),
                        )
                      : const SizedBox.shrink());
                }
              }

              final data = recItems[index];
              return isGrid.value
                  ? GridAnimeCard(data: data, isManga: widget.isManga)
                  : _buildRecItem(data);
            },
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: getResponsiveCrossAxisVal(
                MediaQuery.of(context).size.width,
                itemWidth: isGrid.value ? 120 : 400,
              ),
              crossAxisSpacing: 10,
              mainAxisExtent: isGrid.value ? 250 : 200,
            ),
          ),
        ),
      ],
    );
  }

  void showSettings() {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AnymexText(
                  text: "Settings",
                  variant: TextVariant.bold,
                  size: 20,
                ),
                const SizedBox(height: 20),
                Obx(() {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AnymexText(
                        text: "Grid",
                        variant: TextVariant.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      Switch(
                          value: isGrid.value,
                          onChanged: (v) {
                            isGrid.value = v;
                          })
                    ],
                  );
                }),
                Obx(() {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AnymexText(
                        text: "18+",
                        variant: TextVariant.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      Switch(
                          value: isAdult.value,
                          onChanged: (v) {
                            isAdult.value = v;
                          })
                    ],
                  );
                })
              ],
            ),
          );
        });
  }

  Widget _buildRecItem(Media data) {
    return InkWell(
      onTap: () {
        if (widget.isManga) {
          navigate(() => MangaDetailsPage(media: data, tag: data.description));
        } else {
          navigate(() => AnimeDetailsPage(media: data, tag: data.description));
        }
      },
      child: SlideAndScaleAnimation(
          child: Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .secondaryContainer
                .withOpacity(0.5),
            borderRadius: BorderRadius.circular(12.multiplyRoundness())),
        child: Row(
          children: [
            Hero(
              tag: data.description,
              child: NetworkSizedImage(
                radius: 12.multiplyRoundness(),
                imageUrl: data.poster,
                width: 120,
                height: 170,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnymexText(
                    text: data.title,
                    variant: TextVariant.semiBold,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Flexible(
                    child: AnymexText(
                      text: data.description,
                      color: Colors.grey[300],
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: data.genres
                        .take(3)
                        .map((e) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius:
                                    BorderRadius.circular(8.multiplyRadius()),
                              ),
                              child: AnymexText(
                                text: e,
                                variant: TextVariant.semiBold,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      )),
    );
  }
}
