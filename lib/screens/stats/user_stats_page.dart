import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/database/isar_models/daily_activity.dart';
import 'package:anymex/database/isar_models/media_stats.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/screens/novel/details/details_view.dart';
import 'package:anymex/screens/stats/model/user_rank_info.dart';
import 'package:anymex/screens/stats/controller/user_stats_controller.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_expansion_tile.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/common/scroll_aware_app_bar.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image_button.dart';
import 'package:anymex/widgets/header/header.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:anymex/widgets/common/anymex_pills.dart';
import 'package:iconsax/iconsax.dart';
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

  RxString get activeFilter => controller.activeFilter;
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
      final today = DateTime.utc(
          DateTime.now().year, DateTime.now().month, DateTime.now().day);
      selectedDate.value = today;
      selectedActivity.value = controller.dailyActivities
          .firstWhereOrNull((a) => a.date.isAtSameMomentAs(today));
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
      'Dec'
    ];
    return labels[month];
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.paddingOf(context).top;
    const appBarHeight = kToolbarHeight + 20;
    final settings = Get.find<Settings>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Obx(() {
            final isLegacy = settings.useLegacyNavbar;
            final totalWatchTime = controller.totalWatchTimeMinutes;
            final totalReadTime = controller.totalReadTimeMinutes;

            int displayedMinutes = 0;
            int displayedUnits = 0;
            MediaStats? favorite;

            if (activeFilter.value == 'Anime') {
              displayedMinutes = controller.mediaStats
                  .where((e) =>
                      e.type == 'anime' ||
                      e.type == 'movie' ||
                      e.type == 'series')
                  .fold(0, (sum, e) => sum + e.totalTimeMinutes);
              displayedUnits = controller.mediaStats
                  .where((e) =>
                      e.type == 'anime' ||
                      e.type == 'movie' ||
                      e.type == 'series')
                  .fold(0, (sum, e) => sum + e.totalUnitsConsumed);

              final animeList = controller.mediaStats
                  .where((e) =>
                      e.type == 'anime' ||
                      e.type == 'movie' ||
                      e.type == 'series')
                  .toList();
              if (animeList.isNotEmpty) {
                animeList.sort(
                    (a, b) => b.totalTimeMinutes.compareTo(a.totalTimeMinutes));
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
                mangaList.sort(
                    (a, b) => b.totalTimeMinutes.compareTo(a.totalTimeMinutes));
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
                novelList.sort(
                    (a, b) => b.totalTimeMinutes.compareTo(a.totalTimeMinutes));
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
                  child: SizedBox(
                      height: statusBarHeight +
                          appBarHeight +
                          (isLegacy ? 60 : 10)),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildPrimaryStatsRow(
                          context, totalHrs, totalMins, displayedUnits),
                      const SizedBox(height: 14),
                      _buildRankProgressCard(
                          context, totalWatchTime + totalReadTime),
                      const SizedBox(height: 14),
                      _buildDailyAveragesRow(context),
                      const SizedBox(height: 20),
                      _buildFavoriteTitleShowcase(context, favorite),
                      const SizedBox(height: 20),
                      _buildHeatmapSection(context),
                      const SizedBox(height: 24),
                      _buildDetailedInsightsSection(context),
                      const SizedBox(height: 24),
                      _buildFrequentlyRevisitedSection(context),
                      const SizedBox(height: 100),
                    ]),
                  ),
                ),
              ],
            );
          }),
          Obx(() {
            final isLegacy = settings.useLegacyNavbar;
            return CustomAnimatedAppBar(
              isVisible: _isAppBarVisibleExternally,
              scrollController: _scrollController,
              headerContent: Header(
                title: 'Stats',
                subtitle: 'Your watch & read statistics',
                bottom: isLegacy ? _buildStatsModeChips(context) : null,
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
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatsModeChips(BuildContext context) {
    const options = [
      ('All', Icons.grid_view_rounded),
      ('Anime', Icons.movie_filter_rounded),
      ('Manga', Iconsax.book),
      ('Novel', Icons.auto_stories_rounded),
    ];

    return Obx(() {
      final items = options.map((opt) {
        return PillItem(
          icon: opt.$2,
          label: opt.$1,
          isSelected: activeFilter.value == opt.$1,
          onTap: () => activeFilter.value = opt.$1,
        );
      }).toList();

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: AnymeXPills(
          scrollPadding: EdgeInsets.zero,
          expandEqually: true,
          items: items,
        ),
      );
    });
  }

  Widget _buildPrimaryStatsRow(
      BuildContext context, int hrs, int mins, int units) {
    final timeReadCard = _buildDashboardCard(
      context: context,
      title: activeFilter.value == 'Anime'
          ? 'TIME WATCHED'
          : (activeFilter.value == 'Manga' || activeFilter.value == 'Novel'
              ? 'TIME READ'
              : 'TIME SPENT'),
      value: hrs > 0 ? "${hrs}h ${mins}m" : "${mins}m",
      icon: IconlyLight.timeCircle,
    );

    final pagesCard = _buildDashboardCard(
      context: context,
      title: activeFilter.value == 'Anime'
          ? 'Episodes'
          : (activeFilter.value == 'Manga' || activeFilter.value == 'Novel'
              ? 'Chapters'
              : 'Items Consumed'),
      value:
          units >= 1000 ? "${(units / 1000.0).toStringAsFixed(1)}k" : "$units",
      icon: IconlyLight.paper,
    );

    final daysCard = _buildDashboardCard(
      context: context,
      title: 'DAYS ACTIVE',
      value: "${controller.totalDaysActive}",
      icon: IconlyLight.calendar,
    );

    return Row(
      children: [
        Expanded(child: SizedBox(height: 80, child: timeReadCard)),
        const SizedBox(width: 8),
        Expanded(child: SizedBox(height: 80, child: pagesCard)),
        const SizedBox(width: 8),
        Expanded(child: SizedBox(height: 80, child: daysCard)),
      ],
    );
  }

  Widget _buildRankProgressCard(BuildContext context, int totalMinutes) {
    final UserRankInfo rankInfo = controller.getUserRankInfo(totalMinutes);
    final String title = rankInfo.title;
    final double hours = rankInfo.hours;
    final int nextMaxHours = rankInfo.nextMaxHours;
    final double progress = rankInfo.progress;
    final String rankIcon = rankInfo.rankIcon;
    final int points = rankInfo.points;

    return AnymeXCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  AnymeXText(
                    rankIcon,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnymeXText(
                        title.toUpperCase(),
                        size: 13,
                        variant: TextVariant.bold,
                        color: context.colors.primary,
                      ),
                      const SizedBox(height: 2),
                      AnymeXText(
                        'Otaku Rank Level',
                        size: 10,
                        color: context.colors.onSurfaceVariant.withOpacity(0.5),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: context.colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AnymeXText(
                  '$points XP',
                  size: 11,
                  variant: TextVariant.bold,
                  color: context.colors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AnymeXText(
                'Level Progress',
                size: 11,
                variant: TextVariant.semiBold,
                color: context.colors.onSurfaceVariant.withOpacity(0.8),
              ),
              AnymeXText(
                '${hours.toStringAsFixed(1)}h / ${nextMaxHours}h',
                size: 11,
                variant: TextVariant.semiBold,
                color: context.colors.onSurfaceVariant.withOpacity(0.6),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: context.colors.primary.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(context.colors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyAveragesRow(BuildContext context) {
    final longestStreak = controller.streaks['longest'] ?? 0;
    final currentStreak = controller.streaks['current'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildSmallInfoCard(
            title: 'Avg Episodes',
            value: '${controller.averageEpisodesPerDay.toStringAsFixed(1)}/day',
            icon: Icons.play_circle_outline_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSmallInfoCard(
            title: 'Avg Chapters',
            value: '${controller.averageChaptersPerDay.toStringAsFixed(1)}/day',
            icon: Icons.chrome_reader_mode_outlined,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSmallInfoCard(
            title: 'Streak (Cur/Long)',
            value: '${currentStreak}d / ${longestStreak}d',
            icon: Icons.local_fire_department_rounded,
          ),
        ),
      ],
    );
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
            padding: EdgeInsets.only(
                right: (child != null && isChildOnRight) ? 56.0 : 0.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon,
                        size: 12,
                        color:
                            context.colors.onSurfaceVariant.withOpacity(0.5)),
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

  Widget _buildFavoriteTitleShowcase(
      BuildContext context, MediaStats? favorite) {
    if (favorite == null) return const SizedBox.shrink();

    final totalHrs = favorite.totalTimeMinutes ~/ 60;
    final totalMins = favorite.totalTimeMinutes % 60;
    final timeStr =
        totalHrs > 0 ? '${totalHrs}h ${totalMins}m' : '${totalMins}m';

    final mediaType = favorite.type == 'anime' ||
            favorite.type == 'movie' ||
            favorite.type == 'series'
        ? ItemType.anime
        : (favorite.type == 'novel' ? ItemType.novel : ItemType.manga);

    final mediaObj = Media(
      id: favorite.mediaId,
      title: favorite.title,
      mediaType: mediaType,
      poster: favorite.poster ?? '',
      cover: favorite.cover ?? '',
      serviceType: favorite.mediaId.contains('*')
          ? ServicesType.simkl
          : Get.find<ServiceHandler>().serviceType.value,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4.0),
          child: AnymeXText(
            'Favorite Title',
            size: 16,
            variant: TextVariant.bold,
          ),
        ),
        const SizedBox(height: 12),
        ImageButton(
          buttonText: favorite.title,
          backgroundColor:
              context.colors.surfaceContainerLowest.withOpacity(0.2),
          subText: 'FAVORITE • $timeStr spent',
          tagIcon: IconlyLight.bookmark,
          backgroundImage: favorite.poster ?? '',
          width: double.infinity,
          height: 100,
          borderRadius: 16,
          imageProportion: 0.35,
          onPressed: () {
            if (mediaType == ItemType.anime) {
              navigateWithAnimation(
                  () => AnimeDetailsPage(media: mediaObj, tag: favorite.title));
            } else if (mediaType == ItemType.manga) {
              navigateWithAnimation(
                  () => MangaDetailsPage(media: mediaObj, tag: favorite.title));
            } else {
              navigateWithAnimation(
                  () => NovelDetailsPage(media: mediaObj, tag: favorite.title));
            }
          },
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
              Icon(icon,
                  size: 10,
                  color: context.colors.onSurfaceVariant.withOpacity(0.5)),
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
          _heatmapScrollController
              .jumpTo(_heatmapScrollController.position.maxScrollExtent);
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
                            child: AnymeXText(dayLabels[row],
                                style: dayLabelStyle),
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
                                  style:
                                      TextStyle(fontSize: 9, color: subtleText),
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
                                    final date = gridStart
                                        .add(Duration(days: col * 7 + row));
                                    final dateStrip = DateTime(
                                        date.year, date.month, date.day);
                                    final key = _dayKey(dateStrip);
                                    final level = levelMap[key] ?? 0;
                                    final minutes = amountMap[key] ?? 0;

                                    final isFuture =
                                        dateStrip.isAfter(todayDate);

                                    Color cellColor;
                                    if (isFuture) {
                                      cellColor = Colors.transparent;
                                    } else if (level == 0) {
                                      cellColor = emptyColor;
                                    } else {
                                      final opacity =
                                          0.15 + (level / 10.0) * 0.85;
                                      cellColor = primary.withOpacity(opacity);
                                    }

                                    final tooltipText =
                                        '${_dayName(date.weekday)}, ${date.day} ${_monthLabel(date.month)} | $minutes mins active';

                                    final isSelected = selectedDate.value
                                            ?.isAtSameMomentAs(dateStrip) ??
                                        false;

                                    return SizedBox(
                                      width: cellStep,
                                      height: cellStep,
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.all(cellGap / 2),
                                        child: Tooltip(
                                          message: isFuture ? '' : tooltipText,
                                          preferBelow: false,
                                          verticalOffset: 14,
                                          decoration: BoxDecoration(
                                            color: context
                                                .colors.surfaceContainerHighest,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: context
                                                  .colors.outlineVariant
                                                  .withOpacity(0.3),
                                            ),
                                          ),
                                          textStyle: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: context.colors.onSurface,
                                          ),
                                          triggerMode: TooltipTriggerMode.tap,
                                          child: GestureDetector(
                                            onTap: isFuture
                                                ? null
                                                : () {
                                                    selectedDate.value =
                                                        dateStrip;
                                                    selectedActivity.value = controller
                                                        .dailyActivities
                                                        .firstWhereOrNull((a) => a
                                                            .date
                                                            .isAtSameMomentAs(
                                                                dateStrip));
                                                  },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: cellColor,
                                                borderRadius:
                                                    BorderRadius.circular(3),
                                                border: isSelected
                                                    ? Border.all(
                                                        color: context
                                                            .colors.onSurface,
                                                        width: 1.2)
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

    final formattedDate =
        DateFormat('MMMM d, yyyy').format(selectedDate.value!);
    final activity = selectedActivity.value;

    final watchMins = activity?.watchTimeMinutes ?? 0;
    final readMins = activity?.readTimeMinutes ?? 0;
    final eps = activity?.episodesWatched ?? 0;
    final chs = activity?.chaptersRead ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLowest.opaque(0.2),
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
                  Icon(IconlyLight.play,
                      size: 12, color: context.colors.primary),
                  const SizedBox(width: 4),
                  AnymeXText(
                    '$watchMins min watch ($eps eps)',
                    size: 11,
                  ),
                  const SizedBox(width: 16),
                ],
                if (readMins > 0) ...[
                  Icon(IconlyLight.paper,
                      size: 12, color: context.colors.secondary),
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
        const Padding(
          padding: EdgeInsets.only(left: 4.0),
          child: AnymeXText(
            'Frequently Revisited',
            size: 16,
            variant: TextVariant.bold,
          ),
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
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .opaque(0.3),
                    border: Border.all(
                      color: context.colors.outline
                          .opaque(0.1, iReallyMeanIt: true),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        final mediaType = item.type == 'anime' ||
                                item.type == 'movie' ||
                                item.type == 'series'
                            ? ItemType.anime
                            : (item.type == 'novel'
                                ? ItemType.novel
                                : ItemType.manga);
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
                          navigateWithAnimation(() => AnimeDetailsPage(
                              media: mediaObj, tag: item.title));
                        } else if (mediaType == ItemType.manga) {
                          navigateWithAnimation(() => MangaDetailsPage(
                              media: mediaObj, tag: item.title));
                        } else {
                          navigateWithAnimation(() => NovelDetailsPage(
                              media: mediaObj, tag: item.title));
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: AnymeXImage(
                                width: 55,
                                height: 80,
                                imageUrl: item.poster ?? '',
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnymeXText(
                                    item.title,
                                    maxLines: 2,
                                    size: 14,
                                    variant: TextVariant.semiBold,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  AnymeXText(
                                    '${item.type.capitalizeFirst} • Interacted: ${item.interactionCount} times',
                                    size: 11,
                                    color: context.colors.onSurfaceVariant
                                        .withOpacity(0.6),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              IconlyLight.arrowRight2,
                              color: context.colors.onSurfaceVariant
                                  .withOpacity(0.5),
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildDetailedInsightsSection(BuildContext context) {
    final filter = activeFilter.value;
    final genres = controller.getGenreDistribution(filter);
    final formats = controller.getFormatDistribution(filter);
    final studios = controller.getStudioDistribution();

    final showStudios = filter == 'All' || filter == 'Anime';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4.0),
          child: AnymeXText(
            'Detailed Insights',
            size: 16,
            variant: TextVariant.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (genres.isEmpty &&
            formats.isEmpty &&
            (!showStudios || studios.isEmpty))
          AnymeXCard(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: AnymeXText(
                'No insights available yet. Add items to your library!',
                size: 12,
                color: context.colors.onSurfaceVariant.withOpacity(0.4),
              ),
            ),
          )
        else ...[
          if (genres.isNotEmpty) ...[
            _buildInsightCard(
              context: context,
              title: 'Top Genres',
              icon: Icons.category_outlined,
              data: genres.entries.take(5).toList(),
            ),
            const SizedBox(height: 12),
          ],
          if (showStudios && studios.isNotEmpty) ...[
            _buildInsightCard(
              context: context,
              title: 'Top Studios',
              icon: Icons.movie_creation_outlined,
              data: studios.entries.take(5).toList(),
            ),
            const SizedBox(height: 12),
          ],
          if (formats.isNotEmpty) ...[
            _buildInsightCard(
              context: context,
              title: 'Media Type Breakdown',
              icon: Icons.grid_view_rounded,
              data: formats.entries.toList(),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }

  Widget _buildInsightCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<MapEntry<String, int>> data,
  }) {
    if (data.isEmpty) return const SizedBox.shrink();
    final maxVal = data.first.value;

    return AnymeXCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: context.colors.primary),
              const SizedBox(width: 8),
              AnymeXText(
                title,
                size: 14,
                variant: TextVariant.bold,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...data.map((entry) {
            final double percent = maxVal > 0 ? entry.value / maxVal : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AnymeXText(
                        entry.key,
                        size: 12,
                        variant: TextVariant.semiBold,
                      ),
                      AnymeXText(
                        '${entry.value} ${entry.value == 1 ? "title" : "titles"}',
                        size: 11,
                        color: context.colors.onSurfaceVariant.withOpacity(0.6),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percent,
                      minHeight: 6,
                      backgroundColor: context.colors.primary.withOpacity(0.08),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(context.colors.primary),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
