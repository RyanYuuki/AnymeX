import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/models/custom_card_style.dart';
import 'package:anymex/models/models_convertor/carousel/carousel_data.dart';
import 'package:anymex/utils/fallback/fallback_anime.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/common/anymex_pills.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/common/cards/card_gate.dart';
import 'package:anymex/widgets/common/cards/media_cards.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class CardCustomizerPage extends StatefulWidget {
  const CardCustomizerPage({super.key});

  @override
  State<CardCustomizerPage> createState() => _CardCustomizerPageState();
}

class _CardCustomizerPageState extends State<CardCustomizerPage> {
  final settings = Get.find<Settings>();
  late final List<CarouselData> _sampleCards;

  static const _styleOptions = [
    'Default',
    'Exotic',
    'Minimal Exotic',
    'Saikou',
    'Modern',
  ];

  @override
  void initState() {
    super.initState();
    registerBuiltInMediaCardStyles();

    final converted = convertData(trendingAnimes.take(4).toList());
    _sampleCards = converted.isNotEmpty
        ? converted
        : [
            CarouselData(
              id: '1',
              title: 'Solo Leveling Season 2 – Arise from the Shadow',
              poster:
                  'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx176496-zEa7w0t8V90a.jpg',
              extraData: '8.6',
              source: '12',
              releasing: true,
              servicesType: ServicesType.anilist,
            ),
            CarouselData(
              id: '2',
              title: 'Frieren: Beyond Journey\'s End',
              poster:
                  'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx154587-n2bJDnUhdwio.png',
              extraData: '9.3',
              source: '28',
              releasing: false,
              servicesType: ServicesType.anilist,
            ),
            CarouselData(
              id: '3',
              title: 'BLEACH: Thousand-Year Blood War',
              poster:
                  'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx114446-2t352pD3F95p.jpg',
              extraData: '8.8',
              source: '14',
              releasing: true,
              servicesType: ServicesType.anilist,
            ),
          ];
  }

  int _indexFromStyleName(String name) => switch (name) {
        'Default' => 0,
        'Saikou' => 1,
        'Exotic' => 2,
        'Minimal Exotic' => 3,
        'Modern' => 4,
        _ => 0,
      };

  String _styleNameFromIndex(int index) => switch (index) {
        0 => 'Default',
        1 => 'Saikou',
        2 => 'Exotic',
        3 => 'Minimal Exotic',
        4 => 'Modern',
        _ => 'Default',
      };

  void _update(CardCustomization Function(CardCustomization) updater) {
    final updated = updater(settings.cardCustomization);
    settings.cardCustomization = updated;
  }

  void _reset() {
    settings.cardStyle = 0;
    settings.cardCustomization = const CardCustomization();
  }

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width > 600;

    return AnymeXScaffold(
      showHeader: true,
      headerTitle: 'Card Customizer',
      headerAction: IconButton(
        tooltip: 'Reset to Default',
        icon: const Icon(Icons.refresh_rounded),
        onPressed: _reset,
      ),
      body: Builder(
        builder: (ctx) => SingleChildScrollView(
          padding:
              EdgeInsets.fromLTRB(16.0, AnymeXHeaderScope.of(ctx), 16.0, 36.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLivePreview(desktop),
              const SizedBox(height: 20),
              _buildStylesSection(),
              const SizedBox(height: 20),
              _buildSizingSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLivePreview(bool desktop) {
    return Obx(() {
      final styleIdx = settings.cardStyle.clamp(0, 4);
      final config = settings.cardCustomization;
      final previewHeight = config.getCardHeight(styleIdx, desktop) + 15;
      final activeStyleName = _styleNameFromIndex(styleIdx);

      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainer.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: context.colors.outlineVariant.withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                children: [
                  Icon(Icons.visibility_outlined,
                      size: 16, color: context.colors.primary),
                  const SizedBox(width: 8),
                  AnymeXText(
                    'Live Preview',
                    size: 13,
                    variant: TextVariant.bold,
                    color: context.colors.primary,
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.colors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: AnymeXText(
                      activeStyleName,
                      size: 11,
                      variant: TextVariant.bold,
                      color: context.colors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: previewHeight,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(left: 10, top: 5, bottom: 10),
                itemCount: _sampleCards.length,
                itemBuilder: (context, index) {
                  return MediaCardGate(
                    cardStyleIndex: styleIdx,
                    itemData: _sampleCards[index],
                    tag: 'preview-card-$index',
                    variant: DataVariant.anilist,
                    type: ItemType.anime,
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStylesSection() {
    return Obx(() {
      final currentName = _styleNameFromIndex(settings.cardStyle);

      return AnymeXSectionBuilder(
        title: 'Card Style',
        children: [
          AnymeXTile.pills<String>(
            icon: Iconsax.category,
            title: 'Preset Style',
            subtitle: 'Choose from 5 authentic built-in designs',
            value: currentName,
            options: _styleOptions,
            onChanged: (selected) {
              settings.cardStyle = _indexFromStyleName(selected);
            },
            expand: false,
            wrap: true,
            pillStyle: PillStyle.standalone,
          ),
        ],
      );
    });
  }

  Widget _buildSizingSection() {
    return Obx(() {
      final config = settings.cardCustomization;

      return AnymeXSectionBuilder(
        title: 'Sizing & Geometry',
        children: [
          AnymeXTile.slider(
            icon: Iconsax.size,
            title: 'Card Size',
            subtitle: 'Scale cards proportionally without distortion',
            value: config.scale,
            min: 0.75,
            max: 1.35,
            divisions: 12,
            valueTransformer: (v) => '${(v * 100).toInt()}%',
            onChanged: (val) {
              _update((c) =>
                  c.copyWith(scale: double.parse(val.toStringAsFixed(2))));
            },
          ),
          AnymeXTile.toggle(
            icon: Iconsax.rotate_right,
            title: 'Landscape Cards',
            subtitle: 'Format cards in 16:9 widescreen orientation',
            value: config.isLandscape,
            onChanged: (val) {
              _update((c) => c.copyWith(isLandscape: val));
            },
          ),
          if (!config.isLandscape)
            AnymeXTile.pills<String>(
              icon: Icons.aspect_ratio_rounded,
              title: 'Aspect Ratio',
              subtitle: 'Select poster image aspect ratio',
              value: config.aspectRatio,
              options: const ['2:3', '3:4', '1:1', '9:16'],
              onChanged: (val) {
                _update((c) => c.copyWith(aspectRatio: val));
              },
              expand: false,
              wrap: true,
              pillStyle: PillStyle.standalone,
            ),
          AnymeXTile.pills<int>(
            icon: Iconsax.textalign_left,
            title: 'Title Lines',
            subtitle: 'Maximum number of title lines displayed',
            value: config.titleLines,
            options: const [1, 2, 3],
            optionLabelTransformer: (lines) =>
                '$lines ${lines == 1 ? "Line" : "Lines"}',
            onChanged: (val) {
              _update((c) => c.copyWith(titleLines: val));
            },
            expand: false,
            wrap: true,
            pillStyle: PillStyle.standalone,
          ),
        ],
      );
    });
  }
}
