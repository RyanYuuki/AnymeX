import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/screens/library/controller/library_controller.dart';
import 'package:anymex/screens/library/editor/list_editor.dart';
import 'package:anymex/widgets/common/anymex_pills.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/anymex_slider_m3.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tabbar.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_icon_wrapper.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
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
                AnymeXIcon(icon, size: 30, color: context.colors.primary),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnymeXText(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: context.colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 5),
                      AnymeXText(
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
                  AnymeXText(sliderValue.toInt() == 0
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
                  AnymeXText(max % 1 == 0
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


  Widget _buildSettingsButton(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => navigate(
          () => CustomListsEditor(type: controller.type.value)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.opaque(0.3, iReallyMeanIt: true),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colors.onSurface.opaque(0.08, iReallyMeanIt: true),
            width: 0.5,
          ),
        ),
        child: Icon(
          Iconsax.setting,
          size: 16,
          color: context.colors.onSurfaceVariant,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      child: Obx(() {
        final lists = controller.customLists;
        final selectedIndex = controller.selectedListIndex.value;
        final isUnified = General.unifiedLibrary.get<bool>(true);

        final pillItems = <PillItem>[];
        for (int i = 0; i < lists.length; i++) {
          final list = lists[i];
          final listName = list.listName ?? '';
          final itemCount = list.mediaIds?.length ?? 0;
          final isSelected = selectedIndex == i;

          if (!isUnified && itemCount == 0 && !isSelected) {
            continue;
          }

          pillItems.add(
            PillItem(
              label: '$listName ($itemCount)',
              isSelected: isSelected,
              onTap: () => controller.selectList(i),
            ),
          );
        }

        return Row(
          children: [
            _buildSettingsButton(context),
            const SizedBox(width: 8),
            Expanded(
              child: AnymeXPills(
                scrollPadding: EdgeInsets.zero,
                items: pillItems,
              ),
            ),
          ],
        );
      }),
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
              ? [ItemType.anime]
              : [ItemType.anime, ItemType.manga, ItemType.novel];

      final currentIndex = availableTypes.indexOf(controller.type.value);

      return AnymeXTabBar(
        selectTabs:
            availableTypes.map((itemType) => _getTypeLabel(itemType)).toList(),
        selectedIndex: currentIndex < 0 ? 0 : currentIndex,
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
      return 'Movies & Series';
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
