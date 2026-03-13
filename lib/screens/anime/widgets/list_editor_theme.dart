import 'package:anymex/models/Media/media.dart';
import 'package:flutter/material.dart';

typedef ListEditorThemeBuilder = Widget Function(
  BuildContext context,
  ListEditorThemeData data,
);

class ListEditorThemeSpec {
  final String id;
  final String name;
  final String description;
  final ListEditorThemeBuilder builder;

  const ListEditorThemeSpec({
    required this.id,
    required this.name,
    required this.builder,
    this.description = '',
  });
}

class ListEditorStatusOption {
  final String value;
  final String label;
  final IconData icon;

  const ListEditorStatusOption({
    required this.value,
    required this.label,
    required this.icon,
  });
}

class ListEditorThemeData {
  final Media media;
  final bool isManga;
  final String status;
  final double score;
  final int progress;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final bool isPrivate;
  final bool showAdvanced;
  final int? maxTotal;
  final String displayTotal;
  final bool hasKnownTotal;
  final double progressRatio;
  final String statusDisplayText;
  final List<ListEditorStatusOption> statusOptions;
  final TextEditingController progressController;
  final ValueChanged<String> onProgressTextChanged;
  final VoidCallback onProgressTextEditingComplete;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<double> onScoreChanged;
  final ValueChanged<int> onProgressChanged;
  final VoidCallback onIncrementProgress;
  final VoidCallback onDecrementProgress;
  final Future<void> Function({required bool isStart}) onPickDate;
  final VoidCallback onClearStartDate;
  final VoidCallback onClearCompletedDate;
  final ValueChanged<bool> onPrivateChanged;
  final VoidCallback onToggleAdvanced;
  final VoidCallback onSave;
  final VoidCallback onDelete;
  final VoidCallback onClose;
  final String advancedSummary;
  final String Function(DateTime?) formatDate;
  final bool canShowPrivateToggle;

  const ListEditorThemeData({
    required this.media,
    required this.isManga,
    required this.status,
    required this.score,
    required this.progress,
    required this.startedAt,
    required this.completedAt,
    required this.isPrivate,
    required this.showAdvanced,
    required this.maxTotal,
    required this.displayTotal,
    required this.hasKnownTotal,
    required this.progressRatio,
    required this.statusDisplayText,
    required this.statusOptions,
    required this.progressController,
    required this.onProgressTextChanged,
    required this.onProgressTextEditingComplete,
    required this.onStatusChanged,
    required this.onScoreChanged,
    required this.onProgressChanged,
    required this.onIncrementProgress,
    required this.onDecrementProgress,
    required this.onPickDate,
    required this.onClearStartDate,
    required this.onClearCompletedDate,
    required this.onPrivateChanged,
    required this.onToggleAdvanced,
    required this.onSave,
    required this.onDelete,
    required this.onClose,
    required this.advancedSummary,
    required this.formatDate,
    required this.canShowPrivateToggle,
  });
}