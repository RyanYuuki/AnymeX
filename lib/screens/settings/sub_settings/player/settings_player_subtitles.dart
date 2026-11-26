import 'package:anymex/constants/contants.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/utils/external_font_loader.dart';
import 'package:anymex/utils/subtitle_style_renderer.dart';
import 'package:anymex/utils/subtitle_translator.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_container.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile_builder.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/non_widgets/reusable_checkmark.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconsax/iconsax.dart';
import 'package:anymex/l10n/l10n_extension.dart';

const Map<String, List<String>> _subtitleFontGroups = {
  'Default': ['Default'],
  'Latin': ['Trebuchet', 'Bahnschrift', 'Tahoma', 'Anime Ace 3', 'Linotte'],
  'Japanese': ['Cinecaption'],
};

class SettingsPlayerSubtitles extends StatefulWidget {
  final bool isModal;
  final bool isEmbedded;
  const SettingsPlayerSubtitles({
    super.key,
    this.isModal = false,
    this.isEmbedded = false,
  });

  @override
  State<SettingsPlayerSubtitles> createState() =>
      _SettingsPlayerSubtitlesState();
}

class _SettingsPlayerSubtitlesState extends State<SettingsPlayerSubtitles> {
  final settings = Get.find<Settings>();
  late bool _useLibass;
  List<String> _customFonts = [];

  @override
  void initState() {
    super.initState();
    _useLibass = PlayerKeys.useLibass.get<bool>(false);
    _loadCustomFonts();
  }

  Future<void> _loadCustomFonts() async {
    final fonts = await ExternalFontLoader.getCustomFontNames();
    if (mounted) {
      setState(() {
        _customFonts = fonts;
      });
    }
  }

  void _showColorSelectionDialog(
    String title,
    Color currentColor,
    Function(String) onColorSelected,
    Map<String, Color> options,
  ) {
    AnymeXDialog(
      title: title,
      onConfirm: () {},
      showCancelButton: false,
      confirmText: context.l10n.actionClose,
      contentWidget: AnymeXTileBuilder<String>(
        getTitle: (t) => t,
        onItemPressed: (s) {
          onColorSelected(s);
          Navigator.pop(context);
        },
        selectedItem: options.entries
            .firstWhere(
              (entry) => entry.value == currentColor,
              orElse: () => const MapEntry('', Colors.transparent),
            )
            .key,
        items: options.keys.toList(),
      ),
    ).show(context);
  }

  void _showTranslationLanguageDialog() {
    showSelectionDialog<String>(
      title: context.l10n.translationLanguage,
      items: SubtitleTranslator.languages.keys.toList(),
      selectedItem: settings.playerSettings.value.translateTo.obs,
      getTitle: (code) => SubtitleTranslator.languages[code]!,
      onItemSelected: (code) {
        settings.playerSettings.update((s) => s?.translateTo = code);
        PlayerSettingsKeys.translateTo.set(code);
        setState(() {});
      },
    );
  }

