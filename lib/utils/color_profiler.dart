// ignore_for_file: deprecated_member_use

import 'dart:developer';

import 'package:anymex/widgets/custom_widgets/custom_expansion_tile.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ColorProfileManager {
  static const Map<String, Map<String, int>> profiles = {
    "cinema": {
      "brightness": 5,
      "contrast": 15,
      "saturation": 10,
      "gamma": 8,
      "hue": 0,
    },
    "cinema_dark": {
      "brightness": -8,
      "contrast": 20,
      "saturation": 12,
      "gamma": 15,
      "hue": 0,
    },
    "cinema_hdr": {
      "brightness": 3,
      "contrast": 25,
      "saturation": 8,
      "gamma": 5,
      "hue": -2,
    },
    "anime": {
      "brightness": 8,
      "contrast": 25,
      "saturation": 35,
      "gamma": -5,
      "hue": 2,
    },
    "anime_vibrant": {
      "brightness": 12,
      "contrast": 30,
      "saturation": 45,
      "gamma": -8,
      "hue": 5,
    },
    "anime_soft": {
      "brightness": 6,
      "contrast": 18,
      "saturation": 28,
      "gamma": -2,
      "hue": 1,
    },
    "vivid": {
      "brightness": 12,
      "contrast": 30,
      "saturation": 40,
      "gamma": 5,
      "hue": 0,
    },
    "vivid_pop": {
      "brightness": 15,
      "contrast": 35,
      "saturation": 50,
      "gamma": 8,
      "hue": 3,
    },
    "vivid_warm": {
      "brightness": 10,
      "contrast": 28,
      "saturation": 38,
      "gamma": 3,
      "hue": 12,
    },
    "natural": {
      "brightness": 0,
      "contrast": 0,
      "saturation": 0,
      "gamma": 0,
      "hue": 0,
    },
    "dark": {
      "brightness": -15,
      "contrast": 10,
      "saturation": -5,
      "gamma": 12,
      "hue": 0,
    },
    "warm": {
      "brightness": 5,
      "contrast": 8,
      "saturation": 12,
      "gamma": 3,
      "hue": 8,
    },
    "cool": {
      "brightness": 2,
      "contrast": 5,
      "saturation": 8,
      "gamma": 0,
      "hue": -8,
    },
    "grayscale": {
      "brightness": 0,
      "contrast": 15,
      "saturation": -100,
      "gamma": 5,
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
    "vivid": "Bright and punchy colors",
    "vivid_pop": "Maximum vibrancy for eye-catching content",
    "vivid_warm": "Vivid colors with warm temperature",
    "natural": "Default balanced settings",
    "dark": "Optimized for dark environments",
    "warm": "Warmer tones for comfort viewing",
    "cool": "Cooler tones for clarity",
    "grayscale": "Black and white viewing",
  };

  static const Map<String, IconData> profileIcons = {
    "cinema": Icons.movie,
    "cinema_dark": Icons.movie_outlined,
    "cinema_hdr": Icons.hd,
    "anime": Icons.animation,
    "anime_vibrant": Icons.color_lens,
    "anime_soft": Icons.blur_on,
    "vivid": Icons.palette,
    "vivid_pop": Icons.auto_awesome,
    "vivid_warm": Icons.wb_sunny,
    "natural": Icons.nature,
    "dark": Icons.dark_mode,
    "warm": Icons.wb_sunny,
    "cool": Icons.ac_unit,
    "grayscale": Icons.gradient,
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
  final Function(String) onProfileSelected;
  final Function(Map<String, int>) onCustomSettingsChanged;
  final dynamic player;

  const ColorProfileBottomSheet({
    super.key,
    required this.currentProfile,
    required this.onProfileSelected,
    required this.onCustomSettingsChanged,
    required this.player,
  });

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
    _tabController = TabController(length: 2, vsync: this);
    _selectedProfile = widget.currentProfile;
    _customSettings = Map.from(ColorProfileManager.profiles['natural']!);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showProfileAppliedFeedback(String profileName) {
    HapticFeedback.lightImpact();
    log('Applied ${profileName.toUpperCase()} profile');
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
                Icon(
                  Icons.tune,
                  color: theme.colorScheme.primary,
                  size: 28,
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
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.dashboard, size: 20),
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
                borderRadius: BorderRadius.circular(8),
              ),
              labelColor: theme.colorScheme.onPrimary,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPresetsTab(theme),
                _buildCustomTab(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetsTab(ThemeData theme) {
    Map<String, List<String>> groupedProfiles = {
      'Anime': ['anime', 'anime_vibrant', 'anime_soft'],
      'Cinema': ['cinema', 'cinema_dark', 'cinema_hdr'],
      'Vivid': ['vivid', 'vivid_pop', 'vivid_warm'],
      'Other': ['natural', 'dark', 'warm', 'cool', 'grayscale'],
    };

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Choose a preset that matches your viewing preference',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        ...groupedProfiles.entries.map((category) {
          return AnymexExpansionTile(
            title: category.key,
            initialExpanded: category.key == 'Cinema' ||
                category.key == 'Anime' ||
                category.key == 'Vivid',
            content: Column(
              children: category.value.map((profileKey) {
                final isSelected = _selectedProfile == profileKey;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
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
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.surfaceVariant
                                  .withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(
                                  color: theme.colorScheme.primary, width: 2)
                              : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                ColorProfileManager.profileIcons[profileKey],
                                color: isSelected
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurface,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profileKey
                                        .replaceAll('_', ' ')
                                        .toUpperCase(),
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? theme.colorScheme.onPrimaryContainer
                                          : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
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
                              Icon(
                                Icons.check_circle,
                                color: theme.colorScheme.primary,
                                size: 20,
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
        Text(
          'Fine-tune individual settings to your preference',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        ..._customSettings.keys.map((setting) {
          return _buildSliderTile(setting, theme);
        }),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonal(
                onPressed: () {
                  setState(() {
                    _customSettings =
                        Map.from(ColorProfileManager.profiles['natural']!);
                  });
                  ColorProfileManager()
                      .applyCustomSettings(_customSettings, widget.player);
                  widget.onCustomSettingsChanged(_customSettings);
                },
                child: const Text('Reset to Default'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () {
                  ColorProfileManager()
                      .applyCustomSettings(_customSettings, widget.player);
                  widget.onCustomSettingsChanged(_customSettings);
                  _showProfileAppliedFeedback('Custom');
                },
                child: const Text('Apply Custom'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSliderTile(String setting, ThemeData theme) {
    final value = _customSettings[setting]!;
    final displayName = setting[0].toUpperCase() + setting.substring(1);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
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
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  value.toString(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
            ),
            child: Slider(
              value: value.toDouble(),
              min: -100,
              max: 100,
              divisions: 200,
              onChanged: (newValue) {
                setState(() {
                  _customSettings[setting] = newValue.round();
                });
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '-100',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '100',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
