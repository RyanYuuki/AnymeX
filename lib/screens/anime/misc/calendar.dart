import 'dart:async';
import 'dart:ui';

import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/anilist/calendar_data.dart';
import 'package:anymex/controllers/services/simkl/calendar_data.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/anime/misc/dub_service.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_progress.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class Calendar extends StatefulWidget {
  const Calendar({super.key});

  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar>
    with SingleTickerProviderStateMixin {
  final serviceHandler = Get.find<ServiceHandler>();
  RxList<Media> calendarData = <Media>[].obs;
  RxList<Media> listData = <Media>[].obs;
  RxList<Media> rawData = <Media>[].obs;
  late TabController _tabController;
  late ScrollController _tabScrollController;
  int _selectedTabIndex = 0;
  List<DateTime> dateTabs = [];
  bool isGrid = true;
  bool isLoading = true;
  bool hasError = false;
  String? errorMessage;
  bool includeList = false;

  RxBool isDubMode = false.obs;
  RxBool isFetching = false.obs;
  List<DubAnimeInfo> dubCache = [];

  bool get isAnilist => serviceHandler.serviceType.value == ServicesType.anilist;
  bool get isSimkl => serviceHandler.serviceType.value == ServicesType.simkl;

  @override
  void initState() {
    super.initState();
    _tabScrollController = ScrollController();
    _loadData();

    dateTabs =
        List.generate(7, (index) => DateTime.now().add(Duration(days: index)));

    _tabController = TabController(length: dateTabs.length, vsync: this);
    _tabController.addListener(_onTabControllerChanged);
  }

  void _loadData() {
    setState(() {
      isLoading = true;
      hasError = false;
      errorMessage = null;
      calendarData.clear();
      rawData.clear();
      listData.clear();
    });

    final ids = serviceHandler.animeList.map((e) => e.id).toSet().toList();

    if (isSimkl) {
      fetchSimklCalendarData(calendarData, isMovies: true).then((_) {
        return fetchSimklCalendarData(calendarData, isMovies: false);
      }).then((_) {
        if (!mounted) return;
        setState(() {
          rawData.value = calendarData.map((e) => e).toList();
          listData.value =
              calendarData.where((e) => ids.contains(e.id)).toList();
          isLoading = false;
          hasError = false;
        });
      }).catchError((e) {
        if (!mounted) return;
        setState(() {
          isLoading = false;
          hasError = true;
          final raw = e.toString().replaceFirst('Exception: ', '').trim();
          errorMessage =
              raw.isNotEmpty ? raw : 'Failed to load Simkl calendar data';
        });
      });
    } else {
      fetchCalendarData(calendarData).then((_) {
        if (!mounted) return;
        setState(() {
          rawData.value = calendarData.map((e) => e).toList();
          listData.value =
              calendarData.where((e) => ids.contains(e.id)).toList();
          isLoading = false;
          hasError = false;
        });
      }).catchError((e) {
        if (!mounted) return;
        setState(() {
          isLoading = false;
          hasError = true;
          final raw = e.toString().replaceFirst('Exception: ', '').trim();
          errorMessage =
              raw.isNotEmpty ? raw : 'Failed to load AniList calendar data';
        });
      });
    }
  }

  Future<void> _toggleDub() async {
    if (!isAnilist) return;

    isDubMode.value = !isDubMode.value;
    if (isDubMode.value && dubCache.isEmpty) {
      isFetching.value = true;
      try {
        dubCache = await DubService.fetchDubSources();
      } catch (_) {
      } finally {
        isFetching.value = false;
      }
    }
  }

  String _norm(String t) =>
      t.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  bool _isSameDate(Media media, DateTime date) {
    if (media.nextAiringEpisode != null) {
      final airDate = DateTime.fromMillisecondsSinceEpoch(
          media.nextAiringEpisode!.airingAt * 1000);
      return airDate.year == date.year &&
          airDate.month == date.month &&
          airDate.day == date.day;
    }
    final rawAired = media.aired.trim();
    if (rawAired.isEmpty) return false;
    try {
      final parsed = DateTime.tryParse(rawAired);
      if (parsed != null) {
        return parsed.day == date.day && parsed.month == date.month;
      }
      final parts = rawAired.split('-');
      if (parts.length == 3) {
        if (parts[0].length == 4) {
          final m = int.parse(parts[1]);
          final d = int.parse(parts[2]);
          return d == date.day && m == date.month;
        } else if (parts[2].length == 4) {
          final d = int.parse(parts[0]);
          final m = int.parse(parts[1]);
          return d == date.day && m == date.month;
        }
      }
    } catch (_) {}
    return false;
  }

  DubAnimeInfo? _getDubInfo(Media m) {
    if (!isAnilist) return null;
    
    String normalized = _norm(m.title);
    for (var dub in dubCache) {
      if (_norm(dub.title) == normalized) {
        return dub;
      }
    }
    return null;
  }

  void changeLayout() {
    setState(() {
      isGrid = !isGrid;
    });
  }

  void changeListType() {
    setState(() {
      includeList = !includeList;
    });
  }

  void _onTabControllerChanged() {
    if (!mounted) return;
    if (_tabController.index != _selectedTabIndex) {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
      _scrollToTab(_selectedTabIndex);
    }
  }

  void _scrollToTab(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_tabScrollController.hasClients) return;
      const tabEstimatedWidth = 140.0;
      final screenWidth = MediaQuery.sizeOf(context).width;
      final targetOffset = (index * (tabEstimatedWidth + 8)) -
          (screenWidth / 2) +
          (tabEstimatedWidth / 2);
      final clampedOffset = targetOffset.clamp(
        0.0,
        _tabScrollController.position.maxScrollExtent,
      );
      _tabScrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabControllerChanged);
    _tabController.dispose();
    _tabScrollController.dispose();
    super.dispose();
  }

  BorderRadius _dateTabBorder(int index, bool isSelected) {
    if (isSelected) {
      return BorderRadius.circular(50.multiplyRadius());
    }
    if (index == 0) {
      return BorderRadius.only(
        topLeft: Radius.circular(16.multiplyRadius()),
        bottomLeft: Radius.circular(16.multiplyRadius()),
        topRight: Radius.circular(5.multiplyRadius()),
        bottomRight: Radius.circular(5.multiplyRadius()),
      );
    }
    if (index == dateTabs.length - 1) {
      return BorderRadius.only(
        topRight: Radius.circular(16.multiplyRadius()),
        bottomRight: Radius.circular(16.multiplyRadius()),
        topLeft: Radius.circular(5.multiplyRadius()),
        bottomLeft: Radius.circular(5.multiplyRadius()),
      );
    }
    return BorderRadius.circular(5.multiplyRadius());
  }

  Widget _buildHeaderActions(BuildContext context) {
    return Obx(
      () => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isAnilist)
            IconButton(
              onPressed: _toggleDub,
              tooltip: isDubMode.value ? 'Show All Anime' : 'Dubbed Only',
              icon: Icon(
                isDubMode.value
                    ? HugeIcons.strokeRoundedMicOff01
                    : HugeIcons.strokeRoundedMic01,
                color: isDubMode.value ? context.colors.primary : null,
                size: 20,
              ),
            ),
          if (serviceHandler.isLoggedIn.value)
            IconButton(
              onPressed: changeListType,
              tooltip: includeList ? 'In My List' : 'All Anime',
              icon: Icon(
                !includeList ? Icons.book_rounded : Icons.text_snippet_sharp,
                size: 20,
              ),
            ),
          IconButton(
            onPressed: changeLayout,
            tooltip: isGrid ? 'List Layout' : 'Grid Layout',
            icon: Icon(
              isGrid ? Icons.grid_view_rounded : Icons.view_list,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTab(
      BuildContext context, int index, DateTime date, bool isSelected) {
    final theme = Theme.of(context);

    return Obx(() {
      var list = (includeList ? listData : rawData)
          .where((media) => _isSameDate(media, date))
          .toList();

      if (isDubMode.value && isAnilist && !isFetching.value) {
        list = list.where((m) => _getDubInfo(m) != null).toList();
      }

      final count = list.length;
      final dayLabel = index == 0
          ? 'Today'
          : (index == 1 ? 'Tomorrow' : DateFormat('EEE').format(date));
      final dateLabel = DateFormat('MMM d').format(date);

      return AnymexOnTap(
        margin: 0,
        scale: 0.95,
        onTap: () {
          HapticFeedback.lightImpact();
          _tabController.animateTo(index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.opaque(0.18, iReallyMeanIt: true)
                : theme.colorScheme.surfaceContainerHighest
                    .opaque(0.3, iReallyMeanIt: true),
            borderRadius: _dateTabBorder(index, isSelected),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary.opaque(0.4, iReallyMeanIt: true)
                  : theme.colorScheme.onSurface
                      .opaque(0.08, iReallyMeanIt: true),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnymeXText(
                dayLabel,
                variant: isSelected ? TextVariant.bold : TextVariant.semiBold,
                size: 13,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
              const SizedBox(width: 4),
              AnymeXText(
                '• $dateLabel',
                variant: TextVariant.regular,
                size: 11.5,
                color: isSelected
                    ? theme.colorScheme.primary.opaque(0.8)
                    : theme.colorScheme.onSurface.opaque(0.5),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest
                          .opaque(0.5, iReallyMeanIt: true),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: AnymeXText(
                  count.toString(),
                  variant: TextVariant.bold,
                  size: 11,
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant.opaque(0.8),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildTabsRow(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width > 600;
    final h = isDesktop ? 24.0 : 16.0;

    return SizedBox(
      height: 42,
      child: ListView.separated(
        controller: _tabScrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: h),
        itemCount: dateTabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 3),
        itemBuilder: (context, index) {
          final date = dateTabs[index];
          final isSelected = _selectedTabIndex == index;
          return _buildDateTab(context, index, date, isSelected);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      String subtitleText;
      if (isDubMode.value && isAnilist) {
        subtitleText =
            isFetching.value ? 'Fetching dubs...' : 'Dubbed Only';
      } else if (isSimkl) {
        subtitleText = 'Simkl Schedule';
      } else {
        subtitleText = 'AniList Schedule';
      }

      return AnymeXScaffold(
        showHeader: true,
        headerTitle: 'Calendar',
        headerSubtitle: subtitleText,
        headerAction: _buildHeaderActions(context),
        headerBottom: _buildTabsRow(context),
        headerBottomHeight: 50.0,
        body: Builder(
          builder: (ctx) {
            final headerHeight = AnymeXHeaderScope.of(ctx);

            return TabBarView(
              controller: _tabController,
              children: dateTabs.map((date) {
                return Obx(() {
                  if (isFetching.value && isAnilist) {
                    return Padding(
                      padding: EdgeInsets.only(top: headerHeight),
                      child: const Center(child: AnymeXProgressIndicator()),
                    );
                  }

                  var filteredList = (includeList ? listData : rawData)
                      .where((media) => _isSameDate(media, date))
                      .toList();

                  if (isDubMode.value && isAnilist) {
                    filteredList = filteredList
                        .where((m) => _getDubInfo(m) != null)
                        .toList();
                  }

                  if (isLoading) {
                    return Padding(
                      padding: EdgeInsets.only(top: headerHeight),
                      child: const Center(child: AnymeXProgressIndicator()),
                    );
                  } else if (hasError &&
                      (includeList ? listData : rawData).isEmpty) {
                    return Padding(
                      padding: EdgeInsets.only(top: headerHeight),
                      child: _buildErrorState(context),
                    );
                  } else if (filteredList.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.only(top: headerHeight),
                      child: const Center(child: AnymeXText("No Anime found")),
                    );
                  }

                  return GridView.builder(
                    padding: EdgeInsets.fromLTRB(10, headerHeight + 10, 10, 10),
                    itemCount: filteredList.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: getResponsiveCrossAxisVal(
                            MediaQuery.sizeOf(context).width,
                            itemWidth: isGrid ? 120 : 400),
                        mainAxisExtent: getResponsiveSize(context,
                            mobileSize: isGrid ? 280 : 150,
                            desktopSize: isGrid ? 280 : 180),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 25),
                    itemBuilder: (context, index) {
                      final data = filteredList[index];
                      final dubInfo = isDubMode.value && isAnilist
                          ? _getDubInfo(data)
                          : null;
                      return isGrid
                          ? GridAnimeCard(
                              data: data,
                              dubInfo: dubInfo,
                              isDubMode: isDubMode.value && isAnilist)
                          : BlurAnimeCard(data: data);
                    },
                  );
                });
              }).toList(),
            );
          },
        ),
      );
    });
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.colors.error.opaque(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.warning_2,
                size: 48,
                color: context.colors.error,
              ),
            ),
            const SizedBox(height: 24),
            const AnymeXText.bold(
              'Oops! Something went wrong',
              size: 18,
            ),
            const SizedBox(height: 8),
            AnymeXText.regular(
              errorMessage ?? 'Failed to load calendar data',
              textAlign: TextAlign.center,
              size: 14,
              color: Theme.of(context).colorScheme.onSurface.opaque(0.7),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: Icon(Iconsax.refresh, color: context.colors.onPrimary),
              label: const AnymeXText.semiBold('Try Again', size: 14),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
                foregroundColor: context.colors.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GridAnimeCard extends StatefulWidget {
  const GridAnimeCard({
    super.key,
    required this.data,
    this.dubInfo,
    this.isDubMode = false,
  });
  final Media data;
  final DubAnimeInfo? dubInfo;
  final bool isDubMode;

  @override
  State<GridAnimeCard> createState() => _GridAnimeCardState();
}

class _GridAnimeCardState extends State<GridAnimeCard> {
  static const double cardWidth = 108;
  static const double cardHeight = 280;

  final serviceHandler = Get.find<ServiceHandler>();
  
  bool get isAnilist => serviceHandler.serviceType.value == ServicesType.anilist;
  bool get isSimkl => serviceHandler.serviceType.value == ServicesType.simkl;

  Future<void> _launchUrl(String? url) async {
    if (url != null && url.isNotEmpty) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  String _formatAirTime(DateTime airDateTime) {
    final now = DateTime.now();
    final difference = airDateTime.difference(now);

    if (difference.isNegative) {
      return 'Aired';
    }

    if (difference.inDays > 0) {
      return '${difference.inDays}d ${difference.inHours % 24}h';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m';
    } else {
      return '${difference.inMinutes}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    final streams = widget.dubInfo?.streams ?? [];

    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            children: [
              AnymexOnTap(
                margin: 0,
                onTap: () {
                  navigate(() => AnimeDetailsPage(
                      media: widget.data, tag: widget.data.title));
                },
                child: Hero(
                  tag: widget.data.title,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AnymeXImage(
                      radius: 12,
                      imageUrl: widget.data.poster,
                      width: cardWidth,
                      height: 160,
                      errorImage:
                          'https://s4.anilist.co/file/anilistcdn/character/large/default.jpg',
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: _buildEpisodeChip(widget.data),
              ),
              if (widget.isDubMode)
                Positioned(
                    top: 5,
                    right: 5,
                    child: CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.black54,
                        child: Icon(HugeIcons.strokeRoundedMic01,
                            size: 12,
                            color: context.colors.primary))),
            ],
          ),
          const SizedBox(height: 5),
          if (widget.isDubMode && widget.dubInfo != null) ...[
            SizedBox(
              height: 25,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.schedule,
                      color: context.colors.primary, size: 14),
                  const SizedBox(width: 4),
                  AnymeXText('EP ${widget.dubInfo!.episode}',
                    size: 11,
                    variant: TextVariant.bold,
                    color: context.colors.primary,
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .opaque(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Builder(
                      builder: (context) {
                       
                        if (widget.data.nextAiringEpisode != null) {
                           final nextEp = widget.data.nextAiringEpisode!;
                           final airDate = DateTime.fromMillisecondsSinceEpoch(nextEp.airingAt * 1000);
                           return AnymeXText(_formatAirTime(airDate),
                              size: 10,
                              color: context.colors.primary,
                           );
                        }
                        
                        
                        return AnymeXText(_formatAirTime(widget.dubInfo!.airDateTime),
                          size: 10,
                          color: context.colors.primary,
                        );
                      }
                    ),
                  ),
                ],
              ),
            ),
            if (widget.dubInfo!.streams.isNotEmpty)
              SizedBox(
                height: 25,
                child: Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: widget.dubInfo!.streams.map((s) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0),
                          child: GestureDetector(
                            onTap: () => _launchUrl(s.url),
                            child: Tooltip(
                              message: s.name,
                              child: (s.icon.isEmpty)
                                  ? Icon(Icons.link,
                                      size: 12,
                                      color:
                                          context.colors.primary)
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(50),
                                      child: s.name
                                              .toLowerCase()
                                              .contains('apple')
                                          ? const AnymeXImage(
                                              imageUrl:
                                                  "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRVCJpAHzn91VMfwirwAbAmV-ONO02UjmCj2w&s",
                                              height: 20,
                                              width: 20,
                                              fit: BoxFit.cover,
                                              radius: 0)
                                          : SvgPicture.network(
                                              s.icon,
                                              height: 20,
                                              width: 20,
                                              fit: BoxFit.contain,
                                            )),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              )
          ] else if (widget.isDubMode && streams.isNotEmpty) ...[
            SizedBox(
              height: 25,
              child: Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: streams.map((s) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: GestureDetector(
                          onTap: () => _launchUrl(s.url),
                          child: Tooltip(
                            message: s.name,
                            child: CircleAvatar(
                              radius: 10,
                              backgroundColor: Colors.white10,
                              backgroundImage: (s.icon.isNotEmpty)
                                  ? NetworkImage(s.icon)
                                  : null,
                              child: (s.icon.isEmpty)
                                  ? Icon(Icons.link,
                                      size: 12,
                                      color:
                                          context.colors.primary)
                                  : null,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSimkl ? Icons.movie_filter_rounded : Icons.movie_filter_rounded,
                  color: Colors.grey, 
                  size: 16
                ),
                if (isAnilist && widget.data.nextAiringEpisode?.episode != null) ...[
                  const SizedBox(width: 5),
                  AnymeXText('EPISODE ${widget.data.nextAiringEpisode!.episode}',
                    maxLines: 1,
                    variant: TextVariant.regular,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                    size: 12,
                  ),
                ]
              ],
            ),
          ],
          const SizedBox(height: 5),
          SizedBox(
            width: cardWidth,
            child: AnymeXText(widget.data.title,
              maxLines: 2,
              size: 14,
              textAlign: TextAlign.center,
            ),
          ),
          if (isAnilist && !widget.isDubMode &&
              widget.data.nextAiringEpisode?.episode != null)
            SizedBox(
              width: cardWidth,
              child: AnymeXText('~ | ${widget.data.nextAiringEpisode!.episode - 1} |  ~',
                maxLines: 1,
                size: 12,
                color: Colors.grey,
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEpisodeChip(Media media) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.primary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Iconsax.star5,
            size: 16,
            color: context.colors.onPrimary,
          ),
          const SizedBox(width: 4),
          AnymeXText(media.rating,
            color: context.colors.onPrimary,
            size: 12,
            variant: TextVariant.bold,
          ),
        ],
      ),
    );
  }
}

class BlurAnimeCard extends StatefulWidget {
  final Media data;

  const BlurAnimeCard({super.key, required this.data});

  @override
  State<BlurAnimeCard> createState() => _BlurAnimeCardState();
}

class _BlurAnimeCardState extends State<BlurAnimeCard> {
  RxInt timeLeft = 0.obs;
  final serviceHandler = Get.find<ServiceHandler>();
  
  bool get isAnilist => serviceHandler.serviceType.value == ServicesType.anilist;

  @override
  void initState() {
    super.initState();
   
    if (widget.data.nextAiringEpisode != null) {
       timeLeft.value = widget.data.nextAiringEpisode!.timeUntilAiring;
    } else {
       timeLeft.value = widget.data.nextAiringEpisode?.timeUntilAiring ?? 0;
    }
    startCountdown();
  }

  void startCountdown() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && timeLeft.value > 0) {
        timeLeft.value--;
      } else {
        timer.cancel();
      }
    });
  }

  String formatTime(int seconds) {
    if (seconds <= 0) {
      return 'Aired Already';
    } else {
      int days = seconds ~/ (24 * 3600);
      seconds %= 24 * 3600;
      int hours = seconds ~/ 3600;
      seconds %= 3600;
      int minutes = seconds ~/ 60;
      seconds %= 60;

      List<String> parts = [];
      if (days > 0) parts.add("${days}D");
      if (hours > 0) parts.add("${hours}H");
      if (minutes > 0) parts.add("${minutes}M");
      if (seconds > 0 || parts.isEmpty) parts.add("${seconds}S");

      return parts.join(" ");
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = [
      context.colors.surface.opaque(0.3),
      context.colors.primaryContainer.opaque(0.3),
      context.colors.primaryContainer.opaque(0.8),
    ];

    return AnymexOnTap(
      onTap: () {
        navigate(
            () => AnimeDetailsPage(media: widget.data, tag: widget.data.title));
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          border: Border(
              right: BorderSide(
                  width: 2, color: context.colors.primary)),
          borderRadius: BorderRadius.circular(12.multiplyRadius()),
          color: context.colors.surface.withAlpha(144),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.multiplyRadius()),
          child: Stack(children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: AnymeXImage(
                    imageUrl: widget.data.poster.isNotEmpty
                        ? widget.data.poster
                        : (widget.data.cover ?? ""),
                    radius: 0,
                    width: double.infinity,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: gradientColors)),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnymeXImage(
                  width: getResponsiveSize(context,
                      mobileSize: 120, desktopSize: 130),
                  height: getResponsiveSize(context,
                      mobileSize: 150, desktopSize: 180),
                  radius: 0,
                  imageUrl: widget.data.poster,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                            height: getResponsiveSize(context,
                                mobileSize: 10, desktopSize: 30)),
                        if (isAnilist && widget.data.nextAiringEpisode != null) ...[
                          AnymeXText("Episode ${widget.data.nextAiringEpisode!.episode}",
                            size: 14,
                            maxLines: 2,
                            color: context.colors.primary,
                            variant: TextVariant.bold,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                        ],
                        AnymeXText(widget.data.title,
                          size: 14,
                          maxLines: 2,
                          variant: TextVariant.bold,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              right: 10,
              bottom: 10,
              child: Obx(() {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular((8.multiplyRadius())),
                    color: context.colors.primary,
                  ),
                  child: AnymeXText(formatTime(timeLeft.value),
                    size: 12,
                    color: context.colors.onPrimary,
                    variant: TextVariant.bold,
                  ),
                );
              }),
            ),
          ]),
        ),
      ),
    );
  }
}
