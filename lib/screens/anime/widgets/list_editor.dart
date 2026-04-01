import 'dart:async';

import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/widgets/list_editor_theme.dart';
import 'package:anymex/screens/anime/widgets/list_editor_theme_registry.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ListEditorModal extends StatefulWidget {
  final RxString animeStatus;
  final RxDouble animeScore;
  final RxInt animeProgress;
  final Rx<dynamic> currentAnime;
  final Media media;
  final Function(String, double, String, int, DateTime?, DateTime?, bool?)
      onUpdate;
  final Function(String) onDelete;
  final bool isManga;

  const ListEditorModal({
    super.key,
    required this.animeStatus,
    required this.animeScore,
    required this.animeProgress,
    required this.currentAnime,
    required this.media,
    required this.onUpdate,
    required this.onDelete,
    required this.isManga,
  });

  @override
  State<ListEditorModal> createState() => _ListEditorModalState();
}

class _ListEditorModalState extends State<ListEditorModal> {
  final Settings _settings = Get.find<Settings>();
  late TextEditingController _progressController;

  late String _localStatus;
  late double _localScore;
  late int _localProgress;
  DateTime? _startedAt;
  DateTime? _completedAt;
  bool _isPrivate = false;
  bool _showAdvanced = false;

  @override
  void initState() {
    super.initState();

    _localStatus =
        widget.animeStatus.value.isEmpty ? 'CURRENT' : widget.animeStatus.value;
    _localScore = widget.animeScore.value;
    _localProgress = widget.animeProgress.value;

    final tracked = widget.currentAnime.value;
    if (tracked != null) {
      _startedAt = tracked.startedAt;
      _completedAt = tracked.completedAt;
      _isPrivate = tracked.isPrivate ?? false;
    }

    _showAdvanced = false;

    _progressController = TextEditingController(
      text: _localProgress.toString(),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  List<ListEditorStatusOption> get _statusOptions => [
        const ListEditorStatusOption(
          value: 'PLANNING',
          label: 'Planning',
          icon: Icons.schedule_rounded,
        ),
        ListEditorStatusOption(
          value: 'CURRENT',
          label: widget.isManga ? 'Reading' : 'Watching',
          icon: Icons.play_circle_rounded,
        ),
        const ListEditorStatusOption(
          value: 'COMPLETED',
          label: 'Completed',
          icon: Icons.check_circle_rounded,
        ),
        const ListEditorStatusOption(
          value: 'REPEATING',
          label: 'Repeating',
          icon: Icons.repeat_rounded,
        ),
        const ListEditorStatusOption(
          value: 'PAUSED',
          label: 'Paused',
          icon: Icons.pause_circle_rounded,
        ),
        const ListEditorStatusOption(
          value: 'DROPPED',
          label: 'Dropped',
          icon: Icons.cancel_rounded,
        ),
      ];

  String _getStatusDisplayText(String status) {
    switch (status) {
      case 'PLANNING':
        return 'Planning';
      case 'CURRENT':
        return widget.isManga ? 'Reading' : 'Watching';
      case 'COMPLETED':
        return 'Completed';
      case 'REPEATING':
        return 'Repeating';
      case 'PAUSED':
        return 'Paused';
      case 'DROPPED':
        return 'Dropped';
      default:
        return status;
    }
  }

  bool _isUnknownTotal() {
    final String? total = widget.isManga
        ? widget.media.totalChapters
        : widget.media.totalEpisodes;
    return total == null || total.isEmpty || total == '?' || total == '??';
  }

  int? _getMaxTotal() {
    if (_isUnknownTotal()) return null;
    final String? total = widget.isManga
        ? widget.media.totalChapters
        : widget.media.totalEpisodes;
    return int.tryParse(total ?? '');
  }

  String _getDisplayTotal() {
    if (widget.isManga) {
      return widget.media.totalChapters ?? '??';
    }
    return widget.media.totalEpisodes;
  }

  int _clampProgress(int value) {
    final int normalized = value < 0 ? 0 : value;
    final int? maxTotal = _getMaxTotal();
    if (maxTotal != null && normalized > maxTotal) {
      return maxTotal;
    }
    return normalized;
  }

  void _setProgress(int value) {
    final int clamped = _clampProgress(value);
    setState(() {
      _localProgress = clamped;
      if (_progressController.text != clamped.toString()) {
        _progressController.text = clamped.toString();
        _progressController.selection = TextSelection.fromPosition(
          TextPosition(offset: _progressController.text.length),
        );
      }
    });
  }

  void _incrementProgress() {
    final int? maxTotal = _getMaxTotal();
    if (maxTotal != null && _localProgress >= maxTotal) return;
    _setProgress(_localProgress + 1);
  }

  void _decrementProgress() {
    if (_localProgress <= 0) return;
    _setProgress(_localProgress - 1);
  }

  void _handleProgressTextChanged(String value) {
    final int? parsed = int.tryParse(value);

    if (parsed == null || parsed < 0) {
      return;
    }

    final int clamped = _clampProgress(parsed);

    if (clamped != parsed) {
      _progressController.text = clamped.toString();
      _progressController.selection = TextSelection.fromPosition(
        TextPosition(offset: _progressController.text.length),
      );
    }

    setState(() {
      _localProgress = clamped;
    });
  }

  void _syncProgressText() {
    setState(() {
      _progressController.text = _localProgress.toString();
    });
  }

  void _setStatus(String value) {
    setState(() {
      final prev = _localStatus;
      _localStatus = value;
      if (_localStatus == 'CURRENT' && _startedAt == null) {
        _startedAt = DateTime.now();
      }
      if (_localStatus == 'COMPLETED' && _completedAt == null) {
        _completedAt = DateTime.now();
        _startedAt ??= DateTime.now();
      }
      if (prev == 'COMPLETED' && _localStatus != 'COMPLETED') {
        _completedAt = null;
      }
    });
  }

  void _setScore(double value) {
    setState(() {
      _localScore = value;
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not set';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _pickDate(BuildContext context, {required bool isStart}) async {
    final initial = isStart
        ? (_startedAt ?? DateTime.now())
        : (_completedAt ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: context.colors),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startedAt = picked;
        } else {
          _completedAt = picked;
        }
      });
    }
  }

