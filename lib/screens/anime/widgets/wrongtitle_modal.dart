import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/controllers/source/source_mapper.dart';
import 'package:anymex/widgets/common/search_bar.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:get/get.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/widgets/common/cards/card_gate.dart';
import 'package:anymex/models/models_convertor/carousel_mapper.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/cards/base_card.dart';

class WrongTitleModal extends StatefulWidget {
  const WrongTitleModal({
    super.key,
    required this.initialText,
    required this.onTap,
    required this.isManga,
    this.isNovel = false,
    this.mediaId,
  });
  final String initialText;
  final Function(DMedia) onTap;
  final bool isManga;
  final bool isNovel;
  final String? mediaId;

  @override
  State<WrongTitleModal> createState() => _WrongTitleModalState();
}

class _WrongTitleModalState extends State<WrongTitleModal> {
  late Future<List<DMedia?>?> searchFuture;
  late TextEditingController controller;
  final sourceController = Get.find<SourceController>();
  final RxString searchStatus = "".obs;
  Worker? _sourceWorker;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialText);
    searchStatus.value = "Searching: ${controller.text}";
    searchFuture = performSearch();

    _sourceWorker = ever<Source?>(
        widget.isNovel
            ? sourceController.activeNovelSource
            : widget.isManga
                ? sourceController.activeMangaSource
                : sourceController.activeSource, (_) {
      if (mounted) {
        setState(() {
          searchFuture = performSearch();
        });
      }
    });
  }

  @override
  void dispose() {
    _sourceWorker?.dispose();
    controller.dispose();
    super.dispose();
  }

  Future<List<DMedia?>?> performSearch() async {
    searchStatus.value = "Searching: ${controller.text}";
    final source = widget.isNovel
        ? sourceController.activeNovelSource.value
        : widget.isManga
            ? sourceController.activeMangaSource.value
            : sourceController.activeSource.value;
    final results = (await source!.methods.search(controller.text, 1, [])).list;
    searchStatus.value = "";
    return results;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: CustomSearchBar(
                disableIcons: true,
                padding: const EdgeInsets.all(0),
                controller: controller,
                onSubmitted: (value) {
                  setState(() {
                    searchFuture = performSearch();
                  });
                },
              ),
            ),
            Obx(() => searchStatus.value.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: AnymexText(
                      text: searchStatus.value,
                      variant: TextVariant.semiBold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : const SizedBox.shrink()),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<DMedia?>?>(
                future: searchFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: AnymexProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  } else if (snapshot.hasData && snapshot.data != null) {
                    final results = snapshot.data ?? [];

                    if (results.isEmpty) {
                      return const Center(
                        child: Text('No results found.'),
                      );
                    }

                    final crossAxisCount = getResponsiveCrossAxisCount(context,
                        maxColumns: 5, baseColumns: 3);
                    return GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 10,
                          childAspectRatio: getGridCardAspectRatio(
                            context: context,
                            crossAxisCount: crossAxisCount,
                            spacing: 10,
                            padding: 40,
                          ),
                          mainAxisSpacing: 10),
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final item = results[index];
                        if (item == null) return const SizedBox.shrink();
                        final source = widget.isNovel
                            ? sourceController.activeNovelSource.value
                            : widget.isManga
                                ? sourceController.activeMangaSource.value
                                : sourceController.activeSource.value;
                        final carouselData = item.toCarouselData(sourceId: source?.id);
                        final itemType = widget.isNovel ? ItemType.novel : (widget.isManga ? ItemType.manga : ItemType.anime);
                        final heroTag = '${item.url}-$index-wrong-title';

                        return AnymexOnTap(
                          onTap: () {
                            SourceMapper.interruptMapping();
                            if (source != null && widget.mediaId != null) {
                              sourceController.setActiveSource(source,
                                  mediaId: widget.mediaId);
                            }
                            widget.onTap(item);
                            Get.back();
                          },
                          child: MediaCardGate(
                            itemData: carouselData,
                            tag: heroTag,
                            variant: DataVariant.regular,
                            type: itemType,
                            cardStyle: CardStyle.values[settingsController.cardStyle],
                          ),
                        );
                      },
                    );
                  } else {
                    return const Center(
                      child: Text('No data available.'),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showWrongTitleModal(
    BuildContext context, String initialText, Function(DMedia) onTap,
    {bool isManga = false, bool isNovel = false, String? mediaId}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: context.colors.surfaceContainer,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12.0),
    ),
    builder: (context) {
      final isDesktop = MediaQuery.of(context).size.width > 600;
      return SizedBox(
        width: isDesktop
            ? MediaQuery.of(context).size.width * 0.8
            : MediaQuery.of(context).size.width,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: WrongTitleModal(
              initialText: initialText,
              onTap: onTap,
              isManga: isManga,
              isNovel: isNovel,
              mediaId: mediaId),
        ),
      );
    },
  );
}
