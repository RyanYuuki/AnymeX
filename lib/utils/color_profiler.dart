// ignore_for_file: deprecated_member_use

import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/player_core_visual_settings.dart';
import 'package:anymex/utils/shaders.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/widgets/common/slider_semantics.dart';
import 'package:anymex/widgets/custom_widgets/custom_expansion_tile.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/non_widgets/reusable_checkmark.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class ColorProfileManager {
  static bool get _experimentalEnabled =>
      PlayerUiKeys.playerExperimentalEnabled.get<bool>(false);

  static const Map<String, Map<String, int>> profiles = {
    "cinema": {
      "brightness": 2,
      "contrast": 12,
      "saturation": 8,
      "gamma": 5,
      "hue": 0,
    },
    "cinema_dark": {
      "brightness": -12,
      "contrast": 18,
      "saturation": 6,
      "gamma": 12,
      "hue": -1,
    },
    "cinema_hdr": {
      "brightness": 5,
      "contrast": 22,
      "saturation": 12,
      "gamma": 3,
      "hue": -1,
    },
    "anime": {
      "brightness": 10,
      "contrast": 22,
      "saturation": 30,
      "gamma": -3,
      "hue": 3,
    },
    "anime_vibrant": {
      "brightness": 14,
      "contrast": 28,
      "saturation": 42,
      "gamma": -6,
      "hue": 4,
    },
    "anime_soft": {
      "brightness": 8,
      "contrast": 16,
      "saturation": 25,
      "gamma": -1,
      "hue": 2,
    },
    "anime_4k": {
      "brightness": 0,
      "contrast": 20,
      "saturation": 100,
      "gamma": 1,
      "hue": 2,
    },
    "vivid": {
      "brightness": 8,
      "contrast": 25,
      "saturation": 35,
      "gamma": 2,
      "hue": 1,
    },
    "vivid_pop": {
      "brightness": 12,
      "contrast": 32,
      "saturation": 48,
      "gamma": 4,
      "hue": 2,
    },
    "vivid_warm": {
      "brightness": 6,
      "contrast": 24,
      "saturation": 32,
      "gamma": 1,
      "hue": 8,
    },
    "natural": {
      "brightness": 0,
      "contrast": 0,
      "saturation": 0,
      "gamma": 0,
      "hue": 0,
    },
    "dark": {
      "brightness": -18,
      "contrast": 15,
      "saturation": -8,
      "gamma": 15,
      "hue": -2,
    },
    "warm": {
      "brightness": 3,
      "contrast": 10,
      "saturation": 15,
      "gamma": 2,
      "hue": 6,
    },
    "cool": {
      "brightness": 1,
      "contrast": 8,
      "saturation": 12,
      "gamma": 1,
      "hue": -6,
    },
    "grayscale": {
      "brightness": 2,
      "contrast": 20,
      "saturation": -100,
      "gamma": 8,
      "hue": 0,
    },
    "custom": {
      "brightness": 0,
      "contrast": 0,
      "saturation": 0,
      "gamma": 0,
      "hue": 0,
    },
  };

  static const Map<String, String> profileDescriptions = {
    "cinema": "Balanced colors for movie watching",
    "cinema_dark": "Optimized for dark room cinema viewing",
    "cinema_hdr": "Enhanced cinema with HDR-like contrast",
    "anime": "Enhanced colors perfect for animation",
    "anime_vibrant": "Maximum saturation for colorful anime",
    "anime_soft": "Gentle enhancement for pastel anime",
    "anime_4k": "Ultra-sharp with vibrant 4K clarity",
    "vivid": "Bright and punchy colors",
    "vivid_pop": "Maximum vibrancy for eye-catching content",
    "vivid_warm": "Vivid colors with warm temperature",
    "natural": "Default balanced settings",
    "dark": "Optimized for dark environments",
    "warm": "Warmer tones for comfort viewing",
    "cool": "Cooler tones for clarity",
    "grayscale": "Black and white viewing",
    "custom": "Your personalized settings",
  };

  static const Map<String, IconData> profileIcons = {
    "cinema": Icons.movie,
    "cinema_dark": Icons.movie_outlined,
    "cinema_hdr": Icons.hd,
    "anime": Icons.animation,
    "anime_vibrant": Icons.color_lens,
    "anime_soft": Icons.blur_on,
    "anime_4k": Icons.four_k,
    "vivid": Icons.palette,
    "vivid_pop": Icons.auto_awesome,
    "vivid_warm": Icons.wb_sunny,
    "natural": Icons.nature,
    "dark": Icons.dark_mode,
    "warm": Icons.wb_sunny,
    "cool": Icons.ac_unit,
    "grayscale": Icons.gradient,
    "custom": Icons.tune,
  };

  Future<void> applyColorProfile(String profile, dynamic player) async {
    if (!_experimentalEnabled) {
      Logger.i('Skipped color profile apply (experimental disabled)');
      return;
    }
    final settings = profiles[profile.toLowerCase()];
    if (settings != null && player.platform != null) {
      try {
        for (final entry in settings.entries) {
          await (player.platform as dynamic)
              .setProperty(entry.key, entry.value.toString());
          Logger.i('Applied ${entry.key}: ${entry.value}');
        }
      } catch (e) {
        Logger.i('Error applying color profile: $e');
      }
    }
  }

  Future<void> applyCustomSettings(
      Map<String, int> customSettings, dynamic player) async {
    if (!_experimentalEnabled) {
      Logger.i('Skipped custom visual settings apply (experimental disabled)');
      return;
    }
    if (player.platform != null) {
      try {
        for (final entry in customSettings.entries) {
          await (player.platform as dynamic)
              .setProperty(entry.key, entry.value.toString());
        }
      } catch (e) {
        Logger.i('Error applying custom settings: $e');
      }
    }
  }

  Future<void> resetToNatural(dynamic player) async {
    if (!_experimentalEnabled) return;
    await applyColorProfile('natural', player);
  }

  Future<void> resetShader(dynamic player) async {
    if (!_experimentalEnabled) {
      Logger.i('Skipped shader reset (experimental disabled)');
      return;
    }
    try {
      if (player.platform != null) {
        await PlayerShaders.setShaders(player, "Default");
        Logger.i('Shader reset to Default');
      }
    } catch (e) {
      Logger.i('Error resetting shader: $e');
    }
  }
}

