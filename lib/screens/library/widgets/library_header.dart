import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/screens/library/controller/library_controller.dart';
import 'package:anymex/screens/library/editor/history_editor.dart';
import 'package:anymex/screens/library/editor/list_editor.dart';
import 'package:anymex/screens/library/widgets/library_deps.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:anymex/widgets/custom_widgets/anymex_tabbar.dart';
import 'package:flutter/material.dart';
import 'package:anymex/widgets/header.dart';
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
          return 'Movies';
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

  void _showSortingSettings(BuildContext context) =>
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) {
          return LibrarySettingsSheet(controller: controller);
        },
      );
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
    return Obx(() {
      final availableTypes =
          serviceHandler.serviceType.value == ServicesType.simkl
              ? [ItemType.anime, ItemType.manga]
              : [ItemType.anime, ItemType.manga, ItemType.novel];

      final currentIndex = availableTypes.indexOf(controller.type.value);

      return AnymeXTabBar(
        selectTabs: availableTypes.map((itemType) => _getTypeLabel(itemType)).toList(),
        selectedIndex: currentIndex,
        height: 52,
        icons: availableTypes.map((itemType) => _getTypeIcon(itemType)).toList(),
        activeColor: context.colors.secondary,
        activeTextColor: context.colors.onSecondary,
        inactiveTextColor: context.colors.onSurfaceVariant,
        onTabSelected: (index) {
          controller.switchCategory(availableTypes[index]);
        },
      );
    });
  }

  String _getTypeLabel(ItemType itemType) {
    if (serviceHandler.serviceType.value == ServicesType.simkl) {
      switch (itemType) {
        case ItemType.anime:
          return 'Movies';
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
