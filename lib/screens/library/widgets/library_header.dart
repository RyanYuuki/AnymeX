import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/screens/library/controller/library_controller.dart';
import 'package:anymex/screens/library/editor/list_editor.dart';
import 'package:anymex/screens/library/widgets/library_deps.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/custom_widgets/anymex_bottomsheet.dart';
import 'package:anymex/widgets/custom_widgets/anymex_chip.dart';
import 'package:anymex/widgets/custom_widgets/custom_expansion_tile.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:dartotsu_extension_bridge/Models/Source.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';

class LibraryHeader extends StatelessWidget {
  final LibraryController controller;

  const LibraryHeader({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSearchArea(context),
                  _buildActionButtons(context),
                ],
              ),
              const SizedBox(height: 16),
              _SegmentedControl(controller: controller),
            ],
          ),
        ));
  }

  Widget _buildSearchArea(BuildContext context) {
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        AnimatedSlide(
          offset: controller.isSearchActive.value
              ? const Offset(-1.0, 0)
              : Offset.zero,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic,
          child: AnimatedOpacity(
            opacity: controller.isSearchActive.value ? 0.0 : 1.0,
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
          width: controller.isSearchActive.value
              ? MediaQuery.of(context).size.width * 0.7
              : 0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: controller.isSearchActive.value ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: Row(
              children: [
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.elasticOut,
                  tween: Tween<double>(
                    begin: 0.0,
                    end: controller.isSearchActive.value ? 1.0 : 0.0,
                  ),
                  builder: (context, value, child) {
                    return Transform.scale(scale: value, child: child);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
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
                      onPressed: controller.toggleSearch,
                      icon: Icon(Icons.arrow_back_ios_new,
                          color: Theme.of(context).colorScheme.onPrimary),
                      constraints: const BoxConstraints(
                        minHeight: 40,
                        minWidth: 40,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: CustomSearchBar(
                      controller: controller.searchController,
                      onChanged: controller.search,
                      hintText: _getSearchHint(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return ScaleTransition(
              scale: animation,
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: !controller.isSearchActive.value
              ? Container(
                  key: const ValueKey('searchButton'),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
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
                    onPressed: controller.toggleSearch,
                    icon: Icon(IconlyLight.search,
                        color: Theme.of(context).colorScheme.onPrimary),
                  ),
                )
              : const SizedBox(key: ValueKey('emptySearch'), width: 0),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () => _showSortingSettings(context),
            icon: Icon(Icons.sort,
                color: Theme.of(context).colorScheme.onPrimary),
          ),
        ),
      ],
    );
  }

  String _getSearchHint() {
    return 'Search ${_getTypeLabel(controller.type.value)}...';
  }

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

  void _showSortingSettings(BuildContext context) => AnymexSheet(
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
                              _SortBox(
                                title: 'Title',
                                currentSort: controller.currentSort,
                                sortType: SortType.title,
                                isAscending: controller.isAscending,
                                onTap: () {
                                  controller.handleSortChange(SortType.title);
                                  setState(() {});
                                },
                                icon: Icons.sort_by_alpha,
                              ),
                              _SortBox(
                                title: 'Last Added',
                                currentSort: controller.currentSort,
                                sortType: SortType.lastAdded,
                                isAscending: controller.isAscending,
                                onTap: () {
                                  controller
                                      .handleSortChange(SortType.lastAdded);
                                  setState(() {});
                                },
                                icon: Icons.add_circle_outline,
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              _SortBox(
                                title: _getLastReadTitle(),
                                currentSort: controller.currentSort,
                                sortType: SortType.lastRead,
                                isAscending: controller.isAscending,
                                onTap: () {
                                  controller
                                      .handleSortChange(SortType.lastRead);
                                  setState(() {});
                                },
                                icon: _getLastReadIcon(),
                              ),
                              _SortBox(
                                title: 'Rating',
                                currentSort: controller.currentSort,
                                sortType: SortType.rating,
                                isAscending: controller.isAscending,
                                onTap: () {
                                  controller.handleSortChange(SortType.rating);
                                  setState(() {});
                                },
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
                                  sliderValue:
                                      controller.gridCount.value.toDouble(),
                                  onChanged: (e) {
                                    controller.gridCount.value = e.toInt();
                                    controller.savePreferences();
                                  },
                                  max: 10);
                            })
                          ],
                        )),
                    20.height()
                  ],
                ),
              ),
            );
          },
        ),
      ).show(context);

  String _getLastReadTitle() {
    switch (controller.type.value) {
      case ItemType.anime:
        return 'Last Watched';
      case ItemType.manga:
        return 'Last Read';
      case ItemType.novel:
        return 'Last Read';
    }
  }

  IconData _getLastReadIcon() {
    switch (controller.type.value) {
      case ItemType.anime:
        return Icons.visibility;
      case ItemType.manga:
        return Icons.menu_book;
      case ItemType.novel:
        return Iconsax.book;
    }
  }
}

class _SortBox extends StatelessWidget {
  final String title;
  final SortType currentSort;
  final SortType sortType;
  final bool isAscending;
  final VoidCallback onTap;
  final IconData icon;

  const _SortBox({
    required this.title,
    required this.currentSort,
    required this.sortType,
    required this.isAscending,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
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
}

class ChipTabs extends StatelessWidget {
  final LibraryController controller;

  const ChipTabs({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Obx(() {
          final lists = controller.typeBuilder(controller.type.value,
              animeValue: controller.customListData,
              mangaValue: controller.customListDataManga,
              novelValue: controller.customListNovelData);
          final historyCount = controller.typeBuilder(controller.type.value,
              animeValue: controller.historyData.length,
              mangaValue: controller.historyDataManga.length,
              novelValue: controller.historyDataNovel.length);

          return Row(children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: AnymexIconChip(
                icon: Row(
                  children: [
                    Icon(
                        controller.selectedListIndex.value == -1
                            ? Iconsax.clock5
                            : Iconsax.clock,
                        color: controller.selectedListIndex.value == -1
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurfaceVariant),
                    5.width(),
                    AnymexText(text: '($historyCount)')
                  ],
                ),
                isSelected: controller.selectedListIndex.value == -1,
                onSelected: (selected) {
                  if (selected) {
                    controller.selectList(-1);
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
                  isSelected: controller.selectedListIndex.value == index,
                  onSelected: (selected) {
                    if (selected) {
                      controller.selectList(index);
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
                  navigate(
                      () => CustomListsEditor(type: controller.type.value));
                },
              ),
            ),
          ]);
        }),
      ),
    );
  }
}

class _SegmentedControl extends StatelessWidget {
  final LibraryController controller;

  const _SegmentedControl({required this.controller});

  @override
  Widget build(BuildContext context) {
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
          return Obx(() {
            final isSelected = controller.type.value == itemType;

            return Expanded(
              child: GestureDetector(
                onTap: () => controller.switchCategory(itemType),
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
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
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
          });
        }).toList(),
      ),
    );
  }

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
}
