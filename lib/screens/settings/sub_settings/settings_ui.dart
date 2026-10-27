import 'dart:io';

import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/library/widgets/history_model.dart';
import 'package:anymex/screens/settings/widgets/history_card_gate.dart';
import 'package:anymex/screens/settings/widgets/history_card_selector.dart';
import 'package:anymex/screens/settings/widgets/navbar_selector.dart';
import 'package:anymex/utils/external_font_loader.dart';
import 'package:anymex/utils/fallback/fallback_anime.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile_builder.dart';
import 'package:anymex/widgets/common/anymex_pills.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/common/cards/card_gate.dart';
import 'package:anymex/widgets/common/cards/media_card_registry.dart';
import 'package:anymex/widgets/common/cards/media_cards.dart';
import 'package:anymex/widgets/common/carousel/carousel_style_registry.dart';
import 'package:anymex/widgets/common/carousel/carousel_types.dart';
import 'package:anymex/widgets/common/navbar.dart';
import 'package:anymex/widgets/common/navbar/navbar_registry.dart';
import 'package:anymex/widgets/common/navbar/navbar_styles.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:file_picker/file_picker.dart';
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

  List<Media> get _sampleHeroMedia => trendingAnimes.take(5).toList();
  late final _sampleMediaCards = convertData(trendingAnimes).take(5).toList();
  List<HistoryModel> get _sampleHistoryCards =>
      HistoryCardSelector.sampleDataList;
  List<NavItem> get _navPreviewItems => NavBarStyleSelector.previewItems;

  @override
  void initState() {
    super.initState();
    registerBuiltInMediaCardStyles();
    registerBuiltInNavBarStyles();
  }

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

  Widget _buildCustomizerSection({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String currentStyleName,
    required String description,
    required Widget previewWidget,
    required List<PillItem> pills,
  }) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainer.opaque(0.45, iReallyMeanIt: true),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colors.onSurface.opaque(0.08, iReallyMeanIt: true),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.primary.opaque(0.12, iReallyMeanIt: true),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: colors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnymeXText(
                      title,
                      size: 15,
                      variant: TextVariant.bold,
                    ),
                    const SizedBox(height: 2),
                    AnymeXText(
                      description,
                      size: 11.5,
                      color: colors.onSurface.opaque(0.6, iReallyMeanIt: true),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.primary.opaque(0.12, iReallyMeanIt: true),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colors.primary.opaque(0.25, iReallyMeanIt: true),
                    width: 0.8,
                  ),
                ),
                child: AnymeXText(
                  currentStyleName,
                  size: 11,
                  variant: TextVariant.semiBold,
                  color: colors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Iconsax.eye,
                  size: 12,
                  color: colors.onSurface.opaque(0.5, iReallyMeanIt: true)),
              const SizedBox(width: 6),
              AnymeXText(
                'PREVIEW',
                size: 10.5,
                variant: TextVariant.bold,
                color: colors.onSurface.opaque(0.5, iReallyMeanIt: true),
              ),
            ],
          ),
          const SizedBox(height: 8),
          previewWidget,
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Iconsax.category,
                  size: 12,
                  color: colors.onSurface.opaque(0.5, iReallyMeanIt: true)),
              const SizedBox(width: 6),
              AnymeXText(
                'STYLE',
                size: 10.5,
                variant: TextVariant.bold,
                color: colors.onSurface.opaque(0.5, iReallyMeanIt: true),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AnymeXPills(
            wrap: true,
            items: pills,
          ),
        ],
      ),
    );
  }

  Widget _buildCardStyleSection(BuildContext context, bool desktop) {
    final currentStyle = MediaCardRegistry.getByIndex(settings.cardStyle);
    return _buildCustomizerSection(
      context: context,
      icon: Iconsax.card5,
      title: 'Card Style',
      currentStyleName: currentStyle.displayName,
      description: currentStyle.description,
      previewWidget: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: SizedBox(
          height: getCardHeight(settings.cardStyle, desktop),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: _sampleMediaCards.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              return MediaCardGate(
                cardStyleIndex: settings.cardStyle,
                itemData: _sampleMediaCards[index],
                tag: 'preview-card-$index',
                variant: DataVariant.regular,
                type: ItemType.anime,
              );
            },
          ),
        ),
      ),
      pills: List.generate(MediaCardRegistry.styles.length, (index) {
        final style = MediaCardRegistry.styles[index];
        return PillItem(
          label: style.displayName,
          isSelected: settings.cardStyle == index,
          onTap: () {
            settings.cardStyle = index;
          },
        );
      }),
    );
  }

  Widget _buildHistoryCardStyleSection(BuildContext context, bool desktop) {
    final currentStyle = HistoryCardStyle.values[settings.historyCardStyle];
    return _buildCustomizerSection(
      context: context,
      icon: Iconsax.clock,
      title: 'History Card Style',
      currentStyleName: currentStyle.displayName,
      description: currentStyle.description,
      previewWidget: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: SizedBox(
          height: getHistoryCardHeight(currentStyle, context),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: _sampleHistoryCards.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              return SizedBox(
                width: desktop ? 360 : 300,
                child: HistoryCardGate(
                  data: _sampleHistoryCards[index],
                  cardStyle: currentStyle,
                ),
              );
            },
          ),
        ),
      ),
      pills: List.generate(HistoryCardStyle.values.length, (index) {
        final style = HistoryCardStyle.values[index];
        return PillItem(
          label: style.displayName,
          isSelected: settings.historyCardStyle == index,
          onTap: () {
            settings.historyCardStyle = index;
          },
        );
      }),
    );
  }

  Widget _buildCarouselStyleSection(BuildContext context) {
    final currentStyle = CarouselStyleRegistry.byIndex(settings.carouselStyle);
    return _buildCustomizerSection(
      context: context,
      icon: Icons.view_carousel_rounded,
      title: 'Carousel Style',
      currentStyleName: currentStyle.name,
      description: currentStyle.description,
      previewWidget: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IgnorePointer(
          child: CarouselStyleRegistry.build(
            selectedIndex: settings.carouselStyle,
            data: _sampleHeroMedia,
            carouselType: CarouselType.anime,
          ),
        ),
      ),
      pills: List.generate(CarouselStyleRegistry.styles.length, (index) {
        final style = CarouselStyleRegistry.styles[index];
        return PillItem(
          label: style.name,
          isSelected:
              CarouselStyleRegistry.normalizeIndex(settings.carouselStyle) ==
                  index,
          onTap: () {
            settings.carouselStyle = index;
          },
        );
      }),
    );
  }

  Widget _buildNavBarStyleSection(BuildContext context) {
    final currentStyle = NavBarRegistry.getByIndex(settings.navBarStyle);
    return _buildCustomizerSection(
      context: context,
      icon: Icons.navigation_rounded,
      title: 'Nav Bar Style',
      currentStyleName: currentStyle.displayName,
      description: currentStyle.description,
      previewWidget: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        child: NavBarRegistry.buildByIndex(
          context: context,
          index: settings.navBarStyle,
          props: NavBarProps(
            items: _navPreviewItems,
            currentIndex: 0,
            isDesktop: false,
          ),
        ),
      ),
      pills: List.generate(NavStyleVariant.values.length, (index) {
        final style = NavStyleVariant.values[index];
        return PillItem(
          label: NavBarRegistry.getByIndex(style.index).displayName,
          isSelected: settings.navBarStyle == style.index,
          onTap: () {
            settings.navBarStyle = style.index;
          },
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width > 600;

    return AnymeXScaffold(
      showHeader: true,
      headerTitle: 'UI Settings',
      body: Builder(
          builder: (ctx) => SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    16.0, AnymeXHeaderScope.of(ctx), 16.0, 30.0),
                child: Obx(
                  () => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 12, bottom: 8),
                        child: AnymeXText(
                          'LAYOUT & STYLES',
                          size: 11.5,
                          variant: TextVariant.bold,
                          color: context.colors.onSurface
                              .opaque(0.45, iReallyMeanIt: true),
                        ),
                      ),
                      _buildCardStyleSection(context, desktop),
                      _buildHistoryCardStyleSection(context, desktop),
                      _buildCarouselStyleSection(context),
                      _buildNavBarStyleSection(context),
                      AnymeXSectionBuilder(
                        title: 'Navigation Layout',
                        children: [
                          AnymeXTile(
                            onTap: () => _showNavBarModeSwitcher(context),
                            icon: Icons.view_sidebar_rounded,
                            title: 'Nav Bar Layout',
                            subtitle: settings.useLegacyNavbar
                                ? 'Legacy (Direct Category Tabs)'
                                : 'Modern (Discover & Floating Selector)',
                          ),
                        ],
                      ),
                      AnymeXSectionBuilder(
                        title: 'Common',
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
                          AnymeXTile.toggle(
                            icon: Icons.colorize,
                            title: "Translucent Nav",
                            subtitle: "Enable translucent navigation bar",
                            value: settings.transculentBar,
                            onChanged: (val) {
                              settings.transculentBar = val;
                            },
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
                          AnymeXTile(
                            icon: Icons.font_download_rounded,
                            title: 'Font Family',
                            subtitle: settings.appFontFamily.isEmpty
                                ? 'Default (Linotte)'
                                : settings.appFontFamily,
                            onTap: () => _showFontFamilyPicker(context),
                          ),
                          AnymeXTile(
                            icon: Icons.reorder_rounded,
                            title: 'Reorder Navigation Tabs',
                            subtitle:
                                'Drag and drop to reorder navigation bar tabs',
                            onTap: () => _showReorderTabsDialog(context),
                          ),
                          PlatformBuilder(
                            androidBuilder: AnymeXTile.slider(
                              icon: Icons.margin_rounded,
                              title: 'Bottom Nav Bar Margin',
                              subtitle: 'Adjust horizontal margin of bottom navigation bar',
                              value: settings.bottomNavBarMargin,
                              min: 0,
                              max: 100,
                              divisions: 100,
                              onChanged: (value) => handleSliderChange('bottomNavBarMargin', value),
                            ),
                            desktopBuilder: AnymeXTile.slider(
                              icon: Icons.margin_rounded,
                              title: 'Bottom Nav Bar Margin',
                              subtitle: 'Adjust bottom bar margin (media details page only)',
                              value: settings.bottomNavBarMargin,
                              min: 0,
                              max: 100,
                              divisions: 100,
                              onChanged: (value) => handleSliderChange('bottomNavBarMargin', value),
                            ),
                          ),
                        ],
                      ),
                      AnymeXSectionBuilder(
                        title: 'Extras',
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

  void _showNavBarModeSwitcher(BuildContext context) {
    AnymeXDialog(
      title: 'Nav Bar Layout',
      showCancelButton: false,
      confirmText: 'Close',
      onConfirm: () {},
      contentWidget: SizedBox(
        width: double.maxFinite,
        child: Obx(() => AnymeXTileBuilder<bool>(
              items: const [true, false],
              selectedItem: settings.useLegacyNavbar,
              getTitle: (isLegacy) =>
                  isLegacy ? 'Legacy Nav Bar' : 'Modern Nav Bar',
              getSubtitle: (isLegacy) => isLegacy
                  ? 'Direct tabs for Anime, Manga, and Novels. History accessed from Library.'
                  : 'Discover and Library tabs with floating media mode selector, separate History tab.',
              onItemPressed: (isLegacy) {
                settings.useLegacyNavbar = isLegacy;
                Navigator.pop(context);
                setState(() {});
              },
            )),
      ),
    ).show(context);
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

  void _showFontFamilyPicker(BuildContext context) {
    AnymeXDialog(
      title: 'Font Family',
      showCancelButton: false,
      confirmText: 'Close',
      onConfirm: () {},
      contentWidget: _buildFontFamilyPickerContent(context),
    ).show(context);
  }

  Widget _buildFontFamilyPickerContent(BuildContext context) {
    final downloadingFonts = <String>{};
    final downloadedStatus = <String, bool>{};
    List<String> customFonts = [];
    bool isInit = false;

    return StatefulBuilder(
      builder: (dialogContext, setDialogState) {
        if (!isInit) {
          isInit = true;
          Future.microtask(() async {
            for (final font in ExternalFontLoader.appFonts) {
              final isDownloaded =
                  await ExternalFontLoader.isAppFontDownloaded(font.name);
              downloadedStatus[font.name] = isDownloaded;
            }
            final customs = await ExternalFontLoader.getCustomFontNames();
            customFonts = customs;
            setDialogState(() {});
          });
        }

        final theme = Theme.of(context);
        final currentFont = settings.appFontFamily;

        return Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxHeight: 450),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnymeXSectionBuilder(
                  title: 'Default',
                  children: [
                    AnymeXTile(
                      title: 'Linotte (Default)',
                      subtitle: 'The quick brown fox jumps over the lazy dog',
                      titleStyle: const TextStyle(
                        fontFamily: 'Linotte',
                        fontWeight: FontWeight.w600,
                      ),
                      subtitleStyle: const TextStyle(
                        fontFamily: 'Linotte',
                        fontSize: 11,
                      ),
                      showChevron: false,
                      trailing: SizedBox(
                        width: 24,
                        height: 24,
                        child: Center(
                          child: (currentFont.isEmpty || currentFont == 'Linotte')
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  size: 22,
                                  color: theme.colorScheme.primary,
                                )
                              : null,
                        ),
                      ),
                      onTap: () {
                        settings.appFontFamily = '';
                        setDialogState(() {});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                AnymeXSectionBuilder(
                  title: 'App Fonts',
                  children: ExternalFontLoader.appFonts.map((font) {
                    final isDownloaded = downloadedStatus[font.name] ?? false;
                    final isDownloading = downloadingFonts.contains(font.name);
                    final isSelected = currentFont == font.name;

                    Widget trailingWidget;
                    if (isDownloading) {
                      trailingWidget = const SizedBox(
                        key: ValueKey('downloading'),
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    } else if (isDownloaded) {
                      if (isSelected) {
                        trailingWidget = Icon(
                          key: const ValueKey('selected'),
                          Icons.check_circle_rounded,
                          size: 22,
                          color: theme.colorScheme.primary,
                        );
                      } else {
                        trailingWidget = const SizedBox.shrink(
                          key: ValueKey('unselected'),
                        );
                      }
                    } else {
                      trailingWidget = IconButton(
                        key: const ValueKey('download'),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        iconSize: 22,
                        icon: const Icon(Icons.download_rounded),
                        onPressed: () async {
                          downloadingFonts.add(font.name);
                          setDialogState(() {});
                          final success =
                              await ExternalFontLoader.downloadAppFont(
                                  font.name);
                          downloadingFonts.remove(font.name);
                          if (success) {
                            downloadedStatus[font.name] = true;
                            settings.appFontFamily = font.name;
                            snackBar('Downloaded and applied ${font.name}');
                          } else {
                            snackBar('Failed to download ${font.name}');
                          }
                          setDialogState(() {});
                        },
                      );
                    }

                    return AnymeXTile(
                      title: font.label,
                      subtitle: 'The quick brown fox jumps over the lazy dog',
                      titleStyle: TextStyle(
                        fontFamily: isDownloaded ? font.name : 'Linotte',
                        fontWeight: FontWeight.w600,
                      ),
                      subtitleStyle: TextStyle(
                        fontFamily: isDownloaded ? font.name : 'Linotte',
                        fontSize: 11,
                      ),
                      showChevron: false,
                      trailing: SizedBox(
                        width: 24,
                        height: 24,
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: trailingWidget,
                          ),
                        ),
                      ),
                      onTap: () async {
                        if (isDownloaded) {
                          settings.appFontFamily = font.name;
                          setDialogState(() {});
                        } else if (!isDownloading) {
                          downloadingFonts.add(font.name);
                          setDialogState(() {});
                          final success =
                              await ExternalFontLoader.downloadAppFont(font.name);
                          downloadingFonts.remove(font.name);
                          if (success) {
                            downloadedStatus[font.name] = true;
                            settings.appFontFamily = font.name;
                            snackBar('Downloaded and applied ${font.name}');
                          } else {
                            snackBar('Failed to download ${font.name}');
                          }
                          setDialogState(() {});
                        }
                      },
                    );
                  }).toList(),
                ),
                if (customFonts.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  AnymeXSectionBuilder(
                    title: 'Custom Fonts',
                    children: customFonts.map((customName) {
                      final isSelected = currentFont == customName;
                      return AnymeXTile(
                        title: customName,
                        subtitle: 'The quick brown fox jumps over the lazy dog',
                        titleStyle: TextStyle(
                          fontFamily: customName,
                          fontWeight: FontWeight.w600,
                        ),
                        subtitleStyle: TextStyle(
                          fontFamily: customName,
                          fontSize: 11,
                        ),
                        showChevron: false,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) ...[
                              Icon(
                                Icons.check_circle_rounded,
                                size: 22,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                            ],
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              iconSize: 22,
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                color: theme.colorScheme.error,
                              ),
                              onPressed: () async {
                                await ExternalFontLoader.deleteCustomFont(
                                    customName);
                                if (settings.appFontFamily == customName) {
                                  settings.appFontFamily = '';
                                }
                                customFonts =
                                    await ExternalFontLoader.getCustomFontNames();
                                setDialogState(() {});
                                snackBar('Deleted "$customName"');
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          settings.appFontFamily = customName;
                          setDialogState(() {});
                        },
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 10),
                AnymeXTile(
                  icon: Icons.upload_file_rounded,
                  title: 'Import Custom Font',
                  subtitle: 'Support .ttf and .otf files',
                  showChevron: false,
                  onTap: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['ttf', 'otf'],
                    );
                    if (result != null && result.files.single.path != null) {
                      final fontName = await ExternalFontLoader.importCustomFont(
                        result.files.single.path!,
                      );
                      if (fontName != null) {
                        settings.appFontFamily = fontName;
                        customFonts =
                            await ExternalFontLoader.getCustomFontNames();
                        setDialogState(() {});
                        snackBar('Imported font "$fontName"');
                      } else {
                        snackBar('Failed to load font file');
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

