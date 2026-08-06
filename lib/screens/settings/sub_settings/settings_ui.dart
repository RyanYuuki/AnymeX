import 'dart:io';

import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/screens/settings/widgets/card_selector.dart';
import 'package:anymex/screens/settings/widgets/history_card_selector.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/custom_expansion_tile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconsax/iconsax.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/screens/other_features.dart';
import 'package:anymex/widgets/custom_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex/utils/theme_extensions.dart';

class SettingsUi extends StatefulWidget {
  const SettingsUi({super.key});

  @override
  State<SettingsUi> createState() => _SettingsUiState();
}

class _SettingsUiState extends State<SettingsUi> {
  final settings = Get.find<Settings>();

  void handleSliderChange(String property, double value) {
    switch (property) {
      case 'glowMultiplier':
        settings.glowMultiplier = value;
        break;
      case 'radiusMultiplier':
        settings.radiusMultiplier = value;
        break;
      case 'blurMultiplier':
        settings.blurMultiplier = value;
        break;
      case 'cardRoundness':
        settings.cardRoundness = value;
        break;
      case 'animation':
        settings.animationDuration = value.toInt();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Glow(
        child: Scaffold(
            body: Column(children: [
      const NestedHeader(title: 'UI'),
      Expanded(
        child: SingleChildScrollView(
          child: Padding(
              padding: const EdgeInsets.fromLTRB(15.0, 20.0, 15.0, 50),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(
                    () => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnymexExpansionTile(
                            title: 'Common',
                            initialExpanded: true,
                            content: Column(
                              children: [
                                CustomSwitchTile(
                                    icon: HugeIcons.strokeRoundedBounceRight,
                                    title: "Enable Animation",
                                    description:
                                        "Enable Animation on Carousels, Disable it to get smoother experience",
                                    switchValue: settings.enableAnimation,
                                    onChanged: (val) {
                                      settings.enableAnimation = val;
                                    }),
                                CustomSwitchTile(
                                    icon: Iconsax.image,
                                    title: "Enable Ken Burns",
                                    description:
                                        "Enable background animations on anime/manga posters",
                                    switchValue: settings.enablePosterKenBurns,
                                    onChanged: (val) {
                                      settings.enablePosterKenBurns = val;
                                    }),
                                CustomSwitchTile(
                                    icon: Icons.colorize,
                                    title: "Translucent Nav",
                                    description: "Enable translucent tab bar",
                                    switchValue: settings.transculentBar,
                                    onChanged: (val) {
                                      settings.transculentBar = val;
                                    }),
                                CustomSwitchTile(
                                    icon: Icons.view_headline_rounded,
                                    title: "Use Legacy Header",
                                    description:
                                        "Enable the classic simple header style on home screens",
                                    switchValue: settings.useLegacyHeader,
                                    onChanged: (val) {
                                      settings.useLegacyHeader = val;
                                    }),
                                if (Platform.isAndroid || Platform.isIOS)
                                  CustomSwitchTile(
                                      icon: Icons.fullscreen_rounded,
                                      title: "Immersive Mode",
                                      description:
                                          "Hide status bar and system navigation bar for an immersed view",
                                      switchValue: settings.enableImmersiveMode,
                                      onChanged: (val) {
                                        settings.enableImmersiveMode = val;
                                      }),
                                CustomTile(
                                  onTap: () => showCardStyleSwitcher(context),
                                  icon: Iconsax.card5,
                                  title: "Card Style",
                                  description: "Change card style",
                                ),
                                CustomTile(
                                  onTap: () =>
                                      showHistoryCardStyleSelector(context),
                                  icon: Iconsax.card5,
                                  title: "History Card Style",
                                  description: "Change history card style",
                                ),
                                CustomTile(
                                  icon: Icons.reorder_rounded,
                                  title: 'Reorder Navigation Tabs',
                                  description:
                                      'Drag and drop to reorder the main navigation tabs',
                                  onTap: () => _showReorderTabsDialog(context),
                                ),
                                10.height(),
                              ],
                            )),
                        AnymexExpansionTile(
                            title: 'Extras',
                            content: Column(
                              children: [
                                CustomSliderTile(
                                  icon: HugeIcons.strokeRoundedLighthouse,
                                  title: "Glow Multiplier",
                                  description:
                                      "Adjust the glow of all the elements",
                                  sliderValue: settings.glowMultiplier,
                                  onChanged: (value) => handleSliderChange(
                                      'glowMultiplier', value),
                                  max: 5.0,
                                ),
                                const SizedBox(height: 20),
                                CustomSliderTile(
                                  icon: HugeIcons.strokeRoundedRadius,
                                  title: "Radius Multiplier",
                                  description:
                                      "Adjust the radius of all the elements",
                                  sliderValue: settings.radiusMultiplier,
                                  onChanged: (value) => handleSliderChange(
                                      'radiusMultiplier', value),
                                  max: 3.0,
                                ),
                                const SizedBox(height: 20),
                                CustomSliderTile(
                                  icon: HugeIcons.strokeRoundedRadius,
                                  title: "Blur Multiplier",
                                  description:
                                      "Adjust the Glow Blur of all the elements",
                                  sliderValue: settings.blurMultiplier,
                                  onChanged: (value) => handleSliderChange(
                                      'blurMultiplier', value),
                                  max: 5.0,
                                ),
                                const SizedBox(height: 20),
                                CustomSliderTile(
                                  icon: HugeIcons.strokeRoundedRadius,
                                  title: "Card Roundness",
                                  description:
                                      "Adjust the Roundness of All Cards",
                                  sliderValue: settings.cardRoundness,
                                  onChanged: (value) => handleSliderChange(
                                      'cardRoundness', value),
                                  max: 5.0,
                                ),
                                const SizedBox(height: 20),
                                CustomSliderTile(
                                  icon: HugeIcons.strokeRoundedRadius,
                                  title: "Card Animation Duration",
                                  description:
                                      "Adjust the Animation of All Cards",
                                  sliderValue:
                                      settings.animationDuration.toDouble(),
                                  onChanged: (value) =>
                                      handleSliderChange('animation', value),
                                  max: 1000,
                                  divisions: 10,
                                ),
                              ],
                            )),
                      ],
                    ),
                  )
                ],
              )),
        ),
      ),
    ])));
  }

  void _showReorderTabsDialog(BuildContext context) {
    final isSimkl = Get.find<ServiceHandler>().serviceType.value == ServicesType.simkl;
    final allPossibleTabs = ['Home', 'Anime', 'Manga', 'Library', 'Novel', 'Extensions'];
    final visibleTabs = settings.navigationTabOrder
        .where((t) => allPossibleTabs.contains(t))
        .toList();

    final hiddenTabs = allPossibleTabs.where((t) => !visibleTabs.contains(t)).toList();

    const tabIcons = {
      'Home': Icons.home_rounded,
      'Anime': Icons.movie_rounded,
      'Manga': Icons.menu_book_rounded,
      'Novel': Icons.auto_stories_rounded,
      'Library': Icons.video_library_rounded,
      'Extensions': Icons.extension_rounded,
    };

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);

            return AnymexDialog(
              title: 'Reorder Navigation Tabs',
              contentWidget: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          'Visible Tabs',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (visibleTabs.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('No visible tabs'),
                        )
                      else
                        ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          buildDefaultDragHandles: false,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: visibleTabs.length,
                          onReorder: (oldIndex, newIndex) {
                            setDialogState(() {
                              if (newIndex > oldIndex) newIndex--;
                              final item = visibleTabs.removeAt(oldIndex);
                              visibleTabs.insert(newIndex, item);
                            });
                          },
                          proxyDecorator: (child, index, animation) {
                            return AnimatedBuilder(
                              animation: animation,
                              builder: (context, _) {
                                final t = Curves.easeOut.transform(animation.value);
                                return Transform.scale(
                                  scale: 1.0 + (0.03 * t),
                                  child: Material(
                                    color: Colors.transparent,
                                    elevation: 6 * t,
                                    borderRadius: BorderRadius.circular(14),
                                    shadowColor:
                                        theme.colorScheme.primary.withOpacity(0.3),
                                    child: child,
                                  ),
                                );
                              },
                              child: child,
                            );
                          },
                          itemBuilder: (context, i) {
                            final tab = visibleTabs[i];
                            return Container(
                              key: ValueKey(tab),
                              width: double.infinity,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.only(left: 12, right: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                leading: Container(
                                  width: 32,
                                  height: 32,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${i + 1}',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Icon(
                                      tabIcons[tab] ?? Icons.circle_outlined,
                                      size: 18,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 10),
                                    AnymexText(
                                      text: isSimkl ? (tab == 'Anime' ? 'Movies' : (tab == 'Manga' ? 'Series' : tab)) : tab,
                                      variant: TextVariant.semiBold,
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.visibility_off_rounded, size: 20),
                                      color: theme.colorScheme.error,
                                      onPressed: () {
                                        if (visibleTabs.length <= 2) {
                                          snackBar('At least 2 tabs must remain visible!');
                                          return;
                                        }
                                        setDialogState(() {
                                          visibleTabs.remove(tab);
                                          hiddenTabs.add(tab);
                                        });
                                      },
                                    ),
                                    ReorderableDragStartListener(
                                      index: i,
                                      child: Icon(
                                        Icons.drag_indicator_rounded,
                                        color: theme.colorScheme.onSurfaceVariant
                                            .withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          'Hidden Tabs',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (hiddenTabs.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'No hidden tabs',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                              fontSize: 13,
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: hiddenTabs.length,
                          itemBuilder: (context, i) {
                            final tab = hiddenTabs[i];
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHigh.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.only(left: 12, right: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                title: Row(
                                  children: [
                                    Icon(
                                      tabIcons[tab] ?? Icons.circle_outlined,
                                      size: 18,
                                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                                    ),
                                    const SizedBox(width: 10),
                                    AnymexText(
                                      text: isSimkl ? (tab == 'Anime' ? 'Movies' : (tab == 'Manga' ? 'Series' : tab)) : tab,
                                      variant: TextVariant.semiBold,
                                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.visibility_rounded, size: 20),
                                  color: theme.colorScheme.primary,
                                  onPressed: () {
                                    setDialogState(() {
                                      hiddenTabs.remove(tab);
                                      visibleTabs.add(tab);
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              confirmText: 'Save',
              onConfirm: () {
                settings.navigationTabOrder = visibleTabs;
                setState(() {});
              },
            );
          },
        );
      },
    );
  }
}
