import 'dart:math' as math;

import 'package:anymex/screens/anime/widgets/list_editor_theme.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/custom_widgets/anymex_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final ListEditorThemeSpec violetNebulaListEditorTheme = ListEditorThemeSpec(
  id: 'violet_nebula',
  name: 'Violet Nebula',
  description: 'Ring progress, bold scoring, and split actions.',
  builder: (context, data) => _VioletNebulaListEditorTheme(data: data),
);

class _VioletNebulaListEditorTheme extends StatefulWidget {
  final ListEditorThemeData data;

  const _VioletNebulaListEditorTheme({required this.data});

  @override
  State<_VioletNebulaListEditorTheme> createState() => _VioletNebulaListEditorThemeState();
}

class _VioletNebulaListEditorThemeState extends State<_VioletNebulaListEditorTheme> {
  double _fromProgress = 0.0;
  double _toProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _fromProgress = widget.data.progressRatio;
    _toProgress = widget.data.progressRatio;
  }

  @override
  void didUpdateWidget(covariant _VioletNebulaListEditorTheme oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data.progressRatio != _toProgress) {
      _fromProgress = _toProgress;
      _toProgress = widget.data.progressRatio;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        child: ColoredBox(
          color: context.colors.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              _buildBody(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = context.colors;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.opaque(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit ${widget.data.isManga ? 'Manga' : 'Anime'}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Update your progress and rating',
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: widget.data.onClose,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.surfaceContainerHighest,
              ),
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('Status'),
          const SizedBox(height: 8),
          _buildStatusDropdown(context),
          const SizedBox(height: 12),
          _buildEpisodeSection(context),
          const SizedBox(height: 12),
          _buildScoreCard(context),
          const SizedBox(height: 12),
          _buildDatesRow(context),
          const SizedBox(height: 12),
          if (widget.data.canShowPrivateToggle) ...[
            _buildPrivateToggle(context),
            const SizedBox(height: 12),
          ],
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: context.colors.onSurfaceVariant.opaque(0.6),
      ),
    );
  }

  Widget _buildStatusDropdown(BuildContext context) {
    final colorScheme = context.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.opaque(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.opaque(0.2),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: widget.data.status,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: colorScheme.primary,
            size: 20,
          ),
          dropdownColor: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
          items: widget.data.statusOptions
              .map((option) => DropdownMenuItem<String>(
                    value: option.value,
                    child: Text(option.label),
                  ))
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            widget.data.onStatusChanged(value);
          },
        ),
      ),
    );
  }

  Widget _buildEpisodeSection(BuildContext context) {
    final colorScheme = context.colors;
    final bool hasKnownLimit = widget.data.hasKnownTotal;
    final int? maxTotal = widget.data.maxTotal;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.opaque(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.opaque(0.1),
        ),
      ),
      child: Row(
        children: [
          _buildRingProgress(context),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.data.isManga ? 'Chapters Read' : 'Episodes Watched',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: colorScheme.onSurfaceVariant.opaque(0.5),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: widget.data.progress > 0
                            ? () {
                                widget.data.onDecrementProgress();
                                HapticFeedback.lightImpact();
                              }
                            : null,
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color:
                                colorScheme.surfaceContainerHighest.opaque(0.5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: colorScheme.outline.opaque(0.15),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '−',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w400,
                                color: widget.data.progress > 0
                                    ? colorScheme.onSurface.opaque(0.6)
                                    : colorScheme.onSurface.opaque(0.25),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: (hasKnownLimit &&
                                maxTotal != null &&
                                widget.data.progress >= maxTotal)
                            ? null
                            : () {
                                widget.data.onIncrementProgress();
                                HapticFeedback.lightImpact();
                              },
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                colorScheme.primary,
                                colorScheme.primary.opaque(0.85),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.opaque(0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '+',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  widget.data.isManga
                      ? '${widget.data.progress} read · ${widget.data.displayTotal} total'
                      : '${widget.data.progress} watched · ${widget.data.displayTotal} total',
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant.opaque(0.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRingProgress(BuildContext context) {
    final colorScheme = context.colors;
    const size = 55.0;
    const strokeWidth = 5.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(size, size),
            painter: _RingPainter(
              color: colorScheme.outline.opaque(0.12),
              strokeWidth: strokeWidth,
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: _fromProgress, end: _toProgress),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return CustomPaint(
                size: const Size(size, size),
                painter: _ProgressRingPainter(
                  progress: value,
                  color: colorScheme.primary,
                  strokeWidth: strokeWidth,
                ),
              );
            },
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${widget.data.progress}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                  height: 1,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                widget.data.isManga ? 'CH' : 'EPS',
                style: TextStyle(
                  fontSize: 7,
                  letterSpacing: 0.5,
                  color: colorScheme.onSurfaceVariant.opaque(0.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(BuildContext context) {
    final colorScheme = context.colors;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.opaque(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.opaque(0.1),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    widget.data.score.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                      height: 1,
                    ),
                  ),
                  Text(
                    ' / 10',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant.opaque(0.4),
                    ),
                  ),
                ],
              ),
              Row(
                children: List.generate(5, (index) {
                  final starValue = (index + 1) * 2;
                  final isFilled = widget.data.score >= starValue;
                  return GestureDetector(
                    onTap: () {
                      widget.data.onScoreChanged(starValue.toDouble());
                      HapticFeedback.selectionClick();
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(left: 3),
                      child: Text(
                        '★',
                        style: TextStyle(
                          fontSize: 14,
                          color: isFilled
                              ? colorScheme.primary
                              : colorScheme.outline.opaque(0.15),
                          shadows: isFilled
                              ? [
                                  Shadow(
                                    color: colorScheme.primary.opaque(0.5),
                                    blurRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: widget.data.score,
              min: 0,
              max: 10,
              divisions: 100,
              activeColor: colorScheme.primary,
              inactiveColor: colorScheme.surfaceContainerHighest,
              onChanged: widget.data.onScoreChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatesRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildDateInput(
            context,
            label: 'Start',
            date: widget.data.startedAt,
            onTap: () => widget.data.onPickDate(isStart: true),
            onClear: widget.data.startedAt != null
                ? widget.data.onClearStartDate
                : null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildDateInput(
            context,
            label: 'Finish',
            date: widget.data.completedAt,
            onTap: () => widget.data.onPickDate(isStart: false),
            onClear: widget.data.completedAt != null
                ? widget.data.onClearCompletedDate
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDateInput(
    BuildContext context, {
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    final colorScheme = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.opaque(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.opaque(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant.opaque(0.5),
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onTap,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    date != null ? widget.data.formatDate(date) : 'Not set',
                    style: TextStyle(
                      fontSize: 12,
                      color: date != null
                          ? colorScheme.onSurface.opaque(0.7)
                          : colorScheme.onSurfaceVariant.opaque(0.4),
                    ),
                  ),
                ),
                if (onClear != null)
                  GestureDetector(
                    onTap: onClear,
                    child: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: colorScheme.onSurfaceVariant.opaque(0.4),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivateToggle(BuildContext context) {
    final colorScheme = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.opaque(0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.data.isPrivate
              ? colorScheme.primary.opaque(0.4)
              : colorScheme.outline.opaque(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: widget.data.isPrivate
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              widget.data.isPrivate
                  ? Icons.lock_rounded
                  : Icons.lock_open_rounded,
              size: 14,
              color: widget.data.isPrivate
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Private Entry',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Hidden from public',
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: widget.data.isPrivate,
            onChanged: (value) {
              widget.data.onPrivateChanged(value);
              HapticFeedback.lightImpact();
            },
            activeColor: colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final colorScheme = context.colors;

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 46,
            child: AnymexButton(
              onTap: widget.data.onDelete,
              color: colorScheme.error,
              border: BorderSide.none,
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(100), right: Radius.circular(10)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.delete_rounded,
                    color: colorScheme.onError,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Delete',
                    style: TextStyle(
                      color: colorScheme.onError,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: SizedBox(
            height: 46,
            child: AnymexButton(
              borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(100), left: Radius.circular(10)),
              onTap: widget.data.onSave,
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
                    'Save Changes',
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _RingPainter({
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _ProgressRingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}