import 'dart:convert';

import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/shaders.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dropdown.dart';
import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'package:anymex/constants/contants.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/screens/anime/watch/controls/themes/setup/media_indicator_theme_registry.dart';
import 'package:anymex/screens/anime/watch/controls/themes/setup/player_control_theme_registry.dart';

import 'package:anymex/screens/settings/sub_settings/widgets/settings_json_shared.dart';
import 'package:anymex/utils/player_core_visual_settings.dart';
import 'package:anymex/utils/subtitle_style_renderer.dart';
import 'package:anymex/utils/subtitle_translator.dart';
import 'package:anymex/utils/theme_extensions.dart';

import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/non_widgets/reusable_checkmark.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconsax/iconsax.dart';

const Map<String, List<String>> fontGroups = {
  'Default': ['Default'],
  'Latin': ['Trebuchet', 'Bahnschrift', 'Tahoma', 'Anime Ace 3', 'Poppins'],
  'Japanese': ['Cinecaption'],
};

class SettingsPlayer extends StatefulWidget {
  final bool isModal;
  const SettingsPlayer({super.key, this.isModal = false});

  @override
  State<SettingsPlayer> createState() => _SettingsPlayerState();
}

class _BottomControl {
  final String id;
  final String name;
  final IconData icon;
  final String defaultPosition;

  const _BottomControl({
    required this.id,
    required this.name,
    required this.icon,
    this.defaultPosition = 'right',
  });
}

class _DecoderOption {
  final String value;
  final String title;
  final String description;

  const _DecoderOption({
    required this.value,
    required this.title,
    required this.description,
  });
}

class _RendererOption {
  final String value;
  final String title;
  final String description;

  const _RendererOption({
    required this.value,
    required this.title,
    required this.description,
  });
}

class _AudioOption {
  final String value;
  final String title;
  final String description;

  const _AudioOption({
    required this.value,
    required this.title,
    required this.description,
  });
}

final List<_BottomControl> _bottomControls = [
  const _BottomControl(
      id: 'playlist',
      name: 'Playlist',
      icon: Icons.playlist_play_rounded,
      defaultPosition: 'left'),
  const _BottomControl(
      id: 'shaders', name: 'Shaders', icon: Icons.tune_rounded),
  const _BottomControl(
      id: 'source', name: 'Quality', icon: Icons.high_quality_rounded),
  const _BottomControl(
      id: 'tracks', name: 'Subtitles', icon: Icons.subtitles_rounded),
  const _BottomControl(
      id: 'audio', name: 'Audio', icon: Icons.volume_up_rounded),
  const _BottomControl(
      id: 'sync_subs', name: 'Sync Subs', icon: Icons.sync_rounded),
  const _BottomControl(id: 'speed', name: 'Speed', icon: Icons.speed_rounded),
  const _BottomControl(
      id: 'orientation',
      name: 'Orientation',
      icon: Icons.screen_rotation_rounded),
  const _BottomControl(
      id: 'aspect_ratio', name: 'Aspect Ratio', icon: Icons.fit_screen),
  const _BottomControl(
      id: 'external_player',
      name: 'External Player',
      icon: Icons.launch_rounded),
  const _BottomControl(
      id: 'watch_together',
      name: 'Watch Together',
      icon: Icons.people_outline_rounded,
      defaultPosition: 'right'),
];