class ColorProfileBottomSheet extends StatefulWidget {
  final String currentProfile;
  final Map<String, int> activeSettings;
  final Function(String) onProfileSelected;
  final Function(Map<String, int>) onCustomSettingsChanged;
  final dynamic player;

  const ColorProfileBottomSheet({
    super.key,
    required this.currentProfile,
    required this.activeSettings,
    required this.onProfileSelected,
    required this.onCustomSettingsChanged,
    required this.player,
  });

  static void showColorProfileSheet(
      BuildContext context, PlayerController controller, dynamic player) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ColorProfileBottomSheet(
        activeSettings: controller.customSettings,
        currentProfile: controller.currentVisualProfile.value,
        player: player,
        onProfileSelected: (profile) {
          controller.currentVisualProfile.value = profile;
          PlayerUiKeys.currentVisualProfile.set(profile);
        },
        onCustomSettingsChanged: (sett) {
          controller.customSettings.value = sett;
          PlayerUiKeys.currentVisualSettings.set(sett);
        },
      ),
    );
  }

  @override
  State<ColorProfileBottomSheet> createState() =>
      _ColorProfileBottomSheetState();
}

class _ColorProfileBottomSheetState extends State<ColorProfileBottomSheet>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedProfile = '';
  String _selectedShader = '';
  Map<String, int> _customSettings = {
    "brightness": 0,
    "contrast": 0,
    "saturation": 0,
    "gamma": 0,
    "hue": 0,
  };
  late Map<String, dynamic> _visualSettings;

  bool get _experimentalEnabled =>
      PlayerUiKeys.playerExperimentalEnabled.get<bool>(false);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _selectedProfile = widget.currentProfile;
    _selectedShader = settingsController.selectedShader.isEmpty
        ? "Default"
        : settingsController.selectedShader;
    if (widget.currentProfile.toLowerCase() == 'custom') {
      _customSettings = Map.from(widget.activeSettings);
    } else {
      _customSettings = Map.from(ColorProfileManager.profiles['natural']!);
    }
    _visualSettings = PlayerCoreVisualSettings.getMpvVisualSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showProfileAppliedFeedback(String profileName) {
    HapticFeedback.lightImpact();
    Logger.i('Applied ${profileName.toUpperCase()} profile');
  }

  Future<void> _applyCustomSettings() async {
    setState(() => _selectedProfile = 'custom');
    await ColorProfileManager()
        .applyCustomSettings(_customSettings, widget.player);
    widget.onProfileSelected('custom');
    widget.onCustomSettingsChanged(_customSettings);
    _showProfileAppliedFeedback('Custom');
  }

  Future<void> _resetShaderToDefault() async {
    setState(() {
      _selectedShader = "Default";
    });
    await ColorProfileManager().resetShader(widget.player);
    settingsController.selectedShader = "Default";
    PlayerUiKeys.selectedShader.set("Default");
    HapticFeedback.lightImpact();
    Logger.i('Shader reset to Default');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Shader reset to Default'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  void _resetPresetToNatural() async {
    setState(() {
      _selectedProfile = 'natural';
    });
    await ColorProfileManager().resetToNatural(widget.player);
    widget.onProfileSelected('natural');
    _showProfileAppliedFeedback('natural');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Reset to Natural profile'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  void _resetCustomToDefault() async {
    setState(() {
      _customSettings = Map.from(ColorProfileManager.profiles['natural']!);
    });
    await _applyCustomSettings();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Custom settings reset to default'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  Future<void> _applyVisualSettings() async {
    if (!_experimentalEnabled) return;
    PlayerUiKeys.mpvVisualSettings.set(_visualSettings);
    await PlayerCoreVisualSettings.applyMpvVisualSettings(widget.player);
  }

  Future<void> _resetVisualToDefault() async {
    setState(() {
      _visualSettings = Map<String, dynamic>.from(
        PlayerCoreVisualSettings.mpvVisualDefaults,
      );
    });
    await _applyVisualSettings();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Visual settings reset to defaults'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.opaque(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.tune,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Color Profiles',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.surfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.opaque(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.eye, size: 20),
                      SizedBox(width: 8),
                      AnymexText.semiBold(text: 'Shaders'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.movie_filter_rounded, size: 20),
                      SizedBox(width: 8),
                      AnymexText.semiBold(text: 'Visual'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.dashboard_customize, size: 20),
                      SizedBox(width: 8),
                      AnymexText.semiBold(text: 'Presets'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.tune, size: 20),
                      SizedBox(width: 8),
                      AnymexText.semiBold(text: 'Custom'),
                    ],
                  ),
                ),
              ],
              indicator: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.opaque(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: theme.colorScheme.onPrimary,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildShadersTab(theme),
                _buildVisualTab(theme),
                _buildPresetsTab(theme),
                _buildCustomTab(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShadersTab(ThemeData theme) {
    bool enableShaders = PlayerUiKeys.shadersEnabled.get<bool>(false);
    return Column(
      children: [
        Expanded(
          child: Opacity(
            opacity: enableShaders ? 1 : 0.3,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primaryContainer.opaque(0.3),
                        theme.colorScheme.secondaryContainer.opaque(0.3),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          enableShaders
                              ? 'Choose a shader that matches your viewing preference'
                              : 'Shaders are disabled (Enable them from Settings > Experimental)',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                AnymexExpansionTile(
                  title: 'ANIME 4K',
                  initialExpanded: true,
                  content: Column(
                    children: ["Default", ...PlayerShaders.getShaders()]
                        .map((shader) {
                      return Obx(() {
                        final isSelected = shader == "Default"
                            ? settingsController.selectedShader.isEmpty ||
                                settingsController.selectedShader == shader
                            : settingsController.selectedShader == shader;
                        return IgnorePointer(
                          ignoring: !enableShaders,
                          child: AnymexOnTap(
                            onTap: () => setShaders(shader),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? LinearGradient(
                                          colors: [
                                            theme.colorScheme.primaryContainer,
                                            theme.colorScheme.primaryContainer
                                                .opaque(0.8),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : null,
                                  color: isSelected
                                      ? null
                                      : theme.colorScheme.surfaceVariant
                                          .opaque(0.5),
                                  borderRadius: BorderRadius.circular(16),
                                  border: isSelected
                                      ? Border.all(
                                          color: theme.colorScheme.primary,
                                          width: 2,
                                        )
                                      : Border.all(
                                          color: theme.colorScheme.outline
                                              .opaque(0.2),
                                          width: 1,
                                        ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: theme.colorScheme.primary
                                                .opaque(0.2),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            shader,
                                            style: theme.textTheme.titleSmall
                                                ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: isSelected
                                                  ? theme.colorScheme
                                                      .onPrimaryContainer
                                                  : theme.colorScheme.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.check,
                                          color: theme.colorScheme.onPrimary,
                                          size: 16,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      });
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Reset button for Shaders tab
        Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: enableShaders ? _resetShaderToDefault : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh, size: 20),
                  SizedBox(width: 8),
                  Text('Reset Shader to Default'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> setShaders(String message, {bool backOut = true}) async {
    if (!_experimentalEnabled) return;
    await PlayerShaders.setShaders(widget.player, message);
    settingsController.selectedShader = message == "Default" ? "" : message;
    PlayerUiKeys.selectedShader.set(message == "Default" ? "" : message);
    setState(() {
      _selectedShader = message;
    });
    HapticFeedback.lightImpact();
    if (backOut) {
      Navigator.pop(context);
    }
  }

  Widget _buildPresetsTab(ThemeData theme) {
    Map<String, List<String>> groupedProfiles = {
      'Anime': ['anime_4k', 'anime', 'anime_vibrant', 'anime_soft'],
      'Cinema': ['cinema', 'cinema_dark', 'cinema_hdr'],
      'Vivid': ['vivid', 'vivid_pop', 'vivid_warm'],
      'Other': ['natural', 'dark', 'warm', 'cool', 'grayscale'],
    };

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primaryContainer.opaque(0.3),
                      theme.colorScheme.secondaryContainer.opaque(0.3),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Choose a preset that matches your viewing preference',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ...groupedProfiles.entries.map((category) {
                return AnymexExpansionTile(
                  title: category.key,
                  initialExpanded: true,
                  content: Column(
                    children: category.value.map((profileKey) {
                      final isSelected = _selectedProfile == profileKey;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              setState(() => _selectedProfile = profileKey);
                              await ColorProfileManager()
                                  .applyColorProfile(profileKey, widget.player);
                              widget.onProfileSelected(profileKey);
                              _showProfileAppliedFeedback(profileKey);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? LinearGradient(
                                        colors: [
                                          theme.colorScheme.primaryContainer,
                                          theme.colorScheme.primaryContainer
                                              .opaque(0.8),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                color: isSelected
                                    ? null
                                    : theme.colorScheme.surfaceVariant
                                        .opaque(0.5),
                                borderRadius: BorderRadius.circular(16),
                                border: isSelected
                                    ? Border.all(
                                        color: theme.colorScheme.primary,
                                        width: 2,
                                      )
                                    : Border.all(
                                        color: theme.colorScheme.outline
                                            .opaque(0.2),
                                        width: 1,
                                      ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: theme.colorScheme.primary
                                              .opaque(0.2),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: isSelected
                                          ? LinearGradient(
                                              colors: [
                                                theme.colorScheme.primary,
                                                theme.colorScheme.primary
                                                    .opaque(0.8),
                                              ],
                                            )
                                          : null,
                                      color: isSelected
                                          ? null
                                          : theme.colorScheme.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: theme.colorScheme.primary
                                                    .opaque(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Icon(
                                      ColorProfileManager
                                          .profileIcons[profileKey],
                                      color: isSelected
                                          ? theme.colorScheme.onPrimary
                                          : theme.colorScheme.onSurface,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          profileKey
                                              .replaceAll('_', ' ')
                                              .toUpperCase(),
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: isSelected
                                                ? theme.colorScheme
                                                    .onPrimaryContainer
                                                : theme.colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          ColorProfileManager
                                                      .profileDescriptions[
                                                  profileKey] ??
                                              '',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: isSelected
                                                ? theme.colorScheme
                                                    .onPrimaryContainer
                                                    .opaque(0.8)
                                                : theme.colorScheme
                                                    .onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.check,
                                        color: theme.colorScheme.onPrimary,
                                        size: 16,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              }),
            ],
          ),
        ),
        // Reset button for Presets tab
        Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: _resetPresetToNatural,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh, size: 20),
                  SizedBox(width: 8),
                  Text('Reset to Natural Profile'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVisualTab(ThemeData theme) {
    if (!_experimentalEnabled) {
      return _buildVisualLockedState(theme);
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primaryContainer.opaque(0.3),
                      theme.colorScheme.secondaryContainer.opaque(0.3),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.tune_rounded,
                        color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'These controls directly affect mpv rendering quality & picture output',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildVisualSwitchTile(
                keyName: 'deband',
                title: 'Deband',
                description: 'Reduce color banding in gradients',
                icon: Icons.gradient_rounded,
              ),
              _buildVisualSwitchTile(
                keyName: 'correctDownscaling',
                title: 'Correct Downscaling',
                description: 'Improve quality when scaling down video',
                icon: Icons.fit_screen_rounded,
              ),
              _buildVisualSwitchTile(
                keyName: 'sigmoidUpscaling',
                title: 'Sigmoid Upscaling',
                description: 'Reduce haloing while upscaling',
                icon: Icons.auto_fix_high_rounded,
              ),
              _buildVisualSwitchTile(
                keyName: 'temporalDither',
                title: 'Temporal Dither',
                description: 'Smoother gradients with slight temporal noise',
                icon: Icons.grain_rounded,
              ),
              _buildVisualSelectionTile(
                keyName: 'scale',
                title: 'Luma Upscaler',
                icon: Icons.zoom_in_map_rounded,
                items: const [
                  'bilinear',
                  'bicubic',
                  'spline36',
                  'ewa_lanczossharp',
                ],
              ),
              _buildVisualSelectionTile(
                keyName: 'cscale',
                title: 'Chroma Upscaler',
                icon: Icons.color_lens_rounded,
                items: const [
                  'bilinear',
                  'bicubic',
                  'spline36',
                  'ewa_lanczossharp',
                ],
              ),
              _buildVisualSelectionTile(
                keyName: 'dscale',
                title: 'Downscaler',
                icon: Icons.zoom_out_map_rounded,
                items: const ['bilinear', 'bicubic', 'mitchell', 'spline36'],
              ),
              _buildVisualSelectionTile(
                keyName: 'ditherDepth',
                title: 'Dither Depth',
                icon: Icons.blur_linear_rounded,
                items: const ['auto', '8', '10', '12'],
              ),
              _buildVisualSelectionTile(
                keyName: 'toneMapping',
                title: 'Tone Mapping',
                icon: Icons.hdr_auto_rounded,
                items: const ['auto', 'mobius', 'reinhard', 'hable', 'bt.2390'],
              ),
              _buildVisualSliderTile(
                keyName: 'debandIterations',
                title: 'Deband Iterations',
                description: 'More iterations = stronger debanding',
                icon: Icons.layers_rounded,
                min: 1,
                max: 4,
                divisions: 3,
              ),
              _buildVisualSliderTile(
                keyName: 'debandThreshold',
                title: 'Deband Threshold',
                description: 'Higher value increases debanding strength',
                icon: Icons.tune_rounded,
                min: 16,
                max: 128,
                divisions: 28,
              ),
              _buildVisualSliderTile(
                keyName: 'targetPeak',
                title: 'Target Peak',
                description: 'HDR tone mapping target peak',
                icon: Icons.brightness_6_rounded,
                min: 50,
                max: 1000,
                divisions: 38,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: _resetVisualToDefault,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh, size: 20),
                  SizedBox(width: 8),
                  Text('Reset Visual Settings'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVisualLockedState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.opaque(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.primary.opaque(0.35),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.science_outlined,
                size: 28,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                'Visual settings are experimental',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Enable Experimental in Player Settings to use this tab.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisualSwitchTile({
    required String keyName,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return CustomSwitchTile(
      icon: icon,
      title: title,
      description: description,
      switchValue: (_visualSettings[keyName] as bool?) ?? false,
      onChanged: (value) {
        setState(() => _visualSettings[keyName] = value);
        _applyVisualSettings();
      },
    );
  }

  Widget _buildVisualSelectionTile({
    required String keyName,
    required String title,
    required IconData icon,
    required List<String> items,
  }) {
    final current = (_visualSettings[keyName] as String?) ?? items.first;
    return CustomTile(
      icon: icon,
      title: title,
      description: current,
      isDescBold: true,
      descColor: Theme.of(context).colorScheme.primary,
      onTap: () {
        showSelectionDialog<String>(
          title: title,
          items: items,
          selectedItem: current.obs,
          getTitle: (v) => v,
          onItemSelected: (v) {
            setState(() => _visualSettings[keyName] = v);
            _applyVisualSettings();
          },
          leadingIcon: icon,
        );
      },
    );
  }

  Widget _buildVisualSliderTile({
    required String keyName,
    required String title,
    required String description,
    required IconData icon,
    required double min,
    required double max,
    required int divisions,
  }) {
    final value = ((_visualSettings[keyName] as num?) ?? min).toDouble();
    return CustomSliderTile(
      icon: icon,
      title: title,
      description: description,
      sliderValue: value.clamp(min, max),
      min: min,
      max: max,
      divisions: divisions.toDouble(),
      label: value.round().toString(),
      onChanged: (newValue) {
        setState(() => _visualSettings[keyName] = newValue.round());
        _applyVisualSettings();
      },
    );
  }

  Widget _buildCustomTab(ThemeData theme) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primaryContainer.opaque(0.3),
                      theme.colorScheme.secondaryContainer.opaque(0.3),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.tune,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Fine-tune individual settings to your preference',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ..._customSettings.keys.map((setting) {
                return _buildSliderTile(setting, theme);
              }),
            ],
          ),
        ),
        // Reset button for Custom tab
        Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: _resetCustomToDefault,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh, size: 20),
                  SizedBox(width: 8),
                  Text('Reset to Default Settings'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliderTile(String setting, ThemeData theme) {
    final value = _customSettings[setting]!;
    final displayName = setting[0].toUpperCase() + setting.substring(1);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.opaque(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.opaque(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                displayName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.opaque(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.opaque(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  value.toString(),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomSlider(
            value: value.toDouble(),
            min: -100,
            max: 100,
            divisions: 200,
            onChanged: (newValue) {
              setState(() {
                _customSettings[setting] = newValue.round();
              });
              _applyCustomSettings();
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '-100',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '100',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
