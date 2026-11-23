import 'package:anymex/l10n/l10n_extension.dart';
import 'dart:async';
import 'package:anymex/database/kv_helper.dart';
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/episodes_pane.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/watch_settings_pane.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/common/anymex_slider_m3.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class SpeedPopup extends StatelessWidget {
  final PlayerController controller;

  const SpeedPopup({super.key, required this.controller});

  void _closePane() {
    controller.isSpeedPaneOpened.value = false;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => EpisodeSidePane(
          isVisible: controller.isSpeedPaneOpened.value,
          onOverlayTap: _closePane,
          child: controller.isSpeedPaneOpened.value
              ? _SpeedPopupContent(
                  controller: controller,
                  onClose: _closePane,
                )
              : const SizedBox.shrink(),
        ));
  }
}

class _SpeedPopupContent extends StatefulWidget {
  final PlayerController controller;
  final VoidCallback onClose;

  const _SpeedPopupContent({
    required this.controller,
    required this.onClose,
  });

  @override
  State<_SpeedPopupContent> createState() => _SpeedPopupContentState();
}

class _SpeedPopupContentState extends State<_SpeedPopupContent> {
  static const List<double> _defaultSpeeds = [
    0.25,
    0.5,
    0.75,
    1.0,
    1.25,
    1.5,
    1.75,
    2.0,
  ];

  late List<double> _speedChips;
  late double _currentSpeed;
  bool _resetDone = false;
  Timer? _resetTimer;

