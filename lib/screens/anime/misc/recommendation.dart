import 'package:anymex/ai/animeo.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/screens/novel/details/details_view.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/animation/slide_scale.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_bottomsheet.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_progress.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile_builder.dart';
import 'package:anymex/widgets/common/anymex_pills.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/common/cards/card_gate.dart';
import 'package:anymex/widgets/common/search_bar.dart';
import 'package:anymex/widgets/media_items/media_item.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class _PrefOption {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PrefOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });
}

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
  RxBool noMoreItems = false.obs;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    if (serviceHandler.isLoggedIn.value) {
      fetchAiRecommendations(currentPage);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    textEditingController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isLoading.value &&
        !noMoreItems.value) {
      final nextPage = currentPage + 1;
      if (textEditingController.text.isEmpty) {
        fetchAiRecommendations(nextPage);
      } else {
        fetchAiRecommendations(nextPage,
            username: textEditingController.text);
      }
    }
  }

  Future<void> fetchAiRecommendations(int page, {String? username}) async {
    if (isLoading.value || noMoreItems.value) return;
    isLoading.value = true;

    try {
      final listData = widget.isManga
          ? Get.find<ServiceHandler>().mangaList
          : Get.find<ServiceHandler>().animeList;
      final existingIds = listData.map((e) => e.id.toString()).toSet();
      final currentUiIds = recItems.map((e) => e.id.toString()).toSet();

      int fetchPage = page;
      int attempts = 0;
      int newItemsAdded = 0;

      while (attempts < 15 && newItemsAdded < 12) {
        attempts++;
        final data = await getAiRecommendations(
          widget.isManga,
          fetchPage,
          username: username,
          isAdult: isAdult.value,
        );

        if (data.isEmpty) {
          noMoreItems.value = true;
          break;
        }

        final newItems = data.where((e) =>
            !existingIds.contains(e.id.toString()) &&
            !currentUiIds.contains(e.id.toString())).toList();

        for (final item in newItems) {
          currentUiIds.add(item.id.toString());
          recItems.add(item);
          newItemsAdded++;
        }

        fetchPage++;
      }

      currentPage = fetchPage;

      if (newItemsAdded == 0 && attempts >= 15) {
        noMoreItems.value = true;
      }
    } catch (e) {
      Logger.e('Error fetching AI recommendations: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _showSettings() {
    AnymeXSheet(
      title: 'Preferences',
      showDragHandle: true,
      contentWidget: Obx(() {
        final options = [
          _PrefOption(
            title: "Grid View",
            subtitle: "Toggle between grid and detailed list",
            icon: Iconsax.grid_1,
            value: isGrid.value,
            onChanged: (v) => isGrid.value = v,
          ),
          _PrefOption(
            title: "18+ Content",
            subtitle: "Include adult & NSFW suggestions",
            icon: Icons.eighteen_up_rating_rounded,
            value: isAdult.value,
            onChanged: (v) {
              isAdult.value = v;
              noMoreItems.value = false;
              recItems.clear();
              currentPage = 1;
              fetchAiRecommendations(1,
                  username: textEditingController.text.isNotEmpty
                      ? textEditingController.text
                      : null);
            },
          ),
        ];

        return AnymeXTileBuilder<_PrefOption>(
          items: options,
          isSelection: false,
          getTitle: (opt) => opt.title,
          getSubtitle: (opt) => opt.subtitle,
          getIcon: (opt) => opt.icon,
          getTrailing: (opt) => Switch(
            value: opt.value,
            onChanged: opt.onChanged,
          ),
          onItemPressed: (opt) => opt.onChanged(!opt.value),
        );
      }),
    ).show(context);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final title = "AI Picks${recItems.isNotEmpty ? ' (${recItems.length})' : ''}";
      final subtitle = widget.isManga
          ? 'Smart manga suggestions'
          : 'Personalized recommendations';

      return AnymeXScaffold(
        showHeader: true,
        headerTitle: title,
        headerSubtitle: subtitle,
        headerAction: IconButton(
          onPressed: _showSettings,
          icon: const Icon(Iconsax.setting_2, size: 22),
        ),
        body: Builder(
          builder: (ctx) {
            final headerHeight = AnymeXHeaderScope.of(ctx);

            return Obx(() {
              if (recItems.isEmpty) {
                if (!serviceHandler.isLoggedIn.value) {
                  return _buildInputBox(context, headerHeight);
                }
                return Padding(
                  padding: EdgeInsets.only(top: headerHeight),
                  child: const Center(child: AnymeXProgressIndicator()),
                );
              }
              return _buildRecommendations(context, headerHeight);
            });
          },
        ),
      );
    });
  }

  Widget _buildInputBox(BuildContext context, double headerHeight) {
    return Padding(
      padding: EdgeInsets.only(top: headerHeight),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 320,
                child: CustomSearchBar(
                  controller: textEditingController,
                  onSubmitted: (v) {
                    final query = v.trim();
                    if (query.isNotEmpty) {
                      noMoreItems.value = false;
                      recItems.clear();
                      fetchAiRecommendations(1, username: query);
                    }
                  },
                  disableIcons: true,
                  hintText: "Enter Username",
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  final text = textEditingController.text.trim();
                  if (text.isNotEmpty) {
                    noMoreItems.value = false;
                    recItems.clear();
                    fetchAiRecommendations(1, username: text);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  decoration: BoxDecoration(
                    color: context.colors.primary,
                    borderRadius: BorderRadius.circular(12.multiplyRadius()),
                  ),
                  child: AnymeXText(
                    "Search",
                    variant: TextVariant.semiBold,
                    color: context.colors.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendations(BuildContext context, double headerHeight) {
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(12, headerHeight + 8, 12, 24),
      controller: _scrollController,
      itemCount: recItems.length + 3,
      itemBuilder: (context, index) {
        final isLastRow = index >= recItems.length;
        final lastRowIndex = index - recItems.length;

        if (isLastRow) {
          if (lastRowIndex == 0 || lastRowIndex == 2) {
            return const SizedBox.shrink();
          } else if (lastRowIndex == 1) {
            return Obx(() {
              if (isLoading.value) {
                return const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Center(child: AnymeXProgressIndicator()),
                );
              }
              if (noMoreItems.value) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: AnymeXText(
                      'No more recommendations',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .opaque(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            });
          }
        }

        final data = recItems[index];
        return isGrid.value
            ? GridAnimeCard(data: data, isManga: widget.isManga)
            : _buildRecItem(data);
      },
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: getResponsiveCrossAxisVal(
          MediaQuery.sizeOf(context).width,
          itemWidth: isGrid.value ? 115 : 380,
        ),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: isGrid.value ? null : 172,
        childAspectRatio: isGrid.value
            ? getGridCardAspectRatio(
                context: context,
                crossAxisCount: getResponsiveCrossAxisVal(
                  MediaQuery.sizeOf(context).width,
                  itemWidth: 115,
                ),
                spacing: 10,
                padding: 20,
              )
            : 2.2,
      ),
    );
  }

  Widget _buildRecItem(Media data) {
    final colors = Theme.of(context).colorScheme;

    final metaPills = <PillItem>[
      if (data.rating.isNotEmpty && data.rating != '0' && data.rating != '??')
        PillItem(
          icon: Icons.star_rounded,
          label: data.rating,
          isSelected: false,
          onTap: () {},
        ),
      if (data.format.isNotEmpty && data.format != '?')
        PillItem(
          label: data.format,
          isSelected: false,
          onTap: () {},
        )
      else
        PillItem(
          label: data.mediaType.name.toUpperCase(),
          isSelected: false,
          onTap: () {},
        ),
    ];

    return InkWell(
      borderRadius: BorderRadius.circular(16.multiplyRoundness()),
      onTap: () {
        if (data.mediaType == ItemType.novel) {
          navigate(() => NovelDetailsPage(media: data));
        } else if (data.mediaType == ItemType.manga || widget.isManga) {
          navigate(() => MangaDetailsPage(media: data, tag: data.description));
        } else {
          navigate(() => AnimeDetailsPage(media: data, tag: data.description));
        }
      },
      child: SlideAndScaleAnimation(
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.opaque(0.35, iReallyMeanIt: true),
            borderRadius: BorderRadius.circular(16.multiplyRoundness()),
            border: Border.all(
              color: colors.outline.opaque(0.12, iReallyMeanIt: true),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: data.description,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.multiplyRoundness()),
                  child: AnymeXImage(
                    radius: 0,
                    imageUrl: data.poster,
                    width: 102,
                    height: 156,
                    fit: BoxFit.cover,
                    isAnime: !widget.isManga,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    AnymeXText(
                      data.displayTitle,
                      variant: TextVariant.bold,
                      size: 14,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      isMarquee: true,
                    ),
                    const SizedBox(height: 5),
                    if (metaPills.isNotEmpty) ...[
                      AnymeXPills(
                        items: metaPills,
                        style: PillStyle.connective,
                        scrollable: true,
                        scrollPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 5),
                    ],
                    Expanded(
                      child: AnymeXText(
                        data.description,
                        color: colors.onSurfaceVariant.opaque(0.75, iReallyMeanIt: true),
                        size: 11.5,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (data.genres.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      AnymeXPills(
                        items: data.genres
                            .map((e) => PillItem(
                                  label: e,
                                  isSelected: false,
                                  onTap: () {},
                                ))
                            .toList(),
                        style: PillStyle.connective,
                        scrollable: true,
                        scrollPadding: EdgeInsets.zero,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
