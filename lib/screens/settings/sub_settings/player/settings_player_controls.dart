import 'dart:convert';

import 'package:anymex/constants/contants.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/screens/anime/watch/controls/themes/setup/media_indicator_theme.dart';
import 'package:anymex/screens/anime/watch/controls/themes/setup/media_indicator_theme_registry.dart';
import 'package:anymex/screens/anime/watch/controls/themes/setup/player_control_theme_registry.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/player_control_buttons.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/progress_slider.dart';
import 'package:anymex/screens/settings/sub_settings/widgets/settings_json_shared.dart';
import 'package:anymex/utils/subtitle_style_renderer.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_popup_menu.dart';
import 'package:anymex/widgets/common/anymex_pills.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_container.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile_builder.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconsax/iconsax.dart';
import 'package:anymex/l10n/l10n_extension.dart';

const String _previewAnimeImage =
    'https://i.pinimg.com/736x/f8/a1/fd/f8a1fdf302b56743ee6fbd6deb648921.jpg';

class SettingsPlayerControls extends StatefulWidget {
  final bool isModal;
  final bool isEmbedded;
  const SettingsPlayerControls({
    super.key,
    this.isModal = false,
    this.isEmbedded = false,
  });

  @override
  State<SettingsPlayerControls> createState() => _SettingsPlayerControlsState();
}

class _SettingsPlayerControlsState extends State<SettingsPlayerControls> {
  final settings = Get.find<Settings>();

  late List<String> _topButtonIds;
  late List<String> _leftButtonIds;
  late List<String> _rightButtonIds;
  late List<String> _hiddenButtonIds;
  late Map<String, dynamic> _buttonConfigs;

  int _activeControlSlot = 0;

  @override
  void initState() {
    super.initState();
    _loadButtonConfig();
  }

  void _loadButtonConfig() {
    _topButtonIds = [];
    _leftButtonIds = [];
    _rightButtonIds = [];
    _hiddenButtonIds = [];
    _buttonConfigs = {};

    final decodedConfig = readPlayerControlConfig();

    if (decodedConfig.isEmpty) {
      _initializeDefaultButtonLayout();
      return;
    }

    _topButtonIds = resolvePlayerTopButtonIds(decodedConfig);
    _leftButtonIds = List<String>.from(decodedConfig['leftButtonIds'] ?? []);
    _rightButtonIds = List<String>.from(decodedConfig['rightButtonIds'] ?? []);
    _hiddenButtonIds =
        List<String>.from(decodedConfig['hiddenButtonIds'] ?? []);
    _buttonConfigs =
        Map<String, dynamic>.from(decodedConfig['buttonConfigs'] ?? {});

    if (_topButtonIds.isEmpty &&
        _leftButtonIds.isEmpty &&
        _rightButtonIds.isEmpty &&
        _hiddenButtonIds.isEmpty) {
      _initializeDefaultButtonLayout();
    } else {
      _migrateLegacyButtons();
      _pruneRemovedButtons();
      _addNewButtons();
    }
  }

