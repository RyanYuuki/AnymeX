import 'dart:io';

import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/shaders.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_segmented_button.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:anymex/l10n/l10n_extension.dart';

class SettingsPlayerShaders extends StatefulWidget {
  final bool isModal;
  final bool isEmbedded;
  const SettingsPlayerShaders({
    super.key,
    this.isModal = false,
    this.isEmbedded = false,
  });

  @override
  State<SettingsPlayerShaders> createState() => _SettingsPlayerShadersState();
}

class _SettingsPlayerShadersState extends State<SettingsPlayerShaders> {
  final settings = Get.find<Settings>();
  final _isDownloading = false.obs;
  final _downloadProgress = 0.0.obs;
  final _currentStatus = 'Connecting…'.obs;
  final _shadersDownloaded = false.obs;
  final _enableShaders = false.obs;
  final _defaultColorProfile = 'natural'.obs;
  final _defaultShader = 'Default'.obs;
  Dio? _dio;

  static final List<({String id, String title, String sub})> _modeDefs = [
    (id: 'A', title: Get.context!.l10n.modeA, sub: 'Sharpen soft lines'),
    (id: 'B', title: Get.context!.l10n.modeB, sub: 'Gentle, keeps grain'),
    (id: 'C', title: Get.context!.l10n.modeC, sub: 'Denoise, upscale'),
    (id: 'A+A', title: Get.context!.l10n.modeAA, sub: 'Sharper · heavier'),
    (id: 'B+B', title: Get.context!.l10n.modeBB, sub: 'Gentle · heavier'),
    (id: 'C+A', title: Get.context!.l10n.modeCA, sub: 'Clean, then sharpen'),
  ];

