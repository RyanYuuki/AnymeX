import 'package:anymex/models/Anilist/anilist_profile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ActivityHeatmap extends StatefulWidget {
  final List<ActivityHistory> history;

  const ActivityHeatmap({super.key, required this.history});

  @override
  State<ActivityHeatmap> createState() => _ActivityHeatmapState();
}

class _ActivityHeatmapState extends State<ActivityHeatmap> {
  final ScrollController _scrollController = ScrollController();
  bool _hasJumped = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }


  int _dayKey(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  String _dayName(int weekday) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[(weekday - 1) % 7];
  }

  String _monthLabel(int month) {
    const labels = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return labels[month];
  }

  @override
  Widget build(BuildContext context) {
    final primary = context.theme.colorScheme.primary;
    final emptyColor =
        context.theme.colorScheme.surfaceContainerHighest.withOpacity(0.3);
    final subtleText =
        context.theme.colorScheme.onSurfaceVariant.withOpacity(0.5);

    
    final Map<int, int> levelMap = {};
    final Map<int, int> amountMap = {};
    DateTime? earliestDate;
    for (final h in widget.history) {
      if (h.date > 0) {
        // AniList provides unix in sec
        final day = DateTime.fromMillisecondsSinceEpoch(h.date * 1000);
        final key = _dayKey(day);
        levelMap[key] = h.level;
        amountMap[key] = h.amount;
        if (earliestDate == null || day.isBefore(earliestDate)) {
          earliestDate = day;
        }
      }
    }

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // anilist 6 months from api
    final effectiveEarliest = earliestDate != null
        ? DateTime(earliestDate.year, earliestDate.month, earliestDate.day)
        : todayDate;


    final daysFromSun = effectiveEarliest.weekday % 7;
    final gridStart = effectiveEarliest.subtract(Duration(days: daysFromSun));

  
    final totalDays = todayDate.difference(gridStart).inDays + 1;
    final totalWeeks = (totalDays / 7).ceil();

    const cellSize = 12.0;
    const cellGap = 3.0;
    const cellStep = cellSize + cellGap;
    const dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    const dayLabelWidth = 18.0;

    final monthLabels = <String>[];
    final monthOffsets = <double>[];
    int? prevMonth;


    if (!_hasJumped) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _hasJumped) return;
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          _hasJumped = true;
        }
      });
    }

    List<int> monthStartCols = [];
    for (int col = 0; col < totalWeeks; col++) {
      final weekStart = gridStart.add(Duration(days: col * 7));
      if (prevMonth == null || weekStart.month != prevMonth) {
        prevMonth = weekStart.month;
        monthStartCols.add(col);
      }
    }

    double lastOffset = -999.0;
    for (int i = 0; i < monthStartCols.length; i++) {
      int col = monthStartCols[i];
      final weekStart = gridStart.add(Duration(days: col * 7));

    
      if (i == 0 && monthStartCols.length > 1) {
        int nextCol = monthStartCols[1];
        if (nextCol - col <= 2) continue;
      }

      final currentOffset = (col * cellStep).toDouble();
      if (currentOffset - lastOffset > 24.0) {
        monthLabels.add(_monthLabel(weekStart.month));
        monthOffsets.add(currentOffset);
        lastOffset = currentOffset;
      }
    }

    final dayLabelStyle = TextStyle(fontSize: 9, color: subtleText);
    final gridWidth = totalWeeks * cellStep;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.theme.colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // days
            SizedBox(
              width: dayLabelWidth,
              child: Column(
                children: [
                  const SizedBox(height: 18), 
                  ...List.generate(7, (row) {
                    return SizedBox(
                      height: cellStep,
                      child: Center(
                        child: Text(dayLabels[row], style: dayLabelStyle),
                      ),
                    );
                  }),
                ],
              ),
            ),
            // Scrollable heatmap grid
            Flexible(
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Month labels
                    SizedBox(
                      height: 14,
                      width: gridWidth,
                      child: Stack(
                        children: List.generate(monthLabels.length, (i) {
                          return Positioned(
                            left: monthOffsets[i],
                            child: Text(
                              monthLabels[i],
                              style: TextStyle(fontSize: 9, color: subtleText),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Grid cells
                    SizedBox(
                      width: gridWidth,
                      height: 7 * cellStep,
                      child: Row(
                        children: List.generate(totalWeeks, (col) {
                          return SizedBox(
                            width: cellStep,
                            child: Column(
                              children: List.generate(7, (row) {
                                final date = gridStart
                                    .add(Duration(days: col * 7 + row));
                                final dateStrip =
                                    DateTime(date.year, date.month, date.day);
                                final key = _dayKey(dateStrip);
                                final level = levelMap[key] ?? 0;
                                final amount = amountMap[key] ?? 0;

                                final isFuture = dateStrip.isAfter(todayDate);

                                Color cellColor;
                                if (isFuture) {
                                  cellColor = Colors.transparent;
                                } else if (level == 0) {
                                  cellColor = emptyColor;
                                } else {
                                  final opacity = 0.15 + (level / 10.0) * 0.85;
                                  cellColor = primary.withOpacity(opacity);
                                }

                                final tooltipText =
                                    '${_dayName(date.weekday)}, ${date.day} ${_monthLabel(date.month)} | $amount activities';

                                return SizedBox(
                                  width: cellStep,
                                  height: cellStep,
                                  child: Padding(
                                    padding: const EdgeInsets.all(cellGap / 2),
                                    child: Tooltip(
                                      message: isFuture ? '' : tooltipText,
                                      preferBelow: false,
                                      verticalOffset: 14,
                                      decoration: BoxDecoration(
                                        color: context.theme.colorScheme
                                            .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: context
                                              .theme.colorScheme.outlineVariant
                                              .withOpacity(0.3),
                                        ),
                                      ),
                                      textStyle: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color:
                                            context.theme.colorScheme.onSurface,
                                      ),
                                      triggerMode: TooltipTriggerMode.tap,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: cellColor,
                                          borderRadius:
                                              BorderRadius.circular(3),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