  void _migrateLegacyButtons() {
    const legacyToNew = {
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

    replaceInList(_topButtonIds);
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

    deduplicate(_topButtonIds);
    deduplicate(_leftButtonIds);
    deduplicate(_rightButtonIds);
    deduplicate(_hiddenButtonIds);

    if (migrated) {
      _saveButtonConfig();
    }
  }

  void _saveButtonConfig() {
    final Map<String, dynamic> configToSave = {
      'topButtonIds': _topButtonIds,
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
    _topButtonIds = [];
    _leftButtonIds = [];
    _rightButtonIds = [];
    _hiddenButtonIds = [];
    _buttonConfigs = {};
    for (final control in playerControlCatalog) {
      if (control.defaultSlot == 'top') {
        _topButtonIds.add(control.id);
      } else if (control.defaultSlot == 'left') {
        _leftButtonIds.add(control.id);
      } else {
        _rightButtonIds.add(control.id);
      }
      _buttonConfigs[control.id] = {'visible': true};
    }
    _saveButtonConfig();
  }

  void _pruneRemovedButtons() {
    final allKnownIds = playerControlCatalog.map((c) => c.id).toSet();
    bool changed = false;

    for (final list in [
      _topButtonIds,
      _leftButtonIds,
      _rightButtonIds,
      _hiddenButtonIds,
    ]) {
      final before = list.length;
      list.removeWhere((id) => !allKnownIds.contains(id));
      if (list.length != before) changed = true;
    }

    final beforeCfg = _buttonConfigs.length;
    _buttonConfigs.removeWhere((id, _) => !allKnownIds.contains(id));
    if (_buttonConfigs.length != beforeCfg) changed = true;

    if (changed) _saveButtonConfig();
  }

  void _addNewButtons() {
    final allUserIds = {
      ..._topButtonIds,
      ..._leftButtonIds,
      ..._rightButtonIds,
      ..._hiddenButtonIds,
    };
    bool changed = false;
    for (final control in playerControlCatalog) {
      if (!allUserIds.contains(control.id)) {
        if (control.defaultSlot == 'top') {
          _topButtonIds.add(control.id);
        } else if (control.defaultSlot == 'left') {
          _leftButtonIds.add(control.id);
        } else {
          _rightButtonIds.add(control.id);
        }
        _buttonConfigs[control.id] = {'visible': true};
        changed = true;
      }
    }
    if (changed) _saveButtonConfig();
  }

  void _moveControlToSlot(String id, String targetSlot) {
    _topButtonIds.remove(id);
    _leftButtonIds.remove(id);
    _rightButtonIds.remove(id);
    _hiddenButtonIds.remove(id);

    switch (targetSlot) {
      case 'top':
        _topButtonIds.add(id);
        _buttonConfigs[id] = {'visible': true};
        break;
      case 'left':
        _leftButtonIds.add(id);
        _buttonConfigs[id] = {'visible': true};
        break;
      case 'right':
        _rightButtonIds.add(id);
        _buttonConfigs[id] = {'visible': true};
        break;
      default:
        _hiddenButtonIds.add(id);
        _buttonConfigs[id] = {'visible': false};
        break;
    }
    _saveButtonConfig();
  }

  List<String> _slotList(int slotIndex) {
    return switch (slotIndex) {
      0 => _topButtonIds,
      1 => _leftButtonIds,
      2 => _rightButtonIds,
      _ => _hiddenButtonIds,
    };
  }

  String _slotKey(int slotIndex) {
    return switch (slotIndex) {
      0 => 'top',
      1 => 'left',
      2 => 'right',
      _ => 'hidden',
    };
  }

  PlayerController _acquirePreviewPlayerController() {
    if (Get.isRegistered<PlayerController>()) {
      return Get.find<PlayerController>();
    }
    return Get.put<PlayerController>(
      PlayerController.preview(),
      tag: null,
    );
  }

  void _releasePreviewPlayerController(bool createdTemp) {
    if (createdTemp && Get.isRegistered<PlayerController>()) {
      final ctrl = Get.find<PlayerController>();
      if (ctrl.isPreview) {
        Get.delete<PlayerController>(force: true);
      }
    }
  }

  Future<void> _showPlayerControlThemeDialog() async {
    final hadController = Get.isRegistered<PlayerController>();
    final previewController = _acquirePreviewPlayerController();
    final themes = PlayerControlThemeRegistry.themes;
    String selectedId = settings.playerControlTheme;

    await AnymeXDialog(
      title: context.l10n.playerTheme,
      showCancelButton: false,
      confirmText: context.l10n.actionDone,
      padding: const EdgeInsets.all(20),
      width: getResponsiveValue(
        context,
        mobileValue: Get.width * 0.94,
        desktopValue: 680.0,
      ),
      onConfirm: () {},
      contentWidget: StatefulBuilder(
        builder: (ctx, setDialogState) {
          final colors = ctx.colors;
          final themeObj = PlayerControlThemeRegistry.resolve(selectedId);
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AnymeXText(
                    'Live Preview',
                    size: 12,
                    color: colors.onSurfaceVariant,
                  ),
                  AnymeXText(
                    themeObj.name,
                    size: 12,
                    color: colors.primary,
                    variant: TextVariant.semiBold,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        _previewAnimeImage,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: const Color(0xFF0E131D)),
                      ),
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 58,
                        child: Center(
                          child: buildStyledSubtitleText(
                            text: context.l10n.freedom,
                            textColor:
                                fontColorOptions[settings.subtitleColor] ??
                                    fontColorOptions['Default']!,
                            fontSize: 15,
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
                      IgnorePointer(
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: SizedBox(
                            width: 960,
                            height: 540,
                            child: MediaQuery(
                              data: const MediaQueryData(
                                size: Size(960, 540),
                                padding: EdgeInsets.zero,
                              ),
                              child: Builder(
                                builder: (innerCtx) => Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Align(
                                      alignment: Alignment.center,
                                      child: themeObj.buildCenterControls(
                                          innerCtx, previewController),
                                    ),
                                    Align(
                                      alignment: Alignment.topCenter,
                                      child: themeObj.buildTopControls(
                                          innerCtx, previewController),
                                    ),
                                    Align(
                                      alignment: Alignment.bottomCenter,
                                      child: themeObj.buildBottomControls(
                                          innerCtx, previewController),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: themes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, index) {
                    final item = themes[index];
                    final isSelected = item.id == selectedId;
                    return AnymeXTile.radio(
                      selected: isSelected,
                      title: item.name,
                      onTap: () {
                        setDialogState(() {
                          selectedId = item.id;
                          settings.playerControlTheme = item.id;
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    ).show(context);

    _releasePreviewPlayerController(!hadController);
    if (mounted) setState(() {});
  }

  String _getSliderStyleLabel(BuildContext context, String style) {
    switch (style.toLowerCase()) {
      case 'wavy':
        return context.l10n.linearWavy;
      case 'capsule':
        return context.l10n.capsule;
      case 'ios':
        return 'iOS';
      case 'defaultm3':
      default:
        return context.l10n.defaultM3;
    }
  }

  Future<void> _showSliderStyleDialog(BuildContext context) async {
    final styles = [
      {'id': 'wavy', 'name': context.l10n.linearWavy},
      {'id': 'defaultm3', 'name': context.l10n.defaultM3},
      {'id': 'capsule', 'name': context.l10n.capsule},
      {'id': 'ios', 'name': 'iOS'},
    ];
    String selectedId = settings.progressSliderStyle;

    await AnymeXDialog(
      title: context.l10n.progressSliderStyle,
      showCancelButton: false,
      confirmText: context.l10n.done,
      padding: const EdgeInsets.all(20),
      width: getResponsiveValue(
        context,
        mobileValue: double.infinity,
        desktopValue: 460.0,
      ),
      onConfirm: () {},
      contentWidget: StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AnymeXTileBuilder<Map<String, String>>(
            items: styles,
            selectedItem: styles.firstWhere(
              (s) => s['id'] == selectedId,
              orElse: () => styles[1],
            ),
            isSelected: (s) => s['id'] == selectedId,
            getTitle: (s) => s['name']!,
            getSubtitleWidget: (s) => Padding(
              padding: const EdgeInsets.only(top: 6),
              child: IgnorePointer(
                child: ProgressSliderPreview(
                  style: parseSliderStyle(s['id']!),
                ),
              ),
            ),
            onItemPressed: (s) {
              setDialogState(() {
                selectedId = s['id']!;
                settings.progressSliderStyle = s['id']!;
              });
            },
          );
        },
      ),
    ).show(context);

    if (mounted) setState(() {});
  }

  Future<void> _showMediaIndicatorThemeDialog() async {
    final hadController = Get.isRegistered<PlayerController>();
    final previewController = _acquirePreviewPlayerController();
    final themes = MediaIndicatorThemeRegistry.themes;
    String selectedId = settings.mediaIndicatorTheme;
    bool isVolume = true;
    double value = 0.65;

    await AnymeXDialog(
      title: context.l10n.swipeIndicatorTheme,
      showCancelButton: false,
      confirmText: context.l10n.actionDone,
      padding: const EdgeInsets.all(20),
      width: getResponsiveValue(
        context,
        mobileValue: Get.width * 0.94,
        desktopValue: 600.0,
      ),
      onConfirm: () {},
      contentWidget: StatefulBuilder(
        builder: (ctx, setDialogState) {
          final themeObj = MediaIndicatorThemeRegistry.resolve(selectedId);
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AnymeXText(
                    themeObj.name,
                    size: 12,
                    color: ctx.colors.primary,
                    variant: TextVariant.semiBold,
                  ),
                  SegmentedButton<bool>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                          value: true,
                          icon: Icon(Icons.volume_up_rounded, size: 15)),
                      ButtonSegment(
                          value: false,
                          icon: Icon(Icons.brightness_6_rounded, size: 15)),
                    ],
                    selected: {isVolume},
                    onSelectionChanged: (s) {
                      setDialogState(() {
                        isVolume = s.first;
                        value = isVolume ? 0.65 : 0.72;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        _previewAnimeImage,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: const Color(0xFF0E131D)),
                      ),
                      IgnorePointer(
                        child: themeObj.buildIndicator(
                          ctx,
                          MediaIndicatorThemeData(
                            controller: previewController,
                            isVisible: true,
                            isVolumeIndicator: isVolume,
                            value: value,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Slider(
                value: value,
                min: 0.0,
                max: isVolume ? 2.0 : 1.0,
                onChanged: (v) => setDialogState(() => value = v),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: themes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, index) {
                    final item = themes[index];
                    return AnymeXTile.radio(
                      selected: item.id == selectedId,
                      title: item.name,
                      onTap: () {
                        setDialogState(() {
                          selectedId = item.id;
                          settings.mediaIndicatorTheme = item.id;
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    ).show(context);

    _releasePreviewPlayerController(!hadController);
    if (mounted) setState(() {});
  }

  Future<void> _showGestureAreasDialog() async {
    double brightnessWidth =
        PlayerUiKeys.brightnessGestureWidth.get<double>(0.35).clamp(0.10, 0.45);
    double volumeWidth =
        PlayerUiKeys.volumeGestureWidth.get<double>(0.35).clamp(0.10, 0.45);

    await AnymeXDialog(
      title: context.l10n.gestureAreas,
      confirmText: context.l10n.actionSave,
      cancelText: context.l10n.actionCancel,
      padding: const EdgeInsets.all(20),
      width: getResponsiveValue(
        context,
        mobileValue: Get.width * 0.94,
        desktopValue: 620.0,
      ),
      onConfirm: () {
        PlayerUiKeys.brightnessGestureWidth.set<double>(brightnessWidth);
        PlayerUiKeys.volumeGestureWidth.set<double>(volumeWidth);
        if (mounted) setState(() {});
      },
      contentWidget: StatefulBuilder(
        builder: (ctx, setDialogState) {
          final colors = ctx.colors;
          final overlayWidth =
              (1.0 - brightnessWidth - volumeWidth).clamp(0.10, 0.80);

          void updateBrightness(double v) {
            setDialogState(() {
              brightnessWidth = v.clamp(0.10, 0.45);
              if (brightnessWidth + volumeWidth > 0.90) {
                volumeWidth = (0.90 - brightnessWidth).clamp(0.10, 0.45);
              }
            });
          }

          void updateVolume(double v) {
            setDialogState(() {
              volumeWidth = v.clamp(0.10, 0.45);
              if (brightnessWidth + volumeWidth > 0.90) {
                brightnessWidth = (0.90 - volumeWidth).clamp(0.10, 0.45);
              }
            });
          }

          void updateOverlay(double v) {
            setDialogState(() {
              final targetOverlay = v.clamp(0.10, 0.80);
              final sidesTotal = 1.0 - targetOverlay;
              final currentSides = brightnessWidth + volumeWidth;
              if (currentSides <= 0) {
                brightnessWidth = sidesTotal / 2;
                volumeWidth = sidesTotal / 2;
              } else {
                brightnessWidth =
                    (sidesTotal * (brightnessWidth / currentSides))
                        .clamp(0.10, 0.45);
                volumeWidth = (sidesTotal - brightnessWidth).clamp(0.10, 0.45);
              }
            });
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    setDialogState(() {
                      brightnessWidth = 0.35;
                      volumeWidth = 0.35;
                    });
                  },
                  child: AnymeXText(context.l10n.resetDefault, size: 12),
                ),
              ),
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: LayoutBuilder(
                    builder: (_, constraints) {
                      final totalW = constraints.maxWidth;
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            _previewAnimeImage,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(color: const Color(0xFF0E131D)),
                          ),
                          Row(
                            children: [
                              _gestureZoneOverlayBox(
                                width: totalW * brightnessWidth,
                                color: colors.tertiary,
                                icon: Icons.brightness_6_rounded,
                                label: context.l10n.brightness,
                                percent: (brightnessWidth * 100).round(),
                              ),
                              _gestureZoneOverlayBox(
                                width: totalW * overlayWidth,
                                color: colors.primary,
                                icon: Icons.touch_app_rounded,
                                label: context.l10n.overlay,
                                percent: (overlayWidth * 100).round(),
                              ),
                              _gestureZoneOverlayBox(
                                width: totalW * volumeWidth,
                                color: colors.secondary,
                                icon: Icons.volume_up_rounded,
                                label: context.l10n.volume,
                                percent: (volumeWidth * 100).round(),
                              ),
                            ],
                          ),
                          Positioned(
                            left: (totalW * brightnessWidth) - 14,
                            top: 0,
                            bottom: 0,
                            width: 28,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onHorizontalDragUpdate: (d) {
                                updateBrightness(
                                    brightnessWidth + d.delta.dx / totalW);
                              },
                              child: Center(
                                child: Container(
                                  width: 4,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: (totalW * (1.0 - volumeWidth)) - 14,
                            top: 0,
                            bottom: 0,
                            width: 28,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onHorizontalDragUpdate: (d) {
                                updateVolume(volumeWidth - d.delta.dx / totalW);
                              },
                              child: Center(
                                child: Container(
                                  width: 4,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _areaSliderRow(
                label: context.l10n.brightnessArea,
                percent: (brightnessWidth * 100).round(),
                value: brightnessWidth,
                min: 0.10,
                max: 0.45,
                color: colors.tertiary,
                onChanged: updateBrightness,
              ),
              _areaSliderRow(
                label: context.l10n.overlayAreaTap,
                percent: (overlayWidth * 100).round(),
                value: overlayWidth,
                min: 0.10,
                max: 0.80,
                color: colors.primary,
                onChanged: updateOverlay,
              ),
              _areaSliderRow(
                label: context.l10n.volumeArea,
                percent: (volumeWidth * 100).round(),
                value: volumeWidth,
                min: 0.10,
                max: 0.45,
                color: colors.secondary,
                onChanged: updateVolume,
              ),
            ],
          );
        },
      ),
    ).show(context);
  }

  Widget _gestureZoneOverlayBox({
    required double width,
    required Color color,
    required IconData icon,
    required String label,
    required int percent,
  }) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.32),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 0.8,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(height: 4),
          AnymeXText(
            label,
            size: 10,
            variant: TextVariant.semiBold,
            color: Colors.white,
            maxLines: 1,
          ),
          AnymeXText(
            '$percent%',
            size: 11,
            variant: TextVariant.bold,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _areaSliderRow({
    required String label,
    required int percent,
    required double value,
    required double min,
    required double max,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AnymeXText(label, size: 12, variant: TextVariant.semiBold),
            ),
            AnymeXText('$percent%', size: 12, variant: TextVariant.bold),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          activeColor: color,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDefaultOnlyNote() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 10),
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
              'Note: Player control placement only works on the Default controls theme.',
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

  Widget _buildPlayerControlsBoard() {
    final colors = context.colors;
    final slotNames = [
      ('Top Bar', _topButtonIds.length),
      ('Bottom Left', _leftButtonIds.length),
      ('Bottom Right', _rightButtonIds.length),
      ('Hidden', _hiddenButtonIds.length),
    ];
    final currentList = _slotList(_activeControlSlot);
    final currentSlotKey = _slotKey(_activeControlSlot);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDefaultOnlyNote(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: AnymeXPills(
                  items: List.generate(slotNames.length, (idx) {
                    final active = _activeControlSlot == idx;
                    final (title, count) = slotNames[idx];
                    return PillItem(
                      label: title,
                      count: count,
                      isSelected: active,
                      onTap: () => setState(() => _activeControlSlot = idx),
                    );
                  }),
                  scrollable: true,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: context.l10n.resetToDefaultLayout,
                icon: const Icon(Icons.restart_alt_rounded, size: 20),
                onPressed: _initializeDefaultButtonLayout,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (currentList.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: AnymeXContainer(
              padding: const EdgeInsets.all(16),
              color: colors.surfaceContainer.opaque(0.35),
              borderRadius: BorderRadius.circular(14),
              child: const Center(
                child: AnymeXText(
                  'No controls in this slot. Move a control here using its placement menu.',
                  size: 12,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        else
          ReorderableListView.builder(
            key: ValueKey('slot_list_$currentSlotKey'),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            shrinkWrap: true,
            buildDefaultDragHandles: false,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: currentList.length,
            itemBuilder: (context, index) {
              final id = currentList[index];
              final control =
                  playerControlCatalog.firstWhere((c) => c.id == id);
              return _buildSlotControlTile(
                control,
                currentSlotKey,
                index,
                currentList.length,
                key: ValueKey('slot_${currentSlotKey}_$id'),
              );
            },
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                final item = currentList.removeAt(oldIndex);
                currentList.insert(newIndex, item);
                _saveButtonConfig();
              });
            },
          ),
      ],
    );
  }

  Widget _buildSlotControlTile(
    PlayerControlItemMeta control,
    String currentSlot,
    int index,
    int totalCount, {
    required Key key,
  }) {
    final colors = context.colors;
    final slotLabel = switch (currentSlot) {
      'top' => 'Top Bar',
      'left' => 'Bottom Left',
      'right' => 'Bottom Right',
      _ => 'Hidden',
    };

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
            children: [
              AnymeXPopupMenuButton<String>(
                tooltip: context.l10n.moveToSlot,
                onSelected: (target) {
                  if (target != null) {
                    _moveControlToSlot(control.id, target);
                  }
                },
                items: [
                  AnymeXMenuItem(
                    value: 'top',
                    title: context.l10n.topBar,
                    leadingIcon: Icons.vertical_align_top_rounded,
                  ),
                  AnymeXMenuItem(
                    value: 'left',
                    title: context.l10n.bottomLeft,
                    leadingIcon: Icons.align_horizontal_left_rounded,
                  ),
                  AnymeXMenuItem(
                    value: 'right',
                    title: context.l10n.bottomRight,
                    leadingIcon: Icons.align_horizontal_right_rounded,
                  ),
                  AnymeXMenuItem(
                    value: 'hidden',
                    title: context.l10n.hidden,
                    leadingIcon: Icons.visibility_off_rounded,
                  ),
                ],
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.opaque(0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnymeXText(
                        slotLabel,
                        size: 11,
                        variant: TextVariant.semiBold,
                        color: colors.onPrimaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down_rounded,
                        size: 16,
                        color: colors.onPrimaryContainer,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.drag_handle_rounded,
                    size: 20,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (index < totalCount - 1)
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

  @override
  Widget build(BuildContext context) {
    final brightnessPct = (PlayerUiKeys.brightnessGestureWidth
                .get<double>(0.35)
                .clamp(0.10, 0.45) *
            100)
        .round();
    final volumePct =
        (PlayerUiKeys.volumeGestureWidth.get<double>(0.35).clamp(0.10, 0.45) *
                100)
            .round();
    final overlayPct = (100 - brightnessPct - volumePct).clamp(10, 80);

    final content = Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnymeXSectionBuilder(
            title: context.l10n.themesOverlay,
            children: [
              AnymeXTile(
                icon: HugeIcons.strokeRoundedPlaySquare,
                onTap: _showPlayerControlThemeDialog,
                title: context.l10n.playerTheme,
                subtitle: PlayerControlThemeRegistry.resolve(
                  settings.playerControlTheme,
                ).name,
              ),
              AnymeXTile(
                icon: Icons.data_object_rounded,
                onTap: () =>
                    showJsonPlayerThemesSheet(context, setState, settings),
                title: context.l10n.jsonThemeManager,
                subtitle:
                    '${PlayerControlThemeRegistry.jsonThemes.length} imported theme(s)',
              ),
              AnymeXTile(
                icon: Icons.tune_rounded,
                onTap: _showMediaIndicatorThemeDialog,
                title: context.l10n.swipeIndicatorTheme,
                subtitle: MediaIndicatorThemeRegistry.resolve(
                  settings.mediaIndicatorTheme,
                ).name,
              ),
              AnymeXTile(
                icon: Icons.linear_scale_rounded,
                title: context.l10n.progressSliderStyle,
                subtitle:
                    _getSliderStyleLabel(context, settings.progressSliderStyle),
                onTap: () => _showSliderStyleDialog(context),
              ),
              AnymeXTile.toggle(
                icon: Icons.layers_clear_rounded,
                title: 'Override Theme Slider Style',
                subtitle:
                    'Use your selected progress slider style instead of the active theme slider',
                value: settings.overrideSliderTheme,
                onChanged: (val) => settings.overrideSliderTheme = val,
              ),
              AnymeXTile.toggle(
                icon: Icons.animation_rounded,
                title: context.l10n.animateControlOverlay,
                subtitle: context.l10n.disableToShowAndHidePlayer,
                value: settings.playerMenuAnimation,
                onChanged: (val) => settings.playerMenuAnimation = val,
              ),
            ],
          ),
          AnymeXSectionBuilder(
            title: context.l10n.gesturesSeeking,
            children: [
              AnymeXTile(
                icon: Icons.aspect_ratio_rounded,
                title: context.l10n.gestureAreas,
                subtitle:
                    'Brightness $brightnessPct% • Overlay $overlayPct% • Volume $volumePct%',
                onTap: _showGestureAreasDialog,
              ),
              AnymeXTile.toggle(
                icon: Icons.brightness_6_rounded,
                title: context.l10n.gestureForBrightnessVolume,
                subtitle:
                    'Vertical swipe on brightness & volume areas to adjust levels',
                value: settings.enableSwipeControls,
                onChanged: (val) => settings.enableSwipeControls = val,
              ),
              AnymeXTile.toggle(
                icon: Icons.gesture_rounded,
                title: context.l10n.holdToSpeedUp,
                subtitle:
                    'Press and hold on player screen to temporarily speed up playback',
                value: settings.enableHoldToSeek,
                onChanged: (val) => settings.enableHoldToSeek = val,
              ),
              AnymeXTile.toggle(
                icon: Icons.speed_rounded,
                title: context.l10n.doubleCurrentSpeedOnHold,
                subtitle: context.l10n.doubleCurrentSpeedOnHoldDescription,
                value: settings.relativeHoldSpeed,
                onChanged: (val) => settings.relativeHoldSpeed = val,
              ),
              AnymeXTile.toggle(
                icon: Icons.swap_horiz_rounded,
                title: context.l10n.swipeToSeek,
                subtitle: context.l10n.horizontalSwipeAcrossTheScreenTo,
                value: settings.enableSlideToSeek,
                onChanged: (val) => settings.enableSlideToSeek = val,
              ),
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
                title: context.l10n.doubletapToSeek,
                subtitle: context.l10n.adjustDoubleTapToSeekDuration,
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
                title: context.l10n.megaskipDuration,
                subtitle: context.l10n.adjustMegaskipDuration,
                icon: Iconsax.forward5,
              ),
              AnymeXTile.toggle(
                icon: Icons.preview_rounded,
                title: context.l10n.seekPreview,
                subtitle: context.l10n.showThumbnailScrubbingPreviewWhileSeeking,
                value: settings.enableSeekPreview.value,
                onChanged: (val) {
                  setState(() {
                    settings.setSeekPreviewEnabled(val);
                  });
                },
              ),
            ],
          ),
          AnymeXSectionBuilder(
            title: context.l10n.autoSkipCompletion,
            children: [
              AnymeXTile.toggle(
                icon: Icons.skip_next_outlined,
                title: 'Enable AniSkip',
                subtitle: 'Show skip intro, outro, and recap buttons in the player',
                value: settings.enableAniSkip,
                onChanged: (val) => settings.enableAniSkip = val,
              ),
              AnymeXTile.toggle(
                icon: Icons.fast_forward,
                title: context.l10n.autoSkipOp,
                subtitle: context.l10n.autoSkipTheOpeningSong,
                value: settings.autoSkipOP,
                onChanged: (val) => settings.autoSkipOP = val,
              ),
              AnymeXTile.toggle(
                icon: Icons.fast_forward_outlined,
                title: context.l10n.autoSkipEd,
                subtitle: context.l10n.autoSkipTheEndingSong,
                value: settings.autoSkipED,
                onChanged: (val) => settings.autoSkipED = val,
              ),
              AnymeXTile.toggle(
                icon: Icons.fast_forward_outlined,
                title: context.l10n.autoSkipRecap,
                subtitle: context.l10n.autoSkipTheRecapSection,
                value: settings.autoSkipRecap,
                onChanged: (val) => settings.autoSkipRecap = val,
              ),
              AnymeXTile.toggle(
                icon: Icons.all_inclusive,
                title: context.l10n.autoSkipOnceOnly,
                subtitle: context.l10n.autoSkipOnlyOncePerWatch,
                value: settings.autoSkipOnce,
                onChanged: (val) => settings.autoSkipOnce = val,
              ),
              AnymeXTile.toggle(
                icon: Icons.skip_next_rounded,
                title: context.l10n.autoSkipFiller,
                subtitle:
                    'Automatically skip filler episodes when going to next episode',
                value: settings.autoSkipFiller,
                onChanged: (val) => settings.autoSkipFiller = val,
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
                title: context.l10n.markAsWatched,
                subtitle: context.l10n.percentageWatchedBeforeMarkingCompleted,
                icon: Iconsax.tick_circle,
              ),
            ],
          ),
          AnymeXSectionBuilder(
            title: context.l10n.playerControls,
            disableSeperator: true,
            children: [
              _buildPlayerControlsBoard(),
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
      headerTitle: context.l10n.controlsGestures,
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
