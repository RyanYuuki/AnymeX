// ignore_for_file: deprecated_member_use

import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/models/Offline/Hive/offline_media.dart';
import 'package:anymex/screens/library/widgets/anime_card.dart';
import 'package:anymex/screens/library/widgets/manga_card.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/cards/base_card.dart';
import 'package:anymex/widgets/common/cards/card_gate.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

enum SortType {
  title,
  lastAdded,
  lastRead,
  rating,
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

  // Anime data
  RxList<CustomListData> customListData = <CustomListData>[].obs;
  RxList<CustomListData> initialCustomListData = <CustomListData>[].obs;
  RxList<OfflineMedia> filteredData = <OfflineMedia>[].obs;
  RxList<OfflineMedia> historyData = <OfflineMedia>[].obs;

  // Manga data
  RxList<CustomListData> customListDataManga = <CustomListData>[].obs;
  RxList<CustomListData> initialCustomListMangaData = <CustomListData>[].obs;
  RxList<OfflineMedia> filteredDataManga = <OfflineMedia>[].obs;
  RxList<OfflineMedia> historyDataManga = <OfflineMedia>[].obs;

  RxString searchQuery = ''.obs;
  RxInt selectedListIndex = 0.obs;
  RxBool isAnimeSelected = true.obs;

  @override
  void initState() {
    super.initState();
    final handler = Get.find<ServiceHandler>();

    // Initialize anime data
    customListData.value = offlineStorage.animeCustomListData
        .map((e) => CustomListData(
              listName: e.listName,
              listData: e.listData
                  .where((item) =>
                      item.serviceIndex == handler.serviceType.value.index)
                  .toList(),
            ))
        .toList();

    historyData.value = offlineStorage.animeLibrary
        .where((e) =>
            e.currentEpisode?.currentTrack != null &&
            e.serviceIndex == handler.serviceType.value.index)
        .toList();

    customListDataManga.value = offlineStorage.mangaCustomListData
        .map((e) => CustomListData(
              listName: e.listName,
              listData: e.listData
                  .where((item) =>
                      item.serviceIndex == handler.serviceType.value.index)
                  .toList(),
            ))
        .toList();

    historyDataManga.value = offlineStorage.mangaLibrary
        .where((e) =>
            e.currentChapter?.currentOffset != null &&
            e.serviceIndex == handler.serviceType.value.index)
        .toList();

    initialCustomListData.value = customListData;
    initialCustomListMangaData.value = customListDataManga;
    _getPreferences();
  }

  void _getPreferences() {
    currentSort = SortType.values[settingsController.preferences.get(
        '${isAnimeSelected.value ? 'anime' : 'manga'}_sort_type',
        defaultValue: SortType.lastRead.index)];
    isAscending = settingsController.preferences.get(
        '${isAnimeSelected.value ? 'anime' : 'manga'}_sort_order',
        defaultValue: true);
  }

  void _savePreferences() {
    settingsController.preferences.put(
        '${isAnimeSelected.value ? 'anime' : 'manga'}_sort_type',
        currentSort.index);
    settingsController.preferences.put(
        '${isAnimeSelected.value ? 'anime' : 'manga'}_sort_order', isAscending);
  }

  void _search(String val) {
    searchQuery.value = val;
    final currentIndex = selectedListIndex.value;

    if (isAnimeSelected.value) {
      final initialData = customListData[currentIndex].listData;
      filteredData.value = initialData
          .where(
              (e) => e.name?.toLowerCase().contains(val.toLowerCase()) ?? false)
          .toList();
    } else {
      final initialData = customListDataManga[currentIndex].listData;
      filteredDataManga.value = initialData
          .where(
              (e) => e.name?.toLowerCase().contains(val.toLowerCase()) ?? false)
          .toList();
    }
  }

