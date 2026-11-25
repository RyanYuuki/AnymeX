import 'package:anymex/l10n/l10n_extension.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/library/widgets/history_model.dart';
import 'package:anymex/screens/settings/widgets/history_card_gate.dart';
import 'package:anymex/screens/settings/widgets/history_card_selector.dart';
import 'package:anymex/screens/settings/widgets/navbar_selector.dart';
import 'package:anymex/screens/settings/widgets/style_picker_section.dart';
import 'package:anymex/utils/fallback/fallback_anime.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile_builder.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/common/carousel/carousel_style_registry.dart';
import 'package:anymex/widgets/common/carousel/carousel_types.dart';
import 'package:anymex/widgets/common/navbar.dart';
import 'package:anymex/widgets/common/navbar/navbar_registry.dart';
import 'package:anymex/widgets/common/navbar/navbar_styles.dart';
import 'package:anymex/widgets/common/tile_icon_shapes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class SettingsUiComponents extends StatefulWidget {
  const SettingsUiComponents({super.key});

  @override
  State<SettingsUiComponents> createState() => _SettingsUiComponentsState();
}

class _SettingsUiComponentsState extends State<SettingsUiComponents> {
  final settings = Get.find<Settings>();

  List<Media> get _sampleHeroMedia => trendingAnimes.take(5).toList();
  List<HistoryModel> get _sampleHistoryCards =>
      HistoryCardSelector.sampleDataList;
  List<NavItem> get _navPreviewItems => NavBarStyleSelector.previewItems;

  @override
  void initState() {
    super.initState();
    registerBuiltInNavBarStyles();
  }

