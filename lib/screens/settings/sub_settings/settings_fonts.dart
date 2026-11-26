import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/controllers/theme.dart';
import 'package:anymex/utils/external_font_loader.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_container.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/common/anymex_slider_m3.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:anymex/l10n/l10n_extension.dart';

class SettingsFonts extends StatefulWidget {
  const SettingsFonts({super.key});

  @override
  State<SettingsFonts> createState() => _SettingsFontsState();
}

class _SettingsFontsState extends State<SettingsFonts> {
  final Map<String, bool> _downloadedStatus = {};
  final Set<String> _downloadingFonts = {};
  List<String> _customFonts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFontStatuses();
  }

  Future<void> _loadFontStatuses() async {
    for (final font in ExternalFontLoader.appFonts) {
      _downloadedStatus[font.name] =
          await ExternalFontLoader.isAppFontDownloaded(font.name);
    }
    _customFonts = await ExternalFontLoader.getCustomFontNames();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _applyFont(String fontName) async {
    final themeProvider = Get.find<ThemeController>();
    themeProvider.setFontFamily(fontName);
    Get.find<Settings>().appFontFamily = fontName;
    if (mounted) setState(() {});
  }

  Future<void> _downloadAndApplyFont(String fontName) async {
    setState(() => _downloadingFonts.add(fontName));
    final success = await ExternalFontLoader.downloadAppFont(fontName);
    _downloadingFonts.remove(fontName);

    if (success) {
      _downloadedStatus[fontName] = true;
      await _applyFont(fontName);
      snackBar(Get.context!.l10n.appliedFont(fontName.toString()));
    } else {
      snackBar(Get.context!.l10n.failedToDownload(fontName.toString()));
    }
    if (mounted) setState(() {});
  }

  Future<void> _importCustomFont() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ttf', 'otf'],
    );
    if (result != null && result.files.single.path != null) {
      final fontName = await ExternalFontLoader.importCustomFont(
        result.files.single.path!,
      );
      if (fontName != null) {
        _customFonts = await ExternalFontLoader.getCustomFontNames();
        await _applyFont(fontName);
        snackBar(Get.context!.l10n.importedApplied(fontName.toString()));
      } else {
        snackBar(Get.context!.l10n.failedToImportFontFile);
      }
      if (mounted) setState(() {});
    }
  }

  Future<void> _deleteCustomFont(String fontName) async {
    await ExternalFontLoader.deleteCustomFont(fontName);
    if (!mounted) return;
    final themeProvider = Get.find<ThemeController>();
    if (themeProvider.appFontFamily == fontName) {
      await _applyFont('');
    }
    _customFonts = await ExternalFontLoader.getCustomFontNames();
    snackBar(Get.context!.l10n.deleted3(fontName.toString()));
    if (mounted) setState(() {});
  }

  Widget _buildPreviewCard() {
    final themeProvider = Get.find<ThemeController>();
    final colors = context.colors;
    final currentFont = themeProvider.appFontFamily.isEmpty
        ? 'Linotte'
        : (themeProvider.appFontFamily == 'System'
            ? null
            : themeProvider.appFontFamily);
    final currentScale = themeProvider.fontScale;

    return AnymeXContainer(
      useIosBorder: true,
      color: colors.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(18),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: AnymeXText.semiBold(
                  themeProvider.appFontFamily.isEmpty
                      ? 'Default (Linotte)'
                      : themeProvider.appFontFamily,
                  color: colors.primary,
                  size: 11,
                ),
              ),
              const Spacer(),
              AnymeXText(
                context.l10n.scale(((currentScale * 100).round()).toString()),
                size: 11,
                color: colors.onSurface.withValues(alpha: 0.6),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'The Quick Brown Fox',
            style: TextStyle(
              fontFamily: currentFont,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Jumped over the lazy dog. AnymeX gives you rich, adaptive typography with system-wide live text scaling and crisp rendering.',
            style: TextStyle(
              fontFamily: currentFont,
              fontSize: 13.5,
              height: 1.45,
              color: colors.onSurface.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '1234567890 • EP 24 • 1080p • 60 FPS • \$49.99',
            style: TextStyle(
              fontFamily: currentFont,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: colors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScaleSection() {
    final themeProvider = Get.find<ThemeController>();
    final colors = context.colors;
    final scale = themeProvider.fontScale;
    final presets = [
      (label: '85%', value: 0.85),
      (label: '100%', value: 1.0),
      (label: '115%', value: 1.15),
      (label: '130%', value: 1.30),
    ];

    return AnymeXSectionBuilder(
      title: context.l10n.globalFontScaling,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AnymeXText(
                    context.l10n.fontSizeScale,
                    size: 14,
                    color: colors.onSurface,
                  ),
                  AnymeXText.semiBold(
                    '${(scale * 100).round()}%',
                    size: 14,
                    color: colors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              AnymeXSliderM3(
                value: scale.clamp(0.80, 1.40),
                min: 0.80,
                max: 1.40,
                divisions: 12,
                onChanged: (newScale) {
                  themeProvider.setFontScale(double.parse(newScale.toStringAsFixed(2)));
                },
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: presets.map((p) {
                  final isSelected = (scale - p.value).abs() < 0.02;
                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => themeProvider.setFontScale(p.value),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colors.primary
                            : colors.surfaceContainerHighest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: AnymeXText.semiBold(
                        p.label,
                        size: 12,
                        color: isSelected ? colors.onPrimary : colors.onSurface,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFontLibrarySection() {
    final themeProvider = Get.find<ThemeController>();
    final colors = context.colors;
    final current = themeProvider.appFontFamily;

    return AnymeXSectionBuilder(
      title: context.l10n.fontLibrary,
      children: [
        AnymeXTile(
          title: context.l10n.linotte,
          subtitle: context.l10n.defaultGeometricRoundedFontDesignedFor,
          titleStyle: const TextStyle(
            fontFamily: 'Linotte',
            fontWeight: FontWeight.bold,
          ),
          trailing: current.isEmpty
              ? Icon(Icons.check_circle_rounded, color: colors.primary)
              : null,
          onTap: () => _applyFont(''),
        ),
        AnymeXTile(
          title: context.l10n.systemFont,
          subtitle: context.l10n.useYourDeviceOsDefaultSystem,
          trailing: current == 'System'
              ? Icon(Icons.check_circle_rounded, color: colors.primary)
              : null,
          onTap: () => _applyFont('System'),
        ),
        ...ExternalFontLoader.appFonts.map((font) {
          final isDownloaded = _downloadedStatus[font.name] ?? false;
          final isDownloading = _downloadingFonts.contains(font.name);
          final isSelected = current == font.name;

          Widget trailing;
          if (isDownloading) {
            trailing = const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          } else if (isDownloaded) {
            trailing = isSelected
                ? Icon(Icons.check_circle_rounded, color: colors.primary)
                : const SizedBox.shrink();
          } else {
            trailing = IconButton(
              icon: const Icon(Icons.download_rounded),
              color: colors.primary,
              onPressed: () => _downloadAndApplyFont(font.name),
            );
          }

          return AnymeXTile(
            title: font.label,
            subtitle: context.l10n.theQuickBrownFoxJumpsOver,
            titleStyle: TextStyle(
              fontFamily: isDownloaded ? font.name : 'Linotte',
              fontWeight: FontWeight.w600,
            ),
            subtitleStyle: TextStyle(
              fontFamily: isDownloaded ? font.name : 'Linotte',
              fontSize: 11,
            ),
            trailing: trailing,
            onTap: () async {
              if (isDownloaded) {
                await _applyFont(font.name);
              } else if (!isDownloading) {
                await _downloadAndApplyFont(font.name);
              }
            },
          );
        }),
      ],
    );
  }

  Widget _buildCustomFontsSection() {
    final themeProvider = Get.find<ThemeController>();
    final colors = context.colors;
    final current = themeProvider.appFontFamily;

    return AnymeXSectionBuilder(
      title: context.l10n.customFonts,
      children: [
        AnymeXTile(
          icon: Icons.add_circle_outline_rounded,
          title: context.l10n.importCustomFont,
          subtitle: context.l10n.loadYourOwnTtfOrOtf,
          onTap: _importCustomFont,
        ),
        for (final fontName in _customFonts)
          AnymeXTile(
            title: fontName,
            subtitle: context.l10n.theQuickBrownFoxJumpsOver,
            titleStyle: TextStyle(
              fontFamily: fontName,
              fontWeight: FontWeight.w600,
            ),
            subtitleStyle: TextStyle(
              fontFamily: fontName,
              fontSize: 11,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (current == fontName)
                  Icon(Icons.check_circle_rounded, color: colors.primary),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded, color: colors.error),
                  onPressed: () => _deleteCustomFont(fontName),
                ),
              ],
            ),
            onTap: () => _applyFont(fontName),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (themeController) {
        return AnymeXScaffold(
          showHeader: true,
          headerTitle: context.l10n.fontsTypography,
          body: Builder(
            builder: (ctx) {
              final headerHeight = AnymeXHeaderScope.of(ctx);
              if (_isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16, headerHeight, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPreviewCard(),
                    const SizedBox(height: 16),
                    _buildScaleSection(),
                    const SizedBox(height: 16),
                    _buildFontLibrarySection(),
                    const SizedBox(height: 16),
                    _buildCustomFontsSection(),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