  static final List<({String key, String title, Color c1, Color c2, Color c3})>
      _presetDefs = [
    (
      key: 'natural',
      title: Get.context!.l10n.natural,
      c1: const Color(0xFF8FB1A3),
      c2: const Color(0xFFE7C9A1),
      c3: const Color(0xFF5E6F9A),
    ),
    (
      key: 'vivid',
      title: Get.context!.l10n.vivid,
      c1: const Color(0xFFFF6B8B),
      c2: const Color(0xFFFFC857),
      c3: const Color(0xFF3DDBD9),
    ),
    (
      key: 'cinema',
      title: Get.context!.l10n.cinema,
      c1: const Color(0xFF1F3A4D),
      c2: const Color(0xFFC98B4E),
      c3: const Color(0xFF0E0E14),
    ),
    (
      key: 'anime_soft',
      title: Get.context!.l10n.soft,
      c1: const Color(0xFFC9B8E8),
      c2: const Color(0xFFF3D3D0),
      c3: const Color(0xFFA9D6CE),
    ),
    (
      key: 'warm',
      title: Get.context!.l10n.warm,
      c1: const Color(0xFFE8895B),
      c2: const Color(0xFFF2C879),
      c3: const Color(0xFF8E4B3A),
    ),
    (
      key: 'cool',
      title: Get.context!.l10n.cool,
      c1: const Color(0xFF5B8DEF),
      c2: const Color(0xFF9FD3F0),
      c3: const Color(0xFF2E3A6B),
    ),
    (
      key: 'anime_4k',
      title: Get.context!.l10n.anime4k,
      c1: const Color(0xFF7B61FF),
      c2: const Color(0xFFFF6584),
      c3: const Color(0xFF43E6D5),
    ),
    (
      key: 'cinema_hdr',
      title: Get.context!.l10n.cinemaHdr,
      c1: const Color(0xFF1A2A3A),
      c2: const Color(0xFFE5A93C),
      c3: const Color(0xFFFF5722),
    ),
    (
      key: 'vivid_pop',
      title: Get.context!.l10n.vividPop,
      c1: const Color(0xFFFF2A6D),
      c2: const Color(0xFF05D9E8),
      c3: const Color(0xFFF3E600),
    ),
    (
      key: 'dark',
      title: Get.context!.l10n.dark,
      c1: const Color(0xFF212121),
      c2: const Color(0xFF37474F),
      c3: const Color(0xFF121212),
    ),
    (
      key: 'grayscale',
      title: Get.context!.l10n.grayscale,
      c1: const Color(0xFF424242),
      c2: const Color(0xFF757575),
      c3: const Color(0xFFBDBDBD),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkShadersAvailability();
    _enableShaders.value = PlayerUiKeys.shadersEnabled.get<bool>(false);
    _defaultColorProfile.value =
        PlayerUiKeys.currentVisualProfile.get<String>('natural');
    final savedShader = settings.selectedShader;
    _defaultShader.value = savedShader.isEmpty ? 'Default' : savedShader;
  }

  @override
  void dispose() {
    _dio?.close(force: true);
    super.dispose();
  }

  Future<void> _checkShadersAvailability() async {
    try {
      final downloaded = await PlayerShaders.areShadersDownloaded();
      _shadersDownloaded.value = downloaded;
    } catch (e) {
      Logger.i('Error checking shaders: $e');
    }
  }

  Future<void> _downloadShaders() async {
    _isDownloading.value = true;
    _downloadProgress.value = 0.0;
    _currentStatus.value = 'Connecting…';

    try {
      await Future.delayed(const Duration(milliseconds: 200));
      _currentStatus.value = 'Downloading shaders…';
      _downloadProgress.value = 0.10;

      final shadersPath = await PlayerShaders.getShaderBasePath();
      final mpvPath = Directory(shadersPath).path;

      final tempDir = await getTemporaryDirectory();
      final tempFilePath = '${tempDir.path}/anime4k_shaders.zip';
      final tempFile = File(tempFilePath);

      _dio = Dio();
      await _dio!.download(
        'https://github.com/RyanYuuki/AnymeX/raw/refs/heads/main/assets/shaders/shaders_new.zip',
        tempFilePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = 0.10 + (received / total) * 0.60;
            _downloadProgress.value = progress;
          }
        },
      );

      _currentStatus.value = 'Extracting files…';
      _downloadProgress.value = 0.75;

      final bytes = await tempFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        if (file.isFile) {
          final outFile = File('$mpvPath${file.name}');
          await outFile.parent.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        }
      }

      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      _currentStatus.value = 'Finishing up…';
      _downloadProgress.value = 1.0;
      _isDownloading.value = false;
      _shadersDownloaded.value = true;
      _enableShaders.value = true;
      PlayerUiKeys.shadersEnabled.set(true);
    } catch (e) {
      _isDownloading.value = false;
      _currentStatus.value = 'Download failed';
    }
  }

  void _cancelDownload() {
    _dio?.close(force: true);
    _isDownloading.value = false;
    _downloadProgress.value = 0.0;
    _currentStatus.value = 'Connecting…';
  }

  String _extractModeFromShader(String shader) {
    if (shader.contains('Mode A+A')) return 'A+A';
    if (shader.contains('Mode B+B')) return 'B+B';
    if (shader.contains('Mode C+A')) return 'C+A';
    if (shader.contains('Mode A')) return 'A';
    if (shader.contains('Mode B')) return 'B';
    if (shader.contains('Mode C')) return 'C';
    return 'B';
  }

  void _selectShaderMode(String modeId) {
    final suffix = settings.selectedProfile == 'HIGH-END' ? '(HQ)' : '(Fast)';
    final shaderName = 'Anime4K: Mode $modeId $suffix';
    settings.selectedShader = shaderName;
    PlayerUiKeys.selectedShader.set(shaderName);
    _defaultShader.value = shaderName;
    _enableShaders.value = true;
    PlayerUiKeys.shadersEnabled.set(true);
    HapticFeedback.lightImpact();
    setState(() {});
  }

  void _selectDefaultShader() {
    settings.selectedShader = '';
    PlayerUiKeys.selectedShader.set('');
    _defaultShader.value = 'Default';
    _enableShaders.value = false;
    PlayerUiKeys.shadersEnabled.set(false);
    HapticFeedback.lightImpact();
    setState(() {});
  }

  void _selectTier(String tier) {
    settings.selectedProfile = tier;
    if (_enableShaders.value &&
        _defaultShader.value.isNotEmpty &&
        _defaultShader.value != 'Default') {
      final modeId = _extractModeFromShader(_defaultShader.value);
      final suffix = tier == 'HIGH-END' ? '(HQ)' : '(Fast)';
      final shaderName = 'Anime4K: Mode $modeId $suffix';
      settings.selectedShader = shaderName;
      PlayerUiKeys.selectedShader.set(shaderName);
      _defaultShader.value = shaderName;
    }
    HapticFeedback.lightImpact();
    setState(() {});
  }

  void _selectPreset(String presetKey) {
    PlayerUiKeys.currentVisualProfile.set(presetKey);
    _defaultColorProfile.value = presetKey;
    HapticFeedback.lightImpact();
    setState(() {});
  }

  Widget _buildKeybindingItem(String key, String description) {
    final theme = context.theme;
    final colors = theme.colorScheme;
    final cardBg = colors.surfaceContainer.opaque(0.45, iReallyMeanIt: true);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: AnymeXText.semiBold(
              key,
              style: TextStyle(
                fontFamily: 'monospace',
                color: colors.onPrimaryContainer,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: AnymeXText(
              description,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colorScheme;
    final cardBg = colors.surfaceContainer.opaque(0.45, iReallyMeanIt: true);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnymeXSectionBuilder(
          title: context.l10n.anime4kEngine,
                children: [
                  Obx(() {
                    if (!_shadersDownloaded.value) {
                      return Container(
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: colors.outlineVariant.withValues(alpha: 0.2),
                          ),
                        ),
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: colors.primaryContainer,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.download_rounded,
                                    size: 24,
                                    color: colors.primary,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      AnymeXText.semiBold(
                                        'Anime4K Shaders',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: colors.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      AnymeXText(
                                        context.l10n.highQualityRealTimeUpscaling,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: colors.onSurfaceVariant,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (!_isDownloading.value)
                              InkWell(
                                onTap: _downloadShaders,
                                borderRadius: BorderRadius.circular(26),
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: colors.primary,
                                    borderRadius: BorderRadius.circular(26),
                                  ),
                                  alignment: Alignment.center,
                                  child: AnymeXText.semiBold(
                                    'Download now',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: colors.onPrimary,
                                    ),
                                  ),
                                ),
                              )
                            else
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      AnymeXText(
                                        _currentStatus.value,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: colors.onSurface,
                                        ),
                                      ),
                                      AnymeXText.semiBold(
                                        '${(_downloadProgress.value * 100).toInt()}%',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: colors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(5),
                                    child: LinearProgressIndicator(
                                      value: _downloadProgress.value,
                                      backgroundColor:
                                          colors.surfaceContainerHighest,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                              colors.primary),
                                      minHeight: 8,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _cancelDownload,
                                      child: AnymeXText.semiBold(
                                        'Cancel',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: colors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      );
                    }

                    return AnymeXTile.toggle(
                      title: context.l10n.anime4kShaders2,
                      subtitle:
                          context.l10n.enableRealTimeNeuralUpscaling,
                      value: _enableShaders.value,
                      onChanged: (val) {
                        _enableShaders.value = val;
                        PlayerUiKeys.shadersEnabled.set(val);
                        if (val && _defaultShader.value == 'Default') {
                          _selectShaderMode('B');
                        }
                      },
                    );
                  }),
                ],
              ),
              const SizedBox(height: 16),
              AnymeXSectionBuilder(
                title: context.l10n.devicePerformanceTier,
                children: [
                  AnymeXSegmentedButtonGroup<String>(
                    selected: settings.selectedProfile,
                    items: [
                      (value: 'MID-END', title: context.l10n.midRange, icon: null),
                      (value: 'HIGH-END', title: context.l10n.highEnd, icon: null),
                    ],
                    onSelected: _selectTier,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colors.outlineVariant.withValues(alpha: 0.2),
                      ),
                    ),
                    child: AnymeXText(
                      context.l10n.midRangeOptimizedForMobile,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AnymeXSectionBuilder(
                title: context.l10n.shaderMode,
                children: [
                  Obx(() {
                    final current = _defaultShader.value;
                    final isDefault = !_enableShaders.value ||
                        current.isEmpty ||
                        current == 'Default';

                    return Column(
                      children: [
                        InkWell(
                          onTap: _selectDefaultShader,
                          borderRadius:
                              BorderRadius.circular(isDefault ? 28 : 20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            height: 72,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: isDefault
                                  ? colors.primaryContainer
                                  : cardBg,
                              borderRadius:
                                  BorderRadius.circular(isDefault ? 28 : 20),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isDefault
                                        ? colors.primary
                                        : colors.surfaceContainerHighest,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.block_rounded,
                                    size: 18,
                                    color: isDefault
                                        ? colors.onPrimary
                                        : colors.onSurface,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      AnymeXText.semiBold(
                                        'Default · no shader',
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: isDefault
                                              ? colors.onPrimaryContainer
                                              : colors.onSurface,
                                        ),
                                      ),
                                      AnymeXText(
                                        context.l10n.nativeSourceWithoutUpscaling,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDefault
                                              ? colors.onPrimaryContainer
                                                  .withValues(alpha: 0.8)
                                              : colors.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isDefault)
                                  Icon(Icons.check_circle_rounded,
                                      size: 20, color: colors.primary),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            mainAxisExtent: 82,
                          ),
                          itemCount: _modeDefs.length,
                          itemBuilder: (context, index) {
                            final m = _modeDefs[index];
                            final isSelected = _enableShaders.value &&
                                current.contains('Mode ${m.id}');
                            return InkWell(
                              onTap: () => _selectShaderMode(m.id),
                              borderRadius:
                                  BorderRadius.circular(isSelected ? 28 : 16),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? colors.primaryContainer
                                      : cardBg,
                                  borderRadius: BorderRadius.circular(
                                      isSelected ? 28 : 16),
                                ),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    AnymeXText.semiBold(
                                      m.title,
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: isSelected
                                            ? colors.onPrimaryContainer
                                            : colors.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    AnymeXText(
                                      m.sub,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isSelected
                                            ? colors.onPrimaryContainer
                                                .withValues(alpha: 0.8)
                                            : colors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  }),
                ],
              ),
              const SizedBox(height: 16),
              AnymeXSectionBuilder(
                title: context.l10n.colorPreset,
                children: [
                  Obx(() {
                    final currentProfile = _defaultColorProfile.value;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        mainAxisExtent: 96,
                      ),
                      itemCount: _presetDefs.length,
                      itemBuilder: (context, index) {
                        final p = _presetDefs[index];
                        final isSelected = currentProfile == p.key;
                        return InkWell(
                          onTap: () => _selectPreset(p.key),
                          borderRadius:
                              BorderRadius.circular(isSelected ? 28 : 16),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colors.primaryContainer
                                  : cardBg,
                              borderRadius: BorderRadius.circular(
                                  isSelected ? 28 : 16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: p.c1,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Container(
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: p.c2,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Container(
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: p.c3,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: AnymeXText.semiBold(
                                        p.title,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isSelected
                                              ? colors.onPrimaryContainer
                                              : colors.onSurface,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(Icons.check_circle_rounded,
                                          size: 16, color: colors.primary),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ],
              ),
              getResponsiveValue(
                context,
                mobileValue: const SizedBox.shrink(),
                strictMode: true,
                desktopValue: Column(
                  children: [
                    const SizedBox(height: 16),
                    AnymeXSectionBuilder(
                      title: context.l10n.desktopPlaybackKeybindings,
                      children: [
                        _buildKeybindingItem('CTRL + 1', 'Anime4K: Mode A'),
                        _buildKeybindingItem('CTRL + 2', 'Anime4K: Mode B'),
                        _buildKeybindingItem('CTRL + 3', 'Anime4K: Mode C'),
                        _buildKeybindingItem('CTRL + 4', 'Anime4K: Mode A+A'),
                        _buildKeybindingItem('CTRL + 5', 'Anime4K: Mode B+B'),
                        _buildKeybindingItem('CTRL + 6', 'Anime4K: Mode C+A'),
                        _buildKeybindingItem(
                            'CTRL + 0', 'Reset (Clear Shaders)'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );

    if (widget.isEmbedded) {
      return content;
    }

    return AnymeXScaffold(
      showHeader: !widget.isModal,
      headerTitle: context.l10n.shadersColors,
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