  void _handleSave() {
    widget.animeStatus.value = _localStatus;
    widget.animeScore.value = _localScore;
    widget.animeProgress.value = _localProgress;
    Get.back();
    widget.onUpdate(
      widget.media.id,
      _localScore,
      _localStatus,
      _localProgress,
      _startedAt,
      _completedAt,
      widget.media.serviceType.isAL ? _isPrivate : null,
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) => _DeleteConfirmDialog(
        title: 'Delete entry?',
        message: 'This will remove it from your list.',
        onConfirm: () {
          Navigator.of(dialogContext).pop();
          widget.animeStatus.value = '';
          widget.animeScore.value = 0.0;
          widget.animeProgress.value = 0;
          Get.back();
          widget.onDelete(widget.media.id);
        },
      ),
    );
  }

  String _getAdvancedSummary() {
    final List<String> parts = [];

    if (_startedAt != null || _completedAt != null) {
      final List<String> dateParts = [];
      if (_startedAt != null) dateParts.add('Start');
      if (_completedAt != null) dateParts.add('Finish');
      parts.add(dateParts.join(' & '));
    }

    if (widget.media.serviceType.isAL && _isPrivate) {
      parts.add('Private');
    }

    return parts.join(' / ');
  }

  ListEditorThemeData _buildThemeData() {
    final int? maxTotal = _getMaxTotal();
    final bool hasKnownTotal = maxTotal != null && maxTotal > 0;
    final double progressRatio =
        hasKnownTotal ? (_localProgress / maxTotal!).clamp(0.0, 1.0) : 0.0;

    return ListEditorThemeData(
      media: widget.media,
      isManga: widget.isManga,
      status: _localStatus,
      score: _localScore,
      progress: _localProgress,
      startedAt: _startedAt,
      completedAt: _completedAt,
      isPrivate: _isPrivate,
      showAdvanced: _showAdvanced,
      maxTotal: maxTotal,
      displayTotal: _getDisplayTotal(),
      hasKnownTotal: hasKnownTotal,
      progressRatio: progressRatio,
      statusDisplayText: _getStatusDisplayText(_localStatus),
      statusOptions: _statusOptions,
      progressController: _progressController,
      onProgressTextChanged: _handleProgressTextChanged,
      onProgressTextEditingComplete: _syncProgressText,
      onStatusChanged: _setStatus,
      onScoreChanged: _setScore,
      onProgressChanged: _setProgress,
      onIncrementProgress: _incrementProgress,
      onDecrementProgress: _decrementProgress,
      onPickDate: ({required bool isStart}) =>
          _pickDate(context, isStart: isStart),
      onClearStartDate: () => setState(() => _startedAt = null),
      onClearCompletedDate: () => setState(() => _completedAt = null),
      onPrivateChanged: (value) => setState(() => _isPrivate = value),
      onToggleAdvanced: () => setState(() => _showAdvanced = !_showAdvanced),
      onSave: _handleSave,
      onDelete: _showDeleteConfirmation,
      onClose: () => Get.back(),
      advancedSummary: _getAdvancedSummary(),
      formatDate: _formatDate,
      canShowPrivateToggle: widget.media.serviceType.isAL,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final theme = ListEditorThemeRegistry.byId(_settings.listEditorTheme);
      return theme.builder(context, _buildThemeData());
    });
  }
}

class _DeleteConfirmDialog extends StatefulWidget {
  final String title;
  final String message;
  final VoidCallback onConfirm;

  const _DeleteConfirmDialog({
    required this.title,
    required this.message,
    required this.onConfirm,
  });

  @override
  State<_DeleteConfirmDialog> createState() => _DeleteConfirmDialogState();
}

class _DeleteConfirmDialogState extends State<_DeleteConfirmDialog> {
  static const int _waitSeconds = 3;
  late int _secondsLeft;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _secondsLeft = _waitSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft <= 0) {
        timer.cancel();
        return;
      }
      setState(() {
        _secondsLeft--;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = context.colors;
    final bool canConfirm = _secondsLeft <= 0;

    return AlertDialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(
        widget.title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
      content: Text(
        widget.message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ),
        FilledButton(
          onPressed: canConfirm ? widget.onConfirm : null,
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
            disabledBackgroundColor:
                colorScheme.error.opaque(0.4, iReallyMeanIt: true),
            disabledForegroundColor:
                colorScheme.onError.opaque(0.7, iReallyMeanIt: true),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            canConfirm ? 'Confirm' : 'Confirm (${_secondsLeft}s)',
          ),
        ),
      ],
    );
  }
}