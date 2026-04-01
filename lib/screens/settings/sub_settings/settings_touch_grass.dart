import 'package:anymex/services/touch_grass_service.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:anymex/screens/other_features.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';

enum _ChartPeriod { weekly, monthly }

class SettingsTouchGrass extends StatefulWidget {
  const SettingsTouchGrass({super.key});

  @override
  State<SettingsTouchGrass> createState() => _SettingsTouchGrassState();
}

class _SettingsTouchGrassState extends State<SettingsTouchGrass> {
  final service = Get.find<TouchGrassService>();
  _ChartPeriod _selectedPeriod = _ChartPeriod.weekly;

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Glow(
      child: Scaffold(
        body: Column(
          children: [
            const NestedHeader(title: 'Touch Grass'),
            Expanded(
              child: Padding(
                padding: getResponsiveValue(context,
                    mobileValue: const EdgeInsets.fromLTRB(10, 16, 10, 0),
                    desktopValue: const EdgeInsets.fromLTRB(20, 16, 25, 0)),
                child: Column(
                  children: [
                    // Settings toggles
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: colorScheme.surfaceContainer.opaque(0.3),
                      ),
                      child: Obx(() => Column(
                            children: [
                              CustomSwitchTile(
                                icon: Icons.grass_rounded,
                                title: 'Enable Reminder',
                                description:
                                    'Get a popup reminder after extended viewing',
                                switchValue: service.enabled.value,
                                onChanged: (val) {
                                  service.setEnabled(val);
                                  setState(() {});
                                },
                              ),
                              if (service.enabled.value) ...[
                                const Divider(height: 1),
                                CustomTile(
                                  icon: Icons.timer_outlined,
                                  title: 'Reminder Interval',
                                  description:
                                      'Remind after ${_formatMinutes(service.reminderMinutes.value)}',
                                  onTap: () => _showIntervalPicker(colorScheme),
                                ),
                              ],
                            ],
                          )),
                    ),
                    // Test button
                    Obx(() {
                      if (!service.enabled.value) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: colorScheme.surfaceContainer.opaque(0.3),
                          ),
                          child: CustomTile(
                            icon: Icons.play_arrow_rounded,
                            title: 'Test Reminder',
                            description: 'Preview the popup right now',
                            onTap: () => service.showTestReminder(),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    // Stats bubble
                    Obx(() {
                      if (!service.enabled.value) {
                        return const SizedBox.shrink();
                      }
                      final session = service.currentSessionMinutes;
                      final todaySaved = service.todaySavedMinutes;
                      final total = todaySaved + session;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color:
                                      colorScheme.surfaceContainer.opaque(0.3),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Today',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            colorScheme.onSurface.opaque(0.5),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatMinutes(total),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (session > 0) ...[
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: colorScheme.primaryContainer
                                        .opaque(0.4),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Current Session',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              colorScheme.onSurface.opaque(0.5),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _formatMinutes(session),
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                    // Chart section
                    Expanded(
                      child: Obx(() => _buildChartSection(colorScheme)),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- INTERVAL PICKER ----

  void _showIntervalPicker(ColorScheme colorScheme) {
    int selectedHours = service.reminderMinutes.value ~/ 60;
    int selectedMinutes = (service.reminderMinutes.value % 60);
    selectedMinutes = (selectedMinutes / 5).round() * 5;
    if (selectedMinutes >= 60) {
      selectedMinutes = 0;
      selectedHours = (selectedHours + 1).clamp(0, 24);
    }

    final hoursController =
        FixedExtentScrollController(initialItem: selectedHours);
    final minutesController =
        FixedExtentScrollController(initialItem: selectedMinutes ~/ 5);

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurfaceVariant.opaque(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Reminder Interval',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _PickerColumn(
                        label: 'HOURS',
                        controller: hoursController,
                        itemCount: 25,
                        itemBuilder: (index) => '$index',
                        onSelected: (val) {
                          setSheetState(() => selectedHours = val);
                        },
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(top: 28),
                        child: Text(
                          'h',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface.opaque(0.3),
                          ),
                        ),
                      ),
                      const SizedBox(width: 32),
                      _PickerColumn(
                        label: 'MINUTES',
                        controller: minutesController,
                        itemCount: 12,
                        itemBuilder: (index) =>
                            (index * 5).toString().padLeft(2, '0'),
                        onSelected: (val) {
                          setSheetState(() => selectedMinutes = val * 5);
                        },
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(top: 28),
                        child: Text(
                          'm',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface.opaque(0.3),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: FilledButton(
                      onPressed: () {
                        final total = selectedHours * 60 + selectedMinutes;
                        if (total >= 1) {
                          service.setReminderMinutes(total);
                          setState(() {});
                        }
                        Navigator.pop(ctx);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Set',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  // ---- CHART SECTION ----

  Widget _buildChartSection(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: colorScheme.surfaceContainer.opaque(0.3),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildSegmentedTabs(colorScheme),
          const SizedBox(height: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: _buildChart(colorScheme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedTabs(ColorScheme colorScheme) {
    const periods = [
      ('Weekly', _ChartPeriod.weekly),
      ('Monthly', _ChartPeriod.monthly),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.opaque(0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: periods.map((p) {
          final selected = _selectedPeriod == p.$2;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriod = p.$2),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    p.$1,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface.opaque(0.5),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChart(ColorScheme colorScheme) {
    switch (_selectedPeriod) {
      case _ChartPeriod.weekly:
        return _buildWeeklyChart(colorScheme);
      case _ChartPeriod.monthly:
        return _buildMonthlyChart(colorScheme);
    }
  }

  // ---- BAR WIDGET ----

  Widget _buildBar({
    required double value,
    required double displayMax,
    required String label,
    required bool isHighlighted,
    required ColorScheme colorScheme,
  }) {
    return LayoutBuilder(builder: (context, constraints) {
      final maxBar =
          (constraints.maxHeight - 42).clamp(10.0, constraints.maxHeight);
      final frac = displayMax > 0 ? value / displayMax : 0.0;
      final barH = (frac * maxBar).clamp(value > 0 ? 4.0 : 0.0, maxBar);

      return ClipRect(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (value > 0)
              Text(
                value >= 60
                    ? '${(value / 60).toStringAsFixed(1)}h'
                    : '${value.toInt()}m',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface.opaque(0.7),
                ),
              ),
            const SizedBox(height: 3),
            Container(
              height: barH,
              width: constraints.maxWidth - 4,
              decoration: BoxDecoration(
                color: isHighlighted
                    ? colorScheme.primary
                    : colorScheme.primary.opaque(0.22),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isHighlighted
                    ? colorScheme.primary
                    : colorScheme.primary.opaque(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isHighlighted
                      ? colorScheme.onPrimary
                      : colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ---- WEEKLY ----

  Widget _buildWeeklyChart(ColorScheme colorScheme) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
    final labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final values = days.map((d) {
      final key = DateTime(d.year, d.month, d.day).toIso8601String();
      return (service.dailyUsage[key] ?? 0).toDouble();
    }).toList();

    // Include current session in today's bar
    final todayIdx = days.indexWhere((d) => d == today);
    if (todayIdx >= 0) {
      values[todayIdx] += service.currentSessionMinutes.toDouble();
    }

    final maxVal = values.fold<double>(0, (m, v) => v > m ? v : m);
    final displayMax = maxVal < 5 ? 5.0 : maxVal;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (i) {
        return Expanded(
          child: _buildBar(
            value: values[i],
            displayMax: displayMax,
            label: labels[days[i].weekday - 1],
            isHighlighted: days[i] == today,
            colorScheme: colorScheme,
          ),
        );
      }),
    );
  }

  // ---- MONTHLY (12 bars for months of current year) ----

  Widget _buildMonthlyChart(ColorScheme colorScheme) {
    final now = DateTime.now();

    final values = List<double>.generate(12, (m) {
      final month = m + 1;
      final daysInMonth = DateTime(now.year, month + 1, 0).day;
      double sum = 0;
      for (var d = 1; d <= daysInMonth; d++) {
        final key = DateTime(now.year, month, d).toIso8601String();
        sum += (service.dailyUsage[key] ?? 0);
      }
      return sum;
    });

    // Include current session in current month
    values[now.month - 1] += service.currentSessionMinutes.toDouble();

    final maxVal = values.fold<double>(0, (m, v) => v > m ? v : m);
    final displayMax = maxVal < 5 ? 5.0 : maxVal;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(12, (i) {
        return Expanded(
          child: _buildBar(
            value: values[i],
            displayMax: displayMax,
            label: '${i + 1}',
            isHighlighted: i + 1 == now.month,
            colorScheme: colorScheme,
          ),
        );
      }),
    );
  }
}

// ---- PICKER WIDGET ----

class _PickerColumn extends StatelessWidget {
  final String label;
  final FixedExtentScrollController controller;
  final int itemCount;
  final String Function(int index) itemBuilder;
  final void Function(int index) onSelected;
  final ColorScheme colorScheme;

  const _PickerColumn({
    required this.label,
    required this.controller,
    required this.itemCount,
    required this.itemBuilder,
    required this.onSelected,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
            color: colorScheme.onSurface.opaque(0.4),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 72,
          height: 160,
          child: ListWheelScrollView.useDelegate(
            controller: controller,
            itemExtent: 44,
            perspective: 0.003,
            diameterRatio: 1.4,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: onSelected,
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                if (index < 0 || index >= itemCount) return null;
                final isSelected = index == controller.selectedItem;
                return Center(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 150),
                    style: TextStyle(
                      fontSize: isSelected ? 22 : 16,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w400,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface.opaque(0.35),
                    ),
                    child: Text(itemBuilder(index)),
                  ),
                );
              },
              childCount: itemCount,
            ),
          ),
        ),
      ],
    );
  }
}
