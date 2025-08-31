// ignore_for_file: deprecated_member_use

import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/utils/logger.dart';

import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/utils/shaders.dart';
import 'package:anymex/widgets/common/slider_semantics.dart';
import 'package:anymex/widgets/custom_widgets/custom_expansion_tile.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class ColorProfileManager {
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
    final settings = profiles[profile.toLowerCase()];
    if (settings != null && player.platform != null) {
      try {
        for (final entry in settings.entries) {
          await (player.platform as dynamic)
              .setProperty(entry.key, entry.value.toString());
          print('Applied ${entry.key}: ${entry.value}');
        }
      } catch (e) {
        print('Error applying color profile: $e');
      }
    }
  }

  Future<void> applyCustomSettings(
      Map<String, int> customSettings, dynamic player) async {
    if (player.platform != null) {
      try {
        for (final entry in customSettings.entries) {
          await (player.platform as dynamic)
              .setProperty(entry.key, entry.value.toString());
        }
      } catch (e) {
        print('Error applying custom settings: $e');
      }
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
          controller.settings.preferences.put('currentVisualProfile', profile);
        },
        onCustomSettingsChanged: (sett) {
          controller.customSettings.value = sett;
          controller.settings.preferences.put('currentVisualSettings', sett);
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
  Map<String, int> _customSettings = {
    "brightness": 0,
    "contrast": 0,
    "saturation": 0,
    "gamma": 0,
    "hue": 0,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedProfile = widget.currentProfile;
    if (widget.currentProfile.toLowerCase() == 'custom') {
      _customSettings = Map.from(widget.activeSettings);
    } else {
      _customSettings = Map.from(ColorProfileManager.profiles['natural']!);
    }
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

  void _applyCustomSettings() async {
    setState(() => _selectedProfile = 'custom');
    await ColorProfileManager()
        .applyCustomSettings(_customSettings, widget.player);
    widget.onProfileSelected('custom');
    widget.onCustomSettingsChanged(_customSettings);
    _showProfileAppliedFeedback('Custom');
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
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
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
                  color: theme.colorScheme.shadow.withOpacity(0.1),
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
                      Text('Shaders'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.dashboard_customize, size: 20),
                      SizedBox(width: 8),
                      Text('Presets'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.tune, size: 20),
                      SizedBox(width: 8),
                      Text('Custom'),
                    ],
                  ),
                ),
              ],
              indicator: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
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
    bool enableShaders = (settingsController.preferences
        .get('shaders_enabled', defaultValue: false));
    return Opacity(
      opacity: enableShaders ? 1 : 0.3,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primaryContainer.withOpacity(0.3),
                  theme.colorScheme.secondaryContainer.withOpacity(0.3),
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
              children:
                  ["Default", ...PlayerShaders.getShaders()].map((shader) {
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
                                          .withOpacity(0.8),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: isSelected
                                ? null
                                : theme.colorScheme.surfaceVariant
                                    .withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: isSelected
                                ? Border.all(
                                    color: theme.colorScheme.primary,
                                    width: 2,
                                  )
                                : Border.all(
                                    color: theme.colorScheme.outline
                                        .withOpacity(0.2),
                                    width: 1,
                                  ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: theme.colorScheme.primary
                                          .withOpacity(0.2),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      shader,
                                      style:
                                          theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? theme
                                                .colorScheme.onPrimaryContainer
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
    );
  }

  void setShaders(String message, {bool backOut = true}) async {
    PlayerShaders.setShaders(widget.player, message);
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

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primaryContainer.withOpacity(0.3),
                theme.colorScheme.secondaryContainer.withOpacity(0.3),
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
                                        .withOpacity(0.8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isSelected
                              ? null
                              : theme.colorScheme.surfaceVariant
                                  .withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: isSelected
                              ? Border.all(
                                  color: theme.colorScheme.primary,
                                  width: 2,
                                )
                              : Border.all(
                                  color: theme.colorScheme.outline
                                      .withOpacity(0.2),
                                  width: 1,
                                ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.2),
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
                                              .withOpacity(0.8),
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
                                              .withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Icon(
                                ColorProfileManager.profileIcons[profileKey],
                                color: isSelected
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurface,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profileKey
                                        .replaceAll('_', ' ')
                                        .toUpperCase(),
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? theme.colorScheme.onPrimaryContainer
                                          : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    ColorProfileManager
                                            .profileDescriptions[profileKey] ??
                                        '',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isSelected
                                          ? theme.colorScheme.onPrimaryContainer
                                              .withOpacity(0.8)
                                          : theme.colorScheme.onSurfaceVariant,
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
    );
  }

  Widget _buildCustomTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primaryContainer.withOpacity(0.3),
                theme.colorScheme.secondaryContainer.withOpacity(0.3),
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
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonal(
            onPressed: () {
              setState(() {
                _customSettings =
                    Map.from(ColorProfileManager.profiles['natural']!);
              });
            },
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
                Text('Reset to Default'),
              ],
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
          color: theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
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
                      theme.colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.3),
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
              _applyCustomSettings(); // Apply changes immediately
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
