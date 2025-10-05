import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Offline/Hive/offline_media.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/library/editor/list_editor.dart';
import 'package:anymex/screens/library/widgets/history_model.dart';
import 'package:anymex/screens/library/widgets/library_deps.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/screens/novel/details/details_view.dart';
import 'package:anymex/screens/settings/widgets/history_card_gate.dart';
import 'package:anymex/screens/settings/widgets/history_card_selector.dart';
import 'package:anymex/utils/extension_utils.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/cards/base_card.dart';
import 'package:anymex/widgets/common/cards/card_gate.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/common/slider_semantics.dart';
import 'package:anymex/widgets/custom_widgets/anymex_bottomsheet.dart';
import 'package:anymex/widgets/custom_widgets/anymex_chip.dart';
import 'package:anymex/widgets/custom_widgets/custom_expansion_tile.dart';
import 'package:anymex/widgets/custom_widgets/custom_icon_wrapper.dart';
import 'package:anymex/widgets/exceptions/empty_library.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:dartotsu_extension_bridge/Models/Source.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';

enum SortType {
  title,
  lastAdded,
  lastRead,
  rating,
}

dynamic typeBuilder(ItemType type,
    {required dynamic animeValue,
    required dynamic mangaValue,
    required dynamic novelValue}) {
  switch (type) {
    case ItemType.anime:
      return animeValue;
    case ItemType.manga:
      return mangaValue;
    case ItemType.novel:
      return novelValue;
  }
}

class MyLibrary extends StatefulWidget {
  const MyLibrary({super.key});

  @override
  State<MyLibrary> createState() => _MyLibraryState();
}

class _MyLibraryState extends State<MyLibrary> {
  final TextEditingController controller = TextEditingController();
  final offlineStorage = Get.find<OfflineStorageController>();
  final gridCount = 0.obs;

  RxList<CustomListData> customListData = <CustomListData>[].obs;
  RxList<CustomListData> initialCustomListData = <CustomListData>[].obs;
  RxList<OfflineMedia> filteredData = <OfflineMedia>[].obs;
  RxList<OfflineMedia> historyData = <OfflineMedia>[].obs;

  RxList<CustomListData> customListDataManga = <CustomListData>[].obs;
  RxList<CustomListData> initialCustomListMangaData = <CustomListData>[].obs;
  RxList<OfflineMedia> filteredDataManga = <OfflineMedia>[].obs;
  RxList<OfflineMedia> historyDataManga = <OfflineMedia>[].obs;

  RxList<CustomListData> customListNovelData = <CustomListData>[].obs;
  RxList<CustomListData> initialCustomListNovelData = <CustomListData>[].obs;
  RxList<OfflineMedia> filteredDataNovel = <OfflineMedia>[].obs;
  RxList<OfflineMedia> historyDataNovel = <OfflineMedia>[].obs;

  RxString searchQuery = ''.obs;
  RxInt selectedListIndex = 0.obs;
  Rx<ItemType> type = ItemType.anime.obs;

  @override
  void initState() {
    super.initState();
    _initLibraryData();
    _getPreferences();
    ever(offlineStorage.animeCustomLists, (_) => _initLibraryData());
    ever(offlineStorage.mangaCustomLists, (_) => _initLibraryData());
    ever(offlineStorage.novelCustomLists, (_) => _initLibraryData());
  }

  void _initLibraryData() {
    customListData.value = offlineStorage.animeCustomListData.value
        .map((e) => CustomListData(
              listName: e.listName,
              listData: e.listData.toList(),
            ))
        .toList();

    customListDataManga.value = offlineStorage.mangaCustomListData.value
        .map((e) => CustomListData(
              listName: e.listName,
              listData: e.listData.toList(),
            ))
        .toList();

    customListNovelData.value = offlineStorage.novelCustomListData.value
        .map((e) => CustomListData(
              listName: e.listName,
              listData: e.listData.toList(),
            ))
        .toList();

    historyData.value = offlineStorage.animeLibrary
        .where((e) => e.currentEpisode?.currentTrack != null)
        .toList();
    historyDataManga.value = offlineStorage.mangaLibrary.toList();
    historyDataNovel.value = offlineStorage.novelLibrary.toList();

    initialCustomListData.value = customListData;
    initialCustomListMangaData.value = customListDataManga;
    initialCustomListNovelData.value = customListNovelData;
  }

  void _getPreferences() {
    currentSort = SortType.values[settingsController.preferences.get(
        '${type.value.name}_sort_type',
        defaultValue: SortType.lastRead.index)];
    isAscending = settingsController.preferences
        .get('${type.value.name}_sort_order', defaultValue: true);
    gridCount.value = settingsController.preferences
        .get('${type.value.name}_grid_size', defaultValue: 0);
  }

