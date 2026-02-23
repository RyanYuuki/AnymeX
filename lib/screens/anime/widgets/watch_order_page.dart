import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/other_features.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/watch_order_util.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/header.dart';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';
import 'package:flutter/material.dart';
import 'package:anymex/utils/theme_extensions.dart';

class WatchOrderPage extends StatefulWidget {
  final String title;
  const WatchOrderPage({super.key, required this.title});

  @override
  State<WatchOrderPage> createState() => _WatchOrderPageState();
}

class _WatchOrderPageState extends State<WatchOrderPage> {
  bool isLoading = true;
  String? error;
  List<WatchOrderItem> watchOrder = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final searchResults = await WatchOrderUtil.searchWatchOrder(widget.title);

      print('Search results: ${searchResults.length}');

      if (searchResults.isEmpty) {
        if (mounted) {
          setState(() {
            isLoading = false;
            error = "Could not find watch order for '${widget.title}'";
          });
        }
        return;
      }

      final id = searchResults.first.id;
      final order = await WatchOrderUtil.fetchWatchOrder(id);

      if (mounted) {
        setState(() {
          watchOrder = order;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Glow(
      child: Scaffold(
        body: Column(
          children: [
            const NestedHeader(title: 'Watch Order'),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (isLoading) {
                    return const Center(child: AnymexProgressIndicator());
                  }
                  if (error != null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: AnymexText(
                          text: error!,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  if (watchOrder.isEmpty) {
                    return const Center(
                        child: AnymexText(text: "No watch order found."));
                  }

                  return ListView.builder(
                    itemExtent: 180,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 20),
                    itemCount: watchOrder.length,
                    itemBuilder: (context, index) {
                      final item = watchOrder[index];
                      final isLast = index == watchOrder.length - 1;
                      return _buildTimelineItem(
                          context, item, index + 1, isLast);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
      BuildContext context, WatchOrderItem item, int index, bool isLast) {
    final colorScheme = context.colors;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.opaque(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  "$index",
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant.opaque(0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: _buildAnimeCard(context, item),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimeCard(BuildContext context, WatchOrderItem item) {
    final colorScheme = context.colors;

    return GestureDetector(
      onTap: () {
        if (item.anilistId.isNotEmpty) {
          final media = Media(
            id: item.anilistId,
            title: item.nameEnglish ?? item.name,
            poster: item.image,
            serviceType: ServicesType.anilist,
          );
          navigate(() => AnimeDetailsPage(media: media, tag: "wo-${item.id}"));
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer.opaque(0.5),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: colorScheme.outlineVariant.opaque(0.2)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            if (item.image.isNotEmpty)
              AnymeXImage(
                imageUrl: item.image,
                width: 100,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    if (item.relationType.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: AnymexText(
                          text: item.relationType.toUpperCase(),
                          size: 9,
                          color: colorScheme.onPrimaryContainer,
                          variant: TextVariant.bold,
                        ),
                      ),
                    AnymexText(
                      text: item.nameEnglish ?? item.name,
                      variant: TextVariant.bold,
                      size: 15,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.nameEnglish != null &&
                        item.nameEnglish!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: AnymexText(
                          text: item.name,
                          size: 11,
                          color: colorScheme.onSurfaceVariant,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (item.airDate.isNotEmpty)
                          _buildInfoBadge(context, _formatAirDate(item.airDate),
                              Icons.calendar_today_rounded),
                        if (item.mediaType.isNotEmpty)
                          _buildInfoBadge(context, item.mediaType,
                              Icons.movie_filter_rounded,
                              isAccent: true),
                        if (item.episodes.isNotEmpty)
                          _buildInfoBadge(context, item.episodes,
                              Icons.video_library_rounded),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (item.rating.isNotEmpty)
                      AnymexText(
                        text: (item.rating),
                        size: 12,
                        variant: TextVariant.semiBold,
                        color: colorScheme.onSurface,
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

  Widget _buildInfoBadge(BuildContext context, String text, IconData icon,
      {bool isAccent = false}) {
    final colorScheme = context.colors;
    final color =
        isAccent ? colorScheme.secondary : colorScheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatAirDate(String airDate) {
    final yearMatch = RegExp(r'\d{4}').firstMatch(airDate);
    if (yearMatch != null) {
      return yearMatch.group(0)!;
    }
    return airDate;
  }
}
