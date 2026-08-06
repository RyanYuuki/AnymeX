import 'package:anymex/controllers/offline/offline_storage_controller.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/screens/library/controller/library_controller.dart';
import 'package:anymex/screens/library/editor/history_editor.dart';
import 'package:anymex/screens/library/editor/list_editor.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/anymex_slider_m3.dart';
import 'package:anymex/widgets/common/slider_semantics.dart';
import 'package:anymex/widgets/custom_widgets/anymex_tabbar.dart';
import 'package:anymex/widgets/custom_widgets/custom_icon_wrapper.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:iconsax/iconsax.dart';

class CustomSearchBar extends StatefulWidget {
  final TextEditingController? controller;
  final Function(String)? onChanged;
  final String hintText;
  final Color? backgroundColor;

  const CustomSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    required this.hintText,
    this.backgroundColor,
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
        fillColor: widget.backgroundColor ??
            context.colors.secondaryContainer.opaque(0.5, iReallyMeanIt: true),
        prefixIcon: const Icon(IconlyLight.search),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.multiplyRadius()),
          borderSide: BorderSide(
            color: context.colors.secondaryContainer,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.multiplyRadius()),
          borderSide: BorderSide(
            color: context.colors.secondaryContainer,
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
  final String? label;
  final Function(double value) onChanged;
  final Function(double value)? onChangedEnd;

  const CustomSliderTile({
    super.key,
    required this.icon,
    this.label,
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
                AnymexIcon(icon, size: 30, color: context.colors.primary),
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
                          color: context.colors.onSurface,
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
                              .opaque(0.6, iReallyMeanIt: true),
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
                    child: AnymeXSliderM3(
                      focusNode: FocusNode(
                          canRequestFocus: false, skipTraversal: true),
                      value: double.parse(sliderValue.toStringAsFixed(1)),
                      onChanged: onChanged,
                      max: max,
                      min: min,
                      label: label ?? sliderValue.toInt().toString(),
                      onChangeEnd: onChangedEnd,
                      divisions: divisions?.toInt() ?? (max * 10).toInt(),
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
        selectTabs:
            availableTypes.map((itemType) => _getTypeLabel(itemType)).toList(),
        selectedIndex: currentIndex,
        height: 52,
        icons:
            availableTypes.map((itemType) => _getTypeIcon(itemType)).toList(),
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
