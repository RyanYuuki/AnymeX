import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/screens/library/controller/library_controller.dart';
import 'package:anymex/screens/library/editor/history_editor.dart';
import 'package:anymex/screens/library/editor/list_editor.dart';
import 'package:anymex/screens/library/widgets/library_deps.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/custom_widgets/anymex_bottomsheet.dart';
import 'package:anymex/widgets/custom_widgets/anymex_chip.dart';
import 'package:anymex/widgets/custom_widgets/custom_expansion_tile.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
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
              LibrarySegmentedControl(controller: controller),
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
                    color: context.colors.onSurface.withOpacity(0.55),
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
                      color: context.colors.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: context.colors.outline.withOpacity(0.08),
                      ),
                    ),
                    child: IconButton(
                      onPressed: controller.toggleSearch,
                      icon: Icon(Icons.arrow_back_ios_new,
                          color: context.colors.onSurface),
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
                      backgroundColor: context.colors.surfaceContainer
                          .opaque(0.5, iReallyMeanIt: true),
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
                    color: context.colors.surfaceContainer.opaque(0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: context.colors.outline.withOpacity(0.08),
                    ),
                  ),
                  child: IconButton(
                    onPressed: controller.toggleSearch,
                    icon: Icon(IconlyLight.search,
                        color: context.colors.onSurface),
                  ),
                )
              : const SizedBox(key: ValueKey('emptySearch'), width: 0),
        ),
        Container(
          decoration: BoxDecoration(
            color: context.colors.surfaceContainer.opaque(0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: context.colors.outline.withOpacity(0.08),
            ),
          ),
          child: IconButton(
            onPressed: () => _showSortingSettings(context),
            icon: Icon(Icons.sort, color: context.colors.onSurface),
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
          return 'Movies & Series & Animes';
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
                        content: Obx(() {
                          final isHistory =
                              controller.selectedListIndex.value == -1;
                          return Column(children: [
                            Row(
                              children: [
                                _SortBox(
                                  title: 'Title',
                                  currentSort: controller.currentSort.value,
                                  sortType: SortType.title,
                                  isAscending: controller.isAscending.value,
                                  onTap: () {
                                    controller.handleSortChange(SortType.title);
                                  },
                                  icon: Icons.sort_by_alpha,
                                ),
                                if (!isHistory)
                                  _SortBox(
                                    title: 'Last Added',
                                    currentSort: controller.currentSort.value,
                                    sortType: SortType.lastAdded,
                                    isAscending: controller.isAscending.value,
                                    onTap: () {
                                      controller
                                          .handleSortChange(SortType.lastAdded);
                                    },
                                    icon: Icons.add_circle_outline,
                                  ),
                                if (isHistory)
                                  _SortBox(
                                    title: _getLastReadTitle(),
                                    currentSort: controller.currentSort.value,
                                    sortType: SortType.lastRead,
                                    isAscending: controller.isAscending.value,
                                    onTap: () {
                                      controller
                                          .handleSortChange(SortType.lastRead);
                                    },
                                    icon: _getLastReadIcon(),
                                  ),
                              ],
                            ),
                            if (!isHistory)
                              Row(
                                children: [
                                  _SortBox(
                                    title: _getLastReadTitle(),
                                    currentSort: controller.currentSort.value,
                                    sortType: SortType.lastRead,
                                    isAscending: controller.isAscending.value,
                                    onTap: () {
                                      controller
                                          .handleSortChange(SortType.lastRead);
                                    },
                                    icon: _getLastReadIcon(),
                                  ),
                                  _SortBox(
                                    title: 'Rating',
                                    currentSort: controller.currentSort.value,
                                    sortType: SortType.rating,
                                    isAscending: controller.isAscending.value,
                                    onTap: () {
                                      controller
                                          .handleSortChange(SortType.rating);
                                    },
                                    icon: Icons.star_border,
                                  ),
                                ],
                              ),
                          ]);
                        })),
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
                ? theme.colorScheme.primary.opaque(0.4, iReallyMeanIt: true)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: onTap,
              splashColor:
                  theme.colorScheme.primary.opaque(0.15, iReallyMeanIt: true),
              highlightColor:
                  theme.colorScheme.primary.opaque(0.05, iReallyMeanIt: true),
              child: Container(
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.colorScheme.primary
                                .opaque(0.15, iReallyMeanIt: true),
                            theme.colorScheme.primaryContainer,
                          ],
                        )
                      : null,
                  color: isSelected
                      ? null
                      : theme.colorScheme.surfaceVariant
                          .opaque(0.7, iReallyMeanIt: true),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline
                            .opaque(0.2, iReallyMeanIt: true),
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
                              color: theme.colorScheme.primary
                                  .opaque(0.12, iReallyMeanIt: true),
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

  Widget _buildCustomPill({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    Widget? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(30),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected
                  ? context.colors.primary.withOpacity(0.08)
                  : context.colors.surfaceContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isSelected
                    ? context.colors.primary.withOpacity(0.3)
                    : context.colors.outline.withOpacity(0.08),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  icon,
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? context.colors.primary
                        : context.colors.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Obx(() {
          controller.selectedListIndex.value;
          return StreamBuilder<List<dynamic>>(
            stream: controller.offlineStorage
                .watchCustomLists(controller.type.value)
                .map((lists) => lists
                    .where(
                        (l) => l.mediaTypeIndex == controller.type.value.index)
                    .toList()),
            builder: (context, customListSnapshot) {
              return StreamBuilder<List<dynamic>>(
                stream: controller.getHistoryStream(),
                builder: (context, historySnapshot) {
                  final customLists = customListSnapshot.data ?? [];
                  final historyCount = historySnapshot.data?.length ?? 0;

                  return Row(children: [
                    _buildCustomPill(
                      context: context,
                      label: 'History ($historyCount)',
                      isSelected: controller.selectedListIndex.value == -1,
                      onTap: () => controller.selectList(-1),
                      onLongPress: () => Get.to(
                          () => HistoryEditor(type: controller.type.value)),
                      icon: Icon(
                        controller.selectedListIndex.value == -1
                            ? Iconsax.clock5
                            : Iconsax.clock,
                        size: 16,
                        color: controller.selectedListIndex.value == -1
                            ? context.colors.primary
                            : context.colors.onSurfaceVariant,
                      ),
                    ),
                    ...List.generate(
                      customLists.length,
                      (index) {
                        final list = customLists[index];
                        final listName = list.listName ?? '';

                        return StreamBuilder<CustomListData>(
                          stream: controller.offlineStorage.watchCustomListData(
                              listName, controller.type.value),
                          builder: (context, listDataSnapshot) {
                            final itemCount =
                                listDataSnapshot.data?.listData.length ?? 0;

                            return _buildCustomPill(
                              context: context,
                              label: '$listName ($itemCount)',
                              isSelected:
                                  controller.selectedListIndex.value == index,
                              onTap: () => controller.selectList(index),
                            );
                          },
                        );
                      },
                    ),
                    _buildCustomPill(
                      context: context,
                      label: 'Edit',
                      isSelected: false,
                      onTap: () => navigate(
                          () => CustomListsEditor(type: controller.type.value)),
                      icon: Icon(
                        Iconsax.edit,
                        size: 16,
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ]);
                },
              );
            },
          );
        }),
      ),
    );
  }
}

