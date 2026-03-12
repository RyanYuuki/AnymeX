import 'dart:async';

import 'package:anymex/models/Media/media.dart';
import 'package:anymex/widgets/common/slider_semantics.dart';
import 'package:anymex/widgets/custom_widgets/anymex_button.dart';
import 'package:anymex/widgets/custom_widgets/anymex_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:flutter/services.dart';
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
        widget.animeStatus.value.isEmpty ? "CURRENT" : widget.animeStatus.value;
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double gap = 12.0;
        final bool isWide = constraints.maxWidth >= 520;
        final double cardWidth =
            isWide ? (constraints.maxWidth - gap) / 2 : constraints.maxWidth;

        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
              top: 12.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 12),
                Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: _buildStatusSection(context),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _buildScoreSection(context),
                    ),
                    SizedBox(
                      width: constraints.maxWidth,
                      child: _buildProgressSection(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildAdvancedSection(context),
                const SizedBox(height: 16),
                _buildActionButtons(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = context.colors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit ${widget.isManga ? 'Manga' : 'Anime'}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
            ),
          ],
        ),
        Row(
          children: [
            _buildHeaderIconButton(
              context,
              icon: Icons.delete_outline_rounded,
              color: colorScheme.error,
              onTap: _showDeleteConfirmation,
            ),
            const SizedBox(width: 8),
            _buildHeaderIconButton(
              context,
              icon: Icons.close_rounded,
              color: colorScheme.onSurfaceVariant,
              onTap: () => Get.back(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderIconButton(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final colorScheme = context.colors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.opaque(0.25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.opaque(0.2),
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 19,
            color: color,
          ),
        ),
      ),
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
          Get.back();
          widget.onDelete(widget.media.id);
        },
      ),
    );
  }

  Widget _buildStatusSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnymexDropdown(
          label: 'Status',
          icon: Icons.info_rounded,
          compact: true,
          onChanged: (e) {
            setState(() {
              final prev = _localStatus;
              _localStatus = e.value;
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
          },
          selectedItem: DropdownItem(
            value: _localStatus,
            text: _getStatusDisplayText(_localStatus),
          ),
          items: [
            ('PLANNING', 'Planning', Icons.schedule_rounded),
            (
              'CURRENT',
              widget.isManga ? 'Reading' : 'Watching',
              Icons.play_circle_rounded
            ),
            ('COMPLETED', 'Completed', Icons.check_circle_rounded),
            ('REPEATING', 'Repeating', Icons.repeat_rounded),
            ('PAUSED', 'Paused', Icons.pause_circle_rounded),
            ('DROPPED', 'Dropped', Icons.cancel_rounded),
          ].map((item) {
            return DropdownItem(
              value: item.$1,
              text: item.$2,
            );
          }).toList(),
        ),
      ],
    );
  }

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

  Widget _buildProgressSection(BuildContext context) {
    final colorScheme = context.colors;
    final bool isForManga = widget.isManga;

    bool isUnknownTotal() {
      final String? total =
          isForManga ? widget.media.totalChapters : widget.media.totalEpisodes;
      return total == '?' || total == '??' || total == null || total.isEmpty;
    }

    int? getMaxTotal() {
      if (isUnknownTotal()) return null;
      final String total =
          isForManga ? widget.media.totalChapters! : widget.media.totalEpisodes;
      return int.tryParse(total);
    }

    final int? maxTotal = getMaxTotal();
    final bool hasKnownLimit = maxTotal != null;

    String getDisplayTotal() {
      if (isForManga) {
        return widget.media.totalChapters ?? '??';
      }
      return widget.media.totalEpisodes;
    }

    return _buildSectionCard(
      context,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isForManga
                    ? Icons.menu_book_rounded
                    : Icons.play_circle_rounded,
                color: colorScheme.primary,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Progress',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              Text(
                '$_localProgress / ${getDisplayTotal()}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDecrementButton(context),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextFormField(
                    controller: _progressController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    style: Theme.of(context).textTheme.bodyLarge,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colorScheme.outline.opaque(0.4),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colorScheme.outline.opaque(0.4),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      hintText:
                          isForManga ? 'Chapters read' : 'Episodes watched',
                      hintStyle: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                    ),
                    onChanged: (String value) {
                      final int? parsed = int.tryParse(value);

                      if (parsed == null || parsed < 0) {
                        return;
                      }

                      final int clamped = hasKnownLimit && parsed > maxTotal
                          ? maxTotal
                          : parsed;

                      if (clamped != parsed) {
                        _progressController.text = clamped.toString();
                        _progressController.selection =
                            TextSelection.fromPosition(
                          TextPosition(offset: _progressController.text.length),
                        );
                      }

                      setState(() {
                        _localProgress = clamped;
                      });
                    },
                    onEditingComplete: () {
                      setState(() {
                        _progressController.text = _localProgress.toString();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildIncrementButton(context, hasKnownLimit, maxTotal),
            ],
          ),
          if (hasKnownLimit) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_localProgress / maxTotal).clamp(0.0, 1.0),
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                minHeight: 3,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDecrementButton(BuildContext context) {
    final colorScheme = context.colors;
    final bool canDecrement = _localProgress > 0;

    return Material(
      color: canDecrement
          ? colorScheme.secondaryContainer
          : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: canDecrement
            ? () {
                setState(() {
                  _localProgress--;
                  _progressController.text = _localProgress.toString();
                });
              }
            : null,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Icon(
            Icons.remove_rounded,
            color: canDecrement
                ? colorScheme.onSecondaryContainer
                : colorScheme.onSurfaceVariant.opaque(0.5),
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildIncrementButton(
      BuildContext context, bool hasKnownLimit, int? maxTotal) {
    final colorScheme = context.colors;
    final bool canIncrement =
        !hasKnownLimit || (hasKnownLimit && _localProgress < maxTotal!);

    return Material(
      color: canIncrement
          ? colorScheme.primary
          : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: canIncrement
            ? () {
                setState(() {
                  _localProgress++;
                  _progressController.text = _localProgress.toString();
                });
              }
            : null,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Icon(
            Icons.add_rounded,
            color: canIncrement
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant.opaque(0.5),
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildScoreSection(BuildContext context) {
    final colorScheme = context.colors;

    return _buildSectionCard(
      context,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.star_rounded,
                color: colorScheme.primary,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Score',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _localScore.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              showValueIndicator: ShowValueIndicator.never,
            ),
            child: CustomSlider(
              value: _localScore,
              min: 0.0,
              max: 10.0,
              divisions: 100,
              label: _localScore.toStringAsFixed(1),
              activeColor: colorScheme.primary,
              inactiveColor: colorScheme.surfaceContainerHighest,
              onChanged: (double newValue) {
                setState(() {
                  _localScore = newValue;
                });
              },
            ),
          ),
        ],
      ),
    );
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

  Widget _buildDateSection(BuildContext context) {
    final colorScheme = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionCard(
          context,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.event_rounded,
                    color: colorScheme.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Dates',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildDateTile(
                      context,
                      label: 'Start',
                      icon: Icons.play_circle_outline_rounded,
                      date: _startedAt,
                      onTap: () => _pickDate(context, isStart: true),
                      onClear: _startedAt != null
                          ? () => setState(() => _startedAt = null)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildDateTile(
                      context,
                      label: 'Finish',
                      icon: Icons.check_circle_outline_rounded,
                      date: _completedAt,
                      onTap: () => _pickDate(context, isStart: false),
                      onClear: _completedAt != null
                          ? () => setState(() => _completedAt = null)
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateTile(
    BuildContext context, {
    required String label,
    required IconData icon,
    required DateTime? date,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    final colorScheme = context.colors;
    final bool hasDate = date != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: hasDate
              ? colorScheme.primaryContainer.opaque(0.5)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasDate
                ? colorScheme.primary.opaque(0.4)
                : colorScheme.outline.opaque(0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon,
                    size: 11,
                    color: hasDate
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: hasDate
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                if (onClear != null)
                  GestureDetector(
                    onTap: onClear,
                    child: Icon(Icons.close_rounded,
                        size: 11, color: colorScheme.onSurfaceVariant),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              _formatDate(date),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: hasDate
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant.opaque(0.6),
                    fontWeight: hasDate ? FontWeight.w500 : FontWeight.normal,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivateSection(BuildContext context) {
    final colorScheme = context.colors;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: colorScheme.surfaceContainerHighest.opaque(0.25),
        border: Border.all(
          color: _isPrivate
              ? colorScheme.primary.opaque(0.5)
              : colorScheme.outline.opaque(0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: _isPrivate
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _isPrivate ? Icons.lock_rounded : Icons.lock_open_rounded,
              size: 14,
              color: _isPrivate
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Private Entry',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isPrivate,
            onChanged: (val) => setState(() => _isPrivate = val),
            activeColor: colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final colorScheme = context.colors;

    return SizedBox(
      height: 44,
      width: double.infinity,
      child: AnymexButton(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
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
        },
        color: colorScheme.primary,
        border: BorderSide.none,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.save_rounded,
              color: colorScheme.onPrimary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Save',
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required Widget child,
    EdgeInsets? padding,
    Color? backgroundColor,
    Color? borderColor,
  }) {
    final colorScheme = context.colors;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: backgroundColor ?? colorScheme.surfaceContainer.opaque(0.25),
        border: Border.all(
          color: borderColor ?? colorScheme.outline.opaque(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.opaque(0.08, iReallyMeanIt: true),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: padding ?? const EdgeInsets.all(12),
      child: child,
    );
  }

  Widget _buildAdvancedSection(BuildContext context) {
    final colorScheme = context.colors;
    final String summary = _getAdvancedSummary();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() => _showAdvanced = !_showAdvanced),
          child: _buildSectionCard(
            context,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Icon(
                  Icons.tune_rounded,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Advanced',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                if (summary.isNotEmpty) ...[
                  Text(
                    summary,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(width: 8),
                ],
                AnimatedRotation(
                  turns: _showAdvanced ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.expand_more_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            children: [
              const SizedBox(height: 8),
              _buildDateSection(context),
              if (widget.media.serviceType.isAL) ...[
                const SizedBox(height: 8),
                _buildPrivateSection(context),
              ],
            ],
          ),
          crossFadeState: _showAdvanced
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
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
