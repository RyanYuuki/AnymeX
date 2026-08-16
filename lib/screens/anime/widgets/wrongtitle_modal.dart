import 'package:anymex/widgets/anymex_widgets/anymex_bottomsheet.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/controllers/source/source_mapper.dart';
import 'package:anymex/widgets/common/search_bar.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:flutter/material.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_progress.dart';
import 'package:get/get.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/widgets/common/cards/card_gate.dart';
import 'package:anymex/models/models_convertor/carousel_mapper.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/cards/base_card.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/common/cards/card_components.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile_builder.dart';

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
  bool _isCardView = true;

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
      width: MediaQuery.sizeOf(context).width,
      height: MediaQuery.sizeOf(context).height * 0.6,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: CustomSearchBar(
                    disableIcons: true,
                    padding: const EdgeInsets.all(0),
                    controller: controller,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(22),
                      bottomLeft: Radius.circular(22),
                      topRight: Radius.circular(5),
                      bottomRight: Radius.circular(5),
                    ),
                    onSubmitted: (value) {
                      setState(() {
                        searchFuture = performSearch();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.opaque(0.35),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(5),
                      bottomLeft: Radius.circular(5),
                      topRight: Radius.circular(22),
                      bottomRight: Radius.circular(22),
                    ),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.onSurface.opaque(0.08, iReallyMeanIt: true),
                      width: 0.5,
                    ),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      setState(() {
                        _isCardView = !_isCardView;
                      });
                    },
                    icon: Icon(
                      _isCardView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    tooltip: _isCardView ? 'Switch to List View' : 'Switch to Card View',
                  ),
                ),
              ],
            ),
            Obx(() => searchStatus.value.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                    child: AnymeXText(
                      text: searchStatus.value,
                      variant: TextVariant.semiBold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : const SizedBox.shrink()),
            const SizedBox(height: 10),
            Expanded(
              child: FutureBuilder<List<DMedia?>?>(
                future: searchFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: AnymeXProgressIndicator());
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

                    if (!_isCardView) {
                      return SingleChildScrollView(
                        child: AnymeXTileBuilder<DMedia>(
                          items: results.whereType<DMedia>().toList(),
                          isSelection: false,
                          maxLines: 3,
                          showChevron: (_) => false,
                          getTitle: (item) {
                            final source = widget.isNovel
                                ? sourceController.activeNovelSource.value
                                : widget.isManga
                                    ? sourceController.activeMangaSource.value
                                    : sourceController.activeSource.value;
                            final carouselData =
                                item.toCarouselData(sourceId: source?.id);
                            return carouselData.title ?? '';
                          },
                          getLeading: (item) {
                            final source = widget.isNovel
                                ? sourceController.activeNovelSource.value
                                : widget.isManga
                                    ? sourceController.activeMangaSource.value
                                    : sourceController.activeSource.value;
                            final carouselData =
                                item.toCarouselData(sourceId: source?.id);
                            final itemType = widget.isNovel
                                ? ItemType.novel
                                : (widget.isManga
                                    ? ItemType.manga
                                    : ItemType.anime);
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: AnymeXImage(
                                width: 45,
                                height: 60,
                                imageUrl: carouselData.poster ?? '',
                                sourceId: source?.id,
                                isAnime: itemType == ItemType.anime,
                              ),
                            );
                          },
                          onItemPressed: (item) {
                            final source = widget.isNovel
                                ? sourceController.activeNovelSource.value
                                : widget.isManga
                                    ? sourceController.activeMangaSource.value
                                    : sourceController.activeSource.value;
                            FocusManager.instance.primaryFocus?.unfocus();
                            SourceMapper.interruptMapping();
                            if (source != null && widget.mediaId != null) {
                              sourceController.setActiveSource(source, mediaId: widget.mediaId);
                            }
                            Get.back();
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              widget.onTap(item);
                            });
                          },
                        ),
                      );
                    }

                    final crossAxisCount = getResponsiveCrossAxisCount(context,
                        maxColumns: 5, baseColumns: 3);
                    return GridView.builder(
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
                        final carouselData =
                            item.toCarouselData(sourceId: source?.id);
                        final itemType = widget.isNovel
                            ? ItemType.novel
                            : (widget.isManga
                                ? ItemType.manga
                                : ItemType.anime);
                        final heroTag = '${item.url}-$index-wrong-title';

                        return AnymexOnTap(
                          onTap: () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            SourceMapper.interruptMapping();
                            if (source != null && widget.mediaId != null) {
                              sourceController.setActiveSource(source,
                                  mediaId: widget.mediaId);
                            }
                            Get.back();
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              widget.onTap(item);
                            });
                          },
                          child: MediaCardGate(
                            itemData: carouselData,
                            tag: heroTag,
                            variant: DataVariant.regular,
                            type: itemType,
                            cardStyle:
                                CardStyle.values[settingsController.cardStyle],
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
  final isDesktop = MediaQuery.sizeOf(context).width > 600;

  return AnymeXSheet.custom(
      SizedBox(
        width: isDesktop
            ? MediaQuery.sizeOf(context).width * 0.8
            : MediaQuery.sizeOf(context).width,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: WrongTitleModal(
              initialText: initialText,
              onTap: onTap,
              isManga: isManga,
              isNovel: isNovel,
              mediaId: mediaId),
        ),
      ),
      context);
}
