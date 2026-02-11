import 'dart:async';

import 'dart:ui';

import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/anilist/calendar_data.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/anime/misc/dub_service.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/header.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
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
  List<DateTime> dateTabs = [];
  bool isGrid = true;
  bool isLoading = true;
  bool includeList = false;

  RxBool isDubMode = false.obs;
  RxBool isFetching = false.obs;
  List<DubAnimeInfo> dubCache = [];

  @override
  void initState() {
    super.initState();
    final ids = serviceHandler.animeList.map((e) => e.id).toSet().toList();
    fetchCalendarData(calendarData).then((_) {
      setState(() {
        rawData.value = calendarData.map((e) => e).toList();
        listData.value = calendarData.where((e) => ids.contains(e.id)).toList();
        isLoading = false;
      });
    });

    dateTabs =
        List.generate(7, (index) => DateTime.now().add(Duration(days: index)));

    _tabController = TabController(length: dateTabs.length, vsync: this);
  }

  Future<void> _toggleDub() async {
    isDubMode.value = !isDubMode.value;
    if (isDubMode.value && dubCache.isEmpty) {
      isFetching.value = true;
      dubCache = await DubService.fetchDubSources();
      isFetching.value = false;
    }
  }

  String _norm(String t) =>
      t.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  DubAnimeInfo? _getDubInfo(Media m) {
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Glow(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: context.colors.primary,
              )),
          actions: [
            Obx(() => IconButton(
                  onPressed: _toggleDub,
                  tooltip: isDubMode.value ? "Show All" : "Show Dubs Only",
                  icon: Icon(
                    isDubMode.value
                        ? HugeIcons.strokeRoundedMicOff01
                        : HugeIcons.strokeRoundedMic01,
                    color: isDubMode.value
                        ? context.colors.primary
                        : null,
                  ),
                )),
            const SizedBox(width: 10),
            if (serviceHandler.isLoggedIn.value) ...[
              IconButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        context.colors.surfaceContainer,
                  ),
                  onPressed: () {
                    changeListType();
                  },
                  icon: Icon(!includeList
                      ? Icons.book_rounded
                      : Icons.text_snippet_sharp)),
              const SizedBox(width: 10),
            ],
            IconButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      context.colors.surfaceContainer,
                ),
                onPressed: () {
                  changeLayout();
                },
                icon: Icon(isGrid ? Icons.grid_view_rounded : Icons.view_list)),
            const SizedBox(width: 10),
          ],
          automaticallyImplyLeading: false,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnymexText(
                text: "Calendar",
                color: context.colors.primary,
                variant: TextVariant.semiBold,
                size: 16,
              ),
              Obx(() {
                if (isDubMode.value) {
                  return AnymexText(
                    text: isFetching.value ? "Fetching..." : "Dubbed Only",
                    variant: TextVariant.regular,
                    size: 10,
                    color: Colors.grey,
                  );
                }
                return const SizedBox.shrink();
              })
            ],
          ),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: dateTabs.map((date) {
              return Obx(() {
                var list = (includeList ? listData : rawData)
                    .where((media) =>
                        DateTime.fromMillisecondsSinceEpoch(
                                media.nextAiringEpisode!.airingAt * 1000)
                            .day ==
                        date.day)
                    .toList();

                if (isDubMode.value && !isFetching.value) {
                  list = list.where((m) => _getDubInfo(m) != null).toList();
                }

                return Tab(
                  child: AnymexText(
                    variant: TextVariant.bold,
                    text:
                        '${DateFormat('EEEE, MMM d').format(date)} (${list.length})',
                  ),
                );
              });
            }).toList(),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: dateTabs.map((date) {
            return Obx(() {
              if (isFetching.value) {
                return const Center(child: AnymexProgressIndicator());
              }

              var filteredList = (includeList ? listData : rawData)
                  .where((media) =>
                      DateTime.fromMillisecondsSinceEpoch(
                              media.nextAiringEpisode!.airingAt * 1000)
                          .day ==
                      date.day)
                  .toList();

              if (isDubMode.value) {
                filteredList =
                    filteredList.where((m) => _getDubInfo(m) != null).toList();
              }

              if (isLoading) {
                return const Center(child: AnymexProgressIndicator());
              } else if (filteredList.isEmpty) {
                return const Center(child: Text("No Anime found"));
              }

              return GridView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                itemCount: filteredList.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: getResponsiveCrossAxisVal(
                        MediaQuery.of(context).size.width,
                        itemWidth: isGrid ? 120 : 400),
                    mainAxisExtent: getResponsiveSize(context,
                        mobileSize: isGrid ? 280 : 150,
                        desktopSize: isGrid ? 280 : 180),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 25),
                itemBuilder: (context, index) {
                  final data = filteredList[index];
                  final dubInfo = isDubMode.value ? _getDubInfo(data) : null;
                  return isGrid
                      ? GridAnimeCard(
                          data: data,
                          dubInfo: dubInfo,
                          isDubMode: isDubMode.value)
                      : BlurAnimeCard(data: data);
                },
              );
            });
          }).toList(),
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
                  AnymexText(
                    text: 'EP ${widget.dubInfo!.episode}',
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
                           return AnymexText(
                              text: _formatAirTime(airDate),
                              size: 10,
                              color: context.colors.primary,
                           );
                        }
                        
                        
                        return AnymexText(
                          text: _formatAirTime(widget.dubInfo!.airDateTime),
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
                                          ? CachedNetworkImage(
                                              // color: Colors.white,
                                              imageUrl:
                                                  "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRVCJpAHzn91VMfwirwAbAmV-ONO02UjmCj2w&s",
                                              height: 20,
                                              width: 20,
                                              fit: BoxFit.cover)
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
                const Icon(Icons.movie_filter_rounded,
                    color: Colors.grey, size: 16),
                if (widget.data.nextAiringEpisode?.episode != null) ...[
                  const SizedBox(width: 5),
                  AnymexText(
                    text: 'EPISODE ${widget.data.nextAiringEpisode!.episode}',
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
            child: AnymexText(
              text: widget.data.title,
              maxLines: 2,
              size: 14,
              textAlign: TextAlign.center,
            ),
          ),
          if (!widget.isDubMode &&
              widget.data.nextAiringEpisode?.episode != null)
            SizedBox(
              width: cardWidth,
              child: AnymexText(
                text: '~ | ${widget.data.nextAiringEpisode!.episode - 1} |  ~',
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
          AnymexText(
            text: media.rating,
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
                        AnymexText(
                          text:
                              "Episode ${widget.data.nextAiringEpisode!.episode}",
                          size: 14,
                          maxLines: 2,
                          color: context.colors.primary,
                          variant: TextVariant.bold,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        AnymexText(
                          text: widget.data.title,
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
                  child: AnymexText(
                    text: formatTime(timeLeft.value),
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
