import 'dart:io';

import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/shaders.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dropdown.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:path_provider/path_provider.dart';

class SettingsPlayerShaders extends StatefulWidget {
  final bool isModal;
  const SettingsPlayerShaders({super.key, this.isModal = false});

  @override
  State<SettingsPlayerShaders> createState() => _SettingsPlayerShadersState();
}

class _SettingsPlayerShadersState extends State<SettingsPlayerShaders>
    with TickerProviderStateMixin {
  final settings = Get.find<Settings>();
  late final AnimationController _pulseController;
  late final AnimationController _progressController;
  late final Animation<double> _pulseAnimation;
  final _isDownloading = false.obs;
  final _downloadProgress = 0.0.obs;
  final _currentStatus = 'Connecting...'.obs;
  final _shadersDownloaded = false.obs;
  final _enableShaders = false.obs;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
    _checkShadersAvailability();
    _enableShaders.value = PlayerUiKeys.shadersEnabled.get<bool>(false);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _checkShadersAvailability() async {
    try {
      final shadersPath = await PlayerShaders.getShaderBasePath();
      final shadersDir = Directory(shadersPath);
      if (await shadersDir.exists()) {
        final files = await shadersDir.list().toList();
        _shadersDownloaded.value = files.isNotEmpty;
      }
    } catch (e) {
      Logger.i('Error checking shaders: $e');
    }
  }

  Future<void> _updateStatus(String status, double progress) async {
    _currentStatus.value = status;
    _downloadProgress.value = progress;
    _progressController.animateTo(progress);
  }

  Future<void> _downloadShaders() async {
    _isDownloading.value = true;
    _downloadProgress.value = 0.0;
    _currentStatus.value = 'Initializing download...';

    try {
      await _updateStatus('Connecting to server...', 0.05);
      await Future.delayed(const Duration(milliseconds: 500));

      final shadersPath = await PlayerShaders.getShaderBasePath();
      final mpvPath = Directory(shadersPath).path;

      final tempDir = await getTemporaryDirectory();
      final tempFilePath = '${tempDir.path}/anime4k_shaders.zip';
      final tempFile = File(tempFilePath);

      await _updateStatus('Downloading shaders...', 0.1);

      final dio = Dio();
      await dio.download(
        'https://github.com/RyanYuuki/AnymeX/raw/refs/heads/main/assets/shaders/shaders_new.zip',
        tempFilePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = 0.1 + (received / total) * 0.6;
            _updateStatus('Downloading shaders...', progress);
          }
        },
      );

      await _updateStatus('Download complete, extracting...', 0.75);
      await Future.delayed(const Duration(milliseconds: 500));

      final bytes = await tempFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      await _updateStatus('Extracting shader files...', 0.8);

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

      await _updateStatus('Finalizing installation...', 0.98);
      await Future.delayed(const Duration(milliseconds: 300));

      await _updateStatus('Installation complete!', 1.0);

      _isDownloading.value = false;
      _shadersDownloaded.value = true;
      _currentStatus.value = 'Shaders installed successfully!';
    } catch (e) {
      _isDownloading.value = false;
      _currentStatus.value = 'Download failed: $e';

      try {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/anime4k_shaders.zip');
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (_) {}
    }
  }

  Widget _buildKeybindingItem(String key, String description) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: colors.surfaceContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colors.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: colors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: AnymeXText(
              key,
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                color: colors.primary,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 16),
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
    final colors = context.colors;
    return AnymeXScaffold(
      showHeader: !widget.isModal,
      headerTitle: 'Anime4K & Shaders',
      body: Builder(
        builder: (ctx) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16.0,
            widget.isModal ? 16.0 : AnymeXHeaderScope.of(ctx),
            16.0,
            30.0,
          ),
          child: AnymeXSectionBuilder(
            title: 'Anime 4K Enhancement',
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colors.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                colors.primaryContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Iconsax.eye,
                            color: colors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnymeXText(
                                'Anime 4K Enhancement',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: colors.onSurface,
                                ),
                              ),
                              AnymeXText(
                                'Real-time 4K upscaling for anime content',
                                style: TextStyle(
                                  color:
                                      colors.onSurface.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Obx(() {
                      return Column(
                        children: [
                          if (_isDownloading.value) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colors.primaryContainer
                                    .withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      AnimatedBuilder(
                                        animation: _pulseAnimation,
                                        builder: (context, child) {
                                          return Transform.scale(
                                            scale: _pulseAnimation.value,
                                            child: Icon(
                                              Iconsax.document_download,
                                              color: colors.primary,
                                              size: 16,
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: AnymeXText(
                                          _currentStatus.value,
                                          style: TextStyle(
                                            color: colors.onSurface,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      AnymeXText(
                                        '${(_downloadProgress.value * 100).toInt()}%',
                                        style: TextStyle(
                                          color: colors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  LinearProgressIndicator(
                                    value: _downloadProgress.value,
                                    backgroundColor:
                                        colors.outline.withValues(alpha: 0.2),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        colors.primary),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ],
                              ),
                            ),
                          ] else if (_shadersDownloaded.value) ...[
                            Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: colors.primaryContainer
                                        .withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color:
                                          colors.primary.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Iconsax.play,
                                        color: colors.primary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            AnymeXText(
                                              'Enable Shaders',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: colors.onSurface,
                                              ),
                                            ),
                                            AnymeXText(
                                              getResponsiveValue(
                                                context,
                                                mobileValue:
                                                    'If enabled, shaders will be applied to the player through the HDR menu',
                                                desktopValue:
                                                    'If enabled, shaders will be applied to the player through keybindings',
                                              ),
                                              style: TextStyle(
                                                color: colors.onSurface
                                                    .withValues(alpha: 0.7),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Obx(() {
                                        return Switch(
                                          value: _enableShaders.value,
                                          onChanged: (value) {
                                            _enableShaders.value = value;
                                            PlayerUiKeys.shadersEnabled
                                                .set(_enableShaders.value);
                                          },
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: colors.primaryContainer
                                        .withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color:
                                          colors.primary.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Iconsax.play,
                                            color: colors.primary,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                AnymeXText(
                                                  'Choose Shader Profile',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    color: colors.onSurface,
                                                  ),
                                                ),
                                                AnymeXText(
                                                  'Choose according to your system specs.\nMid End = GTX 980, GTX 1060, RX 570\nHigh End = GTX 1080, RTX 2070, RTX 3060, RX 590',
                                                  style: TextStyle(
                                                    color: colors.onSurface
                                                        .withValues(alpha: 0.7),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      Obx(() {
                                        const availProfiles = [
                                          'MID-END',
                                          'HIGH-END'
                                        ];
                                        return Container(
                                          margin:
                                              const EdgeInsets.only(top: 20.0),
                                          child: AnymeXDropdown(
                                            items: availProfiles
                                                .map((e) => DropdownItem(
                                                    text: e, value: e))
                                                .toList(),
                                            selectedItem: DropdownItem(
                                              text: settings.selectedProfile,
                                              value: settings.selectedProfile,
                                            ),
                                            label: 'SELECT PROFILE',
                                            icon: Iconsax.play,
                                            onChanged: (e) =>
                                                settings.selectedProfile =
                                                    e.text,
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                AnimatedContainer(
                                  width: _enableShaders.value ? null : 0,
                                  curve: Curves.easeInOut,
                                  height: _enableShaders.value ? null : 0,
                                  duration: const Duration(milliseconds: 300),
                                  padding: EdgeInsets.all(
                                      _enableShaders.value ? 16 : 0),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: colors.errorContainer
                                        .withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color:
                                          colors.primary.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Iconsax.info_circle,
                                        color: colors.primary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            AnymeXText(
                                              'Warning',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: colors.onSurface,
                                              ),
                                            ),
                                            AnymeXText(
                                              getResponsiveValue(
                                                context,
                                                mobileValue:
                                                    'You might get a black screen or shaders may not work on unsupported devices.',
                                                desktopValue:
                                                    'Heavy shaders may drop frames on older GPUs.',
                                              ),
                                              style: TextStyle(
                                                color: colors.onErrorContainer
                                                    .withValues(alpha: 0.7),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                getResponsiveValue(
                                  context,
                                  mobileValue: const SizedBox.shrink(),
                                  strictMode: true,
                                  desktopValue: Obx(() {
                                    return AnimatedOpacity(
                                      opacity: _enableShaders.value ? 1 : 0.3,
                                      duration:
                                          const Duration(milliseconds: 300),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: colors.primaryContainer
                                              .withValues(alpha: 0.3),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: colors.primary
                                                .withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Iconsax.keyboard,
                                                  color: colors.primary,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      AnymeXText(
                                                        'Shader Profiles Initialized',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color:
                                                              colors.onSurface,
                                                        ),
                                                      ),
                                                      AnymeXText(
                                                        'Use keyboard shortcuts during playback to switch profiles',
                                                        style: TextStyle(
                                                          color: colors
                                                              .onSurface
                                                              .withValues(
                                                                  alpha: 0.7),
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            AnymeXText(
                                              'Available Keybindings:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: colors.onSurface,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            _buildKeybindingItem('CTRL + 1',
                                                'Anime4K: Mode A (Fast)'),
                                            _buildKeybindingItem('CTRL + 2',
                                                'Anime4K: Mode B (Fast)'),
                                            _buildKeybindingItem('CTRL + 3',
                                                'Anime4K: Mode C (Fast)'),
                                            _buildKeybindingItem('CTRL + 4',
                                                'Anime4K: Mode A+A (Fast)'),
                                            _buildKeybindingItem('CTRL + 5',
                                                'Anime4K: Mode B+B (Fast)'),
                                            _buildKeybindingItem('CTRL + 6',
                                                'Anime4K: Mode C+A (Fast)'),
                                            _buildKeybindingItem('CTRL + 0',
                                                'Reset (Clear Shaders)'),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ] else ...[
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _downloadShaders,
                                icon: const Icon(Iconsax.document_download),
                                label:
                                    const AnymeXText('Download 4K Shaders'),
                                style: FilledButton.styleFrom(
                                  backgroundColor:
                                      colors.primary.withValues(alpha: 0.9),
                                  foregroundColor: colors.onPrimary,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            AnymeXText(
                              'Download size: ~4MB',
                              style: TextStyle(
                                color: colors.onSurface.withValues(alpha: 0.6),
                                fontSize: 11,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
