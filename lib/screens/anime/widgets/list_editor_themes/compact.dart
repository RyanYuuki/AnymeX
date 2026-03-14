import 'package:anymex/screens/anime/widgets/list_editor_theme.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/slider_semantics.dart';
import 'package:anymex/widgets/custom_widgets/anymex_button.dart';
import 'package:anymex/widgets/custom_widgets/anymex_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final ListEditorThemeSpec compactListEditorTheme = ListEditorThemeSpec(
  id: 'compact',
  name: 'Compact',
  description: 'Dense layout with quick access to status, score, and advanced.',
  builder: (context, data) => _CompactListEditorTheme(data: data),
);

class _CompactListEditorTheme extends StatelessWidget {
  final ListEditorThemeData data;

  const _CompactListEditorTheme({required this.data});

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
        Text(
          'Edit ${data.isManga ? 'Manga' : 'Anime'}',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
        ),
        Row(
          children: [
            _buildHeaderIconButton(
              context,
              icon: Icons.delete_outline_rounded,
              color: colorScheme.error,
              onTap: data.onDelete,
            ),
            const SizedBox(width: 8),
            _buildHeaderIconButton(
              context,
              icon: Icons.close_rounded,
              color: colorScheme.onSurfaceVariant,
              onTap: data.onClose,
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

  Widget _buildStatusSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnymexDropdown(
          label: 'Status',
          icon: Icons.info_rounded,
          compact: true,
          onChanged: (e) => data.onStatusChanged(e.value),
          selectedItem: DropdownItem(
            value: data.status,
            text: data.statusDisplayText,
          ),
          items: data.statusOptions
              .map((option) => DropdownItem(
                    value: option.value,
                    text: option.label,
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    final colorScheme = context.colors;

    return _buildSectionCard(
      context,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                data.isManga
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
                '${data.progress} / ${data.displayTotal}',
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
                    controller: data.progressController,
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
                          data.isManga ? 'Chapters read' : 'Episodes watched',
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
                    onChanged: data.onProgressTextChanged,
                    onEditingComplete: data.onProgressTextEditingComplete,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildIncrementButton(context),
            ],
          ),
          if (data.hasKnownTotal) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: data.progressRatio,
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
    final bool canDecrement = data.progress > 0;

    return Material(
      color: canDecrement
          ? colorScheme.secondaryContainer
          : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: canDecrement ? data.onDecrementProgress : null,
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

  Widget _buildIncrementButton(BuildContext context) {
    final colorScheme = context.colors;
    final bool canIncrement =
        !data.hasKnownTotal || data.progress < (data.maxTotal ?? 0);

    return Material(
      color: canIncrement
          ? colorScheme.primary
          : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: canIncrement ? data.onIncrementProgress : null,
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
                  data.score.toStringAsFixed(1),
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
              value: data.score,
              min: 0.0,
              max: 10.0,
              divisions: 100,
              label: data.score.toStringAsFixed(1),
              activeColor: colorScheme.primary,
              inactiveColor: colorScheme.surfaceContainerHighest,
              onChanged: data.onScoreChanged,
            ),
          ),
        ],
      ),
    );
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
                      date: data.startedAt,
                      onTap: () => data.onPickDate(isStart: true),
                      onClear:
                          data.startedAt != null ? data.onClearStartDate : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildDateTile(
                      context,
                      label: 'Finish',
                      icon: Icons.check_circle_outline_rounded,
                      date: data.completedAt,
                      onTap: () => data.onPickDate(isStart: false),
                      onClear: data.completedAt != null
                          ? data.onClearCompletedDate
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
              data.formatDate(date),
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
          color: data.isPrivate
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
              color: data.isPrivate
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              data.isPrivate ? Icons.lock_rounded : Icons.lock_open_rounded,
              size: 14,
              color: data.isPrivate
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
            value: data.isPrivate,
            onChanged: data.onPrivateChanged,
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
        onTap: data.onSave,
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
    final String summary = data.advancedSummary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: data.onToggleAdvanced,
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
                  turns: data.showAdvanced ? 0.5 : 0.0,
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
              if (data.canShowPrivateToggle) ...[
                const SizedBox(height: 8),
                _buildPrivateSection(context),
              ],
            ],
          ),
          crossFadeState: data.showAdvanced
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}