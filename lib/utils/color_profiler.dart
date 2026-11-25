import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:anymex/l10n/l10n_extension.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/screens/settings/sub_settings/player/settings_player_shaders.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/player_core_visual_settings.dart';
import 'package:anymex/utils/shaders.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_segmented_button.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_titlebar.dart';
import 'package:anymex/widgets/common/anymex_pills.dart';
import 'package:anymex/widgets/common/anymex_slider_m3.dart';
import 'package:anymex/widgets/non_widgets/reusable_checkmark.dart';
import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:path_provider/path_provider.dart';

class ColorProfileManager {
  static const Map<String, Map<String, int>> profiles = {
    "natural": {
      "brightness": 0,
      "contrast": 0,
      "saturation": 0,
      "gamma": 0,
      "hue": 0,
    },
    "anime": {
      "brightness": 4,
      "contrast": 14,
      "saturation": 18,
      "gamma": -1,
      "hue": 0,
    },
    "anime_vibrant": {
      "brightness": 6,
      "contrast": 18,
      "saturation": 28,
      "gamma": -2,
      "hue": 0,
    },
    "cinema": {
      "brightness": 1,
      "contrast": 8,
      "saturation": 6,
      "gamma": 3,
      "hue": 0,
    },
    "cinema_dark": {
      "brightness": -6,
      "contrast": 12,
      "saturation": 4,
      "gamma": 8,
      "hue": 0,
    },
    "vivid": {
      "brightness": 4,
      "contrast": 16,
      "saturation": 22,
      "gamma": -1,
      "hue": 0,
    },
    "vivid_pop": {
      "brightness": 7,
      "contrast": 22,
      "saturation": 32,
      "gamma": -3,
      "hue": 0,
    },
    "grayscale": {
      "brightness": 0,
      "contrast": 8,
      "saturation": -100,
      "gamma": 0,
      "hue": 0,
    },
    "warm": {
      "brightness": 2,
      "contrast": 6,
      "saturation": 10,
      "gamma": -1,
      "hue": 4,
    },
    "cool": {
      "brightness": 0,
      "contrast": 8,
      "saturation": 8,
      "gamma": 1,
      "hue": -4,
    },
  };

  Future<void> show(
    BuildContext context, {
    required dynamic player,
    required String currentProfile,
    required Map<String, int> activeSettings,
    required ValueChanged<String> onProfileSelected,
    required ValueChanged<Map<String, int>> onCustomSettingsChanged,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'ColorProfiler',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (ctx, anim1, anim2) => _ColorProfilerContent(
        animation: anim1,
        player: player,
        currentProfile: currentProfile,
        activeSettings: activeSettings,
        onProfileSelected: onProfileSelected,
        onCustomSettingsChanged: onCustomSettingsChanged,
      ),
      transitionBuilder: (ctx, anim1, anim2, child) => Material(
        type: MaterialType.transparency,
        child: child,
      ),
    );
  }

  Future<void> applyColorProfile(String profileKey, dynamic player) async {
    if (player == null) return;
    try {
      final settings = profiles[profileKey] ?? profiles["natural"]!;
      final b = (settings["brightness"] ?? 0).toDouble();
      final c = (settings["contrast"] ?? 0).toDouble();
      final s = (settings["saturation"] ?? 0).toDouble();
      final g = (settings["gamma"] ?? 0).toDouble();
      final h = (settings["hue"] ?? 0).toDouble();

      final p = player.platform;
      if (p != null) {
        await p.setProperty("brightness", b.toString());
        await p.setProperty("contrast", c.toString());
        await p.setProperty("saturation", s.toString());
        await p.setProperty("gamma", g.toString());
        await p.setProperty("hue", h.toString());
      }
    } catch (e) {
      Logger.e("ColorProfileManager Error", error: e);
    }
  }

  Future<void> applyCustomSettings(
      Map<String, int> customSettings, dynamic player) async {
    if (player == null) return;
    try {
      final b = (customSettings["brightness"] ?? 0).toDouble();
      final c = (customSettings["contrast"] ?? 0).toDouble();
      final s = (customSettings["saturation"] ?? 0).toDouble();
      final g = (customSettings["gamma"] ?? 0).toDouble();
      final h = (customSettings["hue"] ?? 0).toDouble();

      final p = player.platform;
      if (p != null) {
        await p.setProperty("brightness", b.toString());
        await p.setProperty("contrast", c.toString());
        await p.setProperty("saturation", s.toString());
        await p.setProperty("gamma", g.toString());
        await p.setProperty("hue", h.toString());
      }
    } catch (e) {
      Logger.e("ColorProfileManager Error", error: e);
    }
  }
}

class ColorProfileBottomSheet {
  static Future<void> showColorProfileSheet(
    BuildContext context,
    PlayerController controller,
    dynamic player,
  ) {
    return ColorProfileManager().show(
      context,
      player: player,
      currentProfile: controller.currentVisualProfile.value,
      activeSettings: Map<String, int>.from(controller.customSettings),
      onProfileSelected: (val) {
        controller.currentVisualProfile.value = val;
        PlayerUiKeys.currentVisualProfile.set(val);
      },
      onCustomSettingsChanged: (val) {
        controller.customSettings.value = val;
        PlayerUiKeys.currentVisualSettings.set(val);
      },
    );
  }
}

class _ColorProfilerContent extends StatefulWidget {
  final Animation<double> animation;
  final dynamic player;
  final String currentProfile;
  final Map<String, int> activeSettings;
  final ValueChanged<String> onProfileSelected;
  final ValueChanged<Map<String, int>> onCustomSettingsChanged;

  const _ColorProfilerContent({
    required this.animation,
    required this.player,
    required this.currentProfile,
    required this.activeSettings,
    required this.onProfileSelected,
    required this.onCustomSettingsChanged,
  });

  @override
  State<_ColorProfilerContent> createState() => _ColorProfilerContentState();
}

