import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/models_convertor/carousel/carousel_data.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/screens/novel/details/details_view.dart';
import 'package:anymex/utils/extension_utils.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/models/models_convertor/carousel_mapper.dart';
import 'package:anymex/widgets/common/cards/base_card.dart';
import 'package:anymex/widgets/common/cards/card_gate.dart';
import 'dart:math' as math;
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/common/future_reusable_carousel.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/common/search_bar.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:anymex/widgets/custom_widgets/custom_text.dart';

class SourceSearchPage extends StatefulWidget {
  final String? initialTerm;
  final ItemType type;
  final Source? source;

  const SourceSearchPage({
    super.key,
    this.initialTerm = "Attack on Titan",
    this.type = ItemType.anime,
    this.source,
  });

  @override
  State<SourceSearchPage> createState() => _SourceSearchPageState();
}

class _SourceSearchPageState extends State<SourceSearchPage> {
  final sourceController = Get.find<SourceController>();
  final serviceHandler = Get.find<ServiceHandler>();
  late TextEditingController textController;
  RxString currentSearchTerm = ''.obs;

  final RxList<ExtensionSearchItem> searchItems = <ExtensionSearchItem>[].obs;
  Key _singleSourceKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    textController = TextEditingController(text: widget.initialTerm ?? '');
    if (widget.initialTerm?.isNotEmpty == true) {
      _search();
    }
  }

  void _search() {
    final searchTerm = textController.text.trim();
    if (searchTerm.isEmpty) return;
    currentSearchTerm.value = searchTerm;
    _singleSourceKey = UniqueKey();

    if (widget.source == null) {
      final items = widget.type.extensions.map((s) {
        late ExtensionSearchItem item;
        final Future<List<dynamic>> future =
            s.methods.search(searchTerm, 1, []).then<List<dynamic>>((res) {
          final list = res.list;
          if (list.isNotEmpty) {
            item.status.value = 2;
          } else {
            item.status.value = 0;
          }
          _reorderSearchItems();
          return list;
        }).catchError((err) {
          item.status.value = 0;
          item.errorMessage.value = err.toString();
          _reorderSearchItems();
          return <dynamic>[];
        });

        item = ExtensionSearchItem(source: s, future: future);
        return item;
      }).toList();

      searchItems.assignAll(items);
    }
  }

  void _reorderSearchItems() {
    final sorted = searchItems.toList()
      ..sort((a, b) => b.status.value.compareTo(a.status.value));
    searchItems.assignAll(sorted);
  }

  @override
  Widget build(BuildContext context) {
    final isSingleSource = widget.source != null;
    final hint = isSingleSource
        ? "Search ${widget.source!.name}..."
        : "Search ${widget.type.name.capitalizeFirst}...";

    return Glow(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  children: [
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.arrow_back_ios_new),
                    ),
                    Expanded(
                      child: CustomSearchBar(
                        onSubmitted: (v) => _search(),
                        controller: textController,
                        disableIcons: true,
                        hintText: hint,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Obx(() {
                  if (currentSearchTerm.value.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  if (isSingleSource) {
                    return _SingleSourceGridView(
                      key: _singleSourceKey,
                      source: widget.source!,
                      type: widget.type,
                      searchTerm: currentSearchTerm.value,
                    );
                  }

                  return Column(
                    children: [
                      for (final item in searchItems)
                        Obx(() {
                          final lang = item.source.lang?.toUpperCase() ?? '';
                          final displayTitle = lang.isNotEmpty
                              ? '${item.source.name ?? "Unknown"} ($lang)'
                              : (item.source.name ?? 'Unknown');

                          if (item.errorMessage.value.isNotEmpty) {
                            final theme = Theme.of(context);
                            return Padding(
                              key: ValueKey(
                                  'err_${item.source.id}_${currentSearchTerm.value}'),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0, vertical: 8.0),
                              child: Container(
                                padding: const EdgeInsets.all(14.0),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.errorContainer
                                      .opaque(0.2, iReallyMeanIt: true),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: theme.colorScheme.error
                                        .opaque(0.3, iReallyMeanIt: true),
                                    width: 0.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      color: theme.colorScheme.error,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          AnymexText.semiBold(
                                            text: displayTitle,
                                            size: 14,
                                            color: theme.colorScheme.error,
                                          ),
                                          const SizedBox(height: 2),
                                          AnymexText.regular(
                                            text: item.errorMessage.value,
                                            maxLines: 2,
                                            size: 12,
                                            color: theme.colorScheme.onSurface
                                                .opaque(0.7, iReallyMeanIt: true),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return FutureReusableCarousel(
                            key: ValueKey(
                                '${item.source.id}_${currentSearchTerm.value}'),
                            title: displayTitle,
                            future: item.future,
                            type: widget.type,
                            variant: DataVariant.extension,
                            source: item.source,
                          );
                        }),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }
}

class ExtensionSearchItem {
  final Source source;
  final Future<List<dynamic>> future;
  final RxInt status = 1.obs;
  final RxString errorMessage = ''.obs;

  ExtensionSearchItem({
    required this.source,
    required this.future,
  });
}

class _SingleSourceGridView extends StatefulWidget {
  final Source source;
  final ItemType type;
  final String searchTerm;

  const _SingleSourceGridView({
    super.key,
    required this.source,
    required this.type,
    required this.searchTerm,
  });

  @override
  State<_SingleSourceGridView> createState() => _SingleSourceGridViewState();
}

class _SingleSourceGridViewState extends State<_SingleSourceGridView> {
  final List<dynamic> _items = [];
  int _currentPage = 1;
  bool _isLoadingInitial = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initialLoad();
  }

  Future<void> _initialLoad() async {
    setState(() {
      _isLoadingInitial = true;
      _errorMessage = null;
      _items.clear();
      _currentPage = 1;
      _hasMore = true;
    });

    try {
      final res = await widget.source.methods.search(widget.searchTerm, 1, []);
      final list = res.list;
      if (mounted) {
        setState(() {
          _items.addAll(list);
          _isLoadingInitial = false;
          if (list.isEmpty) {
            _hasMore = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoadingInitial = false;
        });
      }
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoadingInitial || _isLoadingMore || !_hasMore || _errorMessage != null) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final res = await widget.source.methods.search(widget.searchTerm, nextPage, []);
      final newItems = res.list;

      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          if (newItems.isEmpty) {
            _hasMore = false;
          } else {
            _currentPage = nextPage;
            _items.addAll(newItems);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          _hasMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoadingInitial) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 80.0),
        child: Center(child: AnymexProgressIndicator()),
      );
    }

    if (_errorMessage != null && _items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer
                .opaque(0.2, iReallyMeanIt: true),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.error.opaque(0.4, iReallyMeanIt: true),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: theme.colorScheme.error,
                size: 44,
              ),
              const SizedBox(height: 12),
              AnymexText.semiBold(
                text: 'Failed to search on ${widget.source.name}',
                size: 16,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 8),
              AnymexText.regular(
                text: _errorMessage!,
                textAlign: TextAlign.center,
                size: 13,
                color: theme.colorScheme.onSurface
                    .opaque(0.7, iReallyMeanIt: true),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _initialLoad,
                icon: const Icon(Icons.refresh_rounded),
                label: const AnymexText.regular(text: 'Retry', size: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 20.0),
        child: Center(
          child: AnymexText.semiBold(
            text: 'No search results found on ${widget.source.name}',
            size: 15,
            color: theme.colorScheme.onSurface.opaque(0.6, iReallyMeanIt: true),
          ),
        ),
      );
    }

    const horizontalPadding = 32.0;
    const crossAxisSpacing = 10.0;
    final availableWidth =
        MediaQuery.of(context).size.width - horizontalPadding;
    final isDesktop = getPlatform(context);
    final itemWidth = isDesktop ? 170.0 : 140.0;

    final crossAxisCount = math.max(
      1,
      ((availableWidth + crossAxisSpacing) / (itemWidth + crossAxisSpacing))
          .floor(),
    );

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels >=
            scrollInfo.metrics.maxScrollExtent - 300) {
          _loadNextPage();
        }
        return false;
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _items.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: crossAxisSpacing,
                mainAxisSpacing: 20,
                childAspectRatio: 2 / 3,
              ),
              itemBuilder: (context, index) {
                final item = _items[index];
                final CarouselData itemData = item is CarouselData
                    ? item
                    : (item is DMedia
                        ? item.toCarouselData()
                        : CarouselData(
                            id: item.url ?? '',
                            title: item.title ?? '',
                            poster: item.cover ?? '',
                            servicesType: ServicesType.extensions,
                            releasing: false,
                          ));

                final media = Media.fromCarouselData(
                  itemData,
                  widget.type,
                );
                final tag = '${widget.source.id}_${widget.searchTerm}_$index';

                return AnymexOnTap(
                  onTap: () {
                    final sourceController = Get.find<SourceController>();
                    sourceController.setActiveSource(widget.source);
                    if (widget.type == ItemType.novel) {
                      navigateWithAnimation(() => NovelDetailsPage(
                            media: media,
                            tag: tag,
                            source: widget.source,
                          ));
                    } else if (widget.type == ItemType.manga) {
                      navigateWithAnimation(() => MangaDetailsPage(
                            media: media,
                            tag: tag,
                          ));
                    } else {
                      navigateWithAnimation(() => AnimeDetailsPage(
                            media: media,
                            tag: tag,
                          ));
                    }
                  },
                  child: MediaCardGate(
                    itemData: itemData,
                    tag: tag,
                    variant: DataVariant.extension,
                    type: widget.type,
                    cardStyle: CardStyle.values[settingsController.cardStyle],
                  ),
                );
              },
            ),
          ),
          if (_isLoadingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Center(child: AnymexProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
