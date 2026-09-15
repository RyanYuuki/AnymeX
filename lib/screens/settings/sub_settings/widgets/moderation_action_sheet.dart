import 'package:anymex/widgets/anymex_widgets/anymex_bottomsheet.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_expansion_tile.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/material.dart';

enum ModerationActionType {
  warn,
  mute,
  ban,
  shadowBan,
  unban,
  unmute,
}

class ModerationDurationOption {
  final String label;
  final int? hours;

  const ModerationDurationOption(this.label, this.hours);
}

class AnymeXModerationActionSheet extends StatefulWidget {
  final String targetUserId;
  final String targetUsername;
  final String? targetAvatar;
  final String? targetClientType;
  final String? targetRole;
  final ModerationActionType initialAction;
  final Future<bool> Function({
    required String action,
    required String reason,
    int? duration,
    bool shadowBan,
  }) onConfirm;

  const AnymeXModerationActionSheet({
    super.key,
    required this.targetUserId,
    required this.targetUsername,
    this.targetAvatar,
    this.targetClientType,
    this.targetRole,
    this.initialAction = ModerationActionType.mute,
    required this.onConfirm,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String targetUserId,
    required String targetUsername,
    String? targetAvatar,
    String? targetClientType,
    String? targetRole,
    ModerationActionType initialAction = ModerationActionType.mute,
    required Future<bool> Function({
      required String action,
      required String reason,
      int? duration,
      bool shadowBan,
    }) onConfirm,
  }) {
    return AnymeXSheet.custom<bool>(
      AnymeXModerationActionSheet(
        targetUserId: targetUserId,
        targetUsername: targetUsername,
        targetAvatar: targetAvatar,
        targetClientType: targetClientType,
        targetRole: targetRole,
        initialAction: initialAction,
        onConfirm: onConfirm,
      ),
      context,
      showDragHandle: true,
    );
  }

  @override
  State<AnymeXModerationActionSheet> createState() =>
      _AnymeXModerationActionSheetState();
}

