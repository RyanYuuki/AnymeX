import 'package:anymex/controllers/service_handler/params.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/core/Model/Source.dart';
import 'package:anymex/core/Search/search.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/common/reusable_carousel.dart';
import 'package:anymex/widgets/common/search_bar.dart';
import 'package:anymex/widgets/helper/scroll_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SourceSearchPage extends StatefulWidget {
  final dynamic source;
  final String? initialTerm;
  final bool? isManga;
  const SourceSearchPage({
    super.key,
    this.source,
    this.initialTerm = "Attack on Titan",
    this.isManga,
  });

  @override
  State<SourceSearchPage> createState() => _SourceSearchPageState();
}

class _SourceSearchPageState extends State<SourceSearchPage> {
  RxList<Media> searchData = <Media>[].obs;
  final sourceController = Get.find<SourceController>();
  final serviceHandler = Get.find<ServiceHandler>();
  late TextEditingController textController;
  late bool isManga;
  late bool wasAllSelected;
  RxList<ReusableCarousel> searchCarousels = <ReusableCarousel>[].obs;

  @override
  void initState() {
    super.initState();
    textController = TextEditingController(text: widget.initialTerm);
    determineMediaType();
    _search();
  }

  void determineMediaType() {
    if (widget.source is List<Source>) {
      isManga = widget.source[0].isManga ?? widget.isManga ?? false;
      wasAllSelected = true;
    } else if (widget.source is Source) {
      isManga = widget.source?.isManga ?? widget.isManga ?? false;
      wasAllSelected = false;
    } else {
      isManga = widget.isManga ?? false;
      wasAllSelected = false;
    }
  }

  Future<void> _search() async {
    if (wasAllSelected) {
      searchCarousels.clear();
      for (var e in widget.source) {
        final data = await search(
          source: e,
          query: textController.text,
          page: 1,
          filterList: [],
        );
        if (data != null && data.isNotEmpty) {
          searchCarousels.add(
            ReusableCarousel(
              data: data,
              title: e.name!,
              variant: DataVariant.extension,
              source: e,
            ),
          );
        }
      }
    } else {
      final data =
          await serviceHandler.search(SearchParams(query: textController.text));
      searchData.value = data ?? [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Glow(
      child: Scaffold(
        body: ScrollWrapper(
          children: [
            Row(
              children: [
                const SizedBox(width: 10),
                IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back_ios_new)),
                Expanded(
                  child: CustomSearchBar(
                    onSubmitted: (v) => _search(),
                    controller: textController,
                    hintText: isManga ? "Search Manga..." : "Search Anime...",
                  ),
                ),
              ],
            ),
            Obx(() => wasAllSelected
                ? Column(
                    children: searchCarousels.value,
                  )
                : ReusableCarousel(
                    data: searchData.value,
                    title: widget.source.name,
                  ))
          ],
        ),
      ),
    );
  }
}