  void _switchCategory(bool isAnime) {
    if (isAnimeSelected.value != isAnime) {
      isAnimeSelected.value = isAnime;
      selectedListIndex.value = 0;

      if (searchQuery.isNotEmpty) {
        controller.clear();
        searchQuery.value = '';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Glow(
      child: Scaffold(
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
            // Dynamic content
            _buildSliverTabsBody(),
          ],
        ),
      ),
    );
  }

  double getCardHeight(CardStyle style) {
    final isDesktop = getPlatform(context);
    switch (style) {
      case CardStyle.modern:
        return isDesktop ? 220 : 170;
      case CardStyle.exotic:
        return isDesktop ? 270 : 280;
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
            mainAxisSpacing: 10,
            mainAxisExtent:
                getCardHeight(CardStyle.values[settingsController.cardStyle]));
      } else {
        return const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2 / 3);
      }
    }

    if (gridCount.value == 2) {
      return SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridCount.value,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2 / 3,
      );
    }
    return SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridCount.value,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent:
            getCardHeight(CardStyle.values[settingsController.cardStyle]));
  }

  Widget _buildSliverTabsBody() {
    return Obx(() {
      if (selectedListIndex.value != -1) {
        final currentIndex = selectedListIndex.value;
        final lists =
            isAnimeSelected.value ? customListData : customListDataManga;
        final isEmpty = lists.isEmpty || lists[currentIndex].listData.isEmpty;
        final items = searchQuery.isNotEmpty
            ? (isAnimeSelected.value ? filteredData : filteredDataManga)
            : (lists.isEmpty ? [] : lists[currentIndex].listData);

        return isEmpty
            ? const SliverToBoxAdapter(child: EmptyLibrary())
            : SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
                sliver: SliverGrid(
                  gridDelegate: getSliverDel(),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      return MediaCardGate(
                          itemData: items[i],
                          tag: '${getRandomTag()}-$i',
                          variant: DataVariant.library,
                          isManga: !isAnimeSelected.value,
                          cardStyle:
                              CardStyle.values[settingsController.cardStyle]);
                    },
                    childCount: items.length,
                  ),
                ),
              );
      } else {
        final data = isAnimeSelected.value ? historyData : historyDataManga;

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: getResponsiveCrossAxisVal(
                    MediaQuery.of(context).size.width - 120,
                    itemWidth: 400),
                crossAxisSpacing: 10,
                mainAxisSpacing: 0,
                mainAxisExtent: getResponsiveSize(context,
                    mobileSize: 140, dektopSize: 190)),
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final animeData = data[i];
                return isAnimeSelected.value
                    ? AnimeHistoryCard(data: animeData)
                    : MangaHistoryCard(data: animeData);
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
          final lists =
              isAnimeSelected.value ? customListData : customListDataManga;

          return Row(children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: AnymexIconChip(
                icon: Row(
                  children: [
                    const Icon(Icons.history),
                    5.width(),
                    AnymexText(text: '(${historyData.length})')
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
          ]);
        }),
      ),
    );
  }

  final RxBool isSearchActive = false.obs;

  Widget _buildHeader() {
    return Obx(() => Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (!isSearchActive.value)
                    Column(
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
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    )
                  else
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 1,
                              ),
                            ),
                            child: IconButton(
                              onPressed: () {
                                isSearchActive.value = false;
                              },
                              icon: Icon(Icons.arrow_back_ios_new,
                                  color:
                                      Theme.of(context).colorScheme.onPrimary),
                              constraints: const BoxConstraints(
                                minHeight: 40,
                                minWidth: 40,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: CustomSearchBar(
                                controller: controller,
                                onChanged: _search,
                                hintText: isAnimeSelected.value
                                    ? 'Search Anime...'
                                    : 'Search Manga...',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      if (!isSearchActive.value)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 1,
                            ),
                          ),
                          child: IconButton(
                            onPressed: () => isSearchActive.value = true,
                            icon: Icon(IconlyLight.search,
                                color: Theme.of(context).colorScheme.onPrimary),
                          ),
                        ),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1,
                          ),
                        ),
                        child: IconButton(
                          onPressed: () {
                            showSortingSettings(
                                isManga: !isAnimeSelected.value);
                          },
                          icon: Icon(Icons.sort,
                              color: Theme.of(context).colorScheme.onPrimary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Tab selection buttons for Anime/Manga
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _switchCategory(true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isAnimeSelected.value
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isAnimeSelected.value
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.movie_outlined,
                                color: isAnimeSelected.value
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Anime',
                                style: TextStyle(
                                  fontFamily: "Poppins-Bold",
                                  fontSize: 16,
                                  color: isAnimeSelected.value
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => _switchCategory(false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !isAnimeSelected.value
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: !isAnimeSelected.value
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.menu_book_outlined,
                                color: !isAnimeSelected.value
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Manga',
                                style: TextStyle(
                                  fontFamily: "Poppins-Bold",
                                  fontSize: 16,
                                  color: !isAnimeSelected.value
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }

  void showSortingSettings({required bool isManga}) => AnymexSheet(
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
                          _buildSortTile(
                            title: 'Title',
                            currentSort: currentSort,
                            sortType: SortType.title,
                            isAscending: isAscending,
                            onTap: () =>
                                _handleSortChange(SortType.title, setState),
                          ),
                          _buildSortTile(
                            title: 'Last Added',
                            currentSort: currentSort,
                            sortType: SortType.lastAdded,
                            isAscending: isAscending,
                            onTap: () =>
                                _handleSortChange(SortType.lastAdded, setState),
                          ),
                          _buildSortTile(
                            title: isManga ? 'Last Read' : 'Last Watched',
                            currentSort: currentSort,
                            sortType: SortType.lastRead,
                            isAscending: isAscending,
                            onTap: () =>
                                _handleSortChange(SortType.lastRead, setState),
                          ),
                          _buildSortTile(
                            title: 'Rating',
                            currentSort: currentSort,
                            sortType: SortType.rating,
                            isAscending: isAscending,
                            onTap: () =>
                                _handleSortChange(SortType.rating, setState),
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
                                  },
                                  max: 10);
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

  SortType currentSort = SortType.lastAdded;
  bool isAscending = false;

  Widget _buildSortTile({
    required String title,
    required SortType currentSort,
    required SortType sortType,
    required bool isAscending,
    required VoidCallback onTap,
  }) {
    final isSelected = currentSort == sortType;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Material(
        elevation: 0,
        color: theme.colorScheme.secondaryContainer
            .withOpacity(isSelected ? 1.0 : 0.7),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          splashColor: theme.colorScheme.primary.withOpacity(0.1),
          highlightColor: theme.colorScheme.primary.withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: isSelected
                  ? Border.all(color: theme.colorScheme.primary, width: 1.5)
                  : null,
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: AnymexText(
                text: title,
                variant: isSelected ? TextVariant.bold : TextVariant.regular,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSecondaryContainer,
              ),
              trailing: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSelected ? null : 0,
                child: isSelected
                    ? AnymexIcon(
                        isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                      )
                    : null,
              ),
              selected: isSelected,
              selectedTileColor: Colors.transparent,
              onTap: null,
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
    final lists = isAnimeSelected.value ? customListData : customListDataManga;
    final currentList = lists[selectedListIndex.value];
    final initialList = isAnimeSelected.value
        ? initialCustomListData[selectedListIndex.value]
        : initialCustomListMangaData[selectedListIndex.value];

    currentList.listData.sort((a, b) {
      int comparison = 0;

      switch (currentSort) {
        case SortType.title:
          comparison = a.name!.compareTo(b.name!);
          break;
        case SortType.lastRead:
          final content = isAnimeSelected.value
              ? (a.currentEpisode?.lastWatchedTime ?? 0)
              : (a.currentChapter?.lastReadTime ?? 0);
          final tbc = isAnimeSelected.value
              ? (b.currentEpisode?.lastWatchedTime ?? 0)
              : (b.currentChapter?.lastReadTime ?? 0);
          comparison = content.compareTo(tbc);
          break;
        case SortType.rating:
          final rating = double.tryParse(a.rating ?? '0.0') ?? 0.0;
          final tbcRating = double.tryParse(b.rating ?? '0.0') ?? 0.0;
          comparison = rating.compareTo(tbcRating);
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

    if (isAnimeSelected.value) {
      customListData.refresh();
    } else {
      customListDataManga.refresh();
    }
  }
}

class CustomSearchBar extends StatefulWidget {
  final TextEditingController? controller;
  final Function(String)? onChanged;
  final String hintText;

  const CustomSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    required this.hintText,
  });

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  late FocusNode _focusNode;
  final settings = Get.find<Settings>();

  @override
  void initState() {
    super.initState();
    if (settings.isTV.value) {
      _focusNode = FocusNode(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _focusNode.focusInDirection(TraversalDirection.left);
              return KeyEventResult.skipRemainingHandlers;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _focusNode.focusInDirection(TraversalDirection.right);
              return KeyEventResult.skipRemainingHandlers;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              _focusNode.focusInDirection(TraversalDirection.up);
              return KeyEventResult.skipRemainingHandlers;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              _focusNode.focusInDirection(TraversalDirection.down);
              return KeyEventResult.skipRemainingHandlers;
            }
          }
          return KeyEventResult.ignored;
        },
      );
    } else {
      _focusNode = FocusNode();
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      focusNode: _focusNode,
      controller: widget.controller,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText: widget.hintText,
        filled: true,
        fillColor:
            Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
        prefixIcon: const Icon(IconlyLight.search),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.multiplyRadius()),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.secondaryContainer,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.multiplyRadius()),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.secondaryContainer,
            width: 1,
          ),
        ),
      ),
    );
  }
}

class CustomSliderTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final double sliderValue;
  final double max;
  final double min;
  final double? divisions;
  final Function(double value) onChanged;
  final Function(double value)? onChangedEnd;

  const CustomSliderTile({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.sliderValue,
    required this.onChanged,
    this.onChangedEnd,
    required this.max,
    this.divisions,
    this.min = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return AnymexOnTapAdv(
      onKeyEvent: (p0, e) {
        if (e is KeyDownEvent) {
          double step = (max - min) / (divisions ?? (max - min));

          if (e.logicalKey == LogicalKeyboardKey.arrowRight) {
            double newValue = (sliderValue + step).clamp(min, max);
            onChanged(newValue);
            return KeyEventResult.handled;
          } else if (e.logicalKey == LogicalKeyboardKey.arrowLeft) {
            double newValue = (sliderValue - step).clamp(min, max);
            onChanged(newValue);
            return KeyEventResult.handled;
          }
        } else if (e is KeyUpEvent) {
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
        child: Column(
          children: [
            Row(
              children: [
                AnymexIcon(icon,
                    size: 30, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                children: [
                  AnymexText(
                    text: sliderValue.toInt() == 0
                        ? 'Auto'
                        : (sliderValue % 1 == 0
                            ? sliderValue.toInt().toString()
                            : sliderValue.toStringAsFixed(1)),
                    variant: TextVariant.semiBold,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomSlider(
                      focusNode: FocusNode(
                          canRequestFocus: false, skipTraversal: true),
                      value: double.parse(sliderValue.toStringAsFixed(1)),
                      onChanged: onChanged,
                      max: max,
                      min: min,
                      onDragEnd: onChangedEnd,
                      glowBlurMultiplier: 1,
                      glowSpreadMultiplier: 1,
                      divisions: divisions?.toInt() ?? (max * 10).toInt(),
                      customValueIndicatorSize: RoundedSliderValueIndicator(
                          Theme.of(context).colorScheme,
                          width: 40,
                          height: 40,
                          radius: 50),
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnymexText(
                    text: max % 1 == 0
                        ? max.toInt().toString()
                        : max.toStringAsFixed(1),
                    variant: TextVariant.semiBold,
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
