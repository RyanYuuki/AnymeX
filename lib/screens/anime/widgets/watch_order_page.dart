import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/watch_order_util.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

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
      //Search for the series ID
      final searchResults = await WatchOrderUtil.searchWatchOrder(widget.title);

      if (searchResults.isEmpty) {
        if (mounted) {
          setState(() {
            isLoading = false;
            error = "Could not find watch order for '${widget.title}'";
          });
        }
        return;
      }

      //Fetch the watch order using the best match (first result)
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
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new),
          ),
          title: const AnymexText(
            text: "Watch Order",
            variant: TextVariant.bold,
            size: 18,
          ),
        ),
        body: Builder(
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

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: watchOrder.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = watchOrder[index];
                return _buildWatchOrderItem(context, item, index + 1);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildWatchOrderItem(
      BuildContext context, WatchOrderItem item, int index) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Text(
            "$index",
            style: TextStyle(
                color: colorScheme.primary, fontWeight: FontWeight.bold),
          ),
        ),
        title: AnymexText(
          text: item.name,
          variant: TextVariant.semiBold,
          size: 14,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.nameEnglish != null && item.nameEnglish != item.name)
              AnymexText(
                text: item.nameEnglish!,
                size: 12,
                color: colorScheme.onSurfaceVariant.withOpacity(0.8),
              ),
            if (item.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: AnymexText(
                  text: item.text,
                  size: 11,
                  color: colorScheme.primary,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        onTap: () {
          if (item.anilistId.isNotEmpty) {
            final media = Media(
              id: item.anilistId,
              title: item.nameEnglish ?? item.name,
              poster: item.image,
              serviceType: ServicesType.anilist,
            );
            navigate(
                () => AnimeDetailsPage(media: media, tag: "wo-${item.id}"));
          }
        },
      ),
    );
  }
}
