import 'package:anymex/l10n/l10n_extension.dart';
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
                        title: context.l10n.interfaceStyling,
                        children: [
                          AnymeXTile(
                            icon: HugeIcons.strokeRoundedShapes,
                            title: context.l10n.uiComponents,
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
                            title: context.l10n.detailsPage,
                            subtitle:
                                context.l10n.configurePosterBlurScopeTintBackdrop,
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
                            title: context.l10n.navBarLayout,
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
                            title: context.l10n.translucentNav,
                            subtitle: context.l10n.enableTranslucentNavigationBar,
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
                            title: context.l10n.useLegacyHeader,
                            subtitle:
                                context.l10n.enableClassicSimpleHeaderStyleOn,
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
                              title: context.l10n.immersiveMode,
                              subtitle:
                                  context.l10n.hideSystemStatusAndNavigationBars,
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
                            title: context.l10n.glowMultiplier,
                            subtitle: context.l10n.adjustElementGlowIntensity,
                            value: settings.glowMultiplier,
                            min: 0,
                            max: 5.0,
                            onChanged: (value) =>
                                handleSliderChange('glowMultiplier', value),
                          ),
                          AnymeXTile.slider(
                            icon: HugeIcons.strokeRoundedRadius,
                            title: context.l10n.radiusMultiplier,
                            subtitle: context.l10n.adjustCornerRadiusOfElements,
                            value: settings.radiusMultiplier,
                            min: 0,
                            max: 3.0,
                            onChanged: (value) =>
                                handleSliderChange('radiusMultiplier', value),
                          ),
                          AnymeXTile.slider(
                            icon: HugeIcons.strokeRoundedRadius,
                            title: context.l10n.blurMultiplier,
                            subtitle: context.l10n.adjustGlowBlurIntensity,
                            value: settings.blurMultiplier,
                            min: 0,
                            max: 5.0,
                            onChanged: (value) =>
                                handleSliderChange('blurMultiplier', value),
                          ),
                          AnymeXTile.slider(
                            icon: HugeIcons.strokeRoundedRadius,
                            title: context.l10n.cardRoundness,
                            subtitle: context.l10n.adjustRoundnessOfAllMediaCards,
                            value: settings.cardRoundness,
                            min: 0,
                            max: 5.0,
                            onChanged: (value) =>
                                handleSliderChange('cardRoundness', value),
                          ),
                          AnymeXTile.slider(
                            icon: HugeIcons.strokeRoundedRadius,
                            title: context.l10n.cardAnimationDuration,
                            subtitle: context.l10n.adjustCardAnimationSpeed,
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
              title: context.l10n.reorderNavigationTabs,
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
                          context.l10n.visibleTabs,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (visibleTabs.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: AnymeXText(context.l10n.noVisibleTabs),
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
                                              context.l10n.atLeast2TabsMustRemain);
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
                          context.l10n.hiddenTabs,
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
                            context.l10n.noHiddenTabs,
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
              confirmText: context.l10n.save,
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
