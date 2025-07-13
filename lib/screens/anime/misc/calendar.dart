import 'dart:async';

import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/anilist/calendar_data.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/header.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:blur/blur.dart';
import 'package:flutter/material.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

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
                color: Theme.of(context).colorScheme.primary,
              )),
          actions: [
            if (serviceHandler.isLoggedIn.value) ...[
              IconButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainer,
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
                      Theme.of(context).colorScheme.surfaceContainer,
                ),
                onPressed: () {
                  changeLayout();
                },
                icon: Icon(isGrid ? Icons.grid_view_rounded : Icons.view_list)),
            const SizedBox(width: 10),
          ],
          automaticallyImplyLeading: false,
          title: AnymexText(
            text: "Calendar",
            color: Theme.of(context).colorScheme.primary,
            variant: TextVariant.semiBold,
            size: 16,
          ),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: dateTabs.map((date) {
              return Obx(() {
                List<Media> filteredList = (includeList ? listData : rawData)
                    .where((media) =>
                        DateTime.fromMillisecondsSinceEpoch(
                                media.nextAiringEpisode!.airingAt * 1000)
                            .day ==
                        date.day)
                    .toList();

                return Tab(
                  child: AnymexText(
                    variant: TextVariant.bold,
                    text:
                        '${DateFormat('EEEE, MMMM d, y').format(date)} (${filteredList.length})',
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
              List<Media> filteredList = (includeList ? listData : rawData)
                  .where((media) =>
                      DateTime.fromMillisecondsSinceEpoch(
                              media.nextAiringEpisode!.airingAt * 1000)
                          .day ==
                      date.day)
                  .toList();

              return isLoading
                  ? const Center(child: AnymexProgressIndicator())
                  : filteredList.isEmpty
                      ? const Center(child: Text("No Anime Airing on this day"))
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          itemCount: filteredList.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: getResponsiveCrossAxisVal(
                                      MediaQuery.of(context).size.width,
                                      itemWidth: isGrid ? 120 : 400),
                                  mainAxisExtent: getResponsiveSize(context,
                                      mobileSize: isGrid ? 250 : 150,
                                      desktopSize: isGrid ? 250 : 180),
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 25),
                          itemBuilder: (context, index) {
                            final data = filteredList[index];
                            return isGrid
                                ? GridAnimeCard(data: data)
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
  });
  final Media data;

  @override
  State<GridAnimeCard> createState() => _GridAnimeCardState();
}

class _GridAnimeCardState extends State<GridAnimeCard> {
  static const double cardWidth = 108;
  static const double cardHeight = 270;

  @override
  Widget build(BuildContext context) {
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
                    child: NetworkSizedImage(
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
            ],
          ),
          const SizedBox(height: 5),
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
          const SizedBox(height: 5),
          SizedBox(
            width: cardWidth,
            child: AnymexText(
              text: widget.data.title,
              maxLines: 2,
              size: 14,
            ),
          ),
          if (widget.data.nextAiringEpisode?.episode != null)
            SizedBox(
              width: cardWidth,
              child: AnymexText(
                text: '~ | ${widget.data.nextAiringEpisode!.episode - 1} |  ~',
                maxLines: 1,
                size: 12,
                color: Colors.grey,
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
        color: Theme.of(context).colorScheme.primary,
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
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          const SizedBox(width: 4),
          AnymexText(
            text: media.rating,
            color: Theme.of(context).colorScheme.onPrimary,
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
    timeLeft.value = widget.data.nextAiringEpisode!.timeUntilAiring;
    startCountdown();
  }

  void startCountdown() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft.value > 0) {
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
      if (days > 0) parts.add("$days days");
      if (hours > 0) parts.add("$hours hours");
      if (minutes > 0) parts.add("$minutes minutes");
      if (seconds > 0 || parts.isEmpty) parts.add("$seconds seconds");

      return parts.join(" ");
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = [
      Theme.of(context).colorScheme.surface.withOpacity(0.3),
      Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      Theme.of(context).colorScheme.primaryContainer.withOpacity(0.8),
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
                  width: 2, color: Theme.of(context).colorScheme.primary)),
          borderRadius: BorderRadius.circular(12.multiplyRadius()),
          color: Theme.of(context).colorScheme.surface.withAlpha(144),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.multiplyRadius()),
          child: Stack(children: [
            // Background image
            Positioned.fill(
              child: NetworkSizedImage(
                imageUrl: widget.data.cover ?? widget.data.poster,
                radius: 0,
                width: double.infinity,
              ),
            ),
            Positioned.fill(
              child: RepaintBoundary(
                child: Blur(
                  blur: 4,
                  blurColor: Colors.transparent,
                  child: Container(),
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
                NetworkSizedImage(
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
                          color: Theme.of(context).colorScheme.primary,
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
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  child: AnymexText(
                    text: formatTime(timeLeft.value),
                    size: 12,
                    color: Theme.of(context).colorScheme.onPrimary,
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