class _SettingsPlayerState extends State<SettingsPlayer>
    with TickerProviderStateMixin {
  final settings = Get.find<Settings>();
  RxDouble speed = 0.0.obs;
  Rx<Color> subtitleColor = Colors.white.obs;
  Rx<Color> backgroundColor = Colors.black.obs;
  Rx<Color> outlineColor = Colors.black.obs;
  final styles = ['Regular', 'Accent', 'Blurred Accent'];
  final selectedStyleIndex = 0.obs;

  // Anime 4K Enhancement Variables
  late final AnimationController _pulseController;
  late final AnimationController _progressController;
  late final Animation<double> _pulseAnimation;
  final _isDownloading = false.obs;
  final _downloadProgress = 0.0.obs;
  final _currentStatus = 'Connecting...'.obs;
  final _shadersDownloaded = false.obs;
  final _enableShaders = false.obs;

  late List<String> _leftButtonIds;
  late List<String> _rightButtonIds;
  late List<String> _hiddenButtonIds;
  late Map<String, dynamic> _buttonConfigs;
  bool _shouldApplyResizeModeOnClose = false;
  late bool _useLibass;
  late bool _useExternalPlayer;

  @override
  void initState() {
    super.initState();
    speed.value = settings.speed;
    selectedStyleIndex.value = settings.playerStyle;

    _leftButtonIds = [];
    _rightButtonIds = [];
    _hiddenButtonIds = [];
    _buttonConfigs = {};
    _useLibass = PlayerKeys.useLibass.get<bool>(false);
    _useExternalPlayer = PlayerKeys.useExternalPlayer.get<bool>(false);

    final String jsonString =
        PlayerUiKeys.bottomControlsSettings.get<String>('{}');
    final Map<String, dynamic> decodedConfig = json.decode(jsonString);

    if (decodedConfig.isEmpty) _initializeDefaultButtonLayout();

    _leftButtonIds = List<String>.from(decodedConfig['leftButtonIds'] ?? []);
    _rightButtonIds = List<String>.from(decodedConfig['rightButtonIds'] ?? []);
    _hiddenButtonIds =
        List<String>.from(decodedConfig['hiddenButtonIds'] ?? []);
    _buttonConfigs =
        Map<String, dynamic>.from(decodedConfig['buttonConfigs'] ?? {});

    if (_leftButtonIds.isEmpty &&
        _rightButtonIds.isEmpty &&
        _hiddenButtonIds.isEmpty &&
        _bottomControls.isNotEmpty) {
      _initializeDefaultButtonLayout();
    } else {
      _migrateLegacyButtons();
      _pruneRemovedButtons();
      _addNewButtons();
    }
    _initializeAnimations();
    _checkShadersAvailability();
    _enableShaders.value = PlayerUiKeys.shadersEnabled.get<bool>(false);
  }

  void _migrateLegacyButtons() {
    final legacyToNew = {
      'server': 'source',
      'subtitles': 'tracks',
      'audio_track': 'audio',
      'quality': 'source',
    };

    bool migrated = false;

    void replaceInList(List<String> list) {
      for (int i = 0; i < list.length; i++) {
        if (legacyToNew.containsKey(list[i])) {
          list[i] = legacyToNew[list[i]]!;
          migrated = true;
        }
      }
    }

    replaceInList(_leftButtonIds);
    replaceInList(_rightButtonIds);
    replaceInList(_hiddenButtonIds);

    final seen = <String>{};
    void deduplicate(List<String> list) {
      list.removeWhere((id) {
        if (seen.contains(id)) {
          migrated = true;
          return true;
        }
        seen.add(id);
        return false;
      });
    }

    deduplicate(_leftButtonIds);
    deduplicate(_rightButtonIds);
    deduplicate(_hiddenButtonIds);

    final essential = [
      'source',
      'tracks',
      'audio',
      'sync_subs',
      'external_player'
    ];
    for (final id in essential) {
      if (!seen.contains(id)) {
        _rightButtonIds.add(id);
        _buttonConfigs[id] = {'visible': true};
        migrated = true;
      }
    }

    if (migrated) {
      _saveButtonConfig();
    }
  }

  void _saveButtonConfig() {
    final Map<String, dynamic> configToSave = {
      'leftButtonIds': _leftButtonIds,
      'rightButtonIds': _rightButtonIds,
      'hiddenButtonIds': _hiddenButtonIds,
      'buttonConfigs': _buttonConfigs,
    };
    PlayerUiKeys.bottomControlsSettings.set(json.encode(configToSave));
    if (mounted) {
      setState(() {});
    }
  }

  void _initializeDefaultButtonLayout() {
    _leftButtonIds = [];
    _rightButtonIds = [];
    _hiddenButtonIds = [];
    _buttonConfigs = {};
    for (final control in _bottomControls) {
      if (control.defaultPosition == 'left') {
        _leftButtonIds.add(control.id);
      } else {
        _rightButtonIds.add(control.id);
      }
      _buttonConfigs[control.id] = {'visible': true};
    }
    _saveButtonConfig();
  }

  void _pruneRemovedButtons() {
    final allKnownIds = _bottomControls.map((c) => c.id).toSet();
    bool changed = false;

    int initialLeftCount = _leftButtonIds.length;
    _leftButtonIds.removeWhere((id) => !allKnownIds.contains(id));
    if (_leftButtonIds.length != initialLeftCount) changed = true;

    int initialRightCount = _rightButtonIds.length;
    _rightButtonIds.removeWhere((id) => !allKnownIds.contains(id));
    if (_rightButtonIds.length != initialRightCount) changed = true;

    int initialHiddenCount = _hiddenButtonIds.length;
    _hiddenButtonIds.removeWhere((id) => !allKnownIds.contains(id));
    if (_hiddenButtonIds.length != initialHiddenCount) changed = true;

    int initialConfigCount = _buttonConfigs.length;
    _buttonConfigs.removeWhere((id, _) => !allKnownIds.contains(id));
    if (_buttonConfigs.length != initialConfigCount) changed = true;

    if (changed) _saveButtonConfig();
  }

  /// Adds any new buttons that were added in app updates but aren't
  /// in the user's saved config yet (auto-migration for new buttons).
  void _addNewButtons() {
    final allUserIds = {
      ..._leftButtonIds,
      ..._rightButtonIds,
      ..._hiddenButtonIds,
    };
    bool changed = false;
    for (final control in _bottomControls) {
      if (!allUserIds.contains(control.id)) {
        final position = control.defaultPosition == 'left'
            ? _leftButtonIds
            : _rightButtonIds;
        position.add(control.id);
        _buttonConfigs[control.id] = {'visible': true};
        changed = true;
      }
    }
    if (changed) _saveButtonConfig();
  }

  void _hideButton(String id) {
    _leftButtonIds.remove(id);
    _rightButtonIds.remove(id);
    if (!_hiddenButtonIds.contains(id)) {
      _hiddenButtonIds.add(id);
    }
    _saveButtonConfig();
  }

  void _showButton(String id, String position) {
    _hiddenButtonIds.remove(id);
    if (position == 'left') {
      if (!_leftButtonIds.contains(id)) {
        _leftButtonIds.add(id);
      }
    } else {
      if (!_rightButtonIds.contains(id)) {
        _rightButtonIds.add(id);
      }
    }
    _saveButtonConfig();
  }

  void _moveButton(String id, String to) {
    if (to == 'left') {
      _rightButtonIds.remove(id);
      _leftButtonIds.add(id);
    } else {
      _leftButtonIds.remove(id);
      _rightButtonIds.add(id);
    }
    _saveButtonConfig();
  }

  String numToPlayerStyle(int i) {
    return (i >= 0 && i < styles.length) ? styles[i] : 'Unknown';
  }

  int styleToNum(String i) {
    return styles.indexOf(i);
  }

  void _showPlaybackSpeedDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AnymeXDialog(
          title: 'PlayBack Speeds',
          showCancelButton: false,
          confirmText: 'Close',
          onConfirm: () {},
          contentWidget: Obx(() {
            return AnymeXTileBuilder<double>(
              items: cursedSpeed,
              selectedItem: speed.value,
              getTitle: (s) => '${s.toStringAsFixed(2)}x',
              onItemPressed: (s) {
                speed.value = s;
                settings.speed = s;
              },
            );
          }),
        );
      },
    );
  }

  void showPlayerStyleDialog() {
    showSelectionDialog<int>(
        title: "Player Theme",
        items: [0, 1, 2],
        selectedItem: selectedStyleIndex,
        getTitle: (i) => numToPlayerStyle(i),
        onItemSelected: (i) {
          selectedStyleIndex.value = i;
          settings.playerStyle = i;
        });
  }

  void _showPlayerControlThemeDialog() {
    showSelectionDialog<String>(
      title: 'Control Theme',
      items: PlayerControlThemeRegistry.themes.map((e) => e.id).toList(),
      selectedItem: settings.playerControlThemeRx,
      getTitle: (id) => PlayerControlThemeRegistry.resolve(id).name,
      onItemSelected: (id) {
        settings.playerControlTheme = id;
        setState(() {});
      },
      leadingIcon: Icons.style_rounded,
    );
  }

  void _showMediaIndicatorThemeDialog() {
    showSelectionDialog<String>(
      title: 'Swipe Indicator Theme',
      items: MediaIndicatorThemeRegistry.themes.map((e) => e.id).toList(),
      selectedItem: settings.mediaIndicatorThemeRx,
      getTitle: (id) => MediaIndicatorThemeRegistry.resolve(id).name,
      onItemSelected: (id) {
        settings.mediaIndicatorTheme = id;
        setState(() {});
      },
      leadingIcon: Icons.tune_rounded,
    );
  }

  void _showResizeModeDialog() {
    final currentFit = settings.resizeMode;
    final selectedLabel = resizeModeList.firstWhere(
      (lbl) =>
          (resizeModes[lbl]?.name.toLowerCase() ?? '') ==
          currentFit.toLowerCase(),
      orElse: () => resizeModeList.first,
    );

    showSelectionDialog<String>(
      title: 'Resize Modes',
      items: resizeModeList,
      selectedItem: selectedLabel.obs,
      getTitle: (item) => item,
      onItemSelected: (selected) {
        final fit = resizeModes[selected];
        if (fit != null) {
          settings.resizeMode = fit.name;
          _shouldApplyResizeModeOnClose = true;
        }
      },
      leadingIcon: Icons.crop,
    );
  }

  @override
  void dispose() {
    final shouldApplyResizeOnClose =
        widget.isModal && _shouldApplyResizeModeOnClose;
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
    if (!shouldApplyResizeOnClose) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!Get.isRegistered<PlayerController>()) return;
      final controller = Get.find<PlayerController>();
      if (controller.isClosed) return;
      controller.applyConfiguredResizeMode();
    });
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
      final shadersPath = await PlayerShaders.getShaderBasePath();
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
          color: context.colors.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.3),
              ),
            ),
            child: AnymeXText(
              key,
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                color: context.colors.primary,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: AnymeXText(
              description,
              style: TextStyle(
                color: context.colors.onSurface,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showColorSelectionDialog(String title, Color currentColor,
      Function(String) onColorSelected, Map<String, Color> options) {
    AnymeXDialog(
      title: title,
      onConfirm: () {},
      showCancelButton: false,
      confirmText: 'Close',
      contentWidget: AnymeXTileBuilder<String>(
        getTitle: (t) => t,
        onItemPressed: (s) {
          onColorSelected(s);
          Navigator.pop(context);
        },
        selectedItem: options.entries
            .firstWhere((entry) => entry.value == currentColor,
                orElse: () => const MapEntry('', Colors.transparent))
            .key,
        items: options.keys.toList(),
      ),
    ).show(context);
  }

  void _showTranslationLanguageDialog() {
    showSelectionDialog<String>(
      title: "Translation Language",
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
      title: "Select Subtitle Font",
      onConfirm: () {},
      showCancelButton: false,
      confirmText: 'Close',
      contentWidget: Column(
        mainAxisSize: MainAxisSize.min,
        children: fontGroups.entries.map((group) {
          return AnymeXSectionBuilder(
              title: group.key,
              children: group.value
                  .map((font) => AnymeXTile.radio(
                        selected:
                            settings.playerSettings.value.subtitleFont == font,
                        title: font,
                        onTap: () {
                          final current = settings.playerSettings.value;
                          current.subtitleFont = font;
                          PlayerSettingsKeys.subtitleFont.set(font);
                          settings.playerSettings.refresh();
                          Navigator.pop(context);
                        },
                      ))
                  .toList());
        }).toList(),
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
      title: "Outline Type",
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

  bool get _supportsDecoderSelection =>
      Platform.isAndroid ||
      Platform.isIOS ||
      Platform.isLinux ||
      Platform.isMacOS ||
      Platform.isWindows;

  List<_DecoderOption> get _decoderOptions {
    if (Platform.isAndroid) {
      return const [
        _DecoderOption(
          value: 'hw+',
          title: 'HW+',
          description: 'mediacodec-copy',
        ),
        _DecoderOption(
          value: 'hw',
          title: 'HW',
          description: 'mediacodec',
        ),
        _DecoderOption(
          value: 'sw',
          title: 'SW',
          description: 'no',
        ),
      ];
    }

    if (Platform.isIOS || Platform.isMacOS) {
      return const [
        _DecoderOption(
          value: 'hw+',
          title: 'HW+',
          description: 'videotoolbox',
        ),
        _DecoderOption(
          value: 'hw',
          title: 'HW',
          description: 'videotoolbox',
        ),
        _DecoderOption(
          value: 'sw',
          title: 'SW',
          description: 'no',
        ),
      ];
    }

    if (Platform.isWindows) {
      return const [
        _DecoderOption(
          value: 'hw+',
          title: 'HW+',
          description: 'd3d11va-copy',
        ),
        _DecoderOption(
          value: 'hw',
          title: 'HW',
          description: 'd3d11va',
        ),
        _DecoderOption(
          value: 'sw',
          title: 'SW',
          description: 'no',
        ),
      ];
    }

    if (Platform.isLinux) {
      return const [
        _DecoderOption(
          value: 'hw+',
          title: 'HW+',
          description: 'vaapi-copy',
        ),
        _DecoderOption(
          value: 'hw',
          title: 'HW',
          description: 'vaapi',
        ),
        _DecoderOption(
          value: 'sw',
          title: 'SW',
          description: 'no',
        ),
      ];
    }

    return const [
      _DecoderOption(
        value: 'hw+',
        title: 'HW+',
        description: 'auto-copy',
      ),
      _DecoderOption(
        value: 'hw',
        title: 'HW',
        description: 'auto',
      ),
      _DecoderOption(
        value: 'sw',
        title: 'SW',
        description: 'no',
      ),
    ];
  }

  List<_RendererOption> get _rendererOptions {
    final list = [
      const _RendererOption(
        value: 'auto',
        title: 'Auto (GPU)',
        description: 'Auto-select (default)',
      ),
      const _RendererOption(
        value: 'gpu',
        title: 'GPU',
        description: 'Standard GPU rendering',
      ),
      const _RendererOption(
        value: 'gpu-next',
        title: 'GPU Next (Vulkan)',
        description: 'Experimental high-performance renderer',
      ),
    ];

    if (Platform.isAndroid) {
      list.add(
        const _RendererOption(
          value: 'mediacodec_embed',
          title: 'MediaCodec Embed',
          description: 'Direct surface rendering (Android only)',
        ),
      );
    }
    return list;
  }

  String _rendererTitle(String value) {
    final match = _rendererOptions.firstWhere(
      (option) => option.value == value,
      orElse: () => _rendererOptions.first,
    );
    return match.title;
  }

  String _rendererDescription(String value) {
    final match = _rendererOptions.firstWhere(
      (option) => option.value == value,
      orElse: () => _rendererOptions.first,
    );
    return match.description;
  }

  void _showRendererSelectionDialog() {
    final options = _rendererOptions;
    if (options.isEmpty) return;

    showSelectionDialog<String>(
      title: 'Video Renderer',
      items: options.map((option) => option.value).toList(),
      selectedItem: settings.videoOutput.obs,
      getTitle: _rendererTitle,
      onItemSelected: (value) {
        settings.videoOutput = value;
        setState(() {});
      },
      leadingIcon: Icons.settings_system_daydream_rounded,
    );
  }

  List<_AudioOption> get _audioOptions {
    final list = <_AudioOption>[];
    if (Platform.isAndroid) {
      list.addAll([
        const _AudioOption(
          value: 'auto',
          title: 'Auto (AudioTrack)',
          description: 'Default Android AudioTrack API',
        ),
        const _AudioOption(
          value: 'audiotrack',
          title: 'AudioTrack',
          description: 'Android AudioTrack API',
        ),
        const _AudioOption(
          value: 'opensles',
          title: 'OpenSL ES',
          description: 'OpenSL ES native audio engine',
        ),
      ]);
    } else if (Platform.isWindows) {
      list.addAll([
        const _AudioOption(
          value: 'auto',
          title: 'Auto (WASAPI)',
          description: 'Default Windows audio driver',
        ),
        const _AudioOption(
          value: 'wasapi',
          title: 'WASAPI',
          description: 'Windows Audio Session API',
        ),
        const _AudioOption(
          value: 'sdl',
          title: 'SDL',
          description: 'Simple DirectMedia Layer audio output',
        ),
      ]);
    } else if (Platform.isIOS || Platform.isMacOS) {
      list.addAll([
        const _AudioOption(
          value: 'auto',
          title: 'Auto (CoreAudio)',
          description: 'Default Apple CoreAudio API',
        ),
        const _AudioOption(
          value: 'coreaudio',
          title: 'CoreAudio',
          description: 'Apple CoreAudio API',
        ),
      ]);
    } else if (Platform.isLinux) {
      list.addAll([
        const _AudioOption(
          value: 'auto',
          title: 'Auto (PulseAudio)',
          description: 'Default PulseAudio API',
        ),
        const _AudioOption(
          value: 'pulse',
          title: 'PulseAudio',
          description: 'PulseAudio sound server',
        ),
        const _AudioOption(
          value: 'alsa',
          title: 'ALSA',
          description: 'Advanced Linux Sound Architecture',
        ),
        const _AudioOption(
          value: 'sdl',
          title: 'SDL',
          description: 'Simple DirectMedia Layer audio output',
        ),
      ]);
    } else {
      list.add(
        const _AudioOption(
          value: 'auto',
          title: 'Auto',
          description: 'Default system audio driver',
        ),
      );
    }
    return list;
  }

  String _audioTitle(String value) {
    final match = _audioOptions.firstWhere(
      (option) => option.value == value,
      orElse: () => _audioOptions.first,
    );
    return match.title;
  }

  String _audioDescription(String value) {
    final match = _audioOptions.firstWhere(
      (option) => option.value == value,
      orElse: () => _audioOptions.first,
    );
    return match.description;
  }

  void _showAudioSelectionDialog() {
    final options = _audioOptions;
    if (options.isEmpty) return;

    showSelectionDialog<String>(
      title: 'Audio Engine',
      items: options.map((option) => option.value).toList(),
      selectedItem: settings.audioOutput.obs,
      getTitle: _audioTitle,
      onItemSelected: (value) {
        settings.audioOutput = value;
        setState(() {});
      },
      leadingIcon: Icons.audiotrack_rounded,
    );
  }

  String _decoderTitle(String value) {
    final match = _decoderOptions.firstWhere(
      (option) => option.value == value,
      orElse: () => _decoderOptions.first,
    );
    return match.title;
  }

  String _decoderDescription(String value) {
    final match = _decoderOptions.firstWhere(
      (option) => option.value == value,
      orElse: () => _decoderOptions.first,
    );
    return match.description;
  }

  void _showDecoderModeDialog() {
    final options = _decoderOptions;
    if (options.isEmpty) return;

    showSelectionDialog<String>(
      title: 'Decoder',
      items: options.map((option) => option.value).toList(),
      selectedItem: settings.hardwareDecoder.obs,
      getTitle: _decoderTitle,
      onItemSelected: (value) {
        settings.hardwareDecoder = value;
        setState(() {});
      },
      leadingIcon: Icons.memory_rounded,
    );
  }

  void _showMpvCoreSelectionDialog({
    required String title,
    required List<String> items,
    required String selected,
    required String Function(String) getTitle,
    required String key,
  }) {
    showSelectionDialog<String>(
      title: title,
      items: items,
      selectedItem: selected.obs,
      getTitle: getTitle,
      onItemSelected: (value) {
        PlayerCoreVisualSettings.setMpvCoreSetting(key, value);
        setState(() {});
      },
      leadingIcon: Icons.tune_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnymeXScaffold(
      showHeader: !widget.isModal,
      headerTitle: 'Player Settings',
      body: Builder(
          builder: (ctx) => SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    16.0,
                    widget.isModal ? 10.0 : AnymeXHeaderScope.of(ctx),
                    16.0,
                    30.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.isModal) ...[
                      const Center(
                        child: AnymeXText("Player Settings",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20)),
                      ),
                      const SizedBox(height: 10),
                    ],
                    SizedBox(height: widget.isModal ? 30.0 : 0),
                    Obx(
                      () => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_supportsDecoderSelection)
                            AnymeXSectionBuilder(
                              title: 'Playback',
                              children: [
                                AnymeXTile(
                                  icon: Icons.memory_rounded,
                                  title: 'Decoder',
                                  subtitle: _decoderDescription(
                                      settings.hardwareDecoder),
                                  onTap: _showDecoderModeDialog,
                                ),
                                AnymeXTile(
                                  icon: Icons.settings_system_daydream_rounded,
                                  title: 'Video Renderer',
                                  subtitle: _rendererDescription(
                                      settings.videoOutput),
                                  onTap: _showRendererSelectionDialog,
                                ),
                                AnymeXTile(
                                  icon: Icons.audiotrack_rounded,
                                  title: 'Audio Engine',
                                  subtitle:
                                      _audioDescription(settings.audioOutput),
                                  onTap: _showAudioSelectionDialog,
                                ),
                              ],
                            ),
                          AnymeXSectionBuilder(
                            title: 'Anime 4K Enhancement',
                            children: [
                              Container(
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
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            Iconsax.eye,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              AnymeXText(
                                                'Anime 4K Enhancement',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                ),
                                              ),
                                              AnymeXText(
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
                                                padding:
                                                    const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primaryContainer
                                                      .withValues(alpha: 0.3),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Column(
                                                  children: [
                                                    Row(
                                                      children: [
                                                        AnimatedBuilder(
                                                          animation:
                                                              _pulseAnimation,
                                                          builder:
                                                              (context, child) {
                                                            return Transform
                                                                .scale(
                                                              scale:
                                                                  _pulseAnimation
                                                                      .value,
                                                              child: Icon(
                                                                Iconsax
                                                                    .document_download,
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .primary,
                                                                size: 16,
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                        const SizedBox(
                                                            width: 8),
                                                        Expanded(
                                                          child: AnymeXText(
                                                            _currentStatus
                                                                .value,
                                                            style: TextStyle(
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .onSurface,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                        ),
                                                        AnymeXText(
                                                          '${(_downloadProgress.value * 100).toInt()}%',
                                                          style: TextStyle(
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .primary,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 12),
                                                    LinearProgressIndicator(
                                                      value: _downloadProgress
                                                          .value,
                                                      backgroundColor:
                                                          Theme.of(context)
                                                              .colorScheme
                                                              .outline
                                                              .withValues(
                                                                  alpha: 0.2),
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                              Color>(
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .primary,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ] else if (_shadersDownloaded
                                                .value) ...[
                                              Column(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            16),
                                                    decoration: BoxDecoration(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primaryContainer
                                                          .withValues(
                                                              alpha: 0.3),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      border: Border.all(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .primary
                                                            .withValues(
                                                                alpha: 0.3),
                                                      ),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Iconsax.play,
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
                                                              AnymeXText(
                                                                'Enable Shaders',
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
                                                              AnymeXText(
                                                                getResponsiveValue(
                                                                    context,
                                                                    mobileValue:
                                                                        'if Enabled the Shaders will be applied to the player through hdr menu',
                                                                    desktopValue:
                                                                        'if Enabled the Shaders will be applied to the player through keybindings'),
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
                                                        Obx(() {
                                                          return Switch(
                                                            value:
                                                                _enableShaders
                                                                    .value,
                                                            onChanged: (value) {
                                                              _enableShaders
                                                                      .value =
                                                                  value;
                                                              PlayerUiKeys
                                                                  .shadersEnabled
                                                                  .set(_enableShaders
                                                                      .value);
                                                            },
                                                          );
                                                        })
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            16),
                                                    decoration: BoxDecoration(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primaryContainer
                                                          .withValues(
                                                              alpha: 0.3),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      border: Border.all(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .primary
                                                            .withValues(
                                                                alpha: 0.3),
                                                      ),
                                                    ),
                                                    child: Column(
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Icon(
                                                              Iconsax.play,
                                                              color: Theme.of(
                                                                      context)
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
                                                                  AnymeXText(
                                                                    'Choose Shader Profile',
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
                                                                  AnymeXText(
                                                                    'Choose accordingly to your system specs.\nMid End = Eg. GTX 980, GTX 1060, RX 570\nHigh End = Eg. GTX 1080, RTX 2070, RTX 3060, RX 590, Vega 56',
                                                                    style:
                                                                        TextStyle(
                                                                      color: Theme.of(
                                                                              context)
                                                                          .colorScheme
                                                                          .onSurface
                                                                          .withValues(
                                                                              alpha: 0.7),
                                                                      fontSize:
                                                                          12,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        Obx(() {
                                                          List<String>
                                                              availProfiles = [
                                                            'MID-END',
                                                            'HIGH-END'
                                                          ];

                                                          return Container(
                                                            margin:
                                                                const EdgeInsets
                                                                    .only(
                                                                    top: 20.0),
                                                            child: AnymeXDropdown(
                                                                items: availProfiles
                                                                    .map((e) => DropdownItem(
                                                                        text: e,
                                                                        value:
                                                                            e))
                                                                    .toList(),
                                                                selectedItem: DropdownItem(
                                                                    text: settingsController
                                                                        .selectedProfile,
                                                                    value: settingsController
                                                                        .selectedProfile),
                                                                label:
                                                                    "SELECT PROFILE",
                                                                icon: Iconsax
                                                                    .play,
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
                                                    width: _enableShaders.value
                                                        ? null
                                                        : 0,
                                                    curve: Curves.easeInOut,
                                                    height: _enableShaders.value
                                                        ? null
                                                        : 0,
                                                    duration: const Duration(
                                                        milliseconds: 300),
                                                    padding: EdgeInsets.all(
                                                        _enableShaders.value
                                                            ? 16
                                                            : 0),
                                                    margin:
                                                        const EdgeInsets.only(
                                                            bottom: 8),
                                                    decoration: BoxDecoration(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .errorContainer
                                                          .withValues(
                                                              alpha: 0.3),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      border: Border.all(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .primary
                                                            .withValues(
                                                                alpha: 0.3),
                                                      ),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Iconsax.info_circle,
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
                                                              AnymeXText(
                                                                'Warning',
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
                                                              AnymeXText(
                                                                getResponsiveValue(
                                                                    context,
                                                                    mobileValue:
                                                                        'you might get black screen or it may not work.',
                                                                    desktopValue:
                                                                        'will lag like hell on older gpus'),
                                                                style:
                                                                    TextStyle(
                                                                  color: Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .onErrorContainer
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
                                                  ),
                                                  getResponsiveValue(
                                                    context,
                                                    mobileValue:
                                                        const SizedBox.shrink(),
                                                    strictMode: true,
                                                    desktopValue: Obx(() {
                                                      return AnimatedOpacity(
                                                        opacity:
                                                            _enableShaders.value
                                                                ? 1
                                                                : 0.3,
                                                        duration:
                                                            const Duration(
                                                                milliseconds:
                                                                    300),
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(16),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .primaryContainer
                                                                .withValues(
                                                                    alpha: 0.3),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                            border: Border.all(
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .primary
                                                                  .withValues(
                                                                      alpha:
                                                                          0.3),
                                                            ),
                                                          ),
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Row(
                                                                children: [
                                                                  Icon(
                                                                    Iconsax
                                                                        .keyboard,
                                                                    color: Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .primary,
                                                                    size: 20,
                                                                  ),
                                                                  const SizedBox(
                                                                      width:
                                                                          12),
                                                                  Expanded(
                                                                    child:
                                                                        Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                      children: [
                                                                        AnymeXText(
                                                                          'Shader Profiles Initialized',
                                                                          style:
                                                                              TextStyle(
                                                                            fontWeight:
                                                                                FontWeight.w600,
                                                                            color:
                                                                                context.colors.onSurface,
                                                                          ),
                                                                        ),
                                                                        AnymeXText(
                                                                          'Use keyboard shortcuts during playback to switch profiles',
                                                                          style:
                                                                              TextStyle(
                                                                            color:
                                                                                context.colors.onSurface.withValues(alpha: 0.7),
                                                                            fontSize:
                                                                                12,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              const SizedBox(
                                                                  height: 16),
                                                              AnymeXText(
                                                                'Available Keybindings:',
                                                                style:
                                                                    TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color: Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .onSurface,
                                                                  fontSize: 13,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                  height: 12),
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
                                                  icon: const Icon(Iconsax
                                                      .document_download),
                                                  label: const AnymeXText(
                                                      'Download 4K Shaders'),
                                                  style: FilledButton.styleFrom(
                                                    backgroundColor:
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .primary
                                                            .withValues(
                                                                alpha: 0.9),
                                                    foregroundColor:
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .onPrimary,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 16),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              AnymeXText(
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
                                ),
                              ),
                            ],
                          ),
                          AnymeXSectionBuilder(
                            title: 'Experimental',
                            children: [
                              Builder(builder: (context) {
                                final experimentalEnabled = PlayerUiKeys
                                    .playerExperimentalEnabled
                                    .get<bool>(false);
                                final mpvCore = PlayerCoreVisualSettings
                                    .getMpvCoreSettings();

                                return Column(
                                  children: [
                                    AnymeXTile.toggle(
                                      icon: Icons.science_outlined,
                                      title: 'Enable Experimental Settings',
                                      subtitle:
                                          'Required for Core and Visual tuning. Keep off on low-end devices.',
                                      value: experimentalEnabled,
                                      onChanged: (val) {
                                        PlayerUiKeys.playerExperimentalEnabled
                                            .set<bool>(val);
                                        setState(() {});
                                      },
                                    ),
                                    if (!experimentalEnabled)
                                      _buildExperimentalGateMessage(
                                          'Core and Visual settings are disabled. Enable Experimental to use them.'),
                                    if (experimentalEnabled)
                                      Column(
                                        children: [
                                          AnymeXTile(
                                            icon: Icons.sync_rounded,
                                            title: 'Video Sync',
                                            subtitle: (mpvCore['videoSync']
                                                    as String?) ??
                                                'audio',
                                            onTap: () =>
                                                _showMpvCoreSelectionDialog(
                                              title: 'Video Sync',
                                              items: const [
                                                'audio',
                                                'display-resample',
                                                'display-vdrop',
                                                'display-adrop',
                                              ],
                                              selected: (mpvCore['videoSync']
                                                      as String?) ??
                                                  'audio',
                                              getTitle: (item) => item,
                                              key: 'videoSync',
                                            ),
                                          ),
                                          AnymeXTile.toggle(
                                            icon: Icons.movie_filter_rounded,
                                            title: 'Frame Interpolation',
                                            subtitle:
                                                'Smoother motion, can increase GPU usage',
                                            value: (mpvCore['interpolation']
                                                    as bool?) ??
                                                false,
                                            onChanged: (val) {
                                              PlayerCoreVisualSettings
                                                  .setMpvCoreSetting(
                                                      'interpolation', val);
                                              setState(() {});
                                            },
                                          ),
                                          AnymeXTile.toggle(
                                            icon: Icons.graphic_eq_rounded,
                                            title: 'Audio Pitch Correction',
                                            subtitle:
                                                'Keep voice pitch stable at higher speeds',
                                            value:
                                                (mpvCore['audioPitchCorrection']
                                                        as bool?) ??
                                                    true,
                                            onChanged: (val) {
                                              PlayerCoreVisualSettings
                                                  .setMpvCoreSetting(
                                                      'audioPitchCorrection',
                                                      val);
                                              setState(() {});
                                            },
                                          ),
                                          AnymeXTile.slider(
                                            icon: Icons.timer_outlined,
                                            title: 'Cache Minutes',
                                            subtitle:
                                                'Read-ahead duration in Minutes',
                                            value: ((mpvCore['cacheMinutes']
                                                        as num?) ??
                                                    5)
                                                .toDouble(),
                                            min: 0,
                                            max: 60,
                                            divisions: 60,
                                            onChanged: (value) {
                                              PlayerCoreVisualSettings
                                                  .setMpvCoreSetting(
                                                      'cacheMinutes',
                                                      value.round());
                                              setState(() {});
                                            },
                                          ),
                                          AnymeXTile.slider(
                                            icon: Icons.downloading_rounded,
                                            title: 'Demuxer Readahead',
                                            subtitle: 'Readahead seconds',
                                            value:
                                                ((mpvCore['demuxerReadaheadSeconds']
                                                            as num?) ??
                                                        30)
                                                    .toDouble(),
                                            min: 0,
                                            max: 120,
                                            divisions: 24,
                                            onChanged: (value) {
                                              PlayerCoreVisualSettings
                                                  .setMpvCoreSetting(
                                                      'demuxerReadaheadSeconds',
                                                      value.round());
                                              setState(() {});
                                            },
                                          ),
                                          AnymeXTile.slider(
                                            icon: Icons.storage_rounded,
                                            title: 'Demuxer Max Buffer',
                                            subtitle:
                                                'Maximum demuxer buffer (MB)',
                                            value:
                                                ((mpvCore['demuxerMaxBytesMb']
                                                            as num?) ??
                                                        128)
                                                    .toDouble(),
                                            min: 16,
                                            max: 512,
                                            divisions: 62,
                                            onChanged: (value) {
                                              PlayerCoreVisualSettings
                                                  .setMpvCoreSetting(
                                                      'demuxerMaxBytesMb',
                                                      value.round());
                                              setState(() {});
                                            },
                                          ),
                                          AnymeXTile.slider(
                                            icon: Icons.developer_board_rounded,
                                            title: 'Decoder Threads',
                                            subtitle:
                                                '0 means automatic thread count',
                                            value: ((mpvCore['vdLavcThreads']
                                                        as num?) ??
                                                    4)
                                                .toDouble(),
                                            min: 0,
                                            max: 16,
                                            divisions: 16,
                                            onChanged: (value) {
                                              PlayerCoreVisualSettings
                                                  .setMpvCoreSetting(
                                                      'vdLavcThreads',
                                                      value.round());
                                              setState(() {});
                                            },
                                          ),
                                        ],
                                      ),
                                  ],
                                );
                              }),
                            ],
                          ),
                          AnymeXSectionBuilder(
                            title: 'Common',
                            children: [
                              AnymeXTile.toggle(
                                  icon: Icons.subtitles,
                                  title: "Use Libass for Subtitles",
                                  subtitle:
                                      "Better subtitle rendering using libass library",
                                  value: _useLibass,
                                  onChanged: (val) async {
                                    setState(() {
                                      _useLibass = val;
                                    });
                                    PlayerKeys.useLibass.set<bool>(val);
                                    if (Get.isRegistered<PlayerController>()) {
                                      final controller =
                                          Get.find<PlayerController>();
                                      if (!controller.isClosed) {
                                        await controller
                                            .onLibassPreferenceChanged(val);
                                      }
                                    }
                                  }),
                              AnymeXTile.toggle(
                                  icon: Icons.launch_rounded,
                                  title: "Use External Player",
                                  subtitle:
                                      "Open video stream in external player by default",
                                  value: _useExternalPlayer,
                                  onChanged: (val) {
                                    setState(() {
                                      _useExternalPlayer = val;
                                    });
                                    PlayerKeys.useExternalPlayer.set<bool>(val);
                                  }),
                              AnymeXTile(
                                icon: HugeIcons.strokeRoundedPlaySquare,
                                onTap: _showPlayerControlThemeDialog,
                                title: 'Player Theme',
                                subtitle: PlayerControlThemeRegistry.resolve(
                                  settings.playerControlTheme,
                                ).name,
                              ),
                              AnymeXTile(
                                icon: Icons.data_object_rounded,
                                onTap: () => showJsonPlayerThemesSheet(
                                    context, setState, settings),
                                title: 'JSON Theme Manager',
                                subtitle:
                                    '${PlayerControlThemeRegistry.jsonThemes.length} imported theme(s)',
                              ),
                              AnymeXTile(
                                icon: Icons.tune_rounded,
                                onTap: _showMediaIndicatorThemeDialog,
                                title: 'Swipe Indicator Theme',
                                subtitle: MediaIndicatorThemeRegistry.resolve(
                                  settings.mediaIndicatorTheme,
                                ).name,
                              ),
                              AnymeXTile.toggle(
                                  icon: Icons.stay_current_portrait,
                                  title: "Default Portrait",
                                  subtitle:
                                      "For psychopaths who like watching in portrait",
                                  value: settings.defaultPortraitMode,
                                  onChanged: (val) =>
                                      settings.defaultPortraitMode = val),
                              AnymeXTile(
                                icon: Icons.speed,
                                onTap: _showPlaybackSpeedDialog,
                                title: "Playback Speed",
                                subtitle:
                                    '${settings.speed.toStringAsFixed(1)}x',
                              ),
                              AnymeXTile(
                                icon: Icons.aspect_ratio,
                                title: 'Resize Mode',
                                subtitle: settings.resizeMode.capitalizeFirst!,
                                onTap: () {
                                  _showResizeModeDialog();
                                },
                              ),
                              AnymeXTile.toggle(
                                  icon: Icons.fast_forward,
                                  title: "Auto Skip OP",
                                  subtitle: "Auto skip the opening song",
                                  value: settings.autoSkipOP,
                                  onChanged: (val) =>
                                      settings.autoSkipOP = val),
                              AnymeXTile.toggle(
                                  icon: Icons.fast_forward_outlined,
                                  title: "Auto Skip ED",
                                  subtitle: "Auto skip the ending song",
                                  value: settings.autoSkipED,
                                  onChanged: (val) =>
                                      settings.autoSkipED = val),
                              AnymeXTile.toggle(
                                  icon: Icons.fast_forward_outlined,
                                  title: "Auto Skip Recap",
                                  subtitle: "Auto skip the recap section",
                                  value: settings.autoSkipRecap,
                                  onChanged: (val) =>
                                      settings.autoSkipRecap = val),
                              AnymeXTile.toggle(
                                  icon: Icons.all_inclusive,
                                  title: "Auto Skip Once Only",
                                  subtitle: "Auto skip only once per watch",
                                  value: settings.autoSkipOnce,
                                  onChanged: (val) =>
                                      settings.autoSkipOnce = val),
                              AnymeXTile.toggle(
                                  icon: Icons.skip_next_rounded,
                                  title: "Auto Skip Filler",
                                  subtitle:
                                      "Automatically skip filler episodes when going to next episode",
                                  value: settings.autoSkipFiller,
                                  onChanged: (val) =>
                                      settings.autoSkipFiller = val),
                              AnymeXTile.toggle(
                                  icon: Icons.play_disabled_rounded,
                                  title: "Gesture for Brightness & Volume",
                                  subtitle:
                                      "Enable vertical swiping on the left/right sides of the player screen to adjust brightness and volume",
                                  value: settings.enableSwipeControls,
                                  onChanged: (val) =>
                                      settings.enableSwipeControls = val),
                              AnymeXTile.toggle(
                                  icon: Icons.gesture_rounded,
                                  title: "Hold to Speed Up",
                                  subtitle:
                                      "Enable holding on player screen to temporarily speed up video playback",
                                  value: settings.enableHoldToSeek,
                                  onChanged: (val) =>
                                      settings.enableHoldToSeek = val),
                              AnymeXTile.toggle(
                                  icon: Icons.swap_horiz_rounded,
                                  title: "Swipe to Seek",
                                  subtitle:
                                      "Enable horizontal swiping on player screen to seek through video",
                                  value: settings.enableSlideToSeek,
                                  onChanged: (val) =>
                                      settings.enableSlideToSeek = val),
                              AnymeXTile.toggle(
                                  icon: Icons.screenshot_rounded,
                                  title: "Save Last Frame",
                                  subtitle:
                                      "Saves a screenshot of the last frame you watched. Disabling this significantly reduces storage usage",
                                  value: settings.enableScreenshot,
                                  onChanged: (val) =>
                                      settings.enableScreenshot = val),
                              AnymeXTile.toggle(
                                  icon: Icons.bluetooth_audio_rounded,
                                  title: "Media Session (Bluetooth Support)",
                                  subtitle:
                                      "Enable background media controls for Bluetooth headsets and system media notifications. Note: Enabling this will increase battery usage.",
                                  value: settings.useMediaSession,
                                  onChanged: (val) =>
                                      settings.useMediaSession = val),
                              AnymeXTile.toggle(
                                  icon: Icons.animation_rounded,
                                  title: "Animate Control Overlay",
                                  subtitle:
                                      "Disable to show and hide player controls instantly",
                                  value: settings.playerMenuAnimation,
                                  onChanged: (val) =>
                                      settings.playerMenuAnimation = val),
                              AnymeXTile.slider(
                                value: settings.seekDuration.toDouble(),
                                max: 50,
                                min: 0,
                                divisions: 10,
                                onChanged: (double value) {
                                  setState(() {
                                    settings.seekDuration = value.toInt();
                                  });
                                },
                                title: 'DoubleTap to Seek',
                                subtitle: 'Adjust Double Tap To Seek Duration',
                                icon: Iconsax.forward5,
                              ),
                              AnymeXTile.slider(
                                value: settings.skipDuration.toDouble(),
                                max: 120,
                                min: 0,
                                divisions: 24,
                                onChanged: (double value) {
                                  setState(() {
                                    settings.skipDuration = value.toInt();
                                  });
                                },
                                title: 'MegaSkip Duration',
                                subtitle: 'Adjust MegaSkip Duration',
                                icon: Iconsax.forward5,
                              ),
                              AnymeXTile.slider(
                                value: settings.markAsCompleted.toDouble(),
                                max: 100,
                                min: 0,
                                divisions: 20,
                                onChanged: (double value) {
                                  setState(() {
                                    settings.markAsCompleted = value.toInt();
                                  });
                                },
                                title: 'Mark As Watched',
                                subtitle:
                                    'How much in percentage to mark episode as watched',
                                icon: Iconsax.tick_circle,
                              ),
                            ],
                          ),
                          AnymeXSectionBuilder(
                            title: 'Subtitles',
                            children: [
                              AnymeXTile(
                                icon: Icons.closed_caption_rounded,
                                title: 'Preferred Subtitle Language',
                                subtitle: SubtitleTranslator.languages[
                                        settings.preferredSubtitleLanguage] ??
                                    'None (Disabled)',
                                onTap: () => showSelectionDialog<String>(
                                  title: "Preferred Subtitle Language",
                                  items: [
                                    'none',
                                    ...SubtitleTranslator.languages.keys
                                  ],
                                  selectedItem: settings.playerSettings.value
                                      .preferredSubtitleLanguage.obs,
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
                                  icon: Icons.lightbulb,
                                  title: 'Transition Subtitle',
                                  subtitle:
                                      'By disabling this you can avoid the transition between subtitles.',
                                  value: settings.transitionSubtitle,
                                  onChanged: (e) {
                                    settings.transitionSubtitle = e;
                                  }),
                              AnymeXTile.toggle(
                                icon: HugeIcons.strokeRoundedTranslate,
                                title: 'Auto Translate Subtitles',
                                subtitle:
                                    'Use AI to translate soft-subtitles live',
                                value:
                                    settings.playerSettings.value.autoTranslate,
                                onChanged: (val) {
                                  settings.playerSettings
                                      .update((s) => s?.autoTranslate = val);
                                  PlayerSettingsKeys.autoTranslate.set(val);
                                  setState(() {});
                                },
                              ),
                              if (!widget.isModal &&
                                  settings.playerSettings.value.autoTranslate)
                                AnymeXTile(
                                  icon: Icons.language,
                                  title: 'Translate To',
                                  subtitle: SubtitleTranslator.languages[
                                          settings.playerSettings.value
                                              .translateTo] ??
                                      'Select Language',
                                  onTap: () {
                                    _showTranslationLanguageDialog();
                                  },
                                ),
                              AnymeXTile(
                                icon: Icons.font_download_rounded,
                                title: 'Subtitle Font',
                                subtitle:
                                    settings.playerSettings.value.subtitleFont,
                                onTap: _showFontSelectionDialog,
                              ),
                              AnymeXTile(
                                icon: Icons.format_paint_rounded,
                                title: 'Outline Type',
                                subtitle: normalizeSubtitleOutlineType(settings
                                    .playerSettings.value.subtitleOutlineType),
                                onTap: _showOutlineTypeDialog,
                              ),
                              AnymeXTile.slider(
                                value: settings
                                    .playerSettings.value.subtitleOpacity,
                                min: 0.1,
                                max: 1.0,
                                divisions: 10,
                                onChanged: (val) {
                                  final current = settings.playerSettings.value;
                                  current.subtitleOpacity = val;
                                  PlayerSettingsKeys.subtitleOpacity.set(val);
                                  settings.playerSettings.refresh();
                                },
                                title: 'Subtitle Transparency',
                                subtitle: 'Adjust text visibility',
                                icon: Icons.opacity,
                              ),
                              AnymeXTile.slider(
                                value: settings
                                    .playerSettings.value.subtitleBottomMargin,
                                min: 0.0,
                                max: 500.0,
                                divisions: 500,
                                onChanged: (val) {
                                  final current = settings.playerSettings.value;
                                  current.subtitleBottomMargin = val;
                                  PlayerSettingsKeys.subtitleBottomMargin
                                      .set(val);
                                  settings.playerSettings.refresh();
                                },
                                title: 'Bottom Margin',
                                subtitle: 'Distance from bottom of screen',
                                icon: Icons.vertical_align_bottom,
                              ),
                              AnymeXTile(
                                subtitle: 'Change subtitle colors',
                                icon: Icons.palette,
                                title: 'Subtitle Color',
                                onTap: () {
                                  _showColorSelectionDialog(
                                      'Select Subtitle Color',
                                      fontColorOptions[
                                              settings.subtitleColor] ??
                                          fontColorOptions['Default']!,
                                      (color) {
                                    settings.subtitleColor = color;
                                  }, fontColorOptions);
                                },
                              ),
                              AnymeXTile(
                                icon: Icons.palette,
                                title: 'Subtitle Outline Color',
                                subtitle: 'Change subtitle outline color',
                                onTap: () {
                                  _showColorSelectionDialog(
                                      'Select Subtitle Outline Color',
                                      colorOptions[
                                              settings.subtitleOutlineColor] ??
                                          colorOptions['None']!, (color) {
                                    settings.subtitleOutlineColor = color;
                                  }, colorOptions);
                                },
                              ),
                              AnymeXTile(
                                subtitle: 'Change subtitle background color',
                                icon: Icons.palette,
                                title: 'Subtitle Background Color',
                                onTap: () {
                                  _showColorSelectionDialog(
                                      'Select Subtitle Background Color',
                                      colorOptions[settings
                                              .subtitleBackgroundColor] ??
                                          colorOptions['None']!, (color) {
                                    settings.subtitleBackgroundColor = color;
                                  }, colorOptions);
                                },
                              ),
                              AnymeXTile.slider(
                                value: settings.subtitleSize.toDouble(),
                                min: 12.0,
                                max: 90.0,
                                onChanged: (double value) {
                                  settings.subtitleSize = value.toInt();
                                },
                                title: 'Subtitle Size',
                                subtitle: 'Adjust Sub Size',
                                icon: Iconsax.subtitle5,
                              ),
                              AnymeXTile.slider(
                                value: settings.subtitleOutlineWidth.toDouble(),
                                min: 1.0,
                                max: 8.0,
                                divisions: 14,
                                onChanged: (double value) {
                                  settings.subtitleOutlineWidth = value.toInt();
                                },
                                title: 'Subtitle Outline Width',
                                subtitle: 'Adjust Subtitle Outline Width',
                                icon: Iconsax.subtitle5,
                              ),
                              const SizedBox(height: 20),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 17.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const AnymeXText(
                                      'Subtitle Preview',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: colorOptions[
                                            settings.subtitleBackgroundColor],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.all(10),
                                      child: buildStyledSubtitleText(
                                        text: 'Subtitle Preview Text',
                                        textColor: fontColorOptions[
                                                settings.subtitleColor] ??
                                            fontColorOptions['Default']!,
                                        fontSize:
                                            settings.subtitleSize.toDouble(),
                                        fontFamily: resolveSubtitleFontFamily(
                                            settings.playerSettings.value
                                                .subtitleFont),
                                        outlineType: settings.playerSettings
                                            .value.subtitleOutlineType,
                                        outlineWidth: settings
                                            .subtitleOutlineWidth
                                            .toDouble(),
                                        outlineColor: colorOptions[settings
                                                .subtitleOutlineColor] ??
                                            colorOptions['Black']!,
                                      ),
                                    ),
                                    10.height(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          AnymeXSectionBuilder(
                            title: 'Bottom Controls',
                            disableSeperator: true,
                            children: [
                              _buildJsonThemeInfoCard(),
                              _buildSectionLabel('Left Side'),
                              ReorderableListView.builder(
                                key: const Key('left_list'),
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _leftButtonIds.length,
                                itemBuilder: (context, index) {
                                  final id = _leftButtonIds[index];
                                  final control = _bottomControls
                                      .firstWhere((c) => c.id == id);
                                  return _buildControlTile(control, 'left',
                                      index, _leftButtonIds.length,
                                      key: ValueKey('left_$id'));
                                },
                                onReorder: (oldIndex, newIndex) {
                                  setState(() {
                                    if (newIndex > oldIndex) {
                                      newIndex -= 1;
                                    }
                                    final String item =
                                        _leftButtonIds.removeAt(oldIndex);
                                    _leftButtonIds.insert(newIndex, item);
                                    _saveButtonConfig();
                                  });
                                },
                              ),
                              _buildSectionLabel('Right Side'),
                              ReorderableListView.builder(
                                key: const Key('right_list'),
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _rightButtonIds.length,
                                itemBuilder: (context, index) {
                                  final id = _rightButtonIds[
                                      _rightButtonIds.length - 1 - index];
                                  final control = _bottomControls
                                      .firstWhere((c) => c.id == id);
                                  return _buildControlTile(control, 'right',
                                      index, _rightButtonIds.length,
                                      key: ValueKey('right_$id'));
                                },
                                onReorder: (oldIndex, newIndex) {
                                  setState(() {
                                    _rightButtonIds =
                                        _rightButtonIds.reversed.toList();
                                    if (newIndex > oldIndex) {
                                      newIndex -= 1;
                                    }
                                    final String item =
                                        _rightButtonIds.removeAt(oldIndex);
                                    _rightButtonIds.insert(newIndex, item);
                                    _rightButtonIds =
                                        _rightButtonIds.reversed.toList();
                                    _saveButtonConfig();
                                  });
                                },
                              ),
                              if (_hiddenButtonIds.isNotEmpty) ...[
                                _buildSectionLabel('Hidden'),
                                ListView.builder(
                                  key: const Key('hidden_list'),
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _hiddenButtonIds.length,
                                  itemBuilder: (context, index) {
                                    final id = _hiddenButtonIds[index];
                                    final control = _bottomControls
                                        .firstWhere((c) => c.id == id);
                                    return _buildControlTile(control, 'hidden',
                                        index, _hiddenButtonIds.length,
                                        key: ValueKey('hidden_$id'));
                                  },
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
    );
  }

  Widget _buildSectionLabel(String label) {
    final colors = context.colors;
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
        child: AnymeXText(
          label,
          size: 13,
          variant: TextVariant.bold,
          color: colors.primary,
        ),
      ),
    );
  }

  Widget _buildExperimentalGateMessage(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(10, 4, 10, 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.colors.primaryContainer.opaque(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.colors.primary.opaque(0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              size: 18, color: context.colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: AnymeXText(
              text,
              style: TextStyle(
                color: context.colors.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJsonThemeInfoCard() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.opaque(0.18, iReallyMeanIt: true),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.opaque(0.4, iReallyMeanIt: true),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AnymeXText(
              'If you are using a JSON theme, changes here will not affect player controls. Switch to a built-in theme to apply these settings.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlTile(
    _BottomControl control,
    String position,
    int index,
    int totalCount, {
    required Key key,
  }) {
    final colors = context.colors;
    final isLast = index == totalCount - 1;
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnymeXTile(
          icon: control.icon,
          title: control.name,
          showChevron: false,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: _buildTrailingButtons(control, position),
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            thickness: 0.6,
            indent: 66,
            endIndent: 16,
            color: colors.onSurface.opaque(0.08, iReallyMeanIt: true),
          ),
      ],
    );
  }

  List<Widget> _buildTrailingButtons(_BottomControl control, String position) {
    if (position == 'hidden') {
      return [
        IconButton(
          tooltip: 'Show on left',
          icon: const Icon(Icons.visibility_outlined, size: 20),
          onPressed: () => _showButton(control.id, 'left'),
        ),
        IconButton(
          tooltip: 'Show on right',
          icon: const Icon(
            Icons.keyboard_arrow_right_rounded,
          ),
          onPressed: () => _showButton(control.id, 'right'),
        ),
      ];
    } else {
      return [
        IconButton(
          tooltip: 'Hide button',
          icon: const Icon(
            Icons.visibility_off_outlined,
            size: 20,
          ),
          onPressed: () => _hideButton(control.id),
        ),
        if (position == 'left')
          IconButton(
            tooltip: 'Move to right',
            icon: const Icon(
              Icons.keyboard_arrow_right_rounded,
            ),
            onPressed: () => _moveButton(control.id, 'right'),
          )
        else
          IconButton(
            tooltip: 'Move to left',
            icon: const Icon(Icons.keyboard_arrow_left_rounded,
                color: Colors.white),
            onPressed: () => _moveButton(control.id, 'left'),
          ),
      ];
    }
  }
}