  Widget _buildHistoryCardStyleSection(BuildContext context, bool desktop) {
    final cardWidth = desktop ? 360.0 : 300.0;

    return StylePickerSection(
      icon: Iconsax.clock,
      title: context.l10n.historyCard,
      itemCount: HistoryCardStyle.values.length,
      appliedIndex: settings.historyCardStyle,
      labelFor: (i) => HistoryCardStyle.values[i].displayName,
      descriptionFor: (i) => HistoryCardStyle.values[i].description,
      previewBuilder: (i) {
        final style = HistoryCardStyle.values[i];
        return SizedBox(
          height: getHistoryCardHeight(style, context),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _sampleHistoryCards.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) => SizedBox(
              width: cardWidth,
              child: HistoryCardGate(
                data: _sampleHistoryCards[index],
                cardStyle: style,
              ),
            ),
          ),
        );
      },
      onApply: (i) => settings.historyCardStyle = i,
    );
  }

  Widget _buildCarouselStyleSection(BuildContext context) {
    return StylePickerSection(
      icon: Icons.view_carousel_rounded,
      title: context.l10n.carousel,
      itemCount: CarouselStyleRegistry.styles.length,
      appliedIndex:
          CarouselStyleRegistry.normalizeIndex(settings.carouselStyle),
      labelFor: (i) => CarouselStyleRegistry.styles[i].name,
      descriptionFor: (i) => CarouselStyleRegistry.styles[i].description,
      previewBuilder: (i) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CarouselStyleRegistry.build(
          selectedIndex: i,
          data: _sampleHeroMedia,
          carouselType: CarouselType.anime,
        ),
      ),
      onApply: (i) => settings.carouselStyle = i,
    );
  }

  Widget _buildNavBarStyleSection(BuildContext context) {
    return StylePickerSection(
      icon: Icons.navigation_rounded,
      title: context.l10n.navBar,
      itemCount: NavStyleVariant.values.length,
      appliedIndex: settings.navBarStyle,
      labelFor: (i) =>
          NavBarRegistry.getByIndex(NavStyleVariant.values[i].index)
              .displayName,
      descriptionFor: (i) =>
          NavBarRegistry.getByIndex(NavStyleVariant.values[i].index)
              .description,
      previewBuilder: (i) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: NavBarRegistry.buildByIndex(
          context: context,
          index: NavStyleVariant.values[i].index,
          props: NavBarProps(
            items: _navPreviewItems,
            currentIndex: 0,
            isDesktop: false,
          ),
        ),
      ),
      onApply: (i) => settings.navBarStyle = NavStyleVariant.values[i].index,
    );
  }

  Widget _buildTileStyleSection(BuildContext context) {
    final sampleItems = [
      (
        title: context.l10n.labelAppearance,
        subtitle: context.l10n.themeDarkModeLayoutStyling,
        icon: Icons.palette_outlined,
      ),
      (
        title: context.l10n.playerControls,
        subtitle: context.l10n.gesturesSubtitlesVideoSettings,
        icon: Icons.play_circle_outline_rounded,
      ),
    ];

    const labels = ['Classic', 'M3 Expressive'];
    const descriptions = [
      'Original AnymeX borderless list tiles',
      'Material 3 Expressive rounded tiles with circular icons, bold type, and connected corners',
    ];

    return StylePickerSection(
      icon: Icons.view_agenda_rounded,
      title: context.l10n.settingsTiles,
      itemCount: 2,
      appliedIndex: settings.tileStyle,
      labelFor: (i) => labels[i],
      descriptionFor: (i) => descriptions[i],
      previewBuilder: (i) => AnymeXTileBuilder(
        items: sampleItems,
        getTitle: (item) => item.title,
        getSubtitle: (item) => item.subtitle,
        getIcon: (item) => item.icon,
        showChevron: (_) => true,
        isSelection: false,
        style: i == 1 ? TileStyle.modern : TileStyle.classic,
        onItemPressed: (_) {},
      ),
      onApply: (i) => settings.tileStyle = i,
    );
  }

  void _showTileIconShapeDialog(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width > 600;

    AnymeXDialog(
      title: context.l10n.tileIconShapes,
      showCancelButton: false,
      confirmText: context.l10n.done,
      width: desktop ? 520.0 : MediaQuery.sizeOf(context).width * 0.92,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      onConfirm: () {},
      contentWidget: Obx(() {
        final currentShape = settings.tileIconShape;
        final currentTileStyle = settings.tileStyle == 1
            ? TileStyle.modern
            : TileStyle.classic;

        return AnymeXSectionBuilder(
          margin: EdgeInsets.zero,
          style: currentTileStyle,
          children: List.generate(totalTileIconShapes, (i) {
            final isSelected = currentShape == i;
            return AnymeXTile.radio(
              icon: getTileIconShapeIcon(i),
              iconShape: getTileIconShapeKind(i),
              title: getTileIconShapeName(i),
              subtitle: getTileIconShapeDescription(i),
              selected: isSelected,
              style: currentTileStyle,
              onTap: () {
                settings.tileIconShape = i;
              },
            );
          }),
        );
      }),
    ).show(context);
  }

  Widget _buildTileIconShapeSection(BuildContext context) {
    final colors = context.colors;
    final currentTileStyle = settings.tileStyle == 1
        ? TileStyle.modern
        : TileStyle.classic;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: AnymeXSectionBuilder(
        title: context.l10n.tilePrefixIconShape,
        style: currentTileStyle,
        children: [
          AnymeXTile(
            icon: getTileIconShapeIcon(settings.tileIconShape),
            iconShape: getTileIconShapeKind(settings.tileIconShape),
            title: context.l10n.tileIconShapesLower,
            subtitle: getTileIconShapeName(settings.tileIconShape),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: colors.primary.opaque(0.12, iReallyMeanIt: true),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnymeXText(
                    getTileIconShapeName(settings.tileIconShape),
                    size: 11.5,
                    variant: TextVariant.semiBold,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: colors.primary,
                  ),
                ],
              ),
            ),
            style: currentTileStyle,
            onTap: () => _showTileIconShapeDialog(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width > 600;

    return AnymeXScaffold(
      showHeader: true,
      headerTitle: context.l10n.uiComponents,
      body: Builder(
        builder: (ctx) => SingleChildScrollView(
          padding:
              EdgeInsets.fromLTRB(16.0, AnymeXHeaderScope.of(ctx), 16.0, 30.0),
          child: Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHistoryCardStyleSection(context, desktop),
                _buildCarouselStyleSection(context),
                _buildNavBarStyleSection(context),
                _buildTileStyleSection(context),
                _buildTileIconShapeSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