class _AnymeXModerationActionSheetState
    extends State<AnymeXModerationActionSheet> {
  late ModerationActionType _currentAction;
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _customHoursController = TextEditingController();

  int? _selectedDurationHours = 24; // Default to 24h
  bool _isCustomDuration = false;
  String _customUnit = 'hours'; // 'hours' or 'days'
  bool _isSubmitting = false;

  static const List<ModerationDurationOption> _durationPresets = [
    ModerationDurationOption('1 Hour', 1),
    ModerationDurationOption('12 Hours', 12),
    ModerationDurationOption('1 Day', 24),
    ModerationDurationOption('3 Days', 72),
    ModerationDurationOption('1 Week', 168),
    ModerationDurationOption('1 Month', 720),
    ModerationDurationOption('Permanent', null),
  ];

  static const List<String> _quickReasons = [
    'Spam / Bot',
    'Spoilers',
    'Harassment / Hate',
    'Inappropriate Content',
    'Toxicity',
    'Self-Promotion',
    'Disruptive Behavior',
  ];

  @override
  void initState() {
    super.initState();
    _currentAction = widget.initialAction;
    if (_currentAction == ModerationActionType.ban ||
        _currentAction == ModerationActionType.shadowBan) {
      _selectedDurationHours = null; // Default ban to permanent
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _customHoursController.dispose();
    super.dispose();
  }

  bool get _requiresDuration =>
      _currentAction == ModerationActionType.mute ||
      _currentAction == ModerationActionType.ban ||
      _currentAction == ModerationActionType.shadowBan;

  Color _getActionColor(ColorScheme colorScheme) {
    switch (_currentAction) {
      case ModerationActionType.warn:
        return Colors.amber;
      case ModerationActionType.mute:
        return Colors.orange;
      case ModerationActionType.ban:
        return colorScheme.error;
      case ModerationActionType.shadowBan:
        return Colors.deepPurple;
      case ModerationActionType.unban:
        return Colors.green;
      case ModerationActionType.unmute:
        return Colors.teal;
    }
  }

  String _getActionTitle() {
    switch (_currentAction) {
      case ModerationActionType.warn:
        return 'Warn User';
      case ModerationActionType.mute:
        return 'Mute User';
      case ModerationActionType.ban:
        return 'Ban User';
      case ModerationActionType.shadowBan:
        return 'Shadow Ban User';
      case ModerationActionType.unban:
        return 'Unban User';
      case ModerationActionType.unmute:
        return 'Unmute User';
    }
  }

  String _getActionCode() {
    switch (_currentAction) {
      case ModerationActionType.warn:
        return 'warn_user';
      case ModerationActionType.mute:
        return 'mute_user';
      case ModerationActionType.ban:
      case ModerationActionType.shadowBan:
        return 'ban_user';
      case ModerationActionType.unban:
        return 'unban_user';
      case ModerationActionType.unmute:
        return 'unmute_user';
    }
  }

  int? get _effectiveDurationHours {
    if (!_requiresDuration) return null;
    if (_isCustomDuration) {
      final value = int.tryParse(_customHoursController.text.trim());
      if (value == null || value <= 0) return null;
      return _customUnit == 'days' ? value * 24 : value;
    }
    return _selectedDurationHours;
  }

  String _getExpirationPreview() {
    if (!_requiresDuration) return '';
    final hours = _effectiveDurationHours;
    if (hours == null) {
      return 'Action is Permanent (lasts until manually removed)';
    }

    final expiry = DateTime.now().add(Duration(hours: hours));
    final days = hours ~/ 24;
    final remainingHours = hours % 24;

    String durationText = '';
    if (days > 0) durationText += '$days day${days > 1 ? "s" : ""}';
    if (remainingHours > 0) {
      if (durationText.isNotEmpty) durationText += ' ';
      durationText += '$remainingHours hr${remainingHours > 1 ? "s" : ""}';
    }

    return 'Expires in $durationText on ${expiry.day}/${expiry.month}/${expiry.year} at ${_formatTime(expiry)}';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$min $ampm';
  }

  Future<void> _submit() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty &&
        _currentAction != ModerationActionType.unban &&
        _currentAction != ModerationActionType.unmute) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a reason for this action')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final success = await widget.onConfirm(
        action: _getActionCode(),
        reason: reason.isEmpty ? 'Action performed by moderator' : reason,
        duration: _effectiveDurationHours,
        shadowBan: _currentAction == ModerationActionType.shadowBan,
      );

      if (mounted) {
        Navigator.pop(context, success);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final actionColor = _getActionColor(colorScheme);

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Target User Header Card
          AnymeXCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: colorScheme.surfaceContainer,
                  backgroundImage: widget.targetAvatar != null &&
                          widget.targetAvatar!.isNotEmpty
                      ? NetworkImage(widget.targetAvatar!)
                      : null,
                  child: widget.targetAvatar == null ||
                          widget.targetAvatar!.isEmpty
                      ? Icon(Icons.person,
                          size: 24, color: colorScheme.onSurfaceVariant)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.targetUsername,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.targetClientType != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colorScheme.primary
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                widget.targetClientType!.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'User ID: #${widget.targetUserId}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Action Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: actionColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: actionColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    _getActionTitle(),
                    style: TextStyle(
                      color: actionColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Duration Selector (for Mute, Ban, Shadow Ban)
          if (_requiresDuration) ...[
            Text(
              'Penalty Duration',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._durationPresets.map((preset) {
                  final isSelected = !_isCustomDuration &&
                      _selectedDurationHours == preset.hours;
                  return ChoiceChip(
                    label: Text(preset.label),
                    selected: isSelected,
                    selectedColor: actionColor.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? actionColor : colorScheme.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _isCustomDuration = false;
                          _selectedDurationHours = preset.hours;
                        });
                      }
                    },
                  );
                }),
                ChoiceChip(
                  label: const Text('Custom...'),
                  selected: _isCustomDuration,
                  selectedColor: actionColor.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: _isCustomDuration
                        ? actionColor
                        : colorScheme.onSurface,
                    fontWeight:
                        _isCustomDuration ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _isCustomDuration = true;
                      });
                    }
                  },
                ),
              ],
            ),

            // Custom Duration Input
            if (_isCustomDuration) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customHoursController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Custom Value',
                        hintText: 'Enter amount...',
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'hours', label: Text('Hours')),
                      ButtonSegment(value: 'days', label: Text('Days')),
                    ],
                    selected: {_customUnit},
                    onSelectionChanged: (selection) {
                      setState(() {
                        _customUnit = selection.first;
                      });
                    },
                  ),
                ],
              ),
            ],

            // Real-time Expiration Preview Banner
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: actionColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: actionColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    _effectiveDurationHours == null
                        ? Icons.all_inclusive_rounded
                        : Icons.timer_outlined,
                    size: 16,
                    color: actionColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getExpirationPreview(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: actionColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Quick Reasons
          Text(
            'Reason',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _quickReasons.map((reason) {
                final isCurrent = _reasonController.text.trim() == reason;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    label: Text(reason),
                    avatar: isCurrent
                        ? Icon(Icons.check, size: 14, color: actionColor)
                        : null,
                    backgroundColor: isCurrent
                        ? actionColor.withValues(alpha: 0.15)
                        : null,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: isCurrent ? actionColor : null,
                      fontWeight:
                          isCurrent ? FontWeight.bold : FontWeight.normal,
                    ),
                    onPressed: () {
                      setState(() {
                        _reasonController.text = reason;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _reasonController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Enter reason or details for this action...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: actionColor, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Confirm CTA Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: actionColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: ExpressiveLoadingIndicator(),
                    )
                  : Text(
                      'Confirm ${_getActionTitle()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
