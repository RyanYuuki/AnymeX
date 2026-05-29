import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/episodes_pane.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_symbols_icons/symbols.dart';

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
          child: _SpeedPopupContent(
            controller: controller,
            onClose: _closePane,
          ),
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
    2.0
  ];

  late List<double> _speedChips;
  late double _currentSpeed;

  @override
  void initState() {
    super.initState();
    _currentSpeed = widget.controller.playbackSpeed.value;
    _speedChips = List<double>.from(_defaultSpeeds);
    _currentSpeed = _currentSpeed.clamp(_speedChips.first, _speedChips.last);
  }

  double get _min => _speedChips.first;
  double get _max => _speedChips.last;

  void _setSpeed(double v) {
    setState(() => _currentSpeed = v);
    widget.controller.setRate(v);
  }

  void _removeChip(double speed) {
    if (_speedChips.length <= 1) return;
    setState(() {
      _speedChips.remove(speed);
      _currentSpeed = _currentSpeed.clamp(_min, _max);
    });
    widget.controller.setRate(_currentSpeed);
  }

  void _addChip() async {
    double? newSpeed = await _showAddSpeedDialog();
    if (newSpeed == null) return;
    if (_speedChips.contains(newSpeed)) return;
    setState(() {
      _speedChips.add(newSpeed);
      _speedChips.sort();
    });
  }

  Future<double?> _showAddSpeedDialog() async {
    double value = 2.5;
    return showDialog<double>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSt) {
          return AlertDialog(
            title: const Text('Add Speed'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${value.toStringAsFixed(2)}x',
                    style: ctx.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Slider(
                  min: 0.05,
                  max: 20.0,
                  divisions: 399,
                  year2023: false,
                  value: value,
                  onChanged: (v) => setSt(() => value = v),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx, value),
                  child: const Text('Add')),
            ],
          );
        });
      },
    );
  }

  void _restoreChips() {
    setState(() {
      _speedChips = List<double>.from(_defaultSpeeds);
      _currentSpeed = _currentSpeed.clamp(_min, _max);
    });
    widget.controller.setRate(_currentSpeed);
  }

  void _restoreSpeed() {
    _setSpeed(1.0);
  }

  String _fmt(double v) {
    if (v == 1.0) return '1×';
    final s = v.toStringAsFixed(2);
    return '${s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')}×';
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final cs = theme.colorScheme;
    final sliderVal = _currentSpeed.clamp(_min, _max);

    return Column(
      children: [
        _buildHeader(cs, theme),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSpeedDisplay(cs, theme),
                const SizedBox(height: 20),
                _buildSlider(cs, theme, sliderVal),
                const SizedBox(height: 8),
                _buildSliderLabels(cs, theme),
                const SizedBox(height: 24),
                _buildPresetsHeader(cs, theme),
                const SizedBox(height: 12),
                _buildSpeedChips(cs, theme),
                const SizedBox(height: 20),
                _buildMakeDefaultButton(cs, theme),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ColorScheme cs, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(color: cs.outline.withOpacity(0.15)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Symbols.speed_rounded, color: cs.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Playback Speed',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: widget.onClose,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.close,
                  size: 20, color: cs.onSurface.withOpacity(0.7)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedDisplay(ColorScheme cs, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Speed',
                style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.5), letterSpacing: 0.8)),
            const SizedBox(height: 2),
            Text(
              _fmt(_currentSpeed),
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.primary,
                height: 1,
              ),
            ),
          ],
        ),
        _ActionChip(
          label: 'Reset to 1×',
          icon: Icons.replay_rounded,
          onTap: _restoreSpeed,
          color: cs.secondary,
        ),
      ],
    );
  }

  Widget _buildSlider(ColorScheme cs, ThemeData theme, double sliderVal) {
    return Row(
      children: [
        Text(_fmt(_min),
            style: theme.textTheme.labelSmall
                ?.copyWith(color: cs.onSurface.withOpacity(0.45))),
        Expanded(
          child: Slider(
            min: _min,
            max: _max,
            value: sliderVal,
            year2023: false,
            onChanged: (v) {
              final snapped = (v * 20).round() / 20;
              _setSpeed(snapped);
            },
          ),
        ),
        Text(_fmt(_max),
            style: theme.textTheme.labelSmall
                ?.copyWith(color: cs.onSurface.withOpacity(0.45))),
      ],
    );
  }

  Widget _buildSliderLabels(ColorScheme cs, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Slow',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: cs.onSurface.withOpacity(0.4))),
        Text('Fast',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: cs.onSurface.withOpacity(0.4))),
      ],
    );
  }

  Widget _buildPresetsHeader(ColorScheme cs, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Text('Speed Presets',
              style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withOpacity(0.7))),
        ),
        _ActionChip(
          label: 'Restore',
          icon: Icons.settings_backup_restore_rounded,
          onTap: _restoreChips,
          color: cs.tertiary,
        ),
        const SizedBox(width: 8),
        _ActionChip(
          label: 'Add',
          icon: Icons.add_rounded,
          onTap: _addChip,
          color: cs.primary,
        ),
      ],
    );
  }

  Widget _buildSpeedChips(ColorScheme cs, ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _speedChips.map((speed) {
        final isActive = (speed - _currentSpeed).abs() < 0.001;
        final isLast = _speedChips.length == 1;
        return _SpeedChip(
          label: _fmt(speed),
          isActive: isActive,
          canDelete: !isLast,
          onTap: () => _setSpeed(speed),
          onDelete: () => _removeChip(speed),
        );
      }).toList(),
    );
  }

  Widget _buildMakeDefaultButton(ColorScheme cs, ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          _setSpeed(widget.controller.settings.speed);
        },
        icon: const Icon(Icons.star_outline_rounded, size: 18),
        label: const Text('Make Default Speed'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide(color: cs.outline.withOpacity(0.3)),
        ),
      ),
    );
  }
}

class _SpeedChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool canDelete;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SpeedChip({
    required this.label,
    required this.isActive,
    required this.canDelete,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.only(
            left: 12, right: canDelete ? 4 : 12, top: 6, bottom: 6),
        decoration: BoxDecoration(
          color: isActive
              ? cs.primary
              : cs.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border:
              isActive ? null : Border.all(color: cs.outline.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: context.theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isActive ? cs.onPrimary : cs.onSurface,
              ),
            ),
            if (canDelete) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onDelete,
                child: Icon(Icons.close_rounded,
                    size: 14,
                    color: isActive
                        ? cs.onPrimary.withOpacity(0.7)
                        : cs.onSurface.withOpacity(0.5)),
              ),
              const SizedBox(width: 4),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: context.theme.textTheme.labelSmall
                    ?.copyWith(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
