import 'package:anymex/api/animeo.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/animation/slide_scale.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/header.dart';
import 'package:anymex/widgets/minor_widgets/custom_text.dart';
import 'package:flutter/material.dart';
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
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    fetchAiRecommendations(currentPage);
  }

  void _scrollListener() {
    if (_scrollController.hasClients) {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 100 &&
          !isLoading) {
        fetchAiRecommendations(++currentPage);
      }
    }
  }

  Future<void> fetchAiRecommendations(int page) async {
    isLoading = true;
    final listData = Get.find<ServiceHandler>().animeList;
    final ids = listData.map((e) => e.id).toList();
    final data = await getAiRecommendations(widget.isManga, page);
    recItems.addAll(data.where((e) => !ids.contains(e.id)).toList());
    isLoading = false;
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
                  "AI Recommendations ${recItems.isNotEmpty ? '(${recItems.length})' : ''}",
              color: Theme.of(context).colorScheme.primary,
            );
          }),
        ),
        body: Obx(() => recItems.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: GridView.builder(
                      controller: _scrollController,
                      itemCount: recItems.length,
                      itemBuilder: (context, index) {
                        final data = recItems[index];
                        return _buildRecItem(data);
                      },
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: getResponsiveCrossAxisVal(
                          MediaQuery.of(context).size.width,
                          itemWidth: 400,
                        ),
                        mainAxisExtent: 200,
                      ),
                    ),
                  ),
                ],
              )),
      ),
    );
  }

  Widget _buildRecItem(Media data) {
    return InkWell(
      onTap: () {
        if (widget.isManga) {
          Get.to(() => MangaDetailsPage(media: data, tag: data.description));
        } else {
          Get.to(() => AnimeDetailsPage(media: data, tag: data.description));
        }
      },
      child: SlideAndScaleAnimation(
          child: Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
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
