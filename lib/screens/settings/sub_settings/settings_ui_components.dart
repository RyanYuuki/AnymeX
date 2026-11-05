import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/library/widgets/history_model.dart';
import 'package:anymex/screens/settings/widgets/history_card_gate.dart';
import 'package:anymex/screens/settings/widgets/history_card_selector.dart';
import 'package:anymex/screens/settings/widgets/navbar_selector.dart';
import 'package:anymex/utils/fallback/fallback_anime.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/common/anymex_pills.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/common/carousel/carousel_style_registry.dart';
import 'package:anymex/widgets/common/carousel/carousel_types.dart';
import 'package:anymex/widgets/common/navbar.dart';
import 'package:anymex/widgets/common/navbar/navbar_registry.dart';
import 'package:anymex/widgets/common/navbar/navbar_styles.dart';
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
            style: PillStyle.standalone,
            expandEqually: false,
            wrap: true,
            items: pills,
          ),
        ],
      ),
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
      headerTitle: 'UI Components',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
