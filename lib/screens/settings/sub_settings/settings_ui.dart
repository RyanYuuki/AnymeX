import 'dart:io';

import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/screens/settings/sub_settings/card_customizer_page.dart';
import 'package:anymex/screens/settings/sub_settings/settings_ui_components.dart';
import 'package:anymex/screens/settings/sub_settings/settings_ui_details.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconsax/iconsax.dart';

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
      case 'bottomNavBarMargin':
        settings.bottomNavBarMargin = value;
        break;
      case 'animation':
        settings.animationDuration = value.toInt();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnymeXScaffold(
      showHeader: true,
      headerTitle: 'Interface & Layout',
      body: Builder(
          builder: (ctx) => SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    16.0, AnymeXHeaderScope.of(ctx), 16.0, 30.0),
                child: Obx(
                  () => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnymeXSectionBuilder(
                        title: 'Interface Styling',
                        children: [
                          AnymeXTile(
                            icon: HugeIcons.strokeRoundedShapes,
                            title: 'UI Components',
                            subtitle:
                                'Customize history card, carousel & nav bar styles',
                            onTap: () =>
                                navigate(() => const SettingsUiComponents()),
                          ),
                          AnymeXTile(
                            icon: Icons.tune_rounded,
                            title: 'Card Customizer',
                            subtitle:
                                'Customize carousel card styles, geometry, and layout',
                            onTap: () =>
                                navigate(() => const CardCustomizerPage()),
                          ),
                          AnymeXTile(
                            icon: HugeIcons.strokeRoundedPlaySquare,
                            title: 'Details Page',
                            subtitle:
                                'Configure poster blur, scope, tint & backdrop source',
                            onTap: () =>
                                navigate(() => const SettingsUiDetails()),
                          ),
                        ],
                      ),
                      AnymeXSectionBuilder(
                        title: 'Navigation & Home Layout',
                        children: [
                          AnymeXTile.pills<bool>(
                            icon: Icons.view_sidebar_rounded,
                            title: 'Nav Bar Layout',
                            value: settings.useLegacyNavbar,
                            options: const [false, true],
                            optionLabelTransformer: (isLegacy) =>
                                isLegacy ? 'Legacy' : 'Modern',
                            optionDescriptionTransformer: (isLegacy) => isLegacy
                                ? 'Simple direct tabs for Anime, Manga, and Novels.'
                                : 'Floating category switcher with a dedicated History tab.',
                            onChanged: (isLegacy) {
                              settings.useLegacyNavbar = isLegacy;
                            },
                          ),
                          AnymeXTile(
                            icon: Icons.reorder_rounded,
                            title: 'Reorder Navigation Tabs',
                            subtitle:
                                'Drag and drop to reorder navigation bar tabs',
                            onTap: () => _showReorderTabsDialog(context),
                          ),
                          AnymeXTile.toggle(
                            icon: Icons.colorize,
                            title: "Translucent Nav",
                            subtitle: "Enable translucent navigation bar",
                            value: settings.transculentBar,
                            onChanged: (val) {
                              settings.transculentBar = val;
                            },
                          ),
                          PlatformBuilder(
                            androidBuilder: AnymeXTile.slider(
                              icon: Icons.margin_rounded,
                              title: 'Bottom Nav Bar Margin',
                              subtitle:
                                  'Adjust horizontal margin of bottom navigation bar',
                              value: settings.bottomNavBarMargin,
                              min: 0,
                              max: 100,
                              divisions: 100,
                              onChanged: (value) => handleSliderChange(
                                  'bottomNavBarMargin', value),
                            ),
                            desktopBuilder: AnymeXTile.slider(
                              icon: Icons.margin_rounded,
                              title: 'Bottom Nav Bar Margin',
                              subtitle:
                                  'Adjust bottom bar margin (media details page only)',
                              value: settings.bottomNavBarMargin,
                              min: 0,
                              max: 100,
                              divisions: 100,
                              onChanged: (value) => handleSliderChange(
                                  'bottomNavBarMargin', value),
                            ),
                          ),
                          AnymeXTile.toggle(
                            icon: Icons.view_headline_rounded,
                            title: "Use Legacy Header",
                            subtitle:
                                "Enable classic simple header style on home screens",
                            value: settings.useLegacyHeader,
                            onChanged: (val) {
                              settings.useLegacyHeader = val;
                            },
                          ),
                          AnymeXTile.toggle(
                            icon: Icons.play_circle_outline_rounded,
                            title: 'Show Continue Watching on Home',
                            subtitle:
                                'Display a continue watching bar above the bottom navigation bar on home',
                            value: settings.showHomeContinueWatching.value,
                            onChanged: (e) {
                              settings.saveShowHomeContinueWatching(e);
                            },
                          ),
                        ],
                      ),
                      AnymeXSectionBuilder(
                        title: 'Motion & Display',
                        children: [
                          AnymeXTile.toggle(
                            icon: HugeIcons.strokeRoundedBounceRight,
                            title: "Enable Animation",
                            subtitle:
                                "Enable animation on carousels for smooth motion",
                            value: settings.enableAnimation,
                            onChanged: (val) {
                              settings.enableAnimation = val;
                            },
                          ),
                          if (Platform.isAndroid || Platform.isIOS)
                            AnymeXTile.toggle(
                              icon: Icons.fullscreen_rounded,
                              title: "Immersive Mode",
                              subtitle:
                                  "Hide system status and navigation bars",
                              value: settings.enableImmersiveMode,
                              onChanged: (val) {
                                settings.enableImmersiveMode = val;
                              },
                            ),
                        ],
                      ),
                      AnymeXSectionBuilder(
                        title: 'Visual Effects & Tuning',
                        children: [
                          AnymeXTile.slider(
                            icon: HugeIcons.strokeRoundedLighthouse,
                            title: "Glow Multiplier",
                            subtitle: "Adjust element glow intensity",
                            value: settings.glowMultiplier,
                            min: 0,
                            max: 5.0,
                            onChanged: (value) =>
                                handleSliderChange('glowMultiplier', value),
                          ),
                          AnymeXTile.slider(
                            icon: HugeIcons.strokeRoundedRadius,
                            title: "Radius Multiplier",
                            subtitle: "Adjust corner radius of elements",
                            value: settings.radiusMultiplier,
                            min: 0,
                            max: 3.0,
                            onChanged: (value) =>
                                handleSliderChange('radiusMultiplier', value),
                          ),
                          AnymeXTile.slider(
                            icon: HugeIcons.strokeRoundedRadius,
                            title: "Blur Multiplier",
                            subtitle: "Adjust glow blur intensity",
                            value: settings.blurMultiplier,
                            min: 0,
                            max: 5.0,
                            onChanged: (value) =>
                                handleSliderChange('blurMultiplier', value),
                          ),
                          AnymeXTile.slider(
                            icon: HugeIcons.strokeRoundedRadius,
                            title: "Card Roundness",
                            subtitle: "Adjust roundness of all media cards",
                            value: settings.cardRoundness,
                            min: 0,
                            max: 5.0,
                            onChanged: (value) =>
                                handleSliderChange('cardRoundness', value),
                          ),
                          AnymeXTile.slider(
                            icon: HugeIcons.strokeRoundedRadius,
                            title: "Card Animation Duration",
                            subtitle: "Adjust card animation speed",
                            value: settings.animationDuration.toDouble(),
                            min: 0,
                            max: 1000,
                            divisions: 10,
                            valueTransformer: (v) => "${v.toInt()}ms",
                            onChanged: (value) =>
                                handleSliderChange('animation', value),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
    );
  }

  void _showReorderTabsDialog(BuildContext context) {
    final isSimkl =
        Get.find<ServiceHandler>().serviceType.value == ServicesType.simkl;
    final isLegacy = settings.useLegacyNavbar;
    final allPossibleTabs = isLegacy
        ? [
            'Home',
            'Anime',
            'Manga',
            'Novel',
            'Library',
            'Stats',
            'Extensions'
          ]
        : [
            'Home',
            'Discover',
            'Library',
            'History',
            'Stats',
            'Extensions'
          ];
    final visibleTabs = settings.navigationTabOrder
        .where((t) => allPossibleTabs.contains(t))
        .toList();

    final hiddenTabs =
        allPossibleTabs.where((t) => !visibleTabs.contains(t)).toList();

    const tabIcons = {
      'Home': Icons.home_rounded,
      'Discover': Iconsax.discover_13,
      'Anime': Icons.movie_rounded,
      'Manga': Icons.menu_book_rounded,
      'Novel': Icons.auto_stories_rounded,
      'Library': Icons.video_library_rounded,
      'History': Iconsax.clock,
      'Stats': IconlyBold.chart,
      'Extensions': Icons.extension_rounded,
    };

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);

            return AnymeXDialog(
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
                        child: AnymeXText(
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
                          child: AnymeXText('No visible tabs'),
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
                                final t =
                                    Curves.easeOut.transform(animation.value);
                                return Transform.scale(
                                  scale: 1.0 + (0.03 * t),
                                  child: Material(
                                    color: Colors.transparent,
                                    elevation: 6 * t,
                                    borderRadius: BorderRadius.circular(14),
                                    shadowColor: theme.colorScheme.primary
                                        .withOpacity(0.3),
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
                                contentPadding:
                                    const EdgeInsets.only(left: 12, right: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                leading: Container(
                                  width: 32,
                                  height: 32,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: AnymeXText(
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
                                    AnymeXText(
                                      isSimkl
                                          ? (tab == 'Anime'
                                              ? 'Movies'
                                              : (tab == 'Manga'
                                                  ? 'Series'
                                                  : tab))
                                          : tab,
                                      variant: TextVariant.semiBold,
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                          Icons.visibility_off_rounded,
                                          size: 20),
                                      color: theme.colorScheme.error,
                                      onPressed: () {
                                        if (visibleTabs.length <= 2) {
                                          snackBar(
                                              'At least 2 tabs must remain visible!');
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
                                        color: theme
                                            .colorScheme.onSurfaceVariant
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
                        child: AnymeXText(
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
                          child: AnymeXText(
                            'No hidden tabs',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withOpacity(0.6),
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
                                color: theme.colorScheme.surfaceContainerHigh
                                    .withOpacity(0.5),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: ListTile(
                                contentPadding:
                                    const EdgeInsets.only(left: 12, right: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                title: Row(
                                  children: [
                                    Icon(
                                      tabIcons[tab] ?? Icons.circle_outlined,
                                      size: 18,
                                      color: theme.colorScheme.onSurfaceVariant
                                          .withOpacity(0.6),
                                    ),
                                    const SizedBox(width: 10),
                                    AnymeXText(
                                      isSimkl
                                          ? (tab == 'Anime'
                                              ? 'Movies'
                                              : (tab == 'Manga'
                                                  ? 'Series'
                                                  : tab))
                                          : tab,
                                      variant: TextVariant.semiBold,
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.6),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.visibility_rounded,
                                      size: 20),
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