class _ColorProfilerContentState extends State<_ColorProfilerContent> {
  final settingsController = Get.find<Settings>();

  String _selectedTab = 'shaders';
  late String _selectedProfile;
  late String _selectedShader;
  late String _selectedMode;
  late String _selectedTier;
  late bool _shadersOn;
  late bool _experimentalEnabled;
  bool _isComparing = false;
  bool _isFullFramePreview = false;
  bool _resetDone = false;
  Timer? _resetTimer;
  Timer? _holdTimer;
  Uint8List? _capturedFrame;

  Map<String, int> _customSettings = {
    'brightness': 0,
    'contrast': 0,
    'saturation': 0,
    'gamma': 0,
    'hue': 0,
  };
  late Map<String, dynamic> _visualSettings;
  bool _areShadersDownloaded = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _statusText = 'Connecting…';
  Dio? _dio;

  static const List<({String id, String title, String sub})> _modeDefs = [
    (id: 'A', title: 'Mode A', sub: 'Sharpen soft lines'),
    (id: 'B', title: 'Mode B', sub: 'Gentle, keeps grain'),
    (id: 'C', title: 'Mode C', sub: 'Denoise, upscale'),
    (id: 'A+A', title: 'Mode A+A', sub: 'Sharper · heavier'),
    (id: 'B+B', title: 'Mode B+B', sub: 'Gentle · heavier'),
    (id: 'C+A', title: 'Mode C+A', sub: 'Clean, then sharpen'),
  ];

  static final List<({String key, String title})> _presetDefs =
      ColorProfileManager.profiles.entries
          .map((entry) => (
                key: entry.key,
                title: entry.key.capitalize!.replaceAll('_', ' ')
              ))
          .toList();

