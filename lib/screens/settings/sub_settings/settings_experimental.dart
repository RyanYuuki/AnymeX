import 'package:anymex/utils/logger.dart';

import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/utils/shaders.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/anymex_dropdown.dart';
import 'package:anymex/widgets/custom_widgets/custom_expansion_tile.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:dio/dio.dart';

class SettingsExperimental extends StatefulWidget {
  const SettingsExperimental({super.key});

  @override
  State<SettingsExperimental> createState() => _SettingsExperimentalState();
}

class _SettingsExperimentalState extends State<SettingsExperimental>
    with TickerProviderStateMixin {
  final settings = Get.find<Settings>();

  final _shadersDownloaded = false.obs;
  final _isDownloading = false.obs;
  final _downloadProgress = 0.0.obs;
  final _currentStatus = ''.obs;
  final _enableShaders = false.obs;

  final _cacheDays = 7.obs;

  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkShadersAvailability();
    getSavedSettings();
  }

  void getSavedSettings() {
    _enableShaders.value =
        settings.preferences.get('shaders_enabled', defaultValue: false);
    _cacheDays.value = settings.preferences.get('cache_days', defaultValue: 7);
  }

  void saveSettings() {
    settings.preferences.put('shaders_enabled', _enableShaders.value);
    settings.preferences.put('cache_days', _cacheDays.value);
  }

  void _initializeAnimations() {
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
  }

  Future<void> _checkShadersAvailability() async {
    try {
      final shadersPath = PlayerShaders.getShaderBasePath();
      final shadersDir = Directory(shadersPath);

      if (await shadersDir.exists()) {
        final files = await shadersDir.list().toList();
        _shadersDownloaded.value = files.isNotEmpty;
      }
    } catch (e) {
      print('Error checking shaders: $e');
    }
  }

  Future<void> _downloadShaders() async {
    _isDownloading.value = true;
    _downloadProgress.value = 0.0;
    _currentStatus.value = 'Initializing download...';

    try {
      await _updateStatus('Connecting to server...', 0.05);
      await Future.delayed(const Duration(milliseconds: 500));

      final shadersPath = PlayerShaders.getShaderBasePath();
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
          Logger.i('Path is: ${outFile.path}');

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
      } catch (cleanupError) {
        print('Cleanup error: $cleanupError');
      }
    }
  }

  Future<void> _updateStatus(String status, double progress) async {
    _currentStatus.value = status;
    _downloadProgress.value = progress;
    _progressController.animateTo(progress);
  }

  Widget _buildKeybindingItem(String key, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainer
            .withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              key,
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Glow(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          child: Padding(
            padding: getResponsiveValue(context,
                mobileValue: const EdgeInsets.fromLTRB(10.0, 50.0, 10.0, 20.0),
                desktopValue:
                    const EdgeInsets.fromLTRB(25.0, 50.0, 25.0, 20.0)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                children: [
                  IconButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainer
                          .withValues(alpha: 0.5),
                    ),
                    onPressed: () {
                      Get.back();
                    },
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  const SizedBox(width: 10),
                  const Text("Experimental Settings",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                ],
              ),
              const SizedBox(height: 30),
              Obx(() => AnymexExpansionTile(
                    title: "Reader",
                    initialExpanded: true,
                    content: Column(
                      children: [
                        CustomSliderTile(
                            icon: Icons.extension,
                            title: "Cache Duration",
                            label: "${_cacheDays.value} days",
                            description:
                                "When should the image cache be cleared?",
                            sliderValue: _cacheDays.value.toDouble(),
                            divisions: 30,
                            onChanged: (double value) {
                              _cacheDays.value = value.toInt();
                              saveSettings();
                            },
                            max: 30)
                      ],
                    ),
                  )),
              Obx(() {
                settings.animationDuration;
                return AnymexExpansionTile(
                  title: 'Player',
                  initialExpanded: true,
                  content: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withValues(alpha: 0.2),
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
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                      .withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Iconsax.eye,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Anime 4K Enhancement',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                    ),
                                    Text(
                                      'Real-time 4K upscaling for anime content',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Obx(
                            () {
                              return Column(
                                children: [
                                  if (_isDownloading.value) ...[
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primaryContainer
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
                                                    scale:
                                                        _pulseAnimation.value,
                                                    child: Icon(
                                                      Iconsax.document_download,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary,
                                                      size: 16,
                                                    ),
                                                  );
                                                },
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  _currentStatus.value,
                                                  style: TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurface,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                '${(_downloadProgress * 100).toInt()}%',
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          LinearProgressIndicator(
                                            value: _downloadProgress.value,
                                            backgroundColor: Theme.of(context)
                                                .colorScheme
                                                .outline
                                                .withValues(alpha: 0.2),
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(4),
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
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primaryContainer
                                                .withValues(alpha: 0.3),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Iconsax.play,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Enable Shaders',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurface,
                                                      ),
                                                    ),
                                                    Text(
                                                      getResponsiveValue(
                                                          context,
                                                          mobileValue:
                                                              'if Enabled the Shaders will be applied to the player through hdr menu',
                                                          desktopValue:
                                                              'if Enabled the Shaders will be applied to the player through keybindings'),
                                                      style: TextStyle(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurface
                                                            .withValues(
                                                                alpha: 0.7),
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
                                                    _enableShaders.value =
                                                        value;
                                                    saveSettings();
                                                  },
                                                );
                                              })
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primaryContainer
                                                .withValues(alpha: 0.3),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Iconsax.play,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          'Choose Shader Profile',
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .onSurface,
                                                          ),
                                                        ),
                                                        Text(
                                                          'Choose accordingly to your system specs.\nMid End = Eg. GTX 980, GTX 1060, RX 570\nHigh End = Eg. GTX 1080, RTX 2070, RTX 3060, RX 590, Vega 56',
                                                          style: TextStyle(
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
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
                                              Obx(() {
                                                List<String> availProfiles = [
                                                  'MID-END',
                                                  'HIGH-END'
                                                ];

                                                return Container(
                                                  margin: const EdgeInsets.only(
                                                      top: 20.0),
                                                  child: AnymexDropdown(
                                                      items: availProfiles
                                                          .map((e) =>
                                                              DropdownItem(
                                                                  text: e,
                                                                  value: e))
                                                          .toList(),
                                                      selectedItem: DropdownItem(
                                                          text: settingsController
                                                              .selectedProfile,
                                                          value: settingsController
                                                              .selectedProfile),
                                                      label: "SELECT PROFILE",
                                                      icon: Iconsax.play,
                                                      onChanged: (e) =>
                                                          settingsController
                                                                  .selectedProfile =
                                                              e.text),
                                                );
                                              })
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        AnimatedContainer(
                                          width:
                                              _enableShaders.value ? null : 0,
                                          curve: Curves.easeInOut,
                                          height:
                                              _enableShaders.value ? null : 0,
                                          duration:
                                              const Duration(milliseconds: 300),
                                          padding: EdgeInsets.all(
                                              _enableShaders.value ? 16 : 0),
                                          margin:
                                              const EdgeInsets.only(bottom: 8),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .errorContainer
                                                .withValues(alpha: 0.3),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Iconsax.info_circle,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Warning',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurface,
                                                      ),
                                                    ),
                                                    Text(
                                                      getResponsiveValue(
                                                          context,
                                                          mobileValue:
                                                              'you might get black screen or it may not work.',
                                                          desktopValue:
                                                              'will lag like hell on older gpus'),
                                                      style: TextStyle(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onErrorContainer
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
                                        ),
                                        getResponsiveValue(
                                          context,
                                          mobileValue: const SizedBox.shrink(),
                                          strictMode: true,
                                          desktopValue: Obx(() {
                                            return AnimatedOpacity(
                                              opacity: _enableShaders.value
                                                  ? 1
                                                  : 0.3,
                                              duration: const Duration(
                                                  milliseconds: 300),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primaryContainer
                                                      .withValues(alpha: 0.3),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary
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
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary,
                                                          size: 20,
                                                        ),
                                                        const SizedBox(
                                                            width: 12),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                'Shader Profiles Initialized',
                                                                style:
                                                                    TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color: Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .onSurface,
                                                                ),
                                                              ),
                                                              Text(
                                                                'Use keyboard shortcuts during playback to switch profiles',
                                                                style:
                                                                    TextStyle(
                                                                  color: Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .onSurface
                                                                      .withValues(
                                                                          alpha:
                                                                              0.7),
                                                                  fontSize: 12,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 16),
                                                    Text(
                                                      'Available Keybindings:',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurface,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    _buildKeybindingItem(
                                                        'CTRL + 1',
                                                        'Anime4K: Mode A (Fast)'),
                                                    _buildKeybindingItem(
                                                        'CTRL + 2',
                                                        'Anime4K: Mode B (Fast)'),
                                                    _buildKeybindingItem(
                                                        'CTRL + 3',
                                                        'Anime4K: Mode C (Fast)'),
                                                    _buildKeybindingItem(
                                                        'CTRL + 4',
                                                        'Anime4K: Mode A+A (Fast)'),
                                                    _buildKeybindingItem(
                                                        'CTRL + 5',
                                                        'Anime4K: Mode B+B (Fast)'),
                                                    _buildKeybindingItem(
                                                        'CTRL + 6',
                                                        'Anime4K: Mode C+A (Fast)'),
                                                    _buildKeybindingItem(
                                                        'CTRL + 0',
                                                        'Reset (Clear Shaders)'),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }),
                                        ),
                                      ],
                                    )
                                  ] else ...[
                                    SizedBox(
                                      width: double.infinity,
                                      child: FilledButton.icon(
                                        onPressed: _downloadShaders,
                                        icon: const Icon(
                                            Iconsax.document_download),
                                        label:
                                            const Text('Download 4K Shaders'),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.9),
                                          foregroundColor: Theme.of(context)
                                              .colorScheme
                                              .onPrimary,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Download size: ~4MB',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.6),
                                        fontSize: 11,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ],
                              );
                            },
                          )
                        ],
                      )),
                );
              }),
            ]),
          ),
        ),
      ),
    );
  }
}