  void _savePreferences() {
    settingsController.preferences
        .put('${type.value.name}_sort_type', currentSort.index);
    settingsController.preferences
        .put('${type.value.name}_sort_order', isAscending);
    settingsController.preferences
        .put('${type.value.name}_grid_size', gridCount.value);
  }

  void _search(String val) {
    searchQuery.value = val;
    final currentIndex = selectedListIndex.value;

    if (type.value.isAnime) {
      final initialData = customListData[currentIndex].listData;
      filteredData.value = initialData
          .where(
              (e) => e.name?.toLowerCase().contains(val.toLowerCase()) ?? false)
          .toList();
    } else if (type.value.isManga) {
      final initialData = customListDataManga[currentIndex].listData;
      filteredDataManga.value = initialData
          .where(
              (e) => e.name?.toLowerCase().contains(val.toLowerCase()) ?? false)
          .toList();
    } else if (type.value.isNovel) {
      final initialData = customListNovelData[currentIndex].listData;
      filteredDataNovel.value = initialData
          .where(
              (e) => e.name?.toLowerCase().contains(val.toLowerCase()) ?? false)
          .toList();
    }
  }

  void _switchCategory(ItemType typ) {
    type.value = typ;
    selectedListIndex.value = 0;
    if (searchQuery.isNotEmpty) {
      controller.clear();
      searchQuery.value = '';
    }
    _getPreferences();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 28.0),
              child: _buildHeader(),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildChipTabs(),
          ),
          _buildSliverTabsBody(),
        ],
      ),
    );
  }

  double getCardHeight(CardStyle style) {
    final isDesktop = getPlatform(context);
    switch (style) {
      case CardStyle.modern:
        return isDesktop ? 220 : 170;
      case CardStyle.exotic:
        return isDesktop ? 270 : 210;
      case CardStyle.saikou:
        return isDesktop ? 270 : 230;
      case CardStyle.minimalExotic:
        return isDesktop ? 250 : 280;
      default:
        return isDesktop ? 230 : 170;
    }
  }

  SliverGridDelegateWithFixedCrossAxisCount getSliverDel() {
    if (gridCount.value == 0) {
      if (getPlatform(context)) {
        return SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: getResponsiveCrossAxisVal(
                MediaQuery.of(context).size.width - 120,
                itemWidth: 170),
            crossAxisSpacing: 10,
            mainAxisSpacing: 20,
            mainAxisExtent:
                getCardHeight(CardStyle.values[settingsController.cardStyle]));
      } else {
        return const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 20,
            childAspectRatio: 2 / 3);
      }
    }

    if (gridCount.value == 2) {
      return SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridCount.value,
        crossAxisSpacing: 10,
        mainAxisSpacing: 20,
        childAspectRatio: 2 / 3,
      );
    }
    if (getPlatform(context)) {
      return SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gridCount.value,
          crossAxisSpacing: 10,
          mainAxisSpacing: 20,
          mainAxisExtent:
              getCardHeight(CardStyle.values[settingsController.cardStyle]));
    } else {
      return SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gridCount.value,
          crossAxisSpacing: 10,
          mainAxisSpacing: 20,
          mainAxisExtent:
              (MediaQuery.of(context).size.width / gridCount.value) * (3 / 2) +
                  10);
    }
  }

  Widget _buildSliverTabsBody() {
    return Obx(() {
      if (selectedListIndex.value != -1) {
        final currentIndex = selectedListIndex.value;
        final lists = typeBuilder(type.value,
            animeValue: customListData,
            mangaValue: customListDataManga,
            novelValue: customListNovelData);
        final isEmpty = lists.isEmpty || lists[currentIndex].listData.isEmpty;
        final items = searchQuery.isNotEmpty
            ? typeBuilder(type.value,
                animeValue: filteredData,
                mangaValue: filteredDataManga,
                novelValue: filteredDataNovel)
            : (lists.isEmpty ? [] : lists[currentIndex].listData)
                as List<OfflineMedia>;

        return isEmpty
            ? const SliverToBoxAdapter(child: EmptyLibrary())
            : SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
                sliver: SliverGrid(
                  gridDelegate: getSliverDel(),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final tag = getRandomTag(addition: i.toString());
                      OfflineMedia item = items[i];
                      return AnymexOnTap(
                        margin: 0,
                        scale: 1,
                        onTap: () {
                          if (type.value.isAnime) {
                            navigate(() => AnimeDetailsPage(
                                media: Media.fromOfflineMedia(
                                    item, ItemType.anime),
                                tag: tag));
                          } else if (type.value.isManga) {
                            navigate(() => MangaDetailsPage(
                                media: Media.fromOfflineMedia(
                                    item, ItemType.manga),
                                tag: tag));
                          } else {
                            final source = sourceController
                                .getNovelExtensionByName(item.season ?? '');
                            if (source == null) {
                              errorSnackBar('Install ${item.season} extension');
                              return;
                            }

                            navigate(() => NovelDetailsPage(
                                source: source,
                                media: Media.fromOfflineMedia(
                                    items[i], ItemType.novel),
                                tag: tag));
                          }
                        },
                        child: MediaCardGate(
                            itemData: items[i],
                            tag: '${getRandomTag()}-$i',
                            variant: DataVariant.library,
                            type: type.value,
                            cardStyle:
                                CardStyle.values[settingsController.cardStyle]),
                      );
                    },
                    childCount: items.length,
                  ),
                ),
              );
      } else {
        final data = typeBuilder(type.value,
            animeValue: historyData,
            mangaValue: historyDataManga,
            novelValue: historyDataNovel);

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: getResponsiveCrossAxisVal(
                    MediaQuery.of(context).size.width - 120,
                    itemWidth: 400),
                crossAxisSpacing: 10,
                mainAxisSpacing: 0,
                mainAxisExtent: getHistoryCardHeight(
                    HistoryCardStyle
                        .values[settingsController.historyCardStyle],
                    context)),
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final historyModel =
                    HistoryModel.fromOfflineMedia(data[i], type.value);
                return HistoryCardGate(
                  data: historyModel,
                  cardStyle: HistoryCardStyle
                      .values[settingsController.historyCardStyle],
                );
              },
              childCount: data.length,
            ),
          ),
        );
      }
    });
  }

  Padding _buildChipTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Obx(() {
          final lists = typeBuilder(type.value,
              animeValue: customListData,
              mangaValue: customListDataManga,
              novelValue: customListNovelData);
          final historyCount = typeBuilder(type.value,
              animeValue: historyData.length,
              mangaValue: historyDataManga.length,
              novelValue: historyDataNovel.length);

          return Row(children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: AnymexIconChip(
                icon: Row(
                  children: [
                    Icon(
                        selectedListIndex.value == -1
                            ? Iconsax.clock5
                            : Iconsax.clock,
                        color: selectedListIndex.value == -1
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurfaceVariant),
                    5.width(),
                    AnymexText(text: '($historyCount)')
                  ],
                ),
                isSelected: selectedListIndex.value == -1,
                onSelected: (selected) {
                  if (selected) {
                    selectedListIndex.value = -1;
                    if (searchQuery.isNotEmpty) {
                      controller.clear();
                      searchQuery.value = '';
                    }
                  }
                },
              ),
            ),
            ...List.generate(
              lists.length,
              (index) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: AnymexChip(
                  label:
                      '${lists[index].listName} (${lists[index].listData.length})',
                  isSelected: selectedListIndex.value == index,
                  onSelected: (selected) {
                    if (selected) {
                      selectedListIndex.value = index;
                      if (searchQuery.isNotEmpty) {
                        controller.clear();
                        searchQuery.value = '';
                      }
                    }
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: AnymexIconChip(
                icon: Row(
                  children: [
                    Icon(Iconsax.edit,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    5.width(),
                    const AnymexText(text: 'Edit')
                  ],
                ),
                isSelected: false,
                onSelected: (selected) {
                  navigate(() => CustomListsEditor(type: type.value));
                },
              ),
            ),
          ]);
        }),
      ),
    );
  }

  final RxBool isSearchActive = false.obs;

  String _getTypeLabel(ItemType itemType) {
    if (serviceHandler.serviceType.value == ServicesType.simkl) {
      switch (itemType) {
        case ItemType.anime:
          return 'Movies & Series';
        case ItemType.manga:
          return 'Series';
        case ItemType.novel:
          return 'Books';
      }
    } else {
      switch (itemType) {
        case ItemType.anime:
          return 'Anime';
        case ItemType.manga:
          return 'Manga';
        case ItemType.novel:
          return 'Novels';
      }
    }
  }

  IconData _getTypeIcon(ItemType itemType) {
    switch (itemType) {
      case ItemType.anime:
        return Icons.movie_filter_rounded;
      case ItemType.manga:
        return serviceHandler.serviceType.value == ServicesType.simkl
            ? Iconsax.monitor
            : Icons.menu_book_outlined;
      case ItemType.novel:
        return serviceHandler.serviceType.value == ServicesType.simkl
            ? Icons.library_books
            : Iconsax.book;
    }
  }

  Widget _buildSegmentedControl() {
    final availableTypes =
        serviceHandler.serviceType.value == ServicesType.simkl
            ? [ItemType.anime]
            : [ItemType.anime, ItemType.manga, ItemType.novel];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: availableTypes.map((itemType) {
          final isSelected = type.value == itemType;
          return Expanded(
            child: GestureDetector(
              onTap: () => _switchCategory(itemType),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubic,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        _getTypeIcon(itemType),
                        key: ValueKey('${itemType.name}_icon'),
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontFamily: "Poppins-Bold",
                          fontSize: 14,
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        child: Text(
                          _getTypeLabel(itemType),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHeader() {
    return Obx(() => Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      AnimatedSlide(
                        offset: isSearchActive.value
                            ? const Offset(-1.0, 0)
                            : Offset.zero,
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOutCubic,
                        child: AnimatedOpacity(
                          opacity: isSearchActive.value ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Library',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: "Poppins-Bold",
                                ),
                              ),
                              Text(
                                'Discover your favorite series',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      AnimatedContainer(
                        width: isSearchActive.value
                            ? MediaQuery.of(context).size.width * 0.7
                            : 0,
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                        child: AnimatedOpacity(
                          opacity: isSearchActive.value ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          child: Row(
                            children: [
                              TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.elasticOut,
                                tween: Tween<double>(
                                  begin: 0.0,
                                  end: isSearchActive.value ? 1.0 : 0.0,
                                ),
                                builder: (context, value, child) {
                                  return Transform.scale(
                                    scale: value,
                                    child: child,
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    onPressed: () {
                                      isSearchActive.value = false;
                                    },
                                    icon: Icon(Icons.arrow_back_ios_new,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary),
                                    constraints: const BoxConstraints(
                                      minHeight: 40,
                                      minWidth: 40,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  child: CustomSearchBar(
                                    controller: controller,
                                    onChanged: _search,
                                    hintText: _getSearchHint(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                        child: !isSearchActive.value
                            ? Container(
                                key: const ValueKey('searchButton'),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  onPressed: () {
                                    isSearchActive.value = true;
                                  },
                                  icon: Icon(IconlyLight.search,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary),
                                ),
                              )
                            : const SizedBox(
                                key: ValueKey('emptySearch'), width: 0),
                      ),
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutBack,
                        tween: Tween<double>(
                          begin: 0.9,
                          end: 1.0,
                        ),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: child,
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: () {
                              showSortingSettings();
                            },
                            icon: Icon(Icons.sort,
                                color: Theme.of(context).colorScheme.onPrimary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSegmentedControl(),
            ],
          ),
        ));
  }

  String _getSearchHint() {
    return 'Search ${_getTypeLabel(type.value)}...';
  }

  void showSortingSettings() => AnymexSheet(
        title: 'Settings',
        contentWidget: StatefulBuilder(
          builder: (context, setState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnymexExpansionTile(
                        title: 'Sort By',
                        initialExpanded: true,
                        content: Column(children: [
                          Row(
                            children: [
                              _buildSortBox(
                                title: 'Title',
                                currentSort: currentSort,
                                sortType: SortType.title,
                                isAscending: isAscending,
                                onTap: () =>
                                    _handleSortChange(SortType.title, setState),
                                icon: Icons.sort_by_alpha,
                              ),
                              _buildSortBox(
                                title: 'Last Added',
                                currentSort: currentSort,
                                sortType: SortType.lastAdded,
                                isAscending: isAscending,
                                onTap: () => _handleSortChange(
                                    SortType.lastAdded, setState),
                                icon: Icons.add_circle_outline,
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              _buildSortBox(
                                title: _getLastReadTitle(),
                                currentSort: currentSort,
                                sortType: SortType.lastRead,
                                isAscending: isAscending,
                                onTap: () => _handleSortChange(
                                    SortType.lastRead, setState),
                                icon: _getLastReadIcon(),
                              ),
                              _buildSortBox(
                                title: 'Rating',
                                currentSort: currentSort,
                                sortType: SortType.rating,
                                isAscending: isAscending,
                                onTap: () => _handleSortChange(
                                    SortType.rating, setState),
                                icon: Icons.star_border,
                              ),
                            ],
                          ),
                        ])),
                    AnymexExpansionTile(
                        title: 'Grid',
                        content: Column(
                          children: [
                            Obx(() {
                              return CustomSliderTile(
                                  icon: Icons.grid_view_rounded,
                                  title: 'Grid Size',
                                  description: 'Adjust Items per row',
                                  sliderValue: gridCount.value.toDouble(),
                                  onChanged: (e) {
                                    gridCount.value = e.toInt();
                                    _savePreferences();
                                  },
                                  max: getResponsiveSize(context,
                                      mobileSize: 4, desktopSize: 10));
                            })
                          ],
                        ))
                  ],
                ),
              ),
            );
          },
        ),
      ).show(context);

  String _getLastReadTitle() {
    switch (type.value) {
      case ItemType.anime:
        return 'Last Watched';
      case ItemType.manga:
        return 'Last Read';
      case ItemType.novel:
        return 'Last Read';
    }
  }

  IconData _getLastReadIcon() {
    switch (type.value) {
      case ItemType.anime:
        return Icons.visibility;
      case ItemType.manga:
        return Icons.menu_book;
      case ItemType.novel:
        return Iconsax.book;
    }
  }

  SortType currentSort = SortType.lastAdded;
  bool isAscending = false;

  Widget _buildSortBox({
    required String title,
    required SortType currentSort,
    required SortType sortType,
    required bool isAscending,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    final isSelected = currentSort == sortType;
    final theme = Theme.of(context);

    return Expanded(
      child: SizedBox(
        height: 90,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          child: Material(
            clipBehavior: Clip.antiAlias,
            elevation: isSelected ? 3 : 0,
            shadowColor: isSelected
                ? theme.colorScheme.primary.withOpacity(0.4)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: onTap,
              splashColor: theme.colorScheme.primary.withOpacity(0.15),
              highlightColor: theme.colorScheme.primary.withOpacity(0.05),
              child: Container(
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.colorScheme.primary.withOpacity(0.15),
                            theme.colorScheme.primaryContainer,
                          ],
                        )
                      : null,
                  color: isSelected
                      ? null
                      : theme.colorScheme.surfaceVariant.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withOpacity(0.2),
                    width: isSelected ? 1.5 : 0.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        if (isSelected)
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  theme.colorScheme.primary.withOpacity(0.12),
                            ),
                          ),
                        Icon(
                          icon,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                          size: 24,
                        ),
                        if (isSelected)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isAscending
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                color: theme.colorScheme.onPrimary,
                                size: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      child: AnymexText(
                        text: title,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleSortChange(SortType sortType, StateSetter setState) {
    if (currentSort == sortType) {
      setState(() {
        isAscending = !isAscending;
      });
    } else {
      setState(() {
        currentSort = sortType;
        isAscending = false;
      });
    }

    _savePreferences();
    _applySorting();
  }

  void _applySorting() {
    final lists = typeBuilder(type.value,
        animeValue: customListData,
        mangaValue: customListDataManga,
        novelValue: customListNovelData);

    if (lists.isEmpty || selectedListIndex.value >= lists.length) return;

    final currentList = lists[selectedListIndex.value];
    final initialList = typeBuilder(type.value,
        animeValue: initialCustomListData[selectedListIndex.value],
        mangaValue: initialCustomListMangaData[selectedListIndex.value],
        novelValue: initialCustomListNovelData[selectedListIndex.value]);

    currentList.listData.sort((a, b) {
      int comparison = 0;

      switch (currentSort) {
        case SortType.title:
          comparison = a.name.compareTo(b.name);
          break;
        case SortType.lastRead:
          final aTime = type.value.isAnime
              ? (a.currentEpisode?.lastWatchedTime ?? 0)
              : (a.currentChapter?.lastReadTime ?? 0);
          final bTime = type.value.isAnime
              ? (b.currentEpisode?.lastWatchedTime ?? 0)
              : (b.currentChapter?.lastReadTime ?? 0);
          comparison = aTime.compareTo(bTime);
          break;
        case SortType.rating:
          final aRating = double.tryParse(a.rating ?? '0.0') ?? 0.0;
          final bRating = double.tryParse(b.rating ?? '0.0') ?? 0.0;
          comparison = aRating.compareTo(bRating);
          break;
        case SortType.lastAdded:
          break;
      }

      return isAscending ? comparison : -comparison;
    });

    if (currentSort == SortType.lastAdded) {
      if (isAscending) {
        currentList.listData = initialList.listData.reversed.toList();
      } else {
        currentList.listData = initialList.listData;
      }
    }

    if (type.value.isAnime) {
      customListData.refresh();
    } else if (type.value.isManga) {
      customListDataManga.refresh();
    } else if (type.value.isNovel) {
      customListNovelData.refresh();
    }
  }
}