  @override
  void initState() {
    super.initState();
    _currentSpeed = widget.controller.playbackSpeed.value;
    final saved =
        KvHelper.get<List<dynamic>>('custom_playback_speeds', defaultVal: []);
    if (saved.isNotEmpty) {
      _speedChips = saved.map((e) => (e as num).toDouble()).toList();
    } else {
      _speedChips = List<double>.from(_defaultSpeeds);
    }
    if (!_speedChips.contains(_currentSpeed)) {
      _speedChips.add(_currentSpeed);
      _speedChips.sort();
    }
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  bool get _isCurrentDefault =>
      (widget.controller.settings.speed - _currentSpeed).abs() < 0.001;

  String get _speedLabel {
    if ((_currentSpeed - 1.0).abs() < 0.001) return 'Normal speed';
    if (_currentSpeed < 0.75) return 'Slow motion';
    if (_currentSpeed < 1.0) return 'Relaxed pace';
    if (_currentSpeed <= 1.25) return 'Brisk pace';
    if (_currentSpeed <= 1.75) return 'Fast pace';
    if (_currentSpeed <= 2.0) return 'Double speed';
    return 'Ultra fast';
  }

  void _setSpeed(double v) {
    final rounded = (v * 100).round() / 100.0;
    setState(() => _currentSpeed = rounded);
    widget.controller.setRate(rounded);
    HapticFeedback.selectionClick();
  }

  void _removeChip(double speed) {
    if (_speedChips.length <= 1) return;
    setState(() {
      _speedChips.remove(speed);
      if (!_speedChips.contains(_currentSpeed)) {
        _currentSpeed = _speedChips.first;
      }
    });
    KvHelper.set('custom_playback_speeds', _speedChips);
    widget.controller.setRate(_currentSpeed);
    HapticFeedback.lightImpact();
  }

  void _addChip() async {
    final newSpeed = await _showAddSpeedDialog();
    if (newSpeed == null) return;
    if (_speedChips.contains(newSpeed)) {
      _setSpeed(newSpeed);
      return;
    }
    setState(() {
      _speedChips.add(newSpeed);
      _speedChips.sort();
    });
    KvHelper.set('custom_playback_speeds', _speedChips);
    _setSpeed(newSpeed);
  }

  void _restoreChips() {
    setState(() {
      _speedChips = List<double>.from(_defaultSpeeds);
      if (!_speedChips.contains(_currentSpeed)) {
        _currentSpeed = 1.0;
      }
    });
    KvHelper.set('custom_playback_speeds', _speedChips);
    widget.controller.setRate(_currentSpeed);
    HapticFeedback.mediumImpact();
  }

  void _restoreSpeed() {
    _setSpeed(1.0);
    setState(() => _resetDone = true);
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _resetDone = false);
    });
  }

  String _fmt(double v) {
    if (v == 1.0) return '1×';
    final s = v.toStringAsFixed(2);
    return '${s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')}×';
  }

  Future<double?> _showAddSpeedDialog() async {
    double value = 2.5;
    double? confirmedSpeed;
    final quickPicks = [0.33, 1.33, 1.6, 2.25, 2.5, 3.0, 5.0, 10.0, 20.0, 50.0];

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSt) {
            final colors = ctx.theme.colorScheme;
            return AnymeXDialog(
              title: context.l10n.addSpeed,
              confirmText: context.l10n.add,
              cancelText: context.l10n.actionCancel,
              onConfirm: () {
                confirmedSpeed = value;
              },
              confirmResultGetter: () => value,
              contentWidget: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: AnymeXText.semiBold(
                      _fmt(value),
                      style: TextStyle(
                        fontSize: 32,
                        fontFamily: 'Linotte',
                        color: colors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnymeXSliderM3(
                    min: 0.05,
                    max: 50.0,
                    divisions: 999,
                    value: value.clamp(0.05, 50.0),
                    onChanged: (v) {
                      setSt(() {
                        if (v <= 2.0) {
                          value = (v * 20).round() / 20.0;
                        } else if (v <= 10.0) {
                          value = (v * 4).round() / 4.0;
                        } else {
                          value = (v * 2).round() / 2.0;
                        }
                      });
                    },
                    theme: AnymeXSliderM3Theme(
                      activeColor: colors.primary,
                      inactiveColor: colors.surfaceContainerHighest,
                      trackHeight: 16,
                      thumbHeight: 36,
                      thumbWidth: 6,
                      outerRadius: 8,
                      thumbCornerRadius: 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: quickPicks.map((qp) {
                      final isSel = (value - qp).abs() < 0.01;
                      return InkWell(
                        onTap: () => setSt(() => value = qp),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSel
                                ? colors.primary
                                : colors.surfaceContainerLowest
                                    .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSel
                                  ? colors.primary
                                  : colors.outlineVariant
                                      .withValues(alpha: 0.2),
                            ),
                          ),
                          child: AnymeXText.semiBold(
                            _fmt(qp),
                            style: TextStyle(
                              fontSize: 12,
                              color: isSel
                                  ? colors.onPrimary
                                  : colors.onSurface,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    return confirmedSpeed;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final cs = theme.colorScheme;

    return WatchSettingsPane(
      title: context.l10n.playbackSpeed,
      subtitle: AnymeXText(
        '${_fmt(_currentSpeed)} · $_speedLabel',
        style: TextStyle(fontSize: 12, color: cs.primary),
      ),
      onClose: widget.onClose,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPresetsSection(cs, theme),
                  const SizedBox(height: 16),
                  _buildPreferencesSection(cs, theme),
                ],
              ),
            ),
          ),
          _buildBottomBar(cs, theme),
        ],
      ),
    );
  }

  Widget _buildPresetsSection(ColorScheme cs, ThemeData theme) {
    return AnymeXSectionBuilder(
      title: context.l10n.speedPresets,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            InkWell(
              onTap: _restoreChips,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.restore_rounded,
                      size: 14,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    AnymeXText.semiBold(
                      'Restore defaults',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: _addChip,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_rounded,
                      size: 15,
                      color: cs.onPrimaryContainer,
                    ),
                    const SizedBox(width: 4),
                    AnymeXText.semiBold(
                      'Add speed',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            mainAxisExtent: 52,
          ),
          itemCount: _speedChips.length,
          itemBuilder: (context, index) {
            final speed = _speedChips[index];
            final isActive = (_currentSpeed - speed).abs() < 0.001;
            final canDelete = _speedChips.length > 1;

            return InkWell(
              onTap: () => _setSpeed(speed),
              onLongPress: canDelete ? () => _removeChip(speed) : null,
              borderRadius: BorderRadius.circular(isActive ? 20 : 14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: isActive
                      ? cs.primary
                      : cs.surfaceContainer.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(isActive ? 20 : 14),
                  border: Border.all(
                    color: isActive
                        ? cs.primary
                        : cs.outlineVariant.withValues(alpha: 0.18),
                    width: isActive ? 1.5 : 1,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: cs.primary.withValues(alpha: 0.28),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnymeXText.semiBold(
                      _fmt(speed),
                      style: TextStyle(
                        fontSize: 14,
                        color: isActive ? cs.onPrimary : cs.onSurface,
                      ),
                    ),
                    if (canDelete &&
                        !isActive &&
                        !_defaultSpeeds.contains(speed)) ...[
                      const SizedBox(width: 2),
                      GestureDetector(
                        onTap: () => _removeChip(speed),
                        child: Icon(
                          Icons.close_rounded,
                          size: 13,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPreferencesSection(ColorScheme cs, ThemeData theme) {
    return AnymeXSectionBuilder(
      title: context.l10n.preferences,
      children: [
        AnymeXTile.checkbox(
          icon: _isCurrentDefault
              ? Icons.star_rounded
              : Icons.star_outline_rounded,
          title: context.l10n.rememberAsDefaultSpeed,
          subtitle: _isCurrentDefault
              ? '${_fmt(_currentSpeed)} is currently your default speed'
              : 'Set ${_fmt(_currentSpeed)} as default for all media',
          value: _isCurrentDefault,
          onChanged: (val) {
            if (val) {
              widget.controller.settings.speed = _currentSpeed;
            } else {
              widget.controller.settings.speed = 1.0;
            }
            setState(() {});
            HapticFeedback.lightImpact();
          },
        ),
      ],
    );
  }

  Widget _buildBottomBar(ColorScheme cs, ThemeData theme) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow.withValues(alpha: 0.35),
        border: Border(
          top: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: _restoreSpeed,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.2),
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
                      color: _resetDone ? cs.primary : cs.onSurface,
                    ),
                    const SizedBox(width: 8),
                    AnymeXText.semiBold(
                      _resetDone ? 'Reset done' : 'Reset to 1×',
                      style: TextStyle(
                        fontSize: 14,
                        color: _resetDone ? cs.primary : cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: widget.onClose,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: cs.onPrimary,
                    ),
                    const SizedBox(width: 8),
                    AnymeXText.semiBold(
                      'Done',
                      style: TextStyle(
                        fontSize: 14,
                        color: cs.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