class LibrarySegmentedControl extends StatelessWidget {
  final LibraryController controller;

  const LibrarySegmentedControl({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;

    final availableTypes =
        serviceHandler.serviceType.value == ServicesType.simkl
            ? [ItemType.anime]
            : [ItemType.anime, ItemType.manga, ItemType.novel];

    final totalItems = availableTypes.length;

    return Container(
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer.opaque(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          Obx(() {
            final currentIndex = availableTypes.indexOf(controller.type.value);

            double alignmentX = 0.0;
            if (totalItems > 1) {
              alignmentX = -1.0 + (2.0 * currentIndex / (totalItems - 1));
            }

            return AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutQuint,
              alignment: Alignment(alignmentX, 0),
              child: FractionallySizedBox(
                widthFactor: 1 / totalItems,
                heightFactor: 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.opaque(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.12),
                      width: 1,
                    ),
                  ),
                ),
              ),
            );
          }),
          Row(
            children: availableTypes.map((itemType) {
              return Expanded(
                child: Obx(() {
                  final isSelected = controller.type.value == itemType;

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (!isSelected) {
                        HapticFeedback.lightImpact();
                        controller.switchCategory(itemType);
                      }
                    },
                    child: AnimatedScale(
                      scale: isSelected ? 1.02 : 1.0,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: AnimatedOpacity(
                        opacity: isSelected ? 1.0 : 0.6,
                        duration: const Duration(milliseconds: 200),
                        child: SizedBox.expand(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                _getTypeIcon(itemType),
                                size: 18,
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 200),
                                  style: TextStyle(
                                    fontFamily: "Poppins-Bold",
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                  child: Text(
                                    _getTypeLabel(itemType),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _getTypeLabel(ItemType itemType) {
    if (serviceHandler.serviceType.value == ServicesType.simkl) {
      switch (itemType) {
        case ItemType.anime:
          return 'Movies & Series & Animes';
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
