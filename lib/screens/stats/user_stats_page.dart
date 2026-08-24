import 'package:anymex/database/isar_models/daily_activity.dart';
import 'package:anymex/database/isar_models/media_stats.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/screens/novel/details/details_view.dart';
import 'package:anymex/screens/stats/controller/user_stats_controller.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_expansion_tile.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/common/scroll_aware_app_bar.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/header/header.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:intl/intl.dart';

class UserStatsPage extends StatefulWidget {
  const UserStatsPage({super.key});

  @override
  State<UserStatsPage> createState() => _UserStatsPageState();
}

class _UserStatsPageState extends State<UserStatsPage> {
  late final UserStatsController controller;
  final _scrollController = ScrollController();
  final _heatmapScrollController = ScrollController();
  final _isAppBarVisibleExternally = ValueNotifier<bool>(true);

  final RxString activeFilter = 'All'.obs; // 'All', 'Anime', 'Manga', 'Novel'
  final Rx<DateTime?> selectedDate = Rx<DateTime?>(null);
  final Rx<DailyActivity?> selectedActivity = Rx<DailyActivity?>(null);
  bool _heatmapHasJumped = false;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<UserStatsController>()) {
      controller = Get.find<UserStatsController>();
    } else {
      controller = Get.put(UserStatsController());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final today = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      selectedDate.value = today;
      selectedActivity.value = controller.dailyActivities.firstWhereOrNull((a) => a.date.isAtSameMomentAs(today));
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _heatmapScrollController.dispose();
    _isAppBarVisibleExternally.dispose();
    super.dispose();
  }

  int _dayKey(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  String _dayName(int weekday) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[(weekday - 1) % 7];
  }

  String _monthLabel(int month) {
    const labels = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return labels[month];
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.paddingOf(context).top;
    const appBarHeight = kToolbarHeight + 20;

    return AnymeXScaffold(
      body: Stack(
        children: [
          Obx(() {
            final streaksData = controller.streaks;
            final longestStreak = streaksData['longest'] ?? 0;

            final totalWatchTime = controller.totalWatchTimeMinutes;
            final totalReadTime = controller.totalReadTimeMinutes;

            int displayedMinutes = 0;
            int displayedUnits = 0;
            MediaStats? favorite;

            if (activeFilter.value == 'Anime') {
              displayedMinutes = controller.mediaStats
                  .where((e) => e.type == 'anime' || e.type == 'movie' || e.type == 'series')
                  .fold(0, (sum, e) => sum + e.totalTimeMinutes);
              displayedUnits = controller.mediaStats
                  .where((e) => e.type == 'anime' || e.type == 'movie' || e.type == 'series')
                  .fold(0, (sum, e) => sum + e.totalUnitsConsumed);
              
              final animeList = controller.mediaStats
                  .where((e) => e.type == 'anime' || e.type == 'movie' || e.type == 'series')
                  .toList();
              if (animeList.isNotEmpty) {
                animeList.sort((a, b) => b.totalTimeMinutes.compareTo(a.totalTimeMinutes));
                favorite = animeList.first;
              }
            } else if (activeFilter.value == 'Manga') {
              displayedMinutes = controller.mediaStats
                  .where((e) => e.type == 'manga')
                  .fold(0, (sum, e) => sum + e.totalTimeMinutes);
              displayedUnits = controller.mediaStats
                  .where((e) => e.type == 'manga')
                  .fold(0, (sum, e) => sum + e.totalUnitsConsumed);
              
              final mangaList = controller.mediaStats
                  .where((e) => e.type == 'manga')
                  .toList();
              if (mangaList.isNotEmpty) {
                mangaList.sort((a, b) => b.totalTimeMinutes.compareTo(a.totalTimeMinutes));
                favorite = mangaList.first;
              }
            } else if (activeFilter.value == 'Novel') {
              displayedMinutes = controller.mediaStats
                  .where((e) => e.type == 'novel')
                  .fold(0, (sum, e) => sum + e.totalTimeMinutes);
              displayedUnits = controller.mediaStats
                  .where((e) => e.type == 'novel')
                  .fold(0, (sum, e) => sum + e.totalUnitsConsumed);
              
              final novelList = controller.mediaStats
                  .where((e) => e.type == 'novel')
                  .toList();
              if (novelList.isNotEmpty) {
                novelList.sort((a, b) => b.totalTimeMinutes.compareTo(a.totalTimeMinutes));
                favorite = novelList.first;
              }
            } else {
              displayedMinutes = totalWatchTime + totalReadTime;
              displayedUnits = controller.totalUnitsConsumed;
              favorite = controller.favoriteTitle;
            }

            final totalHrs = displayedMinutes ~/ 60;
            final totalMins = displayedMinutes % 60;

            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(height: statusBarHeight + appBarHeight + 10),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildFilterRow(context),
                      const SizedBox(height: 16),
                      _buildMainStatsGrid(context, totalHrs, totalMins, displayedUnits, favorite),
                      const SizedBox(height: 12),
                      _buildSmallCardsRow(longestStreak),
                      const SizedBox(height: 20),
                      _buildHeatmapSection(context),
                      const SizedBox(height: 24),
                      _buildFrequentlyRevisitedSection(context),
                      const SizedBox(height: 100),
                    ]),
                  ),
                ),
              ],
            );
          }),
          CustomAnimatedAppBar(
            isVisible: _isAppBarVisibleExternally,
            scrollController: _scrollController,
            headerContent: const Header(
              type: PageType.stats,
            ),
            visibleStatusBarStyle: SystemUiOverlayStyle(
              statusBarIconBrightness:
                  Theme.of(context).brightness == Brightness.light
                      ? Brightness.dark
                      : Brightness.light,
              statusBarBrightness: Theme.of(context).brightness,
              statusBarColor: Colors.transparent,
            ),
            hiddenStatusBarStyle: SystemUiOverlayStyle(
              statusBarIconBrightness:
                  Theme.of(context).brightness == Brightness.light
                      ? Brightness.dark
                      : Brightness.light,
              statusBarBrightness: Theme.of(context).brightness,
              statusBarColor: Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AnymeXText(
          "SHOWING ${activeFilter.value.toUpperCase()} TIME",
          size: 11,
          variant: TextVariant.bold,
          color: context.colors.onSurfaceVariant.withOpacity(0.5),
        ),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerLow.opaque(0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: context.colors.outline.opaque(0.08),
            ),
          ),
          child: Row(
            children: ['All', 'Anime', 'Manga', 'Novel'].map((filter) {
              final isSelected = activeFilter.value == filter;
              return GestureDetector(
                onTap: () => activeFilter.value = filter,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSelected ? context.colors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: AnymeXText(
                    filter,
                    size: 11,
                    variant: TextVariant.bold,
                    color: isSelected ? context.colors.onPrimary : context.colors.onSurfaceVariant,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMainStatsGrid(BuildContext context, int hrs, int mins, int units, MediaStats? favorite) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth > 600;

    final favoriteTitleStr = favorite?.title ?? 'None';
    final favoritePoster = favorite?.poster ?? '';

    final timeReadCard = _buildDashboardCard(
      context: context,
      title: activeFilter.value == 'Anime' ? 'TIME WATCHED' : (activeFilter.value == 'Manga' || activeFilter.value == 'Novel' ? 'TIME READ' : 'TIME SPENT'),
      value: "${hrs}h ${mins}m",
      icon: IconlyLight.timeCircle,
      child: Container(
        height: 15,
        margin: const EdgeInsets.only(top: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(14, (index) {
            final double h = [6.0, 12.0, 8.0, 14.0, 4.0, 9.0, 15.0, 11.0, 7.0, 13.0, 5.0, 10.0, 14.0, 6.0][index];
            return Container(
              width: 4,
              height: h,
              decoration: BoxDecoration(
                color: context.colors.primary.withOpacity(index == 6 ? 1.0 : 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
      ),
    );

    final pagesCard = _buildDashboardCard(
      context: context,
      title: activeFilter.value == 'Anime' ? 'Episodes' : (activeFilter.value == 'Manga' || activeFilter.value == 'Novel' ? 'Chapters' : 'Items Consumed'),
      value: units >= 1000 ? "${(units / 1000.0).toStringAsFixed(1)}k" : "$units",
      icon: IconlyLight.paper,
    );

    final favoriteCard = _buildDashboardCard(
      context: context,
      title: 'FAVORITE TITLE',
      value: favoriteTitleStr,
      icon: IconlyLight.bookmark,
      valueMaxLines: 3,
      isChildOnRight: true,
      child: favoritePoster.isEmpty
          ? null
          : ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AnymeXImage(
                imageUrl: favoritePoster,
                width: 50,
                height: 65,
              ),
            ),
    );
    

    final daysCard = _buildDashboardCard(
      context: context,
      title: 'DAYS ACTIVE',
      value: "${controller.totalDaysActive}",
      icon: IconlyLight.calendar,
    );

    if (isDesktop) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.2,
        children: [timeReadCard, pagesCard, favoriteCard, daysCard],
      );
    } else {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: SizedBox(height: 120, child: timeReadCard)),
              const SizedBox(width: 12),
              Expanded(child: SizedBox(height: 120, child: pagesCard)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: SizedBox(height: 120, child: favoriteCard)),
              const SizedBox(width: 12),
              Expanded(child: SizedBox(height: 120, child: daysCard)),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildDashboardCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    int valueMaxLines = 1,
    bool isChildOnRight = false,
    Widget? child,
  }) {
    return AnymeXCard(
      padding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          if (child != null && isChildOnRight)
            Align(
              alignment: Alignment.centerRight,
              child: child,
            ),
          Padding(
            padding: EdgeInsets.only(right: (child != null && isChildOnRight) ? 56.0 : 0.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 12, color: context.colors.onSurfaceVariant.withOpacity(0.5)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: AnymeXText(
                        title.toUpperCase(),
                        size: 9,
                        variant: TextVariant.bold,
                        color: context.colors.onSurfaceVariant.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AnymeXText(
                      value,
                      size: (child != null && isChildOnRight) ? 12 : 18,
                      variant: TextVariant.bold,
                      color: context.colors.onSurface,
                      maxLines: valueMaxLines,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (child != null && !isChildOnRight) child,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallCardsRow(int longestStreak) {
    return Row(
      children: [
        Expanded(
          child: _buildSmallInfoCard(
            title: 'Titles added',
            value: '${controller.totalTitlesAdded}',
            icon: IconlyLight.bookmark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSmallInfoCard(
            title: 'Avg items/day',
            value: controller.averageUnitsPerDay.toStringAsFixed(1),
            icon: IconlyLight.chart,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSmallInfoCard(
            title: 'Longest str.',
            value: '${longestStreak}d',
            icon: Icons.local_fire_department_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildSmallInfoCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return AnymeXCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 10, color: context.colors.onSurfaceVariant.withOpacity(0.5)),
              const SizedBox(width: 4),
              Expanded(
                child: AnymeXText(
                  title,
                  size: 9,
                  color: context.colors.onSurfaceVariant.withOpacity(0.5),
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          AnymeXText(
            value,
            size: 14,
            variant: TextVariant.bold,
            color: context.colors.onSurface,
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapSection(BuildContext context) {
    final primary = context.colors.primary;
    final emptyColor = context.colors.surfaceContainerHighest.withOpacity(0.3);
    final subtleText = context.colors.onSurfaceVariant.withOpacity(0.5);

    final Map<int, int> levelMap = {};
    final Map<int, int> amountMap = {};

    DateTime? earliestDate;
    for (final h in controller.dailyActivities) {
      final day = DateTime(h.date.year, h.date.month, h.date.day);
      final key = _dayKey(day);
      final totalMins = h.watchTimeMinutes + h.readTimeMinutes;

      amountMap[key] = totalMins;
      
      int level = 0;
      if (totalMins > 0 && totalMins <= 15) {
        level = 2;
      } else if (totalMins > 15 && totalMins <= 45) {
        level = 5;
      } else if (totalMins > 45 && totalMins <= 90) {
        level = 8;
      } else if (totalMins > 90) {
        level = 10;
      }
      levelMap[key] = level;

      if (earliestDate == null || day.isBefore(earliestDate)) {
        earliestDate = day;
      }
    }

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final effectiveEarliest = earliestDate != null
        ? DateTime(earliestDate.year, earliestDate.month, earliestDate.day)
        : todayDate.subtract(const Duration(days: 180)); // default 6 months

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

    if (!_heatmapHasJumped) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _heatmapHasJumped) return;
        if (_heatmapScrollController.hasClients) {
          _heatmapScrollController.jumpTo(_heatmapScrollController.position.maxScrollExtent);
          _heatmapHasJumped = true;
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

    return AnymeXCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AnymeXText(
            'Activity Heatmap',
            size: 14,
            variant: TextVariant.bold,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: dayLabelWidth,
                  child: Column(
                    children: [
                      const SizedBox(height: 18),
                      ...List.generate(7, (row) {
                        return SizedBox(
                          height: cellStep,
                          child: Center(
                            child: AnymeXText(dayLabels[row], style: dayLabelStyle),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    controller: _heatmapScrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 14,
                          width: gridWidth,
                          child: Stack(
                            children: List.generate(monthLabels.length, (i) {
                              return Positioned(
                                left: monthOffsets[i],
                                child: AnymeXText(
                                  monthLabels[i],
                                  style: TextStyle(fontSize: 9, color: subtleText),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: gridWidth,
                          height: 7 * cellStep,
                          child: Row(
                            children: List.generate(totalWeeks, (col) {
                              return SizedBox(
                                width: cellStep,
                                child: Column(
                                  children: List.generate(7, (row) {
                                    final date = gridStart.add(Duration(days: col * 7 + row));
                                    final dateStrip = DateTime(date.year, date.month, date.day);
                                    final key = _dayKey(dateStrip);
                                    final level = levelMap[key] ?? 0;
                                    final minutes = amountMap[key] ?? 0;

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
                                        '${_dayName(date.weekday)}, ${date.day} ${_monthLabel(date.month)} | $minutes mins active';

                                    final isSelected = selectedDate.value?.isAtSameMomentAs(dateStrip) ?? false;

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
                                            color: context.colors.surfaceContainerHighest,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: context.colors.outlineVariant.withOpacity(0.3),
                                            ),
                                          ),
                                          textStyle: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: context.colors.onSurface,
                                          ),
                                          triggerMode: TooltipTriggerMode.tap,
                                          child: GestureDetector(
                                            onTap: isFuture ? null : () {
                                              selectedDate.value = dateStrip;
                                              selectedActivity.value = controller.dailyActivities.firstWhereOrNull(
                                                (a) => a.date.isAtSameMomentAs(dateStrip)
                                              );
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: cellColor,
                                                borderRadius: BorderRadius.circular(3),
                                                border: isSelected
                                                    ? Border.all(color: context.colors.onSurface, width: 1.2)
                                                    : null,
                                              ),
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
          const SizedBox(height: 16),
          _buildDayDetailPanel(context),
        ],
      ),
    );
  }

  Widget _buildDayDetailPanel(BuildContext context) {
    if (selectedDate.value == null) return const SizedBox.shrink();

    final formattedDate = DateFormat('MMMM d, yyyy').format(selectedDate.value!);
    final activity = selectedActivity.value;

    final watchMins = activity?.watchTimeMinutes ?? 0;
    final readMins = activity?.readTimeMinutes ?? 0;
    final eps = activity?.episodesWatched ?? 0;
    final chs = activity?.chaptersRead ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLowest.opaque(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AnymeXText(
                formattedDate,
                size: 13,
                variant: TextVariant.bold,
              ),
              if (watchMins + readMins == 0)
                AnymeXText(
                  'No activity',
                  size: 11,
                  color: context.colors.onSurfaceVariant.withOpacity(0.5),
                )
              else
                AnymeXText(
                  '${watchMins + readMins} mins total',
                  size: 11,
                  color: context.colors.primary,
                  variant: TextVariant.bold,
                ),
            ],
          ),
          if (watchMins > 0 || readMins > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (watchMins > 0) ...[
                  Icon(IconlyLight.play, size: 12, color: context.colors.primary),
                  const SizedBox(width: 4),
                  AnymeXText(
                    '$watchMins min watch ($eps eps)',
                    size: 11,
                  ),
                  const SizedBox(width: 16),
                ],
                if (readMins > 0) ...[
                  Icon(IconlyLight.paper, size: 12, color: context.colors.secondary),
                  const SizedBox(width: 4),
                  AnymeXText(
                    '$readMins min read ($chs chs)',
                    size: 11,
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFrequentlyRevisitedSection(BuildContext context) {
    final list = controller.frequentlyRevisited;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AnymeXText(
          'Frequently Revisited',
          size: 16,
          variant: TextVariant.bold,
        ),
        const SizedBox(height: 12),
        if (list.isEmpty)
          AnymeXCard(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    IconlyLight.activity,
                    size: 40,
                    color: context.colors.onSurfaceVariant.withOpacity(0.2),
                  ),
                  const SizedBox(height: 8),
                  AnymeXText(
                    'No logged stats yet. Start watching/reading!',
                    size: 12,
                    color: context.colors.onSurfaceVariant.withOpacity(0.4),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: list.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AnymeXCard(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    leading: AnymeXImage(
                      imageUrl: item.poster ?? '',
                      width: 45,
                      height: 60,
                      radius: 8,
                    ),
                    title: AnymeXText(
                      item.title,
                      size: 13,
                      variant: TextVariant.semiBold,
                      maxLines: 2,
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: AnymeXText(
                        '${item.type.capitalizeFirst} • Interacted: ${item.interactionCount} times',
                        size: 11,
                        color: context.colors.onSurfaceVariant.withOpacity(0.6),
                      ),
                    ),
                    trailing: Icon(
                      IconlyLight.arrowRight2,
                      color: context.colors.primary,
                      size: 16,
                    ),
                    onTap: () {
                      final mediaType = item.type == 'anime' || item.type == 'movie' || item.type == 'series'
                          ? ItemType.anime
                          : (item.type == 'novel' ? ItemType.novel : ItemType.manga);
                      final mediaObj = Media(
                        id: item.mediaId,
                        title: item.title,
                        mediaType: mediaType,
                        poster: item.poster ?? '',
                        cover: item.cover ?? '',
                        serviceType: item.mediaId.contains('*') 
                            ? ServicesType.simkl 
                            : Get.find<ServiceHandler>().serviceType.value,
                      );
                      if (mediaType == ItemType.anime) {
                        navigateWithAnimation(() => AnimeDetailsPage(media: mediaObj, tag: item.title));
                      } else if (mediaType == ItemType.manga) {
                        navigateWithAnimation(() => MangaDetailsPage(media: mediaObj, tag: item.title));
                      } else {
                        navigateWithAnimation(() => NovelDetailsPage(media: mediaObj, tag: item.title));
                      }
                    },
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