  static const List<({String key, String label})> _adjustDefs = [
    (key: 'brightness', label: 'Brightness'),
    (key: 'contrast', label: 'Contrast'),
    (key: 'saturation', label: 'Saturation'),
    (key: 'gamma', label: 'Gamma'),
    (key: 'hue', label: 'Hue'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedProfile = widget.currentProfile;
    _shadersOn = PlayerUiKeys.shadersEnabled.get<bool>(false);
    final savedShader = settingsController.selectedShader;
    _selectedShader = savedShader.isEmpty ? 'Default' : savedShader;
    _selectedMode = _extractModeFromShader(_selectedShader);
    _selectedTier =
        settingsController.selectedProfile == 'HIGH-END' ? 'high' : 'mid';

    if (widget.currentProfile.toLowerCase() == 'custom') {
      _customSettings = Map.from(widget.activeSettings);
    } else if (ColorProfileManager.profiles
        .containsKey(widget.currentProfile)) {
      _customSettings =
          Map.from(ColorProfileManager.profiles[widget.currentProfile]!);
    } else {
      _customSettings = Map.from(ColorProfileManager.profiles['natural']!);
    }
    _visualSettings = PlayerCoreVisualSettings.getMpvVisualSettings();
    _experimentalEnabled =
        PlayerUiKeys.playerExperimentalEnabled.get<bool>(false);
    _checkShaders();
    _captureCurrentFrame();
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    _holdTimer?.cancel();
    _dio?.close(force: true);
    super.dispose();
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

  String get _summaryText {
    if (!_areShadersDownloaded) {
      return 'Not installed';
    }
    if (_shadersOn &&
        _selectedShader.isNotEmpty &&
        _selectedShader != 'Default') {
      return 'Mode $_selectedMode';
    }
    return 'Shaders off';
  }

  Future<void> _checkShaders() async {
    final downloaded = await PlayerShaders.areShadersDownloaded();
    if (mounted) {
      setState(() {
        _areShadersDownloaded = downloaded;
      });
    }
  }

  Future<void> _captureCurrentFrame() async {
    try {
      if (widget.player != null) {
        final dynamic p = widget.player;
        final bytes = await p.screenshot(
          includeLibassSubtitles: false,
          format: 'image/jpeg',
        );
        if (bytes != null && mounted) {
          setState(() {
            _capturedFrame = bytes;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _applyCurrentShaderMode() async {
    String shaderName;
    if (!_shadersOn || _selectedMode == 'Default' || _selectedMode.isEmpty) {
      shaderName = 'Default';
    } else {
      final suffix = _selectedTier == 'high' ? '(HQ)' : '(Fast)';
      shaderName = 'Anime4K: Mode $_selectedMode $suffix';
    }
    await _setShader(shaderName);
  }

  Future<void> _setShader(String shader) async {
    setState(() {
      _selectedShader = shader;
    });
    if (Get.isRegistered<PlayerController>()) {
      await Get.find<PlayerController>().applyShader(shader);
    } else {
      await PlayerShaders.setShaders(widget.player, shader);
      settingsController.selectedShader = shader == "Default" ? "" : shader;
      PlayerUiKeys.selectedShader.set(shader == "Default" ? "" : shader);
    }
    HapticFeedback.lightImpact();
  }

  Future<void> _selectProfile(String profileKey) async {
    final presetVals = ColorProfileManager.profiles[profileKey];
    setState(() {
      _selectedProfile = profileKey;
      if (presetVals != null) {
        _customSettings = Map<String, int>.from(presetVals);
      }
    });
    await ColorProfileManager().applyColorProfile(profileKey, widget.player);
    widget.onProfileSelected(profileKey);
    if (presetVals != null) {
      widget.onCustomSettingsChanged(_customSettings);
    }
    HapticFeedback.lightImpact();
  }

  Future<void> _applyCustomSettings() async {
    setState(() => _selectedProfile = 'custom');
    await ColorProfileManager()
        .applyCustomSettings(_customSettings, widget.player);
    widget.onProfileSelected('custom');
    widget.onCustomSettingsChanged(_customSettings);
  }

  Future<void> _applyVisualSettings() async {
    PlayerUiKeys.mpvVisualSettings.set(_visualSettings);
    await PlayerCoreVisualSettings.applyMpvVisualSettings(widget.player);
  }

  void _showVisualSelectionDialog({
    required String title,
    required List<String> items,
    required String selected,
    required String key,
  }) {
    showSelectionDialog<String>(
      title: title,
      items: items,
      selectedItem: selected.obs,
      getTitle: (item) => item,
      onItemSelected: (value) {
        setState(() {
          _visualSettings[key] = value;
        });
        _applyVisualSettings();
      },
      leadingIcon: Icons.tune_rounded,
    );
  }

  void _onCompareStart() {
    setState(() => _isComparing = true);
    HapticFeedback.mediumImpact();
    if (Get.isRegistered<PlayerController>()) {
      Get.find<PlayerController>().showControls.value = false;
    }
    PlayerShaders.setShaders(widget.player, "Default");
    ColorProfileManager().applyColorProfile('natural', widget.player);
  }

  void _onCompareEnd() {
    if (!_isComparing) return;
    setState(() => _isComparing = false);
    HapticFeedback.lightImpact();
    if (_shadersOn &&
        _selectedShader.isNotEmpty &&
        _selectedShader != 'Default') {
      _applyCurrentShaderMode();
    }
    if (_selectedProfile == 'custom') {
      ColorProfileManager().applyCustomSettings(_customSettings, widget.player);
    } else {
      ColorProfileManager().applyColorProfile(_selectedProfile, widget.player);
    }
  }

  void _onPointerDownCompare() {
    _holdTimer?.cancel();
    _holdTimer = Timer(const Duration(milliseconds: 120), () {
      if (mounted) {
        _onCompareStart();
      }
    });
  }

  void _onPointerUpCompare() {
    _holdTimer?.cancel();
    _holdTimer = null;
    if (_isComparing) {
      _onCompareEnd();
    }
  }

  void _resetTab() {
    setState(() {
      _resetDone = true;
      if (_selectedTab == 'shaders') {
        _shadersOn = false;
        _selectedMode = 'B';
        _selectedTier = 'mid';
        settingsController.selectedProfile = 'MID-END';
        _setShader('Default');
      } else if (_selectedTab == 'presets') {
        _selectProfile('natural');
      } else if (_selectedTab == 'custom') {
        _customSettings = Map.from(ColorProfileManager.profiles['natural']!);
        _applyCustomSettings();
      } else if (_selectedTab == 'visual') {
        _visualSettings = Map<String, dynamic>.from(
          PlayerCoreVisualSettings.mpvVisualDefaults,
        );
        _applyVisualSettings();
      }
    });
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _resetDone = false);
    });
  }

  String get _tabResetName {
    switch (_selectedTab) {
      case 'shaders':
        return 'shaders';
      case 'presets':
        return 'preset';
      case 'custom':
        return 'adjustments';
      case 'visual':
        return 'quality';
      default:
        return 'settings';
    }
  }

  Future<void> _downloadShaders() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _statusText = 'Connecting…';
    });

    try {
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      setState(() {
        _statusText = 'Downloading shaders…';
        _downloadProgress = 10.0;
      });

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
          if (total != -1 && mounted) {
            final progress = 10.0 + (received / total) * 60.0;
            setState(() {
              _downloadProgress = progress;
            });
          }
        },
      );

      if (!mounted) return;
      setState(() {
        _statusText = 'Extracting files…';
        _downloadProgress = 75.0;
      });

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

      if (!mounted) return;
      setState(() {
        _statusText = 'Finishing up…';
        _downloadProgress = 100.0;
        _isDownloading = false;
        _areShadersDownloaded = true;
        _shadersOn = true;
      });
      await _applyCurrentShaderMode();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _statusText = 'Download failed';
      });
    }
  }

  void _cancelDownload() {
    _dio?.close(force: true);
    setState(() {
      _isDownloading = false;
      _downloadProgress = 0.0;
      _statusText = 'Connecting…';
    });
  }

  Widget _buildPaneHeader() {
    final theme = context.theme;
    final colors = theme.colorScheme;
    final isDesktop = !Platform.isAndroid && !Platform.isIOS;
    final titleBarHeight =
        (Platform.isWindows && !AnymeXTitleBar.isFullScreen.value) ? 40.0 : 0.0;
    final topPadding = (MediaQuery.paddingOf(context).top +
            titleBarHeight +
            (isDesktop ? 16.0 : 10.0))
        .clamp(16.0, 120.0);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, topPadding, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnymeXText(
                  'Color & Shaders',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontFamily: 'Linotte',
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                AnymeXText(
                  _summaryText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              if (Get.isRegistered<PlayerController>()) {
                Get.find<PlayerController>().showControls.value = false;
              }
              setState(() => _isFullFramePreview = true);
            },
            style: IconButton.styleFrom(
              backgroundColor: colors.surfaceContainerHigh,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(Icons.fullscreen_rounded, color: colors.onSurface),
            tooltip: 'Full frame',
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              backgroundColor: colors.surfaceContainerHigh,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(Icons.close_rounded, color: colors.onSurface),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isFullFramePreview) {
      return Material(
        type: MaterialType.transparency,
        child: _buildFullFramePreview(),
      );
    }

    final colors = context.theme.colorScheme;
    final size = MediaQuery.sizeOf(context);
    final isDesktop = !Platform.isAndroid && !Platform.isIOS;
    final panelWidth = size.width * (isDesktop ? 0.4 : 0.6);
    final titleBarHeight =
        (Platform.isWindows && !AnymeXTitleBar.isFullScreen.value) ? 40.0 : 0.0;
    final topSafe = MediaQuery.paddingOf(context).top + titleBarHeight;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: FadeTransition(
              opacity: widget.animation,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.pop(context),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  color: _isComparing
                      ? Colors.transparent
                      : colors.scrim.withValues(alpha: 0.45),
                ),
              ),
            ),
          ),
          if (_isComparing)
            Positioned(
              top: topSafe + 24.0,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadow.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: AnymeXText.semiBold(
                    'Original · shaders off',
                    style: TextStyle(
                      color: colors.onPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: widget.animation,
                curve: Curves.easeOutCubic,
              )),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 100),
                opacity: _isComparing ? 0.0 : 1.0,
                child: Container(
                  width: panelWidth,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: colors.surfaceContainer.withValues(alpha: 0.82),
                    border: Border(
                      left: BorderSide(
                        color: colors.outlineVariant.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: ClipRect(
                    child: AnimatedBuilder(
                      animation: widget.animation,
                      builder: (context, childWidget) {
                        if (widget.animation.status ==
                                AnimationStatus.completed &&
                            !_isComparing) {
                          return BackdropFilter(
                            filter:
                                ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                            child: childWidget,
                          );
                        }
                        return childWidget!;
                      },
                      child: isDesktop
                          ? _buildDesktopLayout()
                          : _buildMobileLandscapeLayout(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    final colors = context.theme.colorScheme;

    return Column(
      children: [
        _buildPaneHeader(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Container(
            height: 60,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                Expanded(
                  child:
                      _buildDesktopTabButton('shaders', 'Shaders', Iconsax.eye),
                ),
                Expanded(
                  child: _buildDesktopTabButton(
                      'presets', 'Presets', Icons.dashboard_customize_rounded),
                ),
                Expanded(
                  child: _buildDesktopTabButton(
                      'custom', 'Custom', Icons.tune_rounded),
                ),
                Expanded(
                  child: _buildDesktopTabButton(
                      'visual', 'Visual', Icons.movie_filter_rounded),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: _buildTabContent(true),
          ),
        ),
        Container(
          height: 84,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow.withValues(alpha: 0.35),
            border: Border(
              top: BorderSide(
                color: colors.outlineVariant.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _resetTab,
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest
                          .withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: colors.outlineVariant.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _resetDone
                              ? Icons.check_circle_rounded
                              : Icons.restart_alt_rounded,
                          size: 18,
                          color: _resetDone ? colors.primary : colors.onSurface,
                        ),
                        const SizedBox(width: 8),
                        AnymeXText.semiBold(
                          _resetDone ? 'Reset done' : 'Reset $_tabResetName',
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                _resetDone ? colors.primary : colors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Listener(
                  onPointerDown: (_) => _onPointerDownCompare(),
                  onPointerUp: (_) => _onPointerUpCompare(),
                  onPointerCancel: (_) => _onPointerUpCompare(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 54,
                    decoration: BoxDecoration(
                      color: _isComparing
                          ? colors.primary
                          : colors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: colors.primary.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Iconsax.eye,
                          size: 18,
                          color:
                              _isComparing ? colors.onPrimary : colors.primary,
                        ),
                        const SizedBox(width: 8),
                        AnymeXText.semiBold(
                          'Hold to compare',
                          style: TextStyle(
                            fontSize: 14,
                            color: _isComparing
                                ? colors.onPrimary
                                : colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopTabButton(String tabId, String label, IconData icon) {
    final theme = context.theme;
    final colors = theme.colorScheme;
    final isSelected = _selectedTab == tabId;
    return InkWell(
      onTap: () {
        setState(() => _selectedTab = tabId);
        if (tabId == 'presets' && _capturedFrame == null) {
          _captureCurrentFrame();
        }
      },
      borderRadius: BorderRadius.circular(26),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 52,
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            AnymeXText.semiBold(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLandscapeLayout() {
    final colors = context.theme.colorScheme;
    return Column(
      children: [
        _buildPaneHeader(),
        Expanded(
          child: Row(
            children: [
              Container(
                width: 76,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLowest.withValues(alpha: 0.25),
                  border: Border(
                    right: BorderSide(
                      color: colors.outlineVariant.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(3, 0),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: Column(
                  children: [
                    _buildMobileTabButton('shaders', 'Shaders', Iconsax.eye),
                    const SizedBox(height: 6),
                    _buildMobileTabButton('presets', 'Presets',
                        Icons.dashboard_customize_rounded),
                    const SizedBox(height: 6),
                    _buildMobileTabButton(
                        'custom', 'Custom', Icons.tune_rounded),
                    const SizedBox(height: 6),
                    _buildMobileTabButton(
                        'visual', 'Visual', Icons.movie_filter_rounded),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(8, 4, 20, 12),
                        child: _buildTabContent(false),
                      ),
                    ),
                    Container(
                      height: 64,
                      padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
                      decoration: BoxDecoration(
                        color:
                            colors.surfaceContainerLow.withValues(alpha: 0.35),
                        border: Border(
                          top: BorderSide(
                            color: colors.outlineVariant.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _resetTab,
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: colors.surfaceContainerHighest
                                      .withValues(alpha: 0.45),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: colors.outlineVariant
                                        .withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _resetDone
                                          ? Icons.check_circle_rounded
                                          : Icons.restart_alt_rounded,
                                      size: 16,
                                      color: _resetDone
                                          ? colors.primary
                                          : colors.onSurface,
                                    ),
                                    const SizedBox(width: 6),
                                    AnymeXText.semiBold(
                                      _resetDone ? 'Done' : 'Reset',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: _resetDone
                                            ? colors.primary
                                            : colors.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Listener(
                              onPointerDown: (_) => _onPointerDownCompare(),
                              onPointerUp: (_) => _onPointerUpCompare(),
                              onPointerCancel: (_) => _onPointerUpCompare(),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                height: 48,
                                decoration: BoxDecoration(
                                  color: _isComparing
                                      ? colors.primary
                                      : colors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color:
                                        colors.primary.withValues(alpha: 0.5),
                                    width: 1.5,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Iconsax.eye,
                                      size: 16,
                                      color: _isComparing
                                          ? colors.onPrimary
                                          : colors.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    AnymeXText.semiBold(
                                      'Compare',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: _isComparing
                                            ? colors.onPrimary
                                            : colors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileTabButton(String tabId, String label, IconData icon) {
    final theme = context.theme;
    final colors = theme.colorScheme;
    final isSelected = _selectedTab == tabId;
    return InkWell(
      onTap: () {
        setState(() => _selectedTab = tabId);
        if (tabId == 'presets' && _capturedFrame == null) {
          _captureCurrentFrame();
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 64,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
            ),
            const SizedBox(height: 3),
            AnymeXText.semiBold(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(bool isDesktop) {
    switch (_selectedTab) {
      case 'shaders':
        return _buildShadersTab(isDesktop);
      case 'presets':
        return _buildPresetsTab();
      case 'custom':
        return _buildCustomTab();
      case 'visual':
        return _buildVisualTab();
      default:
        return _buildShadersTab(isDesktop);
    }
  }

  Widget _buildShadersTab(bool isDesktop) {
    final theme = context.theme;
    final colors = theme.colorScheme;
    final cardBg = colors.surfaceContainer.opaque(0.45, iReallyMeanIt: true);

    if (!_areShadersDownloaded) {
      return Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        padding: EdgeInsets.all(isDesktop ? 20 : 16),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                        'High-quality real-time upscaling & line reconstruction GLSL shaders (~1.2 MB).',
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
            const SizedBox(height: 18),
            if (!_isDownloading)
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _downloadShaders,
                      borderRadius: BorderRadius.circular(26),
                      child: Container(
                        height: 52,
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
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => Get.to(() => const SettingsPlayerShaders()),
                    borderRadius: BorderRadius.circular(26),
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      alignment: Alignment.center,
                      child: AnymeXText.semiBold(
                        'Settings',
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AnymeXText(
                        _statusText,
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.onSurface,
                        ),
                      ),
                      AnymeXText.semiBold(
                        '${_downloadProgress.toInt()}%',
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
                      value: _downloadProgress / 100.0,
                      backgroundColor: colors.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 10),
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

    final isDefault =
        !_shadersOn || _selectedShader == 'Default' || _selectedShader.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnymeXSectionBuilder(
          title: 'Anime4K Engine',
          children: [
            AnymeXTile.toggle(
              title: 'Anime4K shaders',
              subtitle: 'Real-time upscaling & line reconstruction',
              value: _shadersOn,
              onChanged: (val) {
                setState(() {
                  _shadersOn = val;
                });
                PlayerUiKeys.shadersEnabled.set(val);
                _applyCurrentShaderMode();
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        AnymeXSectionBuilder(
          title: 'Device Performance',
          children: [
            AnymeXSegmentedButtonGroup<String>(
              selected: _selectedTier,
              items: const [
                (value: 'mid', title: 'Mid-range', icon: null),
                (value: 'high', title: 'High-end', icon: null),
              ],
              onSelected: (tier) {
                setState(() {
                  _selectedTier = tier;
                  settingsController.selectedProfile =
                      tier == 'high' ? 'HIGH-END' : 'MID-END';
                });
                if (_shadersOn) _applyCurrentShaderMode();
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        AnymeXSectionBuilder(
          title: 'Shader Mode',
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _shadersOn = false;
                  _selectedMode = 'Default';
                });
                _setShader('Default');
              },
              borderRadius: BorderRadius.circular(isDefault ? 28 : 20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 72,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: isDefault ? colors.primaryContainer : cardBg,
                  borderRadius: BorderRadius.circular(isDefault ? 28 : 20),
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
                        color: isDefault ? colors.onPrimary : colors.onSurface,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                            'Native source without upscaling',
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
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                mainAxisExtent: 82,
              ),
              itemCount: _modeDefs.length,
              itemBuilder: (context, index) {
                final m = _modeDefs[index];
                final isSelected = _shadersOn && _selectedMode == m.id;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedMode = m.id;
                      _shadersOn = true;
                    });
                    _applyCurrentShaderMode();
                  },
                  borderRadius: BorderRadius.circular(isSelected ? 28 : 16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: isSelected ? colors.primaryContainer : cardBg,
                      borderRadius: BorderRadius.circular(isSelected ? 28 : 16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
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
        ),
      ],
    );
  }

  static List<double> _identityMatrix() => [
        1,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ];

  static List<double> _multiplyColorMatrices(List<double> a, List<double> b) {
    final result = List<double>.filled(20, 0.0);
    for (int y = 0; y < 4; y++) {
      for (int x = 0; x < 4; x++) {
        result[y * 5 + x] = a[y * 5 + 0] * b[0 * 5 + x] +
            a[y * 5 + 1] * b[1 * 5 + x] +
            a[y * 5 + 2] * b[2 * 5 + x] +
            a[y * 5 + 3] * b[3 * 5 + x];
      }
      result[y * 5 + 4] = a[y * 5 + 0] * b[0 * 5 + 4] +
          a[y * 5 + 1] * b[1 * 5 + 4] +
          a[y * 5 + 2] * b[2 * 5 + 4] +
          a[y * 5 + 3] * b[3 * 5 + 4] +
          a[y * 5 + 4];
    }
    return result;
  }

  static List<double> _brightnessMatrix(double b) {
    final offset = b * 2.55;
    return [
      1,
      0,
      0,
      0,
      offset,
      0,
      1,
      0,
      0,
      offset,
      0,
      0,
      1,
      0,
      offset,
      0,
      0,
      0,
      1,
      0,
    ];
  }

  static List<double> _contrastMatrix(double c) {
    final f = (c + 100.0) / 100.0;
    final off = 128.0 * (1.0 - f);
    return [
      f,
      0,
      0,
      0,
      off,
      0,
      f,
      0,
      0,
      off,
      0,
      0,
      f,
      0,
      off,
      0,
      0,
      0,
      1,
      0,
    ];
  }

  static List<double> _saturationMatrix(double s) {
    final sat = (s + 100.0) / 100.0;
    final invSat = 1.0 - sat;
    final r = 0.2126 * invSat;
    final g = 0.7152 * invSat;
    final b = 0.0722 * invSat;
    return [
      r + sat,
      g,
      b,
      0,
      0,
      r,
      g + sat,
      b,
      0,
      0,
      r,
      g,
      b + sat,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];
  }

  static List<double> _hueMatrix(double degrees) {
    final rad = degrees * math.pi / 180.0;
    final cosVal = math.cos(rad);
    final sinVal = math.sin(rad);
    const lumR = 0.213;
    const lumG = 0.715;
    const lumB = 0.072;
    return [
      lumR + cosVal * (1 - lumR) + sinVal * (-lumR),
      lumG + cosVal * (-lumG) + sinVal * (-lumG),
      lumB + cosVal * (-lumB) + sinVal * (1 - lumB),
      0,
      0,
      lumR + cosVal * (-lumR) + sinVal * (0.143),
      lumG + cosVal * (1 - lumG) + sinVal * (0.140),
      lumB + cosVal * (-lumB) + sinVal * (-0.283),
      0,
      0,
      lumR + cosVal * (-lumR) + sinVal * (-(1 - lumR)),
      lumG + cosVal * (-lumG) + sinVal * (lumG),
      lumB + cosVal * (1 - lumB) + sinVal * (lumB),
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];
  }

  static List<double> _calculateColorMatrixForPreset(String key) {
    final settings = ColorProfileManager.profiles[key] ??
        ColorProfileManager.profiles['natural']!;
    final b = (settings['brightness'] ?? 0).toDouble();
    final c = (settings['contrast'] ?? 0).toDouble();
    final s = (settings['saturation'] ?? 0).toDouble();
    final h = (settings['hue'] ?? 0).toDouble();

    var m = _identityMatrix();
    if (b != 0) m = _multiplyColorMatrices(m, _brightnessMatrix(b));
    if (c != 0) m = _multiplyColorMatrices(m, _contrastMatrix(c));
    if (s != 0) m = _multiplyColorMatrices(m, _saturationMatrix(s));
    if (h != 0) m = _multiplyColorMatrices(m, _hueMatrix(h));
    return m;
  }

  Widget _buildFramePreview() {
    if (_capturedFrame != null) {
      return Image.memory(
        _capturedFrame!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
      );
    }
    if (Get.isRegistered<PlayerController>()) {
      final pc = Get.find<PlayerController>();
      final thumb = pc.currentEpisode.value.thumbnail;
      if (thumb != null && thumb.isNotEmpty) {
        return AnymeXImage(
          imageUrl: thumb,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      }
      final poster = pc.anilistData.poster.isNotEmpty
          ? pc.anilistData.poster
          : (pc.anilistData.cover ?? '');
      if (poster.isNotEmpty) {
        return AnymeXImage(
          imageUrl: poster,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      }
    }
    return Container(
      color: context.theme.colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.movie_filter_rounded,
        size: 24,
        color:
            context.theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildPresetsTab() {
    final colors = context.theme.colorScheme;
    final cardBg = colors.surfaceContainer.opaque(0.45, iReallyMeanIt: true);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnymeXSectionBuilder(
          title: 'Color Presets',
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                mainAxisExtent: 132,
              ),
              itemCount: _presetDefs.length,
              itemBuilder: (context, index) {
                final p = _presetDefs[index];
                final isSelected = _selectedProfile == p.key;
                return InkWell(
                  onTap: () => _selectProfile(p.key),
                  borderRadius: BorderRadius.circular(isSelected ? 24 : 16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.primaryContainer.withValues(alpha: 0.6)
                          : cardBg,
                      borderRadius: BorderRadius.circular(isSelected ? 24 : 16),
                      border: Border.all(
                        color: isSelected
                            ? colors.primary
                            : colors.outlineVariant.withValues(alpha: 0.18),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: ColorFiltered(
                              colorFilter: ColorFilter.matrix(
                                _calculateColorMatrixForPreset(p.key),
                              ),
                              child: _buildFramePreview(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: AnymeXText.semiBold(
                                p.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isSelected
                                      ? colors.onPrimaryContainer
                                      : colors.onSurface,
                                ),
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.check_circle_rounded,
                                size: 16,
                                color: colors.primary,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomTab() {
    final theme = context.theme;
    final colors = theme.colorScheme;
    final cardBg = colors.surfaceContainer.opaque(0.45, iReallyMeanIt: true);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnymeXSectionBuilder(
          title: 'Custom Adjustments',
          children: _adjustDefs.map((adj) {
            final val = _customSettings[adj.key] ?? 0;
            final showText = val > 0 ? '+$val' : '$val';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AnymeXText.semiBold(
                        adj.label,
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.onSurface,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        constraints: const BoxConstraints(minWidth: 28),
                        decoration: BoxDecoration(
                          color: colors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: AnymeXText.semiBold(
                          showText,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  AnymeXSliderM3(
                    value: val.toDouble().clamp(-50.0, 50.0),
                    min: -50,
                    max: 50,
                    divisions: 100,
                    label: showText,
                    onChanged: (newVal) {
                      setState(() {
                        _customSettings[adj.key] = newVal.round();
                      });
                      _applyCustomSettings();
                    },
                    theme: AnymeXSliderM3Theme(
                      activeColor: colors.primary,
                      inactiveColor: colors.surfaceContainerHighest,
                      trackHeight: 16,
                      thumbHeight: 40,
                      thumbWidth: 6,
                      outerRadius: 8,
                      thumbCornerRadius: 3,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildVisualTab() {
    final theme = context.theme;
    final colors = theme.colorScheme;
    final cardBg = colors.surfaceContainer.opaque(0.45, iReallyMeanIt: true);
    final deband = (_visualSettings['deband'] as bool?) ?? true;
    final iter =
        ((_visualSettings['debandIterations'] as num?) ?? 2).toDouble();
    final threshold =
        ((_visualSettings['debandThreshold'] as num?) ?? 64).toDouble();
    final scale = (_visualSettings['scale'] as String?) ?? 'spline36';
    final cscale = (_visualSettings['cscale'] as String?) ?? 'spline36';
    final dscale = (_visualSettings['dscale'] as String?) ?? 'mitchell';
    final sigmoid = (_visualSettings['sigmoidUpscaling'] as bool?) ?? true;
    final downscale = (_visualSettings['correctDownscaling'] as bool?) ?? true;
    final interpolation = (_visualSettings['interpolation'] as bool?) ?? false;
    final dither = (_visualSettings['temporalDither'] as bool?) ?? true;
    final ditherDepth = (_visualSettings['ditherDepth'] as String?) ?? 'auto';
    final toneMapping = (_visualSettings['toneMapping'] as String?) ?? 'auto';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnymeXSectionBuilder(
          title: 'Experimental MPV Tuning',
          children: [
            AnymeXTile.toggle(
              icon: Icons.science_outlined,
              title: 'Enable Experimental Tuning',
              subtitle:
                  'Required for MPV visual & core tuning. Keep off on low-end devices.',
              value: _experimentalEnabled,
              onChanged: (val) {
                setState(() => _experimentalEnabled = val);
                PlayerUiKeys.playerExperimentalEnabled.set<bool>(val);
                if (val) {
                  _applyVisualSettings();
                }
              },
            ),
            if (!_experimentalEnabled)
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colors.outlineVariant.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 20, color: colors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AnymeXText(
                        'Experimental tuning is currently disabled. Toggle it on above to adjust debanding, scaling algorithms, frame interpolation, dithering, and tone mapping directly.',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        AnymeXSectionBuilder(
          title: 'Debanding',
          children: [
            AnymeXTile.toggle(
              title: 'Debanding filter',
              subtitle: 'Smooths gradient lines and eliminates banding',
              value: deband,
              onChanged: (val) {
                setState(() => _visualSettings['deband'] = val);
                _applyVisualSettings();
              },
            ),
            Opacity(
              opacity: deband ? 1.0 : 0.4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AnymeXText(
                          'Passes',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: colors.onSurface,
                          ),
                        ),
                        AnymeXText.semiBold(
                          '${iter.toInt()}',
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                    AnymeXSliderM3(
                      value: iter.clamp(1.0, 4.0),
                      min: 1,
                      max: 4,
                      divisions: 3,
                      label: '${iter.toInt()}',
                      onChanged: deband
                          ? (val) {
                              setState(() =>
                                  _visualSettings['debandIterations'] =
                                      val.round());
                              _applyVisualSettings();
                            }
                          : null,
                      theme: AnymeXSliderM3Theme(
                        activeColor: colors.primary,
                        inactiveColor: colors.surfaceContainerHighest,
                        trackHeight: 16,
                        thumbHeight: 40,
                        thumbWidth: 6,
                        outerRadius: 8,
                        thumbCornerRadius: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Opacity(
              opacity: deband ? 1.0 : 0.4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AnymeXText(
                          'Sensitivity',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: colors.onSurface,
                          ),
                        ),
                        AnymeXText.semiBold(
                          '${threshold.toInt()}',
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                    AnymeXSliderM3(
                      value: threshold.clamp(16.0, 128.0),
                      min: 16,
                      max: 128,
                      divisions: 14,
                      label: '${threshold.toInt()}',
                      onChanged: deband
                          ? (val) {
                              setState(() =>
                                  _visualSettings['debandThreshold'] =
                                      val.round());
                              _applyVisualSettings();
                            }
                          : null,
                      theme: AnymeXSliderM3Theme(
                        activeColor: colors.primary,
                        inactiveColor: colors.surfaceContainerHighest,
                        trackHeight: 16,
                        thumbHeight: 40,
                        thumbWidth: 6,
                        outerRadius: 8,
                        thumbCornerRadius: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AnymeXSectionBuilder(
          title: 'Scaling & Algorithms',
          children: [
            AnymeXTile(
              icon: Icons.aspect_ratio_rounded,
              title: 'Scaling (Luma)',
              subtitle: scale,
              onTap: () => _showVisualSelectionDialog(
                title: 'Scaling Algorithm',
                items: const [
                  'spline36',
                  'ewa_lanczossharp',
                  'bilinear',
                  'bicubic',
                  'oversample',
                ],
                selected: scale,
                key: 'scale',
              ),
            ),
            AnymeXTile(
              icon: Icons.palette_outlined,
              title: 'Chroma Scaler',
              subtitle: cscale,
              onTap: () => _showVisualSelectionDialog(
                title: 'Chroma Scaler',
                items: const [
                  'spline36',
                  'ewa_lanczossharp',
                  'bilinear',
                  'mitchell',
                ],
                selected: cscale,
                key: 'cscale',
              ),
            ),
            AnymeXTile(
              icon: Icons.photo_size_select_small_rounded,
              title: 'Downscaling Algorithm',
              subtitle: dscale,
              onTap: () => _showVisualSelectionDialog(
                title: 'Downscaling Algorithm',
                items: const [
                  'mitchell',
                  'bicubic',
                  'bilinear',
                  'hermite',
                ],
                selected: dscale,
                key: 'dscale',
              ),
            ),
            AnymeXTile.toggle(
              title: context.l10n.sigmoidUpscaling,
              subtitle: context.l10n.reducesColorRingingArtifacts,
              value: sigmoid,
              onChanged: (val) {
                setState(() => _visualSettings['sigmoidUpscaling'] = val);
                _applyVisualSettings();
              },
            ),
            AnymeXTile.toggle(
              title: context.l10n.correctDownscaling,
              subtitle: context.l10n.downscalesInLinearLightSpace,
              value: downscale,
              onChanged: (val) {
                setState(() => _visualSettings['correctDownscaling'] = val);
                _applyVisualSettings();
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        AnymeXSectionBuilder(
          title: context.l10n.motionDithering,
          children: [
            AnymeXTile.toggle(
              title: context.l10n.frameInterpolation,
              subtitle: context.l10n.smoothMotionBetweenVideoFrames,
              value: interpolation,
              onChanged: (val) {
                setState(() => _visualSettings['interpolation'] = val);
                _applyVisualSettings();
              },
            ),
            AnymeXTile.toggle(
              title: context.l10n.temporalDither,
              subtitle: context.l10n.reducesColorBandingWithSubtle,
              value: dither,
              onChanged: (val) {
                setState(() => _visualSettings['temporalDither'] = val);
                _applyVisualSettings();
              },
            ),
            AnymeXTile(
              icon: Icons.grain_rounded,
              title: 'Dither Depth',
              subtitle: ditherDepth,
              onTap: () => _showVisualSelectionDialog(
                title: 'Dither Depth',
                items: const ['auto', '8', '10', 'no'],
                selected: ditherDepth,
                key: 'ditherDepth',
              ),
            ),
            AnymeXTile(
              icon: Icons.hdr_auto_rounded,
              title: 'Tone Mapping',
              subtitle: toneMapping,
              onTap: () => _showVisualSelectionDialog(
                title: 'Tone Mapping',
                items: const [
                  'auto',
                  'clip',
                  'mobius',
                  'reinhard',
                  'hable',
                  'bt.2390',
                  'spline',
                ],
                selected: toneMapping,
                key: 'toneMapping',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFullFramePreview() {
    if (Get.isRegistered<PlayerController>()) {
      final pc = Get.find<PlayerController>();
      if (pc.showControls.value) {
        pc.showControls.value = false;
      }
    }

    final theme = context.theme;
    final colors = theme.colorScheme;
    final padding = MediaQuery.paddingOf(context);
    final isDesktop = !Platform.isAndroid && !Platform.isIOS;
    final titleBarHeight =
        (Platform.isWindows && !AnymeXTitleBar.isFullScreen.value) ? 40.0 : 0.0;
    final safeTop = (padding.top + titleBarHeight + (isDesktop ? 16.0 : 10.0))
        .clamp(16.0, 120.0);
    final safeBottom = math.max(padding.bottom, 16.0);

    const shaderModes = [
      'Default',
      'Mode A',
      'Mode B',
      'Mode C',
      'Mode A+A',
      'Mode B+B',
      'Mode C+A',
    ];

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (Get.isRegistered<PlayerController>()) {
                Get.find<PlayerController>().showControls.value = false;
              }
            },
          ),
        ),
        if (_isComparing)
          Positioned(
            top: safeTop,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: AnymeXText.semiBold(
                  'Original · shaders off',
                  style: TextStyle(
                    color: colors.onPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          top: safeTop,
          left: 16,
          right: 16,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 100),
            opacity: _isComparing ? 0.0 : 1.0,
            child: Row(
              children: [
                InkWell(
                  onTap: () => setState(() => _isFullFramePreview = false),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: colors.surface.withValues(alpha: 0.90),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colors.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.tune_rounded,
                            size: 18, color: colors.onSurface),
                        const SizedBox(width: 8),
                        AnymeXText(
                          'Controls',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: colors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.surface.withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colors.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: colors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnymeXText.semiBold(
                        _summaryText,
                        style: TextStyle(
                          color: colors.primary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: colors.surfaceContainerHigh,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(Icons.close_rounded, color: colors.onSurface),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: safeBottom,
          left: 16,
          right: 16,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 100),
            opacity: _isComparing ? 0.0 : 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colors.outlineVariant.withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 60,
                        child: AnymeXText.semiBold(
                          'Profile',
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Expanded(
                        child: AnymeXSegmentedButtonGroup<String>(
                          selected: _selectedTier,
                          items: const [
                            (value: 'mid', title: 'Mid-range', icon: null),
                            (value: 'high', title: 'High-end', icon: null),
                          ],
                          height: 38,
                          selectedRadius: 19,
                          unselectedRadius: 10,
                          onSelected: (tier) {
                            setState(() {
                              _selectedTier = tier;
                              settingsController.selectedProfile =
                                  tier == 'high' ? 'HIGH-END' : 'MID-END';
                            });
                            if (_shadersOn) _applyCurrentShaderMode();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      SizedBox(
                        width: 60,
                        child: AnymeXText.semiBold(
                          'Shaders',
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Expanded(
                        child: AnymeXPills(
                          items: shaderModes.map((mode) {
                            final isSelected = mode == 'Default'
                                ? (!_shadersOn ||
                                    _selectedShader == 'Default' ||
                                    _selectedShader.isEmpty)
                                : (_shadersOn &&
                                    _selectedShader.contains(mode));
                            return PillItem(
                              label: mode,
                              isSelected: isSelected,
                              onTap: () {
                                if (mode == 'Default') {
                                  setState(() => _shadersOn = false);
                                  _setShader('Default');
                                } else {
                                  final cleanMode =
                                      mode.replaceFirst('Mode ', '');
                                  setState(() {
                                    _selectedMode = cleanMode;
                                    _shadersOn = true;
                                  });
                                  _applyCurrentShaderMode();
                                }
                              },
                            );
                          }).toList(),
                          style: PillStyle.connective,
                          scrollable: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      SizedBox(
                        width: 60,
                        child: AnymeXText.semiBold(
                          'Presets',
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Expanded(
                        child: AnymeXPills(
                          items: _presetDefs.map((p) {
                            return PillItem(
                              label: p.title,
                              isSelected: _selectedProfile == p.key,
                              onTap: () => _selectProfile(p.key),
                            );
                          }).toList(),
                          style: PillStyle.connective,
                          scrollable: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
