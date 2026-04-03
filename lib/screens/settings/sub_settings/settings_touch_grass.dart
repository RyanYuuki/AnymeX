import 'dart:io';
import 'package:anymex/services/touch_grass_service.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:anymex/screens/other_features.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:intl/intl.dart';

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
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: getResponsiveValue(context,
                    mobileValue: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    desktopValue: const EdgeInsets.fromLTRB(20, 16, 25, 20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(context, 'Configuration'),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: colorScheme.surfaceContainer.opaque(0.3),
                        border: Border.all(
                          color: colorScheme.outline.opaque(0.1),
                        ),
                      ),
                      child: Obx(() => Column(
                            children: [
                              CustomSwitchTile(
                                icon: Icons.analytics_outlined,
                                title: 'Enable Tracking',
                                description:
                                    'Track your usage time within the app',
                                switchValue: service.trackingEnabled.value,
                                onChanged: (val) {
                                  service.setTrackingEnabled(val);
                                  setState(() {});
                                },
                              ),
                              if (service.trackingEnabled.value) ...[
                                Divider(
                                    height: 1,
                                    color: colorScheme.outline.opaque(0.1)),
                                CustomSwitchTile(
                                  icon: Icons.notifications_active_outlined,
                                  title: 'Enable Reminders',
                                  description:
                                      'Get a popup reminder after extended viewing',
                                  switchValue: service.remindersEnabled.value,
                                  onChanged: (val) {
                                    service.setRemindersEnabled(val);
                                    setState(() {});
                                  },
                                ),
                                if (service.remindersEnabled.value) ...[
                                  Divider(
                                      height: 1,
                                      color: colorScheme.outline.opaque(0.1)),
                                  CustomTile(
                                    icon: Icons.timer_outlined,
                                    title: 'Reminder Interval',
                                    description:
                                        'Remind after ${_formatMinutes(service.reminderMinutes.value)}',
                                    onTap: () =>
                                        _showIntervalPicker(colorScheme),
                                  ),
                                ],
                              ],
                              if (Platform.isAndroid) ...[
                                Divider(
                                    height: 1,
                                    color: colorScheme.outline.opaque(0.1)),
                                CustomTile(
                                  icon: Icons.settings_suggest_rounded,
                                  title: 'Usage Access',
                                  description:
                                      'Grant permission to see device-wide screentime (Optional)',
                                  onTap: () {
                                    // Placeholder for Android Usage Stats permission
                                    Get.snackbar('Coming Soon',
                                        'Usage stats integration for Android is under development.');
                                  },
                                ),
                              ],
                            ],
                          )),
                    ),
                    Obx(() {
                      if (!service.trackingEnabled.value) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: colorScheme.surfaceContainer.opaque(0.3),
                            border: Border.all(
                              color: colorScheme.outline.opaque(0.1),
                            ),
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
                    const SizedBox(height: 24),
                    Obx(() {
                      if (!service.trackingEnabled.value) {
                        return const SizedBox.shrink();
                      }
                      final session = service.currentSessionMinutes;
                      final total = service.totalAllTimeMinutes;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(context, 'Current Stats'),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  context: context,
                                  title: 'Total',
                                  value: _formatMinutes(total),
                                  icon: Icons.history_rounded,
                                  color: colorScheme.primary,
                                ),
                              ),
                              if (session > 0) ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatCard(
                                    context: context,
                                    title: 'Current Session',
                                    value: _formatMinutes(session),
                                    icon: Icons.timer_rounded,
                                    color: colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: 24),
                    _buildSectionHeader(context, 'Activity History'),
                    const SizedBox(height: 12),
                    Obx(() => _buildChartSection(colorScheme)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: AnymexText(
        text: title.toUpperCase(),
        variant: TextVariant.bold,
        size: 13,
        color: Theme.of(context).colorScheme.onSurface.opaque(0.5),
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.opaque(0.7),
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
        ],
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
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          return Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurfaceVariant.opaque(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Reminder Interval',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose how often to be reminded',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface.opaque(0.6),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 70,
                          child: Center(
                            child: Text(
                              'HOURS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                color: colorScheme.onSurface.opaque(0.4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                        SizedBox(
                          width: 70,
                          child: Center(
                            child: Text(
                              'MINUTES',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                color: colorScheme.onSurface.opaque(0.4),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          height: 50,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _PickerColumn(
                              controller: hoursController,
                              itemCount: 25,
                              itemBuilder: (index) => '$index',
                              onSelected: (val) {
                                setSheetState(() => selectedHours = val);
                              },
                              colorScheme: colorScheme,
                            ),
                            const SizedBox(width: 40),
                            _PickerColumn(
                              controller: minutesController,
                              itemCount: 12,
                              itemBuilder: (index) =>
                                  (index * 5).toString().padLeft(2, '0'),
                              onSelected: (val) {
                                setSheetState(() => selectedMinutes = val * 5);
                              },
                              colorScheme: colorScheme,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(
                                  color: colorScheme.outline.opaque(0.2)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
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
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: colorScheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Confirm',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: colorScheme.surfaceContainer.opaque(0.3),
        border: Border.all(
          color: colorScheme.outline.opaque(0.1),
        ),
      ),
      child: Column(
        children: [
          _buildSegmentedTabs(colorScheme),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: _buildChart(colorScheme),
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
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.opaque(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: periods.map((p) {
          final selected = _selectedPeriod == p.$2;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriod = p.$2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    p.$1,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                      color: selected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface.opaque(0.7),
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
      final maxBarH = constraints.maxHeight - 50;
      final frac = displayMax > 0 ? value / displayMax : 0.0;
      final barH = (frac * maxBarH).clamp(value > 0 ? 8.0 : 0.0, maxBarH);

      return Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (value > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                value >= 60
                    ? '${(value / 60).toStringAsFixed(1)}h'
                    : '${value.toInt()}m',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isHighlighted
                      ? colorScheme.primary
                      : colorScheme.onSurface.opaque(0.7),
                ),
              ),
            ),
          Container(
            height: barH,
            width: 14,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isHighlighted
                    ? [
                        colorScheme.primary,
                        colorScheme.primary.withValues(alpha: 0.6)
                      ]
                    : [
                        colorScheme.primary.withValues(alpha: 0.3),
                        colorScheme.primary.withValues(alpha: 0.1)
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: isHighlighted
                  ? [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : [],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isHighlighted ? FontWeight.w900 : FontWeight.w700,
              color: isHighlighted
                  ? colorScheme.onSurface
                  : colorScheme.onSurface.opaque(0.7),
            ),
          ),
        ],
      );
    });
  }

  // ---- WEEKLY ----

  Widget _buildWeeklyChart(ColorScheme colorScheme) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = List.generate(7, (i) => DateTime(today.year, today.month, today.day - (6 - i)));

    final values = days.map((d) {
      final key = d.toIso8601String();
      return (service.dailyUsage[key] ?? 0).toDouble();
    }).toList();

    final todayIdx = days.indexWhere((d) => d == today);
    if (todayIdx >= 0) {
      values[todayIdx] += service.currentSessionMinutes.toDouble();
    }

    final maxVal = values.fold<double>(0, (m, v) => v > m ? v : m);
    final displayMax = maxVal < 5 ? 5.0 : maxVal;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (i) {
        final date = days[i];
        return _buildBar(
          value: values[i],
          displayMax: displayMax,
          label: DateFormat.E().format(date),
          isHighlighted: date == today,
          colorScheme: colorScheme,
        );
      }),
    );
  }

  // ---- MONTHLY ----

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

    values[now.month - 1] += service.currentSessionMinutes.toDouble();

    final maxVal = values.fold<double>(0, (m, v) => v > m ? v : m);
    final displayMax = maxVal < 5 ? 5.0 : maxVal;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(12, (i) {
        final monthDate = DateTime(now.year, i + 1);
        return _buildBar(
          value: values[i],
          displayMax: displayMax,
          label: DateFormat.MMM().format(monthDate)[0],
          isHighlighted: i + 1 == now.month,
          colorScheme: colorScheme,
        );
      }),
    );
  }
}

// ---- PICKER WIDGET ----

class _PickerColumn extends StatelessWidget {
  final FixedExtentScrollController controller;
  final int itemCount;
  final String Function(int index) itemBuilder;
  final void Function(int index) onSelected;
  final ColorScheme colorScheme;

  const _PickerColumn({
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
        SizedBox(
          width: 70,
          height: 180,
          child: ListWheelScrollView.useDelegate(
            controller: controller,
            itemExtent: 50,
            perspective: 0.006,
            diameterRatio: 1.2,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: onSelected,
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                if (index < 0 || index >= itemCount) return null;
                return Center(
                  child: Text(
                    itemBuilder(index),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
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