  void _showFontSelectionDialog() {
    AnymeXDialog(
      title: context.l10n.selectSubtitleFont,
      onConfirm: () {},
      showCancelButton: false,
      confirmText: context.l10n.actionClose,
      contentWidget: StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final currentFont = settings.playerSettings.value.subtitleFont;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnymeXSectionBuilder(
                title: context.l10n.customSubtitleFonts,
                children: [
                  AnymeXTile(
                    icon: Icons.add_rounded,
                    title: context.l10n.importCustomFont,
                    subtitle: context.l10n.supportTtfAndOtfFiles,
                    onTap: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['ttf', 'otf'],
                      );
                      if (result != null && result.files.single.path != null) {
                        final fontName =
                            await ExternalFontLoader.importCustomFont(
                          result.files.single.path!,
                        );
                        if (fontName != null) {
                          final current = settings.playerSettings.value;
                          current.subtitleFont = fontName;
                          PlayerSettingsKeys.subtitleFont.set(fontName);
                          settings.playerSettings.refresh();
                          final updated =
                              await ExternalFontLoader.getCustomFontNames();
                          if (mounted) {
                            setState(() {
                              _customFonts = updated;
                            });
                          }
                          setDialogState(() {});
                          snackBar(Get.context!.l10n.importedFont(fontName.toString()));
                        } else {
                          snackBar(Get.context!.l10n.failedToLoadFontFile);
                        }
                      }
                    },
                  ),
                  ..._customFonts.map((font) {
                    return AnymeXTile.radio(
                      selected: currentFont == font,
                      title: font,
                      titleStyle: TextStyle(fontFamily: font),
                      subtitle: context.l10n.holdToDelete,
                      onLongPress: () {
                        AnymeXDialog(
                          title: context.l10n.deleteFont,
                          message: context.l10n.areYouSureYouWantTo3(font.toString()),
                          onConfirm: () async {
                            await ExternalFontLoader.deleteCustomFont(font);
                            if (settings.playerSettings.value.subtitleFont ==
                                font) {
                              final current = settings.playerSettings.value;
                              current.subtitleFont = 'Default';
                              PlayerSettingsKeys.subtitleFont.set('Default');
                              settings.playerSettings.refresh();
                            }
                            final updated =
                                await ExternalFontLoader.getCustomFontNames();
                            if (mounted) {
                              setState(() {
                                _customFonts = updated;
                              });
                            }
                            setDialogState(() {});
                          },
                        ).show(dialogContext);
                      },
                      onTap: () {
                        final current = settings.playerSettings.value;
                        current.subtitleFont = font;
                        PlayerSettingsKeys.subtitleFont.set(font);
                        settings.playerSettings.refresh();
                        Navigator.pop(dialogContext);
                      },
                    );
                  }),
                ],
              ),
              ..._subtitleFontGroups.entries.map((group) {
                return AnymeXSectionBuilder(
                  title: group.key,
                  children: group.value
                      .map((font) => AnymeXTile.radio(
                            selected: currentFont == font,
                            title: font,
                            titleStyle: TextStyle(
                              fontFamily: resolveSubtitleFontFamily(font),
                            ),
                            onTap: () {
                              final current = settings.playerSettings.value;
                              current.subtitleFont = font;
                              PlayerSettingsKeys.subtitleFont.set(font);
                              settings.playerSettings.refresh();
                              Navigator.pop(dialogContext);
                            },
                          ))
                      .toList(),
                );
              }),
            ],
          );
        },
      ),
    ).show(context);
  }

  void _showOutlineTypeDialog() {
    final currentType = normalizeSubtitleOutlineType(
        settings.playerSettings.value.subtitleOutlineType);
    if (currentType != settings.playerSettings.value.subtitleOutlineType) {
      settings.playerSettings
          .update((s) => s?.subtitleOutlineType = currentType);
      PlayerSettingsKeys.subtitleOutlineType.set(currentType);
    }

    showSelectionDialog<String>(
      title: context.l10n.outlineType,
      items: subtitleOutlineTypes,
      selectedItem: currentType.obs,
      getTitle: (v) => v,
      onItemSelected: (v) {
        final current = settings.playerSettings.value;
        current.subtitleOutlineType = v;
        PlayerSettingsKeys.subtitleOutlineType.set(v);
        settings.playerSettings.refresh();
      },
    );
  }

  Widget _buildSubtitlePreviewCard() {
    final colors = context.colors;
    return AnymeXContainer(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      color: colors.surfaceContainer.opaque(0.45),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: colors.outline.opaque(0.16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnymeXText(context.l10n.liveSubtitlePreview,
                variant: TextVariant.bold,
                size: 14,
              ),
              const Spacer(),
              AnymeXText(
                '${settings.playerSettings.value.subtitleFont} • ${settings.subtitleSize}pt',
                size: 11,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://i.pinimg.com/736x/f8/a1/fd/f8a1fdf302b56743ee6fbd6deb648921.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF101521),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.1),
                          Colors.black.withValues(alpha: 0.45),
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                      child: Opacity(
                        opacity: settings.playerSettings.value.subtitleOpacity
                            .clamp(0.1, 1.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: subtitleBackgroundColor(
                              settings.subtitleBackgroundColor,
                              settings.playerSettings.value
                                  .subtitleBackgroundOpacity,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: buildStyledSubtitleText(
                            text: context.l10n.freedom,
                            textColor: fontColorOptions[settings.subtitleColor] ??
                                fontColorOptions['Default']!,
                            fontSize: settings.subtitleSize
                                .toDouble()
                                .clamp(12.0, 40.0),
                            fontFamily: resolveSubtitleFontFamily(
                                settings.playerSettings.value.subtitleFont),
                            outlineType: settings
                                .playerSettings.value.subtitleOutlineType,
                            outlineWidth:
                                settings.subtitleOutlineWidth.toDouble(),
                            outlineColor:
                                colorOptions[settings.subtitleOutlineColor] ??
                                    colorOptions['Black']!,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSubtitlePreviewCard(),
          AnymeXSectionBuilder(
            title: context.l10n.languageTranslation,
            children: [
              AnymeXTile(
                icon: Icons.closed_caption_rounded,
                title: context.l10n.preferredSubtitleLanguage,
                subtitle: SubtitleTranslator
                        .languages[settings.preferredSubtitleLanguage] ??
                    'None (Disabled)',
                onTap: () => showSelectionDialog<String>(
                  title: context.l10n.preferredSubtitleLanguage,
                  items: ['none', ...SubtitleTranslator.languages.keys],
                  selectedItem: settings
                      .playerSettings.value.preferredSubtitleLanguage.obs,
                  getTitle: (code) => code == 'none'
                      ? 'None (Disabled)'
                      : SubtitleTranslator.languages[code]!,
                  onItemSelected: (code) {
                    settings.preferredSubtitleLanguage = code;
                    setState(() {});
                  },
                ),
              ),
              AnymeXTile.toggle(
                icon: HugeIcons.strokeRoundedTranslate,
                title: context.l10n.autoTranslateSubtitles,
                subtitle: context.l10n.useAiToTranslateSoftSubtitles,
                value: settings.playerSettings.value.autoTranslate,
                onChanged: (val) {
                  settings.playerSettings.update((s) => s?.autoTranslate = val);
                  PlayerSettingsKeys.autoTranslate.set(val);
                  setState(() {});
                },
              ),
              if ((!widget.isModal || widget.isEmbedded) &&
                  settings.playerSettings.value.autoTranslate)
                AnymeXTile(
                  icon: Icons.language,
                  title: context.l10n.translateTo,
                  subtitle: SubtitleTranslator.languages[
                          settings.playerSettings.value.translateTo] ??
                      'Select Language',
                  onTap: _showTranslationLanguageDialog,
                ),
            ],
          ),
          AnymeXSectionBuilder(
            title: context.l10n.renderingBehavior,
            children: [
              AnymeXTile.toggle(
                icon: Icons.subtitles,
                title: context.l10n.useLibassForSubtitles,
                subtitle: context.l10n.betterSubtitleRenderingUsingLibassLibrary,
                value: _useLibass,
                onChanged: (val) async {
                  setState(() {
                    _useLibass = val;
                  });
                  PlayerKeys.useLibass.set<bool>(val);
                  if (Get.isRegistered<PlayerController>()) {
                    final controller = Get.find<PlayerController>();
                    if (!controller.isClosed) {
                      await controller.onLibassPreferenceChanged(val);
                    }
                  }
                },
              ),
              AnymeXTile.toggle(
                icon: Icons.lightbulb,
                title: context.l10n.transitionSubtitle,
                subtitle: context.l10n.disableToAvoidFadeTransitionsBetween,
                value: settings.transitionSubtitle,
                onChanged: (e) {
                  settings.transitionSubtitle = e;
                },
              ),
            ],
          ),
          AnymeXSectionBuilder(
            title: context.l10n.typographyOutline,
            children: [
              AnymeXTile(
                icon: Icons.font_download_rounded,
                title: context.l10n.subtitleFont,
                subtitle: settings.playerSettings.value.subtitleFont,
                onTap: _showFontSelectionDialog,
              ),
              AnymeXTile.slider(
                value: settings.subtitleSize.toDouble(),
                min: 12.0,
                max: 90.0,
                onChanged: (double value) {
                  settings.subtitleSize = value.toInt();
                },
                title: context.l10n.subtitleSize,
                subtitle: context.l10n.adjustSubtitleFontSize,
                icon: Iconsax.subtitle5,
              ),
              AnymeXTile(
                icon: Icons.format_paint_rounded,
                title: context.l10n.outlineType,
                subtitle: normalizeSubtitleOutlineType(
                    settings.playerSettings.value.subtitleOutlineType),
                onTap: _showOutlineTypeDialog,
              ),
              AnymeXTile.slider(
                value: settings.subtitleOutlineWidth.toDouble(),
                min: 1.0,
                max: 8.0,
                divisions: 14,
                onChanged: (double value) {
                  settings.subtitleOutlineWidth = value.toInt();
                },
                title: context.l10n.subtitleOutlineWidth,
                subtitle: context.l10n.adjustSubtitleOutlineThickness,
                icon: Iconsax.subtitle5,
              ),
            ],
          ),
          AnymeXSectionBuilder(
            title: context.l10n.colorsPosition,
            children: [
              AnymeXTile(
                subtitle: context.l10n.changeSubtitleTextColor,
                icon: Icons.palette,
                title: context.l10n.subtitleColor,
                onTap: () {
                  _showColorSelectionDialog(
                    'Select Subtitle Color',
                    fontColorOptions[settings.subtitleColor] ??
                        fontColorOptions['Default']!,
                    (color) {
                      settings.subtitleColor = color;
                    },
                    fontColorOptions,
                  );
                },
              ),
              AnymeXTile(
                icon: Icons.palette,
                title: context.l10n.subtitleOutlineColor,
                subtitle: context.l10n.changeSubtitleOutlineColor,
                onTap: () {
                  _showColorSelectionDialog(
                    'Select Subtitle Outline Color',
                    colorOptions[settings.subtitleOutlineColor] ??
                        colorOptions['None']!,
                    (color) {
                      settings.subtitleOutlineColor = color;
                    },
                    colorOptions,
                  );
                },
              ),
              AnymeXTile(
                subtitle: context.l10n.changeSubtitleBackgroundColor,
                icon: Icons.palette,
                title: context.l10n.subtitleBackgroundColor,
                onTap: () {
                  _showColorSelectionDialog(
                    'Select Subtitle Background Color',
                    colorOptions[settings.subtitleBackgroundColor] ??
                        colorOptions['None']!,
                    (color) {
                      settings.subtitleBackgroundColor = color;
                    },
                    colorOptions,
                  );
                },
              ),
              AnymeXTile.slider(
                value: settings.playerSettings.value.subtitleBackgroundOpacity,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                onChanged: (val) {
                  final current = settings.playerSettings.value;
                  current.subtitleBackgroundOpacity = val;
                  PlayerSettingsKeys.subtitleBackgroundOpacity.set(val);
                  settings.playerSettings.refresh();
                },
                title: context.l10n.subtitleBackgroundTransparency,
                subtitle: context.l10n.adjustSubtitleBackgroundVisibility,
                icon: Icons.opacity,
              ),
              AnymeXTile.slider(
                value: settings.playerSettings.value.subtitleOpacity,
                min: 0.1,
                max: 1.0,
                divisions: 10,
                onChanged: (val) {
                  final current = settings.playerSettings.value;
                  current.subtitleOpacity = val;
                  PlayerSettingsKeys.subtitleOpacity.set(val);
                  settings.playerSettings.refresh();
                },
                title: context.l10n.subtitleTransparency,
                subtitle: context.l10n.adjustTextVisibility,
                icon: Icons.opacity,
              ),
              AnymeXTile.slider(
                value: settings.playerSettings.value.subtitleBottomMargin,
                min: 0.0,
                max: 500.0,
                divisions: 500,
                onChanged: (val) {
                  final current = settings.playerSettings.value;
                  current.subtitleBottomMargin = val;
                  PlayerSettingsKeys.subtitleBottomMargin.set(val);
                  settings.playerSettings.refresh();
                },
                title: context.l10n.bottomMargin,
                subtitle: context.l10n.distanceFromBottomOfScreen,
                icon: Icons.vertical_align_bottom,
              ),
            ],
          ),
        ],
      ),
    );

    if (widget.isEmbedded) {
      return content;
    }

    return AnymeXScaffold(
      showHeader: !widget.isModal,
      headerTitle: context.l10n.subtitlesTranslation,
      body: Builder(
        builder: (ctx) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16.0,
            widget.isModal ? 16.0 : AnymeXHeaderScope.of(ctx),
            16.0,
            30.0,
          ),
          child: content,
        ),
      ),
    );
  }
}
